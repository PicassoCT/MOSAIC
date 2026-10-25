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
local CMD={ATTACK=1,MOVE=2,FIRE_STATE=3,STOP=4,GUARD=5}
local function setup()
    local s={units={},orders={},state={},nextID=100,fail=false,water=false,blocked=false,creates=0,rateCalls=0,commandCount=0,
        clearShot=true,rayChecks=0,moveChecks=0,areaQueries=0}
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
        TestMoveOrder=function()
            s.moveChecks=s.moveChecks+1
            return not s.blocked and not (s.failFirstMove and s.moveChecks==1)
        end,
        GetUnitsInRectangle=function(x1,z1,x2,z2)
            s.areaQueries=s.areaQueries+1
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
        GiveOrderToUnit=function(id,cmd,params,options)
            s.commandCount=s.commandCount+1
            s.orders[id]=s.orders[id] or {};s.orders[id][cmd]=params
            if cmd~=CMD.FIRE_STATE then
                if options and options[1]=='shift' then
                    table.insert(s.orders[id].queue,{id=cmd,cmd=cmd,params=params})
                else
                    s.orders[id].last=cmd
                    s.orders[id].queue={{id=cmd,cmd=cmd,params=params}}
                end
            end
        end,
        GetUnitCommands=function(id)
            return s.orders[id] and s.orders[id].queue or {}
        end,
        GetUnitWeaponState=function(id,weapon,key)
            assert(weapon==1 and key=='range')
            return s.units[id].weaponRange or 1024
        end,
        SetUnitWeaponState=function(id,weapon,values)
            assert(weapon==1);s.units[id].weaponRange=values.range
        end,
        SetUnitMaxRange=function(id,range)s.units[id].maxRange=range end,
        GetUnitWeaponHaveFreeLineOfFire=function(id,weapon,target)
            assert(id==90 and weapon==1,'probe the mounted gun, never the marker')
            assert(s.units[target].los and not s.units[target].cloaked,'probed hidden attacker')
            s.rayChecks=s.rayChecks+1;return s.clearShot
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

-- Native movement completes the queued return and begins GUARD. Controller
-- maintenance must not replace that persistent order with another MOVE home.
local resting=setup();resting.units[2].los=false;resting.hit(0);resting.tick(15)
local restingGuard=next(resting.state.units)
table.remove(resting.orders[restingGuard].queue,1)
local before=resting.commandCount
resting.tick(105);resting.reload();resting.tick(195)
assert(resting.orders[restingGuard].queue[1].cmd==CMD.GUARD,
    'a settled guard must not be sent back to its exit every three seconds')
assert(resting.commandCount==before,'unchanged guard orders must persist')
resting.units[2].los=true;resting.tick(210)
assert(resting.orders[restingGuard].queue[1].cmd==CMD.ATTACK)
before=resting.commandCount;resting.tick(300)
assert(resting.commandCount==before,'pursuit must not restart every three seconds')

-- A delayed mounted gun controls the security APC's approach distance, not
-- its dummy marker weapon. Keep the running attack and order the new gun.
resting.units[90]={team=0,transport=restingGuard,weaponRange=450}
resting.tick(390)
assert(resting.units[restingGuard].weaponRange==405)
assert(resting.units[restingGuard].maxRange==405)
assert(resting.orders[90].queue[1].cmd==CMD.ATTACK)
assert(resting.orders[90].queue[1].params[1]==2)
-- Simulate the engine advancing past an interrupted/completed ATTACK.
table.remove(resting.orders[restingGuard].queue,1)
resting.tick(480)
assert(resting.orders[restingGuard].queue[1].cmd==CMD.ATTACK,
    'a still-visible attacker must be reacquired if the attack command ends')
-- UnitTaken is dispatched before the team changes.
resting.api.Remove(restingGuard);resting.units[restingGuard].team=1
assert(resting.units[restingGuard].weaponRange==1024,'capture restores normal truck range')

-- Engine command positions have float precision; an in-progress return must
-- not restart just because its stored coordinates were rounded.
resting=setup();resting.units[2].los=false;resting.hit(0);resting.tick(15)
restingGuard=next(resting.state.units)
resting.orders[restingGuard].queue[1].params[1]=resting.state.units[restingGuard].homeX+0.0001
before=resting.commandCount;resting.tick(105)
assert(resting.commandCount==before,'return movement must survive coordinate rounding')

