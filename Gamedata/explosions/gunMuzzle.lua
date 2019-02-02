    -- trail_ar2
     
    return {
      ["gunmuzzle"] = {
     fakelight = {
          air                = false,
          class              = [[CSimpleGroundFlash]],
          count              = 1,
          ground             = true,
          water              = false,
          properties = {
            colormap           = [[1 0.4 0.7 1  1 0.6 0.12 1    0 0 0 0.1]],
            size               = [[18 r5]],
            sizegrowth         = [[1 r1]],
            texture            = [[ar2groundflash]],
            ttl                = [[9 r4 r4]],
          },
        },
           
     
        bitmapmuzzleflame = {
          air                = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 1,
          ground             = true,
          underwater         = 1,
          water              = true,
          properties = {
              colormap           = [[1 0.6 0.2 1  1 0.6 0.12 1    0 0 0 0.1]],
            dir                = [[dir]],
            frontoffset        = 0,
            fronttexture       = [[flash1]],
            length             = 3,
            sidetexture        = [[burstside]],
            size               = 3,
            sizegrowth         = 1,
            ttl                = 5,
          },
        },
   
     
    },
    }
