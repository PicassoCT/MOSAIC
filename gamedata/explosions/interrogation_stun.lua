-- Brief, body-sized electrical contact effect; respects line of sight.
return {
    interrogation_stun = {
        arcs = {
            air = true, ground = true, water = true,
            class = [[CSimpleParticleSystem]], count = 1,
            properties = {
                airdrag = 0.8,
                colormap = [[0.8 0.95 1 0.08  0.2 0.55 1 0.04  0 0 0 0]],
                directional = false,
                emitrot = 90, emitrotspread = 90,
                emitvector = [[0, 1, 0]], gravity = [[0, 0, 0]],
                numparticles = 5,
                particlelife = 5, particlelifespread = 4,
                particlesize = 5, particlesizespread = 3,
                particlespeed = 0.5, particlespeedspread = 0.8,
                pos = [[0, 0, 0]], sizegrowth = -0.15, sizemod = 1,
                texture = [[lightening]], useairlos = false,
            },
        },
        contact = {
            air = true, ground = true, water = true,
            class = [[CSimpleParticleSystem]], count = 1,
            properties = {
                airdrag = 1,
                colormap = [[0.8 0.95 1 0.1  0.2 0.5 1 0.03  0 0 0 0]],
                directional = false,
                emitrot = 0, emitrotspread = 0,
                emitvector = [[0, 1, 0]], gravity = [[0, 0, 0]],
                numparticles = 1,
                particlelife = 4, particlelifespread = 0,
                particlesize = 7, particlesizespread = 0,
                particlespeed = 0, particlespeedspread = 0,
                pos = [[0, 0, 0]], sizegrowth = -0.5, sizemod = 1,
                texture = [[flare]], useairlos = false,
            },
        },
    },
}
