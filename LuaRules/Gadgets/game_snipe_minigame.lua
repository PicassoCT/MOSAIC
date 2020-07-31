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
	
	function newRoundTable(unitID, attackerteam, oldRound)
		enemyID= Spring.GetUnitNearestEnemy(unitID)
		enemyTeamID = Spring.GetUnitTeam(enemyID)
			 return 
			 {
				 attacker = attackerteam,
				 defender = enemyTeamID, 
				[figure.Red] = { 
					Points = oldRound[figure.Red].Points or 3,
					PlacedFigures = {},
					},
				[figure.Blue] = {
					Points = oldRound[figure.Blue].Points or 3,
					PlacedFigures = {},
					},
			}
	end
	
	
 local function RegisterSniperIcon(self, unitID, unitTeam, raidParentID)
		if not raidParentID then raidParentID = randdict(allRunningRaidRounds) end --TODO Testcode remove
		teamSelected = figure.Blue --defender as default
		if Spring.GetUnitTeamID(raidParentID) == Spring.GetUnitTeamID(unitID)  then --aggressors
			teamSelected = figure.Red
		end
		
			if allRunningRaidRounds[raidParentID][teamSelected] > 0 then
			allRunningRaidRounds[raidParentID][teamSelected].PlacedFigures[#allRunningRaidRounds[raidParentID][teamSelected].PlacedFigures  + 1 ] = unitID
			allRunningRaidRounds[raidParentID][teamSelected].Points = 	allRunningRaidRounds[raidParentID][teamSelected].Points -1
				--reach Into Icon and update Points
			else
				 GG.UnitsToKill:PushKillUnit(unitID)
			end

    end
   if GG.SniperIcon == nil then GG.SniperIcon = { Register = RegisterSniperIcon} end

	function 
	function checkRoundEnds()
		for raidIcon, roundRunning in pairs(allRunningRaidRounds) do
		
			--Round has ended
			if getRaidIconProgressbar(raidIcon) >= 100 or ( roundRunning[figures.Red].Points == 0 and roundRunning[figures.Blue].Points == 0 ) then
				winningTeam = evaluateRound(roundRunning)
				if winningTeam then -- one side has won
					if winningTeam == 
				
					end
				end
			end
		
		end
	
	end
	 function gadget:GameFrame(frame)
		if frame % 30 == 0 then
			 checkRoundEnds()
		end
     end
	
	
	end --gadgetend
