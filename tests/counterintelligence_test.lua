-- Run from the repository root with Lua 5.1+. Exercise the real three gadgets
-- together, including lifecycle callbacks, command validation and inventories.
local function world()
    local w={units={},gadgets={},frame=0,next=100,messages={},money={[1]=100000,[2]=100000,[3]=100000},
        supply={[1]=100000,[2]=100000,[3]=100000},orders={}}
    GG={GameConfig={espionage={raids={revealedGraphLifetimeFrames=9000}}}}
    Game={gameSpeed=30,mapSizeX=10000,mapSizeZ=10000}
    CMD={STOP=0,INSERT=1,MOVE=10,ATTACK=20,REPAIR=40,FIRE_STATE=45,MOVE_STATE=50,SELFD=65,
        LOAD_UNITS=75,ONOFF=85,CLOAK=95}
    CMDTYPE={ICON=0,ICON_UNIT=12}
    UnitDefs={
        [1]={name='operative',humanName='Operative',speed=60,buildOptions={6},buildSpeed=1},
        [2]={name='safehouse',humanName='Safehouse',speed=0,buildOptions={1,3}},
        [3]={name='robot',speed=60},[4]={name='factory',speed=0,buildOptions={3}},
        [5]={name='doubleagent',modCategories={notarget=true}},
        [6]={name='ground_stickybomb',metalCost=300,energyCost=300,buildTime=1},
        [7]={name='deaddropicon',modCategories={notarget=true}},[8]={name='house',speed=0},
        [9]={name='civilian',speed=60},[10]={name='nimrod',speed=0,buildOptions={3}},
        [11]={name='effect',customParams={baseclass='Abstract'}},
    }
    UnitDefNames={operativeasset={id=1},protagonsafehouse={id=2},protagonassembly={id=4},
        doubleagent={id=5},ground_stickybomb={id=6},deaddropicon={id=7},nimrod={id=10}}
    local function units(predicate)
        local out={};for id,u in pairs(w.units) do if not u.dead and predicate(id,u) then out[#out+1]=id end end
        table.sort(out);return out
    end
    function w:add(id,def,team,x,z,builder,built)
        self.units[id]={def=def,team=team,x=x or 1000,y=0,z=z or 1000,hp=100,maxhp=100,built=built or 1,
            experience=2,rules={},visibility={},descs={},cloak=false,rotation={0,0.5,0},queue={}}
        for _,g in ipairs(self.gadgets) do if g.UnitCreated then g:UnitCreated(id,def,team,builder) end end
        return id
    end
    function w:kill(id,attackerTeam)
        local u=assert(self.units[id]);u.dead=true
        for _,g in ipairs(self.gadgets) do if g.UnitDestroyed then g:UnitDestroyed(id,u.def,u.team,nil,nil,attackerTeam) end end
        self.units[id]=nil
    end
    function w:issue(id,cmd,p)
        local u=assert(self.units[id]);p=p or {}
        for _,g in ipairs(self.gadgets) do
            if g.AllowCommand and g:AllowCommand(id,u.def,u.team,cmd,p,{})==false then return false end
        end
        u.command={id=cmd,p=p};self.orders[#self.orders+1]={id=id,cmd=cmd,p=p};return true
    end
    function w:tick(count)
        for i=1,count do
            self.frame=self.frame+1
            for _,id in ipairs(units(function(_,u) return u.command~=nil end)) do
                local u=self.units[id];local cmd=u.command
                local used,done=self.ci:CommandFallback(id,u.def,u.team,cmd.id,cmd.p)
                if used and done then u.command=nil end
            end
            for _,g in ipairs(self.gadgets) do if g.GameFrame then g:GameFrame(self.frame) end end
        end
    end
    function w:count(def) return #units(function(_,u) return u.def==def end) end
    function w:find(def,team,x)
        for _,id in ipairs(units(function(_,u) return u.def==def and u.team==team and (not x or x==u.x) end)) do return id end
    end
    function w:investigate(actor,target,frames)
        assert(self:issue(actor,CMD_INVESTIGATE,{target}),'investigation order rejected')
        self:tick(frames or 900)
    end
    Spring={
        GetGameFrame=function() return w.frame end,GetGaiaTeamID=function() return 0 end,
        GetTeamList=function() return {0,1,2,3} end,
        GetTeamInfo=function(id) return id,0,false,false,'side',id end,
        GetAllyTeamList=function() return {0,1,2,3} end,
        AreTeamsAllied=function(a,b) return a==b end,
        GetAllUnits=function() return units(function() return true end) end,
        GetTeamUnits=function(t) return units(function(_,u) return u.team==t end) end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam=function(id) return w.units[id] and w.units[id].team end,
        GetUnitAllyTeam=function(id) return w.units[id].team end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return w.units[id] and (w.units[id].dead or false) end,
        GetUnitPosition=function(id) local u=w.units[id];if u then return u.x,u.y,u.z end end,
        GetUnitHealth=function(id) local u=w.units[id];if u then return u.hp,u.maxhp,u.paralyze or 0,0,u.built end end,
        GetUnitExperience=function(id) return w.units[id].experience end,
        GetUnitBuildFacing=function() return 0 end,
        GetUnitRotation=function(id) return unpack(w.units[id].rotation) end,
        SetUnitRotation=function(id,x,y,z) w.units[id].rotation={x,y,z} end,
        GetUnitRadius=function() return 15 end,
        GetUnitIsStunned=function(id) local u=w.units[id];return u.stunned,false,u.built<1 end,
        GetUnitTransporter=function(id) return w.units[id].transport end,
        GetUnitLosState=function(id) return {los=not w.units[id].hidden} end,
        GetUnitRulesParam=function(id,key) return w.units[id] and w.units[id].rules[key] end,
        SetUnitRulesParam=function(id,key,value,vis) w.units[id].rules[key]=value;w.units[id].visibility[key]=vis end,
        GetUnitCommands=function(id) return w.units[id].queue end,
        GetUnitCurrentCommand=function(id)
            local c=w.units[id] and w.units[id].command
            if c then return c.id,0,1,unpack(c.p) end
        end,
        GiveOrderToUnit=function(id,cmd,p) return w:issue(id,cmd,p) end,
        SetUnitMoveGoal=function(id,x,y,z) w.units[id].goal={x,y,z} end,
        ClearUnitGoal=function(id) w.units[id].goal=nil end,
        SetUnitHealth=function(id,s)
            local u=w.units[id];u.hp=s.health or u.hp;u.paralyze=s.paralyze or u.paralyze;u.built=s.build or u.built
        end,
        SetUnitExperience=function(id,v) w.units[id].experience=v end,
        SetUnitCloak=function(id,v) w.units[id].cloak=v end,
        SetUnitStealth=function() end,SetUnitAlwaysVisible=function() end,
        SetUnitLosMask=function() end,SetUnitLosState=function() end,
        SetUnitTooltip=function(id,text) w.units[id].tooltip=text end,
        SetUnitBlocking=function() end,
        GetUnitsInCylinder=function(x,z,r) return units(function(_,u) return (x-u.x)^2+(z-u.z)^2<=r*r end) end,
        GetGroundHeight=function() return 0 end,TestMoveOrder=function() return true end,
        GetUnitCollisionVolumeData=function() return 100,100,100,0,0,0 end,
        FindUnitCmdDesc=function(id,cmd) return w.units[id].descs[cmd] and cmd end,
        InsertUnitCmdDesc=function(id,desc) w.units[id].descs[desc.id]=desc end,
        EditUnitCmdDesc=function(id,cmd,desc) for k,v in pairs(desc) do w.units[id].descs[cmd][k]=v end end,
        RemoveUnitCmdDesc=function(id,cmd) w.units[id].descs[cmd]=nil end,
        SendMessageToTeam=function(team,text) w.messages[#w.messages+1]={team=team,text=text} end,
        AddTeamResource=function(team,key,amount)
            local t=key=='metal' and w.money or w.supply;t[team]=t[team]+amount
        end,
        UseUnitResource=function(id,cost)
            local team=w.units[id].team
            if w.money[team]<cost.m or w.supply[team]<cost.e then return false end
            w.money[team]=w.money[team]-cost.m;w.supply[team]=w.supply[team]-cost.e;return true
        end,
        CreateUnit=function(def,x,y,z,facing,team,built,flatten,forced,builder)
            if type(def)=='string' then def=assert(UnitDefNames[def],def).id end
            if w.failDef==def or w.failTeam==team then return nil end
            for _,g in ipairs(w.gadgets) do
                if g.AllowUnitCreation and g:AllowUnitCreation(def,builder,team)==false then return nil end
            end
            w.next=w.next+1;w:add(w.next,def,team,x,z,builder,built and 0.1 or 1);w.units[w.next].y=y;return w.next
        end,
        DestroyUnit=function(id) w:kill(id) end,
        MoveCtrl={Enable=function(id) assert(w.units[id]) end,
            SetPosition=function(id,x,y,z) local u=w.units[id];u.x,u.y,u.z=x,y,z end},
    }
    VFS={Include=function(path)
        if path=='scripts/lib_UnitScript.lua' or path=='scripts/lib_mosaic.lua' then return end
        return dofile(path)
    end}
    gadgetHandler={IsSyncedCode=function() return true end,RegisterCMDID=function() end}
    function getOperativeTypeTable() return {[1]=true} end
    function getSafeHouseTypeTable() return {[2]=true} end
    function getHouseTypeTable() return {[8]=true} end
    function getInterrogateAbleTypeTable() return {[1]=true,[2]=true,[4]=true} end
    local f=assert(io.open('scripts/lib_mosaic.lua'));local source=f:read('*a');f:close()
    local a=assert(source:find('    function initalizeInheritanceManagement',1,true))
    local b=assert(source:find('    function infectWanderlostNearby',a,true))
    assert(loadstring(source:sub(a,b-1)))()
    a=assert(source:find('    function getChildrenOfUnit',b,true))
    b=assert(source:find('    function GetUnitDefRealRadius',a,true))
    assert(loadstring(source:sub(a,b-1)))()
    for _,name in ipairs({'game_counterintelligence','game_treasonAndBetrayal','game_sticky_bombs'}) do
        gadget={};dofile('luarules/gadgets/'..name..'.lua');w.gadgets[#w.gadgets+1]=gadget
    end
    w.ci,w.betrayal,w.bombs=unpack(w.gadgets)
    for _,g in ipairs(w.gadgets) do g:Initialize() end
    return w
end
local function eq(a,b,message) assert(a==b,(message or '')..': '..tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..b) end
local function setup()
    local w=world()
    w:add(10,2,1);w:add(11,1,1,1005,1000,10);w:add(12,4,1,1010,1000,10)
    w:add(13,3,1,1015,1000,12);w:add(14,1,1,1000,1000)
    w:add(20,1,2,2500,1000);w:add(30,1,3,2500,1500)
    return w
end

local w=setup()
assert(GG.Counterintelligence.Register(10,2));w:tick(15)
eq(w:count(5),1,'one icon for the whole existing network')
w:add(15,3,1,1020,1000,12,0.5);w:add(16,11,1,1025,1000,12)
w.units[15].built=1;w:tick(15)
eq(w:count(5),1,'completed last product never needs another build or another icon')
local icon=GG.DoubleAgents[10]
eq(w.units[icon].x,1000,'marker world coordinates');eq(w.units[icon].y,64)
assert(not w:issue(10,CMD_INVESTIGATE,{11}),'safehouses cannot investigate')
assert(not w:issue(12,CMD_INVESTIGATE,{11}),'factories cannot investigate')
assert(not w:issue(11,CMD_INVESTIGATE,{11}),'no self investigation')
assert(not w:issue(14,CMD_INVESTIGATE,{20}),'no probing arbitrary enemy operatives')
assert(not w:issue(14,CMD_INVESTIGATE,{0/0}),'reject malformed target')
w.units[11].queue={{id=CMD.ATTACK,p={20}}};w.units[11].hp=73
w:issue(11,CMD_STICKY_BUILD);w:tick(30)
eq(w.units[11].rules.sticky_bombs,1,'bomb ready before conversion')
w:issue(icon,CMD_ACTIVATE_NETWORK)
eq(w:count(5),0,'successful activation consumes the sole trigger')
eq(w:count(6),0,'ownership replacement never drops explosives')
assert(not w.units[10] and not w.units[11] and not w.units[13] and not w.units[15])
assert(w.units[16],'abstract effects are excluded')
local agent=w:find(1,2,1005)
eq(w.units[agent].hp,73);eq(w.units[agent].experience,2);eq(w.units[agent].rules.sticky_bombs,1)
eq(#w.units[agent].queue,0,'old combat/production orders are not copied')

w=setup();local m2,m3=w.money[2],w.money[3]
w:investigate(14,11,899);near(w.money[2],m2)
w:tick(1);near(w.money[2],m2+250);near(w.money[3],m3+250)
near(w.money[1],100000-300);eq(w:count(7),0,'false suspicion does not create evidence or a runner')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
icon=GG.DoubleAgents[10];local description=w.units[icon].descs[CMD_ACTIVATE_NETWORK].tooltip
w:investigate(14,10)
assert(GG.Counterintelligence.IsProductionDisabled(10) and GG.Counterintelligence.IsProductionDisabled(11))
assert(GG.Counterintelligence.IsProductionDisabled(12) and GG.Counterintelligence.IsProductionDisabled(13))
eq(GG.DoubleAgents[10],icon,'silent neutralization keeps handler marker')
eq(w.units[icon].descs[CMD_ACTIVATE_NETWORK].tooltip,description,'no status disclosure through tooltip')
for _,msg in ipairs(w.messages) do eq(msg.team,1,'no enemy notification') end
assert(not w:issue(10,-1));assert(not w:issue(11,CMD_STICKY_BUILD))
assert(not w.ci:AllowUnitCreation(3,12),'script-built products cannot bypass shutdown')
w:issue(icon,CMD_ACTIVATE_NETWORK)
eq(w.units[10].team,1);eq(w.units[13].team,1,'disabled signal cannot steal units')
w:investigate(14,11);w:tick(1)
assert(next(GG.BetrayalRunners),'spending a disabled signal does not make remaining guilty agents innocent')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15);icon=GG.DoubleAgents[10]
w:issue(11,CMD_STICKY_BUILD);w:tick(30)
w:investigate(14,11);w:tick(1)
local runner;for id in pairs(GG.BetrayalRunners) do runner=id end
assert(runner,'correct operative suspicion enters the real runner mechanic')
eq(w.units[runner].team,2,'runner seeks its actual handler, not arbitrary third party')
eq(w.units[runner].rules.sticky_bombs,1,'runner retains carried inventory')
eq(w:count(6),0,'runner replacement does not detonate bombs')
eq(w.units[runner].rules.ci_production_disabled,1,'burned operative stays unable to build')
eq(GG.DoubleAgents[10],icon)
assert(not w.betrayal:AllowUnitCloak(runner))

w=setup();GG.Counterintelligence.Register(12,2);w:tick(15)
local money,supply=w.money[1],w.supply[1]
w:investigate(14,12,2699);assert(GG.DoubleAgents[12],'factory cleanup is not instant')
w:tick(1);near(w.money[1],money-2000);near(w.supply[1],supply-1000)
assert(not GG.DoubleAgents[12] and not GG.Counterintelligence.IsProductionDisabled(12))
assert(not GG.Counterintelligence.Register(12,2),'secured factory loses backdoor ability')
w:add(15,3,1,1020,1000,12);GG.Counterintelligence.Register(10,2);w:tick(15)
w:issue(GG.DoubleAgents[10],CMD_ACTIVATE_NETWORK)
eq(w.units[12].team,1);eq(w.units[13].team,1);eq(w.units[15].team,1,'secured production stays outside parent hijack')

w=setup();GG.Counterintelligence.Register(12,2);w:tick(15)
w:issue(GG.DoubleAgents[12],CMD_ACTIVATE_NETWORK)
local factory=w:find(4,2,1010);assert(factory)
w:investigate(14,factory,2700)
assert(w:find(4,1,1010) and w:find(3,1,1015),'expensive cleanup restores captured factory and its products')
eq(w:count(5),0)

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
w:issue(GG.DoubleAgents[10],CMD_ACTIVATE_NETWORK)
factory=w:find(4,2,1010);assert(factory)
w:investigate(14,factory,2700)
assert(w:find(4,1,1010) and w:find(3,1,1015),'recover a factory hijacked through an ancestor safehouse')
assert(w:find(2,2),'recovering one factory does not recover the whole enemy-held network')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
w:issue(GG.DoubleAgents[10],CMD_ACTIVATE_NETWORK)
factory=w:find(4,2,1010);w.units[factory].team=3;w.ci:UnitGiven(factory)
assert(not w:issue(14,CMD_INVESTIGATE,{factory}),'factory recovery cannot target a subsequent third-party owner')

w=setup();w.failDef=5;GG.Counterintelligence.Register(10,2);w:tick(30)
eq(w:count(5),0);w.failDef=nil;w:tick(15);assert(GG.DoubleAgents[10],'marker creation retries safely')
w.failTeam=2;icon=GG.DoubleAgents[10];w:issue(icon,CMD_ACTIVATE_NETWORK)
assert(w.units[10] and w.units[11] and w.units[13],'unit cap preserves original units')
w.failTeam=nil;w:issue(icon,CMD_ACTIVATE_NETWORK);assert(not w.units[10])

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15);w:kill(10)
eq(w:count(5),0,'hub death cleans marker');eq(GG.DoubleAgents[10],nil)
w:add(10,2,1);assert(GG.Counterintelligence.Register(10,2));w:tick(15)
assert(GG.DoubleAgents[10],'recycled IDs do not inherit stale records')
w:issue(GG.DoubleAgents[10],CMD_ACTIVATE_NETWORK)
eq(w.units[11].team,1,'recycled hub does not inherit former production roster')
w:investigate(14,11);w:tick(1)
assert(next(GG.BetrayalRunners),'destroyed hub does not make its surviving spies innocent')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15);w:kill(10,2)
eq(w:count(5),0)
eq(w:count(7),0,'enemy bombing does not fabricate an execution dead drop')
eq(next(GG.BetrayalRunners),nil,'bombing a hub does not start runners')
eq(w.units[11].rules.betrayal_pending,nil,'bombing a hub does not expose its recruits')
eq(w.units[11].command,nil,'bombing a hub does not change recruit orders')
eq(#w.messages,0,'bombing a hub does not announce compromised recruits')
assert(GG.Counterintelligence.Register(12,2));w:tick(15)
eq(w:count(5),0,'re-registering an orphan does not create a successor channel')
assert(not GG.Counterintelligence.IsProductionDisabled(12),'hub loss does not automatically shut down production')
w:investigate(14,12,2700)
assert(w.units[12].rules.ci_secured==1 and w.units[13].rules.ci_secured==1,'orphan machinery remains cleanable')
eq(w:count(5),0,'cleanup creates no successor trigger')
w:investigate(14,11);w:tick(1);assert(next(GG.BetrayalRunners))

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
w:investigate(14,10);w:kill(10)
assert(GG.Counterintelligence.IsProductionDisabled(12),'destroying a burned hub does not restore production')
w:investigate(14,11);w:tick(1);assert(next(GG.BetrayalRunners),'burned orphan spies remain guilty')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15);w:kill(10)
w:add(15,3,1,1020,1000,12);w:kill(12)
eq(w:count(5),0,'orphan production does not create new control icons')
w:kill(11);w:add(11,1,1,1005,1000)
local beforeEnemy=w.money[2];w:investigate(14,11);near(w.money[2],beforeEnemy+250,'recycled spoke ID does not inherit guilt')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15);icon=GG.DoubleAgents[10]
GG.Counterintelligence.BeginMorph(10);w:kill(10);w:add(10,10,1);GG.Counterintelligence.EndMorph(10,10)
eq(GG.DoubleAgents[10],icon,'same-ID morph preserves compromise')
w:issue(icon,CMD_ACTIVATE_NETWORK);assert(w:find(10,2) and not w.units[11],'morphed hub keeps earlier roster')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
GG.Counterintelligence.BeginMorph(10);w:kill(10);w:add(10,10,1);GG.Counterintelligence.EndMorph(10,10)
w:investigate(14,10,2700)
assert(GG.Counterintelligence.IsProductionDisabled(11),'factory software repair does not reset historical human loyalty')
assert(not GG.Counterintelligence.IsProductionDisabled(10),'factory itself can resume production')
w:investigate(14,11);w:tick(1);assert(next(GG.BetrayalRunners),'historical human sleeper is still discoverable')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
w.units[13].team=3;w.ci:UnitGiven(13)
w:issue(GG.DoubleAgents[10],CMD_ACTIVATE_NETWORK)
eq(w.units[13].team,3,'hijack cannot steal a product from an unrelated current employer')

w=setup();GG.Counterintelligence.Register(10,2);w:tick(15)
w:investigate(14,10)
assert(not w:issue(12,CMD.INSERT,{0,CMD.ONOFF,0,1}),'insert cannot reactivate a burned factory')
w:add(15,3,1,1020,1000,12,0.2)
assert(not w.ci:AllowUnitBuildStep(14,1,15,3,0.1),'outside assistance cannot complete a burned hub product')
local source=assert(io.open('luarules/gadgets/unit_morph.lua')):read('*a')
local start=assert(source:find('local function UpdateMorph(unitID, morphData)',1,true))
local stop=assert(source:find('\nend',start,true))
local update=assert(loadstring(source:sub(start,stop+3)..'\nreturn UpdateMorph'))()
local morph={progress=0,increment=1,def={resTable={m=50,e=50}}}
local before=w.money[1];assert(update(12,morph));eq(morph.progress,0);eq(w.money[1],before,'burned morph consumes no resources')
w:investigate(14,12,2700)
assert(not GG.Counterintelligence.IsProductionDisabled(12),'costly factory repair releases shutdown')
assert(w.units[12].command and w.units[12].command.id==CMD.ONOFF and w.units[12].command.p[1]==1,'repaired factory is switched on')

w=setup();w:issue(14,CMD_INVESTIGATE,{11});w.money[1]=0;w:tick(300)
eq(w.units[14].rules.ci_progress,nil,'insufficient funds pause progress')
w.money[1]=1000;w.units[14].stunned=true;w:tick(300)
eq(w.units[14].rules.ci_progress,nil,'stun pauses progress')
w.units[14].stunned=false;w:tick(450);near(w.units[14].rules.ci_progress,0.5)
w:issue(14,CMD.STOP);w:tick(15);eq(w.units[14].rules.ci_investigating,0,'cancel releases investigator')
near(w.money[1],850,'cancel does not refund work already performed')

print('PASS counterintelligence: operative-only targeting, historical hub rosters, no icon spam, mass activation, false accusations, silent shutdown, real runners, bomb migration, factory cure/recovery, unit caps, morphs, recycled IDs, resource/stun/cancel handling')
