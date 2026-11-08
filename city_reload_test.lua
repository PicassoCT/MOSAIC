-- Exercise the production gadget in distinct Lua environments sharing engine state.
local function load(path,env)
 setmetatable(env,{__index=_G});local f=assert(loadfile(path));setfenv(f,env);f();return env
end
local function noop()end
local units,rules,actions,logs={}, {}, {}, {}
local nextID,frame,creates,failTooltip,paths,steep=10,0,0,false,true,false
local defs={
 [1]={id=1,name='house_asian1'},[2]={id=2,name='house_arab0'},[3]={id=3,name='house_western0'},
 [4]={id=4,name='gcscrapheap'},[5]={id=5,name='house_asian0'},[6]={id=6,name='truck_arab0',moveDef={name='truck',id=1}},
}
local names={};for _,d in pairs(defs)do names[d.name]=d end
local config={game={culture='western',states={anarchy='anarchy',postLaunch='postlaunch',gameOver='gameover'}},
 city={population={buildings=5},buildings={sizeX=256,sizeY=64,sizeZ=256},alleys={sizeX=25,sizeZ=25},
 streets={mainStreetModulo=4},rubble={decayFrames=30,constructionFrames=30}},performance={maxCityGenerationSteps=100}}
local function add(x,z,def,extra)
 nextID=nextID+1;units[nextID]={x=x,z=z,def=def or 3,rules=extra or {},health=731};return nextID
