local frame=0
local calls,watched={},{}
local e=setmetatable({gadget={},GG={},Game={mapSizeX=8192,mapSizeZ=8192},
 gadgetHandler={IsSyncedCode=function()return true end},VFS={Include=dofile},
 WeaponDefs={[1]={damages={[0]=100}},[2]={damages={[0]=0}},[3]={damages={[0]=3},damageAreaOfEffect=1200}},
 Script={SetWatchWeapon=function(id,v)watched[id]=v end},
 Spring={GetGameFrame=function()return frame end,GetUnitPosition=function(id)if id==10 then return 1000,0,1000 end end}}, {__index=_G})
local f
if setfenv then f=assert(loadfile('luarules/gadgets/game_damageHeatMap.lua'));setfenv(f,e)
else f=assert(loadfile('luarules/gadgets/game_damageHeatMap.lua','t',e)) end
f();e.gadget:Initialize()
assert(e.GG.CityAreaState==e.GG.DamageHeatMap,'legacy alias stores a second map')
assert(watched[1] and watched[3] and not watched[2])
local original=e.GG.CityAreaState.ReportIncident
e.GG.CityAreaState.ReportIncident=function(self,...)calls[#calls+1]={...};return original(self,...)end
e.gadget:ProjectileCreated(1,10,2);assert(#calls==0)
e.gadget:ProjectileCreated(2,10,1);e.gadget:ProjectileCreated(3,10,1);assert(#calls==1)
frame=15;e.gadget:ProjectileCreated(4,10,1);assert(#calls==2)
e.gadget:Explosion(2,1000,0,1000);assert(#calls==2)
assert(e.gadget:Explosion(3,4000,0,4000)==false)
assert(e.GG.CityAreaState:IsDangerous(5100,4000),'blast radius ignored')
e.gadget:UnitDamaged(10,1,0,0);e.gadget:UnitDamaged(11,1,0,100);assert(#calls==3)
e.gadget:UnitDamaged(10,1,0,100);assert(#calls==4)
e.gadget:UnitDestroyed(10);e.gadget:ProjectileCreated(5,10,1);assert(#calls==5)
frame=3000;e.gadget:GameFrame(frame);assert(next(e.GG.CityAreaState.cells)==nil)
print('PASS area event adapter: damage, firing, missed impacts, blast radius, utility filtering, expiry and single storage')
