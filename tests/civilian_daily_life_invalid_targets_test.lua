-- Lua 5.1 standalone regression for the civilian GameFrame error at frame 300.
-- Run from repository root: lua tests/civilian_daily_life_invalid_targets_test.lua
local function read(path)
    local f=assert(io.open(path,"rb"))
    local source=f:read("*a"); f:close(); return source
end
local function chunk(source,env)
    if loadstring and setfenv then
        local fn=assert(loadstring(source)); setfenv(fn,env); return fn()
    end
    return assert(load(source,"civilian test","t",env))()
end
local function section(source,first,last)
    local a=assert(source:find(first,1,true))
    local b=assert(source:find(last,a+#first,true))
    return source:sub(a,b-1)
end

local units={
    [10]={x=120,y=0,z=120,def=1,team=0},
    [11]={x=140,y=0,z=120,def=1,team=0},
    [100]={x=200,y=0,z=200,def=2,team=0},
    [101]={x=350,y=0,z=250,def=2,team=0},
    [102]={x=500,y=0,z=260,def=2,team=0},
    [103]={x=600,y=0,z=270,def=2,team=0}
}
local frame=300
local config={phoneMin=100,phoneMax=110,venueRadius=800,dangerCell=200,
    dangerRadius=300,visitMin=30,visitMax=100,memoryLimit=6,memoryLifetime=1000}
local gameConfig={game={states={normal="normal"}},
    civilians={movement={maxWalkingDistance=1000},activityStates={started="started"}}}
local e=setmetatable({
    CMD_CIVILIAN_BLEND=34971, CMD={MOVE=10,STOP=0,GUARD=25},
    Game={mapName="MOSAIC_test",mapSizeX=2048,mapSizeZ=2048},
    UnitDefs={[1]={name="civilian"},[2]={name="house"}},
    GG={CivilianTable={[10]={defID=1,startID=100},[11]={defID=1,startID="100"}},
        UnitArrivedAtTarget={},DisguiseCivilianFor={},AerosolAffectedCivilians={},
        CivilianUnitInternalLogicActive={},GlobalGameState="normal",BuildingTable={}},
    SendToUnsynced=function() end
}, {__index=_G})
e.VFS={Include=function(name)
    if name=="luarules/configs/civilian_daily_life.lua" then return config end
    if name=="scripts/lib_civilian_dialogue.lua" then
        return {build=function()return {"hello"} end}
    end
    if name=="luarules/configs/commandsIDs.lua" then return true end
    error("unexpected include: "..tostring(name))
end}
e.Spring={
    GetGaiaTeamID=function()return 0 end,
    GetGameFrame=function()return frame end,
    -- Intentionally permissive: old alive("101") passed this check.
    ValidUnitID=function(id)return units[tonumber(id)]~=nil end,
    GetUnitIsDead=function(id)return not units[tonumber(id)] or units[tonumber(id)].dead end,
    -- Mimic the strict Recoil argument type check from infolog.
    GetUnitPosition=function(id)
        assert(type(id)=="number","[GetUnitPosition] unitID not a number")
        local u=units[id]
        if u and not u.dead then return u.x,u.y,u.z end
    end,
    GetUnitDefID=function(id)return units[id] and units[id].def end,
    GetUnitTeam=function(id)return units[id] and units[id].team end,
    GetUnitTransporter=function()return nil end,
    GetUnitRadius=function()return 50 end,
    GetGroundHeight=function()return 0 end,
    TestMoveOrder=function()return true end,
    GetUnitsInCylinder=function()return {} end,
    GiveOrderToUnit=function()end,
    UnitScript={GetScriptEnv=function()return nil end}
}

local factory=chunk(read("luarules/gadgets/include/civilian_daily_life.lua"),e)
local life=factory({gameConfig=gameConfig,walkers={[1]=true},trucks={},raining=function()return false end})
life:Register(10,100)
local candidates={"101",false,{},101,102}
local target=life:SelectTarget(10,100,candidates)
assert(target==101 or target==102,"nonnumeric candidate was selected")
assert(type(target)=="number","target should be a numeric unit ID")
life.people[10].work="101"
target=life:SelectTarget(10,100,candidates)
assert(target==101 or target==102,"stale string workplace was reused")
assert(type(life.people[10].work)=="number","workplace not sanitized")
units[101].dead=true;life.people[10].work=101
assert(life:SelectTarget(10,100,candidates)==102,"dead workplace was not replaced")
assert(life:SelectTarget(10,100,{"102","101",false})==nil,"invalid route should have no target")
assert(life:SelectTarget("10",100,{102})==nil,"invalid civilian ID accepted")
assert(life:BuildRoute(10,100,"102")==nil,"invalid destination accepted")
assert(life:BuildRoute("10",100,102)==nil,"invalid source accepted")
local route=assert(life:BuildRoute(10,100,102))
assert(#route>=2 and route[2].venue==102,"valid route no longer works")

life:RegisterVenue("103","shopping")
life:RegisterVenue(103,"shopping")
units[103].dead=true
assert(life:SelectTarget(10,100,{102})==102,"dead venue disrupted destination selection")
life.people[10].work=103
life:UnitDestroyed(103)
assert(life.people[10].work==nil,"destroyed venue remained remembered as work")

local source=read("luarules/gadgets/game_civilians.lua")
local events={}
e.RouteTabel={[100]={"101",false,{},101,102,103}}
e.civilianLife=life
e.civilianWalkingTypeTable={[1]=true}
e.spGetUnitPosition=e.Spring.GetUnitPosition
e.spGetUnitTeam=e.Spring.GetUnitTeam
e.spGetGameFrame=e.Spring.GetGameFrame
e.gaiaTeamID=0
e.doesUnitExistAlive=function(id)
    assert(type(id)=="number","unsafe unit ID reached old waypoint helper")
    return e.Spring.ValidUnitID(id) and not e.Spring.GetUnitIsDead(id)
end
e.travellFunction=function()end
e.buildRouteSquareFromTwoUnits=function()error("unexpected legacy fallback") end
e.GG.EventStream={CreateEvent=function(_,fn,pack,when)
    assert(pack.unitID==10 and pack.goalList and #pack.goalList>=2)
    events[#events+1]={when=when,pack=pack}
end}
chunk(section(source,"function giveWaypointsToUnit(","function testClampRoute("),e)
assert(e.giveWaypointsToUnit(10,1,100)==true,"valid civilian was not routed")
assert(#events==1)
chunk(section(source,"function issueArrivedUnitsCommands()","function decimateArrivedCivilians("),e)
e.GG.UnitArrivedAtTarget={[11]=true,[10]=true}
e.issueArrivedUnitsCommands()
assert(#events==2,"one corrupt arrival prevented a valid waypoint event")
assert(next(e.GG.UnitArrivedAtTarget)==nil,"arrival queue not cleared")
e.RouteTabel[100]={"101","103",false,{}}
assert(e.giveWaypointsToUnit(10,1,100)==false,"invalid targets should be skipped")
assert(#events==2,"invalid targets scheduled a movement event")

-- A completed everyday trip may already be queued when its civilian joins a
-- parade. Keep that arrival pending without creating a competing travel event.
e.RouteTabel[100]={102}
local retired, arrivalCalls=0,0
local owned=true
e.GG.CityParade={
    OwnsUnit=function(_,id) return owned and id==10 end,
    OnArrived=function(_,id) arrivalCalls=arrivalCalls+1; return false end,
}
e.GG.UnitArrivedAtTarget={[10]=true}
e.issueArrivedUnitsCommands()
assert(e.GG.UnitArrivedAtTarget[10] and #events==2 and arrivalCalls==0,
    "held parade arrival was rerouted or consumed")

-- Retiring floats are consumed by their parade callback at a normal traffic
-- destination, whereas released spectators retain the ordinary route fallback.
owned=false
e.GG.CityParade.OnArrived=function(_,id)
    assert(id==10); retired=retired+1; return true
end
e.issueArrivedUnitsCommands()
assert(retired==1 and #events==2 and next(e.GG.UnitArrivedAtTarget)==nil,
    "retired float was assigned another civilian trip")
e.GG.CityParade.OnArrived=function() return false end
e.GG.UnitArrivedAtTarget={[10]=true}
e.issueArrivedUnitsCommands()
assert(#events==3 and next(e.GG.UnitArrivedAtTarget)==nil,
    "released parade spectator did not resume ordinary routing")

-- Capture can occur AFTER an event reports arrival but BEFORE this batch. A
-- replacement event would record the new player's team and evade the old
-- Gaia-event capture guard, so the arrival boundary must reject it itself.
units[10].team=1
e.GG.UnitArrivedAtTarget={[10]=true}
e.issueArrivedUnitsCommands()
assert(#events==3 and not e.GG.UnitArrivedAtTarget[10],
    "captured arrived carrier received a replacement civilian travel event")

-- Population trimming runs before arrival routing on some frames. It must
-- independently protect captured traffic and parade-owned arrivals as well.
local destroyed={}
e.spDestroyUnit=function(id)
    destroyed[id]=true; units[id].dead=true
end
chunk(section(source,"function decimateArrivedCivilians(","function gadget:GameFrame("),e)
e.GG.CivilianTable[10]={defID=1,startID=100}
e.GG.UnitArrivedAtTarget={[10]=true}
e.decimateArrivedCivilians(1,{[1]=true})
assert(not destroyed[10],"population trimming destroyed a captured arrived carrier")
units[10].team=0;owned=true
e.decimateArrivedCivilians(1,{[1]=true})
assert(not destroyed[10],"population trimming destroyed an active parade participant")
owned=false
e.decimateArrivedCivilians(1,{[1]=true})
assert(destroyed[10],"ordinary unprotected Gaia population no longer trims")

print("PASS civilian waypoint regression: strict IDs, stale destinations, held parade arrivals, retirement, resumed routes and captured traffic")
