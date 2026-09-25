-- Shared by the synced registration API and local preview. No rendering state.
local M = {}
local function number(v, default, lo, hi)
    if v == nil then return default end
    assert(type(v) == 'number' and v == v and math.abs(v) < math.huge, 'expected finite number')
    return math.max(lo, math.min(hi, v))
end
local function vector(v, default, n, lo, hi)
    v = v or default
    assert(type(v) == 'table', 'expected vector table')
    local out = {}
    for i = 1, n do out[i] = number(v[i], default[i], lo, hi) end
    return out
end
function M.Normalize(unitID, piece, options)
    assert(Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID), 'invalid smoke unit')
    local map = Spring.GetUnitPieceMap(unitID) or {}
    if type(piece) == 'string' then piece = map[piece] end
    local found = false
    for _, p in pairs(map) do if p == piece then found = true; break end end
    assert(found, 'unknown smoke emitter piece')
    local o = options or {}
    local mode = o.mode or 'smoke'
    assert(mode == 'smoke' or mode == 'hair', 'unknown ribbon mode')
    local hair = mode == 'hair'
    local direction = vector(o.direction, (hair and {0, 0, -1} or {0, 1, 0}), 3, -1e6, 1e6)
    local length = math.sqrt(direction[1]^2 + direction[2]^2 + direction[3]^2)
    assert(length > 1e-6, 'smoke direction must be nonzero')
    for i = 1, 3 do direction[i] = direction[i] / length end
    local space = o.directionSpace or (hair and 'piece' or 'world')
    assert(space == 'world' or space == 'unit' or space == 'emitter' or space == 'piece', 'unknown directionSpace')
    local directionPiece = o.directionPiece
    if directionPiece ~= nil then
        assert(space == 'piece', 'directionPiece requires piece directionSpace')
        if type(directionPiece) == 'string' then directionPiece = map[directionPiece] end
        local valid = false
        for _, p in pairs(map) do if p == directionPiece then valid = true; break end end
        assert(valid, 'unknown ribbon direction piece')
    end
    return {
        mode = mode, rootOffset = vector(o.rootOffset, {0,0,0}, 3, -1e4, 1e4),
        stiffness = number(o.stiffness, 0.7, 0, 1),
        gravity = number(o.gravity, 0.35, 0, 1),
        unitID = unitID, piece = piece, directionPiece = directionPiece,
        direction = direction, directionSpace = space,
        scale = number(o.scale, 1, 0.001, 100),
        length = number(o.length, hair and 3 or 60, 0.01, 2000),
        width = number(o.width, hair and 0.5 or 9, 0.01, 500),
        curl = number(o.curl, hair and 0.12 or 0.8, 0, 2),
        speed = number(o.speed, 1, 0, 20),
        distanceFactor = number(o.distanceFactor, 40, 1, 200),
        groundDirected = not hair and o.groundDirected == true,
        windAffected = o.windAffected ~= false,
        motionAffected = o.motionAffected == true or (hair and o.motionAffected ~= false),
        windInfluence = number(o.windInfluence, hair and 0.04 or 0.3, 0, 10),
        motionInfluence = number(o.motionInfluence, 1, 0, 10),
        trailTime = number(o.trailTime, hair and 0.12 or 0.7, 0, 5),
        colorStart = vector(o.colorStart, hair and {0.08,0.045,0.025,1} or {0.65, 0.68, 0.72, 0.5}, 4, 0, 1),
        colorEnd = vector(o.colorEnd, hair and {0.16,0.09,0.045,1} or {0.4, 0.43, 0.48, 0}, 4, 0, 1),
        emission = vector(o.emission, {0, 0}, 2, 0, 8),
        seed = number(o.seed, (unitID * 0.754877666 + piece * 0.569840296) % 100, 0, 10000),
        strands = math.floor(number(o.strands, hair and 1 or 3, 1, 4)),
        enabled = o.enabled ~= false,
    }
end
return M
