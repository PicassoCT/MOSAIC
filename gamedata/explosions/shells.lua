-- shells

return {
  ["shells"] = {
    poof01 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        alwaysvisible      = false,
        colormap           = [[1.0 1.0 1.0 1.0	1.0 1.0 1.0 1.0	]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[1, 0.2, 0]],
        gravity            = [[0, -0.5, 0]],
        numparticles       = 1,
        particlelife       = 20,
        particlelifespread = 1,
        particlesize       = 3,
        particlesizespread = 0,
        particlespeed      = 4,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.0,
        sizemod            = 1.0,
        texture            = [[goldshell]],
        useairlos          = false,
      },
    },
  },

}

