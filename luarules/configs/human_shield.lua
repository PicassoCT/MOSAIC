return {
    takeRange = 80,
    speedFactor = 0.6,
    attachmentPiece = "hostagePoint",
    carrierUnits = {
        operativepropagator = true,
        operativeasset = true,
    },
    -- A close-combat hit starts the arena lifecycle, which frees the hostage.
    meleeWeapons = {
        closecombat = true,
    },
    sniperWeapons = {
        sniperrifle = true,
        slowsniperrifle = true,
    },
}