end
local S={GetGaiaTeamID=function()return 0 end,GetGameFrame=function()return frame end,
 GetGameRulesParam=function(k)return rules[k]end,SetGameRulesParam=function(k,v)rules[k]=v end,
 GetUnitRulesParam=function(id,k)return units[id] and units[id].rules[k]end,
 SetUnitRulesParam=function(id,k,v)units[id].rules[k]=v end,
 GetAllUnits=function()local t={};for id in pairs(units)do t[#t+1]=id end;return t end,
 GetUnitDefID=function(id)return units[id] and units[id].def end,
 GetUnitPosition=function(id)local u=units[id];if u then return u.x,20,u.z end end,
 GetUnitIsDead=function(id)return not units[id]end,ValidUnitID=function(id)return units[id]~=nil end,
 GetGroundHeight=function()return 20 end,
 GetGroundNormal=function()return 0,steep and .4 or 1,0,steep and .6 or 0 end,
 RequestPath=function()return paths and {} or nil end,
 SetUnitAlwaysVisible=noop,SetUnitBlocking=noop,SetUnitTooltip=noop,
 IsCheatingEnabled=function()return true end,
 Echo=function(s)logs[#logs+1]=s end,
 CreateUnit=function(def,x,y,z)creates=creates+1;return add(x,z,def)end,
 DestroyUnit=function()error('reload must not destroy infrastructure')end,
 GetUnitHealth=function(id)local u=units[id];if u then return u.health,1000,0,0,.5 end end,
 SetUnitHealth=function(id,t)units[id].health=t.health end,
 GetUnitBuildFacing=function()return 0 end,
}
local shared={CityRoadNetwork={roads={{id='retained'}}},CityPlotAddresses={keep={house_number='7A'}},
 CityAreaState={IsPeaceful=function()return false end}}
local function make()
 local env={GG=shared,Spring=S,Game={mapName='Desert_Plateaus',mapSizeX=4096,mapSizeZ=4096},
 UnitDefs=defs,UnitDefNames=names,gadget={},gadgetHandler={IsSyncedCode=function()return true end,
 AddChatAction=function(_,name,fn)actions[name]=fn end,RemoveChatAction=function(_,name)actions[name]=nil end},
 include=function()return {}end,getGameConfig=function()return config end,
 getUnitDefNames=function()return names end,getBuildingScrapHeapTypeTable=function()return {[4]=4}end,
 getBuildingRuinTypeTable=function()return {}end,getCultureUnitModelTypes=function(_,kind)return kind=='truck' and {[6]=6}or {[1]=1,[2]=2,[3]=3,[5]=5}end,
 getHouseTypeIsInnerCityOnly=function()return {}end,removeDictFromDict=function(t)return t end,
 getHouseTypeLimitations=function()return {}end,getLoadAbleTruckTypes=noop,getRefugeeAbleTruckTypes=noop,
 getCultureDependantRandomOffsets=function()return {xRandOffset=0,zRandOffset=0}end,
 doesUnitExistAlive=function(id)return units[id]~=nil end,isMapControlledBuildingPlacement=function()return false end,
 isNearCityCenter=function()return false,10000 end,toString=tostring,
 randDict=function(t)local keys={};for id in pairs(t)do keys[#keys+1]=id end;table.sort(keys);return keys[1]end,
 randSign=function()return 1 end,maRa=function()return true end,
 getUnitPositionV=function(id)local u=units[id];return {x=u.x,y=20,z=u.z}end,
 makeTable=function(value,x,z)local t={};for i=1,x do t[i]={};for j=1,z do t[i][j]=value end end;return t end,
 setHouseStreetNameTooltip=function(id)
  assert(shared.CityAddressService or (shared.CityGenerationState and shared.CityGenerationState.running),
      'reconciliation called address service before it initialized')
  if failTooltip then failTooltip=false;error('injected post-spawn callback failure')end
 end,
 }
 local tick=0;env.math={};for k,v in pairs(math)do env.math[k]=v end
 env.math.random=function(a,b)
  if a==5 and b==31 then tick=tick+1;return tick%2==0 and 10 or 20 end
  return a
 end
 env.VFS={Include=function(path)
  if path=='scripts/lib_house_asian_split.lua' then return {newState=function()return {used={}}end}end
  if path=='scripts/lib_city_ruins.lua' or path=='luarules/gadgets/include/city_reconstruction.lua' or path=='luarules/gadgets/include/city_reload_snapshot.lua' then return dofile(path)end
 end}
 env=dofile('tests/fixtures/city_policy.lua')(env)
 return load('luarules/gadgets/game_spawnCity.lua',env)
end
local original=add(281,281,3,{city_plot_x=281,city_plot_z=281,city_house_number='7A'})
local city=make();city.gadget:Initialize()
assert(shared.BuildingTable[original] and shared.CityGenerationState.consumed==1)
local network,addresses=shared.CityRoadNetwork,shared.CityPlotAddresses
local before=creates
for i=1,3 do actions.cityreload('', '')end
assert(creates==before and shared.CityGenerationState.consumed==1,'reconciliation spawned or charged twice')
assert(shared.CityRoadNetwork==network and shared.CityPlotAddresses==addresses)
assert(units[original].health==731 and units[original].rules.city_house_number=='7A')
-- Fail after a successful CreateUnit. A failed initialization must pause once,
-- retaining the charged plot, instead of receiving a fresh quota next frame.
failTooltip=true
for i=1,5 do frame=i;city.gadget:GameFrame(frame)end
assert(shared.CityGenerationState.failed and shared.CityGenerationState.consumed==2)
local interrupted=creates
local cursor=shared.CityGenerationState.cursor
local steps=shared.CityGenerationState.steps
for i=6,20 do frame=i;city.gadget:GameFrame(frame)end
assert(creates==interrupted,'error restarted generation automatically')
actions.cityreload('', '')
assert(shared.CityGenerationState.cursor==cursor and shared.CityGenerationState.steps==steps,'retry reset traversal progress')
for i=21,30 do frame=i;city.gadget:GameFrame(frame)end
assert(shared.CitySpawnComplete and shared.CityGenerationState.consumed==4,'retry reset or exceeded remaining quota')
local completed=creates
for i=1,3 do actions.cityreload('', '')end
assert(creates==completed and shared.CitySpawnComplete)
-- Same-GG gadget reload retains reconstruction clocks and completed generation.
local reconstruction=shared.CityReconstruction
local plot=reconstruction:Add({x=3000,z=3000,defID=3,data={x=3000,z=3000},facing=0})
plot.elapsed=17
city.gadget:Shutdown();city=make();city.gadget:Initialize()
assert(shared.CityReconstruction==reconstruction and plot.elapsed==17)
assert(shared.CitySpawnComplete and creates==completed)
-- Public engine metadata recovers a completed city even if Lua GG was lost.
shared.innerCityCenter={x=1777,z=2222}
shared.HouseAsianSplitState.used['historic-component']=true
city.gadget:Shutdown()
shared={};city=make();city.gadget:Initialize();city.gadget:GameFrame(100)
assert(shared.CityReconstruction.plots[plot.id].elapsed==17,'full LuaRules reload lost stage clock')
assert(shared.CitySpawnComplete and creates==completed and shared.BuildingTable[original])
assert(shared.CityGenerationState.consumed==4)
assert(shared.innerCityCenter.x==1777 and shared.HouseAsianSplitState.used['historic-component'])
-- A failed/unreachable path must not inherit the old default-true plot mask.
units={};rules={};shared={};paths=false;city=make();city.gadget:Initialize()
for i=1,5 do city.gadget:GameFrame(i)end
assert(creates==completed,'unreachable cells accepted')
assert(city.validFinalCityPlot(1000,1000,false)) -- flat footprint valid
steep=true;assert(not city.validFinalCityPlot(1000,1000,false))
steep=false;shared.CityAddressService={NearestRoad=function()return {distance=0,road={width=25}}end}
assert(not city.validFinalCityPlot(1000,1000,false),'existing road was buildable')
print('PASS: adopt existing infrastructure, idempotent reload, failure after CreateUnit, persistent budget, completed city, reconstruction clock, cold metadata recovery, terrain and road rejection')
