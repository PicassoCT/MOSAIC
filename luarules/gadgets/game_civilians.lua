function gadget:GetInfo()
    return {
        name = "CityInhabitants Behaviour Gadget",
        desc = "Coordinates Traffic ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

local GameConfig = getGameConfig()
--if not Game.version then Game.version = GameConfig.instance.Version end
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame = Spring.GetGameFrame
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitNearestAlly = Spring.GetUnitNearestAlly

local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit

local UnitDefNames = getUnitDefNames(UnitDefs)

local AllCiviliansTypeTable = getCivilianTypeTable(UnitDefs)
local scrapHeapTypeTable = getScrapheapTypeTable(UnitDefs)
local MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
local CivAnimStates = getCivilianAnimationStates()
local PanicAbleCivliansTable = getPanicableCiviliansTypeTable(UnitDefs)
local closeCombatArenaDefID = UnitDefNames["closecombatarena"].id

GG.CivilianTable = {} -- [id ] ={ defID, startNodeID }
GG.UnitArrivedAtTarget = {} -- [id] = true UnitID -- Units report back once they reach this target

local RouteTabel = {} -- Every start has a subtable of reachable nodes 	
local boolInitialized = false

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)
assert(TruckTypeTable)
assert(#TruckTypeTable>0)

local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)
assert(houseTypeTable)
assert(#houseTypeTable>0)

local civilianWalkingTypeTable = getCultureUnitModelTypes(  GameConfig.instance.culture, 
                                                            "civilian", UnitDefs)
assert(civilianWalkingTypeTable)
assert(#civilianWalkingTypeTable>0)

local loadableTruckType = getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local refugeeableTruckType = getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local gaiaTeamID = Spring.GetGaiaTeamID() 
local OpimizationFleeing = {accumulatedCivilianDamage = 0}


function startInternalBehaviourOfState(unitID, name, ...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end

    env = Spring.UnitScript.GetScriptEnv(unitID)

    if env and env.setOverrideAnimationState then
       result= Spring.UnitScript.CallAsUnit(unitID, 
                                     env[name],
                                     arg[1] or nil,
                                     arg[2] or nil,
                                     arg[3] or nil,
                                     arg[4] or nil
                                     )
       assert(result==true, name)
    end
end

function makePasserBysLook(unitID)
    ux, uy, uz = spGetUnitPosition(unitID)
    foreach(getInCircle(unitID, GameConfig.civilian.InterestRadius, gaiaTeamID),
        function(id)
            -- filter out civilians
            if id then
                defID = spGetUnitDefID(id)
                if defID and PanicAbleCivliansTable[defID] then return id end
            end
        end, 
        function(id)
        if math.random(0, 100) > GameConfig.inHundredChanceOfInterestInDisaster then
            offx, offz = math.random(25, 50) * randSign(),
                         math.random(25, 50) * randSign()
            Command(id, "go", {x = ux + offx, y = uy, z = uz + offz}, {})
            -- TODO Set Behaviour filming
            startInternalBehaviourOfState(id, "startFilmLocation", ux,uy,uz, math.random(5000,15000))
        elseif math.random(0, 100) > GameConfig.inHundredChanceOfDisasterWailing then
            offx, offz = math.random(0, 10) * randSign(),
                         math.random(0, 10) * randSign()
            Command(id, "go", {x = ux + offx, y = uy, z = uz + offz}, {})
            startInternalBehaviourOfState(id, "startWailing", math.random(5000,25000))
       end
    end)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    -- if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
    if teamID == gaiaTeamID and attackerID then
        makePasserBysLook(unitID)
        -- other gadgets worries about propaganda price
    end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, attackerID)
    -- if bble
    if teamID == gaiaTeamID and unitDefID == closeCombatArenaDefID then
        makePasserBysLook(unitID)
        -- other gadgets worries about propaganda price
    end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                            weaponID, projectileID, attackerID, attackerDefID,
                            attackerTeam)
    if MobileCivilianDefIds[unitDefID] or TruckTypeTable[unitDefID] or houseTypeTable[unitDefID] then
        OpimizationFleeing.accumulatedCivilianDamage = OpimizationFleeing.accumulatedCivilianDamage + damage

        if not OpimizationFleeing[unitID] then OpimizationFleeing[unitID] = Spring.GetGameFrame() + 30 end

        if attackerID and OpimizationFleeing[unitID] > Spring.GetGameFrame() then
            --Spring.Echo(attackerID .. " attacked civilian "..unitID)
            T = foreach(getInCircle(unitID,  GameConfig.civilian.PanicRadius, gaiaTeamID),
                function(id)
                    if id then
                        defID = spGetUnitDefID(id)
                        if MobileCivilianDefIds[defID] or TruckTypeTable[unitDefID] then
                            return id
                        end
                    end
                end,
                function (id)
                     if not OpimizationFleeing[id] then OpimizationFleeing[id] = Spring.GetGameFrame() + 30 end

                     if OpimizationFleeing[id] > Spring.GetGameFrame()  then
                        startInternalBehaviourOfState(id, "startFleeing", attackerID)
                        OpimizationFleeing[id] = Spring.GetGameFrame() + math.random(15,35)
                     end
                end
                )

            if (MobileCivilianDefIds[unitDefID] and not GG.DisguiseCivilianFor[unitID]) or TruckTypeTable[unitDefID] then
                startInternalBehaviourOfState(unitID, "startFleeing", attackerID)
                OpimizationFleeing[unitID] = Spring.GetGameFrame() + math.random(15,35)
             end       
        end
    end
end

--will not be called with boolInitialized true
function spawnInitialPopulation(frame)  
    -- great Grid of placeable Positions 
    if GG.CitySpawnComplete  then
        issueArrivedUnitsCommands()
        boolInitialized = true
    end
end

function getRandomSpawnNode()
    startNode = randT(RouteTabel)
    if count(RouteTable) == 0 then regenerateRoutesTable() end
    attempts = 0

    while not doesUnitExistAlive(startNode) and attempts < 5 do
        startNode = randT(RouteTabel)
        attempts = attempts + 1
    end
    assert(startNode)

    x, y, z = spGetUnitPosition(startNode)

    return x, y, z, startNode
end

function checkReSpawnPopulation()
    counter = 0
    toDeleteTable = {}
    for id, data in pairs(GG.CivilianTable) do
        if id and civilianWalkingTypeTable[data.defID] then
            if doesUnitExistAlive(id) == true then
                counter = counter + 1
            else
                toDeleteTable[id] = true
            end
        end
    end

    for id, data in pairs(toDeleteTable) do GG.CivilianTable[id] = nil end

    if counter < getNumberOfUnitsAtTime(GameConfig.numberOfPersons) then
        local stepSpawn = math.min(GameConfig.numberOfPersons - counter,
                                   GameConfig.LoadDistributionMax)
        -- echo(counter.. " of "..GameConfig.numberOfPersons .." persons spawned")		

        for i = 1, stepSpawn do
            x, _, z, startNode = getRandomSpawnNode()
            if x and startNode then
                goalNode = RouteTabel[startNode][math.random(1, #RouteTabel[startNode])]
                civilianType = randDict(civilianWalkingTypeTable)
                id = spawnAMobileCivilianUnit(civilianType, x, z, startNode,
                                              goalNode)
            end
        end
    else -- decimate arrived cvilians who are not DisguiseCivilianFor
        decimateArrivedCivilians(absDistance(getNumberOfUnitsAtTime(GameConfig.numberOfPersons), counter), civilianWalkingTypeTable)
    end
end

function attachPayload(payLoadID, id)
    if payLoadID then
       Spring.SetUnitAlwaysVisible(payLoadID,true)
       pieceMap = Spring.GetUnitPieceMap(id)
       assert(pieceMap["attachPoint"], "Truck has no attachpoint")
       Spring.UnitAttach(id, payLoadID, pieceMap["attachPoint"])
       return payLoadID
    end
end

function loadTruck(id, loadType)
    if loadableTruckType[spGetUnitDefID(id)] then
        --Spring.Echo(id .. " is a loadable truck ")
        Spring.Echo("createUnitAtUnit ".."game_civilians.lua")     
        payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)

        return attachPayload(payLoadID, id)
    end
end

function loadRefugee(id, loadType)
    if refugeeableTruckType[spGetUnitDefID(id)] then
        --Spring.Echo(id .. " is a loadable truck ")
        Spring.Echo("createUnitAtUnit ".."game_civilians.lua")   
        payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)
        return attachPayload(payLoadID, id)
    end
end

function checkReSpawnTraffic()
    counter = 0
    toDeleteTable = {}
    for id, data in pairs(GG.CivilianTable) do
        if id and TruckTypeTable[data.defID] then
            if doesUnitExistAlive(id) == true then
                counter = counter + 1
            else
                toDeleteTable[id] = true
            end
        end
    end

    for id, data in pairs(toDeleteTable) do GG.CivilianTable[id] = nil end

    if counter < getNumberOfUnitsAtTime(GameConfig.numberOfVehicles) then
        local stepSpawn = math.min(GameConfig.LoadDistributionMax,
                                   GameConfig.numberOfVehicles - counter)
        -- echo(counter.. " of "..GameConfig.numberOfVehicles .." vehicles spawned")		
        for i = 1, stepSpawn do
            x, _, z, startNode = getRandomSpawnNode()

            goalNode = RouteTabel[startNode][math.random(1,
                                                         #RouteTabel[startNode])]
            TruckType = randDict(TruckTypeTable)
            id = spawnAMobileCivilianUnit(TruckType, x, z, startNode, goalNode)
            if id  then
                loadTruck(id, "truckpayload") 
            end
        end
    else
        decimateArrivedCivilians(absDistance(
                                     getNumberOfUnitsAtTime(
                                         GameConfig.numberOfVehicles), counter),
                                 TruckTypeTable)
    end
end

function getNumberOfUnitsAtTime(value)
    h, m, _, pTime = getDayTime()
    piValue= math.pi * pTime
    mixValue = 0
    if piValue > math.pi*0.25 and  piValue < 0.8* math.pi then
        mixValue = math.sin(piValue)
    end
    blendedFactor = mix(1, GameConfig.nightCivilianReductionFactor, mixValue)
    --		echo("Time:"..h..":"..m.." %:"..pTime.."->"..blendedFactor)
    return value * blendedFactor
end



function buildRouteSquareFromTwoUnits(unitOne, unitTwo, uType)
    local Route = {}

    x1, y1, z1 = spGetUnitPosition(unitOne)
    if doesUnitExistAlive(unitOne) == false then
        x1,y1,z1 = Game.mapSizeX/100 * math.random(10,90), 0, Game.mapSizeZ/100 * math.random(10,90)
    end

    x2, y2, z2 = spGetUnitPosition(unitTwo)
    if not x2 then     x2,y2,z2 = x1 + math.random(100,256)*randSign(), y1, z1 + math.random(100,256)*randSign() end

    index = 1
    Route[index] = {}
    Route[index].x = x1
    Route[index].y = y1
    Route[index].z = z1

    index = index + 1
    Route[index] = {}

    boolLongWay = (distance(x1, y1, z1, x2, y2, z2) > 2048) or maRa()

    if boolLongWay == false then
        if spGetGroundHeight(x1, z2) > 5 then
            Route[index].x = x1
            Route[index].y = spGetGroundHeight(x1,z2)
            Route[index].z = z2

            index = index + 1
            Route[index] = {}
        end
    end

    Route[index].x = x2
    Route[index].y = y2
    Route[index].z = z2

    index = index + 1
    Route[index] = {}

    if boolLongWay == false then
        if spGetGroundHeight(x2, z1) > 5 then
            Route[index].x = x2
            Route[index].y = spGetGroundHeight(x2,z1)
            Route[index].z = z1

            index = index + 1
            Route[index] = {}
        end
    end

    Route[index].x = x1
    Route[index].y = y1
    Route[index].z = z1

    return Route
end

function regenerateRoutesTable()
    local newRouteTabel = {}
    TruckType = randDict(TruckTypeTable)
    assert(TruckType)
    assert(GG.BuildingTable)
    assert(#GG.BuildingTable > 0)
    for thisBuildingID, data in pairs(GG.BuildingTable) do -- [BuildingUnitID] = {x=x, z=z} 
        newRouteTabel[thisBuildingID] = {}
        for otherID, oData in pairs(GG.BuildingTable) do -- [BuildingUnitID] = {x=x, z=z} 		
            if thisBuildingID ~= otherID and
                isRouteTraversable(TruckType, thisBuildingID, otherID) then
                newRouteTabel[thisBuildingID][#newRouteTabel[thisBuildingID] + 1] =
                    otherID
            end
        end
    end
    RouteTabel = newRouteTabel
end

function isRouteTraversable(defID, unitA, unitB)
    vA = getUnitPositionV(unitA)
    vB = getUnitPositionV(unitB)

    path = spRequestPath(UnitDefNames["truck_arab0"].moveDef.id, vA.x, vA.y,
                         vA.z, vB.x, vB.y, vB.z)

    return path ~= nil
end

function getCultureDependentDiretion(culture)
    if culture == "arabic" then return 0 end
    
    return math.max(1, math.floor(math.random(1, 3)))
 end

function spawnUnit(defID, x, z)
    if not x then
        echo("Spawning unit of typ " .. UnitDefs[defID].name ..
                 " with no coords")
    end
    
    dir = getCultureDependentDiretion(GameConfig.instance.culture)
    h = spGetGroundHeight(x, z)
    id = spCreateUnit(defID, x, h, z, dir, gaiaTeamID)

    if id then
        --spSetUnitNoSelect(id, true)
        spSetUnitAlwaysVisible(id, true)
        return id
    end
end

-- truck or Person
function spawnAMobileCivilianUnit(defID, x, z, startID, goalID)
    --ocassionally spawn from arrived car
    if math.random(0,100) > 95 and civilianWalkingTypeTable[defID] and  GG.UnitArrivedAtTarget and # GG.UnitArrivedAtTarget > 0 then
        for id, boolArrived in pairs(GG.UnitArrivedAtTarget) do
            if boolArrived == true and GG.CivilianTable[id].defID and TruckTypeTable[GG.CivilianTable[id].defID] then
                x,_,z = spGetUnitPosition(id)
                break
            end
        end
    end

    id = spawnUnit(defID, x, z)
    if id then
        -- assert(goalID)
        -- assert(startID)
        GG.CivilianTable[id] = {
            defID = defID,
            startID = startID,
            goalID = goalID
        }
        GG.UnitArrivedAtTarget[id] = true
        return id
    end
end


function setUpRefugeeWayPoints()
    if not GG.CivilianEscapePointTable then GG.CivilianEscapePointTable = {} end
    for i = 1,4 do 
        GG.CivilianEscapePointTable[i] = math.random(1,1000)/1000  
    end
end

local startFrame = Spring.GetGameFrame() + 30*5
function gadget:Initialize()
    -- Initialize global tables

    GG.CivilianTable = {}
    GG.DisguiseCivilianFor = {}
    GG.DiedPeacefully = {}
    GG.AerosolAffectedCivilians = {}
    GG.UnitArrivedAtTarget = {}
    GG.TravelFunctionRegistry= {}
    GameConfig = getGameConfig()
    Spring.SetGameRulesParam ( "culture",GameConfig.instance.culture ) 
    startFrame = Spring.GetGameFrame() + 30*5
    setUpRefugeeWayPoints()
end

-----------------------------------------------------------------------------------------------------------------------
-----------------------------  Civilian Behaviour Part  ---------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

function travelInitialization(evtID, frame, persPack, startFrame, myID)
    boolDone = false

    if not myID then
        Spring.Echo("Civilian function has no myID")
        return true, nil, persPack
    end

    if doesUnitExistAlive(myID) == false then 
        return true, nil, persPack
    end

    --update information
    hp, maxHp = spGetUnitHealth(myID)
    if not persPack.myHP then persPack.myHP = hp end
    if hp < maxHp * 0.5 then persPack.boolDamaged = true end

    if persPack.isTruck == nil then persPack.isTruck = TruckTypeTable[spGetUnitDefID(myID)] ~= nil end
    if persPack.isTruck == true then
        if not persPack.hasBreaks then 
            persPack.hasBreaks = maRa() == true
            if  persPack.hasBreaks == true  then 
                persPack.Break= {
                                 startFrame= math.ceil((myID% 100)/100)*GameConfig.daylength + 1, 
                                 lengthFrames = math.random(GameConfig.truckBreakTimeMinSec,GameConfig.truckBreakTimeMaxSec)*30
                                }
            end
        end
    end

    x, y, z = spGetUnitPosition(myID)

    if x and not persPack.currPos then
        persPack.currPos = {x = x, y = y, z = z}
    end

    if not persPack.maxTimeChattingInFrames  then persPack.maxTimeChattingInFrames  = 20 * 30 end
    if not persPack.arrivedDistance  then persPack.arrivedDistance = 300 end
    if not persPack.stuckCounter  then persPack.stuckCounter = 0 end

    --make sure only one instance of this function exists per UnitDefs - newer Ones prefered
    if not GG.TravelFunctionRegistry[myID] then GG.TravelFunctionRegistry[myID] = startFrame end

    if GG.TravelFunctionRegistry[myID] > startFrame then
        return true, nil, persPack, x,y,z, hp
    else
        GG.TravelFunctionRegistry[myID] = startFrame
    end

    if not persPack.boolAnarchy then persPack.boolAnarchy = false end

    -- <External GameState Handling>
    if GG.AerosolAffectedCivilians and GG.AerosolAffectedCivilians[myID] then
        return true, nil, persPack, x,y,z, hp
    end

    if GG.GlobalGameState and 
        GG.GlobalGameState == GameConfig.GameState.normal and
        persPack.boolAnarchy == true then 
        persPack.boolAnarchy = false
    end

    if GG.GlobalGameState and 
        GG.GlobalGameState ~= GameConfig.GameState.normal and 
        not persPack.boolAnarchy  then
        startInternalBehaviourOfState(myID, "startAnarchyBehaviour")
        persPack.boolAnarchy = true
        return true, frame + math.random(30 * 5, 30 * 25), persPack, x,y,z, hp
    end
    -- </External GameState Handling>

    --first move order
    if not persPack.firstTime then 
        persPack.firstTime = true 
        persPack.goalIndex = math.min(persPack.goalIndex + 1, #persPack.goalList)
        persPack = moveToLocation(myID, persPack, {} , true)
    end
    
return boolDone, nil, persPack, x,y,z, hp
end

--1 (x 0, y n)
--2 (x mapSize, y n)
--3 (x n, 0)
--4 (x n, mapSize)

function getEscapePoint(index)
    if index == 1 then return 25,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
    if index == 2 then return Game.mapSizeX,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
    if index == 3 then return GG.CivilianEscapePointTable[index] *Game.mapSizeX, 25 end
    if index == 4 then return GG.CivilianEscapePointTable[index] *Game.mapSizeX, Game.mapSizeZ end
    Spring.Echo("Unknown EscapePoint")
end

function isGoalWarzone(persPack)
    dangerNormalized= GG.DamageHeatMap:getDangerAtLocation(persPack.goalList[persPack.goalIndex].x,persPack.goalList[persPack.goalIndex].z)
    --echo("Is Goal Warzone: danger normalized"..dangerNormalized.. " Heatmap Normalization Value "..GG.DamageHeatMap.normalizationValue)

    boolGoalIsWarzone = dangerNormalized > GameConfig.warzoneValueNormalized and GG.DamageHeatMap.normalizationValue > 5000
    return boolGoalIsWarzone
end

function travelInWarTimes(evtID, frame, persPack, startFrame, myID)
    boolDone = false
 -- avoid combat zones
     if maRa() == true and isGoalWarzone(persPack) and not persPack.boolRefugee then 
        if refugeeableTruckType[spGetUnitDefID(myID)] then
            persPack.boolRefugee = true 
            payloadID = loadTruck(myID, "truckpayloadrefugee")

            Spring.SetUnitTooltip(myID, "Refugee from ".. getCountryByCulture(GameConfig.instance.culture ,getDetermenisticMapHash(Game) + math.random(0,1)*randSign()))
            if payloadID then
                civiliansNearby = foreach(getAllNearUnit(myID, 128),
                                function (id)
                                    defID = spGetUnitDefID(id)
                                    if civilianWalkingTypeTable[defID] and not GG.DisguiseCivilianFor[myID] then
                                        return id
                                    end
                                end
                                )
                if #civiliansNearby > 0 and maRa() == true then
                    id = getRandomElementFromTable(civiliansNearby)
                    if id then
                        map = getPieceMap(payloadID)
                        key,value= randDict(map)
                        Spring.UnitAttach ( payloadID, id,  value ) 
                    end
                end
            end
        end
    end

    --Refugeebehaviour
    if persPack.boolRefugee == true then
    
        --Find known CivilianEscapePointTable (StartPoints) 
        if not persPack.CivilianEscapeIndex then persPack.CivilianEscapeIndex = math.random(1,4) end

        ex,ez = getEscapePoint(persPack.CivilianEscapeIndex)
        ey = spGetGroundHeight(ex,ez)

        if distanceUnitToPoint(myID, ex,ey,ez) < 150 then
            spDestroyUnit(myID, false, true)
            return true, nil, persPack
        else
            Command(id, "go", {x = ex,y = ey,z = ez }, {"shift"})
          return true, frame + math.random(15,45), persPack
        end
     end

    if distanceUnitToPoint(myID, persPack.goalList[persPack.goalIndex].x, persPack.goalList[persPack.goalIndex].y,
                           persPack.goalList[persPack.goalIndex].z) < 150 then
        
        persPack.goalIndex = persPack.goalIndex + 1

        if persPack.goalIndex > #persPack.goalList then
            GG.UnitArrivedAtTarget[myID] = true
            return true, nil, persPack
        end
    end

  return boolDone, frame + 30, persPack
end

function sozialize(evtID, frame, persPack, startFrame, myID)
boolDone = false

  ---ocassionally detour toward the nearest ally or enemy
    if  math.random(0, 42) > 35 and
        civilianWalkingTypeTable[persPack.mydefID] and 
        persPack.maxTimeChattingInFrames > 150  then
            persPack.chatPartnerID = spGetUnitNearestAlly(myID)
            if persPack.chatPartnerID and civilianWalkingTypeTable[spGetUnitDefID(persPack.chatPartnerID)] then 
                persPack.boolStartAChat = true
            end
    end

    if persPack.boolStartAChat == true then
        if (persPack.maxTimeChattingInFrames <= 0 ) or 
            not persPack.chatPartnerID or
             not doesUnitExistAlive(persPack.chatPartnerID) then
                persPack.boolStartAChat = false
                persPack = moveToLocation(myID, persPack, {}, true)
            return true, frame + math.random(15,30), persPack
        end
    end

    if  persPack.boolStartAChat == false then
        persPack.maxTimeChattingInFrames = persPack.maxTimeChattingInFrames + 10
    end

    if persPack.boolStartAChat == true then
        local partnerID = persPack.chatPartnerID 
        if partnerID and distanceUnitToUnit(myID, partnerID) > GameConfig.generalInteractionDistance then
             px, py, pz = spGetUnitPosition(partnerID)
            Command(myID, "go", {x = px, y = py, z = pz}, {})
            Command(partnerID, "go", {
                            x = px + math.random(-20, 20),
                            y = py,
                            z = pz + math.random(-20, 20)
                        }, {})

            return true, frame + 30 , persPack        
        else 
            --stop and chat 
            Command(myID, "stop")
            Command(partnerID, "stop")

            timeChattingInFrames =math.random(GameConfig.minConversationLengthFrames,
                                       GameConfig.maxConversationLengthFrames)
            startInternalBehaviourOfState(myID, "startChatting", timeChattingInFrames*33)
            startInternalBehaviourOfState(partnerID, "startChatting", timeChattingInFrames*33)
            persPack.maxTimeChattingInFrames  = 0
            return true, frame + timeChattingInFrames, persPack
        end
    end  
    return boolDone, nil, persPack
end  



function snychronizedSocialEvents(evtID, frame, persPack, startFrame, myID)
    if  maRa()==true and isPrayerTime() then
        Command(myID, "stop")
        startInternalBehaviourOfState(myID, "startPraying")
        return true, frame + 30, persPack   
    end 

	if GG.SocialEngineeredPeople and GG.SocialEngineeredPeople[myID] and GG.SocialEngineers[GG.SocialEngineeredPeople[myID]] then 
		Command(myID, "stop")
        startInternalBehaviourOfState(myID, "startPeacefullProtest", GG.SocialEngineeredPeople[myID])
		return true, frame + 30, persPack   
	end
	   
    return false, nil, persPack
end  


function stuckDetection(evtID, frame, persPack, startFrame, myID, x, y, z)

    boolDone = false

    if persPack.boolStartAChat and persPack.boolStartAChat == true then 
    return boolDone, nil, persPack
    end 

    if distance(x, y, z, persPack.currPos.x, persPack.currPos.y, persPack.currPos.z) < GameConfig.minimalMoveDistanceElseStuck then
      --  Spring.Echo("Unit "..myID.. "is stuck with counter".. persPack.stuckCounter)
        persPack.stuckCounter = persPack.stuckCounter + 1
    else
        persPack.currPos = {x = x, y = y, z = z}
        persPack.stuckCounter = 0
    end

    -- if stuck move towards the next goal
    if persPack.stuckCounter > 8 then
        if persPack.goalIndex <=  #persPack.goalList then
            persPack.goalIndex = math.min(persPack.goalIndex + 1, #persPack.goalList)
            persPack = moveToLocation(myID, persPack, {})
            persPack.stuckCounter = 0
            return true, frame + math.random(15,35), persPack
        else --reassign new route
            Spring.DestroyUnit(myID, false, true)
            return true, nil, persPack
        end
    end

return boolDone, nil, persPack
end

function moveToLocation(myID, persPack, param, boolOverrideStuckCounter)
 -- only re-issue commands if not moving for a time - prevents repathing frame drop of 15 fps
    if persPack.stuckCounter > 1 or boolOverrideStuckCounter then
        --echo("Givin go Command to "..myID.." goto"..persPack.goalList[persPack.goalIndex].x..","..persPack.goalList[persPack.goalIndex].y..","..persPack.goalList[persPack.goalIndex].z)
        local params = param or {}

        Command(myID, "go", {
            x = math.ceil(persPack.goalList[persPack.goalIndex].x),
            y = math.ceil(persPack.goalList[persPack.goalIndex].y),
            z = math.ceil(persPack.goalList[persPack.goalIndex].z)
        }, params)
    end
    return persPack
end

function travelInPeaceTimes(evtID, frame, persPack, startFrame, myID)
    boolDone = false

    if  persPack.isTruck == true and persPack.hasBreaks == true then
        if  persPack.Break.startFrame < frame and 
            frame < persPack.Break.startFrame + persPack.Break.lengthFrames  then
            --Just stand there like a idiot
            return boolDone, nil, persPack
        end
        --schedule next break
        if  persPack.Break.startFrame < frame and 
            frame > persPack.Break.startFrame + persPack.Break.lengthFrames  then
            --compute new break time
            persPack.Break.lengthFrames = math.random(GameConfig.truckBreakTimeMinSec, GameConfig.truckBreakTimeMaxSec)*30
            persPack.Break.startFrame = frame + math.random(1000, GameConfig.daylength)
        end
    end

    -- if near Destination increase goalIndex
    if distanceUnitToPoint(myID, persPack.goalList[persPack.goalIndex].x, persPack.goalList[persPack.goalIndex].y,
                           persPack.goalList[persPack.goalIndex].z) < 100 then

        if persPack.boolDamaged == true and maRa() == true then persPack.boolTraumatized = true end
        
        persPack.goalIndex = persPack.goalIndex + 1
        if persPack.goalIndex > #persPack.goalList then
            GG.UnitArrivedAtTarget[myID] = true
            return true, nil, persPack
        else
            persPack = moveToLocation(myID, persPack, {}, true)
        end
    end

    return boolDone, nil, persPack
end

function unitInternalLogic(evtID, frame, persPack, startFrame, myID)
    if not GG.CivilianUnitInternalLogicActive then GG.CivilianUnitInternalLogicActive = {} end

    if GG.CivilianUnitInternalLogicActive[myID] then
        if GG.CivilianUnitInternalLogicActive[myID] == "STARTED" then
            return true, frame + 15, persPack
        end

        if GG.CivilianUnitInternalLogicActive[myID] == "ENDED" then
            Command(myID, "go", {
                x = math.ceil(persPack.goalList[persPack.goalIndex].x),
                y = math.ceil(persPack.goalList[persPack.goalIndex].y),
                z = math.ceil(persPack.goalList[persPack.goalIndex].z)
            }, {})

            GG.CivilianUnitInternalLogicActive[myID] = nil
            return true, frame + 15, persPack
        end
    end

    return false, nil, persPack
end

function travellFunction(evtID, frame, persPack, startFrame)
    --  only apply if Unit is still alive
    local myID = persPack.unitID

    boolDone, retFrame, persPack, x,y,z, hp = travelInitialization(evtID, frame, persPack, startFrame, myID)
    if boolDone == true then return retFrame,persPack end

    boolDone, retFrame, persPack = unitInternalLogic(evtID, frame, persPack, startFrame, myID)
    if boolDone == true then return retFrame,persPack end

   boolDone, retFrame, persPack = snychronizedSocialEvents(evtID, frame, persPack, startFrame, myID)
    if boolDone == true then return retFrame,persPack end    

    boolDone, retFrame, persPack = sozialize(evtID, frame, persPack, startFrame, myID)
    if boolDone == true then return retFrame,persPack end

    boolDone, retFrame, persPack = stuckDetection(evtID, frame, persPack, startFrame, myID, x, y, z)
    if boolDone == true then return retFrame,persPack end

    if GG.GlobalGameState ~= GameConfig.GameState.normal or persPack.boolTraumatized then
        boolDone, retFrame, persPack = travelInWarTimes(evtID, frame, persPack, startFrame, myID)
        if boolDone == true then return retFrame,persPack end
    else
        boolDone, retFrame, persPack = travelInPeaceTimes(evtID, frame, persPack, startFrame, myID)
        if boolDone == true then return retFrame,persPack end
    end

    return frame + math.random(60, 90), persPack
end

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

function getTargetNodeInWalkingDistance(startNodeID, defaultTargetNode)
    assert(startNodeID)
    assert(doesUnitExistAlive(startNodeID)==true, "Unit is dead")
    local listOfTargetNodes = RouteTabel[startNodeID]
    assert(#listOfTargetNodes > 0)
    local listInRange = {}
    if #listOfTargetNodes == 0  then return defaultTargetNode end
    if #listOfTargetNodes == 1 then return listOfTargetNodes[1] end

    for i=1, #listOfTargetNodes do
        if distanceUnitToUnit(startNodeID, listOfTargetNodes[i]) < GameConfig.civilian.MaxWalkingDistance then
            listInRange[#listInRange + 1 ]= listOfTargetNodes[i]
        end
    end

    nrOfTargetsInRange = #listInRange
    if nrOfTargetsInRange == 0 then return defaultTargetNode end
    if nrOfTargetsInRange == 1 then return listInRange[1] end
    if nrOfTargetsInRange > 1 then 
        index = math.random(1,#listInRange)
        return listInRange[index] 
    end

return defaultTargetNode
end

function giveWaypointsToUnit(uID, uType, startNodeID)
    boolShortestPath = maRa() or not TruckTypeTable[uType]  -- direct route to target

    index = math.random(2, #RouteTabel[startNodeID])
    targetNodeID =  RouteTabel[startNodeID][index]

    if civilianWalkingTypeTable[uType] then
        targetNodeID = getTargetNodeInWalkingDistance(startNodeID, targetNodeID)
    end

    if startNodeID and targetNodeID then
   --     Spring.Echo("game_civilians:giveWaypointsToUnit:".. uID)
        GG.EventStream:CreateEvent(travellFunction, { -- persistance Pack
            mydefID = uType,
            myTeam = spGetUnitTeam(uID),
            unitID = uID,
            goalIndex = 1,
            goalList = buildRouteSquareFromTwoUnits(startNodeID,
                                                    targetNodeID,
                                                    uType)
        }, spGetGameFrame() + (uID % 100))
    end
end

function testClampRoute(Route, defID) return Route end

function issueArrivedUnitsCommands()
    for id, bArrived in pairs(GG.UnitArrivedAtTarget) do
        if id and GG.CivilianTable[id] and
            doesUnitExistAlive(GG.CivilianTable[id].startID) == true and
            doesUnitExistAlive(id) then
            giveWaypointsToUnit(id, GG.CivilianTable[id].defID,
                                GG.CivilianTable[id].startID)
        end
    end
    GG.UnitArrivedAtTarget = {}
end

function decimateArrivedCivilians(nrToDecimate, typeTable)
    nrToDecimate = math.floor(nrToDecimate)
    -- echo("Decimation called"..nrToDecimate)
    if nrToDecimate <= 0 then return end

    for id, bArrived in pairs(GG.UnitArrivedAtTarget) do
        if id and GG.CivilianTable[id] and
            doesUnitExistAlive(GG.CivilianTable[id].startID) == true and
            doesUnitExistAlive(id) == true and 
            GG.DisguiseCivilianFor[id] == nil and
            typeTable[GG.CivilianTable[id].defID] then
            spDestroyUnit(id, false, true)
            --echo("Killing Unit:"..id)
            if doesUnitExistAlive(id) == false then
                GG.UnitArrivedAtTarget[id] = nil
                nrToDecimate = nrToDecimate - 1
            end
            if nrToDecimate <= 0 then return end
        end
    end
end

function gadget:GameFrame(frame)
    if boolInitialized == false then
        --echo("Intialization GameFrame")
        spawnInitialPopulation(frame)
    elseif boolInitialized == true and frame > 0 and frame % 5 == 0 then
               -- Check number of Units	
        if frame % 30 == 0 and frame > startFrame then checkReSpawnPopulation() end

        if frame % 55 == 0 and frame > startFrame then checkReSpawnTraffic() end

        issueArrivedUnitsCommands()   
    end

    OpimizationFleeing.accumulatedCivilianDamage = math.max(0, OpimizationFleeing.accumulatedCivilianDamage  - 1)
end


