local function CopyTable(srcTbl, dstTbl)
	assert(dstTbl ~= nil)

	for key, val in pairs(srcTbl) do
		assert(type(key) ~= type({}))

		if (type(val) == type({})) then
			dstTbl[key] = {}

			srcSubTbl = val
			dstSubTbl = dstTbl[key]

			CopyTable(srcSubTbl, dstSubTbl)
		else
			dstTbl[key] = val
		end
	end
end


local rgbSpecMults = {0.2, 0.2, 0.2} -- specular RGB scales
local holoRgbSpecMults = {0.2, 0.2, 0.2} -- specular RGB scales
local copyLightDefs = {
	["MOSAIC"] = {
		--weaponName
		["godrod"  ] = "impactor",
		["javelinrocket"  ] = "rocket",
		["tankcannon"  ] = "cannon",
		["machinegun"  ] = "machinegunsalvo",
		["railgun"  ] = "plasmarail",
		["ssied"  ] = "improvisedexplosivedevice",

		
	},
}

local dynLightDefs = {
	["MOSAIC"] = {
		buildingLightDefs = {
		--[[	["house_western_hologram_casino"] = {
				buildingLightDef = {
					diffuseColors      		= {{0.66, 0.34, 0.025}, {0.34, 0.66,  0.025},  {0.34,   0.025, 0.66 }},
					diffuseColor 			= {0.66, 0.025, 0.34},
					customOffsetUnitIDMs 	=  1.5,
					radius            		= 700.0,
					priority          		= 2 * 10,
					ttl  			  		= 270,
					sinusPulseMs      		= 5000,
					ignoreLOS         		= true,
				},
			},
			["house_western_hologram_buisness"] = {
				buildingLightDef = {
					diffuseColors      		= {{0.66, 0.34, 0.025}, {0.34, 0.66,  0.025},  {0.34,   0.025, 0.66 }},
					diffuseColor 			= {0.66, 0.025, 0.34},
					customOffsetUnitIDMs 	=  1.5,
					radius            		= 700.0,
					timeToLive		  		= 270,
					priority          		= 2 * 10,
					sinusPulseMs      		= 5000,
					ignoreLOS         		= true,
				},
			},
			["house_western_hologram_brothel"] = {
				buildingLightDef = {
					diffuseColors      		= {{0.66, 0.34, 0.025}, {0.77, 0.44,  0.25},  {0.66,   0.25, 0.44 }},
					diffuseColor 			= {0.66, 0.025, 0.34},
					customOffsetUnitIDMs 	=  1.5,
					radius            		= 700.0,
					ttl  			  		= 270,
					priority          		= 2 * 10,
					sinusPulseMs      		= 5000,
					ignoreLOS         		= true,
				},
			},			
			["house_asian_hologram_buisness"] = {
				buildingLightDef = {
					diffuseColors      	= {{0.66, 0.34, 0.025}, {0.77, 0.44,  0.25},  {0.66,   0.25, 0.44 }},
					diffuseColor 		= {0.66, 0.025, 0.34},
					customOffsetUnitIDMs =  1.5,
					radius            	= 700.0,
					ttl  			  	= 270,
					priority          	= 2 * 10,
					sinusPulseMs      	= 5000,
					ignoreLOS         	= true,
				},--]]
			},
		},
		weaponLightDefs = {
			-- Arm & Core Commander (dgun) projectiles
			-- NOTE:
			--   no explosion light defs, because a dgun
			--   projectile triggers a new explosion for
			--   every frame it is alive (which consumes
			--   too many light slots)
			["cannon"] = {
				projectileLightDef = {
					diffuseColor      = {0.66,                   0.34,                   0.025                  },
					specularColor     = {0.66 * rgbSpecMults[1], 0.34 * rgbSpecMults[2], 0.025 * rgbSpecMults[3]},
					radius            = 180.0,
					priority          = 2 * 10,
					ttl               = 1000,
					ignoreLOS         = false,
				},
			},

			-- explodeas/selfdestructas lights for various large units
			["impactor"] = {
				explosionLightDef = {
					diffuseColor      = {1.0,                   1.0,                   1.0                  },
					specularColor     = {1.0 * rgbSpecMults[1], 1.0 * rgbSpecMults[2], 1.0 * rgbSpecMults[3]},
					priority          = 15 * 10,
					radius            = 800.0,
					ttl               = 7 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 250.0,
					ignoreLOS         = false,
				},
			},


			["rocket"] = {
				projectileLightDef = {
					diffuseColor      = {0.7,                  0.4,                   0.4                  },
					specularColor     = {0.7 * rgbSpecMults[1], 0.4 * rgbSpecMults[2], 0.4 * rgbSpecMults[3]},
					priority        = 20 * 10,
					radius          = 330.0,
					ttl             = 100000,
					ignoreLOS       = false,
				},

				explosionLightDef = {
					diffuseColor      = {0.5,                  0.5,                   0.5                  },
					specularColor     = {0.5 * rgbSpecMults[1], 0.5 * rgbSpecMults[2], 0.5 * rgbSpecMults[3]},
					priority          = 20 * 10 + 1,
					radius            = 840.0,
					ttl               = 2.2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 250.0,
				},
			},

			-- Arm Stunner / Core Neutron (small nuke) projectiles
			["plasmarail"] = {
				projectileLightDef = {
					diffuseColor      = {0.7,                  0.4,                   0.4                  },
					specularColor     = {0.7 * rgbSpecMults[1], 0.4 * rgbSpecMults[2], 0.4 * rgbSpecMults[3]},
					priority        = 8 * 10,
					radius          = 250.0,
					ttl             = 1000,
					ignoreLOS       = false,
				},
				explosionLightDef = {
					diffuseColor      = {0,                  0.2,                   1                 },
					specularColor     = {0 * rgbSpecMults[1], 0.2 * rgbSpecMults[2], 1 * rgbSpecMults[3]},
					priority          = 8 * 10 + 1,
					radius            = 250.0,
					ttl               = 9 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 125.0,
				},
			},

			["machinegunsalvo"] = {
				projectileLightDef = {
					diffuseColor    = {1.0,                   0.7,                   0.7                  },
					specularColor   = {1.0 * rgbSpecMults[1], 0.7 * rgbSpecMults[2], 0.7 * rgbSpecMults[3]},
					priority        = 8 * 10,
					radius          = 200.0,
					ttl             = 1000,
					ignoreLOS       = false,
				},
				explosionLightDef = {
					diffuseColor      = {1.0,                   1.0,                   0.7                  },
					specularColor     = {1.0 * rgbSpecMults[1], 1.0 * rgbSpecMults[2], 0.7 * rgbSpecMults[3]},
					priority          = 8 * 10 + 1,
					radius            = 530.0,
					ttl               = 3 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 125.0,
				},
			},

			["improvisedexplosivedevice"] = {
				projectileLightDef = {
					diffuseColor    = {0.8,                   0.6,                   0.0                  },
					specularColor   = {1.9 * rgbSpecMults[1], 0.9 * rgbSpecMults[2], 0.0 * rgbSpecMults[3]},
					priority        = 5 * 10,
					radius          = 105.0,
					ttl             = 1000,
					ignoreLOS       = false,
				},
				explosionLightDef = {
					diffuseColor      = {1.7,                   1.2,                   0.0                  },
					specularColor     = {1.7 * rgbSpecMults[1], 1.2 * rgbSpecMults[2], 0.0 * rgbSpecMults[3]},
					priority          = 2 * 10 + 1,
					radius            = 220.0,
					ttl               = 2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 150.0,
				},
			},

		},
	},
}

