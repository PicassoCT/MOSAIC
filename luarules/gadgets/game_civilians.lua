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

if not gadgetHandler:IsSyncedCode() then
    local function receiveConversation(_, speaker, partner, text, duration)
        if Script.LuaUI("CivilianConversation") then
            Script.LuaUI.CivilianConversation(speaker, partner, text, duration)
        end
    end
    function gadget:Initialize()
        gadgetHandler:AddSyncAction("CivilianConversation", receiveConversation)
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("CivilianConversation")
    end
    return
end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_debug.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_staticstring.lua")

local GameConfig = getGameConfig()
--if not Game.version then Game.version = GameConfig.game.version end
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
local scrapHeapTypeTable = getBuildingScrapHeapTypeTable(UnitDefs)
local MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
local CivAnimStates = getCivilianAnimationStates()
local PanicAbleCivliansTable = getPanicableCiviliansTypeTable(UnitDefs)

local closeCombatArenaDefID = UnitDefNames["closecombatarena"].id

GG.BusesTable = GG.BusesTable or {}
GG.CivilianTable = {} -- [id ] ={ defID, startNodeID }
GG.UnitArrivedAtTarget = {} -- [id] = true UnitID -- Units report back once they reach this target
GG.CivilianUnitInternalLogicActive = {} -- {string state, string behaviour}

local RouteTabel = {} -- Every start has a subtable of reachable nodes 	
local boolInitialized = false

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.game.culture,
                                                "truck", UnitDefs)
assert(TruckTypeTable, toString("gameCivilians:",TruckTypeTable))
--assert(count(TruckTypeTable) > 0, toString("gameCivilians:",TruckTypeTable))

local houseTypeTable = getCultureUnitModelTypes(GameConfig.game.culture,
                                                "house", UnitDefs)

assert(houseTypeTable)
assert(count(houseTypeTable) > 0)

local civilianWalkingTypeTable = getCultureUnitModelTypes(  GameConfig.game.culture,
                                                            "civilian", UnitDefs)

local individualNamedTypes = getIndividualCulturalNamedTypes(UnitDefs)
assert(civilianWalkingTypeTable)
assert(count(civilianWalkingTypeTable) > 0)

local loadableTruckType = getLoadAbleTruckTypes(UnitDefs, GameConfig.game.culture)
--echo("Loadable TruckTypes: ".. toString(loadableTruckType))
local refugeeableTruckType = getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.game.culture)
local gaiaTeamID = Spring.GetGaiaTeamID() 
local OpimizationFleeing = {accumulatedCivilianDamage = 0}
local chanceOfCivilianSpawningFromTruck = GameConfig.civilians.traffic.passengerSpawnChance
local newCivilianLife = VFS.Include("luarules/gadgets/include/civilian_daily_life.lua")
local civilianLife = newCivilianLife({gameConfig=GameConfig, walkers=civilianWalkingTypeTable, trucks=TruckTypeTable, raining=isRaining})
GG.CivilianLife = civilianLife
local lastDangerReport = {}


function startInternalBehaviourOfState(unitID, name, ...)
    if not GG.CivilianUnitInternalLogicActive then
        GG.CivilianUnitInternalLogicActive = {}
    end

    local internalState = GG.CivilianUnitInternalLogicActive[unitID]
    local state = internalState
    if type(internalState) == "table" then
        state = internalState.state
    end
    if state == GameConfig.civilians.activityStates.started then
        if name ~= "startFleeing" and name ~= "startAnarchyBehaviour" then return false end
        if type(internalState)=="table" and internalState.behaviour=="aerosol" then return false end
        civilianLife:Interrupt(unitID)
    end

    local args = {...}
    local env = Spring.UnitScript.GetScriptEnv(unitID)
    if env and env[name] then
        return Spring.UnitScript.CallAsUnit(unitID,
                                            env[name],
                                            args[1],
                                            args[2],
                                            args[3],
                                            args[4])
    end

    return false
end

function callInternalFunction(unitID, name)
    local env = Spring.UnitScript.GetScriptEnv(unitID)

    if env and env[name] then
       return Spring.UnitScript.CallAsUnit(unitID, 
                                     env[name]                                     )
    end
end

