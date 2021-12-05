-- blood_spray

return {
  ["bloodspray"] = {


    bitmapmuzzleflame = {
          air                = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 5,
          ground             = true,
          underwater         = 1,
          water              = true,
          properties = {
           colormap           = [[0.7 0.1 0.1 .39   0.8 0.1 0.05 .39		0 0 0 0.0001  ]],
             dir                = [[-1 r2, -1 r2, -1 r2]],
            frontoffset        = 0,
            fronttexture       = [[bloodsplat]],--redexplo
            length             = 7,
            sidetexture        = [[bloodsplat]],
            size               = 7,
            sizegrowth         = 1,
            ttl                = 20,
          },
        },
	
	
	
  },

}
