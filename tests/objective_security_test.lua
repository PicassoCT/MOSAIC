-- Lua 5.1. Exercise real response logic with a deterministic Spring model.
GG={InstanceCulture='asian'}
UnitDefNames=setmetatable({}, {__index=function()return {id=1}end})
UnitDefs={{id=1,buildOptions={}}}
dofile('scripts/lib_mosaic.lua')
local config=getGameConfig().objectives.security
local Security=dofile('luarules/gadgets/include/objective_security.lua')
local defs={
    {name='objective_hospital',xsize=16,zsize=16},
    {name='objective_combatoutpost',xsize=16,zsize=16},
    {name='ground_truck_mg',metalCost=750,xsize=2,zsize=2},
    {name='ground_tank_day',metalCost=5000,xsize=10,zsize=10},
}
local names={};for id,d in ipairs(defs)do names[d.name]={id=id}end
local CMD={ATTACK=1,MOVE=2,FIRE_STATE=3,STOP=4}
local function setup()
    local s={units={},orders={},state={},nextID=100,fail=false,water=false,blocked=false,creates=0,rateCalls=0}
    local function unit(id,def,team,x,z)
        s.units[id]={def=def,team=team,x=x or 2048,y=10,z=z or 2048,los=true}
    end
    unit(1,1,0);unit(2,1,1,2200,2200)
    local Spring={
        GetGaiaTeamID=function()return 0 end,GetTeamAllyTeamID=function(id)return id end,
        ValidUnitID=function(id)return s.units[id]~=nil end,GetUnitIsDead=function()return false end,
        GetUnitTeam=function(id)return s.units[id] and s.units[id].team end,
        GetUnitDefID=function(id)return s.units[id].def end,
        GetUnitIsCloaked=function(id)return s.units[id].cloaked end,
        GetUnitLosState=function(id)return {los=s.units[id].los}end,
        GetUnitPosition=function(id)
            local u=s.units[id];assert(u.los and not u.cloaked,'queried a hidden attacker position')
            return u.x,u.y,u.z
        end,
        GetUnitCollisionVolumeData=function()return 128,9000,128,0,0,0 end,
        GetGroundHeight=function(x,z)return s.water and -500 or 10 end,
        TestMoveOrder=function()return not s.blocked end,
        GetUnitsInRectangle=function(x1,z1,x2,z2)
            local result={}
            for id,u in pairs(s.units)do
                if u.x>=x1 and u.x<=x2 and u.z>=z1 and u.z<=z2 then result[#result+1]=id end
            end
            return result
        end,
        CreateUnit=function(def,x,y,z,facing,team)
            s.creates=s.creates+1
            if s.fail then return end
            s.nextID=s.nextID+1;unit(s.nextID,def,team,x,z);return s.nextID
        end,
        DestroyUnit=function(id)assert(s.units[id].team==0);s.units[id]=nil end,
        GiveOrderToUnit=function(id,cmd,params)
            s.orders[id]=s.orders[id] or {};s.orders[id][cmd]=params
            if cmd~=CMD.FIRE_STATE then s.orders[id].last=cmd end
        end,
        GetUnitTransporter=function(id)return s.units[id] and s.units[id].transport end,
        GetUnitIsTransporting=function(id)
            local result={}
            for passenger,u in pairs(s.units)do if u.transport==id then result[#result+1]=passenger end end
            return result
        end,
        SetUnitNeutral=function()end,SetUnitTooltip=function()end,SetUnitRulesParam=function()end,
    }
    local game={gameSpeed=30,mapSizeX=4096,mapSizeZ=4096}
    s.api=Security.New(Spring,game,defs,names,CMD,config,s.state)
    s.record={uid=1,siteID=40,defID=1,x=2048,z=2048}
    s.live={[1]=s.record}
    function s.hit(frame,rate,damage,attacker,team)
        s.api.Damage(s.record,frame,damage or 10,attacker or 2,team or 1,
            function()s.rateCalls=s.rateCalls+1;return rate or 1 end)
    end
    function s.tick(frame)s.api.Update(frame,s.live)end
    function s.count()local n=0;for _ in pairs(s.state.units)do n=n+1 end;return n end
    function s.reload()s.api=Security.New(Spring,game,defs,names,CMD,config,s.state)end
    return s
end

-- Economic value buys more vehicles; low-value military sites keep both floors.
local s=setup()
assert(#s.api.Plan(s.record,0)==1)
assert(#s.api.Plan(s.record,5)==2)
assert(#s.api.Plan(s.record,12)==4)
s.record.defID=2
local p=s.api.Plan(s.record,0);assert(#p==2 and p[1]==4 and p[2]==3)
p=s.api.Plan(s.record,36);assert(#p==3 and p[1]==4 and p[2]==3 and p[3]==4)
assert(#s.api.Plan(s.record,1e6)==config.maxVehicles)

-- One convoy under sustained damage, deferred creation, staggered exits,
-- saved state on LuaRules reload, and no costly income lookup on every bullet.
s=setup();s.hit(0,12);assert(s.count()==0 and s.creates==0)
for f=1,100 do s.hit(f,12)end
assert(s.rateCalls==1)
for f=15,120,15 do s.tick(f)end
assert(s.count()==4)
for id,u in pairs(s.state.units)do
    assert(s.units[id].team==0 and (u.homeX-2048)^2+(u.homeZ-2048)^2>=160^2)
    assert(s.orders[id].last==CMD.ATTACK and s.orders[id][CMD.ATTACK][1]==2)
end
s.reload();s.hit(200,12);s.tick(210);assert(s.count()==4)

-- Dead guards are replaced only on a later attack after the cooldown.
local guard=next(s.state.units);s.units[guard]=nil;s.api.Remove(guard)
s.hit(300,12);s.tick(315);assert(s.count()==3)
s.hit(2700,12);s.tick(2715);assert(s.count()==4)
s.hit(5400,12);s.tick(5415);assert(s.count()==4)

-- Cloak and LOS loss stop targeting, including the truck's attached gun.
guard=next(s.state.units)
s.units[90]={team=0,transport=guard}
assert(s.api.AllowWeaponTarget(90,2));assert(not s.api.AllowWeaponTarget(90,99))
s.units[2].cloaked=true;s.tick(5430)
assert(s.orders[guard].last==CMD.MOVE and not s.api.AllowWeaponTarget(90,2))
assert(s.orders[90].last==CMD.STOP,'mounted gun must forget the hidden target')
s.units[2].cloaked=false;s.units[2].los=false;s.tick(5445)
assert(not s.api.AllowWeaponTarget(guard,2))
s.units[2].los=true;s.units[2].x=4090;s.tick(5460)
assert(not s.api.AllowWeaponTarget(guard,2))
s.units[2].x=2200;s.units[2].team=2;s.tick(5475)
assert(not s.api.AllowWeaponTarget(guard,2),'captured attacker must not inherit pursuit')

-- Captured security is released, never deleted at stand-down; other guards expire.
s.units[guard].team=1;s.api.Remove(guard);s.tick(9000)
assert(s.units[guard] and s.count()==0 and next(s.state.sites)==nil)
s=setup();s.hit(0);s.tick(15);guard=next(s.state.units)
s.units[90]={team=0,transport=guard};s.tick(3600)
assert(not s.units[guard] and not s.units[90],'stand-down must remove the attached gun too')

-- Failed/blocked deployments retry without consuming the minimum or multiplying it.
s=setup();s.blocked=true;s.hit(0);s.tick(15);assert(s.count()==0)
s.blocked=false;s.fail=true;s.tick(45);assert(s.count()==0)
s.fail=false;s.tick(75);assert(s.count()==1)

-- Ground security never spawns into deep water; the pending response can deploy
-- when a valid shoreline location becomes available.
s=setup();s.water=true;s.hit(0);s.tick(15);assert(s.creates==0)
s.water=false;s.tick(45);assert(s.count()==1)

-- A lethal hit still dispatches its convoy from the ruins. Restoring the same
-- site preserves its force/cooldown, without a new mandatory convoy.
s=setup();s.hit(0,12);s.tick(15);assert(s.count()==1)
s.api.SiteDestroyed(s.record);s.live={}
for f=45,120,15 do s.tick(f)end;assert(s.count()==4)
s.live={[1]=s.record};s.hit(150,12);s.tick(165);assert(s.count()==4)
s.hit(2700,12);for f=2715,2820,15 do s.tick(f)end;assert(s.count()==4)
s=setup();s.hit(0);s.api.SiteDestroyed(s.record);s.live={};s.units[1]=nil
s.tick(15);assert(s.count()==1,'lethal first hit must not cancel the response')

-- Invalid/environmental hits cannot trigger a response; paralysis with positive
-- damage can (it is still an attack). No dependency on attacker coordinates.
for _,damage in ipairs({0,-1,math.huge,0/0})do
    s=setup();s.hit(0,1,damage);assert(next(s.state.sites)==nil)
end
s=setup();s.hit(0,1,10,2,0);assert(next(s.state.sites)==nil)
s.hit(0,1,10,999,1);s.tick(15);assert(s.count()==1)

print('Objective security: value, minimums, cooldown, deployment, visibility, capture, reload and restoration PASS')
