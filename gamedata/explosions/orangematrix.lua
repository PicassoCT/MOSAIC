return {
    ["orangematrix"] = {
        pixelSpawner = {
            air = true,
            class = [[CBitmapParticleSpawner]],
            count = 10, -- Number of particles per frame
            ground = true,
            water = false,
            properties = {
                alwaysvisible = true,
                useairlos = true,
                dir = [[0, 1, 0]], -- Upward direction
                emitrot = 0,
                emitrotspread = 360, -- Spread to create some randomness
                emitvector = [[0, 1, 0]], -- Emit straight upwards
                gravity = [[0, 0, 0]], -- No gravity
                particlelife = 20, -- Time each particle lasts
                particlelifespread = 5, -- Variability in particle lifespan
                particlesize = 2, -- Size of the "pixels"
                particlesizespread = 1, -- Variability in size
                particlespeed = 3, -- Speed of particles
                particlespeedspread = 1, -- Variability in speed
                pos = [[0, 0, 0]], -- Start at unit's position
                sizegrowth = 0, -- No size growth
                sizemod = 1, -- Size does not diminish over life
                texture = [[spawnpointtop]], -- Texture used (can replace with a pixel-like texture)
                colormap = [[1 0.5 0 0.5   1 0.3 0 0.3   0.5 0.1 0 0.1   0 0 0 0]], -- Orange gradient fading out
            },
        },
    },
}