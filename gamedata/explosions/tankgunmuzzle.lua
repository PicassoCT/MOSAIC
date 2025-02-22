    -- trail_ar2
     
    return {
      ["tankgunmuzzle"] = { 

    dirta = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      properties = {
        airdrag            = 0.7,
        alwaysvisible      = true,
        colormap           = [[0.1 0.1 0.1 0.95 0.5 0.5 0.5 0.95  0 0 0 0.0]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 8,
        particlelife       = 45,
        particlelifespread = 90,
        particlesize       = 15,
        particlesizespread = 5,
        particlespeed      = 1,
        particlespeedspread = 10,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[dirt]],
        useairlos          = false,
      },
    },
    dirtg = {
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.7,
        alwaysvisible      = true,
        colormap           = [[0.1 0.1 0.1 0.65   0.5 0.4 0.3 0.75    0 0 0 0.0]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 10,
        particlelife       = 45,
        particlelifespread = 230,
        particlesize       = 15,
        particlesizespread = 5,
        particlespeed      = 1,
        particlespeedspread = 10,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[dirt]],
        useairlos          = false,
      },
    },
    dirtw1 = {
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      water              = true,
      properties = {
        airdrag            = 0.9,
        alwaysvisible      = true,
        colormap           = [[0.9 0.9 0.9 0.95 0.5 0.5 0.9 0.0]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.2, 0]],
        numparticles       = 18,
        particlelife       = 45,
        particlelifespread = 30,
        particlesize       = 10,
        particlesizespread = 5,
        particlespeed      = 1,
        particlespeedspread = 10,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[randdots]],
        useairlos          = false,
      },
    },
    dirtw2 = {
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      water              = true,
      properties = {
        airdrag            = 0.7,
        alwaysvisible      = true,
        colormap           = [[1.0 1.0 1.0 0.75 0.5 0.5 0.8 0.0]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 5,
        particlelife       = 35,
        particlelifespread = 130,
        particlesize       = 15,
        particlesizespread = 5,
        particlespeed      = 1,
        particlespeedspread = 10,
        pos                = [[r-1 r1, 1, r-1 r1]],
        sizegrowth         = 1.2,
        sizemod            = 1.0,
        texture            = [[dirt]],
        useairlos          = false,
      },
    },
    
     
        bitmapmuzzleflame = {
          air                = true,
          ground             = true,
          underwater         = false,
          water              = true,
          class              = [[CBitmapMuzzleFlame]],
          count              = 1,
          
          properties = {
              colormap           = [[1 0.6 0.2 0.025  1 0.6 0.12 0.025    0 0 0 0.025]],
            dir                = [[dir]],
            frontoffset        = 0,
            fronttexture       = [[flash1]],
            length             = 10,
            sidetexture        = [[burstside]],
            size               = 8,
            sizegrowth         = 8,
            ttl                = 17,
          },
        }
  
   
     
    },
    }