function makePasserBysLook(unitID)
    ux, uy, uz = spGetUnitPosition(unitID)
    foreach(getInCircle(unitID, GameConfig.civilians.curiosity.radius, gaiaTeamID),
        function(id)
            -- filter out civilians
            if id then
                defID = spGetUnitDefID(id)
                if defID and PanicAbleCivliansTable[defID] then return id end
            end
        end, 
        function(id)
        if math.random(0, 100) > GameConfig.civilians.curiosity.disasterInterestPercent then
            offx, offz = math.random(25, 50) * randSign(),
                         math.random(25, 50) * randSign()
            Command(id, "go", {x = ux + offx, y = uy, z = uz + offz}, {})
            -- TODO Set Behaviour filming
            filmingDurationMs = math.random(5000,15000)
            startInternalBehaviourOfState(id, "startFilmLocation", ux,uy,uz, filmingDurationMs)
        elseif math.random(0, 100) > GameConfig.civilians.curiosity.disasterWailingPercent then
            offx, offz = math.random(0, 10) * randSign(),
                         math.random(0, 10) * randSign()
            Command(id, "go", {x = ux + offx, y = uy, z = uz + offz}, {})
            wailDurationMs = math.random(5000,25000)
            startInternalBehaviourOfState(id, "startWailing",wailDurationMs)
       end
    end)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    civilianLife:UnitDestroyed(unitID, attackerID)
    lastDangerReport[unitID] = nil
    if GG.AerosolAffectedCivilians then GG.AerosolAffectedCivilians[unitID] = nil end
    if GG.TollWutoxAfflicted then GG.TollWutoxAfflicted[unitID] = nil end
	if GG.BusesTable and GG.BusesTable[unitID] then
	   GG.BusesTable[unitID] =  nil
	end
    -- if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
    if teamID == gaiaTeamID and attackerID then
        makePasserBysLook(unitID)
        -- other gadgets worries about propaganda price
    end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, attackerID)
    civilianLife:UnitCreated(unitID, unitDefID)
    -- if bble
    if teamID == gaiaTeamID and unitDefID == closeCombatArenaDefID then
        makePasserBysLook(unitID)
        -- other gadgets worries about propaganda price
    end
  
    if individualNamedTypes[unitDefID] then
        name = setIndividualCivilianName(unitID, GG.GameConfig.game.culture, UnitDefs)
    end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                            weaponID, projectileID, attackerID, attackerDefID,
                            attackerTeam)
    if damage and damage > 0 and (MobileCivilianDefIds[unitDefID] or TruckTypeTable[unitDefID] or houseTypeTable[unitDefID]) then
        local frame = Spring.GetGameFrame()
        if frame >= (lastDangerReport[unitID] or 0) then
            lastDangerReport[unitID] = frame + 30
            civilianLife:ReportDanger(unitID, damage)
        end
        OpimizationFleeing.accumulatedCivilianDamage = OpimizationFleeing.accumulatedCivilianDamage + damage

        if not OpimizationFleeing[unitID] then OpimizationFleeing[unitID] = 0 end

        if attackerID and OpimizationFleeing[unitID] <= Spring.GetGameFrame() then
            --Spring.Echo(attackerID .. " attacked civilian "..unitID)
            T = foreach(getInCircle(unitID,  GameConfig.civilians.panic.radius, gaiaTeamID),
                function(id)
                    if id then
                        defID = spGetUnitDefID(id)
                        if TruckTypeTable[defID] then
                            return id
                        end
                    end
                end,
                function (id)
                     if not OpimizationFleeing[id] then OpimizationFleeing[id] = 0 end

                     if OpimizationFleeing[id] <= Spring.GetGameFrame() then
                        startInternalBehaviourOfState(id, "startFleeing", attackerID)
                        OpimizationFleeing[id] = Spring.GetGameFrame() + math.random(15,35)
                     end
                end
                )

            if TruckTypeTable[unitDefID] then
                startInternalBehaviourOfState(unitID, "startFleeing", attackerID)
                OpimizationFleeing[unitID] = Spring.GetGameFrame() + math.random(15,35)
             end       
        end
    end
end

--will not be called with boolInitialized true
function spawnInitialPopulation(frame)  
    -- great Grid of placeable Positions 
    --Spring.Echo("spawnInitialPopulation reached")
    if GG.CitySpawnComplete and GG.CitySpawnComplete == true then
        --Spring.Echo("spawnInitialPopulation began")
        regenerateRoutesTable()
        checkReSpawnPopulation()
        issueArrivedUnitsCommands()

        boolInitialized = true
        --Spring.Echo("spawnInitialPopulation completed")
    end
end

function getRandomSpawnNode()

    startNode = randT(RouteTabel)
    
    attempts = 0

    while not doesUnitExistAlive(startNode) and attempts < 5 do
        startNode = randT(RouteTabel)
        attempts = attempts + 1
    end
    if not startNode then return nil end
    if type(startNode) ~= "number" then echo("StartNode is not a numb :",startNode) end
    x, y, z = spGetUnitPosition(startNode)

    return x, y, z, startNode
end

