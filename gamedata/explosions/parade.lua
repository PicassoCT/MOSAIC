-- Small paper objects emitted from building balconies/roof edges.
-- The director supplies an outward toss for confetti/cranes, and map-wind
-- acceleration for petals. Banknotes always fall straight down.
-- These are ordinary LOS-respecting CEG particles, without lights or sub-effects.
local function paper(texture, count, size, spread, life, color)
    return {
        air = true,
        ground = true,
        water = true,
        class = [[CSimpleParticleSystem]],
        count = 1,
        properties = {
            airdrag = 0.985,
            alwaysvisible = false,
            useairlos = false,
            colormap = color,
            directional = false,
            emitrot = 15,
            emitrotspread = 30,
            emitvector = [[dir]],
            gravity = [[0, -0.05, 0]],
            numparticles = count,
            particlelife = life,
            particlelifespread = 45,
            particlesize = size,
            particlesizespread = spread,
            particlespeed = 1.6,
            particlespeedspread = 1.2,
            pos = [[-5 r10, 0 r5, -5 r10]],
            sizegrowth = 0,
            sizemod = 1,
            texture = texture,
        },
    }
end

local effects = {
    parade_confetti = {
        red = paper([[parade_confetti]], 6, 1.4, 0.7, 180,
            [[1 0.25 0.4 1  1 0.25 0.4 1  0.6 0.12 0.2 0]]),
        gold = paper([[parade_confetti]], 6, 1.4, 0.7, 180,
            [[1 0.83 0.25 1  1 0.83 0.25 1  0.6 0.4 0.12 0]]),
        cyan = paper([[parade_confetti]], 6, 1.4, 0.7, 180,
            [[0.25 0.9 1 1  0.25 0.9 1 1  0.12 0.5 0.6 0]]),
    },
    parade_origami = {
        cranes = paper([[parade_origami]], 6, 3.4, 1.0, 225,
            [[1 1 1 1  1 1 1 1  0.7 0.8 1 0]]),
    },
    parade_petals = {
        petals = paper([[parade_petal]], 12, 1.8, 0.8, 360,
            [[1 1 1 1  1 1 1 1  1 0.6 0.8 0]]),
    },
    parade_inflationmoney = {
        notes = paper([[parade_banknote]], 8, 2.8, 0.8, 210,
            [[1 1 1 1  1 1 1 1  0.6 0.8 0.6 0]]),
    },
}

-- Retain the petal launch cone and speed variation, but aim it downward.
-- CEG's supported "dir" vector is sampled as gravity when the burst spawns;
-- the director supplies horizontal map-wind acceleration and negative Y.
local petals = effects.parade_petals.petals.properties
petals.emitvector = [[0, -1, 0]]
petals.gravity = [[dir]]

-- A zero-width downward cone forbids both upward and sideways note travel.
local notes = effects.parade_inflationmoney.notes.properties
notes.emitvector = [[0, -1, 0]]
notes.emitrot = 0
notes.emitrotspread = 0

return effects
