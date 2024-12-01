 -- trail_ar2

return {
  ["flyinggarbage"] = {
  

  papers = {
      air                = true,
      class              = [[CSimpleParticleSystem]] ,	
	  
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[0.8  0.8  0.8  0.3   0.8  0.8  0.8  1 	0.8  0.8  0.8  1   	]],	
		
        directional        = true,
        emitrot            = 25,
        emitrotspread      = 40,
        emitvector         = [[0,0.3,0]],	
       gravity            = [[0, -0.0027, 0]] , 
        numparticles       = 3,
        particlelife       = 80,
        particlelifespread = 227,
        particlesize       = 2.5,
        particlesizespread = 3,
        particlespeed      = 2,
        particlespeedspread = 3,
        pos                = [[0, 0r26 r-26, 0]],
		 
        sizegrowth         = [[0.0 ]] ,
        sizemod            = 1.0,
        texture            = [[paper]] ,
		
        useairlos          = false,
      },
    }
  }
}