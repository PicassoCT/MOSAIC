include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_staticstring.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
boolSafeHouseActive = false
local GameConfig = getGameConfig()
containingHouseID = nil
local gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam

local myTeamID = Spring.GetUnitTeam(unitID)
local spGetUnitPosition = Spring.GetUnitPosition
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
local safeHouseUpgradeTypeTable = getSafeHouseUpgradeTypeTable(UnitDefs, unitDefID)
local safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)
local operativeTypeTable = getOperativeTypeTable(UnitDefs)
function script.HitByWeapon(x, z, weaponDefID, damage) return damage;end

center = piece "center"
Icon = piece "Icon"

function preventBuildingNearPreexistingSafehouse()
    boolResult = false
    foreach(
        getAllNearUnit(unitID, 100),
        function(id)
            if spGetUnitTeam(id) == myTeamID and id ~= unitID then 
                return id
            end
        end,
        function(id)
            defID = spGetUnitDefID(id)
            if safeHouseTypeTable[defID] or safeHouseUpgradeTypeTable[defID] then
                --we already have something in this building -- abort
                boolResult=  true
            end
        end
        )
    
    return boolResult
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    boolPredecessorSafehouseNearby = preventBuildingNearPreexistingSafehouse()
    if boolPredecessorSafehouseNearby == false then
        StartThread(houseAttach)
        StartThread(drawMapRoom)
        Spring.SetUnitBlocking(unitID, false, false, false)
    else
        StartThread(killDelayed)
    end
    StartThread(healAgentsNearbyCyle)
    setSafeHouseTeamName(unitID)
end

function killDelayed()
    Sleep(1)
    echo("Killing due safehouse being near a predecessor")
    destroyUnitConditional(unitID, false, true)
end

function houseAttach()
    Sleep(GameConfig.safeHouseLiftimeUnattached)
    checkPreExistingKill(unitID, unitID)
    waitTillComplete(unitID)

    boolJustOnce = false
    T = foreach(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange),
    function(id) -- filter out all the safe houses
        if houseTypeTable[Spring.GetUnitDefID(id)] and Spring.GetUnitTeam(id) == gaiaTeamID then return id end
        end, 
    function(houseID)
        if boolJustOnce == true then return end

        if not GG.houseHasSafeHouseTable then GG.houseHasSafeHouseTable = {} end

        --common code
        -- if no previous safe house was attached to this building or the previous attached safehouse has died
        if not GG.houseHasSafeHouseTable[houseID] or
            doesUnitExistAlive(GG.houseHasSafeHouseTable[houseID]) == false then
            boolJustOnce = true
        end

        -- if a previous safehouse is attached
        if GG.houseHasSafeHouseTable[houseID] and  doesUnitExistAlive(GG.houseHasSafeHouseTable[houseID]) then
            enemyTeamID = Spring.GetUnitTeam(GG.houseHasSafeHouseTable[houseID])
            waitTillComplete(GG.houseHasSafeHouseTable[houseID])
            
            if  isUnitComplete(GG.houseHasSafeHouseTable[houseID]) and 
                enemyTeamID ~= myTeamID and 
                not Spring.AreTeamsAllied(myTeamID, enemyTeamID) then
                boolJustOnce = true

                -- Turn everything that comes out of this safehouse into a double agent - if the overbuilt unit is safehouse
                boolIsSafeHouse = safeHouseTypeTable[spGetUnitDefID(GG.houseHasSafeHouseTable[houseID])] ~= nil
                attachDoubleAgentToUnit(unitID ,enemyTeamID, boolIsSafeHouse)
                -- destroy the previous created safehouse
                echo("Previous Safehouse detected")
                Spring.DestroyUnit(GG.houseHasSafeHouseTable[houseID], true, false)
            end
        end

        if boolJustOnce == true then
            echo("Attach House "..houseID .." and make safehouse "..unitID.." mortally dependent" )
            containingHouseID = houseID

            GG.houseHasSafeHouseTable[houseID] = unitID
            StartThread(mortallyDependant, unitID, houseID, 250, false, true)
            moveUnitToUnit(unitID, houseID)
            return houseID
        end
    end)
end

local safeHouseTypes = getSafeHouseTypeTable(UnitDefs)
local houseTypeTable = getHouseTypeTable(UnitDefs, GameConfig.instance.culture)

function checkPreExistingKill(toKillId, notID)
 OtherUpgradeTypesAliveAtLocation =foreach(
                    getAllNearUnit(unitID, 120, myTeam),
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
            echo("Previous Upgrade active - killing the unit")
            Spring.DestroyUnit(toKillId, false, true)
        end
end


function script.Killed(recentDamage, _)
    return 1
end

local function open()
    Signal (SIG_BUILD)
    SetSignalMask (SIG_BUILD)
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
end

local function close()
    Signal (SIG_BUILD)
    SetSignalMask (SIG_BUILD)
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
end


function script.Activate()
    --if  boolDoneFor == true then return 0 end
    StartThread(open)
end

function script.Deactivate()
    -- if not containingHouseID then return 0 end
    StartThread(close)
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

function drawMapRoom()
    Sleep(100)
    hideT(TablesOfPiecesGroups["house"])
    hideT(TablesOfPiecesGroups["SafeHouse"])
    dictSafeHouse_Pos = {}
    dictHouses_Pos = {}

    foreach(Spring.GetAllUnits(), function(id)
        if Spring.GetUnitTeam(id) == gaiaTeamID then return id end
    end, function(id)
        if houseTypeTable[spGetUnitDefID(id)] then
            x, _, z = spGetUnitPosition(id)
            dictHouses_Pos[id] = {x = x / Game.mapSizeX, z = z / Game.mapSizeZ}
        end
    end)

    foreach(Spring.GetAllUnits(), function(id)
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

function healAgentsNearbyCyle()
    lastTimePresent = {}
    while true do
        currentlyPresent = foreach(getAllNearUnit(unitID,120, myTeamID),
            function(id)
                if operativeTypeTable[spGetUnitDefID(id)] and lastTimePresent[id] then
                    hp = Spring.GetUnitHealth(id)
                    Spring.SetUnitHealth(id, hp + 25)
                end
            end
        )
        lastTimePresent = currentlyPresent
        Sleep(1000)
    end
end

