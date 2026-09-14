-- Run from repo root with Lua 5.4. Engine calls are mocked.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('luaui/widgets_mosaic/include/radiance_propagation.lua')
local function exercise(failShader,failTexture,singleOutput)
    local allocations, deleted, bound, passes={}, {}, {}, {}
    local shaders, textures=0,0
    local activeShader
    local uniforms={}
    local gl={
        CreateShader=function()
            shaders=shaders+1
            if shaders==failShader then return nil end
            local id='shader'..shaders;allocations[id]=true;return id
        end,
        CreateTexture=function(w,h,options)
            textures=textures+1
            if textures==failTexture then return nil end
            assert(w<=512 and h<=512 and options.fbo)
            local id='texture'..textures;allocations[id]=true;return id
        end,
        DeleteShader=function(id) assert(allocations[id] and not deleted[id]);deleted[id]=true end,
        DeleteTexture=function(id) assert(allocations[id] and not deleted[id]);deleted[id]=true end,
        GetShaderLog=function() return 'mock failure' end,
        GetUniformLocation=function(shader,name) return shader..':'..name end,
        UseShader=function(id) activeShader=id end,
        Uniform=function(loc,...) uniforms[loc]={...} end,
        UniformInt=function(loc,...) uniforms[loc]={...} end,
        Texture=function(unit,texture) bound[unit]=texture end,
        RenderToTexture=function(target,fn,...)
            for _,texture in pairs(bound) do assert(texture~=target,'Read/write feedback') end
            fn(...);passes[#passes+1]={target=target,shader=activeShader,index=uniforms['shader1:cascadeIndex'][1]}
        end,
    }
    setmetatable(gl,{__index=function() return function() end end})
    local env=setmetatable({gl=gl,GL={},Game={mapSizeX=8192,mapSizeZ=4096},VFS={LoadFile=function(path) return read(path) end}},{__index=_G})
    local factory=assert(load(source,'module','t',env))()
    local obj,reason=factory(1024,singleOutput)
    if failShader or failTexture then assert(not obj and reason) else
        assert(obj and not obj.ready)
        local domain=singleOutput and {x=1024,z=512,span=1024} or nil
        obj:Draw('emission','occupancy',0.3,128,256,false,domain,'coarseE','coarseO')
        assert(obj.ready and obj.heightMin==128 and obj.heightMax==256)
        assert(obj.baseInterval==8 and #passes==(singleOutput and 5 or 6))
        for i=1,4 do assert(passes[i].index==4-i and passes[i].target==obj.textures[5-i]) end
        assert(uniforms['shader2:intensity'][1]==(singleOutput and 1 or 0.3))
        assert(uniforms['shader1:localField'][1]==(singleOutput and 1 or 0))
        assert(uniforms['shader1:mapSize'][1]==(singleOutput and 1024 or 8192))
        assert(not bound[3] and not bound[4])
        assert(not bound[0] and not bound[1] and not bound[2] and activeShader==0)
        obj:Shutdown();assert(not obj.ready and not obj.texture and not obj.unitTexture)
        obj:Shutdown() -- idempotent cleanup
    end
    for id in pairs(allocations) do assert(deleted[id], 'Leaked '..id) end
end
exercise()
exercise(nil,nil,true)
for i=1,5 do exercise(nil,i,true) end
for i=1,4 do exercise(i,nil) end
for i=1,7 do exercise(nil,i) end
print('PASS: cascade ordering, no framebuffer feedback, intensity, readiness, bindings and cleanup at every allocation failure')

-- Whole widget wiring: default preview runs cascades, direct diagnostics are
-- opt-in, height changes reach capture/resolve, and WG/globals are removed.
local renders, captureUniforms, globals, serial=0, {}, {}, 0
local previewRects={}
local previewPosition={100,51,200}
local env=setmetatable({widget={},WG={},Game={mapSizeX=8192,mapSizeZ=8192},GL={},Spring={
 ValidUnitID=function() return true end,GetUnitIsDead=function() return false end,
 GetGameFrame=function() return 0 end,GetUnitPiecePosDir=function() return table.unpack(previewPosition) end,
 GetSelectedUnits=function() return {42} end,
 GetUnitDefID=function() return 7 end,
 GetViewGeometry=function() return 1280,720,0,0 end,
 Echo=function() end,
},widgetHandler={RegisterGlobal=function(_,n,f) globals[n]=f end,
 DeregisterGlobal=function(_,n) globals[n]=nil end,RemoveWidget=function() error('Unexpected removal') end}}, {__index=_G})
env.gl=setmetatable({GetViewSizes=function() return 1280,720 end,
 CreateTexture=function() serial=serial+1;return serial end,
 CreateShader=function() serial=serial+1;return serial end,
 GetUniformLocation=function(_,name) return name end,
 Uniform=function(name,...) captureUniforms[name]={...} end,
 UniformInt=function(name,...) captureUniforms[name]={...} end,
 RenderToTexture=function(_,fn,...) renders=renders+1;fn(...) end,
 BeginEnd=function(_,fn,...) fn(...) end,
 Texture=function() return true end,
 TexRect=function(...) previewRects[#previewRects+1]={...} end,
 GetShaderLog=function() return '' end,
}, {__index=function() return function() end end})
env.VFS={LoadFile=read,Include=function(path) return assert(load(read(path),path,'t',env))() end}
sourceEnv=assert(load(read('luaui/widgets_mosaic/gfx_neonlights_radiancecascade.lua'),'widget','t',env));sourceEnv()
env.widget:Initialize();assert(env.WG.NeonRadiance and not env.WG.NeonRadiance.ready)
globals.RecieveAllNeonUnitsPieces({[42]={1}})
env.widget:Update(1);env.widget:DrawWorldPreUnit()
assert(renders==23 and env.WG.NeonRadiance.ready)
assert(captureUniforms.heightRange[1]==0 and captureUniforms.heightRange[2]==128)
assert(captureUniforms.intensity[1]==0)
env.widget:TextCommand('radiancedebug height 256');env.widget:DrawWorldPreUnit()
assert(captureUniforms.heightRange[1]==256 and captureUniforms.heightRange[2]==384)
assert(env.WG.NeonRadiance.heightMin==256)
env.widget:DrawScreen()
env.widget:TextCommand('radiancedebug direct');renders=0
env.widget:Update(1);env.widget:DrawWorldPreUnit();assert(renders==16)
env.widget:DrawScreen()
-- All diagnostic panels must use the same bounded crop; exposure stays in preview.
env.widget:TextCommand('radiancedebug zoom 1024')
env.widget:DrawWorldPreUnit()
assert(captureUniforms.atlasSize[1]==1024 and captureUniforms.atlasSize[2]==1024)
assert(env.WG.NeonRadiance.heightMin==0)
local function checkPreview(cropped)
 previewRects={};env.widget:DrawScreen()
 assert(#previewRects==4)
 local first=previewRects[1]
 for _,rect in ipairs(previewRects) do
  for j=5,8 do assert(rect[j]==first[j] and rect[j]>=0 and rect[j]<=1) end
 end
 assert(math.abs(first[7]-first[5]-(cropped and 0.125 or 1))<1e-9)
 assert(captureUniforms.exposure[1]==8)
end
env.widget:TextCommand('radiancedebug exposure 8')
checkPreview(true)
-- Moving to the far map edge preserves crop size instead of stretching it.
previewPosition={8190,51,8190};checkPreview(true)
env.widget:TextCommand('radiancedebug zoom off');checkPreview(false)
previewPosition={100,300,200}
env.widget:TextCommand('radiancedebug emitter 42 1')
env.widget:DrawWorldPreUnit();assert(env.WG.NeonRadiance.heightMin==256)
-- Scene consumes its independent 0–128 band even after preview focus at 300.
env.widget:TextCommand('radiancelight test on')
env.widget:DrawWorld()
assert(captureUniforms.heightRange[1]==0 and captureUniforms.heightRange[2]==128)
assert(captureUniforms.nightIntensity[1]==1 and captureUniforms.strength[1]==2)
assert(captureUniforms.textured[1]==1)
env.widget:TextCommand('radiancelight strength 3');env.widget:DrawWorld()
assert(captureUniforms.strength[1]==3)
env.widget:TextCommand('radiancelight off')
captureUniforms.nightIntensity=nil;env.widget:DrawWorld();assert(not captureUniforms.nightIntensity)
env.widget:TextCommand('radiancelight on');env.widget:DrawWorldPreUnit();env.widget:DrawWorld()
assert(captureUniforms.nightIntensity[1]==1)
env.widget:TextCommand('radiancedebug off');previewRects={};env.widget:DrawScreen();assert(#previewRects==0)
env.widget:TextCommand('radiancelight test off')
captureUniforms.nightIntensity=nil;env.widget:DrawWorld();assert(not captureUniforms.nightIntensity)
env.widget:Shutdown();assert(not env.WG.NeonRadiance and next(globals)==nil)
print('PASS: widget propagation/default view, lazy direct diagnostics, height selection, day/night intensity, WG ownership and shutdown')

-- Deferred mode owns no screen textures; depth fallback owns at most one.
local function checkScene()
 local dimensions={1280,720,12,34}
 local deferred=false
 local textures,deleted,bound,uniforms={},{},{},{}
 local allocations,copies,draws=0,0,0
 local failAllocation=false
 local lastBlend,lastDepthMask,lastShader
 local sceneEnv=setmetatable({GL={ONE=1,SRC_ALPHA=2,ONE_MINUS_SRC_ALPHA=3},
  Game={mapSizeX=8192,mapSizeZ=8192},Platform={glSupportClipSpaceControl=true},
  VFS={LoadFile=read},Spring={
   GetViewGeometry=function() return table.unpack(dimensions) end,
   GetConfigInt=function() return deferred and 1 or 0 end,
   Echo=function() end,
  }},{__index=_G})
 sceneEnv.gl=setmetatable({
  CreateShader=function() return 1 end,DeleteShader=function(id) assert(id==1) end,
  GetUniformLocation=function(_,name) return name end,
  TextureInfo=function() return {xsize=dimensions[1],ysize=dimensions[2]} end,
  CreateTexture=function(x,y,opt)
   allocations=allocations+1;assert(x*y<=4*1024*1024 and not opt.fbo)
   if failAllocation then return nil end
   local id='depth'..allocations;textures[id]=true;return id
  end,
  DeleteTexture=function(id) assert(textures[id] and not deleted[id]);deleted[id]=true end,
  CopyToTexture=function(id,tx,ty,vpx,vpy,sx,sy)
   assert(textures[id] and not deleted[id] and tx==0 and ty==0)
   assert(vpx==12 and vpy==34 and sx==dimensions[1] and sy==dimensions[2]);copies=copies+1
  end,
  Uniform=function(name,...) uniforms[name]={...} end,
  UniformInt=function(name,...) uniforms[name]={...} end,
  UniformMatrix=function(name,value) uniforms[name]=value end,
  UseShader=function(id) lastShader=id end,
  Texture=function(unit,id) bound[unit]=id end,
  Blending=function(a,b) lastBlend={a,b} end,
  DepthMask=function(v) lastDepthMask=v end,
  TexRect=function()
   draws=draws+1;assert(bound[0]=='radiance' and bound[1]=='occupancy')
   assert(lastBlend[1]==1 and lastBlend[2]==1 and lastDepthMask==false)
   assert(uniforms.inverseProjection=='projectioninverse' and uniforms.inverseView=='viewinverse')
  end,
 },{__index=function() return function() end end})
 local factory=assert(load(read('luaui/widgets_mosaic/include/radiance_scene.lua'),'scene','t',sceneEnv))()
 local obj=assert(factory())
 local function draw(intensity) obj:Draw('radiance','occupancy',0,128,2,intensity or 0.25) end
 draw(0);assert(draws==0 and allocations==0)
 draw();assert(obj.mode=='depth copy' and copies==1 and allocations==1)
 draw();assert(copies==2 and allocations==1)
 assert(uniforms.nightIntensity[1]==0.25 and uniforms.clipZeroToOne[1]==1)
 for i=0,9 do assert(bound[i]==false) end
 assert(lastShader==0 and lastDepthMask==true and lastBlend[1]==2 and lastBlend[2]==3)
 deferred=true;draw();assert(obj.mode=='deferred' and deleted.depth1 and copies==2)
 assert(uniforms.deferred[1]==1 and allocations==1)
 deferred=false;dimensions={4096,2160,12,34};draw();draw()
 assert(obj.mode=='unavailable' and allocations==1,'Oversize depth texture allocated')
 dimensions={1920,1080,12,34};failAllocation=true;draw();draw()
 assert(allocations==2,'Failed allocation retried every frame')
 obj:Resize();failAllocation=false;draw();assert(allocations==3 and copies==3)
 obj:Shutdown();obj:Shutdown()
 for id in pairs(textures) do assert(deleted[id],'Leaked scene texture') end
end
checkScene()
print('PASS: scene buffer reuse, depth fallback, viewport, memory cap, failure recovery, day skip and GL cleanup')

-- Camera-local domain stability, one-time allocations and coarse input routing.
do
 local allocated,deleted,solves,captures=0,{},0,{}
 local zoom=1000
 local localEnv=setmetatable({Game={mapSizeX=8192,mapSizeZ=4096},GL={},
  Spring={Echo=function() end,TraceScreenRay=function() return "ground",{2560,0,2048} end,
   GetCameraPosition=function() return 2560,zoom,2048 end},
  gl={GetViewSizes=function() return 1280,720 end,
   CreateTexture=function(w,h) allocated=allocated+1;return "capture"..allocated end,
   DeleteTexture=function(id) assert(not deleted[id]);deleted[id]=true end,
   RenderToTexture=function(target,fn,...) fn(...) end},
  VFS={Include=function()
   return function(size,minimal)
    assert(size==1024 and minimal)
    return {unitTexture="fine",Shutdown=function() deleted.solver=true end,
     Draw=function(_,e,o,intensity,lo,hi,sceneOnly,domain,ce,co)
      solves=solves+1;assert(domain.span==1024 or domain.span==2048)
      assert(ce=="coarse-emission" and co=="coarse-occupancy" and lo==128 and hi==256)
     end}
   end
  end}},{__index=_G})
 local module=assert(load(read('luaui/widgets_mosaic/include/radiance_local.lua'),'local','t',localEnv))()
 local a=module.ChooseDomain(2560,2048,1000)
 local b=module.ChooseDomain(2563,2050,1000,1024)
 assert(a.x==b.x and a.z==b.z and a.span/512==2)
 assert(module.ChooseDomain(2560,2048,1500,1024).span==1024)
 assert(module.ChooseDomain(2560,2048,1700,1024).span==2048)
 assert(not module.ChooseDomain(2560,2048,4000,2048))
 local edge=module.ChooseDomain(8191,4095,1000)
 assert(edge.x+edge.span<=8192 and edge.z+edge.span<=4096)
 local detail=module.New()
 local function capture(layer,domain) captures[#captures+1]=layer end
 local function refresh() detail:Refresh(2,"coarse-emission","coarse-occupancy",capture,capture) end
 refresh();assert(detail.ready and allocated==2 and solves==1)
 assert(captures[1]==2 and captures[2]==1)
 refresh();assert(allocated==2 and solves==2)
 zoom=4000;refresh();assert(not detail.ready and solves==2)
 zoom=1000;refresh();assert(detail.ready and allocated==2)
 detail.enabled=false;refresh();assert(not detail.ready)
 detail:Shutdown();detail:Shutdown();assert(deleted.solver and deleted.capture1 and deleted.capture2)
end
print('PASS: local patch snapping, zoom hysteresis, map-edge bounds, scene-band capture, reuse and cleanup')
