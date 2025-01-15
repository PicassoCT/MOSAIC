return {
    ["depressol"] = {
        spray = {
          air                = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 1,
          ground             = true,
          underwater         = 1,
          water              = true,
          properties = {
            colormap           = [[
              1 1  1    .01   
              0.5 0.5 1 .01     
              0 0 0 0]],
            dir                = [[0, 1, 0]],
            frontoffset        = 0,
            fronttexture       = [[sprayFront]],
            length             = 2,
            sidetexture        = [[spraySide]],
            size               = 2,
            sizegrowth         = 1.3,
            ttl                = 55,
          },
        },


        
        particles = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.75,
                alwaysvisible = true,
                colormap = [[
                0 0 0 0
                0 0 0 0
                0 0 0 0
                1 1 1 0.02225   
                0.5 0.5 1 0.04225   
                0.5 0.5 1 0.03125 
                0.5 0.5 1 0.02125
                0.5 0.5 1 0.0225
                0.5 0.5 1 0.0125 
                0.5 0 5 0.0]],
                directional = false,
                emitrot = 45,
                 --45
                emitrotspread = 17,
                 --12
                emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
                gravity = [[0, -0.3r0.15r-0.15 , 0]],
                numparticles = 3,
                particlelife = 120,
                particlelifespread = 65,
                particlesize = 0.15,
                particlesizespread = 1.8,
                particlespeed = 0.35,
                particlespeedspread = 0.0004,
                pos = [[0, 0, 0]],
                sizeGrowth = 0.666,
                sizeMod = 1.0000000006,
                texture = [[new_dirta]],
                useairlos = false
            }
        },
        particlesa = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.75,
                alwaysvisible = true,
                colormap = [[
                0 0 0 0
                0 0 0 0
                0 0 0 0
                1 1 1 0.02225   
                0.5 0.5 1 0.04225   
                0.5 0.5 1 0.03125 
                0.5 0.5 1 0.03125
                0.5 0.5 1 0.0225
                0.5 0.5 1 0.0225 
                0.5 0 5 0.0]],
                directional = false,
                emitrot = 45,
                 --45
                emitrotspread = 17,
                 --12
                emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
                gravity = [[0, -0.3r0.15r-0.15 , 0]],
                numparticles = 3,
                particlelife = 120,
                particlelifespread = 65,
                particlesize = 0.15,
                particlesizespread = 1.8,
                particlespeed = 0.35,
                particlespeedspread = 0.0004,
                pos = [[0, 0, 0]],
                sizeGrowth = 0.666,
                sizeMod = 1.0000000006,
                texture = [[neodirta]],
                useairlos = false
            }
        },   
        dropplets = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 3,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.75,
                alwaysvisible = true,
                colormap = [[
                0 0 0 0
                1 1 1 0.0125
                0.5 0.5 1 0.003125   
                0.5 0.5 1 0.00125
                0.5 0.5 1 0.0]],
                directional = false,
                emitrot = 45,
                 --45
                emitrotspread = 17,
                 --12
                emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
                gravity = [[0, -0.3r0.15r-0.15 , 0]],
                numparticles = 1,
                particlelife = 30,
                particlelifespread = 65,
                particlesize = 0.015,
                particlesizespread = 1.8,
                particlespeed = 0.35,
                particlespeedspread = 0.0004,
                pos = [[0, 0, 0]],
                sizeGrowth = 0.666,
                sizeMod = 1.0000000006,
                texture = [[fireSparks]],
                useairlos = false
            }
        }
    }
}
