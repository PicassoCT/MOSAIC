-- Lua 5.1 regression: geometry, shared addressing, tooltip and UI lifecycle.
local roads=dofile('scripts/lib_city_roads.lua')
local realRandom=math.random
math.random=function() error('Address code consumed engine RNG') end
local raw={schema=1,generation='map',roads={
    {id='b',name='Café Street',width=25,points={{1000,0},{500,0}}},
    {id='a',name='Café Street',width=25,points={{500,0},{0,0}}},
    {id='c',name='Café Street',width=25,points={{0,1000},{1000,1000}}},
}}
local network=roads.normalize(raw)
assert(network.roads[1].street_id==network.roads[2].street_id)
assert(network.roads[3].street_id~=network.roads[1].street_id,'Separate same-name streets merged')
assert(network.roads[1].name=='Café Street','UTF-8 street name corrupted')
raw.roads={raw.roads[3],raw.roads[2],raw.roads[1]}
assert(roads.encode(network)==roads.encode(roads.normalize(raw)))
assert(roads.encode(network)==roads.encode(roads.decode(roads.encode(network))))
local plots={{x=100,z=100,house_number='3',street_name='Café Street'},
    {x=200,z=100},{x=300,z=100},{x=400,z=-100},{x=500,z=1000},
    {x=600,z=100,street_name='Missing Road',house_number='7A'}}
local a=roads.assign(network,plots)
assert(a['100:100'].house_number=='3' and a['100:100'].number_source=='osm')
assert(a['200:100'].house_number=='1' and a['300:100'].house_number=='5','Generated numbers collided with imported numbers')
assert(a['400:-100'].house_number=='2','Odd/even road side lost')
assert(a['500:1000'].street_id=='c')
assert(a['600:100'].street_name=='Missing Road' and a['600:100'].house_number=='7A')
local reversed={};for i=#plots,1,-1 do reversed[#reversed+1]=plots[i] end
local b=roads.assign(network,reversed)
for key,address in pairs(a) do for field,value in pairs(address) do assert(b[key][field]==value) end end
local grid=roads.grid(2048,2048,281,281,25,'western','seed')
assert(grid.roads[1].points[1][1]==141 and grid.generation=='game')
assert(roads.encode(grid)==roads.encode(roads.grid(2048,2048,281,281,25,'western','seed')))

Game={mapName='Test',mapSizeX=2048,mapSizeZ=2048}
GG={BuildingTable={},GameConfig={city={buildings={sizeX=256,sizeZ=256},alleys={sizeX=25,sizeZ=25}},game={culture='western'}}}
UnitDefs={}
local units={[11]={x=120,z=80},[22]={x=240,z=80},[99]={x=999,z=999}}
local params,rules,tips={},{},{}
Spring={GetUnitPosition=function(id) local p=units[id];if p then return p.x,0,p.z end end,
    GetUnitRulesParam=function(id,k) return (params[id] or {})[k] end,
    SetUnitRulesParam=function(id,k,v) params[id]=params[id] or {};params[id][k]=v end,
    GetGameRulesParam=function(k) return rules[k] end,
    SetGameRulesParam=function(k,v) rules[k]=v end,
    SetUnitTooltip=function(id,t) tips[id]=t end,
    ValidUnitID=function(id) return units[id]~=nil end,
    GetUnitIsDead=function(id) return units[id]==nil end}
VFS={MAP=1,FileExists=function() return true end,
    Include=function(p)
        if p=='scripts/lib_city_roads.lua' then return roads end
        if p=='mosaic/roads.lua' then return network end
        if p=='scripts/lib_UnitScript.lua' or p=='scripts/lib_mosaic.lua' then return end
        if p=='scripts/lib_staticstring.lua' or p=='scripts/lib_civilian_dialogue.lua' then return dofile(p) end
        error('Unexpected include '..p)
    end}
