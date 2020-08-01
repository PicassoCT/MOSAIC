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
	
	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if unitDefID == raidIconDefID then
			allRunningRaidRounds[unitID] = newRoundTable(unitID, unitTeam)		
		end
	end
	
	function newRoundTable(unitID, attackerteam, oldRound)
		enemyID= Spring.GetUnitNearestEnemy(unitID)
		enemyTeamID = Spring.GetUnitTeam(enemyID)
			 return 
			 {	Objectives ={},
				Aggressor = { 
					team =attackerteam
					Points = oldRound.Aggressor.Points or 3,
					PlacedFigures = {},
					},
				Defender  = {
					team = enemyTeamID
					Points = oldRound.Defender.Points or 3,
					PlacedFigures = {},
					},
			}
	end

 local function RegisterObjective(self, unitID, raidParentID)	
 	if not raidParentID then raidParentID = randdict(allRunningRaidRounds) end --TODO Testcode remove
	Spring.SetUnitAlwaysVisible(unitID, true)
	allRunningRaidRounds[raidParentID].Objectives[unitID] = unitID
 
 end
	
 local function RegisterSniperIcon(self, unitID, unitTeam, raidParentID)
		if not raidParentID then raidParentID = randdict(allRunningRaidRounds) end --TODO Testcode remove
		teamSelected = Defender --defender as default
		if Spring.GetUnitTeam(raidParentID) == Spring.GetUnitTeam(unitID)  then --aggressors
			teamSelected = Aggressor
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
	
	
	function evaluateRound( roundRunning)
		winningTeam = nil
		Graph= {}
		local OriginalGraph = {}

		--find out who aims at who - defenders
			process(roundRunning.Defender,
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
		
			process(roundRunning.Aggressor,
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
		
		--we now have a graph of only valid hits
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
			
		--eliminate from the solitary edges inwards		
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

	--Auswertung
	
	if #Graph == 0 then Spring.Echo("No survivors"); return end --No Survivors - WTF
		
	eliminatedUnits = findEliminatedUnits(OriginalGraph, Graph)
	DestroyTable(eliminatedUnits, false, true)
	
	--condense Survivors Back to Points
	Survivors ={}
	for i=#Graph, 1, -1 do 
		Survivors[Graph[i].from] = Graph[i].from
	end
	
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
		
	end
	
	DestroyTable(roundRunning.Objectives, false, true)
	return winningTeam
	end
	
	function checkRoundEnds()
		for raidIcon, roundRunning in pairs(allRunningRaidRounds) do
		
			--Round has ended
			if getRaidIconProgressbar(raidIcon) >= 100 or ( roundRunning[figures.Red].Points == 0 and roundRunning[figures.Blue].Points == 0 ) then
				--find out who died, who survived, who collected objectives and if there is a new round
				winningTeam, roundRunning = evaluateRound(roundRunning)
				if winningTeam then -- one side has won
					if winningTeam == Aggressor then --agressor won, game over
					
					else
					--kill all the old icons
					process(roundRunning.Aggressor, function(id) Spring.DestroyUnit(id, true, false) end )
					process(roundRunning.Defender, function(id) Spring.DestroyUnit(id, true, false) end )
					allRunningRaidRounds[raidIcon] = newRoundTable(roundRunning)
				
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
