function gadget:GetInfo()
    return {
        name = "Traffic Gadget",
        desc = "Coordinates Traffic ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear

if (gadgetHandler:IsSyncedCode()) then
	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	

    local spGetPosition = Spring.GetUnitPosition
    local spIsUnitDead = Spring.GetUnitIsDead
	
	GameConfig = getGameConfig()
	CivilianTypeTable = getCivilianTypeTable(UnitDefs)

    GG.CivilianTable = {} --[id ] ={ defID, CurrentTargetNode{routeIndex, stationIndex} , LastTargetNode{routeIndex, stationindex} }
    GG.UnitArrivedAtTarget = {} --[id] = true UnitID -- Units report back once they reach this target
	GG.BuildingTable=  {} --[BuildingUnitID] = {routeID, stationIndex}
	BuildingPlaceTable={} -- SizeOf Map/Divide by Size of Building
	RouteTabel = {} --Every Subtable route = {consists of a finite series of coordpairs[i][1] [i][2] ={x,z}}, start, target

    gaiaTeamID = Spring.GetGaiaTeamID()
	
	 function gadget:UnitCreated(unitID, unitDefID)
	 
	 end
	 
    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
       -- Transfer Funds according to who caused the destruction
    end

	 
	function gadget:UnitDestroyed(unitID, unitDefID)
		--if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
	end
	 
	function validateBuildSpotsReachable(BuildingPlaceTable)
	
	end
	
	function fromMapCenterOutwards(BuildingPlaceT,startx, startz)
	
	end
	
	function spawnInitialPopulation()
		uDim ={}
		uDim.x,uDim.y,uDim.z = GameConfig.houseSizeX + GameConfig.allyWaySizeX, GameConfig.houseSizeY, GameConfig.houseSizeZ+ GameConfig.allyWaySizeZ
		-- create Grid of all placeable Positions
		BuildingPlaceTable = makeTable(false, Game.mapSizeX/uDim.x, 1, Game.mapSizeZ/uDim.z)
	
		-- great Grid of placeable Positions
		BuildingPlaceTable = validateBuildSpotsReachable(BuildingPlaceTable)	
		
		-- spawn Buildings from MapCenter Outwards
		fromMapCenterOutwards(BuildingPlaceTable, math.ceil((Game.mapSizeX/uDim.x)*0.5), math.ceil((Game.mapSizeZ/uDim.Z)*0.5))
		-- check Traversability from each position to the previous position
		
		-- spawn Population at Buildings
		checkReSpawnPopulation()
		
		-- give Arrived Units Commands
		sendArrivedUnitsCommands()
	end
	
	function checkReSpawnHouses()
		dataToAdd= {}
		for bID, routeData in pairs(GG.BuildingTable) do
			local routeDataCopy = routeData
			if doesUnitExistAlive(bID) ~= true then
				GG.BuildingTable[bID]= nil
				rID, nID = routeData.rID, routeData.nID
				x, z,  =    RouteTabel[rID][nID].x,RouteTabel[rID][nID].z  
				id = spawnBuilding(CivilianTypeTable["house"], x, z, rID, nID)
				dataToAdd[id] = routeDataCopy
			end
		end
		
			for id, routeData in pairs(dataToAdd) do
				GG.BuildingTable[id] = routeData
			end
	
	end
	
	function checkReSpawnPopulation()
		counter = 0

		for id, data in pairs(GG.CivilianTable) do
			if id then
				if doesUnitExistAlive(id) == true then
					counter = counter + 1
				else
					GG.CivilianTable[id] = nil
				end
			end
		end
		
		if counter < GameConfig.numberOfPersons then
			for i=1, GameConfig.numberOfPersons  - counter do
				x,z,rID, nID = getRandomSpawnNode()
				id = spawnAMobileCivilianUnit(CivilianTypeTable["civilian"], x,z, rID,nID)	
				if id then
				 GG.UnitArrivedAtTarget[id] = true
				end
			end
		end	
	end
	
	function getRandomSpawnNode()
		rID = math.random(1,#RouteTabel)
		nID = 1
		if math.random(0,1)==1 then nID = 3 end
		
		return RouteTabel[rID][nID].x, RouteTabel[rID][nID].z, rID, nID
	end
	
	function isRouteTraversable(defID, nodeA, nodeB)
	 
	return true 
	end

	function spawnUnit(defID, x,z)	
        dir = math.max(1, math.floor(math.random(1, 3)))
        
        id = Spring.CreateUnit(defID, x, 100, z, dir, gaiaTeamID)
          if id then
            Spring.SetUnitNoSelect(id, true)
            Spring.SetUnitAlwaysVisible(id, true)
			return id
        end
	end

	-- truck or Person
    function spawnAMobileCivilianUnit(defID, x, z, rID, nID)
		id = spawnUnit(defID, Route[rID][nID].x,Route[rID][nID].z)
		if id then 
			GG.CivilianTable [id] = {defID = defID, LastTargetNode = {rID = rID, nID = nID}, CurrentTargetNode ={rID=rID, nID=nID}}
			GG.UnitArrivedAtTarget[id]= defID
		end
    end

	function spawnBuilding(defID, x, z, rID, nID)
		id = spawnUnit(defID, Route[rID][nID].x,Route[rID][nID].z)
		if id then 
			GG.BuildingTable[id] = {rID = rID, nID = nID}
			return id
		end
	end
	
	function gadget:Initialize()
		spawnInitialPopulation()
	end
	 
	function giveWaypointsToUnit(uID, uType, startroute, startnode)
		boolShortestPath= not( math.random(0,1)==1 or uType == CivilianTypeTable["truck"] )--  direct route to target
		
			travellFunction = function(evtID, frame, persPack, startFrame)
				--only apply if Unit is still alive
				if Spring.GetUnitIsDead(persPack.unitID) == true then
					return nil, persPack
				end
			
				hp = Spring.GetUnitHealth(persPack.unitID)
				if not persPack.myHP then persPack.myHP = hp end
				
				--we where obviously attacked - flee from attacker
				if persPack.myHP < hp and math.random(0,10) < 5 then
					attackerID = Spring.GetUnitLastAttacker(persPack.unitID)
					if attackerID then
					ax,ay,az = Spring.GetUnitPosition(attackerID)
					x,y,z =Spring.GetUnitPosition(persPack.unitID)
						if ax and x then
							dx,dz = x -ax, z- az
							dx,dz = dx * 100, dz * 100
							persPack.goalIndex= 1
							persPack.goalList[1] ={x= x+ dx, z = z+dz}
						end
					end
				end
			
				--if near Destination increase goalIndex
				
				
				
				-- if goalIndex >= #goalList then write yourself to arrived
				
				Command(persPack.unitID, "go", 
				{persPack.goalList[goalIndex].x,0,persPack.goalList[goalIndex].z}, 
				{"shift"})
				
				--
				
		
				return frame + 50, persPack
			end
			
	
		
			GG.EventStream:CreateEvent(travelling,
						{ unitID = id },
						Spring.GetGameFrame() + 1)
		
    end
	
	function sendArrivedUnitsCommands()
		for id, uType in pairs(GG.UnitArrivedAtTarget) do
			giveWaypointsToUnit(id, uType, GG.CivilianTable [id].LastTargetNode.rID, GG.CivilianTable [id].LastTargetNode.nID )
		end
	
		GG.UnitArrivedAtTarget = {}
	end

    function buildRouteSquareFromTwoUnits(unitOne, unitTwo)
        Route = {}
        x1, _, z1 = spGetPosition(unitOne)
        x2, _, z2 = spGetPosition(unitTwo)

        Route[1] = {}
        Route[1][1] = x1
        Route[1][2] = z1

        Route[2] = {}
        Route[2][1] = x1
        Route[2][2] = z2

        Route[3] = {}
        Route[3][1] = x2
        Route[3][2] = z2

        Route[4] = {}
        Route[4][1] = x2
        Route[4][2] = z1

        Route[5] = {}
        Route[5][1] = x1
        Route[5][2] = z1

        return Route
    end

    function gadget:GameFrame(frame)
			
			--if Unit arrived at Location
			--give new Target
			
			--Check number of Units
			-- recreate buildings 
			-- recreate civilians
			
		
    end
end

