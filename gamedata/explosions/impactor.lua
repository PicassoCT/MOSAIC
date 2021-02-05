return {
  ["impactor"] = {
  
     alwaysvisible      = true,
    usedefaultexplosions = false,

  outberbolt = {
    

      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      alwaysvisible = true,
      properties = {
        colormap           = [[
        0.9 0.9 0.42  0.01 
        0.9 0.49 0.21 0.01  
        0.9 0.32 0.05 0.01 
        1.0 0.16 0.14 0.01   
        0.6 0 0.0 0.01    
        0.6 0 0.0 0.01   
        0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[empty]],
        length             = -32,
        sidetexture        = [[citdronegrad]],
        size               = -6,
        sizegrowth         = 0.18,
        ttl                = 24,
      }
    },
  
  }
}
