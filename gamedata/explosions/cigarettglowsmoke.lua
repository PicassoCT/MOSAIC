return {
    ["cigarettglowsmoke"] = {
        smoke = {
            air = true,
            class = [[CBitmapMuzzleFlame]],
            count = 1,
            ground = true,
            underwater = 1,
            water = true,
            properties = {
                colormap = [[1.0 0.423 0.25  0.1 
                              0.85 0 0         0.2
                              0.57 0.57 0.57   0.1
                              0.25 0.25 0.25   0.05
                              0.12 0.12 0.12   0.025
                              0.05 0.05 0.05   0.01 ]],
                dir = [[0 0.000001 0]],
                frontoffset = 0,
                fronttexture = [[smoke]],
                length = 5,
                sidetexture = [[smoke_particle]],
                size = 5,
                sizegrowth = 0.01,
                ttl = 60,
                alwaysvisible = false,
                useairlos = true
            }
        },
        fire = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
                colormap = [[0.9 0.2 0.0 1.0  0 0 0 0.01]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.0, 0]],
                gravity = [[0, -0.1, 0]],
                numparticles = 3,
                particlelife = 20,
                particlelifespread = 15,
                particlesize = 3,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 0, 0]],
                sizegrowth = 0.0,
                sizemod = 1.0,
                texture = [[glow]],
                alwaysvisible = false,
                useairlos = true
            }
        },
        firelight = {
            air = true,
            class = [[CSimpleGroundFlash]],
            count = 1,
            ground = true,
            water = true,
            alwaysvisible = false,
            useairlos = true,
            properties = {
                colormap = [[0.9 0.2 0.0 0.5   0 0 0 0.01]],
                size = 22,
                sizegrowth = 1,
                texture = [[glowballred]],
                ttl = 100
            }
        }
    }
}