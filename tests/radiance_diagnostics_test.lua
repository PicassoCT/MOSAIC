-- Run from repo root: lua5.4 tests/radiance_diagnostics_test.lua
-- CPU/unit-script mocks only. This does not validate Recoil's GPU output.
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close(); return s
end
local path = 'luaui/widgets_mosaic/include/radiance_diagnostics.lua'
local output, selected, calls = {}, {11}, 0
local function echo(s) output[#output + 1] = s end
local units = {
    [10] = {piece = 0}, [11] = {piece = 2}, [12] = {hidden = true},
    [13] = {}, [14] = {piece = 3}, [15] = {piece = 4},
}
local S = {
    GetGameFrame = function() return 90 end,
    ValidUnitID = function(id) return units[id] ~= nil end,
    GetUnitIsDead = function(id) return units[id].dead end,
    GetUnitIsCloaked = function(id) return units[id].cloaked end,
    GetUnitNoDraw = function(id) return units[id].noDraw end,
    GetUnitTransporter = function(id) return units[id].transported and 100 or nil end,
    GetSpectatingState = function() return false, false end,
    GetMyAllyTeamID = function() return 0 end,
    GetUnitLosState = function(id) return {los = not units[id].hidden} end,
    GetUnitDefID = function() return 7 end,
    GetSelectedUnits = function() return selected end,
    GetAllUnits = function() local ids = {}; for id in pairs(units) do ids[#ids + 1] = id end; return ids end,
    GetUnitPieceMap = function(id)
        assert(not units[id].hidden, 'hidden anchor queried')
        return {bulb = units[id].piece}
    end,
    GetUnitPiecePosDir = function(id, piece)
        assert(not units[id].hidden); assert(piece == units[id].piece)
        return 100, 54, 200
    end,
    GetGroundHeight = function() return 0 end,
    Echo = echo,
}
local env = setmetatable({Spring = S}, {__index = _G})
local M = assert(load(read(path), path, 't', env))()
local profile = {piece = 'bulb', radius = 190, strength = 2.2}
local src = {debugLamps = {}, police = {[50] = {}}, tanks = {}, fires = {}, transient = {}}
for _, id in ipairs({10, 12, 13, 14, 15}) do src.debugLamps[id] = {profile = profile} end
local lights = {}
for _, id in ipairs({10, 13, 14}) do
    lights[#lights + 1] = {unitID = id, x = 100, y = id == 14 and 700 or 54, z = 200,
        radius = 190, strength = 2.2, nightOnly = false}
end
function src:Collect() calls = calls + 1; return lights end
local function snapshot() return M.SourceSnapshot(src, {[7] = profile}, 96) end
local s = snapshot()
assert(calls == 1 and s.queued == 3 and s.queuedLamps == 3)
assert(s.candidates == 6 and s.tracked == 5 and s.visible == 5)
assert(s.lamps[1].id == 11 and not s.lamps[1].tracked and not s.lamps[1].queued)
local rows = {}; for _, row in ipairs(s.lamps) do rows[row.id] = row end
assert(rows[10].piece == 0 and rows[10].anchorAvailable and rows[10].queued)
assert(rows[10].groundReach and not rows[10].nightOnly)
assert(rows[12].visibility == 'outside-unit-LOS' and rows[12].x == nil)
assert(rows[13].queued and not rows[13].anchorAvailable)
assert(rows[14].queued and not rows[14].groundReach)
assert(rows[15].tracked and rows[15].visibility == 'visible' and not rows[15].queued)
s.lamps[2].x = -123
assert(lights[1].x == 100, 'snapshot leaked a mutable live source record')
print('PASS: real-queue snapshot, missing registration, zero-index anchor, fallback, visibility, range and copies')

for key, expected in pairs({dead = 'dead', cloaked = 'cloaked', noDraw = 'no-draw', transported = 'transported'}) do
    units[15][key] = true
    local result = snapshot()
    for _, row in ipairs(result.lamps) do if row.id == 15 then assert(row.visibility == expected) end end
    units[15][key] = nil
end
for id = 20, 60 do units[id] = {piece = 1} end
selected = {60}
s = snapshot()
assert(#s.lamps == M.maxLampRows and s.lamps[1].id == 60 and s.candidates == 47)
for id = 20, 60 do units[id] = nil end
selected = {11}
print('PASS: visibility rejection reasons and bounded selected-first output')

local shared = {NeonRadiance = {ready = true, unitTexture = 'texture'},
    CaptureCombatLightEmission = function() error('diagnostic must not capture to GPU') end,
    GetRainRadiance = function() return {bottom = 0, top = 128, strength = 2} end,
    GetMosaicFogRadiance = function() error('diagnostic must not request GPU fog work') end,
    lighteffects = {getRadianceDiagnostics = function()
        local result = snapshot(); result.captureReady = true; result.capturePublished = true; return result
    end}}
output = {}; M.Report(shared, echo)
local log = table.concat(output, '\n')
assert(log:find('scene=ready', 1, true) and log:find('capture-ready=yes published=yes', 1, true))
assert(log:find('ground-reach=no band=no', 1, true))
assert(log:find('do NOT prove visible pixels', 1, true))
shared.GetRainRadiance = function() error('scene failure') end
output = {}; M.Report(shared, echo); log = table.concat(output, '\n')
assert(log:find('scene state ERROR:', 1, true) and log:find('scene failure', 1, true))
local realCollect = src.Collect
src.Collect = function() error('source failure') end
output = {}; M.Report(shared, echo); log = table.concat(output, '\n')
assert(log:find('COLLECT ERROR:', 1, true) and log:find('queued=UNKNOWN/96', 1, true))
assert(log:find('visible=5 queued=UNKNOWN', 1, true))
src.Collect = realCollect
output = {}; M.Report({}, echo); log = table.concat(output, '\n')
assert(log:find('cascade=absent', 1, true) and log:find('lamp queue is UNKNOWN', 1, true))
print('PASS: absent providers, protected failures, truthful UNKNOWN/ready reporting, no GPU callbacks')

-- Actual diagnostics widget remains useful even if both render widgets failed.
local widgetEnv = setmetatable({widget = {}, WG = {}, Spring = S,
    VFS = {Include = function(p) assert(p == path); return M end}}, {__index = _G})
assert(load(read('luaui/widgets_mosaic/dbg_radiance_diagnostics.lua'), 'widget', 't', widgetEnv))()
assert(widgetEnv.widget.Update == nil and widgetEnv.widget.DrawWorld == nil)
assert(not widgetEnv.widget:TextCommand('radiancedebug on'))
assert(widgetEnv.widget:TextCommand('radiancedebug status'))
widgetEnv.VFS.Include = function() error('broken optional diagnostics include') end
local fresh = setmetatable({widget = {}, WG = {}, Spring = S, VFS = widgetEnv.VFS}, {__index = _G})
assert(load(read('luaui/widgets_mosaic/dbg_radiance_diagnostics.lua'), 'widget', 't', fresh))()
assert(fresh.widget:TextCommand('radiancedebug status'))
print('PASS: independent command, no polling/render call-ins, diagnostic-load error containment')

-- Exercise the production Light Effects API wiring, including renderer failure
-- and shutdown. No replacement of its rendering or source-selection algorithms.
local function exerciseWidget(rendererAvailable)
    local diagnosticLoads, registered = 0, {}
    local w = setmetatable({widget = {}, WG = {}, Spring = S, UnitDefs = {}, WeaponDefs = {},
        widgetHandler = {RegisterGlobal = function(_, name, fn) registered[name] = fn end,
            DeregisterGlobal = function(_, name) registered[name] = nil end}}, {__index = _G})
    local initialized = 0
    function src:UnitCreated() initialized = initialized + 1 end
    function src:GetTankMuzzleStats() return {} end
    w.VFS = {Include = function(p)
        if p == path then diagnosticLoads = diagnosticLoads + 1; return M end
        if p:find('combat_light_sources.lua', 1, true) then
            return {maxLights = 96, New = function() return src end}
        end
        if p:find('radiance_time.lua', 1, true) then return {AtFrame = function() return 0 end} end
        if p == 'scripts/lib_mosaic.lua' then
            return {getPoliceLightTypeTable = function() return {} end,
                getTankMuzzleTypeTable = function() return {} end,
                getRadianceDebugLampTypeTable = function() return {[7] = profile} end}
        end
        if p:find('combat_light_renderer.lua', 1, true) then
            return function()
                if not rendererAvailable then return nil, 'mock shader failure' end
                return {Capture = function() end, Shutdown = function() end}
            end
        end
        if p:find('smoke_ribbon_renderer.lua', 1, true) or p:find('combat_tracers.lua', 1, true) then
            return function() return {Shutdown = function() end} end
        end
        error('unexpected include: ' .. p)
    end}
    assert(load(read('luaui/widgets_mosaic/gfx_light_effects.lua'), 'effects', 't', w))()
    w.widget:Initialize()
    assert(initialized == 6 and diagnosticLoads == 0, 'diagnostics added startup work')
    local report = w.WG.lighteffects.getRadianceDiagnostics()
    assert(report.captureReady == rendererAvailable and report.capturePublished == rendererAvailable)
    assert(report.queuedLamps == 3 and report.limit == 96 and diagnosticLoads == 1)
    w.WG.lighteffects.getRadianceDiagnostics(); assert(diagnosticLoads == 1)
    local staleAPI = w.WG.lighteffects
    w.widget:Shutdown(); assert(w.WG.lighteffects == nil and w.WG.CaptureCombatLightEmission == nil)
    report = staleAPI.getRadianceDiagnostics()
    assert(not report.initialized and not report.captureReady and not report.capturePublished)
    assert(next(registered) == nil)
end
exerciseWidget(true); exerciseWidget(false)
print('PASS: production effects API, lazy include, renderer unavailable, WG teardown and stale-reader safety')

-- MOSAIC's unit-script header provides these locals before the unit source.
-- No constants.lua include is required to run the real lamp idle/hop coroutine.
local turns, moves, thread = 0, 0, nil
local lampEnv = setmetatable({unitID = 17, script = {}, piece = function(name) return name end,
    include = function(name) error('unexpected dependency: ' .. name) end,
    Turn = function(_, axis) assert(axis == 1 or axis == 2); turns = turns + 1 end,
    Move = function(_, axis) assert(axis == 2); moves = moves + 1 end,
    Sleep = function(ms) coroutine.yield(ms) end,
    StartThread = function(fn) thread = coroutine.create(fn) end}, {__index = _G})
assert(load('local x_axis,y_axis,z_axis=1,2,3\n' .. read('scripts/radianceDebugLampScript.lua'),
    'lamp', 't', lampEnv))()
lampEnv.script.Create()
for _ = 1, 12 do local ok, delay = coroutine.resume(thread); assert(ok and type(delay) == 'number') end
assert(turns > 10 and moves >= 3)
assert(lampEnv.script.HitByWeapon(0, 0, 0, 5) == 5 and lampEnv.script.Killed() == 0)
print('PASS: real lamp look/hop script runs with header axes and without constants.lua')
