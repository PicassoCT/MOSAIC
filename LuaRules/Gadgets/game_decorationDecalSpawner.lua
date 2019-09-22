function gadget:GetInfo()
	return {
		name = "Decal spawner",
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
	gameConfig = getGameConfig()
	
	defIDDecalNameMap = getDecalMap(gameConfig.instance.culture)	
	gaiaTeamID = Spring.GetGaiaTeamID()
	
	function gadget:UnitCreated(unitID, unitDefID, teamID)
		if defIDDecalNameMap[UnitDefs[unitDefID].name] then
			x,y,z= Spring.GetUnitPosition(unitID)
			ID = 0
			
			if type(defIDDecalNameMap[UnitDefs[unitDefID].name]) == "table" then
				ID = defIDDecalNameMap[UnitDefs[unitDefID].name][math.random(1,#defIDDecalNameMap[UnitDefs[unitDefID].name])]
			else	
				ID = defIDDecalNameMap[UnitDefs[unitDefID].name]		
			end
			
			GG.UnitsToSpawn:PushCreateUnit(ID, x,y,z, 1 , gaiaTeamID)			
		end
	end		
end