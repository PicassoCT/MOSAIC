-- The actual synced/unsynced event bridge, including LuaUI reload and LOS changes.
local synced=true
local frame,clock,inlos,hasUI=0,0,true,true
local messages,received,watches={},{},{}
WeaponDefs={{name='molotow',type='Cannon'},{name='flame',type='Flame'},{name='rocket',type='MissileLauncher'}}
WeaponDefNames={molotow={id=1}}
Game={gameSpeed=30};gadget={}
gadgetHandler={IsSyncedCode=function() return synced end,
    AddSyncAction=function(_,name,fn) messages[name]=fn end,
    RemoveSyncAction=function(_,name) messages[name]=nil end}
Spring={GetGameFrame=function() return frame end,GetProjectilePosition=function() return 10,5,20 end,
    GetTimer=function() return clock end,DiffTimers=function(a,b) return a-b end,
    GetSpectatingState=function() return false,false end,GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return inlos end}
Script={SetWatchWeapon=function(id) watches[id]=true end,
    LuaUI=setmetatable({GadgetCombatFire=function(id,x,y,z,born,expires)
        received[id]={x=x,y=y,z=z,born=born,expires=expires}
    end,GadgetWeaponExplosion=function() received.explosion=true end,
    GadgetWeaponBarrelfire=function() received.muzzle=true end},
        {__call=function() return hasUI end})}
local sends=0
SendToUnsynced=function() sends=sends+1 end
local path='luarules/gadgets/gfx_explosion_lights.lua'
dofile(path);local producer=gadget;producer:Initialize()
assert(watches[1] and watches[2] and watches[3])
producer:ProjectileCreated(1,7,3);producer:ProjectileCreated(2,7,3)
assert(sends==1,'muzzle events not rate limited')
frame=3;producer:ProjectileCreated(3,7,3);assert(sends==2)
producer:Explosion(1,100,2,200,7)
assert(MosaicCombatFires[1].expires==453,'Molotov lifetime changed')
for i=1,200 do producer:Explosion(1,i,2,i,7) end
local count=0;for _ in pairs(MosaicCombatFires) do count=count+1 end
assert(count==128,'synced fire snapshot unbounded')
synced=false;gadget={};SYNCED={MosaicCombatFires=MosaicCombatFires}
dofile(path);local consumer=gadget;consumer:Initialize();consumer:Update()
assert(received[1] and received[1].expires==453)
received={};clock=.05;consumer:Update();assert(not next(received),'snapshot sent above 10 Hz')
inlos=false;clock=.11;consumer:Update();assert(not next(received),'hidden fire crossed into LuaUI')
messages.explosion_light(nil,10,2,20,1,7);assert(not received.explosion,'hidden explosion leaked')
inlos=true;hasUI=false;clock=.22;consumer:Update();assert(not next(received))
hasUI=true;clock=.33;consumer:Update();assert(received[1],'UI reload/entering LOS did not restore fire')
messages.explosion_light(nil,10,2,20,1,7);assert(received.explosion)
frame=453;producer:GameFrame(frame);assert(not next(MosaicCombatFires),'expired fire snapshot retained')
received={};clock=.44;consumer:Update();assert(not next(received))
consumer:Shutdown();assert(not next(messages),'sync actions leaked on shutdown')
producer:Shutdown();assert(MosaicCombatFires==nil)

-- Exercise both real wreckage fire loops: retain their fire/smoke CEGs, no
-- groundflash, and publish finite radiance/FlamePainter emitter lifetimes.
include=function() end;piece=function(name) return name=='emitfire' and 2 or 1 end
Spring.GetGaiaTeamID=function() return 0 end;Spring.GetUnitTeam=function() return 0 end
Spring.GetUnitPiecePosDir=function() return 10,5,10 end
Spring.SetUnitRulesParam=function(_,key,value,visibility)
    assert(visibility.inlos);received[key]=value
end
StartThread=function() end;unitID=7;script={}
local emitted={}
EmitSfx=function(_,code) emitted[code]=(emitted[code] or 0)+1 end
Sleep=function(ms) frame=frame+ms*.03 end
for _,file in ipairs({'vehicleCorpsescript.lua','tankwreckagescript.lua'}) do
    dofile('scripts/'..file)
    frame=0;received={};emitted={}
    onFire(10,4)
    assert(emitted[1025]==3 and emitted[1026]==3 and emitted[1028]==10,'existing wreck CEG flames/smoke changed')
    assert(not emitted[1031],'wreck still emits CEG ground lighting')
    assert(received.mosaic_fire_piece==emitfire)
    assert(math.abs(received.mosaic_fire_until-(8.1+18))<.001,'fire-light lifetime does not match flame phase')
end
print('PASS: watched weapons, muzzle throttling, bounded fire snapshot, 15-second expiry, LOS/UI reload, event cleanup and both wreckage CEG loops')
