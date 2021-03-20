-- beamimpact

return {
  ["fireSparks"] = {
    
    poof02 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.2,
        alwaysvisible      = true,
        colormap           = [[0.9 0.4 0.0 0.01	0.9 0.2 0.0 0.01	0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.005, 0]],
        numparticles       = 2,
        particlelife       = 4,
        particlelifespread = 8,
        particlesize       = 3,
        particlesizespread = 0,
        particlespeed      = 1,
        particlespeedspread = 3,
        pos                = [[0, 2, 0]],
        sizegrowth         = 0.8,
        sizemod            = 0.9999999,
        texture            = [[fireSparks]],
        useairlos          = false,
      },
    },
   
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 10,
        maxheat            = 15,
        pos                = [[r-3 r3, 5, r-3 r3]],
        size               = 1,
        sizegrowth         = 4,
        speed              = [[0, 1, 0]],
        texture            = [[redexplo]],
      },
    },
  },

}

