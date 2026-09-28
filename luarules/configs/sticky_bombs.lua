local config = {plantRange = 150, plantedFuseMs = 5000, deathFuseMs = 2000,
    damage = 1150, blastRadius = 150}

function config.explode(bombID, targetID, x, y, z, count)
    local strength = config.damage * (count or 1)
    Spring.SpawnCEG("bigbulletimpact", x, y + 25, z, 0, 1, 0, 50, 0)
    Spring.PlaySoundFile("sounds/explosions/Explosion1.ogg", 1, x, y, z)
    local attacker = bombID and Spring.ValidUnitID(bombID) and bombID or nil
    if targetID and Spring.ValidUnitID(targetID) and not Spring.GetUnitIsDead(targetID) then
        Spring.AddUnitDamage(targetID, strength, 0, attacker)
        return
    end
    local victims = Spring.GetUnitsInCylinder(x, z, config.blastRadius) or {}
    table.sort(victims)
    for _, id in ipairs(victims) do
        if id ~= bombID then
            local ux, uy, uz = Spring.GetUnitPosition(id)
            if ux then
                local distance = math.sqrt((ux-x)^2 + (uy-y)^2 + (uz-z)^2)
                local damage = strength * math.max(0, 1 - distance / config.blastRadius)
                if damage > 0 then Spring.AddUnitDamage(id, damage, 0, attacker) end
            end
        end
    end
end
return config
