return {
  ["teargasexplode"] = {
  
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
        alwaysvisible = true,
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
        alwaysvisible = true,
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
        size = 95,
        sizegrowth = -0.5000000005,
        ttl = 300,
      },     
    },      
    dirtw1 = {
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      water              = true,
      properties = {
        airdrag            = 0.9,
        alwaysvisible      = true,
        colormap           = [[0.9 0.9 0.9 1.0	0.5 0.5 0.9 0.0]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.2, 0]],
        numparticles       = 28,
        particlelife       = 25,
        particlelifespread = 10,
        particlesize       = 10,
        particlesizespread = 5,
        particlespeed      = 1,
        particlespeedspread = 20,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[fireSparks]],
        useairlos          = true,
      },
    },
    dirtw2 = {
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      water              = true,
      properties = {
        airdrag            = 0.7,
        alwaysvisible      = true,
        colormap           = [[1.0 1.0 1.0 1.0	0.5 0.5 0.8 0.0]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 10,
        particlelife       = 15,
        particlelifespread = 10,
        particlesize       = 35,
        particlesizespread = 5,
        particlespeed      = 10,
        particlespeedspread = 10,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[dirt]],
        useairlos          = true,
      },
    },
    flare = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.8,
        alwaysvisible      = true,
        colormap           = [[1 1 1 0.01	0.9 0.8 0.7 0.04	0.9 0.5 0.2 0.01	0.5 0.1 0.1 0.01]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.01, 0]],
        numparticles       = 8,
        particlelife       = 14,
        particlelifespread = 0,
        particlesize       = 70,
        particlesizespread = 0,
        particlespeed      = 10,
        particlespeedspread = 5,
        pos                = [[0, 2, 0]],
        sizegrowth         = 1,
        sizemod            = 1.0,
        texture            = [[flashside1]],
        useairlos          = false,
      },
    },
    groundflash = {
      air                = true,
      alwaysvisible      = true,
      circlealpha        = 0.5,
      circlegrowth       = 8,
      flashalpha         = 0.9,
      flashsize          = 150,
      ground             = true,
      ttl                = 17,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.5,
        [3]  = 0.20000000298023,
      },
    },
    pop1 = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 1.4,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 5,
        sizegrowth         = 24,
        speed              = [[0, 1 0, 0]],
        texture            = [[redexplo]],
      },
    },
    whiteglow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 1.1,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 10,
        sizegrowth         = 25,
        speed              = [[0, 1 0, 0]],
        texture            = [[flare]],
      },
    }
  }

}