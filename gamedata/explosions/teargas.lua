return {
  ["teargas"] = {  
    teargas = {      
      air = true,
      class = [[CBitmapMuzzleFlame]],
      count = 1,
      ground = true,
      underwater = true,
      water = true,
      properties = {
        alwaysVisible = true,
        colormap = [[
        0 0 0 0.0
        0.9 0.9 0.9 0.1125  
        0.9 0.9 0.9 0.1125  
        0.9 0.9 0.9 0.1125  
        0.9 0.9 0.9 0.1125
        0.9 0.9 0.9 0.1125  
        0.9 0.9 0.9 0.1125  
        0.9 0.9 0.9 0.1125
        0 0 0 0.0]],
        dir = [[0r-0.0125r0.0125,0.75r0.1,0r-0.125r0.125]],
        pos   = [[r-1 r1, 10, r-1 r1]],
        frontoffset =0,
        fronttexture = [[new_dirtb]],
        length = 78,
        sidetexture = [[empty]],
        size = 110,
        sizegrowth = 1.125000000005,
        ttl = 300,
      },     
    },
    fogGrowth = {
      
      
      air = true,
      class = [[CBitmapMuzzleFlame]],
      count = 1,
      ground = true,
      underwater = true,
      water = true,
      properties = {
        alwaysVisible = true,
        colormap = [[
        0.9 0.9 0.9 0.01225 
        0.9 0.9 0.9 0.0625  
        0.9 0.9 0.9 0.125 
        0.9 0.9 0.9 0.1253  
        0.9 0.9 0.9 0.1255  
        0.9 0.9 0.9 0.1258  
        0.9 0.9 0.9 0.1255  
        0.9 0.9 0.9 0.1253  
        0.9 0.9 0.9 0.125   
        0 0 0 0.0]],
        dir = [[0r-0.0125r0.0125,0.75r0.1,0r-0.125r0.125]],
        pos   = [[r-1 r1, 10, r-1 r1]],
        frontoffset = -0.00065,
        fronttexture = [[new_dirtb]],
        length = 17,
        sidetexture = [[empty]],
        size = 40,
        sizegrowth = 1.000000005,
        ttl = 240,
      },     
    },    
    fogShrink = {
      air = true,
      class = [[CBitmapMuzzleFlame]],
      count = 1,
      ground = true,
      underwater = true,
      water = true,
      properties = {
        alwaysVisible = true,
        colormap = [[
        0 0 0 0.0 
        0.9 0.9 0.9 0.1225  
        0.9 0.9 0.9 0.1125
        0.9 0.9 0.9 0.1725  
        0.9 0.9 0.9 0.1125  
        0.9 0.9 0.9 0.1125  
        0 0 0 0.0]],
        dir = [[0r-0.0125r0.0125,0.75r0.1,0r-0.125r0.125]],
        pos   = [[r-1 r1, 10, r-1 r1]],
        frontoffset =0,
        fronttexture = [[new_dirtb]],
        length = 75,
        sidetexture = [[empty]],
        size = 250,
        sizegrowth = -0.5000000005,
        ttl = 30,
      },     
    }, 
risingcloud = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.75,
        alwaysvisible      = true,       
        colormap           = [[0 0 0 0.0 
                              0.1 0.1 0.1 0.80 
                              0.1 0.1 0.1 0.60 
                              0.9 0.9 0.9 0.2225 
                              0 0 0 0.0 ]],
        directional        = false,   
        emitrot            = 45,--45
        emitrotspread      = 12,--12
        emitvector         = [[0, -0.08, 0]],      
        gravity            = [[0, 0.08r0.01r-0.01, 0]],   

        numparticles       = 2,
        particlelife       = 30*5,
        particlelifespread = 30*10,
    
        particlesize       = 15,
        particlesizespread = 10,
    
        particlespeed      =  0.005,
        particlespeedspread = 0.04,
        pos                = [[0 r-13 r13, 26, 0 r-13 r13]],
        sizeGrowth  = 0.3,
        sizeMod   = 1,
        texture            = [[GenericSmokeCloud]],
        useairlos          = false,
        },
    },    
  }
  }
