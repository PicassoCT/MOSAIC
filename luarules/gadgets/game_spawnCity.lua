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
local boolDebug = false
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_staticstring.lua")
local buisnessNeonSigns =  include("scripts/buissnesNamesNeonLogos.lua")

local GameConfig = getGameConfig()
local ruinConfig = GameConfig.city.ruins or getCityRuinConfig()
local cityGeography = getCityGeography(Game)
local cityRuins = VFS.Include("scripts/lib_city_ruins.lua")
--if not Game.version then Game.version = GameConfig.game.version end
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
local asianSplit = VFS.Include("scripts/lib_house_asian_split.lua")
GG.HouseAsianSplitState = GG.HouseAsianSplitState or asianSplit.newState()
local asianSplitState = GG.HouseAsianSplitState
GG.HouseAsianUnitPlans = GG.HouseAsianUnitPlans or {}

local scrapHeapTypeTable = getBuildingScrapHeapTypeTable(UnitDefs)
local ruinTypeTable = getBuildingRuinTypeTable(UnitDefs)
local ruinCandidateTypeTable = getCityRuinCandidateTypeTable(UnitDefs)
local ruinDefIDs = {}
for defID in pairs(ruinTypeTable) do ruinDefIDs[#ruinDefIDs + 1] = defID end
table.sort(ruinDefIDs)
GG.CityPlotGeometry = GG.CityPlotGeometry or {}
local cityPlotGeometry = GG.CityPlotGeometry
-- Lifecycle coverage is independent of the map's spawn culture and of whether
-- a model supports block damage. The all-culture set is owned by lib_mosaic.
local civilianHouseTypeTable = getCultureUnitModelTypes("international", "house", UnitDefs)
GG.CityConstructionSites = GG.CityConstructionSites or {}
GG.CityRubble = GG.CityRubble or {}
local newReconstruction = VFS.Include("luarules/gadgets/include/city_reconstruction.lua")
local reconstruction
local reloadSnapshot
local routesDirty = false

GG.BuildingTable = GG.BuildingTable or {} -- [BuildingUnitID] = {routeID, stationIndex}
local houseStreetDim = {}
local innerCityDim = {}
houseStreetDim.x, houseStreetDim.y, houseStreetDim.z = GameConfig.city.buildings.sizeX + GameConfig.city.alleys.sizeX, GameConfig.city.buildings.sizeY, GameConfig.city.buildings.sizeZ + GameConfig.city.alleys.sizeZ
innerCityDim.x, innerCityDim.y, innerCityDim.z = GameConfig.city.buildings.sizeX/2 , GameConfig.city.buildings.sizeY/2, GameConfig.city.buildings.sizeZ /2

local BuildingPlaceTable = makeTable(false, math.ceil(Game.mapSizeX / houseStreetDim.x), math.ceil(Game.mapSizeZ / houseStreetDim.z)) -- SizeOf Map/Divide by Size of Building
local RouteTabel = GG.RouteTable or {}
local occupiedGrid = {}
local function gameRule(name)
    return Spring.GetGameRulesParam and Spring.GetGameRulesParam(name)
end
local function unitRule(id, name)
    return Spring.GetUnitRulesParam and Spring.GetUnitRulesParam(id, name)
end
local generation = GG.CityGenerationState or {
    consumed=gameRule("mosaic_city_initial_plots") or 0, seen={},
    complete=gameRule("mosaic_city_spawn_complete")==1,
}
GG.CityGenerationState = generation
if not generation.target and GameConfig.city.population then
    generation.target=math.max(0,GameConfig.city.population.buildings-1)
end
local boolInitialized = generation.complete or false
local function plotKey(x,z) return math.floor(x+0.5)..":"..math.floor(z+0.5) end
local function remainingPlots()
    return math.max(0, generation.target-generation.consumed)
end
local function publishGeneration()
    Spring.SetGameRulesParam("mosaic_city_initial_plots", generation.consumed)
    Spring.SetGameRulesParam("mosaic_city_spawn_complete", boolInitialized and 1 or 0, {public=true})
    GG.CitySpawnComplete = boolInitialized
end

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.game.culture,
                                                "truck", UnitDefs)
local houseTypeTable = getCultureUnitModelTypes(GameConfig.game.culture,
                                                "house", UnitDefs)

local houseSpawnTypeTable = getCityHouseSpawnTypeTable(GameConfig.game.culture, UnitDefs)

local outerCityHouseTypeTable = removeDictFromDict(houseSpawnTypeTable, getHouseTypeIsInnerCityOnly(GameConfig.game.culture, UnitDefs))

local houseTypeLimitationsTable = generation.houseLimits or getHouseTypeLimitations(UnitDefs)
generation.houseLimits=houseTypeLimitationsTable
local houeArabicDefID = UnitDefNames["house_arab0"].id
local arcologyDefID = UnitDefNames["house_asian1"].id
local initialArcologyPlots = generation.arcologies or 0
local arcologyMinimum = ruinConfig.protectedMinimums[UnitDefs[arcologyDefID].name] or 0

