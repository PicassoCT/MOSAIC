--lowest part of the fire

return {
  ["icbmshine"] = {
     alwaysvisible =  true,
    shineicbm = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
     alwaysvisible =  true,
      properties = {
        colormap           = [[0.9 0.2 0.0 0.5   1.0 0.3 0 0.01]],
        size               = 144,
        sizegrowth         = 0.012,
        texture            = [[groundflash]],
        ttl                = 47,
      },
    },    

    shrinkicbm = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
     alwaysvisible =  true,
      properties = {
        colormap           = [[1.0 0.3 0 0.0 1.0 0.3 0 0.0 0.9 0.2 0.0 0.5   1.0 0.3 0 0.01]],
        size               = 144,
        sizegrowth         = -0.012,
        texture            = [[groundflash]],
        ttl                = 88,
      },
    },
}
}
