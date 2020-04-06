-- redlight

return {
  ["greenlight"] = {
    glow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 5,
        heatfalloff        = 0.1,
        maxheat            = 5,
        pos                = [[0,0,0]],
        size               = [[1 r1]],
        sizegrowth         = [[0.15]],
        speed              = [[0, 0.01, 0]],
        texture            = [[laserendgreen]],
      },
    },
  },

}

