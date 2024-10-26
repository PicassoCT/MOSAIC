return {
    ["cigarettglowsmoke"] = {
       
 smoke = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
               colormap = [[
                              1.0 0.423 0.25  0.1
                              1.0 0.423 0.25  0.03
                              0.85 0 0        0.045
                              0.57 0.57 0.57  0.035
                              0.25 0.25 0.25  0.020
                              0.12 0.12 0.12  0.025
                              0.05 0.05 0.05  0.001 ]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.0, 0]],
               gravity = [[0, 0.001, 0]],
                numparticles = 2,
                particlelife = 250,
                particlelifespread = 25,
                particlesize = 3,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 0, 0]],
                sizegrowth = 0.0,
                sizemod = 1.005,
                texture = [[foam]],
                alwaysvisible = false,
                useairlos = true
            }
        }
        , 
    smokeswirl = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
               colormap = [[
                              1.0 0.423 0.25  0.1
                              1.0 0.423 0.25  0.03
                              0.85 0 0        0.045
                              0.57 0.57 0.57  0.035
                              0.25 0.25 0.25  0.020
                              0.12 0.12 0.12  0.025
                              0.05 0.05 0.05  0.001 ]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.0, 0]],
               gravity = [[0, 0.001, 0]],
                numparticles = 2,
                particlelife = 220,
                particlelifespread = 25,
                particlesize = 3,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 0, 0]],
                sizegrowth = 0.0,
                sizemod = 1.005,
                texture = [[GenericSmokeCloud]],
                alwaysvisible = false,
                useairlos = true
            }
        }
        ,
        fire = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
                colormap = [[0 0 0 0.01 
                0.9 0.2 0.0 0.1  
                0.9 0.2 0.0 0.05 
                0 0 0 0.01]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.0, 0]],
                gravity = [[0, 0, 0]],
                numparticles = 1,
                particlelife = 60,
                particlelifespread = 15,
                particlesize = 1,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 0, 0]],
                sizegrowth = 0.0,
                sizemod = 1.000000,
                texture = [[glow]],
                alwaysvisible = false,
                useairlos = true
            }
        },
            groundflash = {
      air                = true,
      alwaysvisible      = true,
      circlealpha        = 0.6,
      circlegrowth       = 1,
      flashalpha         = 0.9,
      flashsize          = 220,
      ground             = true,
      ttl                = 60,
      water              = true,
      color = {
        [1]  = 0.9,
        [2]  = 0.2,
        [3]  = 0.0,
      },
    },        
    }
}
