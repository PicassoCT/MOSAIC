function widget:GetInfo()
	return {
	name      = "Lua UiKeys loader",
	desc      = "Loads uikeys.txt file in LuaUI/Widgets_BAR to apply binds",
	author    = "Doo",
	date      = "2018",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = false, --enabled by default
	}
end

function widget:Initialize()
	if VFS.FileExists("luaui/widgets/uikeys.txt") then
		k = tostring(VFS.LoadFile("luaui/widgets/uikeys.txt"))
	else
		k = ""
	end
	lines = {}
	for s in k:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	for ct, line in pairs(lines) do
		Spring.SendCommands(line)
	end
	Spring.Echo("Succesfully loaded luaui/widgets/uikeys.txt")
end