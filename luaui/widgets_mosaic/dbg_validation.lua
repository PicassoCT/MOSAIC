function widget:GetInfo()
    return {
        name = 'MOSAIC validation checklist',
        desc = 'One startup TODO list with /validate procedures and read-only status',
        author = 'MOSAIC contributors',
        license = 'GPL3',
        layer = -100,
        enabled = true,
    }
end

local config = VFS.Include('luaui/configs/mosaic_validation.lua')
local tasksByName = {}
for index, task in ipairs(config.tasks) do
    tasksByName[task.id] = task
    tasksByName[tostring(index)] = task
    for _, alias in ipairs(task.aliases or {}) do tasksByName[alias] = task end
end

local lastPrintedGameID
local startupHandled = false

local function echo(text)
    Spring.Echo(config.prefix .. text)
end

local function matchID()
    local id = Spring.GetGameRulesParam(config.gameIDParam)
    if type(id) == 'string' and id ~= '' then return id end
    -- Compatibility with games/engines that also expose the event in Game.
    local fallback = Game and Game.gameID
    if type(fallback) == 'string' and #fallback == 32 and fallback:match('^%x+$') then
        return 'engine:' .. fallback:lower()
    end
end

local function printList()
    echo('TODO: manual in-game validation. Enter each command for setup and the expected result.')
    for index, task in ipairs(config.tasks) do
        echo(string.format('TODO %d/%d: /validate %s - %s', index, #config.tasks, task.id, task.summary))
    end
    echo('/validate status - record renderer readiness and the selected unit in infolog.')
    echo('/validate rebuild status - record queued collapses, rubble creation and reconstruction state in infolog.')
    echo('/validate repeats this list; /validate all prints every procedure. /luaui validate also works.')
    echo('Checks stay TODO until visually verified.')
end

local function printTask(task)
    echo('TODO ' .. task.id .. ': ' .. task.title)
    for index, step in ipairs(task.steps) do echo(tostring(index) .. '. ' .. step) end
    echo('Expected: ' .. task.expect)
    echo('Capture the result and /validate status in the same infolog when reporting a failure.')
end

local function value(v)
    if v == nil then return 'unavailable' end
    return tostring(v)
end

local function readiness(v)
    return v == true and 'ready' or 'unavailable'
end

local function requestRebuildStatus()
    if type(Spring.SendLuaRulesMsg) ~= 'function' then
        echo('Reconstruction status request unavailable in this LuaUI session.')
        return
    end
    local selected = Spring.GetSelectedUnits() or {}
    local id = selected[1]
    local message = config.rebuildStatusMessage
    if type(id) == 'number' and id >= 0 and id == math.floor(id) then
        message = message .. ':' .. tostring(id)
    end
    Spring.SendLuaRulesMsg(message)
    echo('Requested reconstruction state from the simulation; the reply follows in this infolog.')
end

local function selectedStatus()
    local selected = Spring.GetSelectedUnits() or {}
    local unitID = selected[1]
    if not unitID then
        echo('Selected unit: none. Select a tank, house, rubble or construction site for its state.')
        return
    end
    local defID = Spring.GetUnitDefID(unitID)
    if not defID then echo('Selected unit: no longer visible or available.'); return end
    local def = UnitDefs[defID]
    echo('Selected unit: ' .. tostring(unitID) .. ' (' .. value(def and def.name) .. ').')
    local hp, maxHP, _, _, build = Spring.GetUnitHealth(unitID)
    echo('Health=' .. value(hp) .. '/' .. value(maxHP) .. ' build_progress=' .. value(build))
    for _, key in ipairs(config.selectedRules) do
        local v = Spring.GetUnitRulesParam(unitID, key)
        if v ~= nil then echo(key .. '=' .. value(v)) end
    end
end

local function printStatus()
    echo('STATUS frame=' .. value(Spring.GetGameFrame()) .. ' match=' .. value(matchID()) ..
        ' map=' .. value(Game and Game.mapName) .. ' game=' .. value(Game and Game.gameVersion))
    local effects = WG.lighteffects
    local ok, status
    if effects and type(effects.getStatus) == 'function' then ok, status = pcall(effects.getStatus) end
    if ok and type(status) == 'table' then
        echo('Renderers: combat_radiance=' .. readiness(status.radiance) ..
            ' FlamePainter=' .. readiness(status.flamePainter) .. ' tracers=' .. readiness(status.tracers))
        local tanks = status.tanks or {}
        echo('Tank sources: tracked=' .. value(tanks.tracked) .. ' visible=' .. value(tanks.visible) ..
            ' active=' .. value(tanks.active) .. ' queued=' .. value(tanks.queued) ..
            ' missing_anchors=' .. value(tanks.missingAnchors) ..
            ' latest_shot_frame=' .. value(tanks.latestShotFrame) .. ' age_frames=' .. value(tanks.latestShotAge))
    else
        echo('Renderers: combat status unavailable. Run /effects status and check earlier shader/widget errors in infolog.')
    end
    echo('Cascade: field=' .. readiness(WG.NeonRadiance and WG.NeonRadiance.ready == true) ..
        ' combat_capture=' .. readiness(type(WG.CaptureCombatLightEmission) == 'function') ..
        ' occupancy_provider=' .. readiness(type(WG.GetVehicleLightOcclusion) == 'function'))
    echo('Mobile shadows: /radiancelight shadows stats reports caster counts, budget overflow and initialization/runtime failure reasons.')
    echo('Roads: revision=' .. value(Spring.GetGameRulesParam('city_roads_revision')) ..
        ' chunks=' .. value(Spring.GetGameRulesParam('city_roads_chunks')) ..
        ' orientation=' .. readiness(type(WG.CityOrientation) == 'table'))
    selectedStatus()
    echo('Readiness and source counts do not establish the visual result; keep the corresponding TODO pending until checked.')
end

local function startup(allowMissingID)
    if startupHandled then return end
    local id = matchID()
    -- Initialize runs before GameStart. The engine GameID event can arrive
    -- between those calls; no per-frame polling or all-unit scans are needed.
    if not id and not allowMissingID then return end
    startupHandled = true
    if id and id == lastPrintedGameID then return end
    if id then lastPrintedGameID = id end
    printList()
    if not id then
        echo('Match identity unavailable: automatic reminder is limited to this LuaUI session; /validate can always repeat it.')
    end
end

function widget:Initialize()
    startup(Spring.GetGameFrame() > 0)
end

function widget:GameStart()
    startup(true)
end

function widget:GetConfigData()
    return {lastPrintedGameID = lastPrintedGameID}
end

function widget:SetConfigData(data)
    if type(data) == 'table' and type(data.lastPrintedGameID) == 'string' then
        lastPrintedGameID = data.lastPrintedGameID
    end
end

function widget:TextCommand(command)
    local name, argument = command:match('^%s*/?(%S+)%s*(.-)%s*$')
    if not name or name:lower() ~= 'validate' then return false end
    argument = argument:lower()
    if argument == '' or argument == 'help' or argument == 'list' then
        printList()
    elseif argument == 'status' then
        printStatus()
    elseif argument == 'rebuild status' or argument == 'rubble status' then
        requestRebuildStatus()
    elseif argument == 'all' then
        for _, task in ipairs(config.tasks) do printTask(task) end
    elseif tasksByName[argument] then
        printTask(tasksByName[argument])
    else
        echo('Unknown validation task: ' .. argument .. '. Use /validate to list tasks, or /validate status.')
    end
    return true
end