local function obstructed()
    local case=setup();case.hit(0);case.tick(15)
    local id=next(case.state.units)
    case.units[90]={team=0,transport=id,weaponRange=450}
    case.clearShot=false
    case.moveChecks,case.areaQueries=0,0
    return case,id
end

-- Persistent blockage triggers one bounded sidestep, preserving attack and
-- return orders. Existing movement must survive controller ticks/reloads.
local blocked,truck=obstructed()
blocked.tick(105)
assert(blocked.rayChecks==1 and blocked.orders[truck].queue[1].cmd==CMD.ATTACK)
for frame=120,180,15 do blocked.tick(frame) end
assert(blocked.rayChecks==1,'half-second controller ticks must not add firing-lane probes')
blocked.tick(195)
local queue=blocked.orders[truck].queue
assert(blocked.rayChecks==2 and blocked.moveChecks==1 and blocked.areaQueries==0)
assert(#queue==4 and queue[1].cmd==CMD.MOVE and queue[2].cmd==CMD.ATTACK)
assert(queue[2].params[1]==2 and queue[3].cmd==CMD.MOVE and queue[4].cmd==CMD.GUARD)
assert(blocked.orders[90].queue[1].cmd==CMD.ATTACK,'gun keeps its target during the sidestep')
before=blocked.commandCount;blocked.reload();blocked.tick(285)
assert(blocked.commandCount==before,'active sidestep must not restart')
blocked.clearShot=true;blocked.tick(375)
assert(not blocked.state.units[truck].reposition and blocked.orders[truck].queue[1].cmd==CMD.ATTACK)

-- A completed or timed-out sidestep resumes native attack, instead of getting
-- stuck in another endless MOVE state. No destination search is unbounded.
blocked,truck=obstructed();blocked.tick(105);blocked.tick(195)
table.remove(blocked.orders[truck].queue,1);blocked.tick(285)
assert(not blocked.state.units[truck].reposition and blocked.orders[truck].queue[1].cmd==CMD.ATTACK)
blocked,truck=obstructed();blocked.tick(105);blocked.tick(195);blocked.tick(465)
assert(not blocked.state.units[truck].reposition and blocked.orders[truck].queue[1].cmd==CMD.ATTACK)
blocked,truck=obstructed();blocked.blocked=true;blocked.tick(105);blocked.tick(195)
assert(blocked.moveChecks==2 and blocked.areaQueries==0 and not blocked.state.units[truck].reposition)
assert(blocked.orders[truck].queue[1].cmd==CMD.ATTACK,'unpassable sidesteps must not discard pursuit')
blocked,truck=obstructed();blocked.failFirstMove=true;blocked.tick(105);blocked.tick(195)
assert(blocked.moveChecks==2 and blocked.state.units[truck].reposition,'try the opposite side when the first is blocked')
blocked,truck=obstructed();blocked.water=true;blocked.tick(105);blocked.tick(195)
assert(blocked.moveChecks==0 and not blocked.state.units[truck].reposition,'do not sidestep into water')

-- Motion and a clear shot reset the consecutive-blockage counter.
blocked,truck=obstructed();blocked.tick(105)
blocked.units[truck].x=blocked.units[truck].x+30;blocked.tick(195)
assert(not blocked.state.units[truck].reposition)
blocked.clearShot=true;blocked.tick(285);blocked.clearShot=false;blocked.tick(375)
assert(not blocked.state.units[truck].reposition)
blocked.tick(465);assert(blocked.state.units[truck].reposition)

-- Early updates on target changes cannot multiply ray probes. Loss of sight
-- or cloak cancels maneuvers and clears the mounted gun immediately.
blocked,truck=obstructed();blocked.tick(105);blocked.tick(195)
blocked.units[3]={team=1,x=2200,y=10,z=2200,los=true}
blocked.hit(200,1,10,3,1);blocked.tick(210)
assert(blocked.rayChecks==2 and not blocked.state.units[truck].reposition)
assert(blocked.orders[truck].queue[1].params[1]==3)
blocked.units[3].cloaked=true;blocked.tick(225)
assert(blocked.rayChecks==2 and blocked.orders[90].last==CMD.STOP)
assert(blocked.orders[truck].queue[1].params[1]==blocked.state.units[truck].homeX)
blocked,truck=obstructed();blocked.units[2].x=4000;blocked.tick(105);blocked.tick(195)
assert(blocked.rayChecks==0 and blocked.moveChecks==0,'distant pursuit does not probe firing lanes')
blocked,truck=obstructed();blocked.tick(105);blocked.tick(195)
blocked.units[2].los=false;blocked.tick(210)
assert(not blocked.state.units[truck].reposition and blocked.rayChecks==2)
blocked,truck=obstructed();blocked.tick(105);blocked.tick(195);blocked.units[90]=nil;blocked.tick(285)
assert(not blocked.state.units[truck].reposition,'missing gun cancels its recovery')

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
    local q=s.orders[id].queue
    assert(#q==3 and q[2].cmd==CMD.MOVE and q[2].params[1]==u.homeX)
    assert(q[3].cmd==CMD.GUARD and q[3].params[1]==s.record.uid)
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
assert(s.orders[guard].queue[2].cmd==CMD.GUARD)
assert(s.orders[90].last==CMD.STOP,'mounted gun must forget the hidden target')
s.units[2].cloaked=false;s.units[2].los=false;s.tick(5445)
assert(not s.api.AllowWeaponTarget(guard,2))
s.units[2].los=true;s.units[2].x=4090;s.tick(5460)
assert(s.api.AllowWeaponTarget(guard,2),'visible attackers beyond 1200 must still be pursued')
assert(s.orders[guard].last==CMD.ATTACK and s.orders[90].last==CMD.ATTACK)
assert(s.orders[guard].queue[2].cmd==CMD.MOVE and s.orders[guard].queue[3].cmd==CMD.GUARD)
s.units[2].x=2200;s.units[2].team=2;s.tick(5475)
assert(not s.api.AllowWeaponTarget(guard,2),'captured attacker must not inherit pursuit')

-- Captured security is released, never deleted at stand-down; other guards expire.
s.units[guard].team=1;s.api.Remove(guard);s.tick(9000)
assert(s.units[guard] and s.count()==0 and next(s.state.sites)==nil)
s=setup();s.hit(0);s.tick(15);guard=next(s.state.units)
s.units[90]={team=0,transport=guard};s.tick(3600)
assert(not s.units[guard] and not s.units[90],'stand-down must remove the attached gun too')

-- A distant convoy comes home before stand-down cleanup. Reload keeps the
-- return alive; renewed attacks can reactivate it without duplicating guards.
s=setup();s.hit(0);s.tick(15);guard=next(s.state.units)
local home=s.state.units[guard]
s.units[guard].x=4000;s.units[guard].z=4000
s.units[90]={team=0,transport=guard}
s.tick(3600)
assert(s.units[guard] and s.orders[guard].last==CMD.MOVE)
assert(s.orders[90].last==CMD.STOP and not s.api.AllowWeaponTarget(90,2))
s.reload();s.tick(3700)
assert(s.units[guard] and s.state.sites[40],'returning force must stay tracked')
s.hit(3710);s.tick(3720)
assert(s.count()==1 and s.orders[guard].last==CMD.ATTACK)
s.tick(7310)
assert(s.units[guard] and s.orders[guard].last==CMD.MOVE)
s.units[guard].x,s.units[guard].z=home.homeX,home.homeZ
s.tick(7325)
assert(not s.units[guard] and not s.units[90] and not s.state.sites[40])

-- Target death returns immediately; a destroyed objective has no GUARD target.
s=setup();s.hit(0);s.tick(15);guard=next(s.state.units)
s.units[2]=nil;s.tick(30)
assert(s.orders[guard].last==CMD.MOVE and s.orders[guard].queue[2].cmd==CMD.GUARD)
s.api.SiteDestroyed(s.record);s.live={};s.units[1]=nil;s.tick(120)
assert(s.orders[guard].last==CMD.MOVE and #s.orders[guard].queue==1)

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
