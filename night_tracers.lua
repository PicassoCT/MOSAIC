-- Run from the repository root: texlua tests/night_tracers.lua
local Time=dofile('luaui/widgets_mosaic/include/radiance_time.lua')
assert(Time.AtFrame(0)==0 and Time.AtFrame(14400)==1,'day/night phase mismatch')
assert(Time.Intensity(7/24)==0 and Time.Intensity(17/24)==0)
assert(Time.Intensity(6/24)>0 and Time.Intensity(18/24)>0)

lowerkeys=function(t) local r={};for k,v in pairs(t) do r[k:lower()]=v end;return r end
VFS={Include=function(p) return dofile(p) end}
local defs={}
for _,path in ipairs({'machinegun.lua','heavymachinegun.lua','aamachinegun.lua',
    'submachinegun.lua','cGunShipMG.lua','military_support.lua'}) do
    for name,wd in pairs(dofile('weapons/'..path)) do defs[name]=wd end
end
local Sources=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
for _,name in ipairs({'machinegun','heavymachinegun','aamachinegun','submachingegun','cgunshipmg',
    'escortmachinegun','covermachinegun','escortantiair','supportgunshipmg'}) do
    local wd=assert(defs[name]);local cp=wd.customParams or wd.customparams
    local source=Sources.Weapon({name=name,type=wd.weaponType or wd.weapontype,
        customParams=cp,damageAreaOfEffect=wd.areaOfEffect or wd.areaofeffect,size=wd.size})
    assert(source and source.tracer,name..' did not get a night tracer')
end
assert(not Sources.Weapon({name='tankcannon',type='Cannon'}).tracer)
assert(not defs.militaryantiair.customparams.night_tracer,'missile inherited gun tracer')

local vertices,used,removed={},0,0
local camera={0,30,30}
Spring={GetCameraPosition=function() return table.unpack(camera) end,IsSphereInView=function() return true end}
GL={ALL_ATTRIB_BITS=1,ONE=1,QUADS=7}
gl=setmetatable({CreateShader=function() return 1 end,GetUniformLocation=function(_,name) return name end,
    UseShader=function(id) if id~=0 then used=used+1 end end,
    BeginEnd=function(_,fn,...) fn(...) end,
    Vertex=function(x,y,z)
        assert(x==x and y==y and z==z,'camera-axis tracer generated NaN')
        vertices[#vertices+1]={x,y,z}
    end,
    DeleteShader=function() removed=removed+1 end,
}, {__index=function() return function() end end})
VFS.LoadFile=function(p) local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local renderer=assert(dofile('luaui/widgets_mosaic/include/combat_tracers.lua')())
local tracer={x=10,y=4,z=5,vx=20,vy=0,vz=0,width=1,color={1,.5,.1}}
renderer:Draw({tracer},Time.AtFrame(0))
assert(#vertices==0 and used==0,'day tracer was submitted')
renderer:Draw({tracer},Time.AtFrame(14400))
assert(#vertices==4 and used==1,'night tracer absent')
assert(vertices[1][1]==-20 and vertices[3][1]==10,'streak did not trail velocity')
camera={100,4,5};renderer:Draw({tracer},1)
assert(#vertices==8,'camera-axis fallback missing')
tracer.vx=0;renderer:Draw({tracer},1);assert(#vertices==8,'stationary round drew an invalid streak')
renderer:Shutdown();assert(removed==1)
print('PASS: shared night window, nine MG/AA definitions, daylight suppression, velocity-aligned streak, camera-axis fallback and cleanup')
