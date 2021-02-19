-- dirt

return {
  ["greycloud"] = {
  

  
  
  
  zashcloud={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[SmokeAshCloud]],
				--colormap           = [[0.2 0.2 0.2 0.6		0.5 0.5 0.5 0.5		0 0 0 0.01]],
				colormap           = [[0.8 0.55 0.35 0.6	0.5 0.5 0.5 0.5		0 0 0 0.01]],
				--colormap           = [[1 0.4 0.25 .01     .02 .02 .02 0.01 .004 .004 .004 0.01		0 0 0 0.01]],
			

				 pos                = [[0, 0, 0]],
				gravity            = [[0, 0.00000000001, 0]],
				emitvector         = [[ dir]],
				  emitRot		= 12,
				 emitRotSpread	= 12.824,


		     sizegrowth         = 1.000000000000000000000001,
			 sizemod            = 0.95,--1

		
				airdrag			= 0.55,
				particleLife		=175,
				particleLifeSpread	= 6,
				numParticles		= 1,
				particleSpeed		= 1,
				particleSpeedSpread	= 0.4999999,
				particlesize       = 0.3,
				particleSizeSpread	= 0.6,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},
  
  
   
  
   dirtgggg = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.7,
        alwaysvisible      = true,
        colormap           = [[0.25 0.20 0.10 0.01	0 0 0 0.0]],
        directional        = true,
        emitrot            = 15,
        emitrotspread      = 45,
        emitvector         = [[0, 0.3, 0]],
        gravity            = [[0, -0.01, 0]],
        numparticles       = 1,
        particlelife       = 75,
        particlelifespread = 15,
        particlesize       = [[0.8]],
        particlesizespread = 12,
        particlespeed      = 3,
        particlespeedspread = 2,
        pos                = [[r-0.5 r0.5, 1 r2, r-0.5 r0.5]],
        sizegrowth         = 1.00000002,
        sizemod            = 0.7,
        texture            = [[SmokeGlowinWeaker]],
        useairlos          = false,
      },
    },
  
  
	
	},

}