temporaryStoppedTilFrame = {}
function checkResetTemporaryStopped(frame)
    local temporaryCopy = temporaryStoppedTilFrame
    for id, endFrame in pairs(temporaryCopy) do
        if endFrame and frame > endFrame then
            if doesUnitExistAlive(id) then setSpeedEnv(id, 1.0) end
            temporaryStoppedTilFrame[id] = nil
        end
    end
end


function setTemporaryStopped(busId)
    setSpeedEnv(busId, 0.0)
    temporaryStoppedTilFrame[busId] = spGetGameFrame() + 3 * 30
end

function checkReSpawnPopulation()
    counter = 0
    toDeleteTable = {}
    --assertTable(GG.CivilianTable)
    for id, data in pairs(GG.CivilianTable) do
        if id and civilianWalkingTypeTable[data.defID] then
            if doesUnitExistAlive(id) == true then
                counter = counter + 1
            else
                toDeleteTable[id] = true
            end
        end
    end
    --assertTable(toDeleteTable)
    for id, data in pairs(toDeleteTable) do GG.CivilianTable[id] = nil end

    if counter < getNumberOfUnitsAtTime(GameConfig.city.population.persons) then
        local stepSpawn = math.min(GameConfig.city.population.persons - counter,
                                   GameConfig.performance.civilianBatchSize)
        -- --echo(counter.. " of "..GameConfig.city.population.persons .." persons spawned")
        --assertType(RouteTabel, "table")
        for i = 1, stepSpawn do
            x, _, z, startNode = getRandomSpawnNode()
            --assert(x > 0 and x < Game.mapSizeX, x)
            --assert(z > 0 and z < Game.mapSizeZ, z)
            if x and startNode and RouteTabel[startNode] and #RouteTabel[startNode] > 0 then
                goalNode = getSafeRandom(RouteTabel[startNode], RouteTabel[startNode][1])
                civilianType = randDict(civilianWalkingTypeTable)
                local vehicle = civilianLife:VehicleOrigin(spGetGameFrame())
                if vehicle then
                    local vx, _, vz = spGetUnitPosition(vehicle)
                    local side = vehicle % 2 == 0 and 1 or -1
                    local px, pz = vx + side * 48, vz + 24
                    local py = spGetGroundHeight(px,pz)
                    if py >= 0 and Spring.TestMoveOrder(civilianType,px,py,pz) then x,z=px,pz
                    else vehicle=nil end
                end
                id = spawnAMobileCivilianUnit(civilianType, x, z, startNode, goalNode)
                if id and vehicle then civilianLife:SpawnedFromVehicle(id,vehicle) end
            else
               --echo("game_civilans: Found no startnode.")
               regenerateRoutesTable()
            end
        end
    else -- decimate arrived cvilians who are not DisguiseCivilianFor
        decimateArrivedCivilians(absDistance(getNumberOfUnitsAtTime(GameConfig.city.population.persons), counter), civilianWalkingTypeTable)
    end
end

function attachPayload(payLoadID, id)
    if payLoadID then
        --echo("checkReSpawnTraffic2.65")
       Spring.SetUnitAlwaysVisible(payLoadID, true)
       pieceMap = Spring.GetUnitPieceMap(id)

       --assert(type(pieceMap["attachPoint"]) == "number", "Truck has no attachpoint")
       Spring.UnitAttach(id, payLoadID, pieceMap["attachPoint"])

       return payLoadID
    else
        Spring.Echo("Not a valid payload")
    end
end

function loadTruck(id, loadType)
            --echo("checkReSpawnTraffic2.61")
    if loadableTruckType[spGetUnitDefID(id)] then
        --echo("checkReSpawnTraffic2.62")
        --Spring.Echo("createUnitAtUnit ".."game_civilians.lua")     
        payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)
        --echo("checkReSpawnTraffic2.63")
        if payLoadID then
            --echo("checkReSpawnTraffic2.64")
            return attachPayload(payLoadID, id)
        end
    end
end

function loadRefugee(id, loadType)
    if refugeeableTruckType[spGetUnitDefID(id)] then
        --Spring.Echo("createUnitAtUnit ".."game_civilians.lua")   
        payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)
        if payLoadID then 
            return attachPayload(payLoadID, id)
        end
    end
end

