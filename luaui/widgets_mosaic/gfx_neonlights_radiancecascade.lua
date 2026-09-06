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
local MORNING_OFFSET = DAYLENGTH * 0.5
local DEBUG_VIEW = true
local DEBUG_VIEW_FRACTION = 0.40
local OCCLUSION_ATLAS_SIZE = 512
local OCCLUSION_LAYER_COUNT = 16
local OCCLUSION_WORLD_HEIGHT = 2048
local DEBUG_OCCLUSION_LAYER = 4

local neonUnitTables = {}
local neonLightPercent = 0.0
local neonUnitCount = 0
local neonPieceCount = 0
local topDownTex
local occlusionTex = {}
local occlusionBuildings = {}
local occlusionDirty = true
local occlusionBuildingCount = 0
local refreshAccumulator = ATLAS_REFRESH_SECONDS
local vsx, vsy = gl.GetViewSizes()

local function customParam(params, name)
    return params[name] or params[string.lower(name)]
end

local function getOcclusionDefinition(unitDefID)
    local unitDef = UnitDefs[unitDefID]
    local params = unitDef and unitDef.customParams
    if not params then
        return nil
    end

    local atlas = customParam(params, "radianceOcclusionAtlas")
    if not atlas or atlas == "" then
        return nil
    end

    local sourceLayers = tonumber(customParam(params, "radianceOcclusionLayers")) or 16
    local columns = tonumber(customParam(params, "radianceOcclusionColumns")) or 4
    local rows = tonumber(customParam(params, "radianceOcclusionRows")) or 4
    local height = tonumber(customParam(params, "radianceOcclusionHeight"))
    local sizeX = tonumber(customParam(params, "radianceOcclusionSizeX"))
    local sizeZ = tonumber(customParam(params, "radianceOcclusionSizeZ"))

    if not height or not sizeX or not sizeZ or sourceLayers < 1 or columns * rows < sourceLayers then
        Spring.Echo("NeonLight Radiance Cascade: invalid occlusion parameters for " .. unitDef.name)
        return nil
    end

    return {
        atlas = atlas,
        sourceLayers = sourceLayers,
        columns = columns,
        rows = rows,
        height = height,
        sizeX = sizeX,
        sizeZ = sizeZ,
    }
end

local function addOcclusionBuilding(unitID, unitDefID)
    local definition = getOcclusionDefinition(unitDefID)
    if not definition then
        return
    end

    occlusionBuildings[unitID] = definition
    occlusionDirty = true
end

local function removeOcclusionBuilding(unitID)
    if occlusionBuildings[unitID] then
        occlusionBuildings[unitID] = nil
        occlusionDirty = true
    end
end

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
    return ((Spring.GetGameFrame() + MORNING_OFFSET) % DAYLENGTH) / DAYLENGTH
end

-- Keep the misspelled public name for compatibility with gfx_neonHolograms.lua.
local function recieveNeonHoloLightPiecesByUnit(unitPiecesTable)
    neonUnitTables = unitPiecesTable or {}
    neonUnitCount = 0
    neonPieceCount = 0

    for _, pieces in pairs(neonUnitTables) do
        neonUnitCount = neonUnitCount + 1
        neonPieceCount = neonPieceCount + #pieces
    end
end

local function removeSelf(message)
    Spring.Echo("NeonLight Radiance Cascade: " .. message)
    widgetHandler:RemoveWidget(widget)
end

local function drawOcclusionQuad(sizeX, sizeZ, u0, v0, u1, v1)
    local halfX = sizeX * 0.5
    local halfZ = sizeZ * 0.5

    gl.BeginEnd(GL.QUADS, function()
        gl.TexCoord(u0, v0); gl.Vertex(-halfX, -halfZ, 0)
        gl.TexCoord(u1, v0); gl.Vertex( halfX, -halfZ, 0)
        gl.TexCoord(u1, v1); gl.Vertex( halfX,  halfZ, 0)
        gl.TexCoord(u0, v1); gl.Vertex(-halfX,  halfZ, 0)
    end)
end

local function drawOcclusionLayer(layerIndex)
    local worldY = (layerIndex + 0.5) * OCCLUSION_WORLD_HEIGHT / OCCLUSION_LAYER_COUNT

    gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0)
    gl.DepthTest(false)
    gl.DepthMask(false)
    gl.Blending(false)
    gl.Culling(false)
    gl.AlphaTest(GL.GREATER, 0.5)
    gl.Color(1, 1, 1, 1)

    gl.MatrixMode(GL.PROJECTION)
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.Ortho(0, Game.mapSizeX, 0, Game.mapSizeZ, -1, 1)

    gl.MatrixMode(GL.MODELVIEW)
    gl.PushMatrix()
    gl.LoadIdentity()

    for unitID, definition in pairs(occlusionBuildings) do
        local x, baseY, z = Spring.GetUnitPosition(unitID)
        if x and worldY >= baseY and worldY < baseY + definition.height then
            local normalizedHeight = (worldY - baseY) / definition.height
            local sourceLayer = math.min(
                definition.sourceLayers - 1,
                math.floor(normalizedHeight * definition.sourceLayers)
            )
            local tileX = sourceLayer % definition.columns
            local tileY = math.floor(sourceLayer / definition.columns)
            local u0 = tileX / definition.columns
            local v0 = tileY / definition.rows
            local u1 = (tileX + 1) / definition.columns
            local v1 = (tileY + 1) / definition.rows
            local heading = Spring.GetUnitHeading(unitID) or 0
            local angle = heading * 360 / 65536

            gl.Texture(definition.atlas)
            gl.PushMatrix()
            gl.Translate(x, z, 0)
            gl.Rotate(-angle, 0, 0, 1)
            drawOcclusionQuad(definition.sizeX, definition.sizeZ, u0, v0, u1, v1)
            gl.PopMatrix()
        end
    end

    gl.Texture(false)
    gl.PopMatrix()
    gl.MatrixMode(GL.PROJECTION)
    gl.PopMatrix()
    gl.MatrixMode(GL.MODELVIEW)
    gl.AlphaTest(false)
    gl.Color(1, 1, 1, 1)
