-- xamelimpact

return {
  ["nukular"] = {
 
     poof01 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.95,
        alwaysvisible      = true,
        	colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
        directional        = true,
        emitrot            = 15,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 42,
        particlelife       = 250,
        particlelifespread = 190,
        particlesize       = 5,
        particlesizespread = 2,
        particlespeed      = 1,
        particlespeedspread = 2,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.0002,
        sizemod            = 1.00000000001,
        texture            = [[fire]],
        useairlos          = true,
      },
    },
	
	 poof02 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.95,
        alwaysvisible      = true,
        	colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
        directional        = true,
        emitrot            = 15,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 10,
        particlelife       = 250,
        particlelifespread = 25,
        particlesize       = 5,
        particlesizespread = 2,
        particlespeed      = 1,
        particlespeedspread = 2,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.00000000002,
        sizemod            = 1.001,
        texture            = [[firehd]],
        useairlos          = true,
      },
    },
	
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 0.1,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 3,
        sizegrowth         = 3,
        speed              = [[0, 1 0, 0]],
        texture            = [[uglynovaexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 0.2,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 7,
        sizegrowth         = 4,
        speed              = [[0, 1 0, 0]],
        texture            = [[redexplo]],
      },
    },
	
    
	
  },
  
  
  
  
  
  
  
  }



