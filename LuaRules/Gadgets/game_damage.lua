function gadget:GetInfo()
    return {
        name = "Damage Modification",
        desc = "Handles damage modfiers/omitters to Units",
        author = "PicassoCT",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = true
    }
end

--GG.UnitsToSpawn:PushCreateUnit(name,x,y,z,dir,teamID)

if ( gadgetHandler:IsSyncedCode()) then
	   

	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	local gaiaTeamID= Spring.GetGaiaTeamID()

	gameConfig = getGameConfig()
	UnitDefNames = getUnitDefNames(UnitDefs)
	houseTypeTables= getHouseTypeTable(UnitDefs)
	local NimRodDefID = UnitDefNames["house"].id
	
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		--if unit is house
		if attackerDefID == NimRodDefID then
			if houseTypeTables[unitDefID]   then
				if GG.UnitHeldByHouseMap[attackerID] and GG.UnitHeldByHouseMap[attackerID] == unitID then
					return 0
				end
			end
		
			if attackerID == unitID then
				return 0 
			end
		end
	end
	

end