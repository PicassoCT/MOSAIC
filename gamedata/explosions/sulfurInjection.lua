    -- trail_ar2
     
    return {
      ["sulfurinjection"] = {   

       dirtgf = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 3,
      ground             = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
       colormap           = [[0.0 0.0 0.0 0.015 1 0.74 0.06 0.025  0.988 0.72 0.36 0.025    1.0 0.4 0.49 0.025  0.0 0.0 0.0 0.015]],

        directional        = false,
        emitrot            = 0,
        emitrotspread      = 2,
        emitvector         = [[0 0 r0.1r-0.1]],
        gravity            = [[0, 0, 0]],
        numparticles       = 5,
        particlelife       = 150,
        particlelifespread = 400,
        particlesize       = 50,
        particlesizespread = 0.1,
        particlespeed      = 2.7,
    
        
        sizegrowth         = 1.001,
        texture            = [[new_dirta]],
        particlespeedspread = 1.1,
        pos                = [[r-10r10, 1, 100]],
 
        sizemod            = 0.95,
    
    
        useairlos          = false,
      },
      },
  

     
    },
    }
