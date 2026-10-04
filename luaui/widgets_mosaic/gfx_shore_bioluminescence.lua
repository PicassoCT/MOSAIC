function widget:GetInfo()
    return {name='Shore Bioluminescence',desc='Dry-night luminous swash and fading sand trails',
        author='MOSAIC contributors',date='2026',license='GNU GPL v2 or later',layer=-8,enabled=true}
end
local Shore=VFS.Include('luaui/widgets_mosaic/include/shore_bioluminescence.lua')
local Night=VFS.Include('luaui/widgets_mosaic/include/radiance_time.lua')
local field,scan,sandTexture
local enabled,testMode=true,false
local function clock()
    local frame=Spring.GetGameFrame()
    local _,_,paused=Spring.GetGameSpeed()
    return (frame+(not paused and Spring.GetFrameTimeOffset and Spring.GetFrameTimeOffset() or 0))/30
end
local function capture(bottom,top,domain)
    if field and field.Draw and enabled then field:Draw(true,bottom,top,domain) end
end
local function stop(reason)
    Spring.Echo('Shore bioluminescence: '..reason)
    widgetHandler:RemoveWidget(widget)
end
function widget:Initialize()
    -- Dhubai's red channel is explicitly sand. Do not guess another map's
    -- material channels. Maps can opt in with their own single-channel mask.
    local configPath='mapconfig/shore_bioluminescence.lua'
    if VFS.FileExists(configPath,VFS.MAP) then
        local ok,config=pcall(VFS.Include,configPath,nil,VFS.MAP)
        if ok and type(config)=='table' then sandTexture=config.sandTexture end
    elseif VFS.FileExists('maps/LastDayOfDubai_distribution.dds',VFS.MAP) then
        sandTexture='maps/LastDayOfDubai_distribution.dds'
    end
    if not sandTexture or not VFS.FileExists(sandTexture,VFS.MAP) then
        widgetHandler:RemoveWidget(widget);return
    end
    if not gl.RenderToTexture or not gl.CreateShader or not gl.MultiTexCoord or not gl.TextureInfo
        or not gl.TextureInfo('$heightmap') then stop('height texture/FBO support unavailable');return end
    scan=coroutine.create(function() return Shore.CollectTiles(Game.mapSizeX,Game.mapSizeZ,Spring.GetGroundHeight) end)
    WG.CaptureShoreBioluminescence=capture
end
function widget:Update()
    if not scan then return end
    local ok,tiles=coroutine.resume(scan)
    if not ok then scan=nil;stop(tostring(tiles));return end
    if coroutine.status(scan)=='dead' then
        scan=nil
        if #tiles==0 then stop('no shoreline');return end
        -- Allocate GL resources in a draw call, not Update.
        field={pendingTiles=tiles}
    end
end
function widget:DrawWorldPreUnit()
    if not field then return end
    if field.pendingTiles then
        local tiles=field.pendingTiles;field=nil
        local reason;field,reason=Shore.New(tiles,sandTexture)
        if not field then stop(reason);return end
    end
    local t=clock()
    -- Missing weather provider fails closed, including widget reload intervals.
    local rain=WG.GetMosaicRainIntensity and WG.GetMosaicRainIntensity()
    local amount=enabled and rain~=nil and Night.AtFrame(t*30)*Shore.DryFactor(rain) or 0
    if testMode and enabled then amount=1 end
    field:Step(t,amount)
end
function widget:DrawWorld()
    if field and field.Draw and enabled then field:Draw(false) end
end
function widget:TextCommand(command)
    command=command:lower():match('^%s*(.-)%s*$')
    if command=='biowaves on' or command=='biowaves off' then
        enabled=command=='biowaves on';testMode=false
        if field then field.intensity=0 end
        Spring.Echo('Shore bioluminescence: '..(enabled and 'automatic dry nights' or 'off'));return true
    elseif command=='biowaves test on' or command=='biowaves test off' then
        testMode=command=='biowaves test on';enabled=true
        Spring.Echo('Shore bioluminescence test: '..(testMode and 'forced glow' or 'automatic dry nights'));return true
    elseif command=='biowaves status' then
        Spring.Echo('Shore bioluminescence: '..(scan and 'scanning coast' or not field and 'unavailable'
            or field.pendingTiles and 'waiting for GPU allocation' or string.format('%d/%d tiles; atlas %dx%d; intensity %.3f',
                field.built,#field.tiles,field.layout.width,field.layout.height,field.intensity)));return true
    end
end
function widget:Shutdown()
    if WG.CaptureShoreBioluminescence==capture then WG.CaptureShoreBioluminescence=nil end
    if field and field.Shutdown then field:Shutdown() end
    field,scan=nil,nil
end
