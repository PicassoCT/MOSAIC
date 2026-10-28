-- Inherit the original payload's gameplay and transport properties. The new
-- model contains thirteen complete numbered bodies; its script shows one.
local base = VFS.Include("units/neutral/truckPayload.lua").truckpayload
local catalog = VFS.Include("scripts/lib_truck_service_payloads.lua")

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[type(key) == "string" and string.lower(key) or key] = copy(item)
    end
    return result
end

local definition = copy(base)
definition.name = "Civilian service payload"
definition.description = "Modular civilian service body"
definition.objectname = catalog.modelName
definition.script = "truckServicePayloadScript.lua"
definition.customparams.normaltex = "unittextures/house_asian_normal.dds"
definition.customparams.civilian_service_payload = true

return lowerkeys({[catalog.unitName] = definition})
