-- bluemuzzle

return {
  ["redmarker"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[   1 0 0 0.01	 1 0 0 0.01	 	]],
        dir                = [[0 0.000001 0]],
        frontoffset        = 0,
        fronttexture       = [[spawnpointtop]],
        length             = 15,
        sidetexture        = [[spawnpointtop]],
        size               = 15,
        sizegrowth         = 0,
        ttl                = 30,
		alwaysvisible      = true,
		useairlos = true,
      },

    },
  },

}

