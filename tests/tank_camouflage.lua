-- Run from repository root with Lua 5.1 or lupa.lua51.
local noop = function() end
local pieces, shown, rules, turns = {}, {}, {}, {}
for i, name in ipairs({"Body1", "Turret1", "Cannon1", "Shell", "FireEmit", "DustEmit", "Halterrung", "StealthBase"}) do
    pieces[name] = i
end
local groups = {StealthShieldFold = {}, MoveStealth = {}, StealthEvening = {}}
local nextID = 10
for name, count in pairs({StealthShieldFold = 14, MoveStealth = 7, StealthEvening = 7}) do
    for i = 1, count do
        nextID = nextID + 1
        groups[name][i] = nextID
        pieces[name .. i] = nextID
    end
end
unitID = 10; unitDefID = 1; x_axis = 1; y_axis = 2
script = {}; include = noop
UnitDefNames = {ground_tank_day = {id = 1}}
Spring = {
    GetUnitTeam = function() return 1 end, GetGaiaTeamID = function() return 0 end,
    GetUnitDefID = function() return 1 end, GetUnitPieceMap = function() return pieces end,
    SetUnitNanoPieces = noop,
    SetUnitRulesParam = function(_, name, value, access)
        assert(access.inlos and not access.public, "canopy state exposed outside LOS")
        rules[name] = value
    end,
}
piece = function(name) return assert(pieces[name], name) end
local rolls = 0
randChance = function() rolls = rolls + 1; return true end
getPieceTableByNameGroups = function() return groups end
Show = function(id) assert(id); shown[id] = true end
Hide = function(id) shown[id] = nil end
hideT = function(t) for _, id in ipairs(t or {}) do Hide(id) end end
showT = function(t) assert(type(t) == "table"); for _, id in ipairs(t) do Show(id) end end
Turn = function(id, axis, angle, speed) turns[id] = {axis, angle, speed} end
WaitForTurn = noop
Sleep = coroutine.yield
local resetDone = false
resetAll = function() resetDone = true end
StartThread = function(fn)
    assert(resetDone, "animation starts before initial reset")
end
local night = false
isNight = function() return night end
dofile("scripts/tankscript.lua")
script.Create()
assert(rules.tank_camo_count == 0 and not shown[pieces.Halterrung])
setup(); showCloakAnimation()
assert(rolls == 1, "second random roll disables equipped tank")
assert(rules.tank_camo_count == 14)
for _, id in ipairs(groups.StealthShieldFold) do
    assert(shown[id] and turns[id][2] == 0, "panel failed to unfold")
end
local animation = coroutine.create(runCloakAnimations)
local function step()
    local ok, err = coroutine.resume(animation)
    assert(ok, err)
    local active = {}
    for i = 1, rules.tank_camo_count do
        local id = rules["tank_camo_piece_" .. i]
        assert(shown[id], "renderer received a hidden panel")
        active[id] = true
    end
    for _, group in pairs(groups) do
        for _, id in ipairs(group) do
            assert(not shown[id] or active[id], "stale animation mesh remains visible")
        end
    end
end
step(); assert(rules.tank_camo_count == 14)
boolMoving = true
for i = 1, 7 do
    step()
    assert(rules.tank_camo_count == 1 and rules.tank_camo_piece_1 == groups.MoveStealth[i], "movement frame skipped/reset")
end
step(); assert(rules.tank_camo_count == 14)
night = true
for i = 1, 7 do
    step(); assert(rules.tank_camo_piece_1 == groups.StealthEvening[i])
end
step(); assert(rules.tank_camo_piece_1 == groups.StealthEvening[7])
boolMoving = false; step(); assert(rules.tank_camo_piece_1 == groups.StealthEvening[1])
night = false; step(); assert(rules.tank_camo_count == 14)
boolCloaked = false; step(); hideCloakAnimation()
assert(rules.tank_camo_count == 0)
SFX = {EXPLODE = 1, SMOKE = 2, FIRE = 4}; Explode = noop; createTankCorpse = noop
showCloakAnimation(); script.Killed(10, 100)
assert(rules.tank_camo_count == 0 and not isStealthTank)

