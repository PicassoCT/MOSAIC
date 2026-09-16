-- Conventional weapons have their own definitions so operative, police and
-- concealed-explosive weapons keep their existing behaviour.
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[type(key) == "string" and key:lower() or key] = copy(item)
    end
    return result
end

local function variant(path, key, changes)
    local weapon = copy(VFS.Include(path)[key])
    for field, value in pairs(changes) do weapon[field] = value end
    return weapon
end

local weapons = {}
weapons.escortmachinegun = variant("weapons/submachinegun.lua", "submachingegun", {
    name = "Weevil escort gun",
    reloadtime = 3.5,
    customparams = {wall_damage_multiplier = 0.05},
})

weapons.covermachinegun = variant("weapons/heavymachinegun.lua", "heavymachinegun", {
    name = "Covering-fire machine gun",
    damage = {default = 12},
    avoidfriendly = true,
    customparams = {wall_damage_multiplier = 0.05},
})

weapons.escortantiair = variant("weapons/aamachinegun.lua", "aamachinegun", {
    name = "Short-range drone defence",
    range = 650,
    damage = {default = 12},
    burst = 12,
    burstrate = 0.12,
    reloadtime = 4,
    avoidfriendly = true,
    customparams = {wall_damage_multiplier = 0.05},
})

weapons.militaryantiair = variant("weapons/guidedrocket.lua", "s16rocket", {
    name = "Dedicated air-defence missile",
    range = 1050,
    damage = {default = 650},
    reloadtime = 6,
    areaofeffect = 48,
    avoidfriendly = true,
    firestarter = 0,
    customparams = {wall_damage_multiplier = 0.1},
})

weapons.breachingcannon = variant("weapons/tankcannon.lua", "tankcannon", {
    name = "Controlled-demolition tank cannon",
    damage = {default = 600},
    areaofeffect = 32,
    sprayangle = 0,
    avoidfriendly = true,
    cratermult = 0,
    -- 2,400 damage per direct hit: five hits / 20 seconds after the first
    -- impact to open a full-health 10,000 HP wall segment with one tank.
    customparams = {wall_damage_multiplier = 4},
})

weapons.militaryantitank = variant("weapons/javelinrocket.lua", "javelinrocket", {
    name = "Sustained-fire anti-armour missile",
    range = 900,
    reloadtime = 12,
    areaofeffect = 24,
    avoidfriendly = true,
    firestarter = 0,
    customparams = {wall_damage_multiplier = 0.5},
})

weapons.supportmortar = variant("weapons/mortar.lua", "mortar", {
    name = "Position-clearing mortar",
    range = 750,
    reloadtime = 8,
    damage = {default = 240},
    areaofeffect = 120,
    edgeeffectiveness = 0.15,
    accuracy = 180,
    avoidfriendly = true,
    customparams = {wall_damage_multiplier = 0.25},
})

weapons.supportgunshipmg = variant("weapons/cGunShipMG.lua", "cgunshipmg", {
    name = "Blackhawk escort gun",
    range = 420,
    damage = {default = 18},
    burst = 12,
    burstrate = 0.12,
    reloadtime = 4,
    avoidfriendly = true,
    customparams = {wall_damage_multiplier = 0.05},
})

weapons.campaignrocket = variant("weapons/guidedrocket.lua", "s16rocket", {
    name = "Predator area-strike salvo",
    canattackground = true,
    range = 700,
    damage = {default = 300},
    areaofeffect = 160,
    edgeeffectiveness = 0.1,
    burst = 4,
    burstrate = 0.3,
    reloadtime = 24,
    tracks = false,
    turnrate = 0,
    trajectoryheight = 0,
    startvelocity = 400,
    weaponvelocity = 600,
    weaponacceleration = 80,
    flighttime = 5,
    sprayangle = 500,
    avoidfriendly = true,
    firestarter = 0,
    customparams = {wall_damage_multiplier = 0.25},
})

weapons.interceptormissile = copy(weapons.militaryantiair)
weapons.interceptormissile.name = "F35 interceptor missile"
weapons.interceptormissile.range = 1200

weapons.fightergroundmissile = variant("weapons/guidedrocket.lua", "s16rocket", {
    name = "F35 light ground-attack missile",
    canattackground = true,
    range = 600,
    damage = {default = 200},
    areaofeffect = 32,
    reloadtime = 18,
    avoidfriendly = true,
    firestarter = 0,
    customparams = {wall_damage_multiplier = 0.25},
})

return lowerkeys(weapons)
