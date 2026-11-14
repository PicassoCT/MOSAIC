local definition = Abstract:New{
    name = "Parade pixel projection",
    description = "A stationary lantern hologram beside the procession",
    objectName = "paradeHologram.dae",
    script = "paradeHologramScript.lua",
    maxDamage = 9000, mass = 0,
    footprintX = 1, footprintZ = 1,
    blocking = false, canMove = false, canAttack = false,
    canReclaim = false, reclaimable = false, capturable = false,
    sightDistance = 0, radarDistance = 0,
    category = [[NOTARGET ABSTRACT]],
    explodeAs = "none", selfDestructAs = "none",
    usePieceCollisionVolumes = false,
    customparams = {baseclass="Abstract", parade_hologram=true, neon_hologram_type=4},
}
return lowerkeys({paradehologram=definition})
