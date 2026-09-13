-- Run from repo root with Lua 5.4. Engine calls are mocked.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('luaui/widgets_mosaic/include/radiance_propagation.lua')
local function exercise(failShader,failTexture)
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
    local obj,reason=factory()
    if failShader or failTexture then assert(not obj and reason) else
        assert(obj and not obj.ready)
        obj:Draw('emission','occupancy',0.3,128,256)
        assert(obj.ready and obj.heightMin==128 and obj.heightMax==256)
        assert(obj.baseInterval==8 and #passes==6)
        for i=1,4 do assert(passes[i].index==4-i and passes[i].target==obj.textures[5-i]) end
        assert(uniforms['shader2:intensity'][1]==0.3)
        assert(not bound[0] and not bound[1] and not bound[2] and activeShader==0)
        obj:Shutdown();assert(not obj.ready and not obj.texture and not obj.unitTexture)
        obj:Shutdown() -- idempotent cleanup
    end
    for id in pairs(allocations) do assert(deleted[id], 'Leaked '..id) end
end
exercise()
for i=1,4 do exercise(i,nil) end
for i=1,6 do exercise(nil,i) end
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
env.widget:Update(1);env.widget:DrawWorldPreUnit();assert(renders==10)
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
env.widget:Shutdown();assert(not env.WG.NeonRadiance and next(globals)==nil)
print('PASS: widget propagation/default view, lazy direct diagnostics, height selection, day/night intensity, WG ownership and shutdown')
