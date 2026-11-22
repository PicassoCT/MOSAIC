-- Standalone: lua tests/police_response_test.lua
local frame,nextID=0,100
local pos={[1]={100,0,100},[2]={300,0,300},[10]={3000,0,3000}}
local defs={[1]=1,[2]=2,[10]=3}
local orders,created,cloaked={},0,false
local cfg={police={population={maxOfficers=8},dispatch={durationFrames=2000,minSpawnDistance=2200,reportDelayFrames=240},pursuit={escapeFrames=900,searchFrames=1350,sightRange=650}},espionage={bribe={durationFrames=1800,radius=750,maxOfficers=3,combatGraceFrames=150,safehouseRevealRange=350,safehouseRevealFrames=900},cybercrime={durationFrames=3600,policeInterruptRange=180}},game={culture='arabic',states={anarchy='anarchy',pacification='pacification'}}}
cfg.police.hostages={cars=2,radius=260,minDistance=140,maxDistance=750,separation=180,arrivalDistance=35}
GG={BuildingTable={[10]={x=3000,z=3000}},GlobalGameState='normal'}
Game={mapSizeX=10000,mapSizeZ=10000}
CMD={MOVE=10,ATTACK=20,STOP=0,FIRE_STATE=45}
UnitDefs={[4]={name='policetruck'}}
UnitDefNames={policetruck={id=4},icon_cybercrime={id=8},icon_bribe={id=9}}
WeaponDefNames={closecombat={id=5}}
gadget={};gadgetHandler={IsSyncedCode=function() return true end};VFS={Include=function(path)
    if path:match('^luarules/gadgets/include/police_') then return dofile(path) end
end}
getGameConfig=function() return cfg end
getPoliceTypes=function() return {[4]=true} end
getSafeHouseTypeTable=function() return {} end
getOperativeTypeTable=function() return {[1]=true} end
getMobileCivilianDefIDTypeTable=function() return {[2]=true} end
getCultureUnitModelTypes=function(_,kind) return kind=='civilian' and {[2]=true} or {} end
getScrapheapTypeTable=function() return {} end
isOffenceIcon=function() return false end
registerEmergency=function() end
local radio={}
Spring={
 GetGameRulesParam=function(key) return radio[key] end,
 SetGameRulesParam=function(key,value,visibility) assert(visibility.public);radio[key]=value end,
 GetGaiaTeamID=function() return 0 end,GetTeamAllyTeamID=function() return 0 end,
 ValidUnitID=function(id) return pos[id]~=nil end,GetUnitIsDead=function(id) return not pos[id] end,
 GetUnitPosition=function(id) if pos[id] then return (table.unpack or unpack)(pos[id]) end end,
 GetUnitDefID=function(id) return defs[id] end,
 GetUnitTeam=function(id) return id==1 and 1 or 0 end,
 GetUnitsInCylinder=function() return {} end,
 GetGameFrame=function() return frame end,GetGroundHeight=function() return 0 end,
 GetUnitStates=function()return {firestate=2}end,
 SetUnitWeaponState=function()end,SetUnitRotation=function(id,x,y,z)pos[id].heading=y end,
 GetUnitRadius=function() return 100 end,TestMoveOrder=function() return true end,
 GetUnitIsCloaked=function() return cloaked end,GetUnitLosState=function() return {los=true} end,
 GiveOrderToUnit=function(id,cmd,p) orders[id]={cmd=cmd,p=p} end,
 GetAllUnits=function() return {} end,SetUnitNeutral=function() end,
 CreateUnit=function(_,x,y,z) created=created+1;nextID=nextID+1;pos[nextID]={x,y,z};defs[nextID]=4;
     gadget:UnitCreated(nextID,4);return nextID end,
 DestroyUnit=function(id) gadget:UnitDestroyed(id,defs[id]);pos[id]=nil end,
}
dofile('luarules/gadgets/game_police.lua');gadget:Initialize()
local function tick(f) frame=f;gadget:GameFrame(f) end
local function shoot(weapon) gadget:UnitDamaged(2,2,0,20,false,weapon,nil,1,1,1) end
shoot(5);tick(240);assert(not radio.police_scanner_frame,'silent stabbing creates no radio report');assert(created==0 and not GG.PoliceExposureUntil[1],'stabbing stays silent')
frame=0;shoot(6);assert(GG.PoliceExposureUntil[1]==900)
tick(225);assert(created==0,'dispatch delay')
assert(radio.police_scanner_kind=='violence' and radio.police_scanner_x==300 and radio.police_scanner_frame==0,'radio uses victim location and actual event time')
tick(240);assert(created==1 and GG.PoliceInPursuit[101]==1,'new officer retains incident')
assert(orders[101].cmd==CMD.MOVE and orders[101].p[1]==300,'drive to victim, not attacker')
assert(pos[101][1]>2200,'spawn at distant building')
-- A repeat shot updates the incident without spawning another unit.
frame=255;shoot(6);tick(270);assert(created==1)
-- Officers cannot read the faraway attacker through shared civilian LOS.
assert(orders[101].cmd==CMD.MOVE)
pos[101]={200,0,200};tick(330)
assert(orders[101].cmd==CMD.ATTACK and GG.PoliceExposureUntil[1]==1230,'nearby sighting renews exposure')
pos[1]={8000,0,8000};tick(480)
assert(orders[101].cmd==CMD.MOVE and orders[101].p[1]<1000,'search last known area')
tick(1230);assert(not GG.PoliceExposureUntil[1],'escape permits recloak')
tick(1680);assert(not GG.PoliceInPursuit[101],'search expires')
frame=1695;shoot(6);tick(1935);assert(created==1 and GG.PoliceInPursuit[101]==1,'reuse sole officer')
Spring.DestroyUnit(101);GG.BuildingTable={}
tick(2040);assert(created==1,'no building means retry, never spawn at attacker')
-- Report location survives a lethal hit and disappearance of the victim.
pos[10]={3000,0,3000};GG.BuildingTable[10]={x=3000,z=3000}
gadget:UnitDestroyed(2,2);pos[2]=nil
tick(2130);assert(created==2 and orders[102].p[1]==300,'lethal incident retains victim location')
print('PASS: silent stab, delay, remote spawn, assignment, victim response, sightings, escape, reuse, retry, lethal hit')

