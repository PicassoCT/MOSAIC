-- This file belongs to the external lab, never the production game archive.
function gadget:GetInfo()
    return {name = 'External Animation Lab', desc = 'Disposable scenario controller',
        author = 'MOSAIC contributors', license = 'GPL-3.0-or-later',
        layer = -100000, enabled = true}
end

local configPath = 'luarules/configs/animation_lab_run.lua'
if not VFS.FileExists(configPath) then return false end
local config = VFS.Include(configPath)
local scenario = config.scenario
local json = VFS.Include('luarules/configs/animation_lab_json.lua')

if not gadgetHandler:IsSyncedCode() then
    local pending = {}
    local function receive(_, payload)
        if Script.LuaUI('AnimationLabEvent') then
            Script.LuaUI.AnimationLabEvent(payload)
        else
            pending[#pending + 1] = payload
        end
    end
    function gadget:Initialize() gadgetHandler:AddSyncAction('AnimationLabEvent', receive) end
    function gadget:Update()
        if #pending == 0 or not Script.LuaUI('AnimationLabEvent') then return end
        for _, payload in ipairs(pending) do Script.LuaUI.AnimationLabEvent(payload) end
        pending = {}
    end
    function gadget:Shutdown() gadgetHandler:RemoveSyncAction('AnimationLabEvent') end
    return
end

local unpackArgs = unpack or table.unpack
local subjects, subjectIndices, expectedDestroyed, phaseOrigins = {}, {}, {}, {}
local ready, spawnFrame, phaseIndex, phaseStart, stopped = false, nil, 0, nil, false
local anchorX, anchorZ = Game.mapSizeX / 2, Game.mapSizeZ / 2
local public = {public = true}
local stateFields = {upper = 'UpperAnimationState', lower = 'LowerAnimationState'}
local reservedFunctions = {load = true, loadstring = true, loadfile = true, dofile = true,
    include = true, require = true, getfenv = true, setfenv = true, setmetatable = true,
    collectgarbage = true, pcall = true, xpcall = true}

local function emit(event)
    event.frame = event.frame or Spring.GetGameFrame()
    event.run_id = config.run_id
    local payload = json.encode(event)
    Spring.Echo('ANIMLAB_EVENT ' .. payload)
    SendToUnsynced('AnimationLabEvent', payload)
end

local function fail(reason)
    if stopped then return end
    stopped = true
    Spring.SetGameRulesParam('animlab_error', tostring(reason), public)
    Spring.SetGameRulesParam('animlab_status', 3, public)
    emit({kind = 'error', message = tostring(reason), phase_index = phaseIndex,
        phase = scenario.phases[phaseIndex] and scenario.phases[phaseIndex].name})
end

local function subject(name)
    local id = subjects[name]
    assert(id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id),
        'subject is missing or dead: ' .. tostring(name))
    return id
end

local function destination(x, z)
    x, z = anchorX + x, anchorZ + z
    assert(x >= 16 and x <= Game.mapSizeX - 16 and z >= 16 and z <= Game.mapSizeZ - 16,
        'scenario coordinate is outside this map')
    local y = Spring.GetGroundHeight(x, z)
    assert(y >= 0, 'scenario placement is underwater; use a land map or move the fixture')
    return x, y, z
end

local function resolve(value)
    if type(value) ~= 'table' then return value end
    if value.ref then return subject(value.ref) end
    local result = {}
    for key, element in pairs(value) do result[key] = resolve(element) end
    return result
end

local actions = {}
function actions.move(action)
    local x, y, z = destination(action.x, action.z)
    Spring.GiveOrderToUnit(subject(action.unit), CMD.MOVE, {x, y, z}, {})
end
function actions.stop(action)
    Spring.GiveOrderToUnit(subject(action.unit), CMD.STOP, {}, {})
end
function actions.attack(action)
    local id = subject(action.unit)
    Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, {2}, {})
    Spring.GiveOrderToUnit(id, CMD.ATTACK, {subject(action.target)}, {})
