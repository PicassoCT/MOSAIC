include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
boolSafeHouseActive = false
GameConfig = getGameConfig()
safeHouseID = nil
boolAttached = false

gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
myDefID = spGetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
local spGetUnitPosition = Spring.GetUnitPosition
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)

safeHouseUpgradeTypeTable = getSafeHouseUpgradeTypeTable(UnitDefs, myDefID)


safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center"
Icon = piece "Icon"

function preventBuildingNearPreexistingSafehouse()
    process(getAllNearUnit(unitID, 100),
            function(id)
                if spGetUnitTeam(id) == myTeamID and id ~= unitID then 
                    return id
                end
            end,
            function(id)
                defID = spGetUnitDefID(id)
                if safeHouseTypeTable[defID] or safeHouseUpgradeTypeTable[defID] then
                    --we already have something in this building -- abort
                return true
                end
            end
            )
        return false
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    boolPredecessorSafehouse = preventBuildingNearPreexistingSafehouse()
    if boolPredecessorSafehouse == false then
    StartThread(houseAttach)
    StartThread(drawMapRoom)
    Spring.SetUnitBlocking(unitID, false, false, false)
    else
    StartThread(killDelayed)
    end
end

function killDelayed()
    Sleep(1)
    destroyUnitConditional(unitID, false, true)
end


function createDoubleAgentEventStream(houseID, doubleAgentTeamDefID, safeHouseID)
    turnEveryoneDoubleAgentEventStream =
        function(houseID, doubleAgentTeamDefID, safeHouseID)

            doubleAgentFunction = function(persPack)
                -- check house is still existing
                if false == doesUnitExistAlive(persPack.houseID) then
                    return true
                end

                -- if the safehouse ceased to be
                if false == doesUnitExistAlive(persPack.safeHouseID) then
                    return true
                end

                buildID = Spring.GetUnitIsBuilding(persPack.safeHouseID)

                if not persPack.traitorTable then
                    persPack.traitorTable = {}
                end

                if buildID then
                    defID = Spring.GetUnitDefID(buildID)
                    -- if not already in list make a double agent
                    if not persPack.traitorTable[buildID] and
                        not persPack.safeHouseUpgradeTypeTable[defID] then
                        persPack.traitorTable[buildID] = true
                        attachDoubleAgentToUnit(buildID,
                                                persPack.doubleAgentTeam)
                    end

                    -- if a upgrade then make it discovered thing
                    if persPack.safeHouseUpgradeTypeTable[defID] then
                        GG.OperativesDiscovered[buildID] = true
                        Spring.SetUnitAlwaysVisible(buildID, true)
                    end
                end

                return false, persPack
            end

            createStreamEvent(unitID, turnEveryoneDoubleAgentEventStream, 23, {
                houseID = houseID,
                safeHouseID = safeHouseID,
                doubleAgentTeam = doubleAgentTeamDefID,
                safeHouseUpgradeTypeTable = safeHouseUpgradeTypeTable
            })
        end

end

function houseAttach()
    Sleep(GameConfig.safeHouseLiftimeUnattached)
    checkPreExistingKill(unitID, unitID)
    waitTillComplete(unitID)
    -- Spring.Echo("Safehouse completed")
    boolJustOnce = false
    T = process(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange),
                function(id) -- filter out all the safe houses
        if houseTypeTable[Spring.GetUnitDefID(id)] and Spring.GetUnitTeam(id) ==
            gaiaTeamID then return id end
    end, function(id)
        if boolJustOnce == true then return end

        if not GG.houseHasSafeHouseTable then
            GG.houseHasSafeHouseTable = {}
        end
        -- if no previous safe house was attached to this building or the previous attached safehouse has died
        if not GG.houseHasSafeHouseTable[id] or
            doesUnitExistAlive(GG.houseHasSafeHouseTable[id]) == false then
            boolJustOnce = true
            GG.houseHasSafeHouseTable[id] = unitID
            safeHouseID = id
            StartThread(mortallyDependant, unitID, id, 250, false, true)
            -- Spring.UnitAttach(id, unitID, getUnitPieceByName(id, GameConfig.safeHousePieceName))
            moveUnitToUnit(unitID, id)
            -- Spring.Echo("SafehouseAttached")
            -- Spring.SetUnitNoSelect(unitID, true)
            -- stunUnit(unitID,GameConfig.delayTillSafeHouseEstablished/1000)
            -- Sleep(GameConfig.delayTillSafeHouseEstablished)
            boolAttached = true
            -- Spring.SetUnitNoSelect(unitID, false)
            StartThread(detectUpgrade)

            
            return id
        end

        -- if a previous safehouse is attached
        if GG.houseHasSafeHouseTable[id] and
            doesUnitExistAlive(GG.houseHasSafeHouseTable[id]) == true and
            GG.houseHasSafeHouseTable[id] ~= unitID then
            boolJustOnce = true
            -- destroy the previous created safehouse
            enemyTeamID = Spring.GetUnitTeam(GG.houseHasSafeHouseTable[id])
            Spring.DestroyUnit(GG.houseHasSafeHouseTable[id], true, false)

            -- Turn everything that comes out of this safehouse into a double agent
            createDoubleAgentEventStream(id, enemyTeamID, unitID)
        end
    end)
