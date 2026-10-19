-- Exercise the production window-light module with an instrumented GL boundary.
-- Run from the repository root:
--   texlua tests/window_lighting_continuity.lua [--compare /path/to/old/window_lighting.lua] [--cpu] [--strict-cost]
-- Counts describe submitted work and nominal texture payloads, NOT GPU timings.
-- Texture contents are symbolic completed-bake contributions, so sampling an
-- unfinished field or losing an unaffected house is observable without a GPU.
-- Normal comparison enforces explicit budgets: one 512-KiB staging texture;
-- one extra atlas copy for immediate 3-to-2 removal (with or without a gain
-- change); two for the explicit strength-control sequence; three for exact
-- cutoff reclassification when the gain retention bounds are crossed.
-- --strict-cost additionally rejects all those intentional extra atlas copies.
-- Texture payload increases are always reported and capped at 512 KiB.
local function read(path)
    local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
local modulePath='luaui/widgets_mosaic/include/window_lighting.lua'
local baselinePath,cpuBenchmark,strictCost
for i=1,#arg do
    if arg[i]=='--compare' then baselinePath=assert(arg[i+1],'--compare needs a module path') end
    if arg[i]=='--cpu' then cpuBenchmark=true end
    if arg[i]=='--strict-cost' then strictCost=true end
end
local source=read(modulePath)
local GL={
    RGBA32F=0x8814,RGBA16F=0x881A,RGBA8=0x8058,R32F=0x822E,R8=0x8229,
    DEPTH_COMPONENT24=0x81A6,COLOR_BUFFER_BIT=0x4000,DEPTH_BUFFER_BIT=0x100,
    COLOR_ATTACHMENT0_EXT=0x8CE0,COLOR_ATTACHMENT1_EXT=0x8CE1,
    PROJECTION=0x1701,MODELVIEW=0x1700,POINTS=0,RGBA=0x1908,
    ONE=1,ZERO=0,LESS=0x0201,LEQUAL=0x0203,NEAREST=0x2600,LINEAR=0x2601,
    CLAMP_TO_EDGE=0x812F,SRC_ALPHA=0x0302,ONE_MINUS_SRC_ALPHA=0x0303,
}
local bytesPerPixel={
    [GL.RGBA32F]=16,[GL.RGBA16F]=8,[GL.RGBA8]=4,[GL.R32F]=4,
    [GL.R8]=1,[GL.DEPTH_COMPONENT24]=3,
}
local measured={
    'captureDraws','wallDraws','readbacks','readbackPixels','bakeChunks','bakePoints',
    'blockerPacks','blockerCopies','atlasPasses','atlasCopies','groundUploads',
    'dataVertices','textureAllocations','textureAllocatedBytes',
}
local gpuCounters={
    'captureDraws','wallDraws','readbacks','bakeChunks','blockerPacks','blockerCopies',
    'atlasPasses','atlasCopies','groundUploads','dataVertices','textureAllocations',
}
local function shallow(t)local c={};for k,v in pairs(t) do c[k]=v end;return c end
local function contents(t)
    local c={}
    for id,entry in pairs(t or {}) do
        c[id]={revision=entry.revision,epoch=entry.epoch,gain=entry.gain,chunks=shallow(entry.chunks)}
    end
    return c
