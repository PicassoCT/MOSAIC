-- trail_ar2

return {
  ["cRailSparks"] = {
  
	

	  sparkO1x = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[0.2 0.8 1 0.01  	0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 40,
        emitvector         = [[r1r-1, 1, r1r-1]],
        gravity            = [[0, -0.17, 0]],
        numparticles       = 6,
        particlelife       = 9,
        particlelifespread = 11,
        particlesize       = 0.5,
        particlesizespread = 0,
        particlespeed      = 2,
        particlespeedspread = 3,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.0 r.35]],
        sizemod            = 1.0,
        texture            = [[gunshot]],
        useairlos          = false,
      },
    },
	electricarcs12x = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.8,
        alwaysvisible      = true,
        colormap           = [[1.0 1.0 1.0 0.04	0.2 0.5 0.9 0.01	0.1 0.5 0.7 0.01]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.17, 0]],
        numparticles       = 1,
        particlelife       = 7,
        particlelifespread = 5,
        particlesize       = 0.5,
        particlesizespread = 1,
        particlespeed      = 0.01,
        particlespeedspread = 0.02,
        pos                = [[0, 2, 0]],
        sizegrowth         = 1,
        sizemod            = 1.0,
        texture            = [[lightening]],
        useairlos          = false,
      },
    },   
	
	
  },

}