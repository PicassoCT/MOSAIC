
local house_asian = Building:New{
	corpse					= "",
	maxDamage        	= 3500,
	mass           		= 500,
	buildCostEnergy    	= 5,
	buildCostMetal    	= 5,
	explodeAs				= "none",
	name = "Asian Style Housing",
	description = "houses civilians",
	buildPic = "house.png",
	iconType = "house",
	Builder					= true,
	levelground				= true,
	FootprintX = 8,
	FootprintZ = 8,
	script 				= "house_asian_script.lua",
	objectName       	= "house_asian.dae",


	isFirePlatform  = true, 	
		
	YardMap =  [[yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy
				yyyyyyyy]]	,  
	

	customparams = {	
		throwsShadow = true,
		normaltex = "unittextures/house_asian_normal.dds",
		helptext			= "Civilian Building",
		baseclass			= "Building", -- TODO: hacks
    },
	
	buildoptions = 
	{
	"civilian_arab0"
	},
	usepiececollisionvolumes = false,
	collisionVolumeType = "box",
	collisionvolumescales = "130 60 130",
	collisionVolumeOffsets  = {0.0, 30.0,  0.0},
	category = [[BUILDING RAIDABLE]],

}

local definitions = {house_asian0 = house_asian:New()}
-- Keep house_asian0 as the semantic spawn choice and authoring/debug model.
-- These inherit every gameplay field; only the model and style metadata differ.
for a = 1, 4 do
    for b = a, 4 do
        local name = "house_asian_split_" .. a .. "_" .. b
        definitions[name] = house_asian:New{
            objectName = name .. ".dae",
            customparams = {
                house_asian_base = "house_asian0",
                house_asian_style_a = a,
                house_asian_style_b = b,
            },
        }
    end
end
return lowerkeys(definitions)