end

local function rebuildOcclusionAtlas()
    occlusionBuildingCount = 0
    for unitID in pairs(occlusionBuildings) do
        if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
            occlusionBuildingCount = occlusionBuildingCount + 1
        else
            occlusionBuildings[unitID] = nil
        end
    end

    for layerIndex = 0, OCCLUSION_LAYER_COUNT - 1 do
        gl.RenderToTexture(occlusionTex[layerIndex + 1], function()
            drawOcclusionLayer(layerIndex)
        end)
    end

    occlusionDirty = false
end

function widget:Initialize()
    if not gl.RenderToTexture or not gl.CreateTexture or not gl.UnitPiece
        or not gl.BeginEnd or not gl.AlphaTest
    then
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

    for layer = 1, OCCLUSION_LAYER_COUNT do
        occlusionTex[layer] = gl.CreateTexture(OCCLUSION_ATLAS_SIZE, OCCLUSION_ATLAS_SIZE, {
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        })

        if not occlusionTex[layer] then
            removeSelf("could not create occlusion layer " .. layer)
            return
        end
    end

    local allUnits = Spring.GetAllUnits()
    for i = 1, #allUnits do
        local unitID = allUnits[i]
        addOcclusionBuilding(unitID, Spring.GetUnitDefID(unitID))
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

function widget:UnitCreated(unitID, unitDefID)
    addOcclusionBuilding(unitID, unitDefID)
end

function widget:UnitDestroyed(unitID)
    removeOcclusionBuilding(unitID)
end

function widget:UnitGiven(unitID, unitDefID)
    addOcclusionBuilding(unitID, unitDefID)
end

function widget:UnitTaken(unitID)
    removeOcclusionBuilding(unitID)
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
    -- The debug atlas must remain readable during daytime, when the real
    -- emission factor is intentionally zero.
    local drawIntensity = DEBUG_VIEW and 1.0 or neonLightPercent
    gl.Color(drawIntensity, drawIntensity, drawIntensity, 1.0)

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

    if occlusionDirty then
        rebuildOcclusionAtlas()
    end
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
    -- Render-to-texture and screen space use opposite vertical origins.
    -- Flip only the preview; keep atlas UVs aligned with world X/Z.
    gl.TexRect(margin, margin, margin + debugSize, margin + debugSize, 0, 1, 1, 0)
    gl.Texture(false)

    gl.Text(
        string.format(
            "L0 debug | units: %d | pieces: %d | neon emission: %.2f",
            neonUnitCount,
            neonPieceCount,
            neonLightPercent
        ),
        margin,
        margin + debugSize + 8,
        13,
        "o"
    )

    local occlusionLayer = math.max(1, math.min(OCCLUSION_LAYER_COUNT, DEBUG_OCCLUSION_LAYER))
    local occlusionX = margin + debugSize + margin
    gl.Color(0, 0, 0, 0.75)
    gl.Rect(
        occlusionX - 2,
        margin - 2,
        occlusionX + debugSize + 2,
        margin + debugSize + 2
    )

    gl.Color(1, 1, 1, 1)
    gl.Texture(occlusionTex[occlusionLayer])
    gl.TexRect(
        occlusionX,
        margin,
        occlusionX + debugSize,
        margin + debugSize,
        0, 1, 1, 0
    )
    gl.Texture(false)
    gl.Text(
        string.format(
            "Occlusion slice %d/%d | y=%.0f | buildings: %d",
            occlusionLayer,
            OCCLUSION_LAYER_COUNT,
            (occlusionLayer - 0.5) * OCCLUSION_WORLD_HEIGHT / OCCLUSION_LAYER_COUNT,
            occlusionBuildingCount
        ),
        occlusionX,
        margin + debugSize + 8,
        13,
        "o"
    )
end

function widget:Shutdown()
    widgetHandler:DeregisterGlobal("RecieveAllNeonUnitsPieces")

    if topDownTex then
        gl.DeleteTexture(topDownTex)
        topDownTex = nil
    end

    for layer = 1, #occlusionTex do
        if occlusionTex[layer] then
            gl.DeleteTexture(occlusionTex[layer])
        end
    end
    occlusionTex = {}
end
