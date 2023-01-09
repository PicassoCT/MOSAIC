function gadget:GetInfo()
    return {
        name = "Spawn City Gadget",
        desc = "creates a city ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 2,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_staticstring.lua")

local GameConfig = getGameConfig()
--if not Game.version then Game.version = GameConfig.instance.Version end
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundNormal = Spring.GetGroundNormal
local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spGetUnitDefID = Spring.GetUnitDefID
local UnitDefNames = getUnitDefNames(UnitDefs)

local scrapHeapTypeTable = getScrapheapTypeTable(UnitDefs)
local TimeDelayedRespawn = {}
local BuildingWithWaitingRespawn = {}

GG.BuildingTable = {} -- [BuildingUnitID] = {routeID, stationIndex}
local houseStreetDim = {}
local innerCityDim = {}
houseStreetDim.x, houseStreetDim.y, houseStreetDim.z = GameConfig.houseSizeX + GameConfig.allyWaySizeX, GameConfig.houseSizeY, GameConfig.houseSizeZ + GameConfig.allyWaySizeZ
innerCityDim.x, innerCityDim.y, innerCityDim.z = GameConfig.houseSizeX/2 , GameConfig.houseSizeY/2, GameConfig.houseSizeZ /2

local BuildingPlaceTable = makeTable(true, math.ceil(Game.mapSizeX / houseStreetDim.x), math.ceil(Game.mapSizeZ / houseStreetDim.z)) -- SizeOf Map/Divide by Size of Building
local RouteTabel = {} -- Every start has a subtable of reachable nodes 	
local boolInitialized = false

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)

assert(houseTypeTable[UnitDefNames["house_arab0"].id])

local loadableTruckType = getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local refugeeableTruckType = getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local gaiaTeamID = Spring.GetGaiaTeamID() 

local boolHasCityCenter = false 
local boolCachedMapManualPlacementResult = nil




function isMapControlledBuildingPlacement()
   return string.find(string.lower(Game.mapName), "dubai") ~= nil
end

allreadyRegistredBuilding = {}
function registerManuallyPlacedHouses()      
    counter = 0
    foreach(Spring.GetAllUnits(),
            function(id)
                defID = spGetUnitDefID(id)
                if houseTypeTable[defID] and not allreadyRegistredBuilding[id]then
                    return id
                end
            end,
            function(id)
                allreadyRegistredBuilding[id] = true
                spSetUnitAlwaysVisible(id, true)
                setCityBuildingBlocking(id)

                x,y,z = Spring.GetUnitPosition(id)
                GG.BuildingTable[id] = {x = x, z = z }
                counter = counter + 1
            end
            )

    return counter
end


function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    -- if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
    if teamID == gaiaTeamID and attackerID then
        if houseTypeTable[unitDefID] then
            rubbleHeapID = spawnRubbleHeapAt(unitID)
        end
    end
    if houseTypeTable[unitDefID] then
      if GG.houseHasSafeHouseTable and  GG.houseHasSafeHouseTable[unitID] and doesUnitExistAlive(GG.houseHasSafeHouseTable[unitID]) == true then
         spDestroyUnit(GG.houseHasSafeHouseTable[unitID], true, false)
         GG.houseHasSafeHouseTable[unitID] = nil
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

local startindex = 1
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

function setCityBuildingBlocking(id)
    isblocking= false
    isSolidObjectCollidable=false
    isProjectileCollidable= true
    isRaySegmentCollidable = true
    crushable = false
    blockEnemyPushing= true
    blockHeightChanges = true

    spSetUnitBlocking( id,  isblocking, isSolidObjectCollidable,  isProjectileCollidable,  isRaySegmentCollidable ,  crushable , blockEnemyPushing,  blockHeightChanges ) 

end

function isOnRoad(cursorl)
    local subResCursor = {x= cursorl.x, z= cursorl.z}

    subResCursor.x = ((subResCursor.x)*2)-1 
    subResCursor.z = ((subResCursor.z)*2)-1 

    if subResCursor.x < 0 then     subResCursor.x =  subResCursor.x + 4 end
    if subResCursor.z < 0 then     subResCursor.z =  subResCursor.z + 4 end

    subResCursor.x  = ((subResCursor.x ) % 4)
    subResCursor.z = ((subResCursor.z ) % 4)
    if subResCursor.x  == 0  then return true end
    if subResCursor.z == 0  then return true end

    return false
end

