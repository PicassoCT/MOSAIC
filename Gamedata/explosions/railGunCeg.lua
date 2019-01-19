-- gauss_hit_h
-- gauss_tag_l
-- gauss_tag_snipe
-- gauss_ring_l
-- gauss_tag_m
-- gauss_tag_h
-- gauss_ring_h
-- gauss_hit_l
-- gauss_ring_m
-- gauss_hit_m
-- gauss_ring_snipe
-- gauss_hit_l_purple
-- gauss_hit_m_purple

return {
  ["railgunceg"] = {
     tealflash = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.5 1 1 0.08    0 0 0 0.01]],
        size               = 160,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
    trail = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 3,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_RING_H]],
        pos                = [[0, 0, 0]],
      },
    },
	 trail2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 1,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_RING_S]],
        pos                = [[0, 0, 0]],
      },
    },
	
	
	
    },
 ["gauss_ring_s"] = {  
 tealring2 = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
           colormap           = [[0.5 0.9 1 0.0025         0 0 0 0.01]],
	   -- colormap           = [[0 1 0.5 0.03    0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[cRailGun2]],
        length             = 0.15,
        sidetexture        = [[pulseshot]],
	    particlesizespread = 1.2,
		emitrot            = 45,
        emitrotspread      = 12.2,
        size               = 1,
		sizegrowth         = 13,
        sizemod            = 1.0,
        
        ttl                = 23,
      },
    },
 
 
 
 
 
 },

["gauss_ring_h"] = {
    tealring = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
          colormap           = [[0.5 0.9 1 0.0025         0 0 0 0.01]],
	  --  colormap           = [[0 1 0.5 0.03    0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 2,
        fronttexture       = [[cRailGun]],
        length             = 0.15,
		emitrot            = 36,
        emitrotspread      = 18.6,
        sidetexture        = [[pulseshot]],
	    particlesizespread = 1.2,
        size               = 0.5,
		sizemod            = 1.0,
        sizegrowth         = 23,
        ttl                = 23,
      },
    },
	
	
	
	
	
	
	
	
  },  
  


}