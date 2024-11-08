return {
    ["cigarettglowsmoke"] = {
    glowingcigaretttiprising = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
                colormap = [[   
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0.01 
                                0.92 0.05 0.05 0.025  
                                0.92 0.05 0.05 0.05  
                                1.0 0.073 0.0 0.075  
                                1.0 0.073 0.0 0.1  
                                1.0 0.073 0.0 0.075
                                0.92 0.05 0.05 0.05
                                0.92 0.05 0.05 0.025
                                0 0 0 0.01]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.001, 0]],
                gravity = [[0, 0, 0]],
                numparticles = 1,
                particlelife = 60,
                particlelifespread = 0,
                particlesize = 3,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 10, 0]],
                sizegrowth = 0.0,
                sizemod = 1.000000,
                texture = [[spawnpointtop]],
                alwaysvisible = false,
                useairlos = true
            }
        },
       
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
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000


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
                emitvector = [[0, 0.0001, 0]],
                gravity = [[0, 0.001, 0]],
                numparticles = 1,
                particlelife = 250,
                particlelifespread = 25,
                particlesize = 0.3,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 10, 0]],
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
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000
                            0.00 0.00 0.00  0.000


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
                emitvector = [[0, 0.0001, 0]],
                gravity = [[0, 0.001, 0]],
                numparticles = 1,
                particlelife = 220,
                particlelifespread = 25,
                particlesize = 0.3,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 10, 0]],
                sizegrowth = 0.0,
                sizemod = 1.005,
                texture = [[smokeSwirls]],
                alwaysvisible = false,
                useairlos = true
            }
        }
        ,
      glowingcigarettashesfalling = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
                colormap = [[   
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0

                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0

                                0.92 0.05 0.05 0.05
                                0.92 0.05 0.05 0.025
                                0 0 0 0.01]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.001, 0]],
                gravity = [[0, 0.0001, 0]],
                numparticles = 1,
                particlelife = 240,
                particlelifespread = 15,
                particlesize = 5,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 10, 0]],
                sizegrowth = 0.0,
                sizemod = 1.000000,
                texture = [[spawnpointtop]],
                alwaysvisible = false,
                useairlos = true
            }
        }, 
        glowingcigarettsparks = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                airdrag = 0.97,
                alwaysvisible = false,
                colormap = [[   
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0

                                0 0 0 0
                                0 0 0 0
                                0 0 0 0
                                0 0 0 0

                                0.92 0.05 0.05 0.05
                                0.92 0.05 0.05 0.025
                                0 0 0 0.01]],
                directional = true,
                emitrot = 0,
                emitrotspread = 10,
                emitvector = [[0, 0.001, 0]],
                gravity = [[0, 0.0001, 0]],
                numparticles = 1,
                particlelife = 240,
                particlelifespread = 15,
                particlesize = 7,
                particlesizespread = 0,
                particlespeed = 0,
                particlespeedspread = 0,
                pos = [[0, 10, 0]],
                sizegrowth = 0.0,
                sizemod = 1.000000,
                texture = [[fireSparks]],
                alwaysvisible = false,
                useairlos = true
            }
        },
        
    }
}
