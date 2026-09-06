function widget:GetInfo()
    return {
        name = "NeonLight Radiance Cascade",
        desc = "Builds a top-down neon emission atlas for later radiance propagation",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = -9,
        enabled = true,
        hidden = false,
    }
end

-- L0 only: first prove a stable top-down neon emission atlas.
local ATLAS_SIZE = 1024
local ATLAS_REFRESH_SECONDS = 0.10
local DAYLENGTH = 28800
local DEBUG_VIEW = true
local DEBUG_VIEW_FRACTION = 0.40

local neonUnitTables = {}
local neonLightPercent = 0.0
local topDownTex
local refreshAccumulator = ATLAS_REFRESH_SECONDS
local vsx, vsy = gl.GetViewSizes()

local function dayPercentToNeonPercent(percent)
    if percent < 0.25 then
        return 1.0 - percent / 0.25
    end
    if percent > 0.75 then
        return 1.0 - (1.0 - percent) / 0.25
    end
    return 0.0
end

local function getDayPercent()
    return (Spring.GetGameFrame() % DAYLENGTH) / DAYLENGTH
end

-- Keep the misspelled public name for compatibility with gfx_neonHolograms.lua.
local function recieveNeonHoloLightPiecesByUnit(unitPiecesTable)
    neonUnitTables = unitPiecesTable or {}
end

local function removeSelf(message)
    Spring.Echo("NeonLight Radiance Cascade: " .. message)
    widgetHandler:RemoveWidget(widget)
end

function widget:Initialize()
    if not gl.RenderToTexture or not gl.CreateTexture or not gl.UnitPiece then
        removeSelf("required FBO or unit-piece drawing API is unavailable")
        return
    end

    topDownTex = gl.CreateTexture(ATLAS_SIZE, ATLAS_SIZE, {
        min_filter = GL.LINEAR,
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE,
        wrap_t = GL.CLAMP_TO_EDGE,
        fbo = true,
    })

    if not topDownTex then
        removeSelf("could not create the L0 emission texture")
        return
    end

    widgetHandler:RegisterGlobal(
        "RecieveAllNeonUnitsPieces",
        recieveNeonHoloLightPiecesByUnit
    )

    Spring.Echo(
        "NeonLight Radiance Cascade: L0 debug atlas enabled (" ..
        ATLAS_SIZE .. "x" .. ATLAS_SIZE .. ", 10 Hz)"
    )
end

function widget:ViewResize()
    vsx, vsy = gl.GetViewSizes()
end

function widget:Update(dt)
    neonLightPercent = dayPercentToNeonPercent(getDayPercent())
    refreshAccumulator = refreshAccumulator + dt
end

local function drawNeonPieces()
    gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0)
    gl.Clear(GL.DEPTH_BUFFER_BIT, 1)

    gl.DepthTest(true)
    gl.DepthMask(true)
    gl.Blending(false)
    gl.Culling(false)
    gl.Texture(false)
    gl.Color(neonLightPercent, neonLightPercent, neonLightPercent, 1.0)

    -- Map Spring world X/Z onto atlas X/Y without touching the player camera.
    gl.MatrixMode(GL.PROJECTION)
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.Ortho(0, Game.mapSizeX, 0, Game.mapSizeZ, -100000, 100000)

    gl.MatrixMode(GL.MODELVIEW)
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.Rotate(-90, 1, 0, 0)

    for unitID, pieces in pairs(neonUnitTables) do
        if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
            gl.PushMatrix()
            gl.UnitMultMatrix(unitID)

            for i = 1, #pieces do
                local pieceID = pieces[i]
                if pieceID then
                    gl.PushMatrix()
                    gl.UnitPieceMultMatrix(unitID, pieceID)
                    gl.UnitPiece(unitID, pieceID)
                    gl.PopMatrix()
                end
            end

            gl.PopMatrix()
        end
    end

    gl.PopMatrix()
    gl.MatrixMode(GL.PROJECTION)
    gl.PopMatrix()
    gl.MatrixMode(GL.MODELVIEW)

    gl.Color(1, 1, 1, 1)
    gl.DepthMask(false)
    gl.DepthTest(false)
    gl.Blending(false)
    gl.Texture(false)
end

function widget:DrawWorldPreUnit()
    if not topDownTex or refreshAccumulator < ATLAS_REFRESH_SECONDS then
        return
    end

    refreshAccumulator = refreshAccumulator % ATLAS_REFRESH_SECONDS
    gl.RenderToTexture(topDownTex, drawNeonPieces)
end

function widget:DrawScreen()
    if not DEBUG_VIEW or not topDownTex then
        return
    end

    local debugSize = math.floor(math.min(vsx, vsy) * DEBUG_VIEW_FRACTION)
    local margin = 16

    gl.Color(0, 0, 0, 0.75)
    gl.Rect(margin - 2, margin - 2, margin + debugSize + 2, margin + debugSize + 2)

    gl.Color(1, 1, 1, 1)
    gl.Texture(topDownTex)
    gl.TexRect(margin, margin, margin + debugSize, margin + debugSize, 0, 0, 1, 1)
    gl.Texture(false)
end

function widget:Shutdown()
    widgetHandler:DeregisterGlobal("RecieveAllNeonUnitsPieces")

    if topDownTex then
        gl.DeleteTexture(topDownTex)
        topDownTex = nil
    end
end
