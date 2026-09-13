-- Standalone Lua regression test; run from the repository root.
local function read(path)
    local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s
end
local function environment(extra)
    return setmetatable(extra or {}, {__index = _G})
end
local function sourceEnv(source, env)
    return assert(load(source, 'test', 't', env))()
end
local shared = read('scripts/lib_building_voxels.lua')
local provider = environment()
sourceEnv(shared, provider)
assert(#provider.GetBuildingShadowColumns().columns == 0)
provider.initializeBuildingShadowVoxels(20, 10)
provider.addShadowVoxel(-10, 10, 25)
provider.addShadowVoxel(-10, 10, 5) -- out of order, hole at floor 1
provider.addShadowVoxel(-10, 10, 5) -- duplicate
provider.addShadowVoxel(10, -10, 0)
local grid = provider.GetBuildingShadowColumns()
assert(grid.columns[1][2] == 3 and grid.columns[2][1] == 1)
assert(grid.columns[1][1] == 0 and grid.columns[2][2] == 0)
assert(grid.baseHeights[1][2] == 5 and grid.masks[1][2] == 5)
assert(grid.originX == -10 and grid.originZ == -10)
assert(not pcall(provider.addShadowVoxel, -10, 10, 7)) -- misaligned floor
provider.initializeBuildingShadowVoxels(20, 10)
assert(#provider.GetBuildingShadowColumns().columns == 0)

-- Full gadget -> unsynced forwarder -> widget protocol, with mocked engine APIs.
local vertices, beginCalls = {}, 0
local gl = setmetatable({GetViewSizes = function() return 1280,720 end,
    Vertex = function(x,y,z) vertices[#vertices+1]={x,y,z} end,
    BeginEnd = function(_, fn, ...) beginCalls=beginCalls+1; fn(...) end,
}, {__index=function() return function() end end})
local spring = {
    ValidUnitID=function() return true end, GetUnitIsDead=function() return false end,
    GetUnitDefID=function() return 1 end,
    GetUnitBasePosition=function() return 100,0,200 end,
    GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
    Echo=function() end, GetSelectedUnits=function() return {42} end,
}
local uiEnv=environment({widget={},gl=gl,Spring=spring,GL={QUADS=1,LINES=2},Game={mapSizeX=1024,mapSizeZ=1024}})
local ui=sourceEnv(read('luaui/widgets_mosaic/gfx_neonlights_radiancecascade.lua')..[[
return {begin=receiveBuildingShadowBegin, add=receiveBuildingShadowColumn,
 finish=receiveBuildingShadowEnd, remove=receiveBuildingShadowRemove,
 buildings=occlusionBuildings, pending=pendingBuildingColumns,
 runs=forEachColumnRun, layer=drawOcclusionLayer, vertex=projectedVertex}
]],uiEnv)
local luaUI=setmetatable({ReceiveBuildingShadowColumnsBegin=ui.begin,
 ReceiveBuildingShadowColumn=ui.add,ReceiveBuildingShadowColumnsEnd=ui.finish,
 ReceiveBuildingShadowColumnsRemove=ui.remove},{__call=function(self,name) return self[name]~=nil end})
local actions={}
local bridgeEnv=environment({gadget={},Script={LuaUI=luaUI},gadgetHandler={
 IsSyncedCode=function() return false end,
 AddSyncAction=function(_,name,fn) actions[name]=fn end,
 RemoveSyncAction=function(_,name) actions[name]=nil end}})
local gadgetSource=read('luarules/gadgets/gfx_building_shadow_volumes.lua')
sourceEnv(gadgetSource,bridgeEnv);bridgeEnv.gadget:Initialize()
local currentGrid=grid
spring.UnitScript={GetScriptEnv=function() return {GetBuildingShadowColumns=function() return currentGrid end} end,
 CallAsUnit=function(_,fn) return fn() end}
local messages={}
local synced=environment({gadget={},GG={},Spring=spring,UnitDefs={{customParams={throwsShadow=true}}},
 gadgetHandler={IsSyncedCode=function() return true end},
 SendToUnsynced=function(name,...)
  for _,v in ipairs({...}) do assert(type(v)=='number' or type(v)=='string' or type(v)=='boolean') end
  messages[#messages+1]=name
  assert(actions[name])(nil,...)
 end})
sourceEnv(gadgetSource,synced);synced.gadget:Initialize()
local function publish(g)
 currentGrid=g; messages={}
 synced.GG.MarkBuildingShadowVolumeDirty(42)
 synced.GG.MarkBuildingShadowVolumeDirty(42)
 synced.gadget:GameFrame()
end
publish(grid)
assert(#messages==4) -- begin, two columns, end, despite two dirty notifications
local building=assert(ui.buildings[42]);assert(#building.columns==8)
local runs={}
ui.runs(building,function(_,x0,y0,z0,x1,y1,z1) runs[#runs+1]={x0,y0,z0,x1,y1,z1} end)
assert(#runs==3)
assert(runs[1][2]==5 and runs[1][5]==15)
assert(runs[2][2]==25 and runs[2][5]==35)
assert(runs[3][2]==0 and runs[3][5]==10)
vertices={};beginCalls=0;ui.layer(0)
assert(beginCalls==1 and #vertices==72)
vertices={};ui.layer(1);assert(#vertices==0) -- above geometry
uiEnv.widget:TextCommand('radiancedebug voxels 42')
vertices={};beginCalls=0;uiEnv.widget:DrawWorld()
assert(beginCalls==2 and #vertices==144)
-- Full model basis, including rotation, without duplicate coordinate arrays.
vertices={};building.front={1,0,0};building.right={0,0,1}
ui.vertex(building,10,5,20)
assert(vertices[1][1]==120 and vertices[1][2]==190)

publish({columns={{2,0},{0,1}},cellSize=20,levelHeight=10})
assert(ui.buildings[42].columns[1]==-10 and ui.buildings[42].columns[2]==-10)
publish({columns={},cellSize=20,levelHeight=10});assert(not ui.buildings[42])
for _,bad in ipairs({
 {columns={{31}},cellSize=20,levelHeight=10},
 {columns={{1},{1,2}},cellSize=20,levelHeight=10},
 {columns={{1}},cellSize=0,levelHeight=10},
 {columns={{1}},cellSize=20,levelHeight=10,masks={{3}}},
 {columns={{1}},cellSize=20,levelHeight=10,baseHeights={{0/0}}},
 {columns={{1}},cellSize=20,levelHeight=10,masks={{0}}},
}) do
 publish(grid);publish(bad)
 assert(#messages==1 and messages[1]=='buildingShadowColumnsRemove' and not ui.buildings[42])
end
publish(grid);synced.gadget:UnitDestroyed(42)
assert(not ui.buildings[42] and not ui.pending[42])
ui.begin(42,1,20,10);ui.add(42,0,0,0,1);ui.remove(42);ui.finish(42)
assert(not ui.buildings[42] and not ui.pending[42])
bridgeEnv.gadget:Shutdown();assert(next(actions)==nil)
synced.gadget:Shutdown();assert(synced.GG.MarkBuildingShadowVolumeDirty==nil)

-- Typical house grids: only 20 occupied columns regardless of floor count.
for _,dim in ipairs({{20.88,14.844375,3},{770,595.4,4},{835.2,683.6,3}}) do
 provider.initializeBuildingShadowVoxels(dim[1],dim[2])
 for floor=0,dim[3]-1 do for x=0,5 do for z=0,5 do
  if x==0 or z==0 or x==5 or z==5 then
   provider.addShadowVoxel((x-2.5)*dim[1],(z-2.5)*dim[1],floor*dim[2])
  end
 end end end
 local g=provider.GetBuildingShadowColumns();local n=0
 for _,row in ipairs(g.columns) do for _,h in ipairs(row) do
  if h>0 then assert(h==dim[3]);n=n+1 end
 end end
 assert(n==20 and not g.masks and not g.baseHeights)
end
print('PASS: offsets, masks, gaps, duplicate/reset, validation, primitive transfer, coalescing, atlas/debug rendering, rotation, replacement/removal and typical house grids')
