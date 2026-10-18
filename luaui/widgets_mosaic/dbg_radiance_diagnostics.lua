function widget:GetInfo()
    return {name = 'Radiance Diagnostics',
        desc = 'On-demand source-to-scene radiance status in infolog',
        author = 'MOSAIC contributors', license = 'GPL V2', layer = 0,
        enabled = true, hidden = false}
end

local diagnostics
function widget:TextCommand(command)
    if command ~= 'radiancedebug status' then return false end
    -- Independent of the render widgets: still reports their absence if one
    -- failed initialization or was removed after a runtime exception.
    local ok, reason = pcall(function()
        if not diagnostics then
            diagnostics = VFS.Include('luaui/widgets_mosaic/include/radiance_diagnostics.lua')
        end
        diagnostics.Report(WG, Spring.Echo)
    end)
    if not ok then Spring.Echo('[MOSAIC radiance] diagnostic ERROR: ' .. tostring(reason)) end
    return true
end
