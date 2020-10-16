--lowest part of the fire

return {
  ["flames"] = {
  
 
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
     pos                = [[0r-5r10,0r-5r10,0r-5r10]],
     size               = [[0.5]],
     sizegrowth         = [[1.04]],
     speed              = [[0, 1 0, 0]],
     texture            = [[Fire6]],
   },
 },


	fire1={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=2,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[Fire4]],

				colormap           = [[1 1 1 .01  	1 1 1 .01  	1 0.3 0.05 .01		0 0 0 0.01]],
			

				 pos                = [[0 r-5 r5,0 r15,0 r-5 r5]],
				gravity            = [[0.0, 1r0.5, 0.0]],
				emitvector         = [[0r0.1 r-0.1, -1, 0 r0.1 r-0.1]],
				emitrot		= 45,
				emitrotspread	= 32.35,


				sizeGrowth	= 1,
				sizeMod		= 1.01,

				airdrag			= 0.5,
				particleLife		= 8,
				particleLifeSpread	= 15,
				numParticles		= 1,
				particleSpeed		= 0.2,
				particleSpeedSpread	= 3.4,
				particleSize		= 0.02,
				particleSizeSpread	= 0.12,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},  
		
	      aoceanofflame = {
          air                = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 1,
          ground             = true,
		
          underwater         = 1,
          water              = false,
		    
          properties = {
		    alwaysvisible      = true,
		    useairlos          = false,
			colormap           = [[1 1 1 .004 	1 0.5 0.25 .004 	1 0.5 0.25 .004  	 1 0.3 0.05 .004		1 0.3 0.05 .004		1 0.3 0.05 .002	]],
			dir                = [[0r0.1,0.2r1,0r0.1]],
            frontoffset        = 0,
            fronttexture       = [[fire]],
            length             = 25,
            sidetexture        = [[fireside]],
            size               = 14,
            sizegrowth         = 0.995,
            ttl                = 21,
          },
        },

  	
		
		
	fire2={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=2,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[Fire3]],

				colormap           = [[1 1 1 .01 1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
			

				 pos                = [[0,0r5,0]],
				gravity            = [[0.0, 1r0.3 r-0.3, 0.0]],
				emitvector         = [[0r0.01 r-0.01, -1, 0r0.01 r-0.01]],
				emitrot		= 45,
				emitrotspread	= 62.3,


				sizeGrowth	= 1,
				sizeMod		= 1.01,

				airdrag			= 0.5,
				particleLife		=6,
				particleLifeSpread	= 18,
				numParticles		= 1,
				particleSpeed		= 0.3,
				particleSpeedSpread	= 1.4,
				particleSize		= 0.02,
				particleSizeSpread	= 0.09,

				directional		= 1, 
				useAirLos		= 0,
				},

	
		
	
		},  	
		
 sparkredX = {
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
        emitvector         = [[0,1,0]],
        gravity            = [[0, -0.001, 0]],
        numparticles       = 1,
        particlelife       = 19,
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
		
					

	
				

},

}