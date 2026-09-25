-- Run from the repository root with Lua 5.1+.
local function loadEnv(path, env)
    setmetatable(env, {__index = _G})
    local f
    if setfenv then f = assert(loadfile(path)); setfenv(f, env)
    else f = assert(loadfile(path, 't', env)) end
    f()
    return env
end
local function noop() end
local function count(t)
    local n = 0; for _ in pairs(t) do n = n + 1 end; return n
end
local function foreach(t, ...)
    local result, callbacks = {}, {...}
    for _, value in pairs(t) do
        for _, fn in ipairs(callbacks) do
            if value == nil then break end
            value = fn(value)
        end
        if value ~= nil then result[#result + 1] = value end
    end
    return result
end
local config = {MegaBuildingMax = 12, houseSizeX = 100, houseSizeY = 100,
    houseSizeZ = 100, allyWaySizeX = 20, allyWaySizeZ = 20,
    instance = {culture = 'western'}}
local arcPieces, projectPieces = {10,20,30,40}, {110,120,130,140,150}
local groups = {Arcology = arcPieces, Project = projectPieces}
local pieceNames = {}
for i, id in ipairs(arcPieces) do pieceNames[id] = 'Arcology' .. i end
for i, id in ipairs(projectPieces) do pieceNames[id] = 'Project' .. i end

local function standalone(shared, id, opts)
    opts = opts or {}
    local shown = {}
    local env = loadEnv('scripts/house_asian_standalone_script.lua', {
        GG = shared, unitID = id, unitDefID = 1, script = {}, Game = {},
        UnitDefs = {{name = opts.project and 'house_asian3' or 'house_asian1'}},
        include = noop, piece = function() return -1 end,
        getGameConfig = function() return config end,
        getPieceTableByNameGroups = function() return groups end,
        Spring = {
            GetGaiaTeamID = function() return 0 end,
            GetUnitPieceList = function() return pieceNames end,
            GetUnitPieceMap = function() return {} end,
            GetUnitPosition = function() return opts.x or 99, 0, 0 end,
            GetUnitPieceInfo = function(_, piece)
                return {min={0,0,0}, max={10,10,(piece == 40 or piece == 130) and 3000 or 100}}
            end,
            SetUnitTooltip = noop,
        },
        StartThread = noop, Sleep = function(ms)
            if opts.onSleep then opts.onSleep(ms) end
        end,
        Show = noop, Hide = noop, hideAll = noop,
        showT = function(t) for _, piece in ipairs(t) do shown[piece] = true end end,
        showTSubSubSpins = function() return {} end,
        showTSubSpins = function() return {} end,
        count = count, foreach = foreach, toString = tostring,
        getNthDictElement = function(t, n) return n, t[n] end,
        ViewShadowGameRelevant = function() return opts.filter or false end,
        isNearCityCenter = function() return opts.center or false end,
        isMapControlledBuildingPlacement = function() return opts.manual or false end,
        getDermenisticChance = function() return false end,
        getDeterministicStationaryUnitHash = function() return opts.x or 99 end,
        getDetermenisticMapHash = function() return 0 end,
        randChance = function() return opts.dual or false end,
    })
    env.script.Create()
    env.buildBuilding()
    return env, shown
end
local function containsAny(shown, pieces)
    for _, id in ipairs(pieces) do if shown[id] then return true end end
    return false
end

-- Map-authored cities: all copies used to fail the same UnitDef-based chance.
local shared = {BuildingTable = {}}
for id = 1, 4 do
    shared.BuildingTable[id] = {}
    local _, shown = standalone(shared, id, {manual = true})
    assert(containsAny(shown, arcPieces) == (id <= 3), 'initial arcology minimum')
    assert(not shown[130], 'mega project unexpectedly selected')
end
assert(shared.StandaloneArcologyCount == 3)

-- Explicit Projects must not consume the minimum, even when center chance wins.
local projectShared = {BuildingTable = {}}
local _, projectShown = standalone(projectShared, 1, {project=true, center=true, x=1})
assert(containsAny(projectShown, projectPieces) and not containsAny(projectShown, arcPieces))
assert(projectShared.StandaloneArcologyCount == 0)

-- Additional selection varies by location for identical UnitDefs.
local _, extraArc = standalone(shared, 5, {center=true, x=1})
local _, extraProject = standalone(shared, 6, {center=true, x=99})
assert(containsAny(extraArc, arcPieces) and not containsAny(extraProject, arcPieces))

-- Shared counters may contain ineligible pieces with lower usage. Respect the
-- requested category, sparse candidate tables, filters, and suggested tie break.
local env = standalone(shared, 7, {project=true})
shared.GlobalPieceCounterArcology = {[10]=100, [20]=100, [40]=0, [110]=0}
assert(env.findLowestPieceInTableFromWithSuggestion(2, {[2]=10,[9]=20}) == 20)
assert(env.findLowestPieceInTableFromWithSuggestion(1, {[3]=10}) == 10)

-- A reserved plot stays an arcology outside the center, even after the minimum.
shared.BuildingTable[8] = {arcology=true}
local reserved, shown = standalone(shared, 8, {filter=true, dual=true})
assert(containsAny(shown, arcPieces) and containsAny(shown, projectPieces))
assert(not shown[40] and not shown[130], 'filtered mega model leaked back in')
local before = shared.StandaloneArcologyCount
reserved.script.Killed(1, 1)
assert(shared.StandaloneArcologyCount == before - 1)

-- Another building may reach the mega cap during the staggered selection wait.
local capped = {BuildingTable = {[1]={arcology=true}}, MegaBuildingCount=11,
    GlobalPieceCounterArcology={[10]=100,[20]=100,[30]=100,[40]=0}}
local _, cappedShown = standalone(capped, 1, {onSleep=function(ms)
    if ms == 99 then capped.MegaBuildingCount = 12 end
end})
assert(not cappedShown[40] and capped.MegaBuildingCount == 12)

-- Actual city gadget with engine calls mocked. A non-Asian city gets three
-- full-size reserved plots; fillers and failed creates do not consume them.
local defs = {[1]={id=1,name='house_asian1'}, [2]={id=2,name='house_arab0'},
    [3]={id=3,name='house_ruin'}, [4]={id=4,name='house_western0'}}
local byName = {}; for _, d in pairs(defs) do byName[d.name] = d end
local units, nextID, fail = {}, 100, false
local city = loadEnv('luarules/gadgets/game_spawnCity.lua', {
    GG = {}, gadget = {}, UnitDefs = defs, Game = {mapSizeX=1024,mapSizeZ=1024},
    gadgetHandler = {IsSyncedCode=function() return true end},
    VFS = {Include=noop}, include=function() return {} end,
    getGameConfig=function() return config end,
    getUnitDefNames=function() return byName end,
    getBuildingScrapHeapTypeTable=function() return {} end,
    getBuildingRuinTypeTable=function() return {} end,
    makeTable=function() return {} end,
    getCultureUnitModelTypes=function() return {[4]=4} end,
    getHouseTypeIsInnerCityOnly=function() return {} end,
    removeDictFromDict=function(t) return t end,
    getHouseTypeLimitations=function() return {} end,
    getLoadAbleTruckTypes=noop, getRefugeeAbleTruckTypes=noop,
    getCultureDependantRandomOffsets=function() return {xRandOffset=0,zRandOffset=0} end,
    isMapControlledBuildingPlacement=function() return false end,
    isNearCityCenter=function() return false end,
    doesUnitExistAlive=function(id) return units[id] ~= nil end,
    randDict=function() return 4 end,
    foreach=foreach, setHouseStreetNameTooltip=noop,
    Spring = {
        GetGaiaTeamID=function() return 0 end, GetGroundHeight=function() return 0 end,
        SetUnitAlwaysVisible=noop, SetUnitBlocking=noop,
        GetUnitDefID=function(id) return units[id].def end,
        GetUnitPosition=function(id) return units[id].x,0,units[id].z end,
        GetAllUnits=function() local t={};for id in pairs(units) do t[#t+1]=id end;return t end,
        CreateUnit=function(def,x,y,z)
            if fail then return nil end
            nextID=nextID+1; units[nextID]={def=def,x=x,z=z}; return nextID
        end,
    },
})
local filler = city.spawnBuilding(4,0,0,true,true)
assert(units[filler].def == 4 and not city.GG.BuildingTable[filler].arcology)
fail = true; assert(city.spawnBuilding(4,100,100,true) == nil); fail = false
local arcIDs = {}
for i=1,3 do
    local id = city.spawnBuilding(4,100*i,100*i,true)
    arcIDs[i] = id
    assert(units[id].def == 1 and city.GG.BuildingTable[id].arcology)
end
local normal = city.spawnBuilding(4,500,500,true)
assert(units[normal].def == 4 and not city.GG.BuildingTable[normal].arcology)

units[arcIDs[1]] = nil
fail = true; city.checkReSpawnHouses()
assert(city.GG.BuildingTable[arcIDs[1]].arcology, 'failed rebuild lost plot')
fail = false; city.checkReSpawnHouses()
assert(not city.GG.BuildingTable[arcIDs[1]])
assert(units[nextID].def == 1 and city.GG.BuildingTable[nextID].arcology, 'rebuild lost arcology')

-- Manually placed arcologies are registered even in a non-Asian culture.
city.GG.BuildingTable = {}
assert(city.registerManuallyPlacedHouses(1) == count(units))
assert(city.GG.BuildingTable[arcIDs[2]])
print('PASS: arcology minimum, per-location chance, project identity, model pools, mega filters/cap, city plots and rebuilds')