function isOnInnerCityGridBlock(cursorl, offx, offz)
    local subResCursor = {x= cursorl.x, z= cursorl.z}
    if offx == 0 and offz == 0 then return false end

    subResCursor.x = ((subResCursor.x)*2)-1 + offx
    subResCursor.z = ((subResCursor.z)*2)-1 + offz

    if subResCursor.x < 0 then     subResCursor.x =  subResCursor.x + 4 end
    if subResCursor.z < 0 then     subResCursor.z =  subResCursor.z + 4 end

    subResCursor.x  = ((subResCursor.x ) % 4)
    subResCursor.z = ((subResCursor.z ) % 4)
    if subResCursor.x  == 0  then return false end
    if subResCursor.z == 0  then return false end

    if subResCursor.x == 1 and (subResCursor.z == 2 ) then return true end
    if subResCursor.x == 2 and (subResCursor.z == 1 or subResCursor.z == 3 ) then return true end
    if subResCursor.x == 3 and (subResCursor.z == 2 ) then return true end

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
    tileX, tileZ = houseStreetDim.x, houseStreetDim.z

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
    orgPosX, orgPosZ= cursor.x*houseStreetDim.x, cursor.z*houseStreetDim.z
    for offsx = -1, 1, 1 do
        for offsz = -1, 1, 1 do
            if isOnInnerCityGridBlock(cursor, offsx, offsz) == true then                
                if  hasAlreadyBuilding(orgPosX + (offsx * innerCityDim.x),  orgPosZ + offsz * innerCityDim.z, 35) == false  then
                          houseID = spawnBuilding(buildingType, 
                                        orgPosX + offsx * innerCityDim.x,
                                        orgPosZ + offsz * innerCityDim.z,
                                        true)
                           setHouseStreetNameTooltip(houseID, (cursor.x*2) + offsx, (cursor.z*2) + offsz, Game, true)
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
    cursor.x = math.max(1, math.min(cursor.x, math.floor(Game.mapSizeX / houseStreetDim.x)-1))
    cursor.z = math.max(1, math.min(cursor.z, math.floor(Game.mapSizeZ / houseStreetDim.z)-1))
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

        dice = math.floor(math.random(5, 31) / 10)
        boolNearCityCenter = isNearCityCenter(cursor.x * houseStreetDim.x, cursor.z*houseStreetDim.z, GameConfig)
        boolMirrorNearCityCenter = isNearCityCenter(mirror.x * houseStreetDim.x, mirror.z*houseStreetDim.z, GameConfig)

        if dice == 1 or (dice == 0 and GameConfig.instance.culture == "arabic")then -- 1 random walk into a direction doing nothing
            cursor = randomWalk(cursor)
            cursor = clampCursor(cursor)
            mirror = mirrorCursor(cursor, startx, startz)
            mirror = clampCursor(mirror)

        elseif dice == 2 or (dice == 0 and GameConfig.instance.culture ~= "arabic")  then -- 2 place a single block
            boolFirstPlaced = false
            dimX,dimZ = houseStreetDim.x, houseStreetDim.z

            if BuildingPlaceT[cursor.x][cursor.z] == true and  isOnRoad(cursor) == false then
                buildingType = randDict(houseTypeTable)
                houseID = spawnBuilding(buildingType, cursor.x * dimX, cursor.z * dimZ, boolNearCityCenter)
                setHouseStreetNameTooltip(houseID, cursor.x*2 , cursor.z*2, Game)

                numberOfBuildings = numberOfBuildings - 1
                BuildingPlaceT[cursor.x][cursor.z] = false
                boolFirstPlaced = true
                if boolNearCityCenter == true then
                     fillGapsWithInnerCityBlocks(cursor,  buildingType)
                end
            end

            if boolFirstPlaced == true and BuildingPlaceT[mirror.x][mirror.z] == true and isOnRoad(mirror) == false then
                buildingType = randDict(houseTypeTable)
                houseID = spawnBuilding(buildingType, mirror.x * dimX, mirror.z * dimZ, boolMirrorNearCityCenter)
                setHouseStreetNameTooltip(houseID, mirror.x*2 , mirror.z*2, Game)
                --echo("Placed Single Mirror")
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
                     GG.innerCityCenter.x = cursor.x*houseStreetDim.x
                     GG.innerCityCenter.z = cursor.z*houseStreetDim.z
                     boolNearCityCenter = true
                else
                    GG.innerCityCenter.x = mirror.x*houseStreetDim.x
                    GG.innerCityCenter.z = mirror.z*houseStreetDim.z
                    boolMirrorNearCityCenter = true
                end
             --   echo("Citycenter at:"..GG.innerCityCenter.x .." / "..GG.innerCityCenter.z)
            end


            numberOfBuildings, BuildingPlaceT =  placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings,
                                                   BuildingPlaceT, boolNearCityCenter)

            numberOfBuildings, BuildingPlaceT =  placeThreeByThreeBlockAroundCursor(mirror, numberOfBuildings,
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
                        local tmpCursor = {x =cursor.x + offx, z = cursor.z + offz}
                        local nameCursor = {x =(cursor.x*2) + offx, z =(cursor.z*2) + offz}
                        tmpCursor = clampCursor(tmpCursor)                      
                        buildingType = randDict(houseTypeTable)
                        if BuildingPlaceT[tmpCursor.x] and BuildingPlaceT[tmpCursor.x][tmpCursor.z] and BuildingPlaceT[tmpCursor.x][tmpCursor.z] == true then
                            houseID = spawnBuilding(buildingType,
                                          tmpCursor.x * houseStreetDim.x,
                                          tmpCursor.z * houseStreetDim.z, boolNearCityCenter)
                            numberOfBuildings = numberOfBuildings - 1
                            setHouseStreetNameTooltip(houseID, nameCursor.x , nameCursor.z, Game, true)
                            if boolNearCityCenter == true then
                                fillGapsWithInnerCityBlocks({x=tmpCursor.x, z=tmpCursor.z}, buildingType, BuildingPlaceT)
                            end

                            BuildingPlaceT[tmpCursor.x][tmpCursor.z] = false
                        end
                    end
                end
            end
        end

    return numberOfBuildings, BuildingPlaceT
end

--will not be called with boolInitialized true
boolAtLeastOneManualPlacement = false
function spawnInitialHouses(frame)
  
    -- great Grid of placeable Positions 
    if distributedPathValidationComplete(frame, 10) == true  then
        if  isMapControlledBuildingPlacement() == false then
        -- spawn Buildings from MapCenter Outwards
        fromMapCenterOutwards(BuildingPlaceTable,
                              math.ceil(#BuildingPlaceTable/2),
                              math.ceil(#BuildingPlaceTable[1]/2)
                              )
            boolInitialized = true   
            GG.CitySpawnComplete = true
            regenerateRoutesTable()
            --echo("spawnInitialHouses: Default Initialization completed")
        else

           registeredUnits = registerManuallyPlacedHouses() 
           --echo("Registering Units manually" ..registeredUnits.." and "..toString(GG.MapCompletedBuildingPlacement))
           boolAtLeastOneManualPlacement = boolAtLeastOneManualPlacement or  registeredUnits > 0
           boolInitialized = (boolAtLeastOneManualPlacement and Spring.GetGameFrame() > originalGameFrame and registeredUnits == 0)
           if boolInitialized == false then return end
           GG.CitySpawnComplete = true
           regenerateRoutesTable()
           --echo("spawnInitialHouses: Manual Placement Initialization completed")
        end
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
            id = spawnBuilding(buildingType, x, z, isNearCityCenter(x,z, GameConfig))
            dataToAdd[id] = routeDataCopy
        end
    end

    for id, routeData in pairs(dataToAdd) do GG.BuildingTable[id] = routeData end
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
    GG.RouteTable = RouteTabel
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
        spSetUnitAlwaysVisible(id, true)
        return id
    end
end

function spawnBuilding(defID, x, z,  boolInCityCenter)
    offset = {xRandOffset = 0, zRandOffset = 0}
    if not boolInCityCenter  then
         offset = getCultureDependantRandomOffsets(GameConfig.instance.culture, {x=x, z=z})
    end
    id = spawnUnit(defID, x + math.random(-1 * offset.xRandOffset, offset.xRandOffset), 
                          z + math.random(-1 * offset.zRandOffset, offset.zRandOffset))

    if id then
        spSetUnitAlwaysVisible(id, true)
        setCityBuildingBlocking(id)
        GG.BuildingTable[id] = {x = x, z = z}
        return id
    end
end

function killAllUnitsAtGamestart()
 foreach(Spring.GetAllUnits(),
            function(id) 
                Spring.DestroyUnit(id, true, true) 
            end)
end

originalGameFrame = -math.huge
function gadget:Initialize()
    -- Initialize global tables
    Spring.Echo(Game.mapName.. " is a map controlled city place map "..toString(isMapControlledBuildingPlacement()))
    if not  GG.BuildingTable then  GG.BuildingTable = {} end
    if not  GG.innerCityCenter then  GG.innerCityCenter = {} end

    GG.CitySpawnComplete = false
    GameConfig = getGameConfig()
    Spring.SetGameRulesParam ( "culture",GameConfig.instance.culture ) 
    --killAllUnitsAtGamestart()
originalGameFrame = Spring.GetGameFrame()
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
        spawnInitialHouses(frame)
    elseif boolInitialized == true and frame > 0 and frame % 5 == 0 then
        countDownRespawnHouses(5)
        checkReSpawnHouses()
    end
end
--[[
function getAITeam()
    teams = getAITeams()
    return teams[1]
end--]]



  