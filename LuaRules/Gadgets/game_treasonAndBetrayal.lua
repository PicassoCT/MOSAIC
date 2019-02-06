function gadget:GetInfo()
	return {
		name = "Civilian City and Inhabitants Gadget",
		desc = "Coordinates Traffic ",
		author = "Picasso",
		date = "3rd of May 2010",
		license = "GPL3",
		layer = 3,
		version = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	
	local spGetPosition = Spring.GetUnitPosition
	UnitDefNames = getUnitDefNames(UnitDefs)
	GameConfig = getGameConfig()
	CivilianTypeTable, CivilianUnitDefsT = getCivilianTypeTable(UnitDefs)
	assert(CivilianTypeTable["civilian"])
	assert(CivilianTypeTable["truck"])
	assert(CivilianUnitDefsT[CivilianTypeTable["truck"]] )
	MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
	InterrogateableType = getInterrogateAbleTypeTable(UnitDefs)
	reruitmentDefID = UnitDefNames["recruitcivilians"].id

	-- GG.CivilianTable = {} --[id ] ={ defID, startNodeID }
	-- GG.UnitArrivedAtTarget = {} --[id] = true UnitID -- Units report back once they reach this target
	-- GG.BuildingTable= {} --[BuildingUnitID] = {routeID, stationIndex}
	
	
	gaiaTeamID = Spring.GetGaiaTeamID()
	
   function gadget:UnitCreated(unitid, unitdefid, unitTeam, father)
		assert(unitTeam)
			assert(father)
   
		if InterrogateableType[unitdefid] then
			 registerChild( unitTeam, father, unitid)
		end
	end
	
	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
		if InterrogateableType[unitdefid] then
			 removeUnit( unitTeam, father, unitid)
		end
	end
	
	
	function gadget:Initialize()
		
		if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end
		initalizeInheritanceManagement()
	end
	
end