--statue spawn gadget

function gadget:GetInfo()
	return {
		name = "Satellites Movement Gadget",
		desc = "Collects Engagment Data and Displays it at exit of person",
		author = "pica",
		date = "Anno Domini 2018",
		license = "Comrade Stallmans License",
		layer = 109,
		version = 1,
		enabled = true,
		hidden = true
	}
end

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear
if (gadgetHandler:IsSyncedCode()) then

	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	
	SatelliteTypes = getSatteliteTypes(UnitDef)
	SatelliteTypesSpeedTable = getSatelliteTypesSpeedTable(UnitDef)
	
	Satellites ={}
	function gadget:UnitDestroyed(unitID, unitDefID)
		if Satellites[unitID] then
			Satellites[unitID] = nil
		end
	
	end

	
	function gadget:UnitCreated(unitID, unitDefID)
		if SatelliteTypes[unitDefID] then
			Satellites[unitID] = unitDefID
		end		
	end
	
	local mapSizeX = Game.mapSizeX
	local mapSizeZ = Game.mapSizeZ
	
	function circularClamp(x,y,z)
		if (x >= mapSizeX) then x = 1 end
		if (z >= mapSizeZ) then z = 1 end
		return x,y,z
	end
	
	function gadget:GameFrame(n)
		for id, utype in pairs(Satellites) do
			x,y,z = spGetUnitPosition(id)
			x,y,z= circularClamp(x,y,z)
			Spring.SetUnitPosition(id,x + SatelliteTypesSpeedTable[utype] ,y,z )
		end
	end
end
