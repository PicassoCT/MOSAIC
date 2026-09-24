-- Lua 5.1+: exercise the real gadget through Spring call-ins.
local function world()
    local w={frame=0,units={},next=100,orders={},reveals=0,blocked=false}
    GG={GameConfig={raid={revealGraphLifeTimeFrames=9000}}}
    Game={mapSizeX=10000,mapSizeZ=10000}
    CMD={STOP=0,MOVE=10,ATTACK=20,FIRE_STATE=45,MOVE_STATE=50,CLOAK=95,SELFD=65,LOAD_UNITS=75}
    UnitDefs={[1]={name='operative',humanName='Operative',speed=60,maxWeaponRange=0},
        [2]={name='safehouse',humanName='Safehouse',speed=0,maxWeaponRange=0},
        [3]={name='deaddropicon',speed=0,maxWeaponRange=0},
        [4]={name='turret',speed=0,maxWeaponRange=600},[5]={name='house',speed=0}}
    UnitDefNames={deaddropicon={id=3}}
    local function list(predicate)
        local out={};for id,u in pairs(w.units) do if not u.dead and predicate(id,u) then out[#out+1]=id end end
        table.sort(out);return out
    end
    function w:add(id,def,team,x,z,builder)
        self.units[id]={def=def,team=team,x=x,y=0,z=z,hp=400,maxHP=750,rules={},cloak=false,experience=2}
        if self.g then self.g:UnitCreated(id,def,team,builder) end
        return id
    end
    function w:tick(frame) self.frame=frame;self.g:GameFrame(frame) end
    function w:kill(id,attacker)
        local u=self.units[id];local a=attacker and self.units[attacker]
        u.dead=true
        self.g:UnitDestroyed(id,u.def,u.team,attacker,a and a.def,a and a.team)
    end
    function w:hit(id,attacker,damage,direct)
        local u,a=self.units[id],self.units[attacker]
        a.target=direct and id or nil
        local amount=self.g:UnitPreDamaged(id,u.def,u.team,damage,false,1,nil,attacker,a.def,a.team)
        u.hp=u.hp-amount
        if u.hp<=0 then self:kill(id,attacker) end
    end
    function w:runner()
        for id in pairs(GG.BetrayalRunners) do return id end
    end
    function w:drop()
        for id,u in pairs(self.units) do if not u.dead and u.rules.betrayal_drop==1 then return id end end
    end
    Spring={
        GetGaiaTeamID=function() return 0 end,GetGameFrame=function() return w.frame end,
        GetAllyTeamList=function() return {0,1,2} end,GetTeamList=function() return {0,1,2} end,
        AreTeamsAllied=function(a,b) return a==b end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return not w.units[id] or w.units[id].dead end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam=function(id) return w.units[id] and w.units[id].team end,
        GetUnitPosition=function(id) local u=w.units[id];if u then return u.x,u.y,u.z end end,
        GetUnitHealth=function(id) local u=w.units[id];if u then return u.hp,u.maxHP,0,0,u.built or 1 end end,
        GetUnitExperience=function(id) return w.units[id].experience end,
        GetUnitBuildFacing=function() return 0 end,
        GetUnitTransporter=function(id) return w.units[id].transporter end,
        GetUnitCurrentCommand=function(id) local t=w.units[id].target;if t then return CMD.ATTACK,0,0,t end end,
        GetAllUnits=function() return list(function() return true end) end,
        GetTeamUnits=function(t) return list(function(id,u) return u.team==t end) end,
        GetUnitsInCylinder=function(x,z,r) return list(function(id,u) return (x-u.x)^2+(z-u.z)^2<=r*r end) end,
        GetGroundHeight=function() return 0 end,TestMoveOrder=function() return not w.blocked end,
        SetUnitCloak=function(id,b) w.units[id].cloak=b end,
        SetUnitStealth=function(id,b) w.units[id].stealth=b end,
        SetUnitAlwaysVisible=function(id,b) w.units[id].visible=b end,
        SetUnitLosMask=function(id,a,b) w.units[id].losMask=b end,
        SetUnitLosState=function(id,a,b) w.units[id].los=b end,
        SetUnitRulesParam=function(id,key,v) w.units[id].rules[key]=v end,
        SetUnitTooltip=function(id,t) w.units[id].tooltip=t end,
        SetUnitHealth=function(id,t) w.units[id].hp=t.health end,
        SetUnitExperience=function(id,v) w.units[id].experience=v end,
        GiveOrderToUnit=function(id,c,p)
            local u=w.units[id]
            assert(w.g:AllowCommand(id,u.def,u.team,c,p),'internal escape order blocked')
            w.orders[id]={cmd=c,p=p}
        end,
        CreateUnit=function(def,x,y,z,f,team)
            if w.failCreate then return nil end
            if type(def)=='string' then def=UnitDefNames[def].id end
            w.next=w.next+1;w:add(w.next,def,team,x,z);return w.next
        end,
        DestroyUnit=function(id) w:kill(id) end,
    }
    VFS={Include=function(p) if p=='luarules/configs/betrayal.lua' then return dofile(p) end end}
    gadgetHandler={IsSyncedCode=function() return true end}
    function getOperativeTypeTable() return {[1]=true} end
    function getSafeHouseTypeTable() return {[2]=true} end
    function getInterrogateAbleTypeTable() return {[1]=true,[2]=true} end
    -- Load the production graph helpers, not another implementation of the graph.
    local f=assert(io.open('scripts/lib_mosaic.lua'));local source=f:read('*a');f:close()
    local start=assert(source:find('    function initalizeInheritanceManagement',1,true))
    local stop=assert(source:find('    function infectWanderlostNearby',start,true))
    assert(loadstring(source:sub(start,stop-1)))()
    start=assert(source:find('    function getChildrenOfUnit',stop,true))
    stop=assert(source:find('    function GetUnitDefRealRadius',start,true))
    assert(loadstring(source:sub(start,stop-1)))()
    gadget={};dofile('luarules/gadgets/game_treasonAndBetrayal.lua');w.g=gadget;gadget:Initialize()
    w:add(10,1,1,2000,2000)
    w:add(11,2,1,2200,2000,10)
    w:add(12,1,1,2300,2000,11)
    w:add(13,2,1,2500,2000,12)
    w:add(20,1,2,5000,2000)
    w:add(21,2,2,5200,2000,20)
    w:add(30,4,1,2000,2200)
    return w
end
local function eq(a,b,msg) assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
local w=world()
w:hit(12,30,10,false);w:tick(15);eq(w:runner(),nil,'splash must not defect')
w:hit(12,30,50,true);w:tick(30)
local runner=assert(w:runner());local u=w.units[runner]
eq(u.team,2);eq(u.hp,340,'injuries preserved');eq(u.experience,2)
eq(u.visible,true);eq(u.los,15);eq(u.cloak,false)
assert(w.units[12].dead);assert(not getChildrenOfUnit(1,11)[12],'old identity stays in graph')
assert(not w.g:AllowUnitCloak(runner))
assert(not w.g:AllowCommand(runner,1,2,CMD.CLOAK,{1}))
assert(not w.g:AllowCommand(runner,1,2,CMD.MOVE,{1,0,1}))
assert(not w.g:AllowUnitTransport(44,4,2,runner))
assert(not w.g:AllowCommand(44,4,2,CMD.LOAD_UNITS,{runner}))
assert(not w.g:AllowUnitTransfer(runner))
assert((u.x-2300)^2+(u.z-2000)^2>=600^2-0.1,'one escape away from execution point')
eq(GG.RevealedLocations,nil,'no intel before rendezvous')
-- A mobile operator can intercept the runner without exposing the safehouse.
w.units[20].x,w.units[20].z=u.x,u.z
w:tick(45);w:tick(90);eq(GG.RevealedLocations,nil,'debrief takes time')
w:tick(105);eq(w:runner(),nil);eq(u.rules.betrayal_delivered,1)
local loc=GG.RevealedLocations[1];assert(loc.revealedUnits[11].boolIsParent)
eq(loc.revealedUnits[13].boolIsParent,false);eq(loc.revealedUnits[10],nil,'no recursive graph reveal')
assert(not w.g:AllowUnitCloak(runner),'delivery must not restore cloak')
assert(w.g:AllowCommand(runner,1,2,CMD.MOVE,{1,0,1}),'delivered operative is usable')
w:kill(runner,30);eq(w:drop(),nil,'delivered intel cannot duplicate')

w=world();w:hit(12,30,50,true);w:tick(15);runner=assert(w:runner());w:kill(runner,30)
local drop=assert(w:drop());eq(GG.RevealedLocations,nil)
u=w.units[drop];assert((u.x-2300)^2+(u.z-2000)^2>=300^2,'backup must escape execution trap')
w.units[20].x,w.units[20].z=u.x,u.z;w:tick(30)
assert(w.units[drop].dead);assert(GG.RevealedLocations[1].revealedUnits[11])

w=world();w:hit(12,30,500,true);drop=assert(w:drop());eq(w:runner(),nil,'fatal hit cannot resurrect victim')
u=w.units[drop];w.units[10].x,w.units[10].z=u.x,u.z;w:tick(15)
eq(GG.RevealedLocations,nil,'former allies suppress package');assert(u.dead)

w=world();assert(not w.g:AllowCommand(12,1,1,CMD.SELFD,{}));w:tick(75)
eq(w:runner(),nil);w.g:AllowCommand(12,1,1,CMD.SELFD,{});w:tick(150)
eq(w:runner(),nil,'cancelled order must not defect');assert(not w.units[12].dead)
w.g:AllowCommand(12,1,1,CMD.SELFD,{});w:tick(300);assert(w:runner(),'Ctrl+D must trigger defection')

w=world();w.g:AllowCommand(11,2,1,CMD.SELFD,{});w:tick(150)
assert(w.units[11].dead);assert(w:drop(),'safehouse demolition must preserve connections')

w=world();w:kill(20);w:kill(21);w:hit(12,30,50,true);w:tick(15)
eq(w:runner(),nil);eq(w.units[12].rules.betrayal_pending,1)
w:add(25,1,2,5000,2000);w:tick(30);assert(w:runner(),'late recipient should permit escape')

w=world();w.blocked=true;w:hit(12,30,50,true);w:tick(15);runner=assert(w:runner())
eq(w.units[runner].x,2300,'no illegal teleport when every tested point blocked')
w:tick(930);assert(w:drop(),'stuck runner leaves recoverable evidence')

w=world();w.failCreate=true;w:hit(12,30,500,true)
assert(GG.RevealedLocations[1],'unit cap must not erase the evidence')

w=world();w:hit(12,30,500,true);drop=assert(w:drop());w:kill(13)
w:add(13,1,1,2600,2400) -- engine reused the dead child's ID
u=w.units[drop];w.units[20].x,w.units[20].z=u.x,u.z;w:tick(15)
eq(GG.RevealedLocations[1].revealedUnits[13],nil,'recycled IDs cannot fabricate contacts')
-- The containing civilian building can kill an attached safehouse indirectly.
w=world();w:add(40,5,0,2200,2000);GG.houseHasSafeHouseTable={[40]=11}
w:hit(40,30,100,true);w:kill(11)
drop=assert(w:drop(),'occupied-building execution loses its attacker in safehouse death')
u=w.units[drop];w.units[20].x,w.units[20].z=u.x,u.z;w:tick(15)
assert(GG.RevealedLocations[1].revealedUnits[10])
assert(GG.RevealedLocations[1].revealedUnits[12])

-- Destroyed rendezvous targets are replaced; a receiver has to remain for the debrief.
w=world();w:hit(12,30,50,true);w:tick(15);runner=assert(w:runner())
u=w.units[runner];local originalRecipient=u.rules.betrayal_recipient
w:kill(originalRecipient);w:tick(30)
assert(GG.BetrayalRunners[runner].recipient~=originalRecipient)
w.units[21].x,w.units[21].z=u.x,u.z
w:tick(45);w:tick(105);eq(u.rules.betrayal_delivered,1)

print('PASS betrayal: execution, cancellation, escape, rendezvous, death, evidence, visibility, graph identity')