end
local function keys(t)local r={};for id in pairs(t) do r[#r+1]=id end;table.sort(r);return r end
local function chunkCount(t)local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function idRange(n)local t={};for i=1,n do t[i]=i end;return t end

local function harness(code,count)
    local h={units={},camera={},positionIDs={},selected=1,epoch=1,intensity=1,frame=0,errors={},metrics={},phase='setup',
        allocations={},textures={},lists={},shaders={},uniforms={},bound={},matrixDepth=0,
        serial=0,liveBytes=0,peakBytes=0,maxStepChunks=0,maxRefreshChunks=0,maxFrameChunks=0,
        required={},forbidden={},firstErrors={},luaSeconds=0}
    for _,name in ipairs(measured) do h.metrics[name]=0 end
    for id=1,count do
        h.units[id]={id=id,revision=1,los=true,dead=false,cloaked=false,exists=true,x=200+id*300,y=10,z=600}
        h.camera[id]=true;h.positionIDs[h.units[id].x]=id
    end
    function h:fail(message)
        local key=self.phase..': '..message
        if not self.firstErrors[key] then self.errors[#self.errors+1]=key;self.firstErrors[key]=true end
    end
    function h:allocate(kind,value)
        self.serial=self.serial+1;local id=kind..self.serial
        self.allocations[id]={kind=kind,value=value};return id
    end
    function h:delete(id,kind)
        local allocation=assert(self.allocations[id],'delete of unknown/already deleted '..tostring(id))
        assert(allocation.kind==kind,'resource deleted with wrong API')
        self.allocations[id]=nil
        if kind=='texture' then self.liveBytes=self.liveBytes-self.textures[id].bytes;self.textures[id].deleted=true end
    end
    local activeTarget,activeShader,compileList
    local function targetTexture()
        if not activeTarget then return end
        if h.textures[activeTarget] then return h.textures[activeTarget] end
        local fbo=h.allocations[activeTarget];return fbo and h.textures[fbo.value.color0]
    end
    local function bump(name,n)h.metrics[name]=h.metrics[name]+(n or 1)end
    local function shaderKind(desc)
        local u=desc.uniformInt or {}
        if u.emissionTex then return 'project' end
        if u.materialTex and u.sourceTex then return 'capture' end
        if u.materialTex and u.exteriorTex then return 'debug' end
        if u.sourceTex then return 'copy' end
        if desc.geometry then return 'walls' end
        return 'data'
    end
    local gl={}
    function gl.CreateTexture(w,ht,options)
        local bpp=assert(bytesPerPixel[options.format],'unaccounted texture format '..tostring(options.format))
        local t={w=w,h=ht,format=options.format,bytes=w*ht*bpp,contents={}}
        if options.format==GL.RGBA16F and w==1024 then t.kind='atlas'
        elseif options.format==GL.RGBA16F and w==256 then t.kind='field'
        elseif options.format==GL.R8 and w==2048 then t.kind='blockers'
        elseif options.format==GL.R32F then t.kind='ground'
        else t.kind='data' end
        local id=h:allocate('texture',t);h.textures[id]=t
        bump('textureAllocations');bump('textureAllocatedBytes',t.bytes)
        h.liveBytes=h.liveBytes+t.bytes;h.peakBytes=math.max(h.peakBytes,h.liveBytes);return id
    end
    function gl.DeleteTexture(t)h:delete(t,'texture')end
    function gl.CreateShader(desc)
        local id=h:allocate('shader',desc);h.shaders[id]={kind=shaderKind(desc),uniforms={}};return id
    end
    function gl.DeleteShader(id)h:delete(id,'shader')end
    function gl.CreateFBO(desc)return h:allocate('fbo',desc)end
    function gl.DeleteFBO(id)h:delete(id,'fbo')end
    function gl.IsValidFBO()return true end
    function gl.GetShaderLog()return 'symbolic fixture'end
    function gl.CreateList(fn)
        local id=h:allocate('list',{});h.lists[id]={points=0};compileList=id;fn();compileList=nil;return id
    end
    function gl.DeleteList(id)h:delete(id,'list')end
    function gl.GetUniformLocation(id,key)return {shader=id,key=key}end
    function gl.Uniform(location,...)h.shaders[location.shader].uniforms[location.key]={...}end
    gl.UniformInt=gl.Uniform
    function gl.UseShader(id)activeShader=id~=0 and h.shaders[id] or nil end
    function gl.Texture(slot,id)
        if id==nil then id=slot;slot=0 end
        if h.textures[id] then assert(not h.textures[id].deleted,'sampled deleted texture') end
        h.bound[slot]=id;return true
    end
    function gl.PushMatrix()h.matrixDepth=h.matrixDepth+1 end
    function gl.PopMatrix()h.matrixDepth=h.matrixDepth-1;assert(h.matrixDepth>=0)end
    function gl.BeginEnd(_,fn)fn()end
    function gl.Vertex()
        if compileList then h.lists[compileList].points=h.lists[compileList].points+1
        elseif activeShader and activeShader.kind=='data' then bump('dataVertices') end
    end
    function gl.ActiveFBO(id,fn)
        local previous=activeTarget;activeTarget=id;fn();activeTarget=previous
    end
    function gl.RenderToTexture(id,fn)
        assert(h.textures[id] and not h.textures[id].deleted,'rendered to missing/deleted texture')
        for _,bound in pairs(h.bound) do assert(bound~=id,'framebuffer feedback') end
        local target=h.textures[id]
        if target.kind=='atlas' then bump('atlasPasses')
        elseif target.kind=='blockers' then bump('blockerPacks');target.epoch=h.epoch
        elseif target.kind=='ground' then bump('groundUploads') end
        local previous=activeTarget;activeTarget=id;fn();activeTarget=previous
    end
    function gl.Clear(mask)
        if mask~=GL.COLOR_BUFFER_BIT then return end
        local t=targetTexture();if t then t.contents={} end
    end
    function gl.Unit(id,raw,lod,noLua)
        assert(h.units[id] and raw and lod==-1 and noLua,'unexpected capture draw')
        assert(activeShader,'unit draw without shader')
        if activeShader.kind=='capture' then
            bump('captureDraws')
            local desc=h.allocations[activeTarget].value
            for _,key in ipairs({'color0','color1'}) do
                local t=h.textures[desc[key]];t.source=id;t.revision=h.units[id].revision
            end
        elseif activeShader.kind=='walls' then bump('wallDraws');targetTexture().source=id end
    end
    function gl.CallList(id)
        assert(activeShader and activeShader.kind=='project','unexpected display list use')
        local target=assert(targetTexture());assert(target.kind=='field','bake target is not field')
        local emission=assert(h.textures[h.bound[0]]);assert(emission.source,'baking unknown capture')
        local blockers=assert(h.textures[h.bound[4]])
        local entry=target.contents[emission.source]
        if not entry then
            entry={revision=emission.revision,epoch=blockers.epoch,chunks={}};target.contents[emission.source]=entry
        end
        assert(entry.revision==emission.revision and entry.epoch==blockers.epoch,'mixed generations in one field')
        entry.chunks[id]=true;bump('bakeChunks');bump('bakePoints',h.lists[id].points)
        h.lastBakeSource=emission.source;h.lastBakeChunks=chunkCount(entry.chunks)
    end
    function gl.TexRect()
        if not activeShader or activeShader.kind~='copy' then return end
        local target=targetTexture();if not target then return end
        local input=h.textures[h.bound[0]]
        if target.kind=='atlas' then
            bump('atlasCopies');assert(input and not input.deleted,'atlas sampled a missing field')
            for id,entry in pairs(input.contents) do
                if chunkCount(entry.chunks)~=16 then h:fail('partial field published for house '..id) end
                if target.contents[id] then h:fail('house copied twice into atlas '..id) end
                target.contents[id]=contents({[id]=entry})[id]
                target.contents[id].gain=(entry.gain or 1)*((activeShader.uniforms.gain or {1})[1])
            end
        elseif target.kind=='blockers' then bump('blockerCopies') end
    end
    function gl.ReadPixels(_,__,w,ht)
        bump('readbacks');bump('readbackPixels',w*ht)
        local rows={};for x=1,w do rows[x]={} end
        for y=0,ht-1 do for x=0,w-1 do
            -- Conventional layout. The existing lifecycle suite separately
            -- exercises the legacy Recoil chunked ReadPixels layout.
            rows[x+1][y+1]=w==2 and {x,y,0,1} or w==256 and {1,1,1,1} or {0,0,0,0}
        end end
        return rows
    end
    function gl.GetViewSizes()return 1280,720 end
    setmetatable(gl,{__index=function()return function()end end})
    local Spring={
        Echo=function(message)if not h.commandEcho then h:fail('production renderer reported: '..message)end end,
        ValidUnitID=function(id)return h.units[id] and h.units[id].exists end,
        GetUnitIsDead=function(id)return h.units[id].dead end,
        GetUnitIsCloaked=function(id)return h.units[id].cloaked end,
        GetUnitDefID=function(id)return id%2==0 and 8 or 7 end,
        GetUnitPosition=function(id)local u=h.units[id];return u.x,u.y,u.z end,
        GetUnitTransformMatrix=function(id)local u=h.units[id];return 1,0,0,0,0,1,0,0,0,0,1,0,u.x,u.y,u.z,1 end,
        GetUnitPieceMatrix=function()return 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1 end,
        GetUnitPieceInfo=function()return {min={-80,0,-80},max={180,400,80}}end,
        GetUnitLosState=function(id)return {los=h.units[id].los}end,
        GetSpectatingState=function()return false,false end,
        GetUnitRulesParam=function(id,key)
            if key=='mosaic_window_revision' then return h.units[id].revision end
            if key=='mosaic_window_piece_count' or key=='mosaic_window_piece_1' then return 1 end
        end,
        GetAllUnits=function()
            local all={};for _,id in ipairs(keys(h.units)) do if h.units[id].exists then all[#all+1]=id end end;return all
        end,
        GetSelectedUnits=function()return {h.selected}end,
        GetCameraPosition=function()return 500,100,600 end,
        IsSphereInView=function(x)return h.camera[h.positionIDs[x]]end,
        GetGroundHeight=function()return 10 end,
    }
    local env=setmetatable({gl=gl,GL=GL,Game={mapSizeX=16384,mapSizeZ=16384},Spring=Spring,
        UnitDefs={[7]={name='house_asian1'},[8]={name='house_asian3'}}},{__index=_G})
    env.VFS={LoadFile=read,Include=function(path)return assert(load(read(path),path,'t',env))()end}
    h.object=assert(load(code,'window-light-under-test','t',env))()()
    h.occupancy={};for i=1,16 do h.occupancy[i]='external-occupancy-'..i end
    function h:move(id,x,z)
        self.positionIDs[self.units[id].x]=nil;self.units[id].x=x;self.units[id].z=z or self.units[id].z
        self.positionIDs[x]=id
    end
    function h:visible()
        if not self.object.ready then return {} end
        local atlas=self.textures[self.object.texture];return atlas and atlas.contents or {}
    end
    function h:observe()
        local visible=self:visible()
        if self.checkGain then
            for id,entry in pairs(visible) do
                local displayGain=(entry.gain or 1)*(self.object.presentationGain or 1)
                if math.abs(displayGain-self.intensity*self.object.strength)>1e-10 then
                    self:fail('displayed gain did not follow night intensity for house '..id)
                end
            end
        end
        if not self.firstVisibleChunks and next(visible) then
            self.firstVisibleChunks=self.metrics.bakeChunks;self.firstVisibleFrame=self.frame
        end
        for _,id in ipairs(self.required) do
            if not visible[id] then self:fail('unaffected house disappeared '..id) end
        end
        for _,id in ipairs(self.forbidden) do
            if visible[id] then self:fail('invalid house still visible '..id) end
        end
    end
    function h:action(kind,fn)
        local chunks=self.metrics.bakeChunks;local start=os.clock();fn();self.luaSeconds=self.luaSeconds+os.clock()-start
        local cost=self.metrics.bakeChunks-chunks
        if kind=='step' then self.maxStepChunks=math.max(self.maxStepChunks,cost)
        elseif kind=='refresh' then self.maxRefreshChunks=math.max(self.maxRefreshChunks,cost) end
        if not self.object.enabled then self:fail('renderer disabled') end
        self:observe()
    end
    function h:refresh(changed,intensity)
        if intensity~=nil then self.intensity=intensity end
        self:action('refresh',function()self.object:Refresh(self.occupancy,changed or false,self.intensity)end)
    end
    function h:step()self:action('step',function()self.object:Step()end)end
    function h:command(text)
        self.commandEcho=true;assert(self.object:TextCommand(text),'test command unhandled');self.commandEcho=false
    end
    function h:advance(frames,onRefresh)
        for _=1,frames do
            self.frame=self.frame+1;local chunks=self.metrics.bakeChunks
            self:step()
            if self.frame%6==0 then
                if onRefresh then onRefresh(self) end
                self.object:Update(0.2);self:refresh()
            end
            self.maxFrameChunks=math.max(self.maxFrameChunks,self.metrics.bakeChunks-chunks)
        end
    end
    function h:settle(ids,epoch,maxFrames,onRefresh)
        local function done()
            local visible=self:visible()
            for _,id in ipairs(ids) do
                local entry=visible[id]
                if not entry or entry.revision~=self.units[id].revision or (epoch and entry.epoch~=epoch) then return false end
            end
            return true
        end
        -- Fixed schedules keep baseline and patched stimulus identical. Stopping
        -- when old light remains visible would under-count a background rebuild.
        local frames=maxFrames or 1200
        self:advance(frames,onRefresh)
        if not done() then self:fail('did not settle within '..frames..' frames') end
        return frames
    end
    function h:checkpoint()local c=shallow(self.metrics);c.liveBytes=self.liveBytes;c.peakBytes=self.peakBytes;return c end
    function h:delta(before)local c={};for _,name in ipairs(measured) do c[name]=self.metrics[name]-before[name] end;return c end
    function h:warm(ids)
        self.phase='cold';self:refresh();self:settle(ids,self.epoch)
        self.required=ids;self:observe()
    end
    function h:close()
        self.required={};self.object:Shutdown();self.object:Shutdown()
        assert(self.liveBytes==0 and not next(self.allocations),'GL resource leak')
        assert(self.matrixDepth==0,'unbalanced matrix stack')
    end
    return h
end

local scenarios={}
local function scenario(name,count,fn)scenarios[#scenarios+1]={name=name,count=count,run=fn}end
scenario('cold_32',32,function(h)h:warm(idRange(32))end)
scenario('warm_32',32,function(h)
    h:warm(idRange(32));local before=h:checkpoint();h.phase='warm';h:advance(360)
    local delta=h:delta(before)
    for _,name in ipairs(gpuCounters) do if delta[name]~=0 then h:fail('warm cache repeated '..name) end end
    return before
end)
scenario('warm_selection_reorder',32,function(h)
    h:warm(idRange(32));local before=h:checkpoint();h.phase='warm_reorder'
    h:advance(360,function(f)f.selected=f.selected%32+1 end)
    local delta=h:delta(before)
    for _,name in ipairs(gpuCounters) do if delta[name]~=0 then h:fail('selection-only change repeated '..name) end end
    return before
end)
scenario('camera_admission',3,function(h)
    h.camera[3]=false;h:warm({1,2});local before=h:checkpoint();h.phase='admit';h.camera[3]=true
    h:refresh();h:settle({1,2,3},nil);return before
end)
scenario('camera_eviction',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='evict';h.required={1,2};h.forbidden={3};h.camera[3]=false
    h:refresh();h:settle({1,2},nil);h:advance(72);return before
end)
scenario('distant_admission',3,function(h)
    h:move(3,10000);h.camera[3]=false;h:warm({1,2});local before=h:checkpoint();h.phase='distant_admit';h.camera[3]=true
    h:refresh();h:settle({1,2,3},nil)
    if h.metrics.bakeChunks-before.bakeChunks~=16 then h:fail('distant admission rebaked unaffected houses')end
    return before
end)
scenario('distant_eviction',3,function(h)
    h:move(3,10000);h:warm({1,2,3});local before=h:checkpoint();h.phase='distant_evict';h.required={1,2};h.forbidden={3};h.camera[3]=false
    h:refresh();h:settle({1,2},nil)
    if h.metrics.bakeChunks~=before.bakeChunks then h:fail('distant eviction rebaked unaffected houses')end
    return before
end)
scenario('camera_limit_replacement',33,function(h)
    h:warm(idRange(32));local before=h:checkpoint();h.phase='replace_32nd';h.required=idRange(31);h.forbidden={32};h.selected=33
    h:refresh();local ids=idRange(31);ids[#ids+1]=33;h:settle(ids,nil);h:advance(72);return before
end)
scenario('occlusion_rebuild_32',32,function(h)
    h:warm(idRange(32));local before=h:checkpoint();h.phase='occlusion';h.epoch=h.epoch+1
    h:refresh(true);h:settle(idRange(32),h.epoch);return before
end)
scenario('occlusion_with_reordering',32,function(h)
    h:warm(idRange(32));local before=h:checkpoint();h.phase='occlusion_reorder';h.epoch=h.epoch+1
    h:refresh(true)
    h:settle(idRange(32),h.epoch,1200,function(f)f.selected=f.selected%32+1 end)
    return before
end)
scenario('normal_night_rebuild_32',32,function(h)
    local time=assert(load(read('luaui/widgets_mosaic/include/radiance_time.lua'),'radiance-time','t',{}))()
    local nightStart=0.1;h.intensity=time.Intensity(nightStart)
    h:warm(idRange(32));local before=h:checkpoint();h.phase='normal_night_rebuild';h.checkGain=true
    local startFrame=h.frame;h.epoch=h.epoch+1;h:refresh(true)
    h:settle(idRange(32),h.epoch,600,function(f)
        f.intensity=time.Intensity(nightStart+(f.frame-startFrame)/time.dayLength)
    end)
    return before
end)
scenario('warm_shutdown_reenable',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='reenable';h.required={}
    h.object:Shutdown()
    -- This reproduces the warm failure cleanup without injecting an unrelated
    -- driver error. A fresh atlas must not inherit the old publication state.
    h:refresh()
    if h.object.ready and not next(h:visible()) then h:fail('uninitialized atlas advertised as ready')end
    h:settle({1,2,3},h.epoch);return before
end)
scenario('daytime_invalidation_resume',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='dawn';h.checkGain=true;h:refresh(false,0.05)
    h.phase='day';h.required={};h.epoch=h.epoch+1
    local dayBefore=h:checkpoint();h:refresh(true,0);h:advance(60)
    if h.object.ready then h:fail('daytime remained active')end
    for _,name in ipairs(gpuCounters) do if h:delta(dayBefore)[name]~=0 then h:fail('daytime submitted '..name)end end
    h.phase='dusk';h.required={1,2,3};h:refresh(false,0.2);h:settle({1,2,3},h.epoch)
    return before
end)
scenario('strength_during_rebuild',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='strength_rebuild';h.checkGain=true
    h.epoch=h.epoch+1;h:refresh(true);h:advance(6)
    h:command('windowlight strength 2');h:refresh();h:advance(6)
    h.phase='strength_zero';h.required={};h:command('windowlight strength 0')
    local zeroBefore=h:checkpoint();h:refresh();h:advance(12)
    if h.object.ready then h:fail('zero strength remained active')end
    for _,name in ipairs(gpuCounters) do if h:delta(zeroBefore)[name]~=0 then h:fail('zero strength submitted '..name)end end
    h.phase='strength_resume';h.required={1,2,3};h:command('windowlight strength 0.7');h:refresh()
    h:settle({1,2,3},h.epoch);return before
end)
scenario('gain_retention_bounds',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='gain_bounds';h.checkGain=true
    h.epoch=h.epoch+1;h:refresh(true)
    local atlas=h.metrics.atlasPasses
    h:refresh(false,0.9);h:refresh(false,0.8)
    if h.metrics.atlasPasses~=atlas then h:fail('gain inside retention bounds redrew the pending atlas')end
    h:refresh(false,0.79)
    if h.metrics.atlasPasses~=atlas+1 then h:fail('gain below retention bound did not refresh cutoff classification')end
    atlas=h.metrics.atlasPasses
    h:refresh(false,0.79*1.25)
    if h.metrics.atlasPasses~=atlas then h:fail('gain at upper retention bound redrew the pending atlas')end
    h:refresh(false,1)
    if h.metrics.atlasPasses~=atlas+1 then h:fail('gain above retention bound did not refresh cutoff classification')end
    h:settle({1,2,3},h.epoch);return before
end)
scenario('capture_batch_with_gain',5,function(h)
    h.camera[3]=false;h.camera[4]=false;h.camera[5]=false;h:warm({1,2})
    local before=h:checkpoint();h.phase='capture_batch_gain';h.checkGain=true
    h.camera[3]=true;h.camera[4]=true;h.camera[5]=true
    h:refresh(false,0.95);h:step();h:refresh(false,0.9);h:step();h:refresh(false,0.85)
    h:settle(idRange(5),nil);return before
end)
scenario('removal_with_gain',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='remove_with_gain';h.checkGain=true
    h.epoch=h.epoch+1;h:refresh(true);h:advance(6)
    h.required={1,2};h.forbidden={3};h.units[3].dead=true;h:refresh(false,0.9)
    h:settle({1,2},h.epoch);return before
end)
local function transientVisibility(h,warm)
    local before
    if warm then
        h:warm({1,2,3});before=h:checkpoint();h.epoch=h.epoch+1;h:refresh(true)
    else h:refresh() end
    h.phase=warm and 'transient_warm_visibility' or 'transient_cold_visibility'
    local frames=0
    while not (h.lastBakeSource==3 and h.lastBakeChunks<16) and frames<600 do h:advance(1);frames=frames+1 end
    if frames>=600 then h:fail('never reached the last house incremental bake')end
    -- A finished second field can await the next 5-Hz atlas publication while
    -- the third bake starts. Protect only light that has actually been shown.
    if not warm then h.required=keys(h:visible())end
    h.units[3].los=false;h:step();h.units[3].los=true;h:refresh()
    h.units[3].cloaked=true;h:step();h.units[3].cloaked=false;h:refresh()
    h:settle({1,2,3},h.epoch)
    return before
end
scenario('transient_cold_visibility',3,function(h)return transientVisibility(h,false)end)
scenario('transient_warm_visibility',3,function(h)return transientVisibility(h,true)end)
scenario('revision_change',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='revision';h.required={2,3};h.units[1].revision=2
    h:refresh();local entry=h:visible()[1]
    if entry and entry.revision~=2 then h:fail('old source revision still visible')end
    h:settle({1,2,3},nil);return before
end)
scenario('source_removals',6,function(h)
    h:warm(idRange(6));local before=h:checkpoint()
    local changes={
        function()h.units[1].revision=-2 end,
        function()h.units[2].dead=true end,
        function()h.units[3].los=false end,
        function()h.units[4].cloaked=true end,
        function()h.units[5].exists=false end,
    }
    for i,change in ipairs(changes) do
        h.phase='remove_'..i;h.required={};h.forbidden=idRange(i)
        for id=i+1,6 do h.required[#h.required+1]=id end
        change();h:refresh();h:settle(h.required,nil);h:advance(24)
    end
    return before
end)
scenario('removal_during_rebuild',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='rebuild';h.epoch=h.epoch+1
    h:refresh(true);h:advance(6);h.phase='remove_during_rebuild';h.required={2,3};h.forbidden={1};h.units[1].dead=true
    h:refresh();h:settle({2,3},h.epoch);return before
end)
scenario('repeated_occlusion',3,function(h)
    h:warm({1,2,3});local before=h:checkpoint();h.phase='repeated_occlusion'
    for _=1,5 do h.epoch=h.epoch+1;h:refresh(true);h:advance(6)end
    h:settle({1,2,3},h.epoch);return before
end)

local function run(code,label)
    local results={};local failures={}
    for _,spec in ipairs(scenarios) do
        local h=harness(code,spec.count)
        local before=spec.run(h) or setmetatable({},{__index=function()return 0 end})
        local result=h:delta(before)
        result.peakBytes=h.peakBytes;result.liveBytes=h.liveBytes
        result.maxStepChunks=h.maxStepChunks;result.maxRefreshChunks=h.maxRefreshChunks;result.maxFrameChunks=h.maxFrameChunks
        result.errors=#h.errors;result.luaSeconds=h.luaSeconds
        result.firstVisibleChunks=h.firstVisibleChunks;result.firstVisibleFrame=h.firstVisibleFrame
        if result.maxStepChunks>1 or result.maxRefreshChunks>1 or result.maxFrameChunks>2 then h:fail('incremental bake budget exceeded') end
        for _,message in ipairs(h.errors) do failures[#failures+1]=spec.name..': '..message end
        results[spec.name]=result;h:close()
    end
    print('WORK '..label..' (format bytes are nominal payloads; no driver/FBO overhead; DEPTH24 is 3 bytes/pixel)')
    print('scenario\tcaptures\treadbacks\tchunks\tblocker_packs\tblocker_copies\tatlas_passes\tatlas_copies\ttexture_allocs\tlive_bytes\tpeak_bytes\tbehavior_errors')
    for _,spec in ipairs(scenarios) do local r=results[spec.name]
        print(string.format('%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d',spec.name,
            r.captureDraws/4,r.readbacks,r.bakeChunks,r.blockerPacks,r.blockerCopies,r.atlasPasses,r.atlasCopies,
            r.textureAllocations,r.liveBytes,r.peakBytes,r.errors))
    end
    return results,failures
end
local current,failures=run(source,'patched')
if baselinePath then
    local baselineSource=read(baselinePath)
    local baseline,oldFailures=run(baselineSource,'baseline')
    print('Baseline reproduced '..#oldFailures..' behavior-check failures (expected diagnostic comparison).')
    -- These are measured, narrow exceptions, not an allowance for more work on
    -- arbitrary scenarios. Removing an invalid source immediately while keeping
    -- surviving light needs an early atlas update. Explicit strength changes and
    -- retention-bound crossings also require exact cutoff reclassification.
    local budgetedCopies={
        camera_eviction={copies=1,reason='immediate removal, then completed replacement'},
        removal_during_rebuild={copies=1,reason='immediate removal, then completed replacement'},
        removal_with_gain={copies=1,reason='immediate removal with new gain, then completed replacement'},
        strength_during_rebuild={copies=2,reason='exact cutoff reclassification for explicit strength changes'},
        gain_retention_bounds={copies=3,reason='exact cutoff reclassification at both retention bounds'},
    }
    local stagingAllocations={cold_32=1,warm_shutdown_reenable=1,transient_cold_visibility=1}
    for _,spec in ipairs(scenarios) do
        local a,b=current[spec.name],baseline[spec.name]
        for _,name in ipairs({'captureDraws','wallDraws','readbacks','bakeChunks','bakePoints','blockerPacks','blockerCopies','atlasPasses','atlasCopies'}) do
            if a[name]>b[name] then
                local budget=name=='atlasCopies' and budgetedCopies[spec.name]
                local allowance=budget and budget.copies or 0
                local message=spec.name..': work increased '..name..' '..b[name]..' -> '..a[name]
                if a[name]<=b[name]+allowance then
                    print('BUDGETED '..message..' ('..budget.reason..')')
                    if strictCost then failures[#failures+1]=message end
                else failures[#failures+1]=message end
            end
        end
        local allocationAllowance=stagingAllocations[spec.name] or 0
        if a.textureAllocations>b.textureAllocations+allocationAllowance then failures[#failures+1]=spec.name..': unbudgeted texture allocations' end
        if a.textureAllocatedBytes>b.textureAllocatedBytes+allocationAllowance*512*1024 then failures[#failures+1]=spec.name..': unbudgeted cumulative texture bytes' end
        if a.liveBytes>b.liveBytes+512*1024 or a.peakBytes>b.peakBytes+512*1024 then
            failures[#failures+1]=spec.name..': texture payload exceeded one shared 512-KiB workspace'
        end
        if a.maxStepChunks>b.maxStepChunks or a.maxRefreshChunks>b.maxRefreshChunks or a.maxFrameChunks>b.maxFrameChunks then
            failures[#failures+1]=spec.name..': per-call/per-frame bake budget increased'
        end
    end
    print('Cold-32 texture payload delta: live '..(current.cold_32.liveBytes-baseline.cold_32.liveBytes)..
        ' bytes; peak '..(current.cold_32.peakBytes-baseline.cold_32.peakBytes)..' bytes.')
    print(string.format('Cold-32 first visible projection: baseline frame %d (%d bake chunks); patched frame %d (%d bake chunks).',
        baseline.cold_32.firstVisibleFrame or -1,baseline.cold_32.firstVisibleChunks or -1,
        current.cold_32.firstVisibleFrame or -1,current.cold_32.firstVisibleChunks or -1))
    if not current.cold_32.firstVisibleFrame or current.cold_32.firstVisibleFrame>baseline.cold_32.firstVisibleFrame then
        failures[#failures+1]='cold_32: first visible projection was delayed'
    end
    print(string.format('Maximum bake budget: patched Step %d / Refresh %d / frame %d; baseline Step %d / Refresh %d / frame %d.',
        current.cold_32.maxStepChunks,current.cold_32.maxRefreshChunks,current.cold_32.maxFrameChunks,
        baseline.cold_32.maxStepChunks,baseline.cold_32.maxRefreshChunks,baseline.cold_32.maxFrameChunks))
    if cpuBenchmark then
        local fresh,old=harness(source,32),harness(baselineSource,32)
        fresh:warm(idRange(32));old:warm(idRange(32))
        local function timeWarm(h)
            local before=h:checkpoint();collectgarbage('collect');local start=os.clock()
            for frame=1,30000 do
                h.object:Step()
                if frame%6==0 then h.object:Update(0.2);h.object:Refresh(h.occupancy,false,1) end
            end
            local seconds=os.clock()-start;local delta=h:delta(before)
            for _,name in ipairs(gpuCounters) do assert(delta[name]==0,'CPU benchmark was not warm: '..name) end
            return seconds
        end
        local a,b={},{}
        for trial=1,7 do
            if trial%2==0 then b[trial]=timeWarm(old);a[trial]=timeWarm(fresh)
            else a[trial]=timeWarm(fresh);b[trial]=timeWarm(old) end
        end
        table.sort(a);table.sort(b)
        print(string.format('CPU warm32: patched median %.6fs [%.6f, %.6f]; baseline median %.6fs [%.6f, %.6f]; ratio %.4f',
            a[4],a[1],a[7],b[4],b[1],b[7],a[4]/b[4]))
        print('CPU sample: 30,000 Step + 5,000 Refresh + 5,000 Update calls; seven alternating trials; mocked engine APIs; no GPU timing.')
        fresh:close();old:close()
    end
end
for _,failure in ipairs(failures) do print('FAIL '..failure) end
assert(#failures==0,string.format('%d continuity/work-budget failures',#failures))
if baselinePath then print('Comparison PASS: declared work budgets met; printed BUDGETED copies and 512-KiB workspace remain real costs.')end
print('PASS: completed-field publication; unaffected-source continuity; camera admission, eviction and reordering;')
print('      hide, death, LOS, cloak and missing-unit removal; source revisions; repeated physical invalidation;')
print('      idle GPU reuse; incremental work budgets; complete resource cleanup.')
