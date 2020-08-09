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
	Aggressor = "Aggressor"
	Defender = "Defender"
	raidStates = getRaidStates()
	
	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if unitDefID == raidIconDefID then
			allRunningRaidRounds[unitID] = newRound(unitID, unitTeam, true)	
			assert(allRunningRaidRounds[unitID].Aggressor.Points > 0)
			assert(allRunningRaidRounds[unitID].Defender.Points > 0)			
		end	
	end
		
	function setPublicRaidState(unitID, state)			
		if not GG.RaidState then GG.RaidState ={} end
		GG.RaidState[unitID] = state
	end
	
	function newRound(raidIconID, attackerteam, boolGameStart, oldRound)
		setRaidIconProgress(raidIconID, 0)
		enemyID= Spring.GetUnitNearestEnemy(raidIconID)
		enemyTeamID = Spring.GetUnitTeam(enemyID)
		setPublicRaidState(raidIconID, raidStates.OnGoing)
		local returnTable = oldRound	
		
		if boolGameStart== true then
			returnTable=  {	
					Objectives ={},
					Aggressor = { 
						team =attackerteam,
						Points =  3,
						PlacedFigures = {},
						},
					Defender  = {
						team = enemyTeamID,
						Points = 3,
						PlacedFigures = {},
						},
				}					
		else
			returnTable.Objectives ={}
			returnTable.Aggressor.PlacedFigures ={}
			returnTable.Defender.PlacedFigures ={}

		end
			
		return returnTable
	end

	function registerPlaceUnit(parentID, unitID, roundRunning, boolObjective)
	env = Spring.UnitScript.GetScriptEnv(parentID)
		if env and env.registerPlaceUnit then
			Spring.UnitScript.CallAsUnit(parentID, env.registerPlaceUnit, unitID, boolObjective)
			
			if boolObjective == false then
			Spring.UnitScript.CallAsUnit(parentID, env.updateShownPoints, roundRunning.Aggressor.Points, roundRunning.Defender.Points)
			end
		end
	end

	local function RegisterObjective(self, unitID, raidParentID)	
		assert(raidParentID)
		Spring.SetUnitAlwaysVisible(unitID, true)
		allRunningRaidRounds[raidParentID].Objectives[unitID] = unitID 
		registerPlaceUnit(raidParentID, unitID, allRunningRaidRounds[raidParentID], true)
	end
	
	local function RegisterSniperIcon(self, unitID, unitTeam, raidParentID)
		assert(raidParentID)
		teamSelected = Defender --defender as default
		if Spring.GetUnitTeam(raidParentID) == Spring.GetUnitTeam(unitID)  then --aggressors
			teamSelected = Aggressor
		end
		
		if allRunningRaidRounds[raidParentID][teamSelected].Points > 0 then
			allRunningRaidRounds[raidParentID][teamSelected].PlacedFigures[#allRunningRaidRounds[raidParentID][teamSelected].PlacedFigures  + 1 ] = unitID
			allRunningRaidRounds[raidParentID][teamSelected].Points = 	allRunningRaidRounds[raidParentID][teamSelected].Points -1
			registerPlaceUnit(raidParentID, unitID, allRunningRaidRounds[raidParentID], false)	--reach Into Icon and update Points
		else
			Spring.Echo("Points that lead to unit Killed:"..allRunningRaidRounds[raidParentID][teamSelected].Points)
			GG.UnitsToKill:PushKillUnit(unitID)
		end
    end
	if GG.SniperIcon == nil then GG.SniperIcon = { Register = RegisterSniperIcon} end

	Graph= {}
	function addEdege(a, b)
		Graph[#Graph + 1] = {from = a, to = b}
	end
	
	function getUnitsInTriangle(id)
	 env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.getUnitsInTriangle then
			return Spring.UnitScript.CallAsUnit(id, env.getUnitsInTriangle)
        else
			Spring.Echo("Unit "..id.. " is not a snipeIcon")
		end
	return {}
	end
	
	function getRaidIconProgress(id)
	 env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.getRoundProgressBar then
			return Spring.UnitScript.CallAsUnit(id, env.getRoundProgressBar)
		end
	return 0
	end
	
	function setRaidIconProgress(id, value)
	 env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.setRoundProgressBar then
			return Spring.UnitScript.CallAsUnit(id, env.setRoundProgressBar, value )
		end
	return 0
	end
	
	allAllreadyExploredNodes={}
	function depthFirstSearchForCycles(currentNode) -- returns true if a cycle is found
		if allAllreadyExploredNodes[currentNode] then return true, currentNode end
		allAllreadyExploredNodes[currentNode]  = true
		cycleNode =nil
		
		boolFoundCycle= false
		for i=1, #Graph do
			local node = Graph[i]
			if node.from == currentNode then
				boolFoundCycle = boolFoundCycle or depthFirstSearchForCycles(node.to)
				if boolFoundCycle == true then
					cycleNode = node.from
					return true, cycleNode
				end
			end
		end
	return boolFoundCycle, cycleNode
	end
	
	function getListOfSolitaryEdges()
		SolitaryEdges = {}
		EdgesPointedTowards ={}
		for i=1, #Graph do
			local node = Graph[i]
			SolitaryEdges[node.from] = true
			EdgesPointedTowards[node.to] = true
		end
		
		for k,v in pairs(EdgesPointedTowards) do
			if SolitaryEdges[k] then  SolitaryEdges[k] = nil end
		end
		
		return SolitaryEdges
	end
	
	function killCyclic(cycleNode)
	toEliminateList ={[cycleNode]=true}

		while count(toEliminateList) > 0 do
			newList={}
			for i=#Graph,1,-1 do
				boolEliminateNode =false
				node = Graph[i]
				if toEliminateList[node.from] then
					newList[#newList +1]= node.to
					table.remove(Graph, i)
				end	
			end
			toEliminateList ={}
			for i=1,#newList do
				toEliminateList[newList[i]] = true
			end
		end
	end
	
	function evaluateEndedRound( raidIcon, roundRunning)
		winningTeam = nil
		Graph= {}
		local OriginalGraph = {}
		
		--early out -if one side has not placed at all 
		if #roundRunning.Defender.PlacedFigures == 0 or #roundRunning.Aggressor.PlacedFigures == 0 then		
			--defenders did not play 
			if #roundRunning.Defender.PlacedFigures == 0 and #roundRunning.Aggressor.PlacedFigures ~= 0 then	
				setPublicRaidState(raidIcon, raidStates.AggressorWins)
				return roundRunning.Aggressor.team, roundRunning, raidStates.AggressorWins
			end	
			
			--aggressors did not play 
			if #roundRunning.Defender.PlacedFigures == 0 and #roundRunning.Aggressor.PlacedFigures ~= 0 then	
				setPublicRaidState(raidIcon, raidStates.DefenderWins)
				return  roundRunning.Defender.team, roundRunning, raidStates.DefenderWins
			end
			
			--bot did not play
			if #roundRunning.Defender.PlacedFigures == 0 and #roundRunning.Aggressor.PlacedFigures == 0 then		
				setPublicRaidState(raidIcon, raidStates.DefenderWins)
				return  nil, roundRunning, raidStates.Aborted
			end
		end

	repeat 
		--find out who aims at who - defenders
			process(roundRunning.Defender.PlacedFigures,
				function (id)
					process(getUnitsInTriangle(id ),			
							function(ad) 					--add those edges to the graph
								if ad ~= id and Spring.GetUnitTeam(ad) ~= roundRunning.Aggressor then
									addEdege(id, ad)
								end
							end
							)
				end
				)
		
			process(roundRunning.Aggressor.PlacedFigures,
				function (id)
					process(getUnitsInTriangle(id ),		
							function(ad) 					--add those edges to the graph
								if ad ~= id and Spring.GetUnitTeam(ad) ~= roundRunning.Defender then
									addEdege(id, ad)
								end
							end
							)
				end
				)
		
		OriginalGraph = Graph
		assert(#Graph > 0)
		
		--we now have a graph of only valid hits - filtered for team on team hits
		--get a list of edges who nobody aims at
		SolitaryEdges = getListOfSolitaryEdges()
		
		
		while #SolitaryEdges > 0 do
		deadList ={}
			for edge, state in pairs(SolitaryEdges) do
				for i=1,#Graph do
					node = Graph[i]
					if node.from == edge then
						deadList[node.to]= true
					end			
				end
			end
			
			for i= #Graph, 1, -1 do
				node = Graph[i]
				if deadList[node.from] then
					table.remove(Graph,i)
				end
			end
			
		--eliminate from the solitary edges inwards	from the graph	
		SolitaryEdges = getListOfSolitaryEdges()
		end
		
		--if it still contains cycles eliminate those entirely
		allAllreadyExploredNodes={}
		for i=1,#Graph do
			bIsCycle, cycleNode = depthFirstSearchForCycles(Graph[i]) 
			if bIsCycle == true  then
				killCyclic(cycleNode)
			
			end
		end
	
	until #Graph == 0
	--Auswertung
	
	if #Graph == 0 then Spring.Echo("No survivors");  end -- No valid aiming pairs
		
	eliminatedUnits = findEliminatedUnits(OriginalGraph, Graph)
	Survivors  = findSurvivors (roundRunning, eliminatedUnits)
	DestroyTable(eliminatedUnits, false, true)
	
	--condense Survivors Back to Points

	
	for k,v in pairs (Survivors) do
		if Spring.GetUnitTeam(k) == roundRunning.Aggressors.team then
			roundRunning.Aggressors.Points = roundRunning.Aggressors.Points + 1
		else
			roundRunning.Defender.Points = roundRunning.Defender.Points + 1
		end
	end

	--Objective Evaluation 
	for objective in pairs(roundRunning.Objectives) do
		process(Survivors,
				function(id)
					if distanceUnitToUnit(objective, id) < 50 then
						if Spring.GetUnitTeam(id) == roundRunning.Aggressors.team then
							roundRunning.Aggressors.Points = roundRunning.Aggressors.Points + 1
						else
							roundRunning.Defender.Points = roundRunning.Defender.Points + 1
						end
					end
				end
				)		
	end
	
	DestroyTable(Survivors, false, true)
	DestroyTable(roundRunning.Objectives, false, true)
	
	
	if roundRunning.Defender.Points <= 0 or roundRunning.Aggressor.Points <= 0 then		
			--defenders dead
			if roundRunning.Aggressor.Points  <= 0 and roundRunning.Defender.Points  ~= 0 then	
				setPublicRaidState(raidIcon, raidStates.AggressorWins)
				return roundRunning.Aggressor.team, roundRunning, raidStates.AggressorWins
			end	
			
			--aggressors dead
			if roundRunning.Aggressor.Points  ~= 0 and roundRunning.Defender.Points  <= 0 then			setPublicRaidState(raidIcon, raidStates.DefenderWins)
				return  roundRunning.Defender.team, roundRunning, raidStates.DefenderWins
			end
			
			--both died
			if #roundRunning.Defender.PlacedFigures <= 0 and #roundRunning.Aggressor.PlacedFigures <= 0 then		
				setPublicRaidState(raidIcon, raidStates.DefenderWins)
				return  nil, roundRunning, raidStates.Aborted
			end
		end		
	end
	
	function findEliminatedUnits(OriginalGraph, Graph)
		eliminatedUnits ={}
		for n,v in (Graph) do
			eliminatedUnits[v.to] = true		
		end
		
		return eliminatedUnits
	end
	
	function 	findSurvivors (roundRunning, eliminatedUnits)
		survivor={} -- not the_Band
		for nr, id in pairs(roundRunning.Aggressor.PlacedFigures) do
			if not eliminatedUnits[id] then
				survivor[id] = true
			end
		end
		return survivor
	end
	
	function checkRoundEnds()
		for raidIcon, roundRunning in pairs(allRunningRaidRounds) do
		
			--Round has ended
			if getRaidIconProgress(raidIcon) >= 100 or ( roundRunning.Defender.Points == 0 and roundRunning.Aggressor.Points == 0 ) then
				--find out who died, who survived, who collected objectives and if there is a new round
				winningTeam, roundRunning, state = evaluateEndedRound(roundRunning)
				
				if state == raidStates.
				if winningTeam then -- one side has won
					if winningTeam == Aggressor then --agressor won, game over
						Spring.Echo("Aggressor won")
					
					else
						Spring.Echo("Defender won")
						--kill all the old icons
						process(roundRunning.Aggressor.PlacedFigures, function(id) Spring.DestroyUnit(id, true, false) end )
						process(roundRunning.Defender.PlacedFigures, function(id) Spring.DestroyUnit(id, true, false) end )
						allRunningRaidRounds[raidIcon] = newRound(roundRunning, roundRunning.Aggressor.team, false, roundRunning)				
					end
				end
			end		
		end	
	end
	
	GG.DisplayedSniperIconParent={}
	local lastSniperIconID
	function gadget:RecvLuaMsg(msg, playerID)
		
        if msg and string.find(msg,"SPWN") then		
			t= split(msg, "|")

            name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country, rank, _ = Spring.GetPlayerInfo(playerID)
			uType =  t[2]
			raidIconID= tonumber(t[6])
			lastSniperIconID = nil

			if allRunningRaidRounds[raidIconID].Aggressor.team == teamID and allRunningRaidRounds[raidIconID].Aggressor.Points > 0 or
			   allRunningRaidRounds[raidIconID].Defender.team == teamID and allRunningRaidRounds[raidIconID].Defender.Points > 0
			then
				-- Spring.Echo("CreateUnit"..uType, tonumber(t[3]), tonumber(t[4]),  tonumber(t[5]),1, teamID)
				lastSniperIconID= Spring.CreateUnit(uType, tonumber(t[3]), tonumber(t[4]),  tonumber(t[5]),1, teamID)
				if uType == "snipeicon" then
				    GG.DisplayedSniperIconParent[lastSniperIconID] = raidIconID
					GG.SniperIcon:Register( lastSniperIconID, teamID, raidIconID)
				end
			end       
		end
		
		if lastSniperIconID and msg and string.find(msg, "POSROT") then
		Spring.Echo("SpawnMessage:"..msg)
			t= split(msg, "|")
			Command(lastSniperIconID, "attack", {tonumber(t[3]),tonumber(t[4]),tonumber(t[5])}, {"shift"})
		end
    end

	function gadget:GameFrame(frame)
		if frame % 30 == 0 then
			checkRoundEnds()
		end
     end
	
end --gadgetend
