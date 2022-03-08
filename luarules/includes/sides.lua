local sideData = VFS.Include("gamedata/sidedata.lua", nil, VFS.ZIP)
local SIDES = {}

for sideNum, data in pairs(sideData) do
	if sideNum > 1 then -- ignore Random/GM
		SIDES[sideNum] = data.name:lower()
	end
end

local function getSideName(name, default)
	if string.find(name, "antagon") then return "antagon" end
	if string.find(name, "protagon") then return "protagon" end
	return default
end

return getSideName