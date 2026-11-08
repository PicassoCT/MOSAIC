-- Run from the repository root with lua5.1 or texlua.
-- Exercise the actual factory-departure bridge and its normal wake consumer.
local unpack=unpack or table.unpack
local frame,synced=100,true
local units,events,callbacks={},{},{}
local ally,full,sourceLos,positionLos=1,false,true,true
local hiddenBand=false
local muzzle,pointCalls,gapCalls={},0,0
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function forbidden() error('visual launch changed gameplay') end
local function add(id,def,team,progress)
    units[id]={def=def,team=team or 1,progress=progress or 1,cloaked=false}
end
Game={gameSpeed=30}
UnitDefNames={nimrod={id=1},satellitescan={id=2},satelliteanti={id=3},
    satellitegodrod={id=4},air_plane_artillery={id=5},unrelated={id=6}}
WeaponDefs={[1]={name='railgun',type='Cannon',customParams={railgun_wake=1}}}
WeaponDefNames={railgun={id=1}}
GG={};gadget={}
gadgetHandler={
    IsSyncedCode=function() return synced end,
    AddSyncAction=function(_,name,fn) callbacks[name]=fn end,
    RemoveSyncAction=function(_,name) callbacks[name]=nil end,
}
Spring={
    GetGameFrame=function() return frame end,
    GetUnitDefID=function(id) return units[id] and units[id].def end,
    GetUnitIsDead=function(id) return not units[id] or units[id].dead end,
    GetUnitHealth=function(id)
        if units[id] then return 100,100,0,0,units[id].progress end
    end,
    GetUnitTeam=function(id) return units[id] and units[id].team end,
    GetUnitAllyTeam=function(id) return units[id] and units[id].team end,
    GetUnitIsCloaked=function(id) return units[id] and units[id].cloaked end,
    GetUnitPieceMap=function() return {projectile=7} end,
    GetUnitPiecePosDir=function(id,piece) assert(id==10 and piece==7);return 100,45,200 end,
    GetUnitPosition=function() return 9999,1500,9999 end,
    GetSpectatingState=function() return full,full end,
    GetMyAllyTeamID=function() return ally end,
    GetUnitLosState=function() return {los=sourceLos} end,
    IsPosInLos=function(x,y,z)
        return positionLos and (not hiddenBand or y<170 or y>390)
    end,
    IsSphereInView=function() return true end,
    SpawnProjectile=forbidden,GiveOrderToUnit=forbidden,SetUnitCloak=forbidden,
    SetUnitPosition=forbidden,MoveCtrl={SetPosition=forbidden},
}
Script={SetWatchWeapon=function() end}
SendToUnsynced=function(name,...) events[#events+1]={name=name,args={...}} end
local path='luarules/gadgets/gfx_explosion_lights.lua'
dofile(path);local producer=gadget;producer:Initialize()
local api=assert(GG.NimrodLaunchFX)
add(10,1)
add(20,2,1,.5);producer:UnitCreated(20,2,1,10)
assert(not api.Departure(20) and #events==0,'incomplete unit emitted a launch')
units[20].progress=1
assert(api.Departure(20,1500) and #events==1,'actual completed departure missing')
assert(not api.Departure(20) and #events==1,'duplicate departure emitted twice')
local first=events[1]
assert(first.name=='nimrod_launch' and first.args[1]<0 and first.args[2]==frame)
assert(first.args[3]==1 and first.args[4]==10 and first.args[5]==1)
assert(first.args[7]==100 and first.args[8]==45 and first.args[9]==200
    and first.args[10]==1455,'launch was not anchored at the barrel before insertion')

-- Only supported Nimrod-built payloads enter the one-shot registry.
add(21,2);producer:UnitCreated(21,2,1,nil)
assert(not api.Departure(21),'cheat-spawned satellite invented a factory launch')
add(22,6);producer:UnitCreated(22,6,1,10)
assert(not api.Departure(22),'unrelated build was given railgun effects')
add(23,3,1,.3);producer:UnitCreated(23,3,1,10)
producer:UnitDestroyed(23,3);units[23].progress=1
assert(not api.Departure(23),'canceled build retained a launch registration')
add(24,4);producer:UnitCreated(24,4,1,10)
units[24].team=2
assert(not api.Departure(24),'captured payload used another team\'s factory')
add(25,5);producer:UnitCreated(25,5,1,10)
producer:UnitDestroyed(10,1)
assert(not api.Departure(25),'destroyed/reused builder retained payload provenance')
assert(#events==1,'rejected launches emitted an event')

-- Same-frame unit ID reuse cannot join the original lingering wake, nor can
-- a synthetic ID collide with the positive engine projectile namespace.
producer:UnitDestroyed(20,2)
add(20,5);producer:UnitCreated(20,5,1,10)
units[10].cloaked=true
assert(api.Departure(20,100000))
local second=events[2]
assert(second.args[1]<0 and second.args[1]~=first.args[1]
    and second.args[2]==first.args[2] and second.args[10]==2048)
assert(second.args[6]==1,'event omitted launch-time cloak state')

local Wakes=dofile('luaui/widgets_mosaic/include/railgun_wakes.lua')
local wakes=Wakes.New(Spring,Game,WeaponDefs)
Script.LuaUI=setmetatable({
    GadgetWeaponBarrelfire=function(...) muzzle[#muzzle+1]={...} end,
    GadgetRailgunWakePoint=function(...)
        pointCalls=pointCalls+1;wakes:Point(...)
    end,
    GadgetRailgunWakeGap=function(...)
        gapCalls=gapCalls+1;wakes:Gap(...)
    end,
},{__call=function(_,name) return Script.LuaUI[name]~=nil end})
synced=false;gadget={};dofile(path);local consumer=gadget;consumer:Initialize()
local function deliver(event) callbacks[event.name](nil,unpack(event.args)) end
deliver(first);deliver(second)
assert(#muzzle==2 and pointCalls<=2*33,'launch exceeded one flash / 33 samples')
assert(wakes:GetStats().tracked==2 and wakes:GetStats().active==0,
    'same-frame synthetic IDs merged or a finite launch remained actively tracked')
for _,shot in pairs(wakes.shots) do
    assert(shot.expires==100+15*30 and #shot.segments<=32)
    for _,span in ipairs(shot.segments) do
        assert(span.ax==100 and span.bx==100 and span.az==200 and span.bz==200,
            'launch wake connected to an orbital map-edge teleport')
    end
end
local Policy=dofile('luaui/widgets_mosaic/include/combat_sfx_policy.lua')
assert(Policy.Profiles(WeaponDefs,WeaponDefNames)[1].priority==Policy.HIGH,
    'launch flash lost railgun High priority')

-- Hidden enemy sources are rejected at event time, even if their sky is in LOS.
local oldPoints,oldMuzzle=pointCalls,#muzzle
ally=2
deliver(second)
assert(pointCalls==oldPoints and #muzzle==oldMuzzle,'cloaked enemy launch revealed source')
sourceLos=false;deliver(first)
assert(pointCalls==oldPoints and #muzzle==oldMuzzle,'unobserved enemy source leaked')
sourceLos=true
assert(not api.Departure(20) and #events==2,
    'revealing the gun replayed its previously concealed launch')
positionLos=false;deliver(first)
assert(pointCalls==oldPoints and #muzzle==oldMuzzle,'point LOS bypassed source visibility')

-- Allied cloaked launches and full-view spectators may see their launch, but
-- per-point/interior LOS still creates permanent gaps for normal viewers.
positionLos=true;ally=1;hiddenBand=true
wakes=Wakes.New(Spring,Game,WeaponDefs);pointCalls,gapCalls=0,0
deliver(second)
assert(#muzzle==oldMuzzle+1 and pointCalls+gapCalls==33 and gapCalls>0)
assert(wakes:GetStats().active==0,'final hidden sample did not close launch')
hiddenBand=false
local spans=wakes:Collect()
assert(#spans>0)
for _,span in ipairs(spans) do
    assert(span.by<170 or span.ay>390,'new visibility reconstructed an unobserved section')
end
full=true;ally=2;positionLos=false;sourceLos=false
wakes=Wakes.New(Spring,Game,WeaponDefs)
deliver(second)
assert(wakes:GetStats().spans==32,'full-view spectator lost the finite launch')
full=false;positionLos=true;sourceLos=true;ally=1

-- The real shared admission limit and expiry apply to launch residue too.
wakes=Wakes.New(Spring,Game,WeaponDefs)
for i=1,40 do
    add(30,5);producer:UnitCreated(30,5,1,10)
    assert(api.Departure(30))
    deliver(events[#events])
end
assert(wakes:GetStats().tracked==16 and wakes:GetStats().spans<=16*32,
    'factory launches bypassed the shared wake budget')
frame=550;wakes:Update()
assert(wakes:GetStats().tracked==0,'launch residue survived its 15-second lifetime')
local eventCount=#events
producer:GameFrame(frame)
assert(#events==eventCount,'finite launch added continuous projectile tracking')
consumer:Shutdown();assert(not next(callbacks),'launch sync action leaked on shutdown')
producer:Shutdown();assert(GG.NimrodLaunchFX==nil,'departure API leaked on shutdown')
print('PASS: actual completed departures, canceled/captured builds, source destruction, once-only/id reuse, local vertical wake, cloak/LOS isolation, High/shared budgets and 15-second expiry')
