function gadget:GetInfo()
	return {
		name = "Treason and Betrayal Gadget",
		desc = " who betrays whom, in the nth layer",
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

	MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
	InterrogateableType = getInterrogateAbleTypeTable(UnitDefs)
	reruitmentDefID = UnitDefNames["recruitcivilian"].id


	
	gaiaTeamID = Spring.GetGaiaTeamID()
	
   function gadget:UnitCreated(unitid, unitdefid, unitTeam, father)
	
		if InterrogateableType[unitdefid] then
		-- Spring.Echo("UnitCreated of InterrogateableType")
			if father  then		
				registerChild( unitTeam, father, unitid)		
			else
				registerFather( unitTeam, unitid)
			end
			-- Spring.Echo("UnitCreated Registered InterrogateableType")
		end
	end
	
	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
		if InterrogateableType[unitDefID] then
			 removeUnit( teamID, unitID)
		end
	end
	
	
	function gadget:Initialize()
		
		if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end
		initalizeInheritanceManagement()
	end
	
end