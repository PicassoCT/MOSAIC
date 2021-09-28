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

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

statistics = {}
local GameConfig = getGameConfig()
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame = Spring.GetGameFrame
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundNormal = Spring.GetGroundNormal
local spGetUnitLastAttacker = Spring.GetUnitLastAttacker
local spGetUnitNearestAlly = Spring.GetUnitNearestAlly
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spSetUnitRotation = Spring.SetUnitRotation

local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spSetUnitNeutral = Spring.SetUnitNeutral
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit

local UnitDefNames = getUnitDefNames(UnitDefs)

local AllCiviliansTypeTable = getCivilianTypeTable(UnitDefs)
local scrapHeapTypeTable = getScrapheapTypeTable(UnitDefs)
local activePoliceUnitIds_Dispatchtime = {}
local MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
local CivAnimStates = getCivilianAnimationStates()
local PanicAbleCivliansTable = getPanicableCiviliansTypeTable(UnitDefs)
local TimeDelayedRespawn = {}
BuildingWithWaitingRespawn = {}

GG.CivilianTable = {} -- [id ] ={ defID, startNodeID }
GG.UnitArrivedAtTarget = {} -- [id] = true UnitID -- Units report back once they reach this target
GG.BuildingTable = {} -- [BuildingUnitID] = {routeID, stationIndex}
local BuildingPlaceTable = {} -- SizeOf Map/Divide by Size of Building
local uDim = {}
local innerCityDim = {}
uDim.x, uDim.y, uDim.z = GameConfig.houseSizeX + GameConfig.allyWaySizeX, GameConfig.houseSizeY, GameConfig.houseSizeZ + GameConfig.allyWaySizeZ
innerCityDim.x, innerCityDim.y, innerCityDim.z = GameConfig.houseSizeX/2 , GameConfig.houseSizeY/2, GameConfig.houseSizeZ /2
local innerCityCenter = {}
numberTileX, numberTileZ = Game.mapSizeX / uDim.x, Game.mapSizeZ / uDim.z

local RouteTabel = {} -- Every start has a subtable of reachable nodes 	
local boolInitialized = false

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)

local loadableTruckType = getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local refugeeAbleTruckType = getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local gaiaTeamID = Spring.GetGaiaTeamID() 
local OpimizationFleeing = {accumulatedCivilianDamage = 0}

local boolCachedMapManualPlacementResult
function isMapControlledBuildingPlacement(mapName)
    if boolCachedMapManualPlacementResult then return boolCachedMapManualPlacementResult end
    manualBuildingPlacingMaps = getManualObjectiveSpawnMapNames("manualBuildingPlacing")
    if manualBuildingPlacingMaps[string.lower(mapName)] then
        boolCachedMapManualPlacementResult = true
    else
        boolCachedMapManualPlacementResult = false
    end
    return boolCachedMapManualPlacementResult
end

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
    process(getInCircle(unitID, GameConfig.civilianInterestRadius, gaiaTeamID),
            function(id)
        -- filter out civilians
        if id then
            defID = spGetUnitDefID(id)
            if defID and PanicAbleCivliansTable[defID] then return id end
        end
    end, function(id)
        if math.random(0, 100) > GameConfig.inHundredChanceOfInterestInDisaster then
            offx, offz = math.random(25, 50) * randSign(),
                         math.random(25, 50) * randSign()
            Command(id, "go", {x = ux + offx, y = uy, z = uz + offz}, {})
            -- TODO Set Behaviour filming
            startInternalBehaviourOfState(id, "startFilmLocation", ux,uy,uz, math.random(5000,15000))
           -- Spring.Echo("Unit "..id.." is now filming")
        elseif math.random(0, 100) > GameConfig.inHundredChanceOfDisasterWailing then
            offx, offz = math.random(0, 10) * randSign(),
                         math.random(0, 10) * randSign()
            Command(id, "go", {x = ux + offx, y = uy, z = uz + offz}, {})
            startInternalBehaviourOfState(id, "startWailing", math.random(5000,25000))
       end
    end)
end

local storedSpawnedUnits = {}
function registerManuallyPlacedHouses() 
    for id, data in pairs(storedSpawnedUnits) do
        if doesUnitExistAlive(id) == true then
            spSetUnitAlwaysVisible(id, true)
            spSetUnitBlocking(id, false)
            GG.BuildingTable[id] = {x = data.x, z = data.z }
        end
    end
    storedSpawnedUnits = {} 
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
    if teamID == gaiaTeamID and houseTypeTable[unitDefID] and isMapControlledBuildingPlacement(Game.mapName) then
       x,y,z = spGetUnitPosition(unitID)
       storedSpawnedUnits[unitID] = {x=x, y=y, z = z}
    end
 end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    -- if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
    if teamID == gaiaTeamID and attackerID then
        makePasserBysLook(unitID)
        -- other gadgets worries about propaganda price
        if houseTypeTable[unitDefID] then
            rubbleHeapID = spawnRubbleHeapAt(unitID)
        end
    end
end

function spawnRubbleHeapAt(id)
    x, y, z = spGetUnitPosition(id)
    if x then

        rubbleHeapID = spCreateUnit(randDict(scrapHeapTypeTable), x, y, z, 1,
                                    gaiaTeamID)
        TimeDelayedRespawn[rubbleHeapID] =
            {
                frame = GameConfig.TimeForScrapHeapDisappearanceInMs,
                x = x,
                z = z,
                bID = id
            }
        BuildingWithWaitingRespawn[id] = true
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
            T = process(getInCircle(unitID,  GameConfig.civilianPanicRadius, gaiaTeamID),
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

BuildingPlaceTable = makeTable(true, math.ceil(Game.mapSizeX / uDim.x), math.ceil(Game.mapSizeZ / uDim.z))


startindex = 1
function distributedPathValidationComplete(frame, elements)
    oldstartindex = startindex

    boolComplete = false
    startindex = validateBuildSpotsReachable(startindex, math.min(
                                                 startindex + elements,
                                                 #BuildingPlaceTable))
    -- echo("Pathingpercentage: ", startindex/((#BuildingPlaceTable)))
    if startindex >= #BuildingPlaceTable then boolComplete = true end

    return boolComplete
end

local boolHasCityCenter = false --maRa()
function isNearCityCenter(x,z)
    if boolHasCityCenter == false then return false end

    return distance(x, 0, z, innerCityCenter.x, 0,  innerCityCenter.z) < GameConfig.innerCitySize
end

function isOnInnerCityGridBlock(cursorl, offx, offz, BuildingPlaceT)
    local subResCursor = cursorl
    if offx == 0 and offz == 0 then return false end

    subResCursor.x = ((subResCursor.x-1)*2)+1 + offx
    subResCursor.z = ((subResCursor.z-1)*2)+1 + offz
 
    if subResCursor.x  < 1 or subResCursor.x > #BuildingPlaceT*2 then return false end
    if subResCursor.z  < 1 or subResCursor.z > #BuildingPlaceT[1]*2 then return false end

    modx = ((subResCursor.x ) % 4)
    modz = ((subResCursor.z ) % 4)

    if modx == 1 and (modz == 2 ) then return true end
    if modx == 2 and (modz == 1 or modz == 3 ) then return true end
    if modx == 3 and (modz == 2 ) then return true end
  
    return false
end

function hasAlreadyBuilding(x,z, range)
    local allPreviousBuildings = GG.BuildingTable
    for id, data in pairs(allPreviousBuildings) do
        if distance(x,0,z, data.x, 0, data.z) < range then return true end
    end

    return false
end

-- check Traversability from each position to the previous position	
function validateBuildSpotsReachable(start, endindex)
    tileX, tileZ = uDim.x, uDim.z

    for x = start, endindex, 1 do
        for z = 1, #BuildingPlaceTable[1] do
            startx, startz = x * tileX, z * tileZ

            PlacesReachableFromPosition = 0
            local boolEarlyOut
            for xi = 1, #BuildingPlaceTable do
                for zi = 1, #BuildingPlaceTable[1] do
                    if xi ~= x or zi ~= z then
                        endx, endz = xi * tileX, zi * tileZ

                        if spRequestPath(
                            UnitDefNames["truck_arab0"].moveDef.name, startx, 0,
                            startz, endx, 0, endz) then
                            PlacesReachableFromPosition =
                                PlacesReachableFromPosition + 1
                            if PlacesReachableFromPosition > 5 then
                                dx, dy, dz, slope =
                                    spGetGroundNormal(x * tileX, z * tileZ)

                                BuildingPlaceTable[x][z] =
                                    spGetGroundHeight(x * tileX, z * tileZ) > 5 and
                                        slope < 0.2
                                boolEarlyOut = true
                                break
                            end
                        end
                    end
                end
                if boolEarlyOut == true then break end
            end
        end
    end

    return endindex + 1
end



function fillGapsWithInnerCityBlocks(cursorl, buildingType, BuildingPlaceT)
    local cursor = cursorl
    orgPosX, orgPosZ= cursor.x*uDim.x, cursor.z*uDim.z
    for offsx = -1, 1, 1 do
        for offsz = -1, 1, 1 do
            if isOnInnerCityGridBlock(cursor, offsx, offsz, BuildingPlaceT) == true then                
                if  hasAlreadyBuilding(orgPosX + (offsx * innerCityDim.x),  orgPosZ + offsz * innerCityDim.z, 30) == false  then
                           spawnBuilding(buildingType, 
                                        orgPosX + offsx * innerCityDim.x,
                                        orgPosZ + offsz * innerCityDim.z,
                                        true)

                end
            end    
        end
    end
end

function cursorIsOnMainRoad(cursor, sx, sz)
    return ((cursor.x - sx) % GameConfig.mainStreetModulo == 0) or
               ((cursor.z - sz) % GameConfig.mainStreetModulo == 0)
end

function clampCursor(cursor)
    cursor.x = math.max(1, math.min(cursor.x, math.floor(Game.mapSizeX / uDim.x)-1))
    cursor.z = math.max(1, math.min(cursor.z, math.floor(Game.mapSizeZ / uDim.z)-1))
    return cursor
end

function randomWalk(cursor)
    return {x = cursor.x + randSign(), z = cursor.z + randSign()}
end

function mirrorCursor(cursor, cx, cz)
    x, z = cx - cursor.x, cz - cursor.z
    return {x = cx + x, z = cz + z}
end

-- spawns intial buildings
function fromMapCenterOutwards(BuildingPlaceT, startx, startz)
    local finiteSteps = GameConfig.maxIterationSteps
    local cursor = {x = startx, z = startz}
    local mirror = {x = startx, z = startz}
    local numberOfBuildings = GameConfig.numberOfBuildings - 1
    local cityBlockCounter = 0

    while finiteSteps > 0 and numberOfBuildings > 0 do
        finiteSteps = finiteSteps - 1

        dice = math.floor(math.random(10, 31) / 10)
        dice = getRandomElementFromTable({1, 3})
        boolNearCityCenter = isNearCityCenter(cursor.x * uDim.x, cursor.z*uDim.z)
        boolMirrorNearCityCenter = isNearCityCenter(mirror.x * uDim.x, mirror.z*uDim.z)

        if dice == 1 then -- 1 random walk into a direction doing nothing
            cursor = randomWalk(cursor)
            cursor = clampCursor(cursor)
            mirror = mirrorCursor(cursor, startx, startz)
            mirror = clampCursor(mirror)
            -- Spring.Echo("dice 1")
        elseif dice == 2 then -- 2 place a single block
            boolFirstPlaced = false
            dimX,dimZ = uDim.x, uDim.z

            if BuildingPlaceT[cursor.x][cursor.z] == true and cursorIsOnMainRoad(cursor, startx, startz) == false then
                buildingType = randDict(houseTypeTable)
                spawnBuilding(buildingType, cursor.x * dimX, cursor.z * dimZ, boolNearCityCenter)
                numberOfBuildings = numberOfBuildings - 1
                BuildingPlaceT[cursor.x][cursor.z] = false
                boolFirstPlaced = true
                if boolNearCityCenter == true then
                     fillGapsWithInnerCityBlocks(cursor,  buildingType)
                end
            end

            if boolFirstPlaced == true and BuildingPlaceT[mirror.x][mirror.z] ==
                true and cursorIsOnMainRoad(mirror, startx, startz) == false then
                buildingType = randDict(houseTypeTable)
                spawnBuilding(buildingType, mirror.x * dimX, mirror.z * dimZ, boolMirrorNearCityCenter)
                numberOfBuildings = numberOfBuildings - 1
                BuildingPlaceT[mirror.x][mirror.z] = false
                if boolMirrorNearCityCenter == true then
                     fillGapsWithInnerCityBlocks(mirror,  buildingType)
                end
            end

        elseif dice == 3 then
            cityBlockCounter = cityBlockCounter + 1
            if cityBlockCounter > 1 and boolHasCityCenter == false then
                boolHasCityCenter = true
                if maRa()== true then
                     innerCityCenter.x = cursor.x*uDim.x
                     innerCityCenter.z = cursor.z*uDim.z
                     boolNearCityCenter = true
                else
                    innerCityCenter.x = mirror.x*uDim.x
                    innerCityCenter.z = mirror.z*uDim.z
                    boolMirrorNearCityCenter = true
                end
                echo("Citycenter at:"..innerCityCenter.x .." / "..innerCityCenter.z)
            end


            numberOfBuildings, BuildingPlaceT =  placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings,
                                                   BuildingPlaceT, boolNearCityCenter)

            numberOfBuildings, BuildingPlaceT =    placeThreeByThreeBlockAroundCursor(mirror, numberOfBuildings,
                                                   BuildingPlaceT, boolMirrorNearCityCenter)
        end
    end
end

function checkCursorInnerCityFree(cursor)
    return BuildingPlaceT[cursor.x][cursor.z] and BuildingPlaceT[cursor.x +1][cursor.z] and BuildingPlaceT[cursor.x ][cursor.z+1]and BuildingPlaceT[cursor.x +1 ][cursor.z +1]
end

function placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings,  BuildingPlaceT, boolNearCityCenter)
    buildingType = randDict(houseTypeTable)

        for offx = -1, 1, 1 do
                if BuildingPlaceT[cursor.x + offx] then
                    for offz = -1, 1, 1 do
                         if BuildingPlaceT[cursor.x + offx][cursor.z + offz] then
                        local tmpCursor = cursor
                        tmpCursor.x = tmpCursor.x + offx
                        tmpCursor.z = tmpCursor.z + offz
                        tmpCursor = clampCursor(tmpCursor)
                      
                        buildingType = randDict(houseTypeTable)
                        if BuildingPlaceT[tmpCursor.x][tmpCursor.z] == true then
                            spawnBuilding(buildingType,
                                          tmpCursor.x * uDim.x,
                                          tmpCursor.z * uDim.z, boolNearCityCenter)
                            numberOfBuildings = numberOfBuildings - 1
                 --[[           assert(tmpCursor.x < #BuildingPlaceT)
                            assert(tmpCursor.z < #BuildingPlaceT[1])--]]
                            if boolNearCityCenter == true then
                                fillGapsWithInnerCityBlocks({x=tmpCursor.x, z=tmpCursor.z}, buildingType, BuildingPlaceT)
                            end
                --[[              assert(tmpCursor.x < #BuildingPlaceT)
                            assert(tmpCursor.z < #BuildingPlaceT[1])--]]
                            --assert( BuildingPlaceT[tmpCursor.x] ~= nil,"No BuildingPlaceT for".. tmpCursor.x)
                            -- assert( BuildingPlaceT[tmpCursor.x][tmpCursor.z] ~= nil, "No BuildingPlaceT for".. tmpCursor.x.."/"..tmpCursor.z)
--[[                            assert(tmpCursor.x)
                            assert(tmpCursor.z)
                            assert(BuildingPlaceT)
                            assert(BuildingPlaceT[tmpCursor.x], tmpCursor.x.." "..#BuildingPlaceT)
                            assert(BuildingPlaceT[tmpCursor.x][tmpCursor.z], tmpCursor.z.." "..#BuildingPlaceT[tmpCursor.x])--]]
                            BuildingPlaceT[tmpCursor.x][tmpCursor.z] = false
                        end
                        end
                    end
                end
        end

    return numberOfBuildings, BuildingPlaceT
end

function spawnInitialPopulation(frame)
  
    -- great Grid of placeable Positions 
    if distributedPathValidationComplete(frame, 10) == true then
        if  not isMapControlledBuildingPlacement(Game.mapName) then
        -- spawn Buildings from MapCenter Outwards
        fromMapCenterOutwards(BuildingPlaceTable,
                              math.ceil(#BuildingPlaceTable/2),
                              math.ceil(#BuildingPlaceTable[1]/2)
                              )
            boolInitialized = true   
        else
           registerManuallyPlacedHouses() 
           boolInitialized = GG.MapCompletedBuildingPlacement and   GG.MapCompletedBuildingPlacement == true
           if not boolInitialized then return end
        end

        regenerateRoutesTable()

        -- give Arrived Units Commands
        sendArrivedUnitsCommands()
       
    end
end

function checkReSpawnHouses()
    dataToAdd = {}
    for bID, routeData in pairs(GG.BuildingTable) do
        local routeDataCopy = routeData
        if bID and doesUnitExistAlive(bID) ~= true and not BuildingWithWaitingRespawn[bID] then
            GG.BuildingTable[bID] = nil

            x, z = routeDataCopy.x, routeDataCopy.z
            buildingType = randDict(houseTypeTable)
            id = spawnBuilding(buildingType, x, z, isNearCityCenter(x,z))
            dataToAdd[id] = routeDataCopy
        end
    end

    for id, routeData in pairs(dataToAdd) do GG.BuildingTable[id] = routeData end
end

function checkReSpawnPopulation()
    counter = 0
    nilTable = {}
    for id, data in pairs(GG.CivilianTable) do
        if id and civilianWalkingTypeTable[data.defID] then
            if doesUnitExistAlive(id) == true then
                counter = counter + 1
            else
                nilTable[id] = true
            end
        end
    end

    for id, data in pairs(nilTable) do GG.CivilianTable[id] = nil end

    if counter < getUnitNumberAtTime(GameConfig.numberOfPersons) then
        local stepSpawn = math.min(GameConfig.numberOfPersons - counter,
                                   GameConfig.LoadDistributionMax)
        -- echo(counter.. " of "..GameConfig.numberOfPersons .." persons spawned")		

        for i = 1, stepSpawn do
            x, _, z, startNode = getRandomSpawnNode()

            -- assert(startNode)
            -- assert(RouteTabel[startNode])
            if x and startNode then
                goalNode = RouteTabel[startNode][math.random(1,
                                                             #RouteTabel[startNode])]
                civilianType = randDict(civilianWalkingTypeTable)
                id = spawnAMobileCivilianUnit(civilianType, x, z, startNode,
                                              goalNode)
            end
        end
    else -- decimate arrived cvilians who are not DisguiseCivilianFor
        decimateArrivedCivilians(absDistance(
                                     getUnitNumberAtTime(
                                         GameConfig.numberOfPersons), counter),
                                 civilianWalkingTypeTable)
    end
end

function loadTruck(id, loadType)
    if loadableTruckType[spGetUnitDefID(id)] then
        --Spring.Echo(id .. " is a loadable truck ")
       payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)
       assert(payLoadID)
       if payLoadID then
           Spring.SetUnitAlwaysVisible(payLoadID,true)
           pieceMap = Spring.GetUnitPieceMap(id)
           assert(pieceMap["attachPoint"])
           Spring.UnitAttach(id, payLoadID, pieceMap["attachPoint"])
            return payLoadID
       end
    end
end

function checkReSpawnTraffic()
    counter = 0
    nilTable = {}
    for id, data in pairs(GG.CivilianTable) do
        if id and TruckTypeTable[data.defID] then
            if doesUnitExistAlive(id) == true then
                counter = counter + 1
            else
                nilTable[id] = true
            end
        end
    end

    for id, data in pairs(nilTable) do GG.CivilianTable[id] = nil end

    if counter < getUnitNumberAtTime(GameConfig.numberOfVehicles) then
        local stepSpawn = math.min(GameConfig.LoadDistributionMax,
                                   GameConfig.numberOfVehicles - counter)
        -- echo(counter.. " of "..GameConfig.numberOfVehicles .." vehicles spawned")		
        for i = 1, stepSpawn do
            x, _, z, startNode = getRandomSpawnNode()

            -- assert(RouteTabel[startNode])
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
                                     getUnitNumberAtTime(
                                         GameConfig.numberOfVehicles), counter),
                                 TruckTypeTable)
    end
end

function getUnitNumberAtTime(value)
    h, m, _, pTime = getDayTime()

    mixValue = math.sin(math.pi * pTime)
    blendedFactor = mix(1, GameConfig.nightCivilianReductionFactor, mixValue)
    --		echo("Time:"..h..":"..m.." %:"..pTime.."->"..blendedFactor)
    return value * blendedFactor
end

function getRandomSpawnNode()
    startNode = randT(RouteTabel)
    attempts = 0
    while not doesUnitExistAlive(startNode) or attempts > 5 do
        startNode = randT(RouteTabel)
        attempts = attempts + 1
    end

    x, y, z = spGetUnitPosition(startNode)

    return x, y, z, startNode
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

    assert(#Route >= 3)
    assert(Route[1].x)
    assert(Route[2].x)

    return testClampRoute(Route, uType)
end

function regenerateRoutesTable()
    local newRouteTabel = {}
    TruckType = randDict(TruckTypeTable)
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

function getCutlureDependentDiretion(culture)
    if culture == "arabic" then return 0 end
    
    return math.max(1, math.floor(math.random(1, 3)))
 end

function spawnUnit(defID, x, z)
    if not x then
        echo("Spawning unit of typ " .. UnitDefs[defID].name ..
                 " with no coords")
    end
    
    dir = getCutlureDependentDiretion(GameConfig.instance.culture)
    h = spGetGroundHeight(x, z)
    id = spCreateUnit(defID, x, h, z, dir, gaiaTeamID)

    if not statistics[defID] then statistics[defID] = 0 end
    statistics[defID] = statistics[defID] + 1

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

function spawnBuilding(defID, x, z,  boolInCityCenter)
    offset = {xRandOffset = 0, zRandOffset = 0}
    if not boolInCityCenter  then
         offset = getCultureDependantRandomOffsets(GameConfig.instance.culture, {x=x, z=z})
    end
    id = spawnUnit(defID, x +
                       math.random(-1 * offset.xRandOffset,
                                   offset.xRandOffset), z +
                       math.random(-1 * offset.zRandOffset,
                                   offset.zRandOffset))

    if id then
        --spSetUnitRotation(id, 0, math.rad(offset.districtRotationDeg), 0)
        spSetUnitAlwaysVisible(id, true)
        spSetUnitBlocking(id, false)
        GG.BuildingTable[id] = {x = x, z = z}
        return id
    end
end

function gadget:Initialize()
    -- Initialize global tables
    GG.CivilianTable = {}
    GG.DisguiseCivilianFor = {}
    GG.DiedPeacefully = {}
    GG.BuildingTable = {}
    GG.AerosolAffectedCivilians = {}
    GG.UnitArrivedAtTarget = {}
    GG.TravelFunctionRegistry= {}

    process(Spring.GetAllUnits(),
            function(id) Spring.DestroyUnit(id, true, true) end)
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

    x, y, z = spGetUnitPosition(myID)
    assert(x)

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
    if index == 1 then return 0,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
    if index == 2 then return Game.mapSizeX,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
    if index == 3 then return GG.CivilianEscapePointTable[index] *Game.mapSizeX, 0 end
    if index == 4 then return GG.CivilianEscapePointTable[index] *Game.mapSizeX, Game.mapSizeZ end
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
        if refugeeAbleTruckType[spGetUnitDefID(myID)] then
            persPack.boolRefugee = true 
            payloadID = loadTruck(myID, "truckpayloadrefugee")
            if payloadID then
                civiliansNearby = process(getAllNearUnit(myID, 128),
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
        if not GG.CivilianEscapePointTable then 
            GG.CivilianEscapePointTable = {} 
            for i=1,4 do GG.CivilianEscapePointTable[i] = math.random(1,1000)/1000  end
        end
        --Find known CivilianEscapePointTable (StartPoints) 
        if not persPack.CivilianEscapeIndex then persPack.CivilianEscapeIndex = math.random(1,4) end

        ex,ez = getEscapePoint(persPack.CivilianEscapeIndex)
        ey = spGetGroundHeight(ex,ez)

        if distanceUnitToPoint(myID, ex,ey,ez) < 150 then
            spDestroyUnit(myID, false, true)
            return true, nil, persPack
        else
            Command(myID, "go", {
                x = ex,
                y = ey,
                z = ez
            }, {})
          return true, frame + math.random(15,45), persPack
        end
     end

 -- if near Destination increase goalIndex
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
    
    return false, nil, persPack
end  


function stuckDetection(evtID, frame, persPack, startFrame, myID, x, y, z)

    boolDone = false

    if persPack.boolStartAChat and persPack.boolStartAChat == true then 
    return boolDone, nil, persPack
    end 

    if distance(x, y, z, persPack.currPos.x, persPack.currPos.y, persPack.currPos.z) < 140 then
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

        --debugCode
        defStr= "Unit "..myID.." a "..UnitDefs[spGetUnitDefID(myID)].name.." has no "
        assert(persPack.goalList, defStr.. "goalList")
        assert(persPack.goalIndex, defStr.. "goalIndex")
        assert(persPack.goalIndex > 0 and persPack.goalIndex <= #persPack.goalList, defStr.. "goalIndex not violating limits "..persPack.goalIndex)
        assert(#persPack.goalList > 0, defStr.."goalList ")

        assert(persPack.goalList[persPack.goalIndex].x,defStr.."x component")
        assert(persPack.goalList[persPack.goalIndex].y,defStr.."y component")
        assert(persPack.goalList[persPack.goalIndex].z,defStr.."z component")

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
    assert(persPack)
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
        if distanceUnitToUnit(startNodeID, listOfTargetNodes[i]) < GameConfig.civilianMaxWalkingDistance then
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

function sendArrivedUnitsCommands()
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

function countDownRespawnHouses(framesToSubstract)
    for rubbleHeapID, tables in pairs(TimeDelayedRespawn) do
        TimeDelayedRespawn[rubbleHeapID].frame =
            TimeDelayedRespawn[rubbleHeapID].frame - framesToSubstract

        if TimeDelayedRespawn[rubbleHeapID].frame <= 0 then
            if isUnitAlive(rubbleHeapID) == true then
                spDestroyUnit(rubbleHeapID, false, true)
            end
            regenerateRoutesTable()
            BuildingWithWaitingRespawn[tables.bID] = nil
            TimeDelayedRespawn[rubbleHeapID] = nil
        end
    end
end

function gadget:GameFrame(frame)
    if boolInitialized == false then
        spawnInitialPopulation(frame)
        --	echo("Initialization:Frame:"..frame)
    elseif boolInitialized == true and frame > 0 and frame % 5 == 0 then
        countDownRespawnHouses(5)

        -- echo("Runcycle:Frame:"..frame)
        -- recreate buildings 
        -- recreate civilians
        checkReSpawnHouses()

        -- Check number of Units	
        if frame % 30 == 0 then checkReSpawnPopulation() end

        if frame % 55 == 0 then checkReSpawnTraffic() end

        -- if Unit arrived at Location
        -- give new Target
        sendArrivedUnitsCommands()
        -- echoT(statistics)      
    end

    OpimizationFleeing.accumulatedCivilianDamage = math.max(0, OpimizationFleeing.accumulatedCivilianDamage  - 1)
end
