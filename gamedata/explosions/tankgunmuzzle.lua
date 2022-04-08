    -- trail_ar2
     
    return {
      ["tankgunmuzzle"] = {

           
     
        bitmapmuzzleflame = {
          air                = true,
          ground             = true,
          underwater         = false,
          water              = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 1,
          
          properties = {
              colormap           = [[1 0.6 0.2 0.025  1 0.6 0.12 0.025    0 0 0 0.025]],
            dir                = [[dir]],
            frontoffset        = 0,
            fronttexture       = [[flash1]],
            length             = 10,
            sidetexture        = [[burstside]],
            size               = 8,
            sizegrowth         = 8,
            ttl                = 17,
          },
        },
          groundflash = {
          air                = true,
          alwaysvisible      = true,
          circlealpha        = 0.6,
          circlegrowth       = 6,
          flashalpha         = 0.9,
          flashsize          = 220,
          ground             = true,
          ttl                = 13,
          water              = true,
          color = {
            [1]  = 1,
            [2]  = 0.6,
            [3]  = 0.2
            ,
          },
        },
   
     
    },
    }
