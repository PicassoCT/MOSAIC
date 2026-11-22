-- Exercise real script coroutines and the renderer's visibility/GL-state boundaries.
local shown, params, threads, current = {}, {}, {}, nil
local now = 0
local function noop() end
local function resume(thread)
    current = thread
    local ok, delay = coroutine.resume(thread.co)
    assert(ok, delay)
    thread.wake = now + (delay or 0)
    current = nil
end
function StartThread(fn, ...)
    local args = {...}
    local thread = {mask = 0, wake = now, co = coroutine.create(function() fn(unpack(args)) end)}
    threads[#threads + 1] = thread
    resume(thread)
end
function Sleep(ms) coroutine.yield(ms) end
function SetSignalMask(mask) current.mask = mask end
function Signal(mask)
    for _, thread in ipairs(threads) do
        if thread.mask == mask then thread.cancelled = true end
    end
end
local function advance(ms)
    local finish = now + ms
    while true do
        local nextThread
        for _, thread in ipairs(threads) do
            if not thread.cancelled and coroutine.status(thread.co) ~= 'dead'
                and thread.wake <= finish and (not nextThread or thread.wake < nextThread.wake) then
                nextThread = thread
            end
        end
        if not nextThread then break end
        now = nextThread.wake
        resume(nextThread)
    end
    now = finish
end

include = noop
piece = function(name) return name end
Hide = function(p) shown[p] = false end
Show = function(p)
    assert(p ~= 'rotors' and p ~= 'tailrotors', 'opaque disc shown')
    shown[p] = true
end
Turn, Move, Spin, StopSpin, EmitSfx, createCorpseCUnitGeneric = noop, noop, noop, noop, noop, noop
isNight = function() return true end
x_axis, y_axis, z_axis = 1, 2, 3
unitID, unitDefID = 11, 7
Game = {windMax = 10, gameSpeed = 30}
Spring = {SetUnitRulesParam = function(id, key, value, access)
    assert(id == unitID and access.inlos)
    params[key] = value
end}
script = {}
dofile('scripts/air_black_hawk_script.lua')
script.Create()
assert(params.helicopter_rotor_blur == 0 and shown.nightlight == false)
script.Activate()
advance(2300)
assert(params.helicopter_rotor_blur == 0, 'blur before blade handoff')
advance(300)
assert(params.helicopter_rotor_blur == 1 and shown.rotor == false and shown.tailrotor == false)
assert(shown.nightlight == true, 'night light aliases the rotor disc')
script.StopMoving()
advance(1000)
assert(params.helicopter_rotor_blur == 1, 'hovering loses rotor blur')
script.Deactivate()
advance(1000)
assert(params.helicopter_rotor_blur == 0 and shown.rotor and shown.tailrotor)
script.Activate()
script.Deactivate() -- Interrupt even before the first sleep has completed.
advance(3000)
assert(params.helicopter_rotor_blur == 0 and shown.rotor and shown.tailrotor)
script.Activate()
advance(2600)
script.Deactivate()
advance(500)
script.Activate() -- Aborted landing must not leave a shutdown coroutine behind.
advance(3000)
assert(params.helicopter_rotor_blur == 1 and shown.rotor == false)
script.Killed()
assert(params.helicopter_rotor_blur == 0)
Game.windMax = 0
script.Create()
script.Activate()
advance(3000)
assert(params.helicopter_rotor_blur == 0, 'changed existing no-air variant')

gadget = {}
gadgetHandler = {IsSyncedCode = function() return true end}
local renderer = 'luarules/gadgets/gfx_helicopter_rotor_blur.lua'
assert(dofile(renderer) == false and gadget.Initialize == nil)
gadgetHandler.IsSyncedCode = function() return false end
UnitDefNames = {air_copter_blackhawk = {id = 7}}
local units = {
    [11] = {blur = 1, los = true},
    [12] = {blur = 0, los = true},
    [13] = {blur = 1, los = false},
    [14] = {blur = 1, los = true, cloaked = true},
    [15] = {blur = 1, los = true, noDraw = true},
    [16] = {blur = 1, los = true, dead = true},
    [17] = {blur = 1, los = true, def = 99},
    [18] = {los = true},
    [19] = {blur = 1, los = true, incomplete = true},
}
local fullView = false
local pieceReads = 0
Spring = {
    GetVisibleUnits = function(team, radius, icons)
        assert(team == -1 and radius == nil and icons == false)
        return {11, 12, 13, 14, 15, 16, 17, 18, 19}
    end,
    GetSpectatingState = function() return fullView, fullView end,
    GetMyAllyTeamID = function() return 3 end,
    GetUnitDefID = function(id) return units[id].def or 7 end,
    GetUnitIsDead = function(id) return units[id].dead end,
    GetUnitNoDraw = function(id) return units[id].noDraw end,
    GetUnitIsCloaked = function(id) return units[id].cloaked end,
    GetUnitRulesParam = function(id, key)
        assert(key == 'helicopter_rotor_blur')
        return units[id].blur
    end,
    GetUnitLosState = function(id, ally)
        assert(ally == 3)
        return {los = units[id].los, radar = true}
    end,
    GetUnitPieceMap = function(id)
        pieceReads = pieceReads + 1
        if units[id].incomplete then return end
        return {rotors = 4, tailrotors = 6}
    end,
    GetUnitPieceInfo = function(_, p)
        if p == 4 then return {min = {-361, -361, 9}, max = {361, 361, 23}} end
        return {min = {-2, -93, -93}, max = {2, 93, 93}}
    end,
    GetGameFrame = function() return 300 end,
    GetFrameTimeOffset = function() return .5 end,
}
GL = {TRIANGLE_STRIP = 5, ALL_ATTRIB_BITS = 123, SMOOTH = 7425,
    LEQUAL = 515, SRC_ALPHA = 770, ONE_MINUS_SRC_ALPHA = 771}
local vertices, color, strip, deleted = {}, {}, 0, false
local draws, matrixDepth, attribDepth, state, activeID, activePiece = {}, 0, 0, {}, nil, nil
gl = {
    CreateList = function(fn) fn(); return 24 end,
    BeginEnd = function(mode, fn) assert(mode == GL.TRIANGLE_STRIP); strip = strip + 1; fn() end,
    Color = function(...) color = {...} end,
    Vertex = function(x, y, z) vertices[#vertices + 1] = {strip, x, y, z, unpack(color)} end,
    PushAttrib = function() attribDepth = attribDepth + 1 end,
    PopAttrib = function() attribDepth = attribDepth - 1 end,
    PushMatrix = function() matrixDepth = matrixDepth + 1 end,
    PopMatrix = function() matrixDepth = matrixDepth - 1 end,
    UseShader = function(s) state.shader = s end,
    Texture = function(s) state.texture = s end,
    Lighting = function(s) state.lighting = s end,
    AlphaTest = function(s) state.alphaTest = s end,
    ShadeModel = function(s) state.shading = s end,
    DepthTest = function(s) state.depth = s end,
    DepthMask = function(s) state.depthWrite = s end,
    Blending = function(a, b) state.blend = {a, b} end,
    Culling = function(s) state.culling = s end,
    UnitMultMatrix = function(id) activeID = id end,
    UnitPieceMultMatrix = function(id, p) assert(id == activeID); activePiece = p end,
    Translate = function(x, y, z)
        assert(x == 0 and y == 0 and z == (activePiece == 4 and 16 or 0))
    end,
    Scale = function(x, y, z)
        local radius = activePiece == 4 and 361 or 93
        assert(x == radius and y == radius and z == 1, 'disc does not match model size')
    end,
    Rotate = function(angle, x, y, z)
        if z == 0 then assert(activePiece == 6 and angle == 90 and y == 1) end
    end,
    CallList = function(list)
        assert(list == 24 and state.shader == 0 and state.texture == false and state.lighting == false)
        assert(state.alphaTest == false and state.depth == GL.LEQUAL and state.depthWrite == false)
        assert(state.blend[1] == GL.SRC_ALPHA and state.blend[2] == GL.ONE_MINUS_SRC_ALPHA)
        assert(state.culling == false and state.shading == GL.SMOOTH)
        draws[#draws + 1] = {activeID, activePiece}
    end,
    DeleteList = function(list) assert(list == 24); deleted = true end,
}
dofile(renderer)
gadget:Initialize()
local maxAlpha = 0
for _, v in ipairs(vertices) do
    local radius = math.sqrt(v[2]^2 + v[3]^2)
    assert(radius <= 1.00001 and v[4] == 0)
    assert(v[8] >= 0 and v[8] <= .16001, 'opaque rotor blur')
    if radius < .00001 or radius > .99999 then assert(v[8] == 0, 'hard disc edge') end
    maxAlpha = math.max(maxAlpha, v[8])
end
assert(maxAlpha > .1, 'invisible blur')
gadget:DrawWorld()
assert(#draws == 2 and draws[1][1] == 11 and draws[1][2] == 4 and draws[2][2] == 6)
assert(matrixDepth == 0 and attribDepth == 0)
local before = pieceReads
gadget:DrawWorld()
assert(pieceReads == before + 1, 'visible rotor geometry was not cached') -- incomplete unit retried
gadget:UnitDestroyed(11)
gadget:DrawWorld()
assert(pieceReads == before + 3, 'destroyed unit retains cached piece IDs')
fullView = true
draws = {}
gadget:DrawWorld()
assert(#draws == 4 and draws[3][1] == 13, 'full-view spectator cannot see off-LOS rotors')
gadget:Shutdown()
assert(deleted)
draws = {}
gadget:DrawWorld()
assert(#draws == 0 and matrixDepth == 0 and attribDepth == 0)

-- Optional export of the production mesh for a headless OpenGL visual check.
local export = os.getenv('MOSAIC_ROTOR_MESH')
if export then
    local file = assert(io.open(export, 'w'))
    for _, vertex in ipairs(vertices) do file:write(table.concat(vertex, ','), '\n') end
    file:close()
end
print('helicopter rotor blur: script lifecycle, transparency, geometry, visibility and cleanup passed')
