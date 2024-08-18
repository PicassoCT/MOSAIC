--lowest part of the fire

return {
    ["firedancesparks"] = {
        glow2 = {
            air = true,
            class = [[heatcloud]],
            count = 1,
            ground = true,
            water = true,
            properties = {
                alwaysvisible = true,
                heat = 3,
                heatfalloff = 1.0,
                maxheat = 3,
                pos = [[0,0,0]],
                size = [[12.9]],
                sizegrowth = [[1.04]],
                speed = [[0, 1 0, 0]],
                texture = [[bubbles]]
            }
        },
        groundflash = {
            air = true,
            alwaysvisible = true,
            circlealpha = 0.5,
            circlegrowth = 1,
             --6
            flashalpha = 0.01,
            flashsize = 210,
            ground = true,
            ttl = 53,
             --53
            water = true,
            color = {
                [1] = 1,
                [2] = 0.2,
                [3] = 0
            }
        }
    }
}