local function isCityHouse(defID)
    return civilianHouseTypeTable[defID]
end

if GameConfig.game.culture == "arab" then
	assert(houseTypeTable[UnitDefNames["house_arab0"].id])
end

if GameConfig.game.culture == "asian" then
	assert(houseTypeTable[UnitDefNames["house_asian0"].id])
end
local loadableTruckType = getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.game.culture)
local refugeeableTruckType = getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.game.culture)
local gaiaTeamID = Spring.GetGaiaTeamID() 

local boolHasCityCenter = generation.hasCityCenter or false
local boolCachedMapManualPlacementResult = nil

allreadyRegistredBuilding = {}
function registerManuallyPlacedHouses(frame)   
    --echo("Manual registering placed houses called " ..frame)   
    counter = 0
    foreach(Spring.GetAllUnits(),
            function(id)
                local defID = spGetUnitDefID(id)
                if isCityHouse(defID) and not GG.CityConstructionSites[id]
                    and not GG.CityRubble[id] and allreadyRegistredBuilding[id] == nil then
                    return id
                end
            end,
            function(id)
                local defID = spGetUnitDefID(id)
                allreadyRegistredBuilding[id] = true
                spSetUnitAlwaysVisible(id, true)
                setCityBuildingBlocking(id)                
                x,y,z = spGetUnitPosition(id)
                --assert(x)
                --assert(z)
                GG.BuildingTable[id] = GG.BuildingTable[id] or {x = x, z = z }
                cityPlotGeometry[id] = {x=x, z=z, defID=defID}
                setHouseStreetNameTooltip(id, x, z, Game, false, UnitDefs, buisnessNeonSigns)
                counter = counter + 1
            end
            )

    return counter
end


local function removeCityRoute(id)
    cityPlotGeometry[id] = nil
    GG.BuildingTable[id] = nil
    allreadyRegistredBuilding[id] = nil
    RouteTabel[id] = nil
    for _, route in pairs(RouteTabel) do
        for i = #route, 1, -1 do
            if route[i] == id then table.remove(route, i) end
        end
    end
end

local function queueDestroyedPlot(id, defID)
    if not reconstruction then return end
    local data = GG.BuildingTable[id]
    local x, y, z = spGetUnitPosition(id)
    if not x and data then x, z = data.x, data.z end
    if not x then return end
    -- Preserve the exact building type, orientation and city plot metadata.
    local plot = reconstruction:Add({x=x, z=z, defID=defID,
        originalUnitID=id, sourceUnitID=id,
        facing=Spring.GetUnitBuildFacing(id) or 0,
        data=data or {x=x,z=z}, plan=GG.HouseAsianUnitPlans[id]})
    removeCityRoute(id)
    return plot
end

function gadget:UnitCreated(id, defID)
    if reconstruction then reconstruction:UnitCreated(id) end
    -- Publish pending construction before the lower-layer placement gadget.
    if GG.CityReconstructionSpawning and isCityHouse(defID) then
        GG.CityConstructionSites[id] = GG.CityReconstructionSpawning
        Spring.SetUnitRulesParam(id, "city_construction", 1, {public=true})
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    local plot = reconstruction and reconstruction:LostUnit(unitID)
    GG.CityConstructionSites[unitID], GG.CityRubble[unitID] = nil, nil
    if isCityHouse(unitDefID) then
        -- A rubble member is already the remains, not another destroyed house.
        -- Managed rubble/site deaths are handled by LostUnit above.
        if not plot and not scrapHeapTypeTable[unitDefID] then
            queueDestroyedPlot(unitID, unitDefID)
        end
        removeCityRoute(unitID)
        local safehouse = GG.houseHasSafeHouseTable and GG.houseHasSafeHouseTable[unitID]
        if safehouse then
            GG.houseHasSafeHouseTable[unitID] = nil
            if doesUnitExistAlive(safehouse) then spDestroyUnit(safehouse, true, false) end
        end
    end
    GG.HouseAsianUnitPlans[unitID] = nil
end

-- Neither player repairs nor reclaim/build power may advance a managed site.
function gadget:AllowUnitBuildStep(builderID, builderTeam, unitID)
    return GG.CityConstructionSites[unitID] == nil
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
    -- Decorative, map-placed and reconstruction rubble share the same policy.
    -- Do not derive house walkability from which model pieces remain visible.
    local rubble = scrapHeapTypeTable[spGetUnitDefID(id)] ~= nil
    local isblocking = rubble
    local isSolidObjectCollidable = rubble
    local isProjectileCollidable= true
    local isRaySegmentCollidable = true
    local crushable = false
    local blockEnemyPushing= true
    local blockHeightChanges = true

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

