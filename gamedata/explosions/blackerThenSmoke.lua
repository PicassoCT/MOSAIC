-- dirt

return {
  ["blackerthensmoke"] = {
poofoo = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.75,
        alwaysvisible      = true,
           colormap           = [[0.1 0.2 0.6 0.25	0.1 0.1 0.3 0.25	]],
		--colormap           = [[1 0.4 0.25 1     .02 .02 .02 0.01 .004 .004 .004 0.02		0 0 0 0.01]],
        directional        = false,
		
			

		
		
		
		
		
        emitrot            = 45,--45
        emitrotspread      = 12,--12
	emitvector         = [[0, -1, 0]],
      
				gravity            = [[0, 0.4, 0]],
	  
	  

        numparticles       = 3,
        particlelife       = 65,
        particlelifespread = 2,
		
        particlesize       = 0.5,
        particlesizespread = 5,
		
        particlespeed      = 0.35,
        particlespeedspread = 0.00004,
       		 pos                = [[0 r-13 r13, 26, 0 r-13 r13]],
       	sizeGrowth	= 0.3,
				sizeMod		= 1,
        texture            = [[smokesmall]],
        useairlos          = false,
				},
    },
	
   --test
    
	
	
},

}

