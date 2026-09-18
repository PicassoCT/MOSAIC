-- Run from repository root with Lua 5.1+, or via Python/lupa.
unpack = unpack or table.unpack
local draws, copies, allocations, deletions = 0, 0, 0, 0
local units, cloaked, carried, built = {1}, false, false, 1
local width, height = 800, 600
local failAllocation = false
GL = {PROJECTION=1,MODELVIEW=2,NEAREST=3,CLAMP_TO_EDGE=4,ONE=5,SRC_ALPHA=6,ONE_MINUS_SRC_ALPHA=7}
gl = setmetatable({}, {__index=function() return function() end end})
gl.CreateShader=function() return 1 end
gl.GetUniformLocation=function(_,name) return name end
gl.CreateTexture=function() allocations=allocations+1; if not failAllocation then return allocations end end
gl.DeleteTexture=function() deletions=deletions+1 end
gl.CopyToTexture=function() copies=copies+1 end
gl.TexRect=function() draws=draws+1 end
VFS={LoadFile=function() return '' end}
WG={}; Game={mapSizeX=512,mapSizeZ=512}; Platform={}
UnitDefs={[1]={speed=50,customParams={}}}
Spring={
 Echo=function() end,
 GetCameraPosition=function() return 0,100,0 end,
 GetVisibleUnits=function() return units end,
 GetUnitDefID=function() return 1 end,
 GetUnitIsDead=function() return false end,
 GetUnitIsCloaked=function() return cloaked end,
 GetUnitTransporter=function() return carried end,
 GetUnitHealth=function() return 100,100,0,0,built end,
 GetUnitVectors=function() return {0,0,1},{0,1,0},{1,0,0} end,
 GetUnitPosition=function() return 256,0,256 end,
 GetUnitCollisionVolumeData=function() return 40,50,70,0,0,0 end,
 GetUnitPieceMap=function() return {} end,
 GetViewGeometry=function() return width,height,0,0 end,
 WorldToScreenCoords=function() return 400,300,.5 end,
}
local constructor=dofile('luaui/widgets_mosaic/include/vehicle_headlights.lua')
local renderer=assert(constructor())
local lampY
gl.Uniform=function(name,...) if name=='lampLeft' then local x,y=...; lampY=y end end
renderer:Draw({[1]=true},1,false,true)
assert(copies==1 and allocations==1 and lampY>0,'surface pass or lamp height')
cloaked=true; renderer:Draw({[1]=true},1,false,true)
cloaked=false; carried=9; renderer:Draw({[1]=true},1,false,true)
carried=false; built=.5; renderer:Draw({[1]=true},1,false,true)
built=1; renderer:Draw({[1]=true},0,false,true)
assert(copies==1,'hidden, transported, unfinished or daytime lights leaked')
units={}; renderer:Draw({[1]=true},1,false,true)
assert(copies==1,'empty scene copied depth')
for i=1,60 do units[i]=i end
draws=0; renderer:Draw({[1]=true},1,false,true)
assert(draws==48 and copies==2 and allocations==1,'road light cap / per-frame depth copy')
renderer:Resize(); assert(deletions==1,'resize cleanup')
width,height=900,700; failAllocation=true
renderer:Draw({[1]=true},1,false,true)
renderer:Draw({[1]=true},1,false,true)
assert(allocations==2,'failed allocation retried every frame')
width,height=1000,700; failAllocation=false
renderer:Draw({[1]=true},1,false,true)
assert(allocations==3,'resolution change did not recover')
renderer:Forget(1); assert(renderer.pieces[1]==nil,'stale unit cache')
renderer:Shutdown(); assert(deletions==2,'shutdown cleanup')
gl.CreateShader=function() return nil end
gl.GetShaderLog=function() return 'expected fixture failure' end
assert(constructor()==nil,'shader failure did not select legacy fallback')
print('PASS: visibility, construction, daytime, light cap, one depth copy, resize/failure recovery, cleanup, shader fallback')
