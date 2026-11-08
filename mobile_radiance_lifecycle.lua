-- Optional local RC source-position targets: allocation, MRT routing, fallback,
-- stale-data invalidation and cleanup. Run: texlua tests/mobile_radiance_lifecycle.lua
unpack=unpack or table.unpack
local function read(path) local f=assert(io.open(path));local text=f:read('*a');f:close();return text end
local function loadIn(path,env)
    local chunk=setfenv and setfenv(assert(loadfile(path)),env) or assert(loadfile(path,'t',env))
    return chunk()
end
local function harness(failure)
    failure=failure or {}
    local live, bound, shaders, textures, fbos = {},{},{},{},{}
    local uniforms, passes = {},{}
    local counts={shader=0,texture=0,fbo=0,mrt=0,rtt=0,sourceBytes=0}
    local activeShader
    local alphaTest=true
    local function allocate(kind)
        counts[kind]=counts[kind]+1
        if failure[kind]==counts[kind] then return end
        local id=kind..counts[kind];live[id]=kind;return id
    end
    local function deleted(id,kind)
        assert(live[id]==kind,'unknown/double resource deletion: '..tostring(id))
        live[id]=nil
    end
    local gl={
        CreateShader=function(desc)
            if failure.heightShader and desc.fragment and desc.fragment:find('#define HEIGHT_AWARE 1',1,true) then return end
            local id=allocate('shader');if id then shaders[id]=desc end;return id
        end,
        DeleteShader=function(id) deleted(id,'shader') end,
        CreateTexture=function(w,h,opts)
            local id=allocate('texture');if not id then return end
            textures[id]={w=w,h=h,format=opts.format}
            if opts.format==0x8814 then counts.sourceBytes=counts.sourceBytes+w*h*16 end
            return id
        end,
        DeleteTexture=function(id)
            for fbo,desc in pairs(fbos) do
                assert(not live[fbo] or (desc.color0~=id and desc.color1~=id),'texture deleted before its FBO')
            end
            deleted(id,'texture')
        end,
        CreateFBO=function(desc)
            local id=allocate('fbo');if not id then return end
            assert(live[desc.color0]=='texture' and live[desc.color1]=='texture')
            assert(textures[desc.color0].format==0x881A and textures[desc.color1].format==0x8814)
            assert(textures[desc.color0].w==textures[desc.color1].w and textures[desc.color0].h==textures[desc.color1].h)
            assert(desc.drawbuffers[1]==0x8CE0 and desc.drawbuffers[2]==0x8CE1,'MRT attachment routing wrong')
            fbos[id]=desc;return id
        end,
        IsValidFBO=function() return failure.invalidFBO~=counts.fbo end,
        DeleteFBO=function(id) deleted(id,'fbo') end,
        GetShaderLog=function() return 'mock capability failure' end,
        GetUniformLocation=function(shader,name) return shader..':'..name end,
        Uniform=function(location,...) uniforms[location]={...} end,
        UniformInt=function(location,...) uniforms[location]={...} end,
        Texture=function(unit,texture) bound[unit]=texture end,
        UseShader=function(shader) activeShader=shader end,
        AlphaTest=function(value) alphaTest=value end,
        TexRect=function() assert(alphaTest==false,'cascade data inherited opacity rejection') end,
        ActiveFBO=function(id,callback,...)
            local desc=assert(fbos[id])
            for _,tex in pairs(bound) do assert(tex~=desc.color0 and tex~=desc.color1,'paired target sampled itself') end
            counts.mrt=counts.mrt+1;callback(...)
            passes[#passes+1]={fbo=id,radiance=desc.color0,source=desc.color1,shader=activeShader,
                parent=bound[2],parentSource=bound[5],resolveSource=bound[3]}
        end,
        RenderToTexture=function(id,callback,...)
            for _,tex in pairs(bound) do assert(tex~=id,'ordinary target sampled itself') end
            counts.rtt=counts.rtt+1;callback(...)
        end,
        GetViewSizes=function() return 1280,720 end,
    }
    for _,name in ipairs({'MatrixMode','PushMatrix','LoadIdentity','PopMatrix','DepthTest',
        'DepthMask','Blending','Culling','Color'}) do gl[name]=function() end end
    if failure.missingAPI then gl[failure.missingAPI]=nil end
    local env=setmetatable({gl=gl,GL={},Game={mapSizeX=8192,mapSizeZ=4096},
        Spring={Echo=function() end,TraceScreenRay=function() return 'ground',{2560,0,2048} end,
            GetCameraPosition=function() return 2560,1000,2048 end}}, {__index=_G})
    env.VFS={LoadFile=read,Include=function(path) return loadIn(path,env) end}
    local factory=loadIn('luaui/widgets_mosaic/include/radiance_propagation.lua',env)
    return {factory=factory,env=env,live=live,bound=bound,counts=counts,textures=textures,
        shaders=shaders,fbos=fbos,passes=passes,uniforms=uniforms}
end
local domain={x=1024,z=512,span=1024}
local function draw(s)
    return s:Draw('emission','occupancy',.3,128,256,false,domain,'coarse-emission','coarse-occupancy')
end
local function noLeaks(h) for id in pairs(h.live) do error('leaked '..id) end end