end

safeHouseUpgradeTypeTable = getSafeHouseUpgradeTypeTable(UnitDefs,
                                                     Spring.GetUnitDefID(unitID))

function checkPreExistingKill(toKillId, notID)
 OtherUpgradeTypesAliveAtLocation =process(getAllNearUnit(unitID, 120, myTeam),
                    function(id)
                        defID = spGetUnitDefID(id)
                            if safeHouseUpgradeTypeTable[defID] and id ~= notID then
                                return id
                            end
                        end,
                        function (id)
                            if isUnitComplete(id) == true then return id end
                        end
                        )

        if #OtherUpgradeTypesAliveAtLocation > 0 then
            Spring.DestroyUnit(toKillId, false, true)
        end
end

--boolDoneFor = false
function detectUpgrade()
   if not GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable = {} end
    while true do
        Sleep(500)
        -- Spring.Echo("Detect Upgrade")
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then
            buildDefID = Spring.GetUnitDefID(buildID)
            --    Spring.Echo("Safehouse is building unit of type ".. UnitDefs[buildDefID].name)
            if safeHouseUpgradeTypeTable[buildDefID] then
                checkPreExistingKill(buildID, buildID)
                --echo("Safehouse"..unitID..": Begin building Updgrade "..UnitDefs[buildDefID].name)
                if doesUnitExistAlive(buildID) == true then
                     echo("Safehouse"..unitID..": Waiting for Completion "..UnitDefs[buildDefID].name)
                    if waitTillComplete(buildID) == true then
            
                    echo("Safehouse"..unitID..": End building Updgrade "..UnitDefs[buildDefID].name)
                    GG.houseHasSafeHouseTable[safeHouseID] = buildID
                    moveUnitToUnit(buildID, safeHouseID)
                   -- boolDoneFor = true
                     Spring.UnitAttach(safeHouseID, buildID, getUnitPieceByName(safeHouseID, GameConfig.safeHousePieceName))
                    --Spring.Echo("Upgrade Complete")
                    Spring.DestroyUnit(unitID, false, true)
                    end
                end
            end
        end
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function script.Activate()
    --if  boolDoneFor == true then return 0 end
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    return 1
end

function script.Deactivate()
    -- if not safeHouseID then return 0 end
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    return 0
end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

function script.StartBuilding()  end

function script.StopBuilding() end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end
end

safeHouseTypes = getSafeHouseTypeTable(UnitDefs)
houseTypeTable = getHouseTypeTable(UnitDefs, GameConfig.instance.culture)

function drawMapRoom()
    Sleep(100)
    hideT(TablesOfPiecesGroups["house"])
    hideT(TablesOfPiecesGroups["SafeHouse"])
    dictSafeHouse_Pos = {}
    dictHouses_Pos = {}


    process(Spring.GetAllUnits(), function(id)
        if Spring.GetUnitTeam(id) == gaiaTeamID then return id end
    end, function(id)
        if houseTypeTable[spGetUnitDefID(id)] then
            x, _, z = spGetUnitPosition(id)
            dictHouses_Pos[id] = {x = x / Game.mapSizeX, z = z / Game.mapSizeZ}
        end
    end)

    process(Spring.GetAllUnits(), function(id)
        if safeHouseTypes[spGetUnitDefID(id)] then
            x, _, z = spGetUnitPosition(id)
            dictSafeHouse_Pos[id] = {
                x = x / Game.mapSizeX,
                z = z / Game.mapSizeZ
            }
        end
    end)

    mapDim = {x = 500, z = -250}

    pieceIndex = 0
    for id, coords in pairs(dictHouses_Pos) do
        if math.random(0, 1) == 1 then
            pieceIndex = (pieceIndex % #TablesOfPiecesGroups["house"]) + 1
            if TablesOfPiecesGroups["house"][pieceIndex] then
                pieceInOurTime = TablesOfPiecesGroups["house"][pieceIndex]
                Show(pieceInOurTime)
                mP(pieceInOurTime, coords.x * mapDim.x, 0, coords.z * mapDim.z,
                   0)
            end
        end
    end
    pieceIndex = 0
    for id, coords in pairs(dictSafeHouse_Pos) do
        if math.random(0, 1) == 1 then
            pieceIndex = (pieceIndex % #TablesOfPiecesGroups["SafeHouse"]) + 1
            if TablesOfPiecesGroups["SafeHouse"][pieceIndex] then
                pieceInOurTime = randT(TablesOfPiecesGroups["SafeHouse"])
                Show(pieceInOurTime)
                mP(pieceInOurTime, coords.x * mapDim.x, 0, coords.z * mapDim.z,
                   0)
            end
        end
    end

end

