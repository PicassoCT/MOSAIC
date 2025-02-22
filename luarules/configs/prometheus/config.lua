-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Misc config
FLAG_RADIUS = 230 --from S44 game_flagManager.lua
SQUAD_SIZE = 1

--------------------------------------------------------------------------------
--
--  Data structures (constructor syntax)
--anycubic photon

-- Converts UnitDefName to UnitDefID, raises an error if name is not valid.
local function NameToID(name)
	local unitDef = UnitDefNames[name]
	if unitDef then
		return unitDef.id
	else
		error("Bad unitname: " .. name)
	end
end

-- Converts UnitDefName array to UnitDefID array, raises an error if a name is
-- not valid.
local function NameArrayToIdArray(array)
	local newArray = {}
	for i,name in ipairs(array) do
		newArray[i] = NameToID(name)
	end
	return newArray
end

-- Converts UnitDefName array to UnitDefID map, raises an error if a name is
-- not valid.
local function NameArrayToIdSet(array)
	local newSet = {}
	for i,name in ipairs(array) do
		newSet[NameToID(name)] = true
	end
	return newSet
end

-- Converts an array of UnitDefNames to an array of UnitDefIDs.
function UnitArray(t)
	local newArray = {}
	for i,name in ipairs(t) do
		newArray[i] = NameToID(name)
	end
	return newArray
end

-- Converts an array of UnitDefNames to a set of UnitDefIDs.
function UnitSet(t)
	local newSet = {}
	for i,name in ipairs(t) do
		newSet[NameToID(name)] = true
	end
	return newSet
end

-- Converts a map with UnitDefNames as keys to a map with UnitDefIDs as keys.
function UnitBag(t)
	local newBag = {}
	for k,v in pairs(t) do
		newBag[NameToID(k)] = v
	end
	return newBag
end

-- This lists all the units that should be considered flags.
gadget.flags = UnitSet{
	"house_arab0",
	"house_western0",
}

-- Number of units per side used to cap flags.
gadget.reservedFlagCappers = {
	antagon = SQUAD_SIZE,
	protagon = SQUAD_SIZE,
}

-- This lists all the units (of all sides) that may be used to cap flags.
-- NOTE: To be removed and automatically parsed
gadget.flagCappers = UnitSet{
	"operativeinvestigator",
	"operativepropagator"
}
