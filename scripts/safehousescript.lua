include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
boolSafeHouseActive= false

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
Icon = piece "Icon"




function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(houseAttach)
    StartThread(killMyselfIfNotAttached)
    StartThread(drawMapRoom)
    Spring.SetUnitBlocking(unitID, false, false, false)


end

GameConfig = getGameConfig()
safeHouseID = nil
boolAttached= false
function killMyselfIfNotAttached()
    Sleep(GameConfig.safeHouseLiftimeUnattached)
    counter = 0
    while  safeHouseID == nil and boolAttached == false do
        Sleep(100)
        counter = counter + 100
        if counter > GameConfig.safeHouseLiftimeUnattached then
            Spring.DestroyUnit(unitID,false,true)
        end
    end

    while doesUnitExistAlive(safeHouseID) == true do
        Sleep(100)
    end
    Spring.DestroyUnit(unitID,false,true)
end

_, CivilianTypeDefTable= getCivilianTypeTable(UnitDefs)
	local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
	

gaiaTeamID = Spring.GetGaiaTeamID()

function createDoubleAgentEventStream(houseID, doubleAgentTeamDefID, safeHouseID)
	turnEveryoneDoubleAgentEventStream = function(houseID, doubleAgentTeamDefID, safeHouseID)
		
				doubleAgentFunction = function( persPack)
					--check house is still existing
					if false == doesUnitExistAlive(persPack.houseID) then 
						return true
					end		

					--if the safehouse ceased to be
					if false == doesUnitExistAlive(persPack.safeHouseID) then 
						return true
					end	

					buildID= Spring.GetUnitIsBuilding(persPack.safeHouseID)
					
					if not persPack.traitorTable  then persPack.traitorTable ={} end
					
					if buildID then
						defID = Spring.GetUnitDefID(buildID)
						--if not already in list make a double agent
						if not persPack.traitorTable[buildID] and not persPack.safeHouseUpgradeTable[defID] then
							persPack.traitorTable[buildID] = true
							attachDoubleAgentToUnit(buildID, persPack.doubleAgentTeam)
						end
						
						--if a upgrade then make it discovered thing
						if persPack.safeHouseUpgradeTable[defID] then
							GG.OperativesDiscovered[buildID] = true
							Spring.SetUnitAlwaysVisible(buildID, true)
						end
					end
			
			
				return false, persPack	
				end
				
	
				createStreamEvent(unitID, turnEveryoneDoubleAgentEventStream, 23, 	{houseID = houseID, safeHouseID = safeHouseID, doubleAgentTeam =doubleAgentTeamDefID, upgradeTypeTable = safeHouseUpgradeTable})
			end

			
	end
	

function houseAttach()
    Sleep(100)
    waitTillComplete(unitID)
    -- Spring.Echo("Safehouse completed")
    process(
        getAllNearUnit(unitID, GameConfig.buildSafeHouseRange),
        function(id) --filter out all the safe houses
            if houseTypeTable[Spring.GetUnitDefID(id)] and Spring.GetUnitTeam(id) == gaiaTeamID then
                return id
        end
        end,
        function(id)
            if not GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable ={} end
            -- if no previous safe house was attached to this building or the previous attached safehouse has died
            if not GG.houseHasSafeHouseTable[id] or doesUnitExistAlive(GG.houseHasSafeHouseTable[id] ) == false then
                GG.houseHasSafeHouseTable[id] = unitID
                safeHouseID = id

                -- Spring.UnitAttach(id, unitID, getUnitPieceByName(id, GameConfig.safeHousePieceName))
                moveUnitToUnit(unitID, id)
                -- Spring.Echo("SafehouseAttached")
                -- Spring.SetUnitNoSelect(unitID, true)
                -- stunUnit(unitID,GameConfig.delayTillSafeHouseEstablished/1000)
                -- Sleep(GameConfig.delayTillSafeHouseEstablished)
                boolAttached= true
                -- Spring.SetUnitNoSelect(unitID, false)
                StartThread(detectUpgrade)
            end

            --if a previous safehouse is attached
            if GG.houseHasSafeHouseTable[id] and doesUnitExistAlive(GG.houseHasSafeHouseTable[id] ) == true and GG.houseHasSafeHouseTable[id] ~= unitID then
            --destroy the previous created safehouse
			enemyTeamID = Spring.GetUnitTeam(GG.houseHasSafeHouseTable[id])
			Spring.DestroyUnit(GG.houseHasSafeHouseTable[id],true,false)
			
			--Turn everything that comes out of this safehouse into a double agent
			createDoubleAgentEventStream(id , enemyTeamID, unitID)	
			
	
            end
        end
    )
