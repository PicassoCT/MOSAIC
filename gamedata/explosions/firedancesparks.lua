--lowest part of the fire

return {
  ["firedancesparks"] = {
  
 
   glow2 = {
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
        pos                = [[0,0,0]],
        size               = [[12.9]],
        sizegrowth         = [[1.04]],
        speed              = [[0, 1 0, 0]],
        texture            = [[bubbles]],
      },
    },
 

		
		
 -- sparkredX2 = {
      -- air                = true,
      -- class              = [[CSimpleParticleSystem]],
      -- count              = 1,
      -- ground             = true,
      -- water              = false,
      -- properties = {
        -- airdrag            = 1,
        -- colormap           = [[1 0.5 0.25 .01   1 0.3 0.05 .01		0 0 0 0.01]],
        -- directional        = true,
        -- emitrot            = 0,
        -- emitrotspread      = 40,
        -- emitvector         = [[0,1,0]],
        -- gravity            = [[0, -0.07, 0]],
        -- numparticles       = 1,
        -- particlelife       = 19,
        -- particlelifespread = 11,
        -- particlesize       = 0.5,
        -- particlesizespread = 0,
        -- particlespeed      = 2,
        -- particlespeedspread = 3,
        -- pos                = [[0, 0, 0]],
        -- sizegrowth         = [[0.0 r.35]],
        -- sizemod            = 1.0,
        -- texture            = [[gunshot]],
        -- useairlos          = false,
      -- },
    -- },
		
					
  groundflash = {
      air                = true,
      alwaysvisible      = true,
      circlealpha        = 0.5,
      circlegrowth       = 1,--6
      flashalpha         = 0.01,
      flashsize          = 210,
      ground             = true,
      ttl                = 53,--53
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.2,
        [3]  = 0,
      },
    },
	
				

},

}