-- Pure initial-city policy, shared by LuaRules and map LuaGaia. Configuration
-- and unit-category membership belong to lib_mosaic; no UI messages or RNG.
local M = {}
local floor, abs = math.floor, math.abs
local modulus = 2147483647

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

function M.Chance(latitude, cfg)
    if not finite(latitude) or abs(latitude) > 90 then latitude = cfg.unknownLatitude end
    local equatorial = math.max(0, math.min(1, cfg.equatorChance))
    local poleward = math.max(0, math.min(equatorial, cfg.polewardChance))
    local fraction = math.min(1, abs(latitude) / cfg.polewardLatitude)
    return equatorial + (poleward - equatorial) * fraction
end

function M.PlotRoll(mapHash, x, z)
    -- Integer arithmetic stays below 2^53 on Lua 5.1. Quantizing to 1/16 elmo
    -- makes the same authored plot stable across LuaRules and LuaGaia. The
    -- nonlinear mix avoids strips of identical damage on regular city grids.
    local hash = floor(mapHash or 0) % modulus
    local key = floor(x * 16 + 0.5) .. ":" .. floor(z * 16 + 0.5)
    for i = 1, #key do hash = (hash * 131 + key:byte(i)) % modulus end
    local mixed = hash % 1000003
    hash = (mixed * mixed * 4093 + hash) % modulus
    hash = (hash * 48271) % modulus
    return hash / modulus
end

function M.ShouldRuin(mapHash, x, z, latitude, cfg)
    if not finite(x) or not finite(z) then return false end
    return M.PlotRoll(mapHash, x, z) < M.Chance(latitude, cfg)
end

return M
