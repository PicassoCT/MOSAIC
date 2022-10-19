return {
  ["greystripe"] = {
  
	   alwaysvisible      = true,
	  usedefaultexplosions = false,

	outberbolt = {
    

      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = false,
      water              = true,
      properties = {
        alwaysvisible      = true,
        colormap           = [[0.9 0.9 0.9 0.01  	0.6 0.6 0.6 0.01 	0.3 0.3 0.3 0.01   0.1 0.1 0.1 0.01 	]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[empty]],
        length             = -12,
        sidetexture        = [[citdronegrad]],
        size               = -3,
        sizegrowth         = 0.18,
        ttl                = 24,
      }
    },
	
	}
}
