local base = VFS.Include("units/neutral/truckPayload.lua").truckpayload
local catalog = VFS.Include("scripts/lib_truck_parade_payloads.lua")

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[type(key) == "string" and string.lower(key) or key] = copy(item)
    end
    return result
end

local definition = copy(base)
definition.name = "Lantern parade float"
definition.description = "Illuminated seventh-night procession float"
definition.objectname = catalog.modelName
definition.script = "truckParadePayloadScript.lua"
definition.customparams.normaltex = "unittextures/house_asian_normal.dds"
definition.customparams.civilian_parade_payload = true

return lowerkeys({[catalog.unitName] = definition})
