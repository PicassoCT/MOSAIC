-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--------------------------------------------------------------------------------
--
--  Convert names to unitDefIDs
--  Must be included after LuaRules/Config/prometheus/buildorder.lua
--

local function NameToID(name)
	local unitDef = UnitDefNames[name]
	if unitDef then
		return unitDef.id
	else
		error("Prometheus: Bad unitname: " .. name)
	end
end


local function convertTableToDefIDNumberTable(t)
local ret={}
	for k,v in ipairs(t) do
		ret[NameToID(k)] = v
	end
	
return ret
end

local function NameArrayToIdArray(array)
	local newArray = {}
	for i,name in ipairs(array) do
		newArray[i] = NameToID(name)
	end
	return newArray
end

local function NameArrayToIdSet(array)
	local newSet = {}
	for i,name in ipairs(array) do
		newSet[NameToID(name)] = true
	end
	return newSet
end

do
	local unitBuildOrderById = {}
	for k,v in pairs(gadget.unitBuildOrder) do
		unitBuildOrderById[NameToID(k)] = NameArrayToIdArray(v)
	end
	gadget.unitBuildOrder = unitBuildOrderById
end

do
	local baseBuildOrderById = {}
	for k,v in pairs(gadget.baseBuildOrder) do
		-- don't translate key here, it's the side
		baseBuildOrderById[k] = NameArrayToIdArray(v)
	end
	gadget.baseBuildOrder = baseBuildOrderById
end



gadget.minBuildRequirementProtagon = convertTableToDefIDNumberTable(gadget.minBuildRequirementProtagon)
assert(gadget.minBuildRequirementProtagon)
gadget.minBuildRequirementAntagon = convertTableToDefIDNumberTable(gadget.minBuildRequirementAntagon)
assert(gadget.minBuildRequirementAntagon)

gadget.baseBuilders = NameArrayToIdSet(gadget.baseBuilders)
assert(gadget.baseBuilders)
gadget.flags = NameArrayToIdSet(gadget.flags)
gadget.flagCappers = NameArrayToIdSet(gadget.flagCappers)
gadget.reservedFlagCappers = gadget.reservedFlagCappers or {}

do
	local unitLimitsById = {}
	for k,v in pairs(gadget.unitLimits) do
		unitLimitsById[NameToID(k)] = v
	end
	gadget.unitLimits = unitLimitsById
end

