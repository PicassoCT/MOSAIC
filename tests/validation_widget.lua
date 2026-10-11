-- Run from the repository root with Lua 5.1.
-- Exercise real LuaUI/System globals, match identity transport, widget config
-- reload ordering, every printed task and the diagnostic failure boundaries.
assert(setfenv and getfenv, 'this regression must run with Lua 5.1')

local frame, messages, gameRules, ruleWrites = 0, {}, {}, 0
local selected, unitAvailable = {}, true
local unitRules = {}
local shared = {}
local requests, replies, reconstructionState = {}, {}, {}
local function forbidden() error('validation changed gameplay or scanned units') end
Game = {mapName = 'Same map', gameVersion = 'validation-test'}
UnitDefs = {[1] = {name = 'ground_tank_day'}}
Spring = {
    Echo = function(text) messages[#messages + 1] = text end,
    GetGameFrame = function() return frame end,
    GetGameRulesParam = function(key) return gameRules[key] end,
    SetGameRulesParam = function(key, value, access)
        assert(type(value) == 'string' and access.public == true)
        gameRules[key] = value
        ruleWrites = ruleWrites + 1
    end,
    GetSelectedUnits = function() return selected end,
    GetUnitDefID = function() if unitAvailable then return 1 end end,
    GetUnitHealth = function() return 3500, 4000, 0, 0, 1 end,
    GetUnitRulesParam = function(_, key) return unitRules[key] end,
    SendLuaRulesMsg = function(message) requests[#requests + 1] = message end,
    SendMessageToPlayer = function(player, message) replies[#replies + 1] = {player=player, message=message} end,
    SendCommands = forbidden, GiveOrderToUnit = forbidden,
    GetAllUnits = forbidden, GetVisibleUnits = forbidden, CreateUnit = forbidden,
    SetUnitHealth = forbidden, SetConfigInt = forbidden,
}
VFS = {Include = function(path, env)
    return setfenv(assert(loadfile(path)), env or getfenv(2))()
end}
dofile('luaui/system.lua')
local config = dofile('luaui/configs/mosaic_validation.lua')

local function loadWidget(saved)
    local w = {}
    for key, value in pairs(System) do w[key] = value end
    w.widget, w.WG = w, shared
    assert(w.pairs and not w._G, 'fixture must use the real LuaUI global layout')
    setfenv(assert(loadfile('luaui/widgets_mosaic/dbg_validation.lua')), w)()
    if saved then w:SetConfigData(saved) end -- widgetHandler:LoadWidget ordering
    w:Initialize()
    assert(w:GetInfo().enabled == true)
    assert(not w.Update and not w.GameFrame and not w.DrawWorld and not w.DrawScreen,
        'the checklist added a perpetual update, scan or render callback')
    return w
end

local function loadBridge(synced)
    local env = {gadget = {}, Spring = Spring, VFS = VFS, type = type,
        GG = reconstructionState, UnitDefs = UnitDefs, math = math, string = string,
        ipairs = ipairs, tostring = tostring, tonumber = tonumber,
        gadgetHandler = {IsSyncedCode = function() return synced end}}
    local result = setfenv(assert(loadfile('luarules/gadgets/game_validation_session.lua')), env)()
    return env.gadget, result
end

local function output()
    return table.concat(messages, '\n')
end

local function count(fragment)
    local n = 0
    for _, line in ipairs(messages) do if line:find(fragment, 1, true) then n = n + 1 end end
    return n
end

local function handlerChunk(path, first, last, env)
    local file = assert(io.open(path, 'r'))
    local source = file:read('*a'); file:close()
    local start = assert(source:find(first, 1, true))
    local finish = assert(source:find(last, start, true))
    setfenv(assert(loadstring(source:sub(start, finish - 1))), env)()
end

-- The bridge handles only the actual engine identity event, once synced.
local noBridge, skipped = loadBridge(false)
assert(skipped == false and not noBridge.GameID)
local bridge = loadBridge(true)
assert(not bridge.Initialize and not bridge.GameFrame and not bridge.Update)
bridge:GameID(nil); bridge:GameID(''); bridge:GameID(123); bridge:GameID(string.rep('\0', 16))
assert(ruleWrites == 0, 'invalid/missing identity was persisted')

-- Frame-zero UI load can precede the GameID packet. GameStart sees it later.
local w = loadWidget()
assert(#messages == 0, 'premature startup used an unstable match identity')
local gadgetDispatch = {GameIDList = {bridge}}
handlerChunk('luarules/gadgets.lua', 'function gadgetHandler:GameID(gameID)',
    'function gadgetHandler:TeamDied(teamID)', {gadgetHandler = gadgetDispatch, ipairs = ipairs})
gadgetDispatch:GameID('01234567890123456789012345678901')
assert(gameRules[config.gameIDParam] == 'engine:01234567890123456789012345678901',
    'match identity lost string precision or used a generic persistent key')
w:GameStart()
assert(count('TODO: manual in-game validation') == 1)
for _, task in ipairs(config.tasks) do
    assert(output():find('/validate ' .. task.id .. ' - ', 1, true), 'startup omitted a task command')
end
local printed = #messages
w:GameStart(); w:Initialize()
assert(#messages == printed, 'startup repeated in the same widget')

-- Real handler saves GetConfigData before Shutdown, then loads it before the
-- next Initialize. Persist only match identity, not a forever-seen boolean.
local saved = w:GetConfigData()
frame = 60
w = loadWidget(saved)
assert(#messages == printed, 'LuaUI reload printed the startup list twice')
w:GameStart()
assert(#messages == printed, 'reload GameStart repeated the list')
assert(w:TextCommand('validate'), 'manual list was swallowed after startup')
assert(count('TODO: manual in-game validation') == 2)
assert(w:TextCommand('validate help') and w:TextCommand('/validate list'))
assert(not w:TextCommand('validation') and not w:TextCommand('effects status'))

-- BAR105 routes both /validate and /luaui validate through ConfigureLayout.
-- Use the production handler entry point, not only a direct callback fixture.
local dispatch = {TextCommandList = {w}, actionHandler = {TextAction = function() return false end}}
handlerChunk('luaui/mosaicwidgets.lua', 'function widgetHandler:ConfigureLayout(command)',
    'local function ArrivalActive(self)', {widgetHandler = dispatch, ipairs = ipairs, string = string})
messages = {}
assert(dispatch:ConfigureLayout('validate tank'))
assert(output():find('Expected:', 1, true))
assert(not dispatch:ConfigureLayout('unrelated command'))

-- A new match on the same map gets a new reminder, including frame-zero load.
frame, gameRules, messages = 0, {}, {}
w = loadWidget(saved)
bridge:GameID('fedcba9876543210fedcba9876543210')
w:GameStart()
assert(count('TODO: manual in-game validation') == 1, 'new match reminder was suppressed')
saved = w:GetConfigData()
messages = {}
w = loadWidget(saved)
w:GameStart()
assert(#messages == 0, 'frame-zero LuaUI reload printed the list twice')

-- Every command from the startup list resolves to instructions, a real command
-- and an expected result. No testing command gets executed by the helper.
for index, task in ipairs(config.tasks) do
    messages = {}
    assert(w:TextCommand('validate ' .. task.id))
    assert(output():find('Expected:', 1, true) and #messages >= 4)
    assert(output():find('/', 1, true), 'task did not include a console test/diagnostic command')
    assert(not output():find('Unknown validation task:', 1, true))
    assert(w:TextCommand('validate ' .. index))
    for _, alias in ipairs(task.aliases or {}) do assert(w:TextCommand('validate ' .. alias)) end
end
messages = {}
assert(w:TextCommand('  /VaLiDaTe TaNk  '))
assert(output():find('/give ground_tank_day', 1, true) and output():find('/effects status', 1, true))
messages = {}
assert(w:TextCommand('validate all'))
assert(count('Expected:') == #config.tasks)
messages = {}
assert(w:TextCommand('validate typo'))
assert(output():find('Unknown validation task:', 1, true))

-- Missing providers, false readiness and failed diagnostics remain unavailable;
-- a nonzero source count is never silently promoted to a passed visual check.
messages = {}
assert(w:TextCommand('validate status'))
assert(output():find('combat status unavailable', 1, true))
assert(output():find('Selected unit: none', 1, true))
shared.lighteffects = {getStatus = function()
    return {radiance = true, flamePainter = false, tracers = true,
        tanks = {tracked = 2, visible = 1, active = 1, queued = 0, missingAnchors = 1,
            latestShotFrame = 60, latestShotAge = 12}}
end}
shared.NeonRadiance = {ready = false}
shared.CaptureCombatLightEmission = function() end
shared.GetVehicleLightOcclusion = function() error('status should only identify provider presence') end
shared.CityOrientation = {}
gameRules.city_roads_revision, gameRules.city_roads_chunks = 3, 4
selected, unitRules = {7}, {mosaic_tank_muzzle_frame = 60, city_street_name = 'Market Street',
    city_house_number = 17, city_rebuild_progress = 0.4, city_rebuild_paused = 1}
messages = {}
assert(w:TextCommand('validate status'))
assert(output():find('FlamePainter=unavailable', 1, true))
assert(output():find('missing_anchors=1', 1, true) and output():find('age_frames=12', 1, true))
assert(output():find('Cascade: field=unavailable', 1, true))
assert(output():find('Roads: revision=3 chunks=4 orientation=ready', 1, true))
assert(output():find('mosaic_tank_muzzle_frame=60', 1, true))
assert(output():find('city_street_name=Market Street', 1, true))
assert(output():find('city_rebuild_paused=1', 1, true))
assert(not output():lower():find('passed', 1, true), 'diagnostics claimed the visual check passed')
unitAvailable = false
messages = {}
w:TextCommand('validate status')
assert(output():find('no longer visible or available', 1, true))
assert(not output():find('city_street_name', 1, true), 'stale selection leaked unit state')
shared.lighteffects.getStatus = function() error('removed renderer') end
messages = {}
w:TextCommand('validate status')
assert(output():find('combat status unavailable', 1, true))

-- Missing identity degrades at GameStart without a permanent polling loop or a
-- cross-match suppression key. On-demand instructions continue to work.
gameRules, messages, frame = {}, {}, 0
w = loadWidget({lastPrintedGameID = false})
w:GameStart(); printed = #messages; w:GameStart()
assert(#messages == printed and count('TODO: manual in-game validation') == 1)
assert(output():find('Match identity unavailable', 1, true))
assert(w:GetConfigData().lastPrintedGameID == nil)
assert(ruleWrites == 2, 'widget wrote game state while reporting validation')

-- Instructions and generic status never send a simulation message. Only this
-- explicit diagnostic asks for the existing reconstruction service snapshot.
assert(#requests == 0, 'startup or instructions sent an unsolicited simulation request')
selected, unitAvailable, messages = {}, true, {}
assert(w:TextCommand('validate rebuild status'))
assert(requests[1] == config.rebuildStatusMessage)
assert(output():find('Requested reconstruction state', 1, true))
frame = 300
assert(bridge:RecvLuaMsg(requests[1], 17))
assert(#replies == 1 and replies[1].player == 17 and replies[1].message:find('status unavailable', 1, true))
local oldReplies = #replies
assert(bridge:RecvLuaMsg(requests[1], 17) and #replies == oldReplies, 'repeated diagnostic was not bounded')
for _, invalid in ipairs({'unrelated', config.rebuildStatusMessage .. 'typo',
    config.rebuildStatusMessage .. ':', config.rebuildStatusMessage .. ':-1',
    config.rebuildStatusMessage .. ':4.5', config.rebuildStatusMessage .. ':999999999'}) do
    assert(not bridge:RecvLuaMsg(invalid, 17), 'diagnostic consumed a malformed or unrelated message')
end
assert(not bridge:RecvLuaMsg(false, 17))

local plots = {}
for index = 1, 12 do
    plots[index] = {id=index, stage='rubble', x=index*100, z=index*200,
        originalUnitID=index+100, sourceUnitID=index+100, sourceWaiting=true,
        unitID=index+200, defID=1, elapsed=0, paused=true, pauseReason='combat',
        rubbleSpawnAttempts=2, rubbleSpawnFailures=1, siteSpawnAttempts=0, siteSpawnFailures=0}
end
reconstructionState.CityReconstruction = {GetStatus = function()
    return {queued=12, completed=0, active=12, waitingForRemoval=12, rubble=0, construction=0, plots=plots}
end}
frame, replies = 330, {}
assert(bridge:RecvLuaMsg(requests[1], 17))
assert(#replies == 10, 'a whole-city diagnostic was not capped at eight plot details')
assert(replies[1].message:find('waiting_for_collapse=12', 1, true))
assert(replies[2].message:find('Plot 5 ', 1, true) and replies[9].message:find('Plot 12 ', 1, true))
assert(replies[2].message:find('rubble_failures=1', 1, true))
for _, reply in ipairs(replies) do assert(reply.player == 17, 'diagnostic reply went to another player') end

selected, messages = {203}, {}
assert(w:TextCommand('validate rubble status'))
assert(requests[#requests] == config.rebuildStatusMessage .. ':203')
frame, replies = 360, {}
bridge:RecvLuaMsg(requests[#requests], 17)
assert(#replies == 3 and replies[2].message:find('Plot 3 ', 1, true), 'selection did not isolate its plot')
reconstructionState.CityReconstruction.GetStatus = function()
    return {queued=12, completed=12, active=0, waitingForRemoval=0, rubble=0, construction=0, plots={}}
end
frame, replies = 390, {}
bridge:RecvLuaMsg(config.rebuildStatusMessage, 17)
assert(#replies == 2 and replies[2].message:find('may still be alive', 1, true))
assert(ruleWrites == 2, 'reconstruction diagnostics mutated game state')

print('PASS: match identity bridge, real LuaUI startup, once-per-match/reload behavior, task commands, bounded private reconstruction diagnostics, unavailable providers and no polling/gameplay changes')
