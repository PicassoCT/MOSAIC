return {
    ["cruisemissiletrail"] = {
        ashcloud = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 4,
            ground = true,
            water = false,
            properties = {
                texture = [[SmokeAshCloud]],
                colormap = [[
				 1 0.78 0.15 0.5    
         1 0.58 0.15 0.25
         1 0.37 0.15 0.25
				 0.345 0.25 0.27 0.35
				 0.5 0.36 0.36 0.45 
				 0.2 0.2 0.2 0.45
				 0.06 0.06 0.06 0.45
				 0.245 0.125 0.127 0.05125
				 0.04 0.04 0.04 0.25
				 0.345 0.25 0.27 0.125
				 0.245 0.125 0.127 0.05125
				 0 0 0 0.0001]],
                pos = [[0 r-42 r42, 26r14, 0 r-42 r42]],
                gravity = [[0r-0.05r0.05, -0.2 , 0r-0.05r0.05]],
                emitvector = [[0r-0.125r0.125, s1, 0r-0.125r0.125]],
                emitrot = 3,
                emitrotspread = 25,
                sizeGrowth = 0.45,
                sizeMod = 1.000000000008,
                airdrag = 0.55,
                particleLife = 100,
                particleLifeSpread = 70,
                numParticles = 1,
                particleSpeed = 0.09,
                particleSpeedSpread = 0.22,
                particleSize = 3.008,
                particleSizeSpread = 6,
                directional = true,
                useAirLos = true
            }
        }
    }
}
