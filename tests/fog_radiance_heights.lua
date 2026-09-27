-- Run from the game root with Lua 5.4 (or lupa.lua54).
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('luaui/widgets_mosaic/include/radiance_fog_heights.lua')
local function exercise(failure)
 local allocated,deleted,serial={}, {},0
 local boundUniforms,draws,frames={},0,0
 local ownShader,ownFBO
 local hidden,dead,cloaked=false,false,false
 local dims={minx=-20,maxx=20,minz=-40,maxz=40,miny=-8,maxy=392}
 local env=setmetatable({GL={NEAREST=1},Game={mapSizeX=8192,mapSizeZ=8192},
  Spring={ValidUnitID=function() return true end,GetUnitIsDead=function() return dead end,
   GetUnitIsCloaked=function() return cloaked end,GetUnitLosState=function() return {los=not hidden} end,
   GetSpectatingState=function() return false,false end,GetUnitDefID=function() return 1 end,
   GetUnitPosition=function() return 100,300,500 end,GetUnitDefDimensions=function() return dims end,
   GetUnitHeight=function() return 40 end,Echo=function() end},VFS={LoadFile=read}},{__index=_G})
 local function new(kind)
  serial=serial+1
  if failure==serial then return nil end
  local id=kind..serial;allocated[id]=true;return id
 end
 local function delete(id) assert(allocated[id] and not deleted[id]);deleted[id]=true end
 env.gl=setmetatable({
  CreateShader=function() ownShader=new('shader');return ownShader end,
  CreateTexture=function(w,h,options)
   assert(w==512 and h==512 and options.min_filter==1 and options.mag_filter==1)
   return new('texture')
  end,
  CreateFBO=function(options) ownFBO=new('fbo');return ownFBO end,
  IsValidFBO=function() return failure~=5 end,
  DeleteShader=delete,DeleteTexture=delete,DeleteFBO=delete,GetShaderLog=function() return 'expected failure' end,
  GetUniformLocation=function(_,name) return name end,
  Uniform=function(name,...) boundUniforms[name]={...} end,
  ActiveFBO=function(id,fn) assert(id==ownFBO);frames=frames+1;fn() end,
  TexRect=function() draws=draws+1;assert(boundUniforms.sourceY[2]>boundUniforms.sourceY[1]) end,
 },{__index=function() return function() end end})
 local module=assert(load(source,'fog heights','t',env))()
 local building=assert(module.UnitEnvelope(1))
 assert(building.bottom==292 and building.top==692 and building.fade==120,'model/world height lost')
 dims=nil;local fallback=assert(module.UnitEnvelope(1));assert(fallback.bottom==300 and fallback.top==340)
 env.Spring.GetUnitHeight=function() return nil end;assert(not module.UnitEnvelope(1),'unknown height became a column')
 dims={minx=-20,maxx=20,minz=-40,maxz=40,miny=-8,maxy=392}
 hidden=true;assert(not module.UnitEnvelope(1));hidden=false
 dead=true;assert(not module.UnitEnvelope(1));dead=false
 cloaked=true;assert(not module.UnitEnvelope(1));cloaked=false
 local lamp=assert(module.LampEnvelope({a={0,304,0},b={2,306,0},front={0,0,1},range=200}))
 assert(lamp.bottom==300 and lamp.top==310 and lamp.fade==12,'elevated lamp fell to ground')
 local field=module.New()
 field:Refresh({},{});assert(serial==0 and not field.ready,'clear weather allocated resources')
 field:Refresh({[1]=true},{})
 if failure then
  assert(not field.ready and field.failed)
  local attempts=serial;field:Refresh({[1]=true},{});assert(serial==attempts,'failed allocation retried')
 else
  assert(field.ready and frames==1 and draws==1)
  field:Refresh({[1]=true},{});assert(frames==2 and serial==4,'targets were not reused')
  field:Refresh({},{});assert(not field.ready and frames==2,'removed emitters left a live envelope')
 end
 field:Shutdown();field:Shutdown()
 for id in pairs(allocated) do assert(deleted[id],'leaked '..id) end
end
exercise()
for fail=1,5 do exercise(fail) end
print('PASS fog envelopes: imported unit height, world elevation, lamp height, visibility, no unknown-height fallback, allocation/cleanup')
