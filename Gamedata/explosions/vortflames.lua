--lowest part of the fire

return {
  ["vortflames"] = {
  
 
   nom = {
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
        size               = [[0.0005]],
        sizegrowth         = [[0.004]],
        speed              = [[0, 10, 0]],
        texture            = [[flame]],
      },
    },
 
 

  
 
  
		nonnom={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[Fire6]],

				colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
			

				 pos                = [[0,0,0]],
				gravity            = [[0.0, 1, 0.0]],
				emitvector         = [[0r0.1r-0.1, -1, 0r0.1r-0.1]],
				emitrot		= 45,
				emitrotspread	= 62.3,


				sizeGrowth	= 1,
				sizeMod		= 1.01,

				airdrag			= 0.5,
				particleLife		=6,
				particleLifeSpread	= 3,
				numParticles		= 2,
				particleSpeed		= 0.3,
				particleSpeedSpread	= 0.00000004,
				particleSize		= 0.0002,
				particleSizeSpread	= 0.000000000009,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},  	
			
	
					

	
				

},

}