-- dirt

return {
  ["firetwo"] = {
     dirtgw = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
        colormap           = [[0.25 0.20 0.10 0.1	1 0.8 0 0.5]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 2,
        particlelife       = 60,
        particlelifespread = 180,
        particlesize       = [[1]],
        particlesizespread = 2.5,
        particlespeed      = 1,
        particlespeedspread = 1.2,
        pos                = [[r-0.5 r0.5, 1 r2, r-0.5 r0.5]],
        sizegrowth         = 0.99,
        sizemod            = 0.9,
        texture            = [[fire2]],
        useairlos          = false,
      },
    },
  
  
  },

}