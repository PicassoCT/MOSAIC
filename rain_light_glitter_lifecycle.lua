-- Run from the repository root with Lua 5.1+, or Python/lupa.
local bound, uniforms = {}, {}
gl={GetUniformLocation=function(_,name) return name end,
    Texture=function(slot,value) bound[slot]=value end,
    Uniform=function(name,...) uniforms[name]={...} end}
Game={mapSizeX=1024,mapSizeZ=2048}
Spring={GetGameSeconds=function() return 12 end}
WG={}
local bind=dofile('luaui/widgets_mosaic/include/rain_lighting.lua')(1)
bind(true)
assert(uniforms.rainLightActive[1]==0 and bound[10]==false,'missing provider')
local field={texture=1,occupancy=2,bottom=0,top=128,intensity=.5,strength=2}
WG.GetRainRadiance=function() return field end
bind(true)
assert(bound[10]==1 and bound[11]==2 and uniforms.rainLightActive[1]==1)
assert(uniforms.rainLocalActive[1]==0 and bound[12]==1,'coarse fallback')
field.detail={texture=3,occupancy=4,domain={x=32,z=64,span=1024}}
bind(true)
assert(bound[12]==3 and bound[13]==4 and uniforms.rainLocalOrigin[2]==64,'local field')
bind(false)
for i=10,13 do assert(bound[i]==false,'disabled binding retained') end
assert(uniforms.rainLightActive[1]==0)
WG.GetRainRadiance=nil; bind(true)
assert(uniforms.rainLightActive[1]==0,'provider shutdown retained field')
print('PASS: borrowed texture binding, local detail, disabled/missing provider, stale binding cleanup')
