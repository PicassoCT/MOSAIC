function gadget:GetInfo()
	return {
		name = "Civilian City and Inhabitants Gadget",
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
	
	local spGetPosition = Spring.GetUnitPosition
	UnitDefNames = getUnitDefNames(UnitDefs)
	GameConfig = getGameConfig()
	CivilianTypeTable, CivilianUnitDefsT = getCivilianTypeTable(UnitDefs)
	assert(CivilianTypeTable["civilian"])
	assert(CivilianTypeTable["truck"])
	assert(#CivilianUnitDefsT > 0)
	MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
		

	GG.CivilianTable = {} --[id ] ={ defID, CurrentTargetNode{routeIndex, stationIndex} , LastTargetNode{routeIndex, stationindex} }
	GG.UnitArrivedAtTarget = {} --[id] = true UnitID -- Units report back once they reach this target
	GG.BuildingTable= {} --[BuildingUnitID] = {routeID, stationIndex}
	BuildingPlaceTable={} -- SizeOf Map/Divide by Size of Building
	uDim ={}
	uDim.x,uDim.y,uDim.z = GameConfig.houseSizeX + GameConfig.allyWaySizeX, GameConfig.houseSizeY, GameConfig.houseSizeZ+ GameConfig.allyWaySizeZ	
	numberTileX, numberTileZ =  Game.mapSizeX/uDim.x,  Game.mapSizeZ/uDim.z
	RouteTabel = {} --Every Subtable route = {consists of a finite series of coordpairs[i][1] [i][2] ={x,z}}, start, target

	gaiaTeamID = Spring.GetGaiaTeamID()
	
	-- function gadget:UnitCreated(unitID, unitDefID)
	-- end
	
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		-- Transfer Funds according to who caused the destruction
	end
	
	function gadget:UnitDestroyed(unitID, unitDefID, teamID)
		--if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
		if teamID == gaiaTeamID then
		ux,uy,uz= Spring.GetUnitPosition(unitID)
			process(getInCircle(unitID, GameConfig.civilianInterestRadius, gaiaTeamID),
					function(id)
						if 	MobileCivilianDefIds[GG.CivilianTable[unitID].defID] then
							return id
						end
					end,
					function(id)
						if math.random(0,100) > GameConfig.inHundredChanceOfInterestInDisaster then						
							Command(persPack.unitID, "go", { ux+ math.random(-10,10), uy, uz+ math.random(-10,10)}, {})					
						end
					end
					)
		end
	end
	
	-- check Traversability from each position to the previous position	
	function validateBuildSpotsReachable( tileX, tileZ)
	BuildingPlaceTable = makeTable(false, Game.mapSizeX/uDim.x, 1, Game.mapSizeZ/uDim.z)	
	
		for x=1,#BuildingPlaceTable do
			
			for z=1,#BuildingPlaceTable[1] do
				startx, startz = x * tileX, z * tileZ
		
				PlacesReachableFromPosition = 0
					for xi=1,#BuildingPlaceTable do
						for zi=1,#BuildingPlaceTable[1] do
							if xi~= x or  zi~= z then
							endx, endz = xi*tileX, zi*tileZ
					
								if Spring.RequestPath(UnitDefNames["truck"].moveDef.name , startx,0,startz,endx,0,endz) then
									PlacesReachableFromPosition = PlacesReachableFromPosition + 1
								end
							end
						end
					end
				if PlacesReachableFromPosition > 5 then
					BuildingPlaceTable[x][z] = true
				end
			end
		end
	end

	function cursorsIsOnMainRoad(cursor)
		return cursor.x % GameConfig.mainStreetModulo == 0 or  cursor.z % GameConfig.mainStreetModulo == 0 
	end
	
	function randomWalk(cursor)
		return {x = cursor.x + randSign(), z = cursor.z +randSign()}
	end
	function mirrorCursor(cursor, x,z)
		x,z = x - cursor.x, z - cursor.z
		x,z = x*-1,z*-1
		cursor.x,cursor.z =x + cursor.x, z + cursor.z
		return cursor
	end
	--spawns intial buildings
	function fromMapCenterOutwards(BuildingPlaceT,startx, startz)
	local finiteSteps= 255
	cursor ={x=startx, z=startz}
	mirror = {x=startx, z=startz}
	local numberOfBuildings = GameConfig.numberOfBuildings -1
	
		while finiteSteps > 0 and numberOfBuildings > 0 do
			finiteSteps = finiteSteps -1
			
			RandomWalkTable = makeTable(false, Game.mapSizeX/uDim.x, 1, Game.mapSizeZ/uDim.z)		
			dice= math.random(1,3)		
				if dice == 1 then 	--1 random walk into a direction doing nothing
					cursor = randomWalk(cursor)
					mirror = mirrorCursor(cursor, startx, startz)
					
				elseif dice == 2 then --2 place a single block
					if BuildingPlaceT[cursor.x][cursor.z] == true and cursorsIsOnMainRoad(cursor) == false then
						spawnBuilding(CivilianTypeTable["house"], 
						cursor.x * uDim.x,
						cursor.z * uDim.Z,
						(GameConfig.numberOfBuildings-numberOfBuildings),
						1
						)
						numberOfBuildings = numberOfBuildings -1
						BuildingPlaceT[cursor.x][cursor.z] = false
					end
					
					if BuildingPlaceT[mirror.x][mirror.z] == true and cursorsIsOnMainRoad(mirror) == false then
						spawnBuilding(CivilianTypeTable["house"], 
						mirror.x * uDim.x,
						mirror.z * uDim.Z,
						(GameConfig.numberOfBuildings-numberOfBuildings),
						1
						)
						numberOfBuildings = numberOfBuildings -1
						BuildingPlaceT[cursor.x][cursor.z] = false
					end
					
				elseif dice == 3 then
					numberOfBuildings, BuildingPlaceT = placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings, BuildingPlaceT)
					numberOfBuildings, BuildingPlaceT = placeThreeByThreeBlockAroundCursor(mirror, numberOfBuildings, BuildingPlaceT)
				end
		end
	end
	
	function placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings, BuildingPlaceT)
		for offx = -1, 1, 1 do
			if 	BuildingPlaceT[cursor.x+ offx] then
				for offz = -1, 1, 1 do 
					if 	BuildingPlaceT[cursor.x+ offx][cursor.z+offz] then
								spawnBuilding(
								CivilianTypeTable["house"], 
								cursor.x * uDim.x + offx*cursor,
								cursor.z * uDim.Z + offz*cursor,
								(GameConfig.numberOfBuildings-numberOfBuildings),
								1
								)
								numberOfBuildings=numberOfBuildings-1
								BuildingPlaceT[cursor.x+ offx][cursor.z+offz] = false
					end                          
				end                          
			end                          
		end
		
		return numberOfBuildings, BuildingPlaceT
	end
	
	function spawnInitialPopulation()
	-- create Grid of all placeable Positions
		-- great Grid of placeable Positions 
		validateBuildSpotsReachable(uDim.x, uDim.z)	
		
		-- spawn Buildings from MapCenter Outwards
		fromMapCenterOutwards(BuildingPlaceTable, math.ceil((Game.mapSizeX/uDim.x)*0.5), math.ceil((Game.mapSizeZ/uDim.z)*0.5))
		
		generateRoutesTable()

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
				x, z = RouteTabel[rID][nID].x, RouteTabel[rID][nID].z 
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
			for i=1, GameConfig.numberOfPersons - counter do
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
	
	function buildRouteSquareFromTwoUnits(unitOne, unitTwo)
		Route = {}
		x1, _, z1 = spGetPosition(unitOne)
		x2, _, z2 = spGetPosition(unitTwo)
		index= 1
		Route[index]= {}
		Route[index][1] = x1
		Route[index][2] = z1
		index = index + 1
		Route[index]= {}
		
		if Spring.GetGroundHeigth(x1, z2) > 5 then
			Route[index][1] = x1
			Route[index][2] = z2
			index = index + 1
			Route[index]= {}
		end
		
		Route[index][1] = x2
		Route[index][2] = z2
		index = index + 1
		Route[index]= {}

		
		if Spring.GetGroundHeigth(x2, z1) > 5 then
			Route[index][1] = x2
			Route[index][2] = z1
			index = index + 1
			Route[index]= {}
		end		
		
		Route[index][1] = x1
		Route[index][2] = z1
		
		return Route
	end
	
	function generateRoutesTable()
		for thisBuildingID, data in pairs(GG.BuildingTable) do--[BuildingUnitID] = {routeID, stationIndex} 
			for otherID, oData in pairs(GG.BuildingTable) do--[BuildingUnitID] = {routeID, stationIndex} 
				if thisBuildingID ~= otherID and isRouteTraversable(CivilianTypeTable["truck"], thisBuildingID, otherID  ) then
					 RouteTabel[#RouteTabel +1] = buildRouteSquareFromTwoUnits(thisBuildingID, otherID)
				end
			end
		end
	end
	
	function isRouteTraversable(defID, unitA, unitB)
		vA = getUnitPositionV(unitA)
		vB = getUnitPositionV(unitB)
		assert(UnitDefNames["truck"].movementClass )
		assert(UnitDefNames["truck"].moveDef.name )
		path = 	Path.RequestPath(UnitDefNames["truck"].movementClass , vA.x,vA.y,vA.z,vB.y,vB.z)
		return path ~= nil
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
		boolIsCivilian = (uType == CivilianTypeTable["civilian"])
		boolShortestPath= not( math.random(0,1)==1 or uType == CivilianTypeTable["truck"] )-- direct route to target
		
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
					ax,ay,az = spGetPosition(attackerID)
					x,y,z = spGetPosition(persPack.unitID)
					if ax and x then
						dx,dz = x -ax, z- az
						dx,dz = dx * 100, dz * 100
						Command(persPack.unitID, "go", { x+ dx ,0 ,z+dz}, {"shift"})
						return frame + 1000 , persPack
					end
				end
			end
			
			--ocassionally detour toward the nearest ally or enemy
			if math.random(0, 4) > 2 and uType == Ci then
				local partnerID
				if math.random(0,1)==1 then
					partnerID = Spring.GetUnitNearestAlly(persPack.unitID)
				else
					partnerID = Spring.GetUnitNearestEnemy(persPack.unitID)
				end
				if partnerID then
					x,y,z= Spring.GetUnitPosition(partnerID)
					return frame + math.random(500,5000) , persPack
				end
			end
			
			--if near Destination increase goalIndex
			if distanceUnitToPoint(persPack.unitID, persPack.goalList[persPack.goalIndex].x,0,persPack.goalList[persPack.goalIndex].z) < (GameConfig.houseSizeX + GameConfig.houseSizeZ)/2 + 40 then
				persPack.goalIndex = persPack.goalIndex + 1
				
				if persPack.goalIndex > #persPack.goalList then						
					GG.UnitArrivedAtTarget[persPack.unitID] = true
					return nil, persPack
				end					
			end			
			
			Command(persPack.unitID, "go", 
			{persPack.goalList[persPack.goalIndex].x,0,persPack.goalList[persPack.goalIndex].z}, {})
			
			return frame + math.random(50,100), persPack
		end	
		
		GG.EventStream:CreateEvent(
		travellFunction,
		{ unitID = id },
		Spring.GetGameFrame() + 1
		)
	end
	
	function sendArrivedUnitsCommands()
		for id, uType in pairs(GG.UnitArrivedAtTarget) do
			giveWaypointsToUnit(id, uType, GG.CivilianTable [id].LastTargetNode.rID, GG.CivilianTable [id].LastTargetNode.nID )
		end
		
		GG.UnitArrivedAtTarget = {}
	end
	
	
	
	function gadget:GameFrame(frame)
		if frame > 0 then
			-- recreate buildings 
			-- recreate civilians
			checkReSpawnHouses()
			
			--Check number of Units	
			checkReSpawnPopulation()
			
			--if Unit arrived at Location
			--give new Target
			sendArrivedUnitsCommands()
		end		
	end
end