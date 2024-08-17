return {
    ["glowingshrapnell"] = {
        shrapnell = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = false,
            properties = {
                texture = [[spawnpointtop]],
                colormap = [[1 1 1       0.0125  
                               1 0.78 0.15 0.0125    
                               1 0.58 0.15 0.0125
                               1 0.37 0.15 0.0125
                               0 0 0        0.01]],
                pos = [[0 r-42 r42, 26r14, 0 r-42 r42]],
                gravity = [[0r-0.05r0.05, -0.9 , 0r-0.05r0.05]],
                emitvector = [[dir]],
                emitrot = 3,
                emitrotspread = 25,
                sizeGrowth = 0.45,
                sizeMod = 1.000000000001,
                airdrag = 0.55,
                particleLife = 95,
                particleLifeSpread = 16,
                numParticles = 1,
                particleSpeed = 0.09,
                particleSpeedSpread = 0.12,
                particleSize = 4.008,
                particleSizeSpread = 4,
                directional = true,
                useAirLos = true
            }
        }
    }
}