function checkReSpawnTraffic()
    ----echo("checkReSpawnTraffic1")
    counter = 0
    toDeleteTable = {}
    if GG.CivilianTable then
        --assertTable(GG.CivilianTable)
        for id, data in pairs(GG.CivilianTable) do
            if id and TruckTypeTable[data.defID] then
                if doesUnitExistAlive(id) == true then
                    counter = counter + 1
                else
                    toDeleteTable[id] = true
                end
            end
        end
    end
    ----echo("checkReSpawnTraffic2")
    --assertTable(toDeleteTable)
    for id, data in pairs(toDeleteTable) do GG.CivilianTable[id] = nil end
      ----echo("checkReSpawnTraffic2.1")
    if counter < getNumberOfUnitsAtTime(GameConfig.city.population.vehicles) then
        local stepSpawn = math.min(GameConfig.performance.civilianBatchSize,
                                   GameConfig.city.population.vehicles - counter)
        ----echo("checkReSpawnTraffic2.2")
        -- --echo(counter.. " of "..GameConfig.city.population.vehicles .." vehicles spawned")
        for i = 1, stepSpawn do
            ----echo("checkReSpawnTraffic2.3")
            x, _, z, startNode = getRandomSpawnNode()
            if startNode then
                ----echo("checkReSpawnTraffic2.4")
                goalNode = RouteTabel[startNode][math.random(1, #RouteTabel[startNode])]
                --assertTable(TruckTypeTable)
                TruckType = randDict(TruckTypeTable)
                --echo("checkReSpawnTraffic2.5")
                id = spawnAMobileCivilianUnit(TruckType, x, z, startNode, goalNode)
                if id  then
                  --  --echo("calling truck loading")
                    --echo("checkReSpawnTraffic2.6")
                    loadTruck(id, "truckpayload")
                      --echo("checkReSpawnTraffic2.7")
                end
            end
        end
    else
        ----echo("checkReSpawnTraffic2.8")
        --assertTable(TruckTypeTable)
        decimateArrivedCivilians(absDistance( getNumberOfUnitsAtTime(GameConfig.city.population.vehicles), counter), TruckTypeTable)
          ----echo("checkReSpawnTraffic2.9")
    end
    ----echo("checkReSpawnTraffic3")
end

function getNumberOfUnitsAtTime(value)
    h, m, _, pTime = getDayTime()
    piValue= math.pi * pTime
    mixValue = 0
    if piValue > math.pi*0.25 and  piValue < 0.8* math.pi then
        mixValue = math.sin(piValue)
    end
    blendedFactor = mix(1, GameConfig.civilians.population.nightReductionFactor, mixValue)
    --		--echo("Time:"..h..":"..m.." %:"..pTime.."->"..blendedFactor)
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
    -- Spring.Echo("Regenerating Routes Tabel")
    local newRouteTabel = {}
    TruckType = randDict(TruckTypeTable)

    if count(GG.BuildingTable) < 2 then 
        echo("regenerateRoutesTable no buildings");
        RouteTabel = newRouteTabel; 
        return 
    end
    for thisBuildingID, data in pairs(GG.BuildingTable) do -- [BuildingUnitID] = {x=x, z=z} 
        --echo("regenerateRoutesTable1")
        newRouteTabel[thisBuildingID] = {}
        for otherID, oData in pairs(GG.BuildingTable) do -- [BuildingUnitID] = {x=x, z=z} 		
            if thisBuildingID ~= otherID and isRouteTraversable(TruckType, thisBuildingID, otherID) then
                --echo("regenerateRoutesTable2")
                newRouteTabel[thisBuildingID][#newRouteTabel[thisBuildingID] + 1] = otherID
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
        --echo("Spawning unit of typ " .. UnitDefs[defID].name ..                 " with no coords")
    end
    
    dir = getCultureDependentDiretion(GameConfig.game.culture)
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
        if civilianWalkingTypeTable[defID] then civilianLife:Register(id,startID) end
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
    Spring.SetGameRulesParam ( "culture",GameConfig.game.culture )
    startFrame = Spring.GetGameFrame() + 30*5
    setUpRefugeeWayPoints()
    GG.CivilianLife = civilianLife
    local units = Spring.GetAllUnits(); table.sort(units)
    for _, id in ipairs(units) do civilianLife:UnitCreated(id,spGetUnitDefID(id)) end
end

function gadget:Shutdown() civilianLife:Shutdown() end

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
                                 startFrame= math.ceil((myID% 100)/100)*GameConfig.game.dayLengthFrames + 1,
                                 lengthFrames = math.random(GameConfig.civilians.traffic.truckBreakMinSeconds,GameConfig.civilians.traffic.truckBreakMaxSeconds)*30
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
        GG.GlobalGameState == GameConfig.game.states.normal and
        persPack.boolAnarchy == true then 
        persPack.boolAnarchy = false
    end

    if GG.GlobalGameState and 
        GG.GlobalGameState ~= GameConfig.game.states.normal and
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
    local goal = persPack.goalList[persPack.goalIndex]
    return goal and GG.CityAreaState and GG.CityAreaState:IsDangerous(goal.x, goal.z) or false
end

function travelInWarTimes(evtID, frame, persPack, startFrame, myID)
    boolDone = false
 -- avoid combat zones
     if maRa() == true and isGoalWarzone(persPack) and not persPack.boolRefugee then 
        if refugeeableTruckType[spGetUnitDefID(myID)] then
            persPack.boolRefugee = true 
            Spring.SetUnitTooltip(myID, "Refugee from ".. getCountryByCulture(GameConfig.game.culture ,getDetermenisticMapHash(Game) + math.random(0,1)*randSign()))
            payloadID = loadTruck(myID, "truckpayloadrefugee")
         
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
            Command(myID, "go", {x = ex,y = ey,z = ez }, {})
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

function displayConversationTextAt(idA, idB)
    civilianLife:Conversation(idA,idB,20*30)
end

function getUnitNearestTalkableAlly(id)
    local resultUnits =
    foreach(getAllNearUnit(id,  GameConfig.civilians.conversation.range, gaiaTeamID  ),
        function(ad)
            defID = spGetUnitDefID(ad)
            if ad ~= id and civilianWalkingTypeTable[defID] and civilianLife:CanSocialize(ad) then
                return ad
            end
        end
        )
    table.sort(resultUnits)
    if #resultUnits > 0 then return resultUnits[math.random(1,#resultUnits)] end
    return nil
end

function sozialize(evtID, frame, persPack, startFrame, myID)
    boolDone = false
    if not civilianLife:CanSocialize(myID) then return false,nil,persPack end

  ---ocassionally detour toward the nearest ally or enemy
    if randChance(80) and
        civilianWalkingTypeTable[persPack.mydefID] and 
        persPack.maxTimeChattingInFrames > 150  then  
           --[[ --echo("Soizialize with partnerID ")--]]
            persPack.chatPartnerID = getUnitNearestTalkableAlly(myID)
            if persPack.chatPartnerID then                
--                echo(myID.." starting a chat with "..persPack.chatPartnerID.. " at "..locationstring(myID)) 
                persPack.boolStartAChat = true
                persPack.boolDeactivateStuckDetection = true             
            end
    end

    if persPack.boolStartAChat == true then 
        if (persPack.maxTimeChattingInFrames <= 0 ) or -- end a chat
            not persPack.chatPartnerID or
            not doesUnitExistAlive(persPack.chatPartnerID) then
                --echo(myID.." chat has ended")
                persPack.boolStartAChat = false
                persPack.boolDeactivateStuckDetection = false
                persPack = moveToLocation(myID, persPack, {}, true)
            return true, frame + math.random(15,30), persPack
        end
    end

    if  persPack.boolStartAChat == false then
        persPack.maxTimeChattingInFrames = persPack.maxTimeChattingInFrames + 10
    end

    if persPack.boolStartAChat == true and persPack.chatPartnerID then
        local partnerID = persPack.chatPartnerID 
        if not civilianLife:CanSocialize(partnerID) then
            persPack.boolStartAChat=false
            persPack.boolDeactivateStuckDetection=false
            persPack=moveToLocation(myID,persPack,{},true)
            return true,frame+30,persPack
        end
        if distanceUnitToUnit(myID, partnerID) > GameConfig.civilians.conversation.range then
            --echo(myID.." moving to chat ")
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
          --echo(myID.." chatting at "..locationstring(partnerID))
            Command(myID, "stop")
            Command(partnerID, "stop")
            -- Readiness controls when to chat, not how long the conversation lasts.
            -- Bias toward shorter chats without ever going below the minimum.
            local timeChattingInFrames = GameConfig.civilians.conversation.minDurationFrames + math.floor(
                (GameConfig.civilians.conversation.maxDurationFrames - GameConfig.civilians.conversation.minDurationFrames) *
                math.random() * math.random() + 0.5)
            local timeChattingInMs = frameToMs(timeChattingInFrames)
            startInternalBehaviourOfState(myID, "startChatting", timeChattingInMs, partnerID)
            startInternalBehaviourOfState(partnerID, "startChatting", timeChattingInMs, myID)
            civilianLife:Conversation(myID,partnerID,timeChattingInFrames)
            persPack.maxTimeChattingInFrames  = 0
            -- Polling remains cheap and lets danger interrupt long conversations.
            return true, frame + 15, persPack
        end    
    end
    return boolDone, nil, persPack
end  


function snychronizedSocialEvents(evtID, frame, persPack, startFrame, myID)
    local prayerSlot = getPrayerSlot(frame)
    local prayerCall = GG.ActivePrayerCall
    if prayerSlot and prayerCall and prayerCall.slot == prayerSlot and civilianWalkingTypeTable[persPack.mydefID] and
       persPack.lastPrayerSlot ~= prayerSlot then
        -- Decide once per civilian and prayer window. A failed roll must not
        -- be retried every event-stream tick throughout the same window.
        persPack.lastPrayerSlot = prayerSlot
        if maRa() and startInternalBehaviourOfState(myID, "startPraying", prayerCall.index) then
            Command(myID, "stop")
            persPack.deactivateStuckDetectionValue = 0
            return true, frame + 1, persPack
        end
    end

    if GG.SocialEngineeredPeople and GG.SocialEngineeredPeople[myID] and GG.SocialEngineers[GG.SocialEngineeredPeople[myID]] then
        Command(myID, "stop")
        persPack.deactivateStuckDetectionValue = -10
        startInternalBehaviourOfState(myID, "startPeacefullProtest", GG.SocialEngineeredPeople[myID])
        return true, frame + 1, persPack
    end

    return false, nil, persPack
end

local metaStuckDetection = {}
function resetStuckDetection(myID, persPack, waitValue)
    persPack.stuckCounter = waitValue
    metaStuckDetection[myID] = 0
    return persPack
end
function stuckDetection(evtID, frame, persPack, startFrame, myID, x, y, z)

    boolDone = false

    if persPack.boolDeactivateStuckDetection then
        return boolDone, nil, persPack
    end

    if persPack.deactivateStuckDetectionValue and persPack.deactivateStuckDetectionValue ~= 0 then
        persPack = resetStuckDetection(myID, persPack, persPack.deactivateStuckDetectionValue)
        persPack.deactivateStuckDetectionValue = 0
        return boolDone, nil, persPack
    end

    if persPack.boolStartAChat and persPack.boolStartAChat == true then 
    return boolDone, nil, persPack
    end 

    if distance(x, y, z, persPack.currPos.x, persPack.currPos.y, persPack.currPos.z) < GameConfig.civilians.movement.minProgressDistance then
        persPack.stuckCounter = persPack.stuckCounter + 1
    else
        persPack.currPos = {x = x, y = y, z = z}
        persPack.stuckCounter = 0
    end

    -- if stuck move towards the next goal
    if persPack.stuckCounter > 12 then
        if not metaStuckDetection[myID] then metaStuckDetection[myID] = 0 end
        metaStuckDetection[myID] = metaStuckDetection[myID] +1

        if persPack.goalIndex <=  #persPack.goalList and metaStuckDetection[myID] < 3 then
            persPack.goalIndex = math.min(persPack.goalIndex + 1, #persPack.goalList)
            persPack = moveToLocation(myID, persPack, {})
            persPack.stuckCounter = 0
            --Spring.Echo(myID.." :Help me stepbro im stuck and will goto a different place at " .. locationstring(myID))
            return true, frame + math.random(15,35), persPack
        else --reassign new route
            --Spring.Echo(myID.." :Help me stepbro im fucked at " .. locationstring(myID))
            if civilianLife:IsProtected(myID) then
                persPack.stuckCounter=0
                metaStuckDetection[myID]=0
                persPack=moveToLocation(myID,persPack,{},true)
                return true,frame+90,persPack
            end
            Spring.DestroyUnit(myID, false, true)
            metaStuckDetection[myID] = nil
            return true, nil, persPack
        end
    end

return boolDone, nil, persPack
end

function moveToLocation(myID, persPack, param, boolOverrideStuckCounter)
 -- only re-issue commands if not moving for a time - prevents repathing frame drop of 15 fps
    if persPack.stuckCounter > 1 or boolOverrideStuckCounter then
        ----echo("Givin go Command to "..myID.." goto"..persPack.goalList[persPack.goalIndex].x..","..persPack.goalList[persPack.goalIndex].y..","..persPack.goalList[persPack.goalIndex].z)
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
            ----echo(myID.." is on a break for "..((persPack.Break.startFrame + persPack.Break.lengthFrames -frame)/30).." seconds")
            --Just stand there like a idiot
            return boolDone, nil, persPack
        end
        --schedule next break
        if  persPack.Break.startFrame < frame and 
            frame > persPack.Break.startFrame + persPack.Break.lengthFrames  then
            --compute new break time
            persPack.Break.lengthFrames = math.random(GameConfig.civilians.traffic.truckBreakMinSeconds, GameConfig.civilians.traffic.truckBreakMaxSeconds)*30
            persPack.Break.startFrame = frame + math.random(1000, GameConfig.game.dayLengthFrames)
        end
    end

    -- if near Destination increase goalIndex
    if distanceUnitToPoint(myID, persPack.goalList[persPack.goalIndex].x, persPack.goalList[persPack.goalIndex].y,
                           persPack.goalList[persPack.goalIndex].z) < 100 then

        if civilianLife:Arrive(myID,persPack.goalList[persPack.goalIndex],frame) then
            return true, frame + 15, persPack
        end

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

CivilianInternalDebugStateStartTabel = {}
local PRAYER_STATE_GRACE_FRAMES = 15 * 30

function unitInternalLogic(evtID, frame, persPack, startFrame, myID)
    local activeStates = GG.CivilianUnitInternalLogicActive
    local internalState = activeStates and activeStates[myID]
    if not internalState then
        return false, nil, persPack
    end

    -- Accept legacy scalar states during migration, but all current writers
    -- publish { state = ..., behaviour = ... } records.
    local state = internalState
    local behaviour = "unknown"
    if type(internalState) == "table" then
        state = internalState.state
        behaviour = internalState.behaviour or behaviour
    end

    local currentFrame = Spring.GetGameFrame()
    if state == GameConfig.civilians.activityStates.started then
        local stateStartFrame = CivilianInternalDebugStateStartTabel[myID]
        if not stateStartFrame then
            stateStartFrame = currentFrame
            CivilianInternalDebugStateStartTabel[myID] = stateStartFrame
        end

        local prayerTimedOut = behaviour == "pray" and
            currentFrame - stateStartFrame >
                getPrayDurationInFrames() + PRAYER_STATE_GRACE_FRAMES

        if not prayerTimedOut then
            return true, frame + 15, persPack
        end

       --echo(myID .. " prayer state timed out; restoring civilian movement")
        setSpeedEnv(myID, GameConfig.civilians.movement.walkingSpeedFactor)
        state = GameConfig.civilians.activityStates.ended
    end

    if state == GameConfig.civilians.activityStates.ended then
        local stateStartFrame = CivilianInternalDebugStateStartTabel[myID]
        if stateStartFrame then
            local durationFrames = currentFrame - stateStartFrame
          --  echo(myID .. " internal state " .. behaviour .. " lasted " ..                 (durationFrames / 30) .. " s")
        end

        if behaviour == "pray" then
            -- Also covers a prayer thread that was signalled before cleanup.
            setSpeedEnv(myID, GameConfig.civilians.movement.walkingSpeedFactor)
        end

        local goal = persPack.goalList and persPack.goalList[persPack.goalIndex]
        if goal and not civilianLife:ResumeGroup(myID) then
            Command(myID, "go", {
                x = math.ceil(goal.x),
                y = math.ceil(goal.y),
                z = math.ceil(goal.z)
            }, {})
        end

        activeStates[myID] = nil
        CivilianInternalDebugStateStartTabel[myID] = nil
        persPack.deactivateStuckDetectionValue = 0
        persPack.stuckCounter = 0
        return true, frame + 15, persPack
    end

    echo(myID .. " has invalid civilian internal state; clearing it")
    activeStates[myID] = nil
    CivilianInternalDebugStateStartTabel[myID] = nil
    return false, nil, persPack
end

function packStep(persPack, nextFrame, currentFrame)
    if nextFrame then
        persPack.LastStepFrame = (nextFrame - currentFrame)
    end
    return persPack
end

function travellFunction(evtID, frame, persPack, startFrame)
    --  only apply if Unit is still alive
    local myID = persPack.unitID

    boolDone, retFrame, persPack, x,y,z, hp = travelInitialization(evtID, frame, persPack, startFrame, myID)
    if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end

    if civilianLife:Step(myID,persPack,frame) then
        return frame + 15, packStep(persPack,frame+15,frame)
    end

    boolDone, retFrame, persPack = unitInternalLogic(evtID, frame, persPack, startFrame, myID)
    if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end

    boolDone, retFrame, persPack = stuckDetection(evtID, frame, persPack, startFrame, myID, x, y, z)
    if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end

    if GG.GlobalGameState == GameConfig.game.states.normal and not persPack.boolTraumatized then

        boolDone, retFrame, persPack = snychronizedSocialEvents(evtID, frame, persPack, startFrame, myID)
        if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end    

        boolDone, retFrame, persPack = sozialize(evtID, frame, persPack, startFrame, myID)
        if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end

        boolDone, retFrame, persPack = travelInPeaceTimes(evtID, frame, persPack, startFrame, myID)
        if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end

    else
        boolDone, retFrame, persPack = travelInWarTimes(evtID, frame, persPack, startFrame, myID)
        if boolDone == true then return retFrame,packStep(persPack, retFrame, frame) end
    end

    retFrame = frame + math.random(60, 90)
    return retFrame, packStep(persPack, retFrame, frame)
end

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

function getTargetNodeInWalkingDistance(startNodeID, defaultTargetNode)
    --assert(startNodeID)
    --assert(doesUnitExistAlive(startNodeID)==true, "Unit is dead")
    local listOfTargetNodes = RouteTabel[startNodeID]
    --assert(#listOfTargetNodes > 0)
    local listInRange = {}
    if #listOfTargetNodes == 0  then return defaultTargetNode end
    if #listOfTargetNodes == 1 then return listOfTargetNodes[1] end

    for i=1, #listOfTargetNodes do
        if distanceUnitToUnit(startNodeID, listOfTargetNodes[i]) < GameConfig.civilians.movement.maxWalkingDistance then
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
    -- RouteTabel is rebuilt from buildings, some of which can subsequently
    -- disappear. Never feed stale/non-numeric IDs into Spring C callins.
    if type(uID)~="number" or type(startNodeID)~="number"
        or not doesUnitExistAlive(uID) or not doesUnitExistAlive(startNodeID)
        or not spGetUnitPosition(uID) or not spGetUnitPosition(startNodeID) then
        return false
    end

    local candidates=RouteTabel[startNodeID]
    if type(candidates)~="table" then return false end
    local validCandidates={}
    for _,candidate in ipairs(candidates) do
        if type(candidate)=="number" and doesUnitExistAlive(candidate)
            and spGetUnitPosition(candidate) then
            validCandidates[#validCandidates+1]=candidate
        end
    end
    if #validCandidates==0 then return false end

    local walking=civilianWalkingTypeTable[uType]
    local targetNodeID
    if walking then
        targetNodeID=civilianLife:SelectTarget(uID,startNodeID,validCandidates)
    else
        targetNodeID=validCandidates[math.random(1,#validCandidates)]
    end
    if type(targetNodeID)~="number" or not doesUnitExistAlive(targetNodeID)
        or not spGetUnitPosition(targetNodeID) then return false end

    local route=walking and civilianLife:BuildRoute(uID,startNodeID,targetNodeID)
    route=route or buildRouteSquareFromTwoUnits(startNodeID,targetNodeID,uType)
    if not route or not route[1] then return false end

    GG.EventStream:CreateEvent(travellFunction, { -- persistance Pack
        mydefID = uType,
        myTeam = spGetUnitTeam(uID),
        unitID = uID,
        goalIndex = 1,
        goalList = route
    }, spGetGameFrame() + (uID % 100))
    return true
end

function testClampRoute(Route, defID) return Route end

function issueArrivedUnitsCommands()
    if not GG.UnitArrivedAtTarget or next(GG.UnitArrivedAtTarget) == nil then
        return
    end

    --assertTable(GG.UnitArrivedAtTarget)
    for id in pairs(GG.UnitArrivedAtTarget) do
        local data=GG.CivilianTable[id]
        if type(id)=="number" and type(data)=="table"
            and type(data.startID)=="number"
            and doesUnitExistAlive(data.startID) == true
            and doesUnitExistAlive(id) then
            giveWaypointsToUnit(id,data.defID,data.startID)
        end
    end
    GG.UnitArrivedAtTarget = {}
end

function decimateArrivedCivilians(nrToDecimate, typeTable)
    nrToDecimate = math.floor(nrToDecimate)
    -- --echo("Decimation called"..nrToDecimate)
    if nrToDecimate <= 0 then return end
    --assertTable(GG.UnitArrivedAtTarget)
    newUnitsArrivedAtTarget = {}
    for id, bArrived in pairs(GG.UnitArrivedAtTarget) do
        if id and GG.CivilianTable[id] and
            doesUnitExistAlive(GG.CivilianTable[id].startID) == true and
            doesUnitExistAlive(id) == true and 
            GG.DisguiseCivilianFor[id] == nil and
            not civilianLife:IsProtected(id) and
            typeTable[GG.CivilianTable[id].defID] then
            spDestroyUnit(id, false, true)
            ----echo("Killing Unit:"..id)
            if doesUnitExistAlive(id) == false then
                GG.UnitArrivedAtTarget[id] = nil
                nrToDecimate = nrToDecimate - 1
            end
            if nrToDecimate <= 0 then return end
        end
    end
end

function gadget:GameFrame(frame)
    civilianLife:Frame(frame)

    if boolInitialized == false then       
        spawnInitialPopulation(frame)
    elseif boolInitialized == true and frame > 0 and frame % 5 == 0 then
        -- Check number of Units	
        if frame % 30 == 0 and frame > startFrame then 
            checkReSpawnPopulation() 
            checkResetTemporaryStopped(frame)
        end

        if frame % 55 == 0 and frame > startFrame then checkReSpawnTraffic() end

        issueArrivedUnitsCommands()   
    end

    OpimizationFleeing.accumulatedCivilianDamage = math.max(0, OpimizationFleeing.accumulatedCivilianDamage  - 1)
end


