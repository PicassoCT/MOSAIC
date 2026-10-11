-- Production mobile data upload/source atlas lifecycle (Lua 5.1 compatible).
unpack=unpack or table.unpack
local function loadIn(path,env)
    local chunk=setfenv and setfenv(assert(loadfile(path)),env) or assert(loadfile(path,'t',env))
    return chunk()
end
local function copy(t) local r={};for k,v in pairs(t) do r[k]=v end;return r end
local function record(id)
    return {unitID=id,shape=1,center={510,35,510},axisX={1,0,0},axisY={0,1,0},axisZ={0,0,1},
        half={30,20,30},minX=480,maxX=540,minZ=480,maxZ=540,minY=15,maxY=55}
end
local function harness(failure)
    failure=failure or {}
    local h={records={record(4095)},stats={minY=15,maxY=55},live={},textures={},fbos={},pixels={},
        counts={shader=0,texture=0,fbo=0,upload=0,collect=0,source=0,clear=0},
        viewport={17,29,1280,720},matrices={[1]=0,[2]=0},draw=1,uniforms={},bindings={}}
    local GL={PROJECTION=1,MODELVIEW=2,POINTS=3,COLOR_BUFFER_BIT=4,DEPTH_BUFFER_BIT=5,LESS=6}
    local target,mode,shader,texcoord,depthWrite,depthTest
    local collector={}
    function collector:Collect(domain,draw)
        assert(domain.margin==512 and domain.minX==h.domain.x and domain.maxX==h.domain.x+h.domain.span)
        assert(draw==h.draw);h.counts.collect=h.counts.collect+1;return h.records,h.stats
    end
    function collector:Invalidate() h.invalidations=(h.invalidations or 0)+1 end
    function collector:Clear() h.clears=(h.clears or 0)+1 end
    function collector:Shutdown() h.closed=true end
    local function allocate(kind)
        h.counts[kind]=h.counts[kind]+1
        if failure[kind]==h.counts[kind] then return end
        local id=kind..h.counts[kind];h.live[id]=kind;return id
    end
    local function deleted(id,kind)
        assert(h.live[id]==kind,'unknown/double delete: '..tostring(id));h.live[id]=nil
    end
    local gl={
        CreateShader=function(desc)
            if desc.vertex then
                assert(desc.vertex:find('gl_MultiTexCoord0',1,true) and desc.fragment:find('gl_FragColor=payload',1,true),
                    'world data went through clamped fixed-function vertex colors')
            else
                assert(desc.uniformInt.sourceTex==0 and desc.fragment:find('texture2D(sourceTex',1,true),
                    'source positions lost their float copy shader')
            end
            return allocate('shader')
        end,
        DeleteShader=function(id) deleted(id,'shader') end,
        GetShaderLog=function() return 'mock shader failure' end,
        CreateTexture=function(w,height,opts)
            local id=allocate('texture');if not id then return end
            h.textures[id]={w=w,h=height,format=opts.format};return id
        end,
        DeleteTexture=function(id)
            for f,desc in pairs(h.fbos) do assert(not h.live[f] or (desc.color0~=id and desc.depth~=id),'texture deleted before FBO') end
            deleted(id,'texture')
        end,
        CreateFBO=function(desc)
            local id=allocate('fbo');if id then h.fbos[id]=desc end;return id
        end,
        IsValidFBO=function() return not failure.invalidFBO end,
        DeleteFBO=function(id) deleted(id,'fbo') end,
        ActiveFBO=function(id,fn,...)
            local oldTarget,oldViewport=target,copy(h.viewport)
            target=h.fbos[id].color0;h.viewport={0,0,h.textures[target].w,h.textures[target].h}
            h.counts.source=h.counts.source+1;fn(...)
            target,h.viewport=oldTarget,oldViewport -- Recoil ActiveFBO restores both.
        end,
        RenderToTexture=function(id,fn,...)
            local oldTarget=target;target=id;h.counts.upload=h.counts.upload+1;fn(...);target=oldTarget
        end,
        Clear=function(bit,...)
            if bit==GL.COLOR_BUFFER_BIT then h.pixels[target]={};h.counts.clear=h.counts.clear+1
            elseif bit==GL.DEPTH_BUFFER_BIT then h.depthClear={...};assert(depthWrite,'depth clear was masked') end
        end,
        TexCoord=function(a,b,c,d) texcoord={a,b,c,d} end,
        Vertex=function(x,y)
            assert(shader and shader~=0 and texcoord and #texcoord==4,'float data shader/payload missing')
            local px=(x+1)*128-.5;local py=(y+1)*16-.5
            assert(math.abs(px-math.floor(px+.5))<.00001 and math.abs(py-math.floor(py+.5))<.00001,'point not on texel center')
            local index=math.floor(py+.5)*256+math.floor(px+.5)
            assert(index>=0 and index<256*32,'data upload escaped fixed target')
            h.pixels[target][index]=copy(texcoord)
        end,
        BeginEnd=function(primitive,fn,...) assert(primitive==GL.POINTS);fn(...) end,
        Color=function(...) for _,v in ipairs({...}) do assert(v>=0 and v<=1,'world data used gl.Color') end end,
        UseShader=function(id) shader=id end,
        MatrixMode=function(value) mode=value end,
        PushMatrix=function() h.matrices[mode]=h.matrices[mode]+1 end,
        PopMatrix=function() h.matrices[mode]=h.matrices[mode]-1;assert(h.matrices[mode]>=0) end,
        Viewport=function(...) h.viewport={...} end,
        DepthMask=function(value) depthWrite=value end,
        DepthTest=function(value) depthTest=value end,
        Texture=function(unit,texture) h.bindings[unit]=texture end,
        Uniform=function(location,...) h.uniforms[location]={...} end,
        UniformInt=function(location,...) h.uniforms[location]={...} end,
        GetUniformLocation=function(_,name) return name end,
        TexRect=function()
            assert(h.viewport[1]==0 and h.viewport[3]==512 and h.bindings[0]=='cascade-source',
                'RC source copy did not fill the left half')
            h.copied=(h.copied or 0)+1
        end,
    }
    for _,name in ipairs({'LoadIdentity','PointSize','Culling','Blending','Ortho','Rotate'}) do gl[name]=function() end end
    if failure.missingAPI then gl[failure.missingAPI]=nil end
    local profiles={test=true}
    local env=setmetatable({gl=gl,GL=GL,Spring={GetDrawFrame=function() return h.draw end},
        VFS={Include=function(path)
            assert(path=='luaui/widgets_mosaic/include/mobile_shadow_sources.lua')
            return {New=function(p,limits) assert(p==profiles and limits.maxCasters==128);return collector end}
        end}}, {__index=_G})
    h.gl,h.GL,h.collector=gl,GL,collector
    h.module=loadIn('luaui/widgets_mosaic/include/mobile_shadow_field.lua',env)
    h.object,h.reason=h.module.New(profiles)
    h.domain={x=0,z=0,span=1024}
    return h
end
local function noLeaks(h) for id in pairs(h.live) do error('leaked '..id) end end
local h=harness();local field=assert(h.object)
assert(h.counts.texture==3 and h.counts.fbo==1 and h.counts.shader==2)
local bytes=0
for _,t in pairs(h.textures) do bytes=bytes+t.w*t.h*(t.format==0x8814 and 16 or 4) end
assert(bytes==10*1024*1024+128*1024,'mobile upload/source atlas exceeded fixed memory budget')
field:Update(h.domain)
local pixels=h.pixels[field.texture]
assert(pixels[0][1]==510 and pixels[0][2]==35 and pixels[0][4]==1 and pixels[4][1]==4095,
    'world position/shape/owner payload was clamped or misplaced')
assert(pixels[1][1]==1 and pixels[1][4]==30 and pixels[2][2]==1 and pixels[2][4]==20)
assert(field.ready and field.count==1 and field.minY==15 and field.maxY==55)
for z=15,16 do for x=15,16 do
    local index=1280+(z*32+x)*4
    assert(pixels[index] and pixels[index][1]==1,'proxy omitted an overlapping spatial cell')
end end
assert(h.stats.occupiedCells==4 and h.stats.gridOverflow==0)
local uploads,collects,allocated=h.counts.upload,h.counts.collect,h.counts.texture
field:Update(h.domain)
assert(h.counts.upload==uploads and h.counts.collect==collects and h.counts.texture==allocated,
    'same-draw update repeated collection/render/allocation')

-- Every full cell retains the nearest sixteen in collector order, with fixed
-- storage and explicit overflow accounting across all overlapped cells.
h.records={};for id=1,128 do h.records[id]=record(id) end
h.draw=h.draw+1;field:Update(h.domain);pixels=h.pixels[field.texture]
assert(field.count==128 and h.stats.gridOverflow==112*4 and h.stats.occupiedCells==4)
local offset=1280+(15*32+15)*4
for i=1,16 do assert(pixels[offset+math.floor((i-1)/4)][(i-1)%4+1]==i,'cell overflow changed nearest ordering') end
field:Invalidate();assert(h.invalidations==1);field:Update(h.domain)
assert(h.counts.upload==uploads+2 and h.counts.texture==allocated)
h.domain={x=128,z=64,span=2048};field:Update(h.domain)
assert(field.originX==-384 and field.originZ==-448 and field.span==3072,'camera domain/margin mapping stale')

-- Source halves keep their independent domains. The atlas FBO clears depth to
-- far, copies RC data left and requests the live renderer's depth-winner mode
-- on the right; ActiveFBO restores the caller viewport, as the engine does.
local beforeViewport=copy(h.viewport)
local detail={ready=true,sourceTexture='cascade-source'}
local calls=0
local function capture(bottom,top,gain,metadata)
    calls=calls+1;assert(bottom==0 and top==128 and gain==1 and metadata==true,'metadata capture flag missing')
    assert(h.depthClear[1]==1 and h.viewport[1]==512 and h.viewport[3]==512 and h.viewport[4]==512,
        'live source pass lost depth reset or right-half viewport')
    -- Live light renderers own nearest-depth selection for strongest sources.
    h.gl.DepthMask(true);h.gl.DepthTest(h.GL.LESS)
end
field:CaptureSources(capture,0,128,h.domain,detail)
assert(calls==1 and h.copied==1 and field.cascadeReady and field.directReady)
for i=1,4 do assert(h.viewport[i]==beforeViewport[i],'source capture changed caller viewport') end
assert(h.matrices[1]==0 and h.matrices[2]==0,'source upload/capture leaked matrix stack')
assert(h.bindings[0]==false)
local locations=field:Locations(1);field:Bind(locations)
assert(h.bindings[14]==field.sourceAtlas and h.bindings[15]==field.texture)
assert(h.uniforms.mobileShadowActive[1]==1 and h.uniforms.mobileShadowCount[1]==128)
assert(h.uniforms.mobileCascadeSourceActive[1]==1 and h.uniforms.mobileDirectSourceActive[1]==1)
field:CaptureSources(nil,0,128,h.domain,{ready=false,sourceTexture='stale'})
assert(not field.cascadeReady and not field.directReady,'removed source provider retained metadata readiness')

-- Removing the crowd clears the full data target; disabling/domain loss skips
-- all further work, and reactivation rebuilds without reallocating resources.
h.records={};h.draw=h.draw+1;field:Update(h.domain)
assert(not field.ready and field.count==0 and next(h.pixels[field.texture])==nil,'removed casters left data behind')
field:CaptureSources(capture,0,128,h.domain,detail);assert(not field.cascadeReady and not field.directReady)
field:Bind(locations);assert(h.uniforms.mobileShadowActive[1]==0)
field.enabled=false;uploads=h.counts.upload;field:Update(h.domain)
assert(h.counts.upload==uploads and h.clears==1)
field.enabled=true;h.records={record(1)};field:Update(h.domain);assert(field.ready and h.counts.texture==allocated)
field:Update(nil);assert(not field.ready and field.count==0 and h.clears==2)
field:Shutdown();field:Shutdown();assert(h.closed);noLeaks(h)

for _,failure in ipairs({{shader=1},{shader=2},{texture=1},{texture=2},{texture=3},{fbo=1},{invalidFBO=true}}) do
    h=harness(failure);assert(not h.object and h.reason,'partial failure returned a live field');noLeaks(h)
end
for _,api in ipairs({'CreateFBO','ActiveFBO','Viewport'}) do
    h=harness({missingAPI=api});assert(not h.object and h.counts.texture==0 and h.counts.shader==0);noLeaks(h)
end
print('PASS: float payload/texel packing, full proxy-grid coverage, deterministic cell overflow, fixed memory, draw reuse, camera/removal lifecycle, metadata/depth/viewport routing and complete allocation cleanup')
