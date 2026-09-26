function gadget:GetInfo()
    return {
        name = "Luxor Waterfalls",
        desc = "Opaque illuminated water with flowing surface glitter",
        author = "PicassoCT, Codex",
        license = "GPL3",
        layer = -13,
        enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then return false end

local luxorDef = UnitDefNames.house_asian4
if not luxorDef then return false end
local shader
local uniforms = {}
local piecesByUnit = {}

function gadget:Initialize()
    if not gl.CreateShader then
        gadgetHandler:RemoveGadget(self)
        return
    end
    local path = "luarules/gadgets/shaders/luxorWaterfall."
    shader = gl.CreateShader({
        vertex = VFS.LoadFile(path .. "vert"),
        fragment = VFS.LoadFile(path .. "frag"),
        uniformInt = {diffuseTex = 0, materialTex = 1},
    })
    if not shader then
        Spring.Echo("Luxor Waterfalls: " .. (gl.GetShaderLog() or "shader unavailable"))
        -- The ordinary illuminated meshes remain visible if GLSL is unavailable.
        gadgetHandler:RemoveGadget(self)
        return
    end
    for _, name in ipairs({"viewInverse", "effectTime", "seed", "cameraPosition", "ambient"}) do
        uniforms[name] = gl.GetUniformLocation(shader, name)
    end
end

local function getPieces(unitID)
    local cached = piecesByUnit[unitID]
    if cached then return cached end
    local count = Spring.GetUnitRulesParam(unitID, "luxor_waterfall_count")
    if not count or count == 0 then return end
    local pieces = {}
    for i = 1, count do
        local piece = Spring.GetUnitRulesParam(unitID, "luxor_waterfall_piece_" .. i)
        if not piece then return end -- wait until the complete set is visible
        pieces[i] = piece
    end
    piecesByUnit[unitID] = pieces
    return pieces
end

function gadget:DrawWorld()
    if not shader then return end
    local candidates = {}
    local _, fullView = Spring.GetSpectatingState()
    local allyTeam = Spring.GetMyAllyTeamID()
    -- Unsynced gadgets can have full read access: explicitly check local LOS.
    -- GetVisibleUnits' third argument excludes icons.
    for _, unitID in ipairs(Spring.GetVisibleUnits(-1, nil, false) or {}) do
        if Spring.GetUnitDefID(unitID) == luxorDef.id
            and not Spring.GetUnitIsDead(unitID)
            and not Spring.GetUnitNoDraw(unitID)
            and not Spring.GetUnitIsCloaked(unitID)
            and Spring.GetUnitRulesParam(unitID, "luxor_waterfall_visible") == 1 then
            local los = fullView or Spring.GetUnitLosState(unitID, allyTeam)
            if fullView or (los and los.los) then
                local pieces = getPieces(unitID)
                if pieces then candidates[#candidates + 1] = {id = unitID, pieces = pieces} end
            end
        end
    end
    if #candidates == 0 then return end

    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(true)
    gl.Blending(false)
    gl.Culling(false)
    -- Draw directly over the existing opaque surface without z-fighting.
    gl.PolygonOffset(-1, -1)
    gl.Texture(0, "%" .. luxorDef.id .. ":0")
    gl.Texture(1, "%" .. luxorDef.id .. ":1")
    gl.UseShader(shader)
    gl.UniformMatrix(uniforms.viewInverse, "viewinverse")
    gl.Uniform(uniforms.effectTime,
        (Spring.GetGameFrame() + (Spring.GetFrameTimeOffset() or 0)) / (Game.gameSpeed or 30))
    gl.Uniform(uniforms.cameraPosition, Spring.GetCameraPosition())
    local ar, ag, ab = gl.GetSun("ambient", "unit")
    gl.Uniform(uniforms.ambient, ar or .5, ag or .5, ab or .5)
    for _, entry in ipairs(candidates) do
        gl.Uniform(uniforms.seed, entry.id * .173)
        gl.PushMatrix()
        gl.UnitMultMatrix(entry.id)
        for _, piece in ipairs(entry.pieces) do
            gl.PushMatrix()
            gl.UnitPieceMultMatrix(entry.id, piece)
            gl.UnitPiece(entry.id, piece)
            gl.PopMatrix()
        end
        gl.PopMatrix()
    end
    gl.UseShader(0)
    gl.Texture(1, false)
    gl.Texture(0, false)
    gl.PopAttrib()
end

function gadget:UnitDestroyed(unitID)
    piecesByUnit[unitID] = nil
end

function gadget:Shutdown()
    if shader then gl.DeleteShader(shader); shader = nil end
    piecesByUnit = {}
end
