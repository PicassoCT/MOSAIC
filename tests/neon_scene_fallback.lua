-- Exercise the actual scene factory/draw path with controlled driver failures.
-- Shader compilation and real alpha-test behavior have separate GPU coverage.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local module=read('luaui/widgets_mosaic/include/radiance_scene.lua')
local function run(failures,missing)
 local attempts,logs,draws,deleted={},{},0,0
 local alphaTest=true
 local gl={UniformMatrix=function() end,
  CreateShader=function(spec)
   attempts[#attempts+1]=spec
   if failures[#attempts] then return nil end
   return #attempts
  end,
  GetShaderLog=function() return 'driver rejected variant '..#attempts end,
  GetUniformLocation=function(_,name) return name end,
  TextureInfo=function() return {xsize=640,ysize=480} end,
  Texture=function(unit)
   if failures[1] or missing then assert(unit<14,'fallback touched optional texture unit') end
  end,
  AlphaTest=function(value) alphaTest=value end,
  TexRect=function()
   assert(alphaTest==false,'scene inherited alpha rejection for its additive alpha-zero output')
   draws=draws+1
  end,
  DeleteShader=function()deleted=deleted+1 end}
 setmetatable(gl,{__index=function()return function()end end})
 local env=setmetatable({gl=gl,GL={ONE=1,SRC_ALPHA=2,ONE_MINUS_SRC_ALPHA=3},Game={mapSizeX=8192,mapSizeZ=8192},
  Spring={Echo=function(s)logs[#logs+1]=s end,GetConfigInt=function()return 1 end,
   GetViewGeometry=function()return 640,480,0,0 end},
  VFS={LoadFile=function(path)
   if missing and path:match('mobile_shadow.glsl$') then return nil end
   return read(path)
  end}},{__index=_G})
 local factory
 if setfenv then factory=assert(loadstring(module,'scene'));setfenv(factory,env)
 else factory=assert(load(module,'scene','t',env)) end
 local obj,reason=factory()()
 if failures[2] then
  assert(not obj and reason:match('driver rejected variant 1') and reason:match('driver rejected variant 2'),
   'failure of both shader variants did not preserve both driver logs')
  return
 end
 assert(obj)
 local ordinary=failures[1] or missing
 assert(obj.mobileSupported==not ordinary)
 if ordinary then
  assert(obj.mobileFailure and #logs==1,'fallback hid the original optional shader failure')
  local selected=attempts[#attempts]
  assert(selected.uniformInt.mobileSourceAtlas==nil and selected.uniformInt.mobileShadowData==nil)
  assert(not selected.fragment:find('#define MOBILE_SHADOWS_ENABLED 1',1,true))
 else
  assert(#attempts==1 and attempts[1].uniformInt.mobileSourceAtlas==14
   and attempts[1].uniformInt.mobileShadowData==15,'supported shader lost its mobile source bindings')
  assert(attempts[1].fragment:find('#define MOBILE_SHADOWS_ENABLED 1',1,true))
 end
 obj:Draw('radiance','occupancy',0,128,2,1,nil,nil,nil,nil,nil,
  ordinary and {Locations=function()error('fallback used unsupported shadow provider')end} or nil)
 assert(draws==1,'ordinary fallback stopped the scene lighting pass')
 obj:Shutdown();assert(deleted==1)
end
run({})
run({true})
run({true,true})
run({},true)
print('PASS: full scene, ordinary fallback after driver failure/missing helper, active scene drawing, alpha-test isolation, unsupported provider isolation, failure logs and cleanup')
