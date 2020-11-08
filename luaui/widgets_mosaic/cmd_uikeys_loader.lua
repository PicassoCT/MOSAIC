function widget:GetInfo()
	return {
	name      = "Lua UiKeys loader",
	desc      = "Loads uikeys.txt file in LuaUI/widgets_mosaic to apply binds",
	author    = "Doo",
	date      = "2018",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = false, --enabled by default
	}
end

function widget:Initialize()
	if VFS.FileExists("LuaUI/widgets/uikeys.txt") then
		k = tostring(VFS.LoadFile("LuaUI/widgets_mosaic/uikeys.txt"))
		Spring.Echo("Succesfully loaded LuaUI/widgets_mosaic/uikeys.txt")
	else
		Spring.Echo("uikeys.txt not loaded")
		k = ""
	end
	lines = {}
	for s in k:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	for ct, line in pairs(lines) do
		Spring.SendCommands(line)
	end

end