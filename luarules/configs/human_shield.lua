return {
    takeRange = 80,
    speedFactor = 0.6,
    moneyPerSecond = 40,
    filmedMoneyPerSecond = 80,
    witnessRange = 300,
    witnessChancePercent = 25, -- one opportunity per held hostage per second
    witnessDurationMs = 10000,
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
