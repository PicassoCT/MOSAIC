    return {
      ["iconkill"] = {
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
            colormap           = [[  0.2 0.6 1 .01   1 0.7 0.25 .01         0 0 0 0]],
            dir                = [[dir]],
            frontoffset        = 0,
            fronttexture       = [[flash1]],
            length             = 3,
            sidetexture        = [[lightray]],
            size               = 3,
            sizegrowth         = 1,
            ttl                = 5,
          },
        },
   
     
    },
    }