end

safeHouseUpgradeTable= getSafeHouseUpgradeTypeTable(UnitDefs, Spring.GetUnitDefID(unitID))

function detectUpgrade()
    while true do
        Sleep(500)
        -- Spring.Echo("Detect Upgrade")
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then

            buildDefID = Spring.GetUnitDefID(buildID)
            Spring.Echo("buildID found Upgrade of type ".. UnitDefs[buildDefID].name)
            if safeHouseUpgradeTable[buildDefID] then
				Sleep(100)
                waitTillComplete(buildID)
				Sleep(100)
                if doesUnitExistAlive(buildID) then

                    if not  GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable ={} end
                    GG.houseHasSafeHouseTable[safeHouseID] = buildID
                    moveUnitToUnit(buildID, safeHouseID)
                    -- Spring.UnitAttach(safeHouseID, buildID, getUnitPieceByName(safeHouseID, GameConfig.safeHousePieceName))
                    Spring.Echo("Upgrade Complete")
                    Spring.DestroyUnit(unitID,false,true)
                end
            end
        end

    end
end

function script.Killed(recentDamage, _)

    Spring.Echo("Safehouse killed")
    return 1

end

function script.Activate()
    -- if not safeHouseID then return 0 end
	SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
end

function script.Deactivate()
    -- if not safeHouseID then return 0 end
	SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })


function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
end


function script.StopBuilding()
    SetUnitValue(COB.INBUILDSTANCE, 0)
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if  boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end
end

safeHouseTypes= getSafeHouseTypeTable(UnitDefs)
houseTypeTable = getHouseTypeTable(UnitDefs, GameConfig.instance.culture)

function drawMapRoom()
	Sleep(100)
	hideT(TablesOfPiecesGroups["house"])
	hideT(TablesOfPiecesGroups["SafeHouse"])
	dictSafeHouse_Pos={}
	dictHouses_Pos ={}
	local spGetUnitDefID= Spring.GetUnitDefID
	local spGetUnitPosition= Spring.GetUnitPosition
	
	
	process(Spring.GetAllUnits(),
			function(id) 
				if Spring.GetUnitTeam(id)== gaiaTeamID then return id end
			end,
			function (id)
				if houseTypeTable[spGetUnitDefID(id)] then
					Spring.Echo("House found")
					x,_,z = spGetUnitPosition(id)
					dictHouses_Pos[id]={x=x/Game.mapSizeX,z=z/Game.mapSizeZ}
				end
			end
			)	
	
	process(Spring.GetAllUnits(),
			function (id)
				if safeHouseTypes[spGetUnitDefID(id)] then
					x,_,z = spGetUnitPosition(id)
					dictSafeHouse_Pos[id]={x=x/Game.mapSizeX,z=z/Game.mapSizeZ}
				end
			end
			)

	
	mapDim={x=500,z=-250}
	
	pieceIndex= 0
	for id, coords in pairs(dictHouses_Pos) do
		if math.random(0,1)==1 then
			pieceIndex= (	pieceIndex % #TablesOfPiecesGroups["house"])+1
			if TablesOfPiecesGroups["house"][pieceIndex] then
			pieceInOurTime = TablesOfPiecesGroups["house"][pieceIndex]
			Show(pieceInOurTime)
			mP(pieceInOurTime,coords.x*mapDim.x,0,coords.z*mapDim.z,0)	
			end
		end
	end	
	pieceIndex= 0
	for id, coords in pairs(dictSafeHouse_Pos) do
		if math.random(0,1)==1 then
			pieceIndex= (	pieceIndex % #TablesOfPiecesGroups["SafeHouse"])+1
			if TablesOfPiecesGroups["SafeHouse"][pieceIndex] then
			pieceInOurTime = randT(TablesOfPiecesGroups["SafeHouse"])
			Show(pieceInOurTime)
			mP(pieceInOurTime,coords.x*mapDim.x,0,coords.z*mapDim.z,0)	
			end
		end
	end

end
	
	