getGameConfig=function() return GG.GameConfig end
isNearCityCenter=function(x,z) assert(math.abs(x)<2048 and math.abs(z)<2048,'Shop coordinates double-scaled');return false end
dofile('scripts/lib_staticstring.lua')
gadget={};gadgetHandler={IsSyncedCode=function() return true end}
dofile('luarules/gadgets/game_city_roads.lua');gadget:Initialize()
GG.BuildingTable[11]={x=100,z=100};GG.BuildingTable[22]={x=200,z=100}
setHouseStreetNameTooltip(22,50000,30000,Game,true,UnitDefs,{'Shop'})
setHouseStreetNameTooltip(11,1,2,Game,false,UnitDefs,{'Shop'})
GG.CitySpawnComplete=true;gadget:GameFrame(2)
assert(params[11].city_plot_key=='100:100' and params[22].city_plot_key=='200:100')
assert(params[11].city_house_number=='1' and params[22].city_house_number=='3')
local original=tips[11]
setHouseStreetNameTooltip(11,9,9,Game,false,UnitDefs,{'Shop'})
assert(tips[11]==original,'Repeated tooltip call changed address')
GG.BuildingTable[99]=GG.BuildingTable[11];units[11]=nil
setHouseStreetNameTooltip(99,5,5,Game,false,UnitDefs,{'Shop'})
assert(params[99].city_plot_key=='100:100' and params[99].city_house_number=='1','Rebuild lost address')
assert(tips[99]==original,'Rebuild changed deterministic descriptor')
assert(not tips[99]:find('^House %- '),'Gadget failed to load house descriptor library')
GG.CityAddressService.SetDescriptor(99,'Arcology')
assert(tips[99]=='Arcology - Café Street 1 [A1]','Arcology title removed address')
-- Simulate LuaRules state loss; public unit parameters preserve living plots.
GG.CityPlotAddresses=nil;GG.BuildingTable={};gadget:Initialize()
setHouseStreetNameTooltip(99,0,0,Game,false,UnitDefs,{'Shop'})
assert(params[99].city_house_number=='1' and params[99].city_plot_x==100)
-- A business array with only one entry must never index beyond it, or use RNG.
for x=1,300 do
    units[99].x=x;GG.BuildingTable[99]={x=x,z=100}
    local name=getHouseShopName(99,{'Only shop'},UnitDefs)
    if name and not name:find("'s ",1,true) then assert(name=='Only shop') end
end
-- Spring gadgets have isolated Lua environments: a descriptor loaded by the
-- city spawner must not accidentally make this service's dependencies pass.
local isolated={gadget={},HouseDescriptor=false}
setmetatable(isolated,{__index=_G})
isolated.VFS={MAP=1,FileExists=VFS.FileExists,Include=function(path)
    if path=='scripts/lib_staticstring.lua' then
        local f
        if setfenv then f=assert(loadfile(path));setfenv(f,isolated)
        else f=assert(loadfile(path,'t',isolated)) end
        return f()
    end
    return VFS.Include(path)
end}
local service
if setfenv then service=assert(loadfile('luarules/gadgets/game_city_roads.lua'));setfenv(service,isolated)
else service=assert(loadfile('luarules/gadgets/game_city_roads.lua','t',isolated)) end
service();isolated.gadget:Initialize()
assert(type(isolated.HouseDescriptor)=='function','Descriptor dependency absent from isolated gadget')
GG.CityAddressService.Register(99,{'Shop'})
assert(not tips[99]:find('^House %- '),'Isolated service lost house descriptor')

-- Unsynced widget: no file reads/mesh rebuild per frame; alpha and resources.
widget={};CITY_ROADS_MAP_WIDGET=nil
VFS.FileExists=function() return false end
local created,deleted,called,vertices,labels=0,0,0,0,0
local alpha
local function noop() end
GL={QUADS=7,SRC_ALPHA=1,ONE_MINUS_SRC_ALPHA=2}
gl={CreateList=function(fn) created=created+1;fn();return created end,
    DeleteList=function() deleted=deleted+1 end,
    BeginEnd=function(_,fn) fn() end,Vertex=function() vertices=vertices+1 end,
    CallList=function() called=called+1 end,Color=function(_,_,_,a) if a and a<1 then alpha=a end end,
    DepthTest=noop,DepthMask=noop,PolygonOffset=noop,Blending=noop,
    GetViewSizes=function() return 1000,1000 end,GetTextWidth=function(s) return #s*0.5 end,
    Text=function() labels=labels+1 end}
Spring.GetGroundHeight=function() return 32 end
Spring.IsSphereInView=function() return true end
Spring.WorldToScreenCoords=function() return 500,500,0.5 end
dofile('luaui/widgets_mosaic/gui_city_roads.lua')
widget:Update(1);assert(created==2 and vertices>0)
widget:Update(1);assert(created==2,'Static road mesh rebuilt each update')
widget:DrawWorld();assert(called==2 and alpha==0.06,'Distant road opacity must be half the old 50%')
Spring.GetCameraPosition=function() return 100,600,100 end
widget:DrawWorld();assert(called==2,'Road overlay remained visible close up')
Spring.GetCameraPosition=function() return 100,1500,100 end
widget:DrawWorld();assert(called==4 and alpha>0 and alpha<0.06,'Zoom fade is not gradual')
widget:DrawScreen();assert(labels==1,'Overlapping road labels were not culled')
rules.city_roads_revision=2;widget:Update(1);assert(created==4 and deleted==2)
widget:Shutdown();assert(deleted==4,'Road mesh leaked on widget shutdown')
math.random=realRandom
print('PASS: deterministic city roads, connected street IDs, OSM addresses, plot rebuilds, tooltips and overlay lifecycle')
