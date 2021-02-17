return {
  ["nukeexplosion"] = {
    
    groundflash = {
      air                = true,
      alwaysvisible      = true,
      circlealpha        = 0.6,
      circlegrowth       = 6,
      flashalpha         = 0.9,
      flashsize          = 120,
      ground             = true,
      ttl                = 122,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.5,
        [3]  = 0,
      },
    },
    poof01 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.8,
        alwaysvisible      = true,
        colormap           = [[1.0 1.0 1.0 0.04	0.9 0.5 0.2 0.01	0.8 0.1 0.1 0.01]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.05, 0]],
        numparticles       = 8,
        particlelife       = 10,
        particlelifespread = 5,
        particlesize       = 20,
        particlesizespread = 0,
        particlespeed      = 5,
        particlespeedspread = 5,
        pos                = [[0, 2, 0]],
        sizegrowth         = 5,
        sizemod            = 1.0,
        texture            = [[flashside1]],
        useairlos          = false,
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
        size               = 1,
        sizegrowth         = 9,
        speed              = [[0, 1 0, 0]],
        texture            = [[uglynovaexplo]],
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
        heatfalloff        = 0.3,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 3,
        sizegrowth         = 25,
        speed              = [[0, 1 0, 0]],
        texture            = [[flare]],
      },
    },
	glowing = {
      air                = true,
      class              = [[explspike]],
      count              = 44,
      ground             = true,
      water              = true,

	  
      properties = {
        alpha              = 0.9,
        alphadecay         = 0.02,
           color              = [[1,0.8,0.5]],
	   -- colormap           = [[0.9 0.8 0.4 0.04	 0.9 0.5 0.0 0.01	0 0 0 0.00]],
        dir                = [[-15 r50,-15 r50,-15 r50]],
        length             = 2,
        width              = 86,
      },
    },	
	
	
  },

}

