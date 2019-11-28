-- bluemuzzle

return {
  ["policelight"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[  0 0 1 0.01		1 0 1 0.01  	1 0 1 0.01		0 0 0 0.01]],
        dir                = [[0 1 0]],
        frontoffset        = 0,
        fronttexture       = [[shotgunflare]],
        length             = 15,
        sidetexture        = [[shotgunflare]],
        size               = 15,
        sizegrowth         = 1,
        ttl                = 30,
      },
    },
  },

}