end
function actions.call(action)
    local id = subject(action.unit)
    local env = assert(Spring.UnitScript.GetScriptEnv(id), 'no unit script environment')
    local name = action['function']
    assert(not reservedFunctions[name], 'script action must name an animation entry point')
    local scriptName = name:match('^script%.([%w_]+)$')
    local fn = scriptName and env.script and env.script[scriptName] or env[name]
    assert(type(fn) == 'function', 'unsupported script entry point: ' .. name)
    local args = resolve(action.args or {})
    -- StartThread is local in MOSAIC's script header, not env.StartThread.
    -- Do not pcall a yielding animation: Lua 5.1 cannot yield across that boundary.
    -- Asynchronous script errors remain visible in the preserved engine log.
    Spring.UnitScript.CallAsUnit(id, function()
        Spring.UnitScript.StartThread(function()
            Spring.UnitScript.SetSignalMask(0)
            local result = fn(unpackArgs(args))
            local scalarResult
            if type(result) == 'boolean' or type(result) == 'string' or type(result) == 'number' then
                scalarResult = result
            end
            emit({kind = 'call_return', unit = action.unit, ['function'] = name,
                result = scalarResult})
            if result == false then fail('script rejected ' .. name .. ' for ' .. action.unit) end
        end)
    end)
end
function actions.attach(action)
    local carrier, passenger = subject(action.transporter), subject(action.unit)
    local pieceMap = assert(Spring.GetUnitPieceMap(carrier), 'carrier has no piece map')
    local piece = assert(pieceMap[action.piece], 'unsupported attachment piece: ' .. action.piece)
    Spring.GiveOrderToUnit(passenger, CMD.STOP, {}, {})
    Spring.UnitAttach(carrier, passenger, piece)
    assert(Spring.GetUnitTransporter(passenger) == carrier, 'UnitAttach did not attach passenger')
end
function actions.detach(action)
    local id = subject(action.unit)
    local x, _, z = destination(action.x, action.z)
    Spring.UnitDetach(id)
    Spring.SetUnitNoSelect(id, false)
    Spring.SetUnitPosition(id, x, z)
    Spring.GiveOrderToUnit(id, CMD.STOP, {}, {})
end
function actions.destroy(action)
    local id = subject(action.unit)
    expectedDestroyed[action.unit] = true
    Spring.SetGameRulesParam('animlab_destroyed_' .. subjectIndices[action.unit], 1, public)
    Spring.DestroyUnit(id, false, false)
end

local checks = {}
function checks.displaced(check)
    local id, origin = subject(check.unit), phaseOrigins[check.unit]
    local x, _, z = Spring.GetUnitPosition(id)
    local distance = math.sqrt((x - origin[1])^2 + (z - origin[3])^2)
    return distance >= check.min, distance, check.min
end
function checks.transported(check)
    local actual, expected = Spring.GetUnitTransporter(subject(check.unit)), subject(check.transporter)
    return actual == expected, actual or -1, expected
end
function checks.detached(check)
    local actual = Spring.GetUnitTransporter(subject(check.unit))
    return actual == nil, actual or -1, -1
end
function checks.alive(check)
    local id = subjects[check.unit]
    local actual = id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) or false
    return actual, actual, true
end

local function finishPhase()
    local phase = scenario.phases[phaseIndex]
    for _, check in ipairs(phase.checks or {}) do
        local ok, actual, expected = assert(checks[check.type], 'unknown check')(check)
        emit({kind = 'check', phase = phase.name, phase_index = phaseIndex,
            check = check.type, unit = check.unit, ok = ok, actual = actual, expected = expected})
        if not ok then fail('phase check failed: ' .. phase.name .. '/' .. check.type); return end
    end
end

