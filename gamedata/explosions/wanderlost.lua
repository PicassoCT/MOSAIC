-- dirt

return {

  ["wanderlost"] = {

        spray = {
          air                = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 1,
          ground             = true,
          underwater         = 1,
          water              = true,
          properties = {
            colormap           = [[
              1 1  1      .01   
              0.25 1 0.25 .01     
              0 0 0 0]],
             dir                = [[0r-0.001r0.001, 1, 0r-0.001r0.001]],
            frontoffset        = 0.1,
            fronttexture       = [[sprayFront]],
            length             = -4,
            sidetexture        = [[spraySide]],
            size               = -4,
            sizegrowth         = 15,
            ttl                = 15,
          },
        },


	particlesa = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 3,
			ground = true,
			water = true,
			properties = {
				airdrag = 0.75,
				alwaysvisible = true,
				colormap = [[
				0 		0    0  0
				1 1 1 0.031225	
				0.25 1 0.25 0.04125	
				0.25 1 0.25 0.03125
				0.25 1 0.25 0.03125
				0.25 1 0.25 0.02125
				0.25 1 0.25 0.0225	
				0 0 0 0.0]],
				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
				
				gravity = [[0, -0.1r0.15r-0.15 , 0]],
				
				numparticles = 1,
				particlelife = 120,
				particlelifespread = 65,
				
				particlesize = 0.15,
				particlesizespread = 1.8,
				
				particlespeed = 0.35,
				particlespeedspread = 0.0004,
				pos = [[0, 0, 0]],
				sizeGrowth	= 0.666,
				sizeMod		= 1.0000000006,
				texture = [[new_dirta]],--
				useairlos = false,
			
		},
	},
	particlesb = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 3,
			ground = true,
			water = true,
			properties = {
				airdrag = 0.75,
				alwaysvisible = true,
				colormap = [[
				0  0  0  0
				1 1  1 0.031225	
				0.25 1 0.25 0.04125	
				0.25 1 0.25 0.03125
				0.25 1 0.25 0.03125
				0.25 1 0.25 0.02125
				0.25 1 0.25 0.0225	
				0 0 0 0.0]],
				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
				
				gravity = [[0, -0.1r0.15r-0.15 , 0]],
				
				numparticles = 1,
				particlelife = 120,
				particlelifespread = 65,
				
				particlesize = 0.15,
				particlesizespread = 1.8,
				
				particlespeed = 0.35,
				particlespeedspread = 0.0004,
				pos = [[0, 0, 0]],
				sizeGrowth	= 0.666,
				sizeMod		= 1.0000000006,
				texture = [[neodirta]],--
				useairlos = false,
			
		},
	},
	particlesc = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 3,
			ground = true,
			water = true,
			properties = {
				airdrag = 0.75,
				alwaysvisible = true,
				colormap = [[
				0 0 0 0
				0.25 1 0.25  0.03125 
				0.25 1 0.25  0.0125
				0.25 1 0.25  0.0
                ]],

				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.5r0.5, 0.5r0.4r-0.5, 0r-0.5r0.5]],
				
				gravity = [[0, -0.1r0.15r-0.15 , 0]],
				
				numparticles = 1,
				particlelife = 30,
				particlelifespread = 65,
				
				particlesize = 0.15,
				particlesizespread = 1.8,
				
				particlespeed = 0.35,
				particlespeedspread = 0.0004,
				pos = [[0r-3.0r3.0, 0, 0r-3.0r3.0]],
				sizeGrowth	= 0.666,
				sizeMod		= 1.0000000006,
				texture = [[fireSparks]],--
				useairlos = false,
			
		},
	}
	}
	
}
