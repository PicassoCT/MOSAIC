return {
  ["lingeringcloud"] = {
  
    poof01 = {
      water                = true,
      ground                = true,
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 8,
      ground             = true,
      properties = {
        airdrag            = 0.8,
        alwaysvisible      = true,
        colormap           = [[
                               0.1 0.1 0.1 0.02  
                               0.1 0.1 0.1 0.4  
                               0.1 0.1 0.1 0.3 
                               0.1 0.1 0.1 0.2 
                               0.2 0.2 0.2 0.2 
                               0.2 0.2 0.2 0.2 
                               0.3 0.3 0.3 0.2 
                               0.3 0.3 0.3 0.1
                               0.4 0.4 0.4 0.02 
                               ]],

        directional        = false,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.0125, 0]],
        numparticles       = 1,
        particlelife       = 500,
        particlelifespread = 50,
        particlesize       = 15,
        particlesizespread = 5,
        particlespeed      = 5,
        particlespeedspread = 5,
        pos                = [[0, 2, 0]],
        sizegrowth         = 0.0001,
        sizemod            = 1.005,
        texture            = [[SmokeAshCloud]],
        useairlos          = false,
      },
    },
  },

}