local function beginPhase(index, frame)
    phaseIndex, phaseStart = index, frame
    local phase = scenario.phases[index]
    Spring.SetGameRulesParam('animlab_phase', index, public)
    Spring.SetGameRulesParam('animlab_phase_start', frame, public)
    Spring.SetGameRulesParam('animlab_phase_end', frame + phase.frames, public)
    phaseOrigins = {}
    for _, spec in ipairs(scenario.units) do
        if not expectedDestroyed[spec.name] then
            phaseOrigins[spec.name] = {Spring.GetUnitPosition(subject(spec.name))}
        end
    end
    emit({kind = 'phase', phase = phase.name, phase_index = index, frame = frame,
        duration_frames = phase.frames, expected_motion = phase.expected_motion})
    for _, action in ipairs(phase.actions or {}) do
        emit({kind = 'action', phase = phase.name, phase_index = index, action = action})
        assert(actions[action.type], 'unknown scenario action')(action)
        if stopped then return end
    end
end

local function spawnSubjects(frame)
    -- Validate all definitions before spawning any subject. A missing variant
    -- is an unsupported run, never a fallback to a different character/model.
    for _, spec in ipairs(scenario.units) do
        assert(UnitDefNames[spec.def], 'unknown unit definition: ' .. spec.def)
        destination(spec.x, spec.z)
    end
    for index, spec in ipairs(scenario.units) do
        local x, y, z = destination(spec.x, spec.z)
        local id = assert(Spring.CreateUnit(spec.def, x, y, z, spec.facing or 0, spec.team or 0),
            'failed to create ' .. spec.def)
        subjects[spec.name] = id
        subjectIndices[spec.name] = index
        Spring.SetUnitAlwaysVisible(id, true)
        Spring.SetUnitNoSelect(id, false)
        Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, {0}, {})
        Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, {0}, {})
        Spring.SetGameRulesParam('animlab_unit_' .. index, id, public)
        emit({kind = 'spawn', unit = spec.name, unit_def = spec.def, id = id,
            team = spec.team or 0, position = {x, y, z}, creation_index = index})
    end
    spawnFrame = frame
    Spring.SetGameRulesParam('animlab_status', 1, public)
    Spring.SetGameRulesParam('animlab_spawn_frame', frame, public)
end

local function publishStates()
    for index, spec in ipairs(scenario.units) do
        local id = subjects[spec.name]
        if id and not expectedDestroyed[spec.name] then
            local env = Spring.UnitScript.GetScriptEnv(id)
            if env then
                for label, key in pairs(stateFields) do
                    local value = env[key]
                    if type(value) == 'string' or type(value) == 'number' or type(value) == 'boolean' then
                        Spring.SetGameRulesParam('animlab_' .. label .. '_' .. index, tostring(value), public)
                    end
                end
            end
        end
    end
    Spring.SetGameRulesParam('animlab_state_frame', Spring.GetGameFrame(), public)
end

function gadget:Initialize()
    Spring.SetGameRulesParam('animlab_status', 0, public)
    Spring.SetGameRulesParam('animlab_phase', 0, public)
end
function gadget:RecvLuaMsg(message, playerID)
    if playerID == 0 and message == 'animlab_ready:' .. config.run_id then ready = true; return true end
end
function gadget:GameFrame(frame)
    if stopped then return end
    local ok, reason = pcall(function()
        if not ready then
            if frame > 1800 then fail('capture widget did not acknowledge readiness after the opening cinematic') end
            return
        end
        if not spawnFrame then spawnSubjects(frame) end
        for name, id in pairs(subjects) do
            if not expectedDestroyed[name] and (not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id)) then
                fail('unexpected subject death: ' .. name); return
            end
        end
        if phaseIndex == 0 and frame >= spawnFrame + scenario.warmup_frames then
            beginPhase(1, frame)
        elseif phaseIndex > 0 and frame >= phaseStart + scenario.phases[phaseIndex].frames then
            finishPhase()
            if stopped then return end
            if phaseIndex < #scenario.phases then beginPhase(phaseIndex + 1, frame)
            else
                stopped = true
                Spring.SetGameRulesParam('animlab_status', 2, public)
                emit({kind = 'controller_complete', status = 'complete', phase_index = phaseIndex})
            end
        end
        if not stopped then publishStates() end
    end)
    if not ok then fail(reason) end
end
