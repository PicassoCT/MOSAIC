-- trail_ar2

return {
  ["AR2Projectile"] = {
  
  fakelight = {
      air                = false,
      class              = [[CSimpleGroundFlash]],
      count              = 0,
      ground             = true,
      water              = false,
      properties = {
        colormap           = [[1 0.4 0.7 1  1 0.6 0.12 1    0 0 0 0.1]],
        size               = [[8 r-5]],
        sizegrowth         = [[2 r-3]],
        texture            = [[ar2groundflash]],
        ttl                = [[9 r4 r-4]],
      },
    },
  
  
  
  
  
  

               
       
    Flash = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[0.5 0.9 1 0.0025         0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 5,
        particlelife       = 6,
        particlelifespread = 0,
        particlesize       = 0.5,
        particlesizespread = 1,
        particlespeed      = 0.05,
        particlespeedspread = 0.05,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.6 r.35]],
        sizemod            = 1.0,
        texture            = [[flashside3]],
        useairlos          = false,
      },
    },
            Flash2 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = false,
      properties = {
        airdrag            = 1,
        colormap           = [[1 0.8 0.3 0.0025         0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 5,
        particlelife       = 6,
        particlelifespread = 0,
        particlesize       = 0.5,
        particlesizespread = 1,
        particlespeed      = 0.1,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[0.6 r.35]],
        sizemod            = 1.0,
        texture            = [[flashside3]],
        useairlos          = false,
      },
    },
 
       
 
       
  },
 
}