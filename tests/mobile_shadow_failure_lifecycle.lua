-- Whole-widget fault isolation. Run from the repository root with Lua 5.1+.
-- Renderer doubles inject failures; the widget and its fallback flow are real.
local function read(path)
    local file=assert(io.open(path));local text=file:read('*a');file:close();return text
end
local function loadIn(path,env)
    local chunk=setfenv and setfenv(assert(loadfile(path)),env) or assert(loadfile(path,'t',env))
    return chunk()
end
local function exercise(stage,shutdownFails)
    local h={logs={},globals={},live={},serial=0,draws=0,headlights=0,propagates=0,
        constructors=0,updates=0,captures=0,closed=0,detailClosed=0,detailRefreshes=0,
        resets=0,matrixResets=0,shader=0,captureTransform=false}
    local function fail(name)
        h.shader=999;h.captureTransform=true
        error('injected '..name..' failure')
    end
    local function alloc(kind)
        h.serial=h.serial+1;h.live[h.serial]=kind;return h.serial
    end
    local function free(id,kind)
        assert(h.live[id]==kind,'invalid/double delete');h.live[id]=nil
    end
    local GL={PROJECTION=0x1701,MODELVIEW=0x1700}
    local gl={
        GetViewSizes=function() return 1280,720 end,
        CreateTexture=function() return alloc('texture') end,
        DeleteTexture=function(id) free(id,'texture') end,
        CreateShader=function() return alloc('shader') end,
        DeleteShader=function(id) free(id,'shader') end,
        GetUniformLocation=function(_,name) return name end,
        GetShaderLog=function() return '' end,
        UseShader=function(shader) h.shader=shader end,
        ResetState=function() h.resets=h.resets+1 end,
        ResetMatrices=function() h.matrixResets=h.matrixResets+1;h.captureTransform=false end,
        RenderToTexture=function(_,fn,...) fn(...) end,
        BeginEnd=function(_,fn,...) fn(...) end,
        Texture=function() return true end,
    }
    for _,name in ipairs({'UnitPiece','UnitMultMatrix','Clear','DepthTest','DepthMask','Blending',
        'Culling','AlphaTest','Color','Uniform','UniformInt','MatrixMode','PushMatrix','PopMatrix',
        'LoadIdentity','Ortho','Rotate','Vertex','TexRect'}) do gl[name]=function() end end
    local propagation={unitTexture='global-unit-radiance',sceneTexture='global-scene-radiance'}
    function propagation:Draw() self.ready=true;h.propagates=h.propagates+1 end
    function propagation:Shutdown() self.ready=false end
    local detail={ready=false,domain={x=0,z=0,span=1024}}
    function detail:CameraDomain() return self.domain end
    function detail:Refresh()
        h.detailRefreshes=h.detailRefreshes+1
        if stage=='local' then fail('local') end
        self.ready=true
    end
    function detail:Shutdown() h.detailClosed=h.detailClosed+1;self.ready=false end
    local headlights={enabled=true,ready=true,localReady=true}
    function headlights:Update() end
    function headlights:Draw(capture)
        h.headlights=h.headlights+1
        assert(capture,'ordinary direct lighting lost its source provider')
    end
    function headlights:Shutdown() end
    local mobile={enabled=true,ready=true,count=0,stats={},collector={}}
    function mobile:Update()
        h.updates=h.updates+1
        if stage=='update' then fail('update') end
    end
    function mobile:CaptureSources()
        h.captures=h.captures+1
        if stage=='capture' then fail('capture') end
    end
    function mobile:Shutdown()
        h.closed=h.closed+1;self.ready=false
        if shutdownFails then error('injected shutdown failure') end
    end
    function mobile:Invalidate() end
    function mobile.collector:UnitCreated() end
    function mobile.collector:UnitDestroyed() end
    local scene={mobileSupported=stage~='unsupported',mode='test'}
    function scene:Draw(texture,occupancy,bottom,top,strength,gain,localField,live,liveGain,windows,objectives,shadows)
        h.draws=h.draws+1
        assert(texture=='global-unit-radiance' and occupancy and bottom==0 and top==128)
        assert(strength>0 and gain==1 and live==headlights and liveGain==1)
        assert(h.shader~=999 and not h.captureTransform,'optional failure left the capture GL state active')
        if stage=='constructor' or stage=='update' or stage=='capture' or stage=='unsupported' then
            assert(shadows==nil,'failed/unsupported mobile field still reached the scene')
        else assert(shadows==mobile) end
        if stage=='local' then assert(localField==nil,'failed local detail still reached the scene') end
    end
    function scene:Resize() end
    function scene:Shutdown() end
    local window={}
    for _,method in ipairs({'Update','Step','Refresh','DrawWorld','Shutdown','TextCommand'}) do window[method]=function() end end
    local env=setmetatable({widget={},WG={CaptureCombatLightEmission=function() end},gl=gl,GL=GL,
        UnitDefs={},Game={mapSizeX=8192,mapSizeZ=8192},Spring={
            GetGameFrame=function() return 0 end,
            GetViewGeometry=function() return 1280,720,0,0 end,
            ValidUnitID=function() return true end,
            GetUnitIsDead=function() return false end,
            Echo=function(text) h.logs[#h.logs+1]=text end,
        },widgetHandler={
            RegisterGlobal=function(_,name,fn) h.globals[name]=fn end,
            DeregisterGlobal=function(_,name) h.globals[name]=nil end,
            RemoveWidget=function() error('optional failure removed the whole lighting widget') end,
        }},{__index=_G})
    env.VFS={LoadFile=read,Include=function(path,includeEnv)
        if path:find('cloud_volume_config.lua',1,true) then return {} end
        if path:find('radiance_objective_sources.lua',1,true) then return {CollectDirect=function() return {} end} end
        if path:find('radiance_propagation.lua',1,true) then return function() return propagation end end
        if path:find('radiance_local.lua',1,true) then return {New=function() return detail end} end
        if path:find('radiance_scene.lua',1,true) then return function() return scene end end
        if path:find('headlight_live_field.lua',1,true) then return function() return headlights end end
        if path:find('window_lighting.lua',1,true) then return function() return window end end
        if path:find('mobile_shadow_field.lua',1,true) then
            return {New=function()
                h.constructors=h.constructors+1
                -- Constructor failures happen outside a draw call-in; do not
                -- simulate or require drawing-only GL recovery APIs there.
                if stage=='constructor' then error('injected constructor failure') end
                return mobile
            end}
        end
        if path=='scripts/lib_mosaic.lua' then
            assert(includeEnv.MOSAIC_CONFIG_ONLY)
            return {getMobileRadianceShadowTypeTable=function(defs) assert(defs==env.UnitDefs);return {} end}
        end
        return loadIn(path,includeEnv or env)
    end}
    loadIn('luaui/widgets_mosaic/gfx_neonlights_radiancecascade.lua',env)
    env.widget:Initialize()
    assert(env.WG.NeonRadiance==propagation,'optional initialization broke the global cascade provider')
    env.widget:TextCommand('radiancelight test on')
    env.widget:Update(1)
    env.widget:DrawWorldPreUnit()
    assert(propagation.ready and h.propagates>0)
    env.widget:DrawWorld();env.widget:DrawWorld()
    assert(h.draws==2 and h.headlights==2,'lighting did not continue after optional failure')
    assert(env.WG.GetRainRadiance().texture=='global-unit-radiance','shared ordinary radiance provider was lost')
    if stage=='unsupported' then assert(h.constructors==0) else assert(h.constructors==1) end
    if stage=='update' then assert(h.updates==1 and h.captures==0 and h.closed==1) end
    if stage=='capture' then assert(h.updates==1 and h.captures==1 and h.closed==1) end
    if stage=='local' then assert(h.detailRefreshes==1 and h.detailClosed==1) end
    if stage=='update' or stage=='capture' or stage=='local' then
        assert(h.resets==1 and h.matrixResets==1,'render failure did not restore GL state and world matrices')
    else assert(h.resets==0 and h.matrixResets==0) end
    if stage~='unsupported' and stage~='none' then
        local messages=0
        for _,message in ipairs(h.logs) do
            if message:find('injected '..stage..' failure',1,true) then messages=messages+1 end
        end
        assert(messages==1,'failure diagnostic missing, replaced, or repeated every draw')
    end
    -- Further ordinary frames must not retry the failed optional component.
    env.widget:Update(1);env.widget:DrawWorldPreUnit();env.widget:DrawWorld()
    assert(h.draws==3 and h.headlights==3)
    if stage=='local' then assert(h.detailRefreshes==1) end
    env.widget:Shutdown()
    if stage=='update' or stage=='capture' then assert(h.closed==1,'failed field destroyed twice') end
    assert(env.WG.NeonRadiance==nil and next(h.globals)==nil)
    assert(next(h.live)==nil,'widget shutdown leaked ordinary lighting resources')
end
for _,stage in ipairs({'none','unsupported','constructor','update','capture','local'}) do exercise(stage) end
exercise('update',true)
print('PASS: optional constructor/update/source/local-capture failures preserve global radiance, direct lights and shared providers; bounded diagnostics, GL recovery, no retries and cleanup')
