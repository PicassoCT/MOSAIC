function gadget:GetInfo()
    return {
        name = "Handles damage to Civilian Units",
        desc = " name",
        author = "nanonymous",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = false
    }
end

--GG.UnitsToSpawn:PushCreateUnit(name,x,y,z,dir,teamID)

if (not gadgetHandler:IsSyncedCode()) then
    return
end

VFS.Include("scripts/lib_UnitScript.lua")
local gaiaTeamID= Spring.GetGaiaTeamID()

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID)
	assert(damage)
	if unitTeam == gaiaTeamID and attackerID then
		attackerTeam = Spring.GetUnitTeam(attackerID)
	attackerPlayerList = Spring.GetPlayerList(attackerTeam)
	
	listOfTeams = Spring.GetTeamList()
	for _, team in pairs(listOfTeams) do
		boolTeamsAreAllied = Spring.AreTeamsAllied(attackerTeam, team)
		if team ~= gaiaTeamID and  boolTeamsAreAllied == false then		
			 consumeAvailableRessource("metal", damage, team, true)	
			 
		elseif boolTeamsAreAllied == true then
			Spring.AddTeamResource(team, "metal", damage)
		end
	end
	-- get enemy Teams -- tranfer damage as budget to them


	end  
end

