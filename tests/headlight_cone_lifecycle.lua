unpack=unpack or table.unpack
local frame,scans,cones,copies=1,0,0,0
local hidden=false
GL={ONE=1,QUADS=2}
gl=setmetatable({CreateShader=function() return 1 end,
 GetUniformLocation=function(_,name) return name end,
 BeginEnd=function(_,fn,...) cones=cones+1;fn(...) end,
 CopyToTexture=function() copies=copies+1 end,
 CreateTexture=function() return 1 end}, {__index=function() return function() end end})
VFS={LoadFile=function() return '' end}
WG={};Game={mapSizeX=512,mapSizeZ=512};Platform={}
UnitDefs={[1]={speed=50,customParams={}}}
Spring={Echo=function() end,GetDrawFrame=function() return frame end,
 GetGameSeconds=function() return 0 end,
 GetVisibleUnits=function() scans=scans+1;return {1} end,
 GetUnitDefID=function() return 1 end,GetUnitIsDead=function() return false end,
 GetUnitIsCloaked=function() return hidden end,GetUnitTransporter=function() return nil end,
 GetUnitHealth=function() return 100,100,0,0,1 end,
 GetUnitVectors=function() return {0,0,1},{0,1,0},{1,0,0} end,
 GetUnitPosition=function() return 256,0,64 end,
 GetUnitCollisionVolumeData=function() return 40,50,70,0,0,0 end,
 GetUnitPieceMap=function() return {} end,
 GetCameraPosition=function() return 0,100,0 end,GetGroundHeight=function() return 0 end,
 GetViewGeometry=function() return 800,600,0,0 end,
 WorldToScreenCoords=function() return 400,300,.5 end}
local renderer=dofile('luaui/widgets_mosaic/include/vehicle_headlights.lua')()
renderer:SetEmissionOptions({[1]=true},1,true)
local capture=assert(WG.CaptureVehicleHeadlightEmission)
capture(0,128);capture(0,128)
assert(cones==4 and scans==1,'coarse/local capture should share snapshot')
capture(128,256);assert(cones==4,'wrong height emitted')
frame=2;hidden=true;capture(0,128);assert(cones==4,'cloaked source emitted')
hidden=false;frame=3;renderer:SetEmissionOptions({[1]=true},1,false)
capture(0,128);assert(cones==4,'disabled source emitted')
renderer:SetEmissionOptions({[1]=true},1,true)
WG.IsVehicleHeadlightCascadeActive=function() return true end
renderer:Draw({[1]=true},1,false,true);assert(copies==0,'duplicate screen-space lighting')
WG.IsVehicleHeadlightCascadeActive=function() return false end
renderer:Draw({[1]=true},1,false,true);assert(copies==1,'standalone fallback missing')
renderer:Shutdown();assert(WG.CaptureVehicleHeadlightEmission==nil,'stale capture after shutdown')
print('PASS: shared capture, layer rejection, cloak/disable, standalone suppression/fallback, cleanup')
