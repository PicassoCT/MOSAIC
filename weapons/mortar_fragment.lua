-- Spawned by game_mortar_fragments, never mounted on a unit. Each fragment
-- carries 5% of its parent shell's damage; existing blast damage is retained.
local function fragment(name, damage)
    return {
        name = name,
        weaponType = "Cannon",
        range = 200,
        weaponVelocity = 180,
        damage = {default = damage},
        areaOfEffect = 4,
        edgeEffectiveness = 0,
        craterMult = 0,
        impulseFactor = 0,
        fireStarter = 0,
        collideFriendly = true,
        collideFeature = true,
        avoidFriendly = false,
        noSelfDamage = false,
        waterWeapon = true,
        -- Short, cooling streaks follow the actual damaging projectiles.
        size = 1.8,
        stages = 3,
        separation = 1.2,
        alphaDecay = 0.25,
        sizeDecay = 0.2,
        texture1 = "debris2",
        colorMap = "1 0.85 0.4 1  0.75 0.3 0.08 1  0.18 0.14 0.1 1  0.08 0.07 0.06 0",
        explosionGenerator = "custom:mortar_fragment_hit",
        -- No recursive fragments or individual dynamic lights/ribbons.
        customParams = {wall_damage_multiplier = 0.25, no_projectile_vfx = 1},
    }
end

return lowerkeys({
    mortarfragment = fragment("Mortar shell fragment", 0.05),
    supportmortarfragment = fragment("Support mortar shell fragment", 12),
})
