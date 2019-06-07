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
nano = piece "nano"
local safeHouseID = nil
gameConfig = getGameConfig()


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(houseAttach)
    StartThread(killMyselfIfNotAttached)
    Spring.SetUnitBlocking(unitID, false, false, false)


end

function killMyselfIfNotAttached()
    Sleep(gameConfig.safeHouseLiftimeUnattached)
    counter = 0
    while  safeHouseID == nil and boolAttached == false do
        Sleep(100)
        counter = counter + 100
        if counter > gameConfig.safeHouseLiftimeUnattached then
            Spring.DestroyUnit(unitID,false,true)
        end
    end

    while doesUnitExistAlive(safeHouseID) == true do
        Sleep(100)
    end
    Spring.DestroyUnit(unitID,false,true)
end

CivilianTypeDefTable= getCivilianTypeTable(UnitDefs)
local houseDefID= CivilianTypeDefTable["house"]
gaiaTeamID = Spring.GetGaiaTeamID()
boolAttached= false

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
    Spring.Echo("Safehouse completed")
    process(
        getAllNearUnit(unitID, gameConfig.buildSafeHouseRange),
        function(id) --filter out all the safe houses
            if Spring.GetUnitDefID(id) == houseDefID and Spring.GetUnitTeam(id) == gaiaTeamID then
                return id
        end
        end,
        function(id)
            if not GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable ={} end
            -- if no previous safe house was attached to this building or the previous attached safehouse has died
            if not GG.houseHasSafeHouseTable[id] or doesUnitExistAlive(GG.houseHasSafeHouseTable[id] ) == false then
                GG.houseHasSafeHouseTable[id] = unitID
                safeHouseID = id

                -- Spring.UnitAttach(id, unitID, getUnitPieceByName(id, gameConfig.safeHousePieceName))
                moveUnitToUnit(unitID,id)
                Spring.Echo("SafehouseAttached")
                -- Spring.SetUnitNoSelect(unitID, true)
                -- stunUnit(unitID,gameConfig.delayTillSafeHouseEstablished/1000)
                -- Sleep(gameConfig.delayTillSafeHouseEstablished)
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
                waitTillComplete(buildID)
                if doesUnitExistAlive(buildID) then

                    GG.houseHasSafeHouseTable[safeHouseID] = buildID
                    moveUnitToUnit(unitID, buildID)
                    -- Spring.UnitAttach(safeHouseID, buildID, getUnitPieceByName(safeHouseID, gameConfig.safeHousePieceName))
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
    if not safeHouseID then return 0 end

    SetUnitValue(COB.YARD_OPEN, 1)

    SetUnitValue(COB.BUGGER_OFF, 1)

    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end

function script.Deactivate()
    if not safeHouseID then return 0 end
    SetUnitValue(COB.YARD_OPEN, 0)

    SetUnitValue(COB.BUGGER_OFF, 0)

    SetUnitValue(COB.INBUILDSTANCE, 0)
    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { nano })


function script.StartBuilding()
    if not safeHouseID then return false end
end


function script.StopBuilding()

end