-- Renderer lifecycle: hidden enemies, icons, construction, stale frames, resize,
-- full-view spectators, one shared capture and ordinary-panel fallback.
local alloc, copies, draws, deleted = 0, 0, 0, 0
local los, fullView, dead, cloaked, noDraw, build = true, false, false, false, false, 1
local visible = {10, 11}
local vw, vh, ox, oy = 640, 480, 17, 23
local matrices, attributes = 0, 0
local viewport, copyArgs
gadget = {}; gadgetHandler = {IsSyncedCode = function() return false end, RemoveGadget = function(_, g) g:Shutdown() end}
VFS = {LoadFile = function(path) local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s end}
GL = {ALL_ATTRIB_BITS = 1, LEQUAL = 2, RGB8 = 3, NEAREST = 4, CLAMP_TO_EDGE = 5}
Game = {gameSpeed = 30}
Spring.GetSpectatingState = function() return fullView, fullView end
Spring.GetMyAllyTeamID = function() return 1 end
Spring.GetUnitIsDead = function() return dead end
Spring.GetUnitNoDraw = function() return noDraw end
Spring.GetUnitIsCloaked = function() return cloaked end
Spring.GetUnitLosState = function() return {los = los} end
Spring.GetUnitHealth = function() return 100, 100, 0, 0, build end
Spring.GetVisibleUnits = function(_, _, icons) assert(icons == false); return visible end
Spring.GetUnitRulesParam = function(_, key) return ({tank_camo_count = 2, tank_camo_piece_1 = 20, tank_camo_piece_2 = 21})[key] end
Spring.GetViewGeometry = function() return vw, vh, ox, oy end
Spring.GetGameFrame = function() return 60 end
Spring.GetFrameTimeOffset = function() return 0 end
Spring.Echo = noop
gl = {
    CreateShader = function() return 1 end, GetUniformLocation = function(_, key) return key end,
    CreateTexture = function(w, h) alloc = alloc + 1; assert(w == vw and h == vh); return alloc end,
    DeleteTexture = function() deleted = deleted + 1 end, DeleteShader = noop,
    CopyToTexture = function(...) copies = copies + 1; copyArgs = {...} end,
    PushAttrib = function() attributes = attributes + 1 end, PopAttrib = function() attributes = attributes - 1 end,
    PushMatrix = function() matrices = matrices + 1 end, PopMatrix = function() matrices = matrices - 1 end,
    UnitPiece = function(_, id) assert(id == 20 or id == 21); draws = draws + 1 end,
    Uniform = function(name, ...) if name == "viewport" then viewport = {...} end end,
    DepthTest = function(mode) assert(mode == GL.LEQUAL, "foreground depth ignored") end,
    DepthMask = function(on) assert(not on, "overlay modified depth") end,
    Blending = function(on) assert(not on, "camouflage became transparent") end,
    Culling = noop, PolygonOffset = noop, Texture = noop, UseShader = noop,
    UnitMultMatrix = noop, UnitPieceMultMatrix = noop,
}
dofile("luarules/gadgets/gfx_tank_camouflage.lua"); gadget:Initialize()
local function render() gadget:DrawWorldPreUnit(); gadget:DrawWorld(); assert(matrices == 0 and attributes == 0) end
los = false; render(); assert(copies == 0 and alloc == 0 and draws == 0, "LOS leak")
los = true; cloaked = true; render(); assert(copies == 0)
cloaked = false; noDraw = true; render(); assert(copies == 0)
noDraw = false; dead = true; render(); assert(copies == 0)
dead = false; build = 0.5; render(); assert(copies == 0)
build = 1; visible = {}; render(); assert(copies == 0)
visible = {10, 11}; render(); assert(copies == 1 and alloc == 1 and draws == 4)
assert(copyArgs[4] == ox and copyArgs[5] == oy and viewport[1] == ox and viewport[2] == oy)
gadget:DrawWorld(); assert(draws == 4, "stale capture reused")
render(); assert(alloc == 1 and copies == 2)
gadget:DrawWorldPreUnit(); los = false; gadget:DrawWorld(); assert(draws == 8, "LOS recheck missing")
fullView = true; render(); assert(draws == 12)
vw = 800; vh = 600; gadget:ViewResize(); render(); assert(alloc == 2 and deleted == 1)
gadget:Shutdown(); assert(deleted == 2)
-- A failed allocation removes the effect without hiding any engine mesh.
gl.CreateTexture = function() return nil end
gadget:Initialize(); render(); assert(deleted == 2)
print("PASS tank camouflage: unfold/move/night/fold/death, exact visible pieces, LOS/build/icon culling, shared capture, viewport/resize, state cleanup and allocation fallback")