for key, value in pairs(dynLightDefs.MOSAIC.buildingLightDefs) do
	local specularColors = {}
	for i=1, #value.buildingLightDef.diffuseColors do
		local color = value.buildingLightDef.diffuseColors[i]
		specularColors[i] = {color[1]*holoRgbSpecMults[1], color[2]*holoRgbSpecMults[2], color[3]*holoRgbSpecMults[3]}
	end
	dynLightDefs.MOSAIC.buildingLightDefs[key].specularColors = specularColors
	dynLightDefs.MOSAIC.buildingLightDefs[key].specularColor = specularColors[1]
end

local modLightDefs = dynLightDefs[Game.gameShortName]
assert(Game.gameShortName == "MOSAIC",Game.gameShortName)
assert(copyLightDefs["MOSAIC"])
assert(copyLightDefs[Game.gameShortName])
local modCopyDefs = copyLightDefs[Game.gameShortName]

-- insert copy-definitions for each light that has one
if (modLightDefs ~= nil and modCopyDefs ~= nil) then
	for dstWeaponDef, srcWeaponDef in pairs(modCopyDefs) do
		modLightDefs.weaponLightDefs[dstWeaponDef] = {}

		srcLightDefTbl = modLightDefs.weaponLightDefs[srcWeaponDef]
		dstLightDefTbl = modLightDefs.weaponLightDefs[dstWeaponDef]

		CopyTable(srcLightDefTbl, dstLightDefTbl)
	end
end

return dynLightDefs

