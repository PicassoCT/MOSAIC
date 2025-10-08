return {
  ["pistol_casing"] = {
  usedefaultexplosions = false,

  particlesystem = {
    class = [[CSimpleParticleSystem]],
    count = 1,
    air = true,
    ground = true,
    water = true,
    underwater = false,
    properties = {
      airdrag            = 0.92,
      alwaysvisible      = false,
      colormap           = [[0.8  0.8  0.8  0.051   
                              0.8  0.8  0.8  0.051 
                              0.8  0.8  0.8  0.0251    ]], 
      directional        = true,
      emitrot            = 60,
      emitrotspread      = 40,
      emitvector         = [[dir]],
      gravity            = [[0, -0.55, 0]],
      numparticles       = 1,
      particlelife       = 22,
      particlelifespread = 8,
      particlesize       = 1.2,
      particlesizespread = 0.4,
      particlespeed      = 2.8,
      particlespeedspread= 1.2,
      pos                = [[0, 0, 0]],
      sizegrowth         = 0.00,
      sizemod            = 1.0,
      texture            = [[shell]],
      useairlos          = true,
    },
  },
},
}