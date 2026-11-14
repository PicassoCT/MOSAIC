-- World-space projections, sized against the 40--52 unit tall lantern floats.
return {
    unitName = "paradehologram",
    tickFrames = 15,
    spawnIntervalFrames = 120,
    spawnDistance = 48,
    roadsideOffset = 60,
    keepRadius = 160,
    clearance = 14,
    maxHolograms = 24,
    ghostEvery = 3, -- every third successful projection; 0 disables ghosts
    pixelSize = 1.25, -- model generation setting; rebuild after changing
    groundOffset = 4,
}
