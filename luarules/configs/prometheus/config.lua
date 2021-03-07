-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Misc config
FLAG_RADIUS = 230 --from S44 game_flagManager.lua
SQUAD_SIZE = 10

--------------------------------------------------------------------------------
--
--  Data structures (constructor syntax)
--
Spring.Echo("Prometheus loading configs")

-- Converts UnitDefName to UnitDefID, raises an error if name is not valid.
local function NameToID(name)
	local unitDef = UnitDefNames[name]
	if unitDef then
		return unitDef.id
	else
		error("Bad unitname: " .. name)
	end
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

gadget.reservedFlagCappers = {
antagon = SQUAD_SIZE,
protagon = SQUAD_SIZE
}

gadget.flagCappers = UnitSet{
"operativeasset",
"operativepropagator",
"operativeinvestigator"
}


--------------------------------------------------------------------------------
--
--  Include configuration
--

local dir = "luarules/configs/prometheus/mosaic/"

if (gadgetHandler:IsSyncedCode()) then
	-- SYNCED
else
	-- UNSYNCED
	Spring.Echo("Prometheus start buildorder loading")
	include(dir .. "buildorder.lua")
	Spring.Echo("Prometheus buildorder loading completed")
end

-- both SYNCED and UNSYNCED
Spring.Echo("Prometheus start unitlimits loading")
include(dir .. "unitlimits.lua")
Spring.Echo("Prometheus unitlimits loading completed")
