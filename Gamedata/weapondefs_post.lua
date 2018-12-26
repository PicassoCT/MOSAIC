VFS.Include("LuaRules/Includes/utilities.lua", nil, VFS.ZIP)

local UnitDefs = DEFS.unitDefs
local FeatureDefs = DEFS.featureDefs

local FUNCTIONS_TO_REMOVE = {"new", "clone", "append"}

local cegCache = {}

local function FloatTo128(num)
	return string.char(string.format("%03d",math.max(num * 255, 1)))
end

local function RGBtoString(rgbstring)
	local rgb = {}
	for i in string.gmatch(rgbstring, "%S+") do
		table.insert(rgb, i)
	end
	return '\255' .. FloatTo128(rgb[1]) .. FloatTo128(rgb[2]) .. FloatTo128(rgb[3])
end

local function WeaponColour(weapName)
	weapName = weapName:lower()
	local colour = WeaponDefs[weapName].rgbcolor
	if not colour then 
			colour = "\255\001\001\001"
	end
	
	colour = RGBtoString(colour)

	return colour
end

for weapName, wd in pairs(WeaponDefs) do 
	local cp = wd.customparams
	if cp then

		for k, v in pairs (cp) do
			if type(v) == "table" or type(v) == "boolean" then
				wd.customparams[k] = table.serialize(v)
			end
		end
	else
		cp = {}
	end
	
	
end

