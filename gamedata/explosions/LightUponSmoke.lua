-- dirt

return {
  ["lightuponsmoke"] = {
  
  ashcloud={	
				air=true,
				class=[[CSimpleParticleSystem]],
				count=1,
				ground=true,
				water=false,
				
				properties={
				
				texture=[[SmokeAshCloud]],
				colormap           = [[0.6 0.2 0.2 0.9		0.5 0.5 0.5 0.6	 0.5 0.5 0.5 0.5		0.5 0.5 0.65 0.75	0.5 0.5 0.55 0.4	 0.5 0.5 0.5 0.35  0 0 0 0.0001]],
				--colormap           = [[1 0.4 0.25 .01     .02 .02 .02 0.01 .004 .004 .004 0.01		0 0 0 0.01]],
			

				pos                = [[0 r-42 r42, 26r14, 0 r-42 r42]],
				gravity            = [[0r-0.05r0.05, 0.9 , 0r-0.05r0.05]],
				emitvector         = [[0, s-1, 0]],
				 emitrot            = 3,
				emitrotspread      = 25,


				sizeGrowth	= 0.45,
				sizeMod		= 1.000000000001,

		
				airdrag			= 0.55,
				particleLife		=95,
				particleLifeSpread	= 16,
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

