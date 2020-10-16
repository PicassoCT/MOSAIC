-- dirt

return {
	["vehsmokepillar"] = {
		poofoo = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 6,
			ground = true,
			water = true,
			properties = {
				airdrag = 0.75,
				alwaysvisible = true,
				colormap = [[0.1 0.2 0.6 0.25	0.3 0.1 0.3 0.22	0.1 0.1 0.3 0.19 0.1 0.1 0.3 0.12]],
				--colormap = [[1 0.4 0.25 1 .02 .02 .02 0.01 .004 .004 .004 0.02		0 0 0 0.01]],
				directional = false,
				
				emitrot = 45,--45
				emitrotspread = 17,--12
				emitvector = [[0r-0.1r0.1, 1r0.3r-0.3, 0r-0.1r0.1]],
				
				gravity = [[0, 0.4r0.15r-0.15 , 0]],
				
				
				
				numparticles = 1,
				particlelife = 65,
				particlelifespread = 102,
				
				particlesize = 1.5,
				particlesizespread = 8,
				
				particlespeed = 0.35,
				particlespeedspread = 0.00004,
				pos = [[0, 26, 0]],
				sizeGrowth	= 0.3,
				sizeMod		= 0.99999977,
				texture = [[smokeSwirls]],
				useairlos = false,
			},
		},
		
		--test
		
		
		
	},
	
}