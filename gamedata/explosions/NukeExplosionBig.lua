local scaleSpeed = 0.25

return {
	["nuclearexplosionbig"] = {
		
		-- Flash of bright light
			flash = {
			air = true,
			class = [[CBitmapMuzzleFlame]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				colormap = [[1 1 1 0.5  1 0.8 0.6 0.3  0.8 0.4 0.2 0.1  0 0 0 0]],
				dir = [[0, 1, 0]],
				frontoffset = 0,
				fronttexture = [[explo]],
				length = 20,
				sidetexture = [[explo]],
				size = 100,
				sizegrowth = 0,
				ttl = 5,
			},
		},
		
		-- The main fiery mushroom cloud
		mushroomcloud = {
			air = true,
			class = [[CBitmapMuzzleFlame]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				colormap = [[1 0.8 0.4 0.04  0.8 0.4 0.1 0.03  0.5 0.2 0.05 0.02  0.1 0.1 0.1 0.01  0 0 0 0]],
				dir = [[0, 1, 0]],
				frontoffset = 1,
				fronttexture = [[explosion]],
				length = 50,
				sidetexture = [[smokeSwirls]],
				size = 30,
				sizegrowth = 1,
				ttl = 50,
			},
		},
		
		-- Expanding shockwave
		shockwave = {
			air = true,
			class = [[CBitmapMuzzleFlame]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				colormap = [[1 1 1 0.1  0.7 0.7 0.7 0.05  0.4 0.4 0.4 0.02  0 0 0 0]],
				dir = [[0, 1, 0]],
				frontoffset = 0,
				fronttexture = [[nuke]],
				length = 100,
				sidetexture = [[bigexplo]],
				size = 40,

				sizegrowth = 25,
				ttl = 30,
			},
		},

			-- Expanding glowing energy sphere
		spherea = {
			air = true,
			class = [[CSpherePartSpawner]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				alpha = 0.6,                   -- Opacity of the sphere
				alwaysvisible = true,          -- Sphere is always visible
				color = [[1,0.75,0]],           -- Glowing orange sphere
				expansionspeed = 15,           -- Speed at which the sphere grows
				ttl = 35,                      -- How long the sphere lasts
			},
			},
		sphereb = {
			air = true,
			class = [[CSpherePartSpawner]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				alpha = 0.75,                   -- Opacity of the sphere
				alwaysvisible = true,          -- Sphere is always visible
				color = [[1,0.8,0]],           -- Glowing orange sphere
				expansionspeed = 14,           -- Speed at which the sphere grows
				ttl = 33,                      -- How long the sphere lasts
			},
		},	
		spherec = {
			air = true,
			class = [[CSpherePartSpawner]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				alpha = 0.85,                   -- Opacity of the sphere
				alwaysvisible = true,          -- Sphere is always visible
				color = [[1,0.9,0]],           -- Glowing orange sphere
				expansionspeed = 13,           -- Speed at which the sphere grows
				ttl = 30,                      -- How long the sphere lasts
			},
		},	

		sphered = {
			air = true,
			class = [[CSpherePartSpawner]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				alpha = 0.99,                   -- Opacity of the sphere
				alwaysvisible = true,          -- Sphere is always visible
				color = [[1,1,0]],           -- Glowing orange sphere
				expansionspeed = 10,           -- Speed at which the sphere grows
				ttl = 30,                      -- How long the sphere lasts
			},
		},
		
		-- Smoke trail after the explosion
		smokecloud = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				airdrag = 0.9,
				colormap = [[0.1 0.1 0.1 0.8  0.2 0.2 0.2 0.7  0.1 0.1 0.1 0.5  0 0 0 0]],
				directional = false,
				emitrot = 90,
				emitrotspread = 30,
				emitvector = [[0, 1, 0]],
				gravity = [[0, 0.1, 0]],
				numparticles = 20,
				particlelife = 60,
				particlelifespread = 20,
				particlesize = 10,
				particlesizespread = 5,
				particlespeed = 5,
				particlespeedspread = 2,
				pos = [[0, 0, 0]],
				sizegrowth = 2,
				sizemod = 1,
				texture = [[smoke]],
			},
		},
		
		-- Fallout particles
		fallout = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 1,
			ground = true,
			water = true,
			underwater = true,
			properties = {
				airdrag = 0.8,
				colormap = [[0.7 0.6 0.5 0.3  0.5 0.4 0.3 0.2  0.3 0.2 0.1 0.1  0 0 0 0]],
				directional = false,
				emitrot = 70,
				emitrotspread = 20,
				emitvector = [[0, 1, 0]],
				gravity = [[0, -0.1, 0]],
				numparticles = 10,
				particlelife = 100,
				particlelifespread = 50,
				particlesize = 3,
				particlesizespread = 2,
				particlespeed = 1,
				particlespeedspread = 0.5,
				pos = [[0, 0, 0]],
				sizegrowth = 1,
				sizemod = 1,
				texture = [[dirt]],
			},
		},
		
	},
}
