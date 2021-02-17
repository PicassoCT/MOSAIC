-- dirt

return {
  ["orangesmoke"] = {
  
  ashcloud={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[SmokeAshCloud]],
			             colormap           = [[1 0.35 0.05 0.1	0 0 0 0.0]],
				
			

				 pos                = [[0 r-13 r13, 26, 0 r-13 r13]],
				gravity            = [[0, 0.1, 0]],
				emitvector         = [[0, 1,0]],
				  emitRot		= 22,
				 emitRotSpread	= 12.824,


				sizeGrowth	= 0.45,
				sizeMod		= 0.65,

		
				airdrag			= 0.55,
				particleLife		=125,
				particleLifeSpread	= 26,
				numParticles		= 2,
				particleSpeed		= 0.09,
				particleSpeedSpread	= 0.0001,
				particleSize		= 16.08,
				particleSizeSpread	= 15.25,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},
  
  
    dirtgf = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
        colormap           = [[1 0.35 0.05 0.2	0 0 0 0.0]],
     --   colormap           = [[0.25 0.20 0.10 1.0	0 0 0 0.0]],
        directional        = false,
        emitrot            = 22,
        emitrotspread      = 12,
              emitvector         = [[0,1,0]],
        gravity            = [[0, 0.022, 0]],
        numparticles       = 1,
        particlelife       = 65,
        particlelifespread = 25,
        particlesize       = 1,
        particlesizespread = 13.5,
        particlespeed      = 0.07,
    
        
        sizegrowth         = 0.94,
        texture            = [[new_dirta]],
		particlespeedspread = 0.3,
        pos                = [[r-1 r1, 1, r-1 r1]],
 
        sizemod            = 0.95,
		
		
        useairlos          = false,
      },
      },
    
  
dirtgff = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
        colormap           = [[1 0.35 0.05 0.9	0 0 0 0.0]],
     --   colormap           = [[0.25 0.20 0.10 1.0	0 0 0 0.0]],
        directional        = false,
        emitrot            = 22,
        emitrotspread      = 12,
              emitvector         = [[0,1,0]],
        gravity            = [[0, 0.018, 0]],
        numparticles       = 1,
        particlelife       = 65,
        particlelifespread = 25,
        particlesize       = 1,
        particlesizespread = 13.5,
        particlespeed      = 0.07,
    
        
        sizegrowth         = 0.94,
        texture            = [[new_dirta]],
		particlespeedspread = 0.3,
        pos                = [[r-1 r1, 1, r-1 r1]],
 
        sizemod            = 0.95,
		
		
        useairlos          = false,
      },
      },
  
  
	
	},

}

