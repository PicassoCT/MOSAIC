function gadget:GetInfo()
    return {
        name = "Collateral damage Gadget",
        desc = "Handles damage to civilian Units",
        author = "nanonymous",
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

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local gaiaTeamID= Spring.GetGaiaTeamID()

gameConfig = getGameConfig()

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	assert(damage)
	assert(attackerID)

	if unitTeam == gaiaTeamID and attackerID and attackerTeam ~= unitTeam and (GG.DisguiseCivilianFor and not GG.DisguiseCivilianFor[unitID] )then
		Spring.Echo("UnitDamaged is gaia "..gaiaTeamID)
		attackerPlayerList = Spring.GetPlayerList(attackerTeam)

		for _, team in pairs(Spring.GetTeamList()) do

			if not GG.Propgandaservers then GG.Propgandaservers ={} end
			if not GG.Propgandaservers[team] then GG.Propgandaservers[team] = 0 end

			if team ~= gaiaTeamID  then
				boolTeamsAreAllied = Spring.AreTeamsAllied(attackerTeam, team)
				
				if  boolTeamsAreAllied == true then		
					 Spring.UseTeamResource(team, "metal", damage)
				else  -- get enemy Teams -- tranfer damage as budget to them
					factor = 1 + (GG.Propgandaservers[team]* gameConfig.propandaServerFactor)
					Spring.AddTeamResource(team, "metal", damage * factor)
				end
			end
		end
	
	end  
end

