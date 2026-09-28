function gadget:GetInfo()
    return {
        name = "Tank Canopy Camouflage",
        desc = "Imperfect pixelated terrain projection on unfolded tank panels",
        author = "PicassoCT, Codex",
        license = "GPL3",
        layer = -100,
        enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then return false end
local tankDef = UnitDefNames.ground_tank_day
if not tankDef then return false end

local shader, terrainTexture
local uniforms = {}
local width, height, originX, originY = 0, 0, 0, 0
local candidates = {}
local captured = false

local function releaseTexture()
    if terrainTexture then gl.DeleteTexture(terrainTexture) end
    terrainTexture = nil
    captured = false
end

local function canDraw(unitID, allyTeam, fullView)
    if Spring.GetUnitIsDead(unitID) or Spring.GetUnitNoDraw(unitID)
        or Spring.GetUnitIsCloaked(unitID) then return false end
    local los = fullView or Spring.GetUnitLosState(unitID, allyTeam)
    if not fullView and not (los and los.los) then return false end
    local _, _, _, _, build = Spring.GetUnitHealth(unitID)
    return build and build >= 1
end

function gadget:Initialize()
    if not gl.CreateShader or not gl.CopyToTexture or not gl.UnitPieceMultMatrix then
        gadgetHandler:RemoveGadget(self)
        return
    end
    local path = "luarules/gadgets/shaders/tankCamouflage."
    shader = gl.CreateShader({
        vertex = VFS.LoadFile(path .. "vert"),
        fragment = VFS.LoadFile(path .. "frag"),
        uniformInt = {terrainTex = 0},
    })
    if not shader then
        Spring.Echo("Tank canopy camouflage: " .. (gl.GetShaderLog() or "shader unavailable"))
        gadgetHandler:RemoveGadget(self)
        return
    end
    for _, name in ipairs({"viewport", "effectTime", "seed", "pixelSize"}) do
        uniforms[name] = gl.GetUniformLocation(shader, name)
    end
end

function gadget:ViewResize()
    releaseTexture()
end

function gadget:DrawWorldPreUnit()
    captured = false
    candidates = {}
    if not shader then return end
    local _, fullView = Spring.GetSpectatingState()
    local allyTeam = Spring.GetMyAllyTeamID()
    -- Unsynced gadgets may read every unit: both LOS and the non-icon visible
    -- list are required. Do this before allocating or copying any framebuffer.
    for _, unitID in ipairs(Spring.GetVisibleUnits(-1, nil, false) or {}) do
        if Spring.GetUnitDefID(unitID) == tankDef.id and canDraw(unitID, allyTeam, fullView) then
            local count = Spring.GetUnitRulesParam(unitID, "tank_camo_count") or 0
            if count > 0 then
                local pieces = {}
                for i = 1, count do
                    local id = Spring.GetUnitRulesParam(unitID, "tank_camo_piece_" .. i)
                    if not id then break end
                    pieces[i] = id
                end
                if #pieces == count then
                    candidates[#candidates + 1] = {id = unitID, pieces = pieces}
                end
            end
        end
    end
    if #candidates == 0 then return end

    local sx, sy, ox, oy = Spring.GetViewGeometry()
    if sx <= 0 or sy <= 0 then return end
    if sx ~= width or sy ~= height then releaseTexture() end
    width, height, originX, originY = sx, sy, ox or 0, oy or 0
    if not terrainTexture then
        terrainTexture = gl.CreateTexture(width, height, {
            format = GL.RGB8,
            min_filter = GL.NEAREST, mag_filter = GL.NEAREST,
            wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE,
        })
        if not terrainTexture then
            Spring.Echo("Tank canopy camouflage: terrain copy unavailable; using ordinary panels")
            gadgetHandler:RemoveGadget(self)
            return
        end
    end
    -- Recoil draws lit terrain before DrawWorldPreUnit, units/features after it.
    -- One shared copy, only when an equipped tank is visible; no second world
    -- render, per-unit textures, GPU readback, or dependency on deferred buffers.
    gl.CopyToTexture(terrainTexture, 0, 0, originX, originY, width, height)
    captured = true
end

function gadget:DrawWorld()
    if not shader or not captured then return end
    captured = false -- never reuse an old view if the pre-unit pass is skipped
    local _, fullView = Spring.GetSpectatingState()
    local allyTeam = Spring.GetMyAllyTeamID()
    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(false)
    gl.Blending(false)
    gl.Culling(false)
    gl.PolygonOffset(-1, -1)
    gl.Texture(0, terrainTexture)
    gl.UseShader(shader)
    gl.Uniform(uniforms.viewport, originX, originY, width, height)
    gl.Uniform(uniforms.effectTime,
        (Spring.GetGameFrame() + (Spring.GetFrameTimeOffset() or 0)) / (Game.gameSpeed or 30))
    gl.Uniform(uniforms.pixelSize, 6)
    for _, entry in ipairs(candidates) do
        if canDraw(entry.id, allyTeam, fullView) then
            gl.Uniform(uniforms.seed, entry.id * 0.173)
            gl.PushMatrix()
            gl.UnitMultMatrix(entry.id)
            for _, pieceID in ipairs(entry.pieces) do
                gl.PushMatrix()
                gl.UnitPieceMultMatrix(entry.id, pieceID)
                gl.UnitPiece(entry.id, pieceID)
                gl.PopMatrix()
            end
            gl.PopMatrix()
        end
    end
    gl.UseShader(0)
    gl.Texture(0, false)
    gl.PopAttrib()
end

function gadget:Shutdown()
    releaseTexture()
    if shader then gl.DeleteShader(shader); shader = nil end
    candidates = {}
end
