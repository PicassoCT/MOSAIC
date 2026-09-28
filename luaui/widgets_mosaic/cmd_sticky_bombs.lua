function widget:GetInfo()
    return {name = "Sticky bomb build orders", desc = "Build carried bombs with one click",
        author = "Mosaic contributors", license = "GNU GPL, v2 or later", layer = 30, enabled = true}
end
VFS.Include("luarules/configs/commandsIDs.lua")
local buildID = -UnitDefNames.ground_stickybomb.id
function widget:CommandNotify(cmd, params, opts)
    if cmd ~= buildID then return false end
    local options = opts.coded
    if not options then
        options = {}
        for _, name in ipairs({"shift", "ctrl", "right"}) do
            if opts[name] then options[#options+1] = name end
        end
    end
    Spring.GiveOrder(CMD_STICKY_BUILD, {}, options)
    return true
end
