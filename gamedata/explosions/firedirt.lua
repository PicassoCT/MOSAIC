-- dirt

return {
  ["firedirt"] = {
    dirtgf = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
        colormap           = [[1 0.35 0.05 1.0	0 0 0 0.0]],
     --   colormap           = [[0.25 0.20 0.10 1.0	0 0 0 0.0]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 2,
              emitvector         = [[dir]],
        gravity            = [[0, -0.0000000003, 0]],
        numparticles       = 1,
        particlelife       = 55,
        particlelifespread = 15,
        particlesize       = 1,
        particlesizespread = 0.1,
        particlespeed      = 2.7,
    
        
        sizegrowth         = 0.94,
        texture            = [[new_dirta]],
		particlespeedspread = 1.1,
        pos                = [[r-1 r1, 1, r-1 r1]],
 
        sizemod            = 0.95,
		
		
        useairlos          = false,
      },
      },
    
  },

}

