return {
    ["molotowtrail"] = {
        poof02 = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.2,
                alwaysvisible = true,
                colormap = [[0.9 0.4 0.0 0.01 0.9 0.2 0.0 0.01  0.0 0.0 0.0 0.01]],
                directional = false,
                emitrot = 45,
                emitrotspread = 32,
                emitvector = [[dir]],
                gravity = [[0, -0.005, 0]],
                numparticles = 1,
                particlelife = 1,
                particlelifespread = 16,
                particlesize = 3,
                particlesizespread = 2,
                particlespeed = 1,
                particlespeedspread = 3,
                pos = [[0, 0, 0]],
                sizegrowth = 0.8,
                sizemod = 0.9999999,
                texture = [[fireSparks]],
                useairlos = false
            }
        },


        trailingFlamesa = {
            air = true,
            class = [[CBitmapMuzzleFlame]],
            count = 1,
            ground = true,
            underwater = false,
            water = true,
            properties = {
                alwaysvisible = false,
                useairlos = true,
                colormap = [[1 1 1 0.05            1 1 1 0.1  
                             1 0.9 0.5 0.1         1 0.9 0.5 0.5 
                             1 0.6 0.2 0.01         1 0.6 0.2 0.01 
                             1 0.3 0.05 0.005       1 0.3 0.05 0.005   
                             0.1 0.05 0.01 0.001    0.1 0.05 0.01 0.001
                             0 0 0 0]],
                dir = [[dir]],
                frontoffset = 0,
                fronttexture = [[]],
                length = 25,
                sidetexture = [[Fire4]],
                size = 15,
                sizegrowth = -0.9,
                ttl = 25,
            },
        },
        trailingFlamesb = {
            air = true,
            class = [[CBitmapMuzzleFlame]],
            count = 1,
            ground = true,
            underwater = false,
            water = true,
            properties = {
                alwaysvisible = false,
                useairlos = true,
                colormap = [[1 1 1 0.001             1 1 1 0.01  
                             1 0.9 0.5 0.1         1 0.9 0.5 0.5 
                             1 0.6 0.2 0.001         1 0.6 0.2 0.05 
                             1 0.3 0.05 0.1       1 0.3 0.05 0.5   
                             0.1 0.05 0.01 0.01    0.1 0.05 0.01 0.001
                             0 0 0 0]],
                dir = [[dir]],
                frontoffset = 0,
                fronttexture = [[]],
                length = 23,
                sidetexture = [[Fire1]],
                size = 14,
                sizegrowth = -0.92,
                ttl = 25,
            },
        },
        trailingFlamesc = {
            air = true,
            class = [[CBitmapMuzzleFlame]],
            count = 1,
            ground = true,
            underwater = false,
            water = true,
            properties = {
                alwaysvisible = false,
                useairlos = true,
                colormap = [[1 1 1 0.001            1 1 1 0.001
                             1 1 1 0.05             1 1 1 0.1  
                             1 0.9 0.5 0.1          1 0.9 0.5 0.05 
                             1 0.6 0.2 0.01         1 0.6 0.2 0.01 
                             1 0.3 0.05 0.005       1 0.3 0.05 0.005   
                             0.1 0.05 0.01 0.001    0.1 0.05 0.01 0.001
                             0 0 0 0]],
                dir = [[dir]],
                frontoffset = 0,
                fronttexture = [[]],
                length = 21,
                sidetexture = [[Fire2]],
                size = 13,
                sizegrowth = -0.94,
                ttl = 25,
            },
        },
    }
}

