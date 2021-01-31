-- redlight

return {
  ["redlight"] = {
    glow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 2,
        heatfalloff        = 0.1,
        maxheat            = 1,
        pos                = [[0,0,0]],
        size               = [[0.5 r0.1]],
        sizegrowth         = [[ 1 r1]],
        speed              = [[0, 0.01, 0]],
        texture            = [[laserendred]],
      },
    },
  },

}

