-- Exercise the production synced/unsynced railgun event bridge.
local unpack=unpack or table.unpack
local synced,frame,visible,full,hasUI=true,0,true,false,true
local projectiles,sent,callbacks,received={},{},{},{}
WeaponDefs={
    [1]={name='railgun',type='Cannon',customParams={railgun_wake='1'}},
    [2]={name='orbitalrailgun',type='Cannon',noExplode=true,customParams={railgun_wake=1}},
    [3]={name='machinegun',type='Cannon',customParams={}},
}
WeaponDefNames={railgun={id=1},orbitalrailgun={id=2}}
UnitDefNames={};Game={gameSpeed=30};gadget={}
gadgetHandler={
    IsSyncedCode=function() return synced end,
    AddSyncAction=function(_,name,fn) callbacks[name]=fn end,
    RemoveSyncAction=function(_,name) callbacks[name]=nil end,
}
Spring={
    GetGameFrame=function() return frame end,
    GetProjectilePosition=function(id)
        local p=projectiles[id];if p then return p.x,p.y,p.z end
    end,
    GetProjectileDefID=function(id) return projectiles[id] and projectiles[id].weapon end,
    GetSpectatingState=function() return full,full end,
    GetMyAllyTeamID=function() return 1 end,
    IsPosInLos=function() return visible end,
}
Script={SetWatchWeapon=function() end,LuaUI=setmetatable({
    GadgetRailgunWakePoint=function(...) received[#received+1]={kind='point',args={...}} end,
    GadgetRailgunWakeGap=function(...) received[#received+1]={kind='gap',args={...}} end,
},{__call=function(_,name) return hasUI and Script.LuaUI[name]~=nil end})}
SendToUnsynced=function(name,...) sent[#sent+1]={name=name,args={...}} end
local path='luarules/gadgets/gfx_explosion_lights.lua'
dofile(path);local producer=gadget;producer:Initialize()
local function wakeEvents()
    local out={}
    for _,event in ipairs(sent) do if event.name=='railgun_wake_point' then out[#out+1]=event.args end end
    return out
end
local function spawn(id,weapon,x,missingDef)
    projectiles[id]={weapon=weapon,x=x,y=20,z=0}
    producer:ProjectileCreated(id,77,missingDef and nil or weapon)
end

-- A projectile born and hit before the next sample gets both exact ends.
spawn(100,1,0)
producer:Explosion(1,25,21,0,77,100)
local events=wakeEvents()
assert(#events==2 and events[1][4]==0 and events[2][4]==25 and events[2][8]==1,'same-frame short shot lost its exact impact')
sent={};projectiles[100].x=32;producer:ProjectileDestroyed(100)
assert(#wakeEvents()==0,'destruction moved a sealed impact past its actual collision')

-- Burst-created weapons may omit weaponDefID and share muzzle throttle slots.
sent={};frame=1
projectiles[101]={weapon=2,x=0,y=20,z=0}
projectiles[102]={weapon=2,x=1,y=20,z=0}
producer:ProjectileCreated(101,77,nil);producer:ProjectileCreated(102,77,nil)
events=wakeEvents()
assert(#events==2 and events[1][1]~=events[2][1],'burst member missing weaponDefID lost its independent start')

-- noExplode rounds can keep travelling after each collision event.
sent={};producer:Explosion(2,60,20,0,77,101)
events=wakeEvents();assert(#events==1 and events[1][8]==0,'noExplode collision incorrectly terminated its trail')
sent={};frame=2;projectiles[101].x=100;projectiles[102].x=101;producer:GameFrame(frame)
events=wakeEvents()
assert(#events==2,'orbital path stopped after its non-terminal explosion')
sent={};projectiles[101].x=111;producer:ProjectileDestroyed(101)
events=wakeEvents();assert(#events==1 and events[1][4]==111 and events[1][8]==1,'destroy callback ignored valid final projectile position')
sent={};projectiles[102]=nil;producer:ProjectileDestroyed(102)
events=wakeEvents();assert(#events==1 and events[1][4]==101 and events[1][8]==1,'missing destruction position lost cached endpoint')

-- Owner destruction has no authority over an already travelling shot.
sent={};frame=3;spawn(103,1,0)
producer:UnitDestroyed(77,9)
sent={};frame=4;projectiles[103].x=80;producer:GameFrame(frame)
assert(#wakeEvents()==1,'owner death deleted independent projectile tracking')
producer:Explosion(1,81,20,0,77,103)

-- Ordinary weapons do not gain railgun trajectory events.
sent={};spawn(104,3,0);frame=5;producer:GameFrame(frame)
assert(#wakeEvents()==0,'unrelated projectile entered the railgun tracker')

-- Tracking load remains bounded before it crosses into unsynced rendering.
frame=6
for id=200,239 do spawn(id,1,id) end
sent={};frame=7;producer:GameFrame(frame)
assert(#wakeEvents()==32,'synced active railgun cap is not enforced')
sent={};frame=456;producer:GameFrame(frame)
events=wakeEvents();assert(#events==32,'active tracking did not expire at shot lifetime')
for _,event in ipairs(events) do assert(event[8]==1,'expiry did not terminate tracking') end
sent={};frame=457;producer:GameFrame(frame);assert(#wakeEvents()==0,'expired tracking continued sampling')

-- Hidden coordinates never cross the unsynced bridge into LuaUI.
synced=false;gadget={};dofile(path);local consumer=gadget;consumer:Initialize()
assert(callbacks.railgun_wake_point,'railgun receiver not registered')
visible=false
callbacks.railgun_wake_point(nil,300,450,1,999,100,888,451,0)
assert(#received==1 and received[1].kind=='gap' and #received[1].args==4,'hidden coordinates leaked instead of an identity-only gap')
assert(received[1].args[1]==300 and received[1].args[2]==450 and received[1].args[3]==451)
visible=true
callbacks.railgun_wake_point(nil,300,450,1,1000,100,888,452,1)
assert(received[2].kind=='point' and received[2].args[4]==1000 and received[2].args[8]==1,'visible exact endpoint lost on the bridge')
visible=false;full=true
callbacks.railgun_wake_point(nil,301,450,1,5,20,0,452,0)
assert(received[3].kind=='point','full-view spectator lost observed shot')
hasUI=false
callbacks.railgun_wake_point(nil,302,450,1,5,20,0,452,0)
assert(#received==3,'missing LuaUI received callbacks')
consumer:Shutdown();assert(not next(callbacks),'railgun sync action leaked on shutdown')
producer:Shutdown()
print('PASS: same-frame impacts, burst ID fallback, noExplode continuation, terminal/cached positions, owner independence, tracker cap, expiry and LOS-filtered event delivery')
