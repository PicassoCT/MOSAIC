
local function GetUnitArmour(unitDef)
    return 1
end


local function GetUnitWeaponsFeatures(unitDef)
    local firepower, accuracy, penetration, range = 0, 0, 0, 0
    if #unitDef.weapons > 0 then
        for i = 1, #unitDef.weapons do
            local weaponDef = WeaponDefs[unitDef.weapons[i].weaponDef]
            -- Consider just the firepower and accuracy of the first weapon
            if i == 0 then
                local d, n = 0, 0
                for k, v in pairs(weaponDef.damages) do
                    if tonumber(k) ~= nil then
                        n = n + 1
                        d = d + v
                    end
                end
                d = d / n
                local t = weaponDef.reload / (weaponDef.salvoSize * weaponDef.projectiles)
                firepower = firepower + d / t
                local a = weaponDef.accuracy
                if a > accuracy then
                    accuracy = a
                end
            end
        
            local r = weaponDef.range
            if r > range then
                range = r
            end
        end
    end
    return firepower, accuracy, 1.0, range
end

return {
    GetUnitArmour = GetUnitArmour,
    GetUnitWeaponsFeatures = GetUnitWeaponsFeatures,
}
