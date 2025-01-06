-- dirt

return {	
	["orgyanyl"] = {
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
				1 0.5 0.0 0.01225		
				1 0.5 0.0 0.04125	
				1 0.5 0.0 0.04125
				1 0.5 0.0 0.03125
				1 0.5 0.0 0.0125
				1 0.5 0.0 0.0125	
				0 0 0 0.0]],
				directional = false,
				
				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
				
				gravity = [[0, -0.3r0.15r-0.15 , 0]],
				
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
				1 0.5 0.0 0.01225		
				1 0.5 0.0 0.04125	
				1 0.5 0.0 0.04125
				1 0.5 0.0 0.03125
				1 0.5 0.0 0.0125
				1 0.5 0.0 0.0125	
				0 0 0 0.0]],
				directional = false,
				
				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
				
				gravity = [[0, -0.3r0.15r-0.15 , 0]],
				
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
                1 0.5 0.0 0.03125 
                1 0.5 0.0 0.0125
                1 0.5 0.0 0.0]],
				directional = false,
				
				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.2r0.2, 0.5r0.5r-0.5, 0r-0.2r0.2]],
				
				gravity = [[0, -0.3r0.15r-0.15 , 0]],
				
				numparticles = 1,
				particlelife = 30,
				particlelifespread = 65,
				
				particlesize = 0.015,
				particlesizespread = 1.8,
				
				particlespeed = 0.35,
				particlespeedspread = 0.0004,
				pos = [[0, 0, 0]],
				sizeGrowth	= 0.666,
				sizeMod		= 1.0000000006,
				texture = [[fireSparks]],--
				useairlos = false,
			
		},
	}
	}, 
	
}
