-- Lua 5.1+: exercise actual city/area/placement adapters with engine calls mocked.
local function read(p) local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local function run(p,env)
    setmetatable(env,{__index=_G})
    local f
    if setfenv then f=assert(loadfile(p));setfenv(f,env) else f=assert(loadfile(p,'t',env)) end
    return f()
end
local function noop() end
local frame=0
local areaConfig=dofile('luarules/configs/city_area.lua')
local area=dofile('luarules/gadgets/include/city_area_state.lua')(areaConfig,8192,8192,function()return frame end)
assert(area:getDangerAtLocation(0,0)==0 and area:getHighestDangerLocation()==nil)
assert(next(area.cells)==nil,'queries allocated empty cells')
area:ReportIncident(6000,6000,500)
assert(area:IsDangerous(6500,6000) and area:IsPeaceful(200,200))
local hx,hz=area:getHighestDangerLocation()
assert(hx>5000 and hz>5000,'sparse heat coordinates were not converted to world space')
frame=areaConfig.quietFrames-1;assert(area:IsDangerous(6000,6000))
area:ReportIncident(6000,6000,0)
frame=frame+areaConfig.quietFrames-1;assert(area:IsDangerous(6000,6000),'missed shots must renew quiet period')
frame=frame+1;area:Update();assert(area:IsPeaceful(6000,6000) and next(area.cells)==nil)
area:ReportIncident(nil,nil,5);area:ReportIncident(-100,0,5)
assert(next(area.cells)==nil)
area:ReportIncident(8192,8192,5)
assert(area:IsDangerous(8192,8192),'edge event dropped')
frame=frame+areaConfig.quietFrames;area:Update()

local config={game={culture='western',states={normal='normal',anarchy='anarchy',postLaunch='postlaunch',gameOver='gameover'}},
 city={buildings={sizeX=256,sizeY=64,sizeZ=256},alleys={sizeX=25,sizeZ=25},rubble={decayFrames=30,constructionFrames=30}},
 espionage={safehouses={buildRange=100}}}
local defs={[1]={id=1,name='house_asian1'},[2]={id=2,name='house_arab0'},
 [3]={id=3,name='house_western0'},[4]={id=4,name='gcscrapheap'},[5]={id=5,name='safehouse'}}
local names={};for id,d in pairs(defs) do names[d.name]=d end
local units,nextID,failed,masks={},100,false,{}
local shared={GlobalGameState='normal',CityAreaState=area}
local env={GG=shared,Game={mapSizeX=8192,mapSizeZ=8192,mapName='test'},UnitDefs=defs,UnitDefNames=names,
 gadget={},gadgetHandler={IsSyncedCode=function()return true end},
 include=function()return {} end,getGameConfig=function()return config end,
 getUnitDefNames=function()return names end,getBuildingScrapHeapTypeTable=function()return {[4]=4} end,
 getBuildingRuinTypeTable=function()return {} end,makeTable=function()return {} end,
 getCultureUnitModelTypes=function()return {[1]=1,[2]=2,[3]=3} end,
 getHouseTypeIsInnerCityOnly=function()return {} end,removeDictFromDict=function(t)return t end,
 getHouseTypeLimitations=function()return {} end,getLoadAbleTruckTypes=noop,getRefugeeAbleTruckTypes=noop,
 getSafeHouseTypeTable=function()return {[5]=true} end,
 getCultureUnitModelNames_Dict_DefIDName=function()return {[1]='arcology',[2]='arab',[3]='western'} end,
 randDict=function()return 4 end,setHouseStreetNameTooltip=noop,
 isMapControlledBuildingPlacement=function()return false end,toString=tostring,
 getCultureDependantRandomOffsets=function()return {xRandOffset=0,zRandOffset=0} end}