-- Hostage response uses exactly two cars, actual roads and the existing pursuit.
Spring.DestroyUnit(102);pos[1]=nil;tick(3000);pos[1]={300,0,300};pos[2]={300,0,300};defs[2]=2
GG.CityRoadNetwork={roads={{points={{0,300},{10000,300}}}}}
frame=3000;GG.PoliceHostages.Report(1,2);GG.PoliceHostages.Report(1,2)
tick(3225);assert(radio.police_scanner_kind=='hostage' and radio.police_scanner_frame==3000);assert(created==2,'hostage report respects ordinary dispatch delay')
tick(3240);assert(created==4,'one report assigns exactly two police cars')
local cars={103,104}
for _,id in ipairs(cars) do
 assert(GG.PoliceHostages.IsHoldingFire(id),'cars hold fire during live hostage')
 assert(orders[id].cmd==CMD.MOVE,'cars approach roadblock without an attack order')
 assert(orders[id].p[3]==300,'roadblock is on the actual road')
 pos[id]={orders[id].p[1],0,orders[id].p[3]}
 assert(not gadget:AllowWeaponTarget(id,1,1,6,0),'automatic targeting blocked')
end
tick(3255)
for _,id in ipairs(cars) do
 assert(orders[id].cmd==CMD.STOP and pos[id].heading,'cars stop across road, not chase captor')
end
tick(3285);assert(created==4,'live hold never duplicates the two-car response')
GG.PoliceHostages.End(1,2,true);tick(3300)
assert(radio.police_scanner_kind=='hostage_death','hostage death reaches scanner')
for _,id in ipairs(cars) do
 assert(not GG.PoliceHostages.IsHoldingFire(id),'hostage death lifts ceasefire')
 assert(orders[id].cmd==CMD.ATTACK and orders[id].p[1]==1,'same cars attack captor after hostage death')
end
-- Pursuit ends normally; peaceful release does not order retaliation.
tick(5310);assert(not GG.PoliceInPursuit[103] and not GG.PoliceInPursuit[104])
frame=5340;GG.PoliceHostages.Report(1,2);tick(5580)
assert(created==4,'new hold reuses available cars')
GG.PoliceHostages.End(1,2,false);tick(5595)
for _,id in ipairs(cars) do assert(not GG.PoliceHostages.IsHoldingFire(id) and orders[id].cmd~=CMD.ATTACK) end
print('PASS: two hostage roadblocks, hold-fire, real road parking, no duplicate dispatch, death pursuit and peaceful release')