function hasAlreadyBuilding(x,z, range, defID)
    local allPreviousBuildings = GG.BuildingTable
    for id, data in pairs(allPreviousBuildings) do
        local placed = cityPlotGeometry[id] or data
        local dx, dz = x - placed.x, z - placed.z
        if dx * dx + dz * dz < range * range then return true end
        -- Full-size rubble must not be copied into the 128-elmo filler spaces.
        -- Check actual jittered positions, not just ideal grid coordinates.
        local otherDefID = placed.defID or spGetUnitDefID(id)
        if ruinTypeTable[defID] or ruinTypeTable[otherDefID] then
            local separation = ruinConfig.ruinFootprintSize + ruinConfig.plotClearance
            if math.abs(dx) < separation and math.abs(dz) < separation then return true end
        end
    end

    return false
end

-- check Traversability from each position to the previous position	
function validateBuildSpotsReachable(start, endindex)
    tileX, tileZ = houseStreetDim.x, houseStreetDim.z

    for x = start, endindex, 1 do
        for z = 1, #BuildingPlaceTable[1] do
            startx, startz = x * tileX, z * tileZ

            BuildingPlaceTable[x][z] = false
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
                                        slope < 0.2 and not occupiedGrid[plotKey(x,z)]
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
    -- An explicitly authored ruin remains one plot, never a source of replicas.
    if ruinTypeTable[buildingType] then return end
    local cursor = cursorl
    orgPosX, orgPosZ= cursor.x*houseStreetDim.x, cursor.z*houseStreetDim.z
    for offsx = -1, 1, 1 do
        for offsz = -1, 1, 1 do
            if isOnInnerCityGridBlock(cursor, offsx, offsz) == true then                
                if  hasAlreadyBuilding(orgPosX + (offsx * innerCityDim.x),  orgPosZ + offsz * innerCityDim.z, 35) == false  then
						houseID = spawnBuilding(buildingType, 
									orgPosX + offsx * innerCityDim.x,
									orgPosZ + offsz * innerCityDim.z,
									true, true)
						if houseID then
                           setHouseStreetNameTooltip(houseID, (cursor.x*2) + offsx, (cursor.z*2) + offsz, Game, true, UnitDefs, buisnessNeonSigns)
						end
                end
            end    
        end
    end
end

function cursorIsOnMainRoad(cursor, sx, sz)
    return ((cursor.x - sx) % GameConfig.city.streets.mainStreetModulo == 0) or
               ((cursor.z - sz) % GameConfig.city.streets.mainStreetModulo == 0)
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

function getBuildingTypeWithinLimits()
    buildingType = randDict(houseSpawnTypeTable)
    if houseTypeLimitationsTable[buildingType] then
        if houseTypeLimitationsTable[buildingType] > 0 then
            houseTypeLimitationsTable[buildingType] = houseTypeLimitationsTable[buildingType] -1 
            return buildingType
        else           
            return randDict(outerCityHouseTypeTable)
        end
    else
        return buildingType
    end
end

