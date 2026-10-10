-- A block is roughly 15--21 elmos across. Keep the puff within that footprint.
return {
    building_block_dust = {
        dust = {
            air = true, ground = true, water = false,
            class = "CSimpleParticleSystem", count = 1,
            properties = {
                airdrag = 0.90,
                colormap = "0.30 0.27 0.23 0.28  0.24 0.22 0.20 0.16  0.18 0.17 0.16 0",
                directional = false,
                emitrot = 65, emitrotspread = 25, emitvector = "0, 1, 0",
                gravity = "0, -0.015, 0",
                numparticles = 8,
                particlelife = 20, particlelifespread = 14,
                particlesize = 3, particlesizespread = 2,
                particlespeed = 0.8, particlespeedspread = 0.6,
                pos = "0, 1, 0", sizegrowth = 0.10, sizemod = 1,
                texture = "smokeSwirls", useairlos = false,
            },
        },
    },
}
