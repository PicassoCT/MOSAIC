-- dirt

return {
  ["nukesuckfire"] = {
    fireballs = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
    --    colormap           = [[0.25 0.20 0.10 0.05	1 0.8 0 0.5]],
	 colormap           = [[0.25 0.20 0.10 0.2	 	1 0.8 0 0.5		0 0 0 0.0]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 4,
              emitvector         = [[dir]],
        gravity            = [[0, -0.0000000003, 0]],
        numparticles       = 1,
        particlelife       = 20,
        particlelifespread = 20,
        particlesize       = 0.5,
        particlesizespread = 1.6,
        particlespeed      = 3.7,
    
        
        sizegrowth         = 1.000005,
        texture            = [[firehd]],
		particlespeedspread = 1.1,
        pos                = [[r-1 r1, 1, r-1 r1]],
 
        sizemod            = 1.0000000003,
		
		
        useairlos          = false,
      },
      },
	  
	     flamez = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
    --    colormap           = [[0.25 0.20 0.10 0.02	0.9 0.7 0.1 0.5]],
	 colormap           = [[0.25 0.20 0.10 	0.2    0.9 0.7 0.1 0.5		0 0 0 0.0]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 8,
              emitvector         = [[dir]],
        gravity            = [[0, -0.0000000003, 0]],
        numparticles       = 1,
        particlelife       = 30,
        particlelifespread = 15,
        particlesize       = 1,
        particlesizespread = 1.1,
        particlespeed      = 3.7,
    
        
        sizegrowth         = 1.000005,
        texture            = [[fire2]],
		particlespeedspread = 1.1,
        pos                = [[r-1 r1, 1, r-1 r1]],
 
        sizemod            = 1.0000000003,
		
		
        useairlos          = false,
      },
      }, 
    
  },

}

