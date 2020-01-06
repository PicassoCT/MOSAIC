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

	GameConfig = getGameConfig()
	UnitDefNames = getUnitDefNames(UnitDefs)
	houseTypeTables= getHouseTypeTable(UnitDefs, GameConfig.instance.culture)
	local NimRodDefID = UnitDefNames["nimrod"].id
	assert(NimRodDefID)
	local NimrodWeaponDefID = WeaponDefNames["railgun"].id
	assert(NimrodWeaponDefID)
	if not GG.UnitHeldByHouseMap then GG.UnitHeldByHouseMap={} end
	
	-- Script.SetWatchWeapon( WeaponDefNames["railgun"].id, true)

	function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		--if weapon is Nimrod
		if weaponDefID == NimrodWeaponDefID then
	
		-- Spring.Echo("PreDamaged called Attacker is nimrod and assaulted unit is "..UnitDefs[unitDefID].name)
			if houseTypeTables[unitDefID] then
				if GG.UnitHeldByHouseMap[attackerID] and GG.UnitHeldByHouseMap[attackerID] == unitID then
					-- Spring.Echo("House spared")
					return 0,1.0
				end
			end
		
			if unitDefID == NimRodDefID and unitID == attackerID then
			-- Spring.Echo("Nimrod spared")
				return 0 , 1.0 
			end
		end
	end
	
	return damage
end