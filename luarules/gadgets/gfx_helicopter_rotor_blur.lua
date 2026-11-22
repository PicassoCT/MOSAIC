function gadget:GetInfo()
    return {
        name = "Helicopter Rotor Blur",
        desc = "Translucent main and tail rotor discs at flight speed",
        author = "PicassoCT, Codex",
        license = "GPL3",
        layer = 0,
        enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then return false end

local rotorProfiles = {
    air_copter_blackhawk = {"rotors", "tailrotors"},
}
local profilesByDef = {}
for name, profile in pairs(rotorProfiles) do
    local def = UnitDefNames[name]
    if def then profilesByDef[def.id] = profile end
end

local discList
local piecesByUnit = {}
local segments = 64
-- Soft hub and outer edge; each annulus shares vertices without overlapping layers.
local rings = {{0, 0}, {.12, .09}, {.30, .16}, {.65, .13}, {.90, .08}, {1, 0}}

local function discVertex(radius, opacity, angle)
    local streak = .80 + .20 * math.cos(4 * angle - radius * .6)
    gl.Color(.20, .22, .23, opacity * streak)
    gl.Vertex(radius * math.cos(angle), radius * math.sin(angle), 0)
end

function gadget:Initialize()
    -- A shared fixed-function mesh avoids shader/texture dependencies and per-frame geometry.
    discList = gl.CreateList(function()
        for i = 1, #rings - 1 do
            gl.BeginEnd(GL.TRIANGLE_STRIP, function()
                for segment = 0, segments do
                    local angle = segment * math.pi * 2 / segments
                    discVertex(rings[i][1], rings[i][2], angle)
                    discVertex(rings[i + 1][1], rings[i + 1][2], angle)
                end
            end)
        end
    end)
end

local function getPieces(unitID, profile)
    if piecesByUnit[unitID] then return piecesByUnit[unitID] end
    local map = Spring.GetUnitPieceMap(unitID)
    if not map then return end
    local pieces = {}
    for _, name in ipairs(profile) do
        local piece = map[name]
        local info = piece and Spring.GetUnitPieceInfo(unitID, piece)
        if not info or not info.min or not info.max then return end
        local center, half = {}, {}
        for axis = 1, 3 do
            center[axis] = (info.min[axis] + info.max[axis]) * .5
            half[axis] = (info.max[axis] - info.min[axis]) * .5
        end
        -- Use the authored disc's bounds in piece space, including imported model scaling.
        local normal = 1
        for axis = 2, 3 do
            if half[axis] < half[normal] then normal = axis end
        end
        pieces[#pieces + 1] = {piece = piece, center = center, half = half, normal = normal}
    end
    piecesByUnit[unitID] = pieces
    return pieces
end

function gadget:DrawWorld()
    if not discList then return end
    local candidates = {}
    local _, fullView = Spring.GetSpectatingState()
    local allyTeam = Spring.GetMyAllyTeamID()
    for _, unitID in ipairs(Spring.GetVisibleUnits(-1, nil, false) or {}) do
        local profile = profilesByDef[Spring.GetUnitDefID(unitID)]
        if profile and not Spring.GetUnitIsDead(unitID)
            and not Spring.GetUnitNoDraw(unitID) and not Spring.GetUnitIsCloaked(unitID)
            and Spring.GetUnitRulesParam(unitID, "helicopter_rotor_blur") == 1 then
            -- Unsynced gadgets may have full read access; radar alone must not reveal rotors.
            local los = fullView or Spring.GetUnitLosState(unitID, allyTeam)
            if fullView or (los and los.los) then
                local pieces = getPieces(unitID, profile)
                if pieces then candidates[#candidates + 1] = {id = unitID, pieces = pieces} end
            end
        end
    end
    if #candidates == 0 then return end

    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.UseShader(0)
    gl.Texture(false)
    gl.Lighting(false)
    gl.AlphaTest(false)
    gl.ShadeModel(GL.SMOOTH)
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(false)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    gl.Culling(false)
    local frame = Spring.GetGameFrame() + (Spring.GetFrameTimeOffset() or 0)
    local angle = frame * 660 / (Game.gameSpeed or 30)
    for _, entry in ipairs(candidates) do
        gl.PushMatrix()
        gl.UnitMultMatrix(entry.id)
        for _, disc in ipairs(entry.pieces) do
            gl.PushMatrix()
            gl.UnitPieceMultMatrix(entry.id, disc.piece)
            gl.Translate(unpack(disc.center))
            if disc.normal == 1 then
                gl.Rotate(90, 0, 1, 0)
                gl.Scale(disc.half[3], disc.half[2], 1)
            elseif disc.normal == 2 then
                gl.Rotate(90, 1, 0, 0)
                gl.Scale(disc.half[1], disc.half[3], 1)
            else
                gl.Scale(disc.half[1], disc.half[2], 1)
            end
            gl.Rotate(angle + entry.id * 17, 0, 0, 1)
            gl.CallList(discList)
            gl.PopMatrix()
        end
        gl.PopMatrix()
    end
    gl.PopAttrib()
end

function gadget:UnitDestroyed(unitID)
    piecesByUnit[unitID] = nil
end

function gadget:Shutdown()
    if discList then gl.DeleteList(discList); discList = nil end
    piecesByUnit = {}
end
