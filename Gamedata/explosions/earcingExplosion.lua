-- electric_explosion

return {
  ["earcexplosion"] = {


  
    electricarcs1 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.8,
        alwaysvisible      = true,
        colormap           = [[1.0 1.0 1.0 0.04	0.2 0.5 0.9 0.01	0.1 0.5 0.7 0.01]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 0, 0]],
        gravity            = [[0, -0.05, 0]],
        numparticles       = 5,
        particlelife       = 20,
        particlelifespread = 15,
        particlesize       = 5,
        particlesizespread = 5,
        particlespeed      = 5,
        particlespeedspread = 5,
        pos                = [[0, r5r-3, 0]],
        sizegrowth         = 1,
        sizemod            = 1.0,
        texture            = [[lightening]],
        useairlos          = false,
      },
    }
   
   
  

}
}

