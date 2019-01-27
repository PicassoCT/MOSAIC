-- dirt

return {
  ["glowsmoke"] = {
  
  glowsmoke={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[SmokeGlowinWeaker]],
			
				colormap           = [[1 0.4 0.25 .6     .02 .02 .02 0.01 .004 .004 .004 0.02		0 0 0 0.01]],
			

				 pos                = [[0 r-13 r13, 26, 0 r-13 r13]],
				gravity            = [[0.14 r0.051, 0.4, 0]],
				emitvector         = [[0, -1, 0]],
				    emitrot            = 45,
					emitrotspread      = 12,


				sizeGrowth	= 0.3,
				sizeMod		= 1,

		
				airdrag			= 0.7,
				particleLife		=45,
				particleLifeSpread	= 2,
				numParticles		= 5,
				particleSpeed		= 0.01,
				particleSpeedSpread	= 0.08,
				particleSize		= 1.14,
				particleSizeSpread	= 14,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},
  
  	  	
		  ashflake = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 2,
  			colormap           = [[0.2 0.2 0.2 0.6		0.5 0.5 0.5 0.5		0 0 0 0.01]],
        directional        = true,
        emitrot            = 12,
        emitrotspread      = 40,
		gravity            = [[0, -0.000000000007, 0]],
		emitvector         = [[0, 1, 0]],
        numparticles       = 2,
        particlelife       = 57,
        particlelifespread = 27,
        particlesize       = 0.08,
        particlesizespread = 0.1,
        particlespeed      = 0.000002,
        particlespeedspread = 0.001,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.1,
        sizemod            = 0.1,
        texture            = [[Flake]],
        useairlos          = false,
      },

	},
	
	
	
	
	},

}

