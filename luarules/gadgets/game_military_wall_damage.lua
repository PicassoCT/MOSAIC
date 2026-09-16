function gadget:GetInfo()
    return {
        name = "Military wall damage",
        desc = "Keeps area denial meaningful while allowing deliberate breaches",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 10,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end

local walls, multipliers = {}, {}
for _, name in ipairs({"brehmerwall", "barricade"}) do
    local def = UnitDefNames[name]
    if def then walls[def.id] = true end
end
for id, def in pairs(WeaponDefs) do
    local value = tonumber((def.customParams or {}).wall_damage_multiplier)
    if value then multipliers[id] = value end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID)
    local multiplier = walls[unitDefID] and multipliers[weaponDefID]
    if multiplier and not paralyzer then return damage * multiplier, 1 end
    return damage, 1
end