-- spawns intial buildings
function fromMapCenterOutwards(BuildingPlaceT, startx, startz)
    local finiteSteps = generation.steps or GameConfig.performance.maxCityGenerationSteps
    local cursor = generation.cursor or {x=startx,z=startz}
    local mirror = generation.mirror or {x=startx,z=startz}
    local numberOfBuildings = remainingPlots()
    generation.running = true
    local cityBlockCounter = generation.blocks or 0

    while finiteSteps > 0 and numberOfBuildings > 0 and remainingPlots() > 0 do
        finiteSteps = finiteSteps - 1
        generation.steps=finiteSteps
        generation.cursor,generation.mirror=cursor,mirror

        dice = math.floor(math.random(5, 31) / 10)

        boolNearCityCenter, distanceToCityCenter = isNearCityCenter(cursor.x * houseStreetDim.x, cursor.z*houseStreetDim.z, GameConfig)
        boolMirrorNearCityCenter, mirrorDistanceToCityCenter = isNearCityCenter(mirror.x * houseStreetDim.x, mirror.z*houseStreetDim.z, GameConfig)

        if dice == 1 or (dice == 0 and GameConfig.game.culture == "arabic")then -- 1 random walk into a direction doing nothing
            cursor = randomWalk(cursor)
            cursor = clampCursor(cursor)
            mirror = mirrorCursor(cursor, startx, startz)
            mirror = clampCursor(mirror)

        elseif dice == 2 or (dice == 0 and GameConfig.game.culture ~= "arabic")  then -- 2 place a single block
            boolFirstPlaced = false
            dimX,dimZ = houseStreetDim.x, houseStreetDim.z

            if BuildingPlaceT[cursor.x][cursor.z] == true and  isOnRoad(cursor) == false then
                buildingType = getBuildingTypeWithinLimits()
               
                houseID = spawnBuilding(buildingType, cursor.x * dimX, cursor.z * dimZ, boolNearCityCenter)
				if houseID then
					setHouseStreetNameTooltip(houseID, cursor.x*2 , cursor.z*2, Game, false, UnitDefs, buisnessNeonSigns)

					numberOfBuildings = numberOfBuildings - 1
					BuildingPlaceT[cursor.x][cursor.z] = false
					boolFirstPlaced = true
					if boolNearCityCenter == true then
						 fillGapsWithInnerCityBlocks(cursor,  buildingType)
					end
                end
            end

            if boolFirstPlaced == true and BuildingPlaceT[mirror.x][mirror.z] == true and isOnRoad(mirror) == false then
                buildingType = getBuildingTypeWithinLimits()
                houseID = spawnBuilding(buildingType, mirror.x * dimX, mirror.z * dimZ, boolMirrorNearCityCenter)
                if houseID then
					setHouseStreetNameTooltip(houseID, mirror.x*2 , mirror.z*2, Game, false, UnitDefs, buisnessNeonSigns)
					--echo("Placed Single Mirror")
					numberOfBuildings = numberOfBuildings - 1
					BuildingPlaceT[mirror.x][mirror.z] = false
					if boolMirrorNearCityCenter == true then
						 fillGapsWithInnerCityBlocks(mirror,  buildingType)
					end
                end
            end

        elseif dice == 3 then
            cityBlockCounter = cityBlockCounter + 1
            generation.blocks=cityBlockCounter
            if cityBlockCounter > 1 and boolHasCityCenter == false then
                boolHasCityCenter = true
                generation.hasCityCenter=true
                if maRa()== true then
                     GG.innerCityCenter.x = cursor.x*houseStreetDim.x
                     GG.innerCityCenter.z = cursor.z*houseStreetDim.z
                     boolNearCityCenter = true
                else
                    GG.innerCityCenter.x = mirror.x*houseStreetDim.x
                    GG.innerCityCenter.z = mirror.z*houseStreetDim.z
                    Spring.SetGameRulesParam ( "innerCityCenter", GG.innerCityCenter.x.."|"..GG.innerCityCenter.z ) 
                    boolMirrorNearCityCenter = true
                end
             --   echo("Citycenter at:"..GG.innerCityCenter.x .." / "..GG.innerCityCenter.z)
            end


            numberOfBuildings, BuildingPlaceT =  placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings,
                                                   BuildingPlaceT, boolNearCityCenter, distanceToCityCenter)

            numberOfBuildings, BuildingPlaceT =  placeThreeByThreeBlockAroundCursor(mirror, numberOfBuildings,
                                                   BuildingPlaceT, boolMirrorNearCityCenter, distanceToCityCenter)
        end
    end
    generation.running = false
end

function checkCursorInnerCityFree(cursor)
    return BuildingPlaceT[cursor.x][cursor.z] and BuildingPlaceT[cursor.x +1][cursor.z] and BuildingPlaceT[cursor.x ][cursor.z+1]and BuildingPlaceT[cursor.x +1 ][cursor.z +1]
end

