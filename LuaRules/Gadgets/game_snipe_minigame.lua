function gadget:GetInfo()
    return {
        name = "game Snipe Mini Game",
        desc = "This gadget handles the minigame",
        author = "",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")
	
	--variables
	local raidIconDefID = UnitDefNames["raidicon"].id
	local snipeIconDefID = UnitDefNames["snipeicon"].id
	local allRunningRaidRounds = {}
	
	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if unitDefID == raidIconDefID then
			allRunningRaidRounds[unitID] = newRoundTable(unitID, unitTeam)		
		end
	end
	
	function newRoundTable(unitID, attackerteam)
		enemyID= Spring.GetUnitNearestEnemy(unitID)
		enemyTeamID = Spring.GetUnitTeam(enemyID)
			 return 
			 {
				 attacker = attackerteam,
				 defender = enemyTeamID, 
				[figure.Red] = { 
					PlacedFigures = {},
					},
				[figure.Blue] = {
					PlacedFigures = {},
					},
			}
	end
	
	
	end --gadgetend
