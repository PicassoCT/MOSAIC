-- factory_explosion

return {
  ["fireignite"] = {
    groundflash = {
      air                = true,
      alwaysvisible      = true,
      circlealpha        = 0.6,
      circlegrowth       = 6,
      flashalpha         = 0.9,
      flashsize          = 256,
      ground             = true,
      ttl                = 20,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.30000001192093,
        [3]  = 0,
      },
    },
   
   
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 0.58,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 15,
        sizegrowth         = 15,
        speed              = [[0, 1 0, 0]],
        texture            = [[uglynovaexplo]],
      },
    },
    pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 15,
        sizegrowth         = 28,
        speed              = [[0, 1 0, 0]],
        texture            = [[flare]],
      },
    },
    
    
  },

}

