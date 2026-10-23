function gadget:GetInfo()
    return {
        name = "Building Flight Clearance",
        desc = "Computes the initial city's highest physical roof once for all Icarus units",
        author = "Mosaic contributors", license = "GNU GPL, v2 or later",
        layer = -9, enabled = true,
    }
end
if not gadgetHandler:IsSyncedCode() then return false end

local environment = (getfenv and getfenv(1)) or _ENV
local config = VFS.Include("scripts/lib_mosaic.lua",
    setmetatable({MOSAIC_CONFIG_ONLY=true}, {__index=environment}))
local bounds = VFS.Include("scripts/lib_building_clearance.lua")
local houseTypes = config.getCivilianHouseTypeTable(UnitDefs)
local buildingTypes = {}
for id, def in pairs(UnitDefs) do
    local cp = def.customParams or {}
    local physical = tostring(cp.baseclass or ""):lower() == "building"
    if houseTypes[id] or (physical and not def.canFly and (def.isBuilding or not def.canMove)) then
        buildingTypes[id] = true
    end
end

local HEIGHT_RULE, READY_RULE = "icarus_city_roof_height", "icarus_city_roof_ready"
local MAX_MEASUREMENTS_PER_FRAME = 4
local snapshot, resolved, queued, queue = {}, {}, {}, {}
local head, tail, remaining, maximum = 1, 0, 0, 0
local started, frozen = false, false
local savedPlacementComplete, deadlineFrame, planningTimedOut
local PLANNING_TIMEOUT_FRAMES = 60 * ((Game and Game.gameSpeed) or 30)
local markDirty
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function stopInitialization()
    frozen = true
    if GG.MarkBuildingClearanceDirty == markDirty then GG.MarkBuildingClearanceDirty = nil end
    gadgetHandler:RemoveCallIn("GameFrame")
    gadgetHandler:RemoveCallIn("UnitDestroyed")
    snapshot, resolved, queued, queue = {}, {}, {}, {}
end

local function finish()
    if not started or remaining ~= 0 or frozen then return end
    GG.IcarusSkylineHeight, GG.IcarusSkylineReady = maximum, true
    Spring.SetGameRulesParam(HEIGHT_RULE, maximum, {public=true})
    Spring.SetGameRulesParam(READY_RULE, 1, {public=true})
    stopInitialization()
end

local function resolve(unitID, roof)
    if not snapshot[unitID] or resolved[unitID] then return end
    if finite(roof) then maximum = math.max(maximum, roof) end
    resolved[unitID], queued[unitID] = true, nil
    remaining = remaining - 1
end

markDirty = function(unitID)
    -- Before the snapshot, the getter retains readiness. After it, only an
    -- unresolved initial-city building can enter the one-time measurement queue.
    if frozen or not started or not snapshot[unitID] or resolved[unitID] or queued[unitID] then return end
    queued[unitID] = true
    tail = tail + 1
    queue[tail] = unitID
end

local function takeSnapshot(frame)
    started = true
    deadlineFrame = frame + PLANNING_TIMEOUT_FRAMES
    -- Exactly one world query, after generated or map-authored city placement
    -- completes. Later construction/destruction cannot change the frozen result.
    for _, unitID in ipairs(Spring.GetAllUnits()) do
        local defID = Spring.GetUnitDefID(unitID)
        if buildingTypes[defID] then
            snapshot[unitID] = defID
            remaining = remaining + 1
            markDirty(unitID)
        end
    end
end

local function measure(unitID)
    if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID)
        or Spring.GetUnitDefID(unitID) ~= snapshot[unitID] then
        resolve(unitID)
        return
    end
    local roof
    if houseTypes[snapshot[unitID]] then
        local env = Spring.UnitScript.GetScriptEnv(unitID)
        local getter = env and env.GetBuildingClearancePieces
        local pieces, providerFailed
        if type(getter) == "function" then
            Spring.UnitScript.CallAsUnit(unitID, function()
                -- Catch inside CallAsUnit so its active-unit context is always
                -- restored by the wrapper, even when a house getter fails.
                local ok, result = pcall(getter)
                if ok then pieces = result else providerFailed = true end
            end)
        end
        -- Wait for planning-ready events, never poll or use hidden model bounds.
        local unready = pieces == nil or pieces == false
        if unready and not providerFailed and not planningTimedOut then return end
        roof = not unready and bounds.SelectedRoof(Spring, unitID, pieces)
        if not finite(roof) then
            roof = bounds.CollisionRoof(Spring, unitID)
            local reason = providerFailed and "selection provider failed"
                or (unready and "planning timed out" or "selected roof unavailable")
            Spring.Echo("Building Flight Clearance: "..reason.." for unit "
                ..unitID.."; using its physical collision envelope")
        end
    else
        roof = bounds.ModelRoof(Spring, unitID)
    end
    resolve(unitID, roof)
end

function gadget:Initialize()
    local saved = Spring.GetGameRulesParam(HEIGHT_RULE)
    if Spring.GetGameRulesParam(READY_RULE) == 1 and finite(saved) then
        GG.IcarusSkylineHeight, GG.IcarusSkylineReady = saved, true
        stopInitialization()
        return
    end
    GG.IcarusSkylineHeight, GG.IcarusSkylineReady = 0, false
    savedPlacementComplete = Spring.GetGameRulesParam("mosaic_city_spawn_complete") == 1
    GG.MarkBuildingClearanceDirty = markDirty
end

function gadget:UnitDestroyed(unitID)
    if frozen then return end
    -- Only unresolved snapshot members matter during initialization. Completed
    -- measurements stay in the aggregate even if that building is later lost.
    resolve(unitID)
    finish()
end

function gadget:GameFrame(frame)
    if frozen then return end
    if not started then
        if not GG.CitySpawnComplete and not (GG.CitySpawnComplete == nil and savedPlacementComplete) then return end
        takeSnapshot(frame or Spring.GetGameFrame())
    end
    if not planningTimedOut and frame and frame >= deadlineFrame then
        -- A failed unit script must not block every Icarus forever. Visit the
        -- captured unresolved IDs once, then use the same bounded queue and a
        -- physical collision fallback. No new world scan/readiness polling.
        planningTimedOut = true
        for unitID in pairs(snapshot) do
            if not resolved[unitID] then markDirty(unitID) end
        end
    end
    local processed = 0
    while head <= tail and processed < MAX_MEASUREMENTS_PER_FRAME do
        local unitID = queue[head]
        queue[head], head = nil, head + 1
        processed = processed + 1
        if queued[unitID] and not resolved[unitID] then
            queued[unitID] = nil
            measure(unitID)
        end
    end
    if head > tail then head, tail = 1, 0 end
    finish()
end

function gadget:Shutdown()
    if GG.MarkBuildingClearanceDirty == markDirty then GG.MarkBuildingClearanceDirty = nil end
end
