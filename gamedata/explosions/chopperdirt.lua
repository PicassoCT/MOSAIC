-- dirt

return {
  ["chopperdirt"] = {
 
	  
	    chos = {
       air                = false,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.7,
        alwaysvisible      = true,
        colormap           = [[0.25 0.20 0.10 0.55	0 0 0 0.0]],
        directional        = true,
        emitrot            = 35,
        emitrotspread      = 5,
        emitvector         = [[dir]],
        gravity            = [[0, -0.0003, 0]],
        numparticles       = 2,
        particlelife       = 15,
        particlelifespread = 65,
        particlesize       = [[12 r4]],
        particlesizespread = 10,
        particlespeed      = 1,
        particlespeedspread = 3,
        pos                = [[r-0.5 r0.5, 1 r2, r-0.5 r0.5]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[new_dirta]],
        useairlos          = false,
      },
    },
    
  },

}

