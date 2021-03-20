-- electric_explosion

return {
  ["unitonfire"] = {

  
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
	
	  glow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 3,
        heatfalloff        = 1.0,
        maxheat            = 3,
        pos                = [[0,0,0]],
        size               = [[0.5]],
        sizegrowth         = [[1.04]],
        speed              = [[0, 1 0, 0]],
        texture            = [[flame]],
      },
    },
 

	fire1={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[firehd]],

				colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
			

				 pos                = [[0,0,0]],
				gravity            = [[0.0, 1, 0.0]],
				emitvector         = [[0, -1, 0]],
				emitrot		= 45,
				emitrotspread	= 32.35,


				sizeGrowth	= 2,
				sizeMod		= 1.01,

				airdrag			= 0.5,
				particleLife		= 28,
				particleLifeSpread	= 15,
				numParticles		= 4,
				particleSpeed		= 0.2,
				particleSpeedSpread	= 0.4,
				particleSize		= 0.2,
				particleSizeSpread	= 0.06,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},  
		
	fire2={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[flame]],

				colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
			

				 pos                = [[0,0,0]],
				gravity            = [[0.0, 1, 0.0]],
				emitvector         = [[0, -1, 0]],
				emitrot		= 45,
				emitrotspread	= 62.3,


				sizeGrowth	= 2,
				sizeMod		= 1.01,

				airdrag			= 0.5,
				particleLife		=26,
				particleLifeSpread	= 12,
				numParticles		= 2,
				particleSpeed		= 0.3,
				particleSpeedSpread	= 0.4,
				particleSize		= 0.2,
				particleSizeSpread	= 0.09,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},  	
  
  redSpark = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 40,
        emitvector         = [[dir]],
        gravity            = [[0, 0.00000007, 0]],
        numparticles       = 3,
        particlelife       = 350,
        particlelifespread = 11,
        particlesize       = 0.5,
        particlesizespread = 0,
        particlespeed      = 0.002,
        particlespeedspread = 1.005,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.0 0.0000000000000000001]],
        sizemod            = 0.99999999,
        texture            = [[Flake]],
        useairlos          = false,
      },
    },
	
  ashflake = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[0.1 0.1 0.1 .01   0.11 0.13 0.15 .01		0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 40,
        emitvector         = [[dir]],
        gravity            = [[0, 0.00000007, 0]],
        numparticles       = 1,
        particlelife       = 450,
        particlelifespread = 11,
        particlesize       = 0.5,
        particlesizespread = 0,
        particlespeed      = 0.002,
        particlespeedspread = 1.005,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.0 0.0000000000001]],
        sizemod            = 0.9999,
        texture            = [[Flake]],
        useairlos          = false,
      },
    },
  
  },

}

