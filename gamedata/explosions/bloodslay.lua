-- blood_spray

return {
  ["bloodslay"] = {
	blooddrops = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[0.7 0.1 0.1 .01   0.8 0.1 0.05 .01		0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 5,
        emitvector         = [[0,1,0]],
        gravity            = [[0, -0.07, 0]],
        numparticles       = 1,
        particlelife       = 23,
        particlelifespread = 4,
        particlesize       = 0.5,
        particlesizespread = 1,
        particlespeed      = 1,
        particlespeedspread = 0.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.0 r.15]],
        sizemod            = 0.9888890,
        texture            = [[bloodsplat]],
        useairlos          = false,
      },
    },
		
	flare = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      ground             = false,
      water              = true,
      properties = {
        colormap           = [[1 1 1 0.05  1 1 1 0.05   0 0 0 0]],
        dir                = [[0r0.5r-0.5,0.5r0.5,0r0.5r-0.5]],
        frontoffset        = 0,
        fronttexture       = [[bloodsplat]],
        length             = 2,
        sidetexture        = [[bloodsplat]],
        size               = 3,
        sizegrowth         = 16,
        ttl                = 18,
      },
    },
	
	
	blooddrops2 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[0.7 0.1 0.1 .01   0.8 0.1 0.05 .01		0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 5,
        emitvector         = [[dir]],
        gravity            = [[0, -0.07, 0]],
        numparticles       = 2,
        particlelife       = 19,
        particlelifespread = 22,
        particlesize       = 0.5,
        particlesizespread = 1,
        particlespeed      = 1,
        particlespeedspread = 0.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.0 r.35]],
        sizemod            = 1.0,
        texture            = [[fireSparks]],
        useairlos          = false,
      },
    },
		
	
	
  },

}
