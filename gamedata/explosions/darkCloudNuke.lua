-- dirt

return {
  ["darkcloudnuke"] = {
  

  
  dkcln = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
     	 colormap           = [[0.7 0.55 0.45 0.75		0.5 0.5 0.5 0.3		0 0 0 0.01]],
        --colormap           = [[1 0.35 0.05 0.5	0 0 0 0.0]],
     
        directional        = false,
        emitrot            = 62,
        emitrotspread      = 122,
              emitvector         = [[0,1,0]],
        gravity            = [[0, -0.0018, 0]],
        numparticles       = 1,
        particlelife       = 45,
        particlelifespread = 55,
        particlesize       = 1,
        particlesizespread = 0.5,
        particlespeed      = 0.22,
    
        
        sizegrowth         = 1.00000000000000001,
        texture            = [[SmokeAshCloud]],
		particlespeedspread = 0.03,
        pos                = [[r-1 r1, 1, r-1 r1]],
 
        sizemod            = 1.00000000000000001,
		
		
        useairlos          = false,
      },
      },
  
  
  
  
	
	},

}

