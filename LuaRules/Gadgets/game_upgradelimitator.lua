function gadget:GetInfo()
    return {
        name = "Safehouse Building Limitator",
        desc = "",
        author = "",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

--GG.UnitsToSpawn:PushCreateUnit(name,x,y,z,dir,teamID)

if (not gadgetHandler:IsSyncedCode()) then
    return
end

	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	
	safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)
	areaDenyMapResolution = 16
	areaDenyMap= {}
local houseDefID = UnitDefs["house"].id
	
function setAroundPoint(x,z, valueToSet, halfSize)
	for rx= math.max(1, x - (halfSize)), math.min(Game.mapSizeX/ areaDenyMapResolution -1, x + halfSize)do
		for rz= math.max(1, z -(halfSize)), math.min(Game.mapSizeZ/ areaDenyMapResolution -1, z + halfSize)do
			Spring.SetSquareBuildingMask(x, z , valueToSet)
		end
	end
end
	
function gadget:Initialize()
	mapSizeX, mapSizeZ	=Game.mapSizeX/areaDenyMapResolution, Game.mapSizeZ/ areaDenyMapResolution
	areaDenyMap = makeTable(0,mapSizeX,mapSizeZ)
	Spring.Echo(mapSizeX,mapSizeZ)
	for x=1, mapSizeX do
		for z=1, mapSizeZ do
			if x > 0 and z > 0 and x < Game.mapSizeX/areaDenyMapResolution and z < Game.mapSizeZ/areaDenyMapResolution then
				Spring.SetSquareBuildingMask(x , z, 0)
			end
		end
	end
end
--https://github.com/ZeroK-RTS/Zero-K/blob/ab984528d14777c188a6161a68d6e1aa201e9a8e/LuaRules/Gadgets/mex_placement.lua#L125
--https://github.com/ZeroK-RTS/Zero-K/blob/f373e6a3c78e7819709aa7a1cd1d4c2500262663/units/staticmex.lua#L10
--https://springrts.com/phpbb/viewtopic.php?f=23&t=35994&p=581356&hilit=SetSquareBuildingMask#p581356

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
	if houseDefID == unitDefID then
	x,y,z = Spring.GetUnitPosition(unitID)
		if x then			
			setAroundPoint(x * 0.0625, z * 0.0625, 0, 2)
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	if houseDefID == unitDefID then
	x,y,z = Spring.GetUnitPosition(unitID)
	Spring.Echo("gadget:UnitCreated", x, y, z)
		if x then
			setAroundPoint(x * 0.0625, z * 0.0625, 8, 2)			
		end
	end
end