local city,placement
local function alive(id)return units[id]~=nil and not units[id].dead end
env.doesUnitExistAlive=alive
local S={GetGameFrame=function()return frame end,GetGaiaTeamID=function()return 0 end,
 Echo=noop,SetGameRulesParam=noop,SetUnitAlwaysVisible=noop,SetUnitBlocking=noop,SetUnitTooltip=noop,
 GetGroundHeight=function()return 0 end,ValidUnitID=alive,GetUnitIsDead=function(id)return not alive(id) end,
 GetAllUnits=function()local t={};for id in pairs(units)do t[#t+1]=id end;return t end,
 GetUnitPosition=function(id)local u=units[id];if u then return u.x,0,u.z end end,
 GetUnitDefID=function(id)return units[id] and units[id].def end,
 GetUnitTeam=function(id)return units[id] and units[id].team end,
 GetUnitBuildFacing=function(id)return units[id] and units[id].facing end,
 GetUnitHealth=function(id)local u=units[id];if u then return u.hp,1000,0,0,u.build end end,
 SetUnitHealth=function(id,t)local u=assert(units[id]);u.build=t.build or u.build;u.hp=t.health or u.hp end,
 SetUnitRulesParam=function(id,k,v)assert(units[id]).rules[k]=v end,
 SetSquareBuildingMask=function(x,z,m)masks[x..':'..z]=m end,
 GetUnitsInCylinder=function(x,z,r)local t={};for id,u in pairs(units)do
  if alive(id) and (u.x-x)^2+(u.z-z)^2<=r*r then t[#t+1]=id end end;table.sort(t);return t end}
env.Spring=S
env.VFS={Include=function(path)
 if path=='scripts/lib_house_asian_split.lua' then return {newState=function()return {} end} end
 if path:find('luarules/gadgets/include/',1,true)==1 then return dofile(path) end
end}
S.CreateUnit=function(def,x,y,z,facing,team,build)
 if failed then return end
 nextID=nextID+1;local id=nextID
 units[id]={def=def,x=x,z=z,team=team,facing=facing,hp=build and 1 or 1000,build=build and 0 or 1,rules={}}
 if city then city:UnitCreated(id,def) end
 if placement then placement:UnitCreated(id,def) end
 return id
end
S.DestroyUnit=function(id)
 local u=assert(units[id]);u.dead=true
 city:UnitDestroyed(id,u.def,u.team,nil)
 if placement then placement:UnitDestroyed(id) end
 units[id]=nil
end
run('luarules/gadgets/game_spawnCity.lua',env);city=env.gadget
city:Initialize()
-- Load only the actual occupancy helper; the rest of lib_mosaic needs the engine.
local lib=read('scripts/lib_mosaic.lua')
local helper=lib:sub(assert(lib:find('function isCityBuildingHabitable',1,true)),assert(lib:find('-- Unit-script animations',1,true))-1)
local fn=assert(loadstring and loadstring(helper) or load(helper));if setfenv then setfenv(fn,env) end;fn()
local pe={GG=shared,Spring=S,Game=env.Game,UnitDefs=defs,UnitDefNames=names,gadget={},gadgetHandler=env.gadgetHandler,
 VFS={Include=noop},getGameConfig=env.getGameConfig,getSafeHouseTypeTable=env.getSafeHouseTypeTable,
 getCultureUnitModelNames_Dict_DefIDName=env.getCultureUnitModelNames_Dict_DefIDName,
 isCityBuildingHabitable=env.isCityBuildingHabitable}
run('luarules/gadgets/game_buildingPlacementLimitor.lua',pe);placement=pe.gadget;placement:Initialize()
local function tick(n)
 frame=frame+n;area:Update();shared.CityReconstruction:Update(n)
end
local house=S.CreateUnit(3,1500,0,1500,2,0,false)
shared.BuildingTable[house]={x=1500,z=1500,arcology=true,routeID=17}
assert(placement:AllowUnitCreation(5,1,1,1500,0,1500))
S.DestroyUnit(house)
assert(not shared.BuildingTable[house]);assert(not placement:AllowUnitCreation(5,1,1,1500,0,1500))
local plot=shared.CityReconstruction.plots[1];assert(plot and plot.data.routeID==17)
area:ReportIncident(1500,1500,100)
tick(15);local rubble=plot.unitID
assert(units[rubble].def==4 and plot.elapsed==0,'combat must freeze rubble')
assert(masks['93:93']==1)
frame=frame+areaConfig.quietFrames;shared.GlobalGameState='anarchy';tick(30)
assert(plot.stage=='rubble' and plot.elapsed==0,'anarchy must freeze rubble')
shared.GlobalGameState='normal';tick(15);assert(plot.elapsed==15)
-- Reclaiming rubble must not erase the plot or bypass its decay clock.
S.DestroyUnit(rubble);tick(0);assert(plot.unitID~=rubble and plot.elapsed==15)
failed=true;tick(15);assert(plot.stage=='rubble' and units[plot.unitID],'unit-cap failure erased rubble')
failed=false;tick(0);local site=plot.unitID
assert(plot.stage=='construction' and units[site].def==3 and units[site].facing==2)
assert(shared.CityConstructionSites[site]==plot and not shared.BuildingTable[site])
assert(units[site].build<1 and masks['93:93']==1 and not env.isCityBuildingHabitable(site))
assert(not placement:AllowUnitCreation(5,1,1,1500,0,1500))
assert(not city:AllowUnitBuildStep(1,1,site),'repair bypass')
tick(15);local progress,hp=units[site].build,units[site].hp
area:ReportIncident(1500,1500,10);units[site].hp=hp-10;tick(30)
assert(units[site].build==progress and units[site].hp==hp-10,'combat freeze healed/finished site')
-- Attacks elsewhere do not stall this district after its own quiet interval.
frame=frame+areaConfig.quietFrames;area:ReportIncident(6000,6000,100)
shared.GlobalGameState='anarchy';tick(30);assert(shared.CityConstructionSites[site])
shared.GlobalGameState='normal';tick(15)
assert(units[site].build==1 and units[site].hp<1000 and units[site].hp>980)
assert(not shared.CityConstructionSites[site] and shared.BuildingTable[site].arcology)
assert(masks['93:93']==9 and env.isCityBuildingHabitable(site))
assert(placement:AllowUnitCreation(5,1,1,1500,0,1500))
assert(next(shared.CityReconstruction.plots)==nil)
-- Destroying an unfinished replacement returns the same plot to rubble.
S.DestroyUnit(site);tick(30);local second=shared.CityReconstruction.plots[2]
assert(second.stage=='construction');S.DestroyUnit(second.unitID);tick(0)
assert(second.stage=='rubble' and second.elapsed==0 and units[second.unitID].def==4)
assert(shared.CityReconstruction.nextID==2,'destroyed site created duplicate plot')
-- Overlapping masks survive a neighbouring house's destruction.
local a=S.CreateUnit(2,3000,0,3000,0,0,false)
local b=S.CreateUnit(2,3016,0,3000,0,0,false)
S.DestroyUnit(a);assert(masks['188:187']==9 and env.isCityBuildingHabitable(b))
print('PASS city reconstruction: shared incidents, decay/quiet/anarchy gates, failed creates, reclaim, restart, native construction, health, occupancy and overlapping masks')