local h=harness();local solver=assert(h.factory(1024,true,true))
assert(solver.heightAware and not solver.ready and not solver.sourceReady)
assert(#solver.textures==4 and #solver.sourceTextures==4 and #solver.fbos==5)
assert(h.counts.texture==10 and h.counts.sourceBytes==8*1024*1024,'local provenance exceeded fixed 8 MiB budget')
local cdesc,rdesc=h.shaders[solver.cascadeShader],h.shaders[solver.resolveShader]
assert(cdesc.fragment:find('#define HEIGHT_AWARE 1',1,true) and rdesc.fragment:find('#define HEIGHT_AWARE 1',1,true))
assert(cdesc.uniformInt.parentSourceTex==5 and rdesc.uniformInt.cascadeSourceTex==3)
draw(solver);assert(solver.ready and solver.sourceReady and h.counts.mrt==5 and h.counts.rtt==0)
for i=1,4 do
    local index=5-i;local pass=h.passes[i]
    assert(pass.radiance==solver.textures[index] and pass.source==solver.sourceTextures[index])
    if index<4 then assert(pass.parent==solver.textures[index+1] and pass.parentSource==solver.sourceTextures[index+1]) end
end
assert(h.passes[5].radiance==solver.unitTexture and h.passes[5].source==solver.unitSourceTexture
    and h.passes[5].resolveSource==solver.sourceTextures[1])
assert(h.uniforms[solver.resolveShader..':mapSize'][1]==1024 and h.uniforms[solver.resolveShader..':mapSize'][2]==1024)
assert(h.uniforms[solver.resolveShader..':domainOrigin'][1]==1024 and h.uniforms[solver.resolveShader..':domainOrigin'][2]==512)
for unit=0,5 do assert(h.bound[unit]==false,'sampler binding leaked: '..unit) end
local texCount=h.counts.texture;draw(solver);assert(h.counts.texture==texCount,'refresh allocated new provenance targets')
assert(solver:Draw('e','o',1,0,128,false,nil)==false and not solver.ready and not solver.sourceReady,
    'camera-local source data survived a missing domain')
draw(solver);solver:Shutdown();solver:Shutdown();assert(not solver.unitSourceTexture);noLeaks(h)

-- Neither the global path nor old single-output factories allocate provenance.
for _,mode in ipairs({{false,true},{true,false}}) do
    h=harness();solver=assert(h.factory(1024,mode[1],mode[2]))
    assert(not solver.heightAware and not solver.unitSourceTexture and h.counts.fbo==0 and h.counts.sourceBytes==0)
    assert(not h.shaders[solver.cascadeShader].uniformInt.parentSourceTex)
    draw(solver);assert(h.counts.mrt==0 and h.counts.rtt==(mode[1] and 5 or 6))
    solver:Shutdown();noLeaks(h)
end

-- Every partially allocated optional path releases its FBOs before textures.
for _,kind in ipairs({'shader','texture','fbo','invalidFBO'}) do
    local maxCount=kind=='shader' and 4 or (kind=='texture' and 10 or 5)
    for index=1,maxCount do
        h=harness({[kind]=index});local failed,reason=h.factory(1024,true,true)
        assert(not failed and reason,'failed allocation did not fail closed: '..kind..index);noLeaks(h)
    end
end
for _,api in ipairs({'CreateFBO','DeleteFBO','ActiveFBO','IsValidFBO'}) do
    h=harness({missingAPI=api});local failed,reason=h.factory(1024,true,true)
    assert(not failed and reason and h.counts.shader==0 and h.counts.texture==0);noLeaks(h)
end

-- The real Local module retries ordinary lighting once if optional source
-- targets are unsupported. A ready source pointer never survives refresh,
-- disabled/invalid domains, or shutdown.
for _,failure in ipairs({{}, {heightShader=true}, {texture=2}, {invalidFBO=1}, {missingAPI='ActiveFBO'}}) do
    h=harness(failure)
    local detail=loadIn('luaui/widgets_mosaic/include/radiance_local.lua',h.env).New()
    local captures=0
    local function capture()
        captures=captures+1
        assert(not detail.ready and detail.sourceTexture==nil,'refresh exposed stale source positions')
    end
    local function refresh() detail:Refresh(2,'coarse-emission','coarse-occupancy',capture,capture) end
    refresh();assert(detail.ready and detail.texture and captures==2,'optional failure removed local lighting')
    if next(failure) then
        assert(not detail.sourceTexture and not detail.solver.heightAware and detail.sourceFailure)
    else
        assert(detail.sourceTexture==detail.solver.unitSourceTexture and detail.solver.sourceReady)
    end
    local allocated=h.counts.texture;refresh();assert(detail.ready and h.counts.texture==allocated,'local fallback retried each refresh')
    detail.enabled=false;refresh();assert(not detail.ready and not detail.sourceTexture and not detail.domain)
    detail.enabled=true;refresh();assert(detail.ready)
    h.env.Spring.TraceScreenRay=function() return nil end
    refresh();assert(not detail.ready and not detail.sourceTexture)
    detail:Shutdown();detail:Shutdown();assert(not detail.sourceTexture and not detail.texture);noLeaks(h)
end
print('PASS: local paired source MRT, fixed 8 MiB provenance, sampler/domain routing, zero feedback, unchanged global path, allocation failure cleanup, lighting fallback and stale-source invalidation')
