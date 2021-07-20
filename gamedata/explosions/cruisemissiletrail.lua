-- dirt

return {
  ["cruisemissiletrail"] = {
  
  ashcloud={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[SmokeAshCloud]],
				colormap           = [[
				 1 0.78 0.15 0.5    
         1 0.58 0.15 0.25
         1 0.37 0.15 0.25
				 0.345 0.25 0.27 0.5
				 0.5 0.36 0.36 0.75 
				 0.08 0.08 0.08 0.75
				 0 0 0 0.0001]],

				         

				pos                = [[0 r-42 r42, 26r14, 0 r-42 r42]],
				gravity            = [[0r-0.05r0.05, -0.1 , 0r-0.05r0.05]],
				emitvector         = [[0, s1, 0]],
				 emitrot            = 3,
				emitrotspread      = 25,


				sizeGrowth	= 0.45,
				sizeMod		= 1.000000000001,

		
				airdrag			= 0.55,
				particleLife		=60,
				particleLifeSpread	= 35,
				numParticles		= 4,
				particleSpeed		= 0.09,
				particleSpeedSpread	= 0.12,
				particleSize		= 4.008,
				particleSizeSpread	= 4,

				directional		= true, 
				useAirLos		= true,
				},
	
		},
	},

}

