

-- dirt

return {
  ["firefive"] = {
    frontalFire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 5,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,

 		colormap           = [[1 0.61 0.27 0.01 	1 0.61 0.27 0.01	0.97 0.23 0.13 0.01  0.97 0.23 0.13 0.01 	 0.64 0.10 0.17 0.01]],
        directional        = true,
        emitrot            = 1,
        emitrotspread      = 1,
        emitvector         = [[dir]],
        gravity            = [[0r0.007r-0.007, 0r-0.001, 0r0.007r-0.007]],
        numparticles       = 1,
        particlelife       = 80,
        particlelifespread = 40,
        particlesize       = [[1]],
        particlesizespread = 7.5,
        particlespeed      = 1,
        particlespeedspread = 0.2,
        pos                = [[r5r-5,r10r-10, r5r-5]],
        sizegrowth         = 0.99,
        sizemod            = 0.9,
        texture            = [[fire8]],
        useairlos          = false,
      },
    }, 
swirlingSmoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
        colormap           = [[0 0 0 0	0 0 0 0		0 0 0 0  	0 0 0 0   0 0 0 0  0 0 0 0  	1 0.8 0  0.25	0.25 0.20 0.25 0.5	 0.25 0.20 0.25 0.75 0.25 0.20 0.25 0.01 0.25 0.20 0.25 0.001 ]],
        directional        = true,
        emitrot            = 3,
        emitrotspread      = 2,
        emitvector         = [[dir]],
		     gravity            = [[0r0.005r-0.005, 0.000r0.0001, 0r0.005r-0.005]],

        numparticles       = 1,
        particlelife       = 120,
        particlelifespread = 50,
        particlesize       = [[150]],
        particlesizespread = 35,
        particlespeed      = 1,
        particlespeedspread = 0.2,
        pos                = [[r5r-5,5r10, r5r-5]],
        sizegrowth         = 1.99,
        sizemod            = 0.95,
        texture            = [[smokeSwirls]],
        useairlos          = false,
      },
    },
sideFire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 3,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
          
		    colormap           = [[1 0.61 0.27  0.01	1 0.61 0.27  0.01	 0.20 0.10 0.01]],
		  --  colormap           = [[0.25 0.20 0.10 0.01	1 0.8 0 0.05 0.25 0.20 0.10 0.01]],
        directional        = true,
        emitrot            = 15,
        emitrotspread      = 5,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 10,
        particlesize       = [[1]],
        particlesizespread = 1.5,
        particlespeed      = 1,
        particlespeedspread = 0.2,
        pos                = [[r-0.5 r0.5, 1 r2, r-0.5 r0.5]],
        sizegrowth         = 0.99,
        sizemod            = 0.9,
        texture            = [[fire8]],
        useairlos          = false,
      },
    },
  
  },

}