function placeThreeByThreeBlockAroundCursor(cursor, numberOfBuildings,  BuildingPlaceT, boolNearCityCenter, distanceToCityCenter)
    buildingType = randDict(houseSpawnTypeTable)

        for offx = -1, 1, 1 do
            if BuildingPlaceT[cursor.x + offx] then
                for offz = -1, 1, 1 do
                    if BuildingPlaceT[cursor.x + offx][cursor.z + offz] then
                        local tmpCursor = {x =cursor.x + offx, z = cursor.z + offz}
                        local nameCursor = {x =(cursor.x*2) + offx, z =(cursor.z*2) + offz}
                        tmpCursor = clampCursor(tmpCursor)  
                        buildingType = getBuildingTypeWithinLimits()                  
                        if BuildingPlaceT[tmpCursor.x] and BuildingPlaceT[tmpCursor.x][tmpCursor.z] and BuildingPlaceT[tmpCursor.x][tmpCursor.z] == true then
                            houseID = spawnBuilding(buildingType,
                                          tmpCursor.x * houseStreetDim.x,
                                          tmpCursor.z * houseStreetDim.z, boolNearCityCenter)
							if houseID then
								numberOfBuildings = numberOfBuildings - 1
								setHouseStreetNameTooltip(houseID, nameCursor.x , nameCursor.z, Game, true, UnitDefs, buisnessNeonSigns)
								if boolNearCityCenter == true then
									fillGapsWithInnerCityBlocks({x=tmpCursor.x, z=tmpCursor.z}, buildingType, BuildingPlaceT)
								end

								BuildingPlaceT[tmpCursor.x][tmpCursor.z] = false
							end
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
    if isMapControlledBuildingPlacement() or distributedPathValidationComplete(frame, 10) == true then
        if  isMapControlledBuildingPlacement() == false then
        -- spawn Buildings from MapCenter Outwards
        fromMapCenterOutwards(BuildingPlaceTable,
                              math.ceil(#BuildingPlaceTable/2),
                              math.ceil(#BuildingPlaceTable[1]/2)
                              )
            boolInitialized = true
            generation.complete = true
            publishGeneration()
            regenerateRoutesTable()
            Spring.SetGameRulesParam("mosaic_city_spawn_complete", 1, {public = true})
            --echo("spawnInitialHouses: Default Initialization completed")
        else
           conditionalEcho(boolDebug, "ManualPlacementInitialization::Starting")
           if boolInitialized then return end
           registeredUnits = registerManuallyPlacedHouses(frame ) 
           conditionalEcho(boolDebug, "ManualPlacementInitialization::Registering Units manually" ..registeredUnits)
           -- Reconciliation may already have registered every map house.
           -- Readiness depends on the live registry, not additions this frame.
           boolInitializationPreqrequisitsFullfiled = (next(GG.BuildingTable) ~= nil and Spring.GetGameFrame() > originalGameFrame)
           if not boolInitializationPreqrequisitsFullfiled then return end
           GG.CitySpawnComplete = true
           regenerateRoutesTable()
           Spring.SetGameRulesParam("mosaic_city_spawn_complete", 1, {public = true})
           boolInitialized = true
           generation.complete = true
           publishGeneration()
           conditionalEcho(boolDebug, "ManualPlacementInitialization::Completed")
        end
    end
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

function getCultureDependentDirection(culture, defID)
    if culture == "arabic" then return 0 end
    if defID == houeArabicDefID then return 0 end
    
    return math.max(1, math.floor(math.random(1, 3)))
 end

function spawnUnit(defID, x, z)
    if not x then
        echo("Spawning unit of typ " .. UnitDefs[defID].name ..
                 " with no coords")
    end
    
    dir = getCultureDependentDirection(GameConfig.game.culture, defID)
    h = spGetGroundHeight(x, z)
    local plan
    if UnitDefNames.house_asian0 and defID == UnitDefNames.house_asian0.id then
        plan = asianSplit.choose(asianSplitState, x, z, Game.mapName)
        defID = assert(UnitDefNames[plan.unitName], "Missing Asian split UnitDef: " .. plan.unitName).id
    end
    id = spCreateUnit(defID, x, h, z, dir, gaiaTeamID)

    if id then
        if plan then
            -- buildHouse yields before assembly, so the plan is present even
            -- when LuaUnitScript.Create runs synchronously inside CreateUnit.
            GG.HouseAsianUnitPlans[id] = plan
            asianSplit.commit(asianSplitState, plan)
            if Spring.SetUnitRulesParam and plan.group then
                Spring.SetUnitRulesParam(id, "city_asian_group", plan.group.id)
            end
        end
        spSetUnitAlwaysVisible(id, true)
        return id
    end
end

function spawnBuilding(defID, x, z, boolInCityCenter, isGapFiller, forceArcology)
    if generation.running and (generation.seen[plotKey(x,z)] or (not isGapFiller and remainingPlots()<=0)) then return end
    -- Allocate real city plots, not the small blocks filling gaps between them.
    -- Count successful placements only, so a failed CreateUnit is retried.
    local reserveArcology = not boolInitialized and not isGapFiller and ruinCandidateTypeTable[defID]
        and initialArcologyPlots < arcologyMinimum
    if reserveArcology or forceArcology then
        defID = arcologyDefID
    elseif isGapFiller then
        if ruinTypeTable[defID] then return end
    elseif ruinCandidateTypeTable[defID] and #ruinDefIDs > 0
        and cityRuins.ShouldRuin(cityGeography.hash, x, z, cityGeography.latitude, ruinConfig) then
        local choice = math.floor(cityRuins.PlotRoll(cityGeography.hash + 7919, x, z) * #ruinDefIDs) + 1
        defID = ruinDefIDs[choice]
    end
    local offset = {xRandOffset = 0, zRandOffset = 0}
    if not boolInCityCenter  then
         offset = getCultureDependantRandomOffsets(GameConfig.game.culture, {x=x, z=z})
		 if not offset then return end
    end
    local spawnX = x + math.random(-1 * offset.xRandOffset, offset.xRandOffset)
    local spawnZ = z + math.random(-1 * offset.zRandOffset, offset.zRandOffset)
    if hasAlreadyBuilding(spawnX, spawnZ, 35, defID) then return end
    if generation.running and not validFinalCityPlot(spawnX,spawnZ,isGapFiller) then return end
    local id = spawnUnit(defID, spawnX, spawnZ)

    if id then
        -- Record a successful plot before tooltips/other callbacks can fail.
        local key=plotKey(x,z)
        GG.BuildingTable[id] = {x=x,z=z,arcology=reserveArcology or forceArcology or nil,
            gapFiller=isGapFiller or false}
        cityPlotGeometry[id] = {x=spawnX,z=spawnZ,defID=defID}
        local ix,iz=math.floor(x/houseStreetDim.x+0.5),math.floor(z/houseStreetDim.z+0.5)
        if not isGapFiller then occupiedGrid[plotKey(ix,iz)]=true end
        if not generation.seen[key] then
            generation.seen[key]=true
            if not isGapFiller then generation.consumed=generation.consumed+1 end
        end
        if reserveArcology then initialArcologyPlots=initialArcologyPlots+1 end
        generation.arcologies=initialArcologyPlots
        if Spring.SetUnitRulesParam then
            Spring.SetUnitRulesParam(id,"city_plot_x",x,{public=true})
            Spring.SetUnitRulesParam(id,"city_plot_z",z,{public=true})
            Spring.SetUnitRulesParam(id,"city_gap_filler",isGapFiller and 1 or 0)
            Spring.SetUnitRulesParam(id,"city_arcology_plot",(reserveArcology or forceArcology) and 1 or 0)
        end
        if Spring.SetGameRulesParam then publishGeneration() end
        spSetUnitAlwaysVisible(id, true)
        setCityBuildingBlocking(id)
        return id
    end
end

-- Validate the final footprint, including jitter and inner-city fillers.
function validFinalCityPlot(x,z,filler)
    local rx=(filler and innerCityDim.x or GameConfig.city.buildings.sizeX)*0.5
    local rz=(filler and innerCityDim.z or GameConfig.city.buildings.sizeZ)*0.5
    if x-rx<0 or z-rz<0 or x+rx>Game.mapSizeX or z+rz>Game.mapSizeZ then return false end
    for dx=-1,1 do for dz=-1,1 do
        local px,pz=x+dx*rx,z+dz*rz
        local _,ny,_,slope=spGetGroundNormal(px,pz)
        if spGetGroundHeight(px,pz)<=5 or (slope or (1-(ny or 0)))>=0.2 then return false end
    end end
    -- An established road is infrastructure, not an empty plot to overwrite.
    local service=GG.CityAddressService
    if service and service.NearestRoad then
        local near=service.NearestRoad(x,z)
        if near and near.distance<(math.min(rx,rz)+(near.road.width or GameConfig.city.alleys.sizeX)*0.5)^2 then return false end
    end
    return true
end

-- Reconcile live units without touching their models, health, occupants or plans.
function reconcileCity()
    local ids=Spring.GetAllUnits();table.sort(ids)
    local living, count, mainPlots, arcologies = {},0,0,0
    occupiedGrid={}
    for _,id in ipairs(ids) do
        local defID=spGetUnitDefID(id)
        if isCityHouse(defID) and not GG.CityConstructionSites[id] and not GG.CityRubble[id]
            and (not Spring.GetUnitIsDead or not Spring.GetUnitIsDead(id)) then
            local x,_,z=spGetUnitPosition(id)
            local data=GG.BuildingTable[id] or {}
            data.x=data.x or unitRule(id,"city_plot_x") or x
            data.z=data.z or unitRule(id,"city_plot_z") or z
            if data.gapFiller==nil then data.gapFiller=unitRule(id,"city_gap_filler")==1 end
            data.arcology=data.arcology or unitRule(id,"city_arcology_plot")==1
            GG.BuildingTable[id]=data
            cityPlotGeometry[id]={x=x,z=z,defID=defID}
            living[id]=true;count=count+1
            local key=plotKey(data.x,data.z)
            if not data.gapFiller then mainPlots=mainPlots+1 end
            if not generation.seen[key] then
                generation.seen[key]=true
                if generation.reconciled and not data.gapFiller then generation.consumed=generation.consumed+1 end
            end
            if data.arcology or defID==arcologyDefID then arcologies=arcologies+1 end
            local group=unitRule(id,"city_asian_group")
            if group then asianSplitState.used[group]=true end
            allreadyRegistredBuilding[id]=true
            spSetUnitAlwaysVisible(id,true);setCityBuildingBlocking(id)
            -- On a full LuaRules reload the address gadget initializes later.
            -- It reconciles this table when ready; retain existing tooltips now.
            if GG.CityAddressService then
                setHouseStreetNameTooltip(id,data.x,data.z,Game,false,UnitDefs,buisnessNeonSigns)
            end
        end
    end
    for id in pairs(GG.BuildingTable) do
        if not living[id] then GG.BuildingTable[id]=nil;cityPlotGeometry[id]=nil;allreadyRegistredBuilding[id]=nil end
    end
    generation.consumed=math.max(generation.consumed,mainPlots)
    generation.reconciled=true
    initialArcologyPlots=math.max(initialArcologyPlots,arcologies)
    generation.arcologies=initialArcologyPlots
    -- Every retained plot (also rubble/construction) reserves its grid cell.
    local function reserve(x,z)
        local ix,iz=math.floor(x/houseStreetDim.x+0.5),math.floor(z/houseStreetDim.z+0.5)
        occupiedGrid[plotKey(ix,iz)]=true
        if BuildingPlaceTable[ix] then BuildingPlaceTable[ix][iz]=false end
    end
    for _,data in pairs(cityPlotGeometry) do reserve(data.x,data.z) end
    if reconstruction then for _,plot in pairs(reconstruction.plots) do reserve(plot.x,plot.z) end end
    publishGeneration()
    return count
end

local function reloadCityCommand(_,line)
    local action=(line or ""):match("^%s*(.-)%s*$")
    if action=="status" then
        Spring.Echo("City: "..(boolInitialized and "complete" or generation.failed and "paused after error" or "generating")
            ..", initial plots="..generation.consumed..", remaining="..remainingPlots())
        return true
    end
    if action~="" then Spring.Echo("Usage: /luarules cityreload [status]");return true end
    if not Spring.IsCheatingEnabled() then Spring.Echo("City reload requires /cheat; status is always available.");return true end
    local count=reconcileCity()
    generation.failed=false
    if GG.CityAddressService and GG.CityAddressService.Reconcile then GG.CityAddressService.Reconcile() end
    regenerateRoutesTable()
    Spring.Echo("City reload: integrated "..count.." buildings; remaining initial plots="..remainingPlots()
        .."; "..(boolInitialized and "completed city retained" or "unfinished generation will resume"))
    return true
end

function killAllUnitsAtGamestart()
 foreach(Spring.GetAllUnits(),
            function(id) 
                Spring.DestroyUnit(id, true, true) 
            end)
end

originalGameFrame = -math.huge
function gadget:Initialize()
    setupCityReconstruction()
    -- Initialize global tables
    Spring.Echo(Game.mapName.. " is a map controlled city place map "..toString(isMapControlledBuildingPlacement()))
    if not  GG.BuildingTable then  GG.BuildingTable = {} end
    if not  GG.innerCityCenter then  GG.innerCityCenter = {} end

    reconcileCity()
    publishGeneration()
    if gadgetHandler.AddChatAction then
        gadgetHandler:AddChatAction("cityreload",reloadCityCommand,"[status]: reconcile existing infrastructure; reload requires cheats")
    end
    Spring.SetGameRulesParam ( "culture",GameConfig.game.culture )
    Spring.SetGameRulesParam("mosaic_city_country", cityGeography.country, {public=true})
    Spring.SetGameRulesParam("mosaic_city_latitude", cityGeography.latitude, {public=true})
    Spring.SetGameRulesParam("mosaic_city_ruin_chance", cityRuins.Chance(cityGeography.latitude, ruinConfig), {public=true})
    --killAllUnitsAtGamestart()
originalGameFrame = Spring.GetGameFrame()
end


local function setConstructionProgress(id, progress)
    local hp, maxHP, _, _, previous = Spring.GetUnitHealth(id)
    if not hp then return end
    -- Construction adds only the health earned by new work; pausing cannot heal
    -- incoming damage and finishing does not wipe out battle damage.
    local health = math.min(maxHP, hp + maxHP * math.max(0, progress - (previous or 0)))
    Spring.SetUnitHealth(id, {build=progress, health=health})
end

function setupCityReconstruction()
    reloadSnapshot = VFS.Include("luarules/gadgets/include/city_reload_snapshot.lua")
    local retained=GG.CityReconstruction
    if not retained and reloadSnapshot then
        retained=reloadSnapshot.Load(Spring)
        if retained and retained.generation then
            generation=retained.generation
            generation.target=generation.target or math.max(0,GameConfig.city.population.buildings-1)
            generation.running=false
            GG.CityGenerationState=generation
            houseTypeLimitationsTable=generation.houseLimits or houseTypeLimitationsTable
            boolHasCityCenter=generation.hasCityCenter or false
            if retained.center then GG.innerCityCenter=retained.center end
            boolInitialized=generation.complete or false
            initialArcologyPlots=generation.arcologies or 0
            if retained.asianState then
                asianSplitState=retained.asianState
                GG.HouseAsianSplitState=asianSplitState
            end
            GG.HouseAsianUnitPlans=retained.plans or GG.HouseAsianUnitPlans
        end
    end
    if retained then
        for _,plot in pairs(retained.plots) do
            if plot.unitID then
                if plot.stage=="rubble" then GG.CityRubble[plot.unitID]=plot
                else GG.CityConstructionSites[plot.unitID]=plot end
            end
        end
    end
    local cfg = GameConfig.city.rubble
    reconstruction = newReconstruction(cfg, {
        Alive = doesUnitExistAlive,
        Exists = Spring.ValidUnitID,
        Peaceful = function(plot)
            local state = GG.GlobalGameState
            if state == GameConfig.game.states.anarchy
                or state == GameConfig.game.states.postLaunch
                or state == GameConfig.game.states.gameOver then
                return false, state
            end
            if not GG.CityAreaState then return false, 'area-state-unavailable' end
            if not GG.CityAreaState:IsPeaceful(plot.x, plot.z) then
                return false, 'combat-or-quiet-period'
            end
            return true, 'none'
        end,
        CreateRubble = function(plot)
            local rubbleDefID = randDict(scrapHeapTypeTable)
            plot.rubbleDefID = rubbleDefID
            local id = spCreateUnit(rubbleDefID, plot.x,
                spGetGroundHeight(plot.x, plot.z), plot.z, plot.facing, gaiaTeamID)
            if id then
                GG.CityRubble[id] = plot
                -- All city houses are always visible. The replacement must
                -- inherit that policy for every rubble model, including ruins
                -- whose unit script does not enable it on its own.
                spSetUnitAlwaysVisible(id, true)
                setCityBuildingBlocking(id)
            end
            return id
        end,
        CreateSite = function(plot)
            -- Release only the old rubble during the same-tick replacement.
            -- A failed creation must leave it blocking, not open the plot.
            local rubbleID = plot.unitID
            if rubbleID then spSetUnitBlocking(rubbleID, false, false) end
            GG.CityReconstructionSpawning = plot
            local id = spCreateUnit(plot.defID, plot.x, spGetGroundHeight(plot.x, plot.z),
                plot.z, plot.facing, gaiaTeamID, true, false)
            GG.CityReconstructionSpawning = nil
            if id then
                GG.CityConstructionSites[id] = plot
                if plot.plan then GG.HouseAsianUnitPlans[id] = plot.plan end
                spSetUnitAlwaysVisible(id, true)
                setCityBuildingBlocking(id)
                setConstructionProgress(id, 0.01)
                Spring.SetUnitRulesParam(id, "city_construction", 1, {public=true})
                Spring.SetUnitTooltip(id, "Construction site — awaiting peaceful completion")
            elseif rubbleID then
                setCityBuildingBlocking(rubbleID)
            end
            return id
        end,
        RemoveRubble = function(id)
            GG.CityRubble[id] = nil
            spDestroyUnit(id, false, true)
        end,
        Complete = function(plot)
            local id = plot.unitID
            GG.CityConstructionSites[id] = nil
            GG.BuildingTable[id] = plot.data
            allreadyRegistredBuilding[id] = true
            Spring.SetUnitRulesParam(id, "city_construction", 0, {public=true})
            Spring.SetUnitRulesParam(id, "city_rebuild_progress", 1, {public=true})
            Spring.SetUnitRulesParam(id, "city_rebuild_paused", 0, {public=true})
            setConstructionProgress(id, 1)
            -- SetUnitHealth completion need not send UnitFinished on every engine.
            if GG.RefreshCityBuildingMask then GG.RefreshCityBuildingMask(id) end
            setHouseStreetNameTooltip(id, plot.data.x, plot.data.z, Game, false, UnitDefs, buisnessNeonSigns)
            routesDirty = true
        end,
        Publish = function(plot)
            local duration = plot.stage == "rubble" and cfg.decayFrames or cfg.constructionFrames
            local progress = math.min(1, plot.elapsed / duration)
            Spring.SetUnitRulesParam(plot.unitID, "city_rebuild_progress", progress, {public=true})
            Spring.SetUnitRulesParam(plot.unitID, "city_rebuild_paused", plot.paused and 1 or 0, {public=true})
            if plot.stage == "construction" then
                setConstructionProgress(plot.unitID, math.max(0.01, math.min(0.99, progress)))
            end
        end,
    }, retained)
    GG.CityReconstruction = reconstruction
end

function gadget:GameFrame(frame)

    if boolInitialized == false and not generation.failed then
        local ok,err=pcall(spawnInitialHouses,frame)
        generation.running=false
        if not ok then
            generation.failed=true
            Spring.Echo("City generation paused after error; existing plots retained. Fix the error, then /luarules cityreload: "..tostring(err))
        end
    end
    if frame > 0 and frame % 15 == 0 then
        reconstruction:Update(15)
        if routesDirty then
            routesDirty = false
            regenerateRoutesTable()
        end
    end
end


function gadget:Shutdown()
    if reloadSnapshot then reloadSnapshot.Save(Spring,reconstruction,GG) end
    if gadgetHandler.RemoveChatAction then gadgetHandler:RemoveChatAction("cityreload") end
end
