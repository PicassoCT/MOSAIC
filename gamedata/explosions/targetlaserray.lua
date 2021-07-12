return {
  ["targetlaserray"] = {
  
	   alwaysvisible      = true,
	  usedefaultexplosions = false,

	outberbolt = {
    

      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[0.7 0.0 0.0 0.01  
        1 0 0 0.01 
        1 0 0 0.01  
        1 0 0 0.01 	 
        1 0 0 0.01 	
        0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[empty]],
        length             = -128,
        sidetexture        = [[TouchGround]],
        size               = -6,
        sizegrowth         = 0.18,
        ttl                = 24,
      }
    },
	
	}
}
