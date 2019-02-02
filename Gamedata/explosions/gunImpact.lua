-- trail_ar2

return {
  ["gunimpact"] = {
   pop2 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 2,
        maxheat            = 15,
        pos                = [[r-3 r3, 5, r-3 r3]],
        size               = 0.2,
        sizegrowth         = 4,
        speed              = [[0, 1, 0]],
        texture            = [[groundflash]],
      },
    },
  
    
  
	
      fakelight = {
      air                = false,
      class              = [[CSimpleGroundFlash]],
      count              = 4,
      ground             = true,
      water              = false,
      properties = {
        colormap           = [[1 0.5 0.2  1     0.8 0.3 0.1 1    0 0 0 0.1]],
        size               = [[8 r-5]],
        sizegrowth         = [[2 r-3]],
        texture            = [[ar2groundflash]],
        ttl                = [[12 r4 r-4]],
      },
    },
  
  }
  }