-- Run from repository root. Verify cadence without an engine or GL context.
local targets,deleted,allocations={},0,0
local failAllocation=false
GL={RGBA8=1,LINEAR=2,CLAMP_TO_EDGE=3,COLOR_BUFFER_BIT=4,PROJECTION=5,MODELVIEW=6}
gl=setmetatable({CreateTexture=function() allocations=allocations+1;if not failAllocation then return allocations end end,
 DeleteTexture=function() deleted=deleted+1 end,
 RenderToTexture=function(tex,fn,...) targets[tex]=(targets[tex] or 0)+1;fn(...) end},
 {__index=function() return function() end end})
Game={mapSizeX=4096,mapSizeZ=4096}
local make=dofile('luaui/widgets_mosaic/include/headlight_live_field.lua')
local field=assert(make())
assert(allocations==2)
local captures=0
local function capture(bottom,top,gain) assert(bottom==0 and top==128 and gain==1);captures=captures+1 end
local domain={x=0,z=0,span=1024}
for i=1,60 do field:Update(1/60);field:Draw(capture,0,128,domain,true) end
assert(targets[field.localTexture]==60,'near cones missed a rendered frame')
assert(targets[field.texture]>=9 and targets[field.texture]<=11,'coarse cadence not near 10 Hz')
assert(allocations==2,'per-frame texture allocations')
field:Draw(capture,0,128,nil,true)
assert(not field.localReady,'local texture persisted after leaving domain')
field:Draw(nil,0,128,domain,true)
assert(not field.ready and not field.localReady,'stale source after provider removal')
field:Draw(capture,0,128,domain,true)
assert(field.ready and field.localReady,'provider did not recover immediately')
local before=captures
field.enabled=false;field:Draw(capture,0,128,domain,true)
assert(captures==before and not field.ready,'disabled drawing')
field.enabled=true;field:Draw(capture,0,128,domain,false)
assert(captures==before and not field.ready,'daytime drawing')
field:Shutdown();assert(deleted==2,'resource cleanup')
failAllocation=true;assert(make()==nil,'allocation failure should preserve slow fallback')
print('PASS: per-draw local update, 10 Hz coarse update, no per-frame allocations, local domain exit, provider removal/recovery, off/daytime, cleanup and failure fallback')
