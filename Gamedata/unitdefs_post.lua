-- USEFUL FUNCTIONS & INCLUDES
VFS.Include("LuaRules/Includes/utilities.lua", nil, VFS.ZIP)

local function GetWeight(mass)
	mass = tonumber(mass)
	local light = mass < 40
	local medium = not light and mass < 60
	local heavy = not light and not medium and mass < 80
	local assault = not light and not medium and not heavy
	local weight = light and "light" or medium and "medium" or heavy and "heavy" or "assault"
	return weight
end


local modOptions = Spring.GetModOptions()
if not modOptions.startmetal then -- load via file
	local raw = VFS.Include("ModOptions.lua", nil, VFS.ZIP)
	for i, v in ipairs(raw) do
		if v.type ~= "section" then
			modOptions[v.key] = v.def
		end
	end
	raw = VFS.Include("EngineOptions.lua", nil, VFS.ZIP)
	for i, v in ipairs(raw) do
		if v.type ~= "section" then
			modOptions[v.key:lower()] = v.def
		end
	end
end


-- TODO: I still don't quite follow why the SIDES table from _pre (available to all defs) isn't available here
local sideData = VFS.Include("Gamedata/sidedata.lua", VFS.ZIP)
local SIDES = {}
local VALID_SIDES = {}
for sideNum, data in pairs(sideData) do
	SIDES[sideNum] = data.shortName:lower()
	VALID_SIDES[data.shortName:lower()] = true
end

local function RecursiveReplaceStrings(t, name, side, replacedMap)
	if (replacedMap[t]) then
		return  -- avoid recursion / repetition
	end
	replacedMap[t] = true
	local changes = {}
	for k, v in pairs(t) do
		if (type(v) == 'string') then
			t[k] = v:gsub("<SIDE>", side):gsub("<NAME>", name)
		end
		if (type(v) == 'table') then
			RecursiveReplaceStrings(v, name, side, replacedMap)
		end
	end 
end

local function ReplaceStrings(t, name)
	local side = ""
	local replacedMap = {}
	for _, sideName in pairs(SIDES) do
		if name:find(sideName) == 1 then
			side = sideName
			break
		end
	end
	RecursiveReplaceStrings(t, name, side, replacedMap)
end

local ammoPerTon = lowerkeys(VFS.Include("Gamedata/AmmoTypes.lua", nil, VFS.ZIP))
local armorTypes = lowerkeys(VFS.Include("Gamedata/ArmorTypes.lua", nil, VFS.ZIP))

