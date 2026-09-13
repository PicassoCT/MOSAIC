function widget:GetInfo()
    return {
        name = "NeonLight Radiance Cascade",
        desc = "Propagates neon radiance through compact building occlusion",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = -9,
        enabled = true,
        hidden = false,
    }
end

-- Height-band radiance propagation with the original direct-light diagnostics.
local ATLAS_SIZE = 1024
local ATLAS_REFRESH_SECONDS = 0.20
local DAYLENGTH = 28800
local MORNING_OFFSET = DAYLENGTH * 0.5
local DEBUG_VIEW = true
local OCCLUSION_ATLAS_SIZE = 512
local OCCLUSION_LAYER_COUNT = 16
local OCCLUSION_WORLD_HEIGHT = 2048
local DIRECT_LIGHT_SIZE = 512
local DIRECT_LIGHT_RANGE = 1800
local DIRECT_LIGHT_STEPS = 48

local neonUnitTables = {}
local neonLightPercent = 0.0
local neonUnitCount = 0
local neonPieceCount = 0
local topDownTex
local occlusionTex = {}
local occlusionBuildings = {}
local pendingBuildingColumns = {}
local occlusionDirty = true
local occlusionBuildingCount = 0
local directLightTex
local unoccludedTex, firstHitTex
local debugModeLoc, clearanceLoc
local lockedUnit, lockedPiece
local emitterU, emitterV, emitterY
local diagnosticClearance = 0
local debugVoxelUnit
local debugVoxelSummary = ""
local directLightShader
local directEmitterUVLoc
local directEmitterHeightLoc
local directMapSizeLoc
local directRangeLoc
local directLightReady = false
local refreshAccumulator = ATLAS_REFRESH_SECONDS
local vsx, vsy = gl.GetViewSizes()
local propagation
local propagationView = true
local propagationLayer = 1

-- Flat x/z/base/mask values: four numbers per occupied column.
local function receiveBuildingShadowBegin(unitID, unitDefID, cellSize, levelHeight)
    pendingBuildingColumns[unitID] = {
        unitDefID = unitDefID, cellSize = cellSize, levelHeight = levelHeight,
        columns = {},
    }
end

local function receiveBuildingShadowColumn(unitID, x, z, base, mask)
    local building = pendingBuildingColumns[unitID]
    if not building then return end
    local c = building.columns
    local n = #c
    c[n + 1], c[n + 2], c[n + 3], c[n + 4] = x, z, base, mask
end

local function receiveBuildingShadowEnd(unitID)
    local building = pendingBuildingColumns[unitID]
    pendingBuildingColumns[unitID] = nil
    if not building then return end
    occlusionBuildings[unitID] = nil
    occlusionDirty = true
    if #building.columns == 0 or not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then return end
    local ux, uy, uz = Spring.GetUnitBasePosition(unitID)
    local front, up, right = Spring.GetUnitVectors(unitID)
    if not ux or not front or not up or not right then return end
    building.ux, building.uy, building.uz = ux, uy, uz
    building.front, building.up, building.right = front, up, right
    building.columnCount = #building.columns / 4
    occlusionBuildings[unitID] = building
end

local function receiveBuildingShadowRemove(unitID)
    pendingBuildingColumns[unitID] = nil
    occlusionBuildings[unitID] = nil
    if debugVoxelUnit == unitID then
        debugVoxelUnit = nil
        debugVoxelSummary = ""
    end
    occlusionDirty = true
end

-- Collapse consecutive occupied floors to prisms without allocating geometry.
local function forEachColumnRun(building, emit, bottom, top)
    local c, half, height = building.columns, building.cellSize * 0.5, building.levelHeight
    for i = 1, #c, 4 do
        local x, z, base, mask = c[i], c[i + 1], c[i + 2], c[i + 3]
        local level = 0
        while mask > 0 do
            if mask % 2 == 0 then
                mask, level = math.floor(mask / 2), level + 1
            else
                local first = level
                repeat
                    mask, level = math.floor(mask / 2), level + 1
                until mask % 2 == 0
                emit(building, x - half, base + first * height, z - half,
                    x + half, base + level * height, z + half, bottom, top)
            end
        end
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

local function emitBoxFaces(vertex, building, x0, y0, z0, x1, y1, z1)

    vertex(building, x0, y0, z0); vertex(building, x1, y0, z0); vertex(building, x1, y1, z0); vertex(building, x0, y1, z0)
    vertex(building, x1, y0, z1); vertex(building, x0, y0, z1); vertex(building, x0, y1, z1); vertex(building, x1, y1, z1)
    vertex(building, x0, y0, z1); vertex(building, x0, y0, z0); vertex(building, x0, y1, z0); vertex(building, x0, y1, z1)
    vertex(building, x1, y0, z0); vertex(building, x1, y0, z1); vertex(building, x1, y1, z1); vertex(building, x1, y1, z0)
    vertex(building, x0, y1, z0); vertex(building, x1, y1, z0); vertex(building, x1, y1, z1); vertex(building, x0, y1, z1)
    vertex(building, x0, y0, z1); vertex(building, x1, y0, z1); vertex(building, x1, y0, z0); vertex(building, x0, y0, z0)
end

local function emitBoxLines(vertex, building, x0, y0, z0, x1, y1, z1)

    vertex(building, x0, y0, z0); vertex(building, x1, y0, z0)
    vertex(building, x1, y0, z0); vertex(building, x1, y0, z1)
    vertex(building, x1, y0, z1); vertex(building, x0, y0, z1)
    vertex(building, x0, y0, z1); vertex(building, x0, y0, z0)
    vertex(building, x0, y1, z0); vertex(building, x1, y1, z0)
    vertex(building, x1, y1, z0); vertex(building, x1, y1, z1)
    vertex(building, x1, y1, z1); vertex(building, x0, y1, z1)
    vertex(building, x0, y1, z1); vertex(building, x0, y1, z0)
    vertex(building, x0, y0, z0); vertex(building, x0, y1, z0)
    vertex(building, x1, y0, z0); vertex(building, x1, y1, z0)
    vertex(building, x1, y0, z1); vertex(building, x1, y1, z1)
    vertex(building, x0, y0, z1); vertex(building, x0, y1, z1)
end

local function projectedVertex(building, x, y, z)
    local r, u, f = building.right, building.up, building.front
    gl.Vertex(building.ux - r[1] * x + u[1] * y + f[1] * z,
        building.uz - r[3] * x + u[3] * y + f[3] * z, 0)
end

local function emitOcclusionRun(building, x0, y0, z0, x1, y1, z1, bottom, top)
    local r, u, f = building.right, building.up, building.front
    local midY = building.uy - r[2] * (x0 + x1) * 0.5 +
        u[2] * (y0 + y1) * 0.5 + f[2] * (z0 + z1) * 0.5
    local extentY = (math.abs(r[2]) * (x1 - x0) + math.abs(u[2]) * (y1 - y0) +
        math.abs(f[2]) * (z1 - z0)) * 0.5
    if midY + extentY < bottom or midY - extentY > top then return end
    -- Full prism projection is exact for upright houses and conservative for tilt.
    emitBoxFaces(projectedVertex, building, x0, y0, z0, x1, y1, z1)
end

local function emitOcclusionColumns(bottom, top)
    for _, building in pairs(occlusionBuildings) do
        forEachColumnRun(building, emitOcclusionRun, bottom, top)
    end
end

local function drawOcclusionLayer(layerIndex)
    local layerHeight = OCCLUSION_WORLD_HEIGHT / OCCLUSION_LAYER_COUNT
    local layerBottom = layerIndex * layerHeight
    local layerTop = layerBottom + layerHeight

    gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0)
    gl.DepthTest(false)
    gl.DepthMask(false)
    gl.Blending(false)
    gl.Culling(false)
    gl.Texture(false)
    gl.Color(1, 1, 1, 1)

    gl.MatrixMode(GL.PROJECTION)
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.Ortho(0, Game.mapSizeX, 0, Game.mapSizeZ, -1, 1)

    gl.MatrixMode(GL.MODELVIEW)
    gl.PushMatrix()
    gl.LoadIdentity()

    -- One BeginEnd callback per layer, not one allocation per voxel.
    gl.BeginEnd(GL.QUADS, emitOcclusionColumns, layerBottom, layerTop)

    gl.PopMatrix()
    gl.MatrixMode(GL.PROJECTION)
    gl.PopMatrix()
    gl.MatrixMode(GL.MODELVIEW)
    gl.Color(1, 1, 1, 1)
end

local function rebuildOcclusionAtlas()
    occlusionBuildingCount = 0
    for _ in pairs(occlusionBuildings) do
        occlusionBuildingCount = occlusionBuildingCount + 1
    end

    for layerIndex = 0, OCCLUSION_LAYER_COUNT - 1 do
        gl.RenderToTexture(occlusionTex[layerIndex + 1], function()
            drawOcclusionLayer(layerIndex)
        end)
    end

    occlusionDirty = false
end

local DIRECT_LIGHT_SHADER_PATH =
    "luaui/widgets_mosaic/shaders/radiancecascade/direct_light_occlusion.frag"

local function loadDirectLightFragmentShader()
    local source = VFS.LoadFile(DIRECT_LIGHT_SHADER_PATH)
    if not source then
        return nil
    end

    local defines = string.format(
        "#define DIRECT_LIGHT_STEPS %d\n" ..
        "#define OCCLUSION_LAYER_COUNT %.1f\n" ..
        "#define OCCLUSION_WORLD_HEIGHT %.1f\n",
        DIRECT_LIGHT_STEPS,
        OCCLUSION_LAYER_COUNT,
        OCCLUSION_WORLD_HEIGHT
    )
    return source:gsub("#version 150 compatibility", "#version 150 compatibility\n" .. defines, 1)
end

local function getDebugEmitter()
    local function position(unitID, pieceID)
        if unitID and Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
            local x, y, z = Spring.GetUnitPiecePosDir(unitID, pieceID)
            if x then return x / Game.mapSizeX, z / Game.mapSizeZ, y end
        end
    end

    if lockedUnit then
        for _, pieceID in ipairs(neonUnitTables[lockedUnit] or {}) do
            if pieceID == lockedPiece then
                local u, v, y = position(lockedUnit, lockedPiece)
                if u then return u, v, y end
            end
        end
    end

    lockedUnit, lockedPiece = nil, nil
    local ids = {}
    for id in pairs(neonUnitTables) do ids[#ids + 1] = id end
    table.sort(ids)

    for _, id in ipairs(ids) do
        for _, pieceID in ipairs(neonUnitTables[id]) do
            local u, v, y = position(id, pieceID)
            if u then
                lockedUnit, lockedPiece = id, pieceID
                Spring.Echo("Radiance debug: locked unit " .. id .. " piece " .. pieceID)
                return u, v, y
            end
        end
    end
end

function widget:TextCommand(command)
    if command == "radiancedebug propagation" then
        propagationView = true
        return true
    end
    if command == "radiancedebug direct" then
        propagationView = false
        return true
    end
    local height = command:match("^radiancedebug height (%d+)$")
    if height then
        propagationLayer = math.max(1, math.min(OCCLUSION_LAYER_COUNT,
            math.floor(tonumber(height) * OCCLUSION_LAYER_COUNT / OCCLUSION_WORLD_HEIGHT) + 1))
        refreshAccumulator = ATLAS_REFRESH_SECONDS
        if propagation then propagation.ready = false end
        return true
    end
    if command == "radiancedebug voxels off" or command == "radiancedebug volumes off" then
        debugVoxelUnit = nil
        debugVoxelSummary = ""
        return true
    end

    local requested = command:match("^radiancedebug voxels (%d+)$")
        or command:match("^radiancedebug volumes (%d+)$")
    if command == "radiancedebug voxels" or command == "radiancedebug volumes" or requested then
        local unitID = tonumber(requested) or (Spring.GetSelectedUnits() or {})[1]
        local building = unitID and occlusionBuildings[unitID]
        if not building then
            Spring.Echo("Radiance voxels: select a completed shadow house, or use /radiancedebug voxels UNITID")
            return true
        end
        debugVoxelUnit = unitID
        Spring.Echo(
            "Radiance voxels: locked house " .. unitID ..
            "; occupied column runs are drawn directly over the rendered building; /radiancedebug voxels off to hide"
        )
        return true
    end

    if command == "radiancedebug reset" then
        lockedUnit, lockedPiece = nil, nil
        return true
    end

    local clearance = command:match("^radiancedebug clearance (%d+)$")
    if clearance then
        diagnosticClearance = math.min(512, tonumber(clearance))
        return true
    end
end

local function drawDirectLight(mode)
    emitterU, emitterV, emitterY = getDebugEmitter()
    if not emitterU then
        gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 1)
        directLightReady = false
        return
    end

    gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 1)
    gl.Blending(false)
    gl.DepthTest(false)
    gl.Texture(false)

    for layer = 1, OCCLUSION_LAYER_COUNT do
        gl.Texture(layer - 1, occlusionTex[layer])
    end

    gl.UseShader(directLightShader)
    gl.Uniform(directEmitterUVLoc, emitterU, emitterV)
    gl.Uniform(directEmitterHeightLoc, emitterY)
    gl.Uniform(directMapSizeLoc, Game.mapSizeX, Game.mapSizeZ)
    gl.Uniform(directRangeLoc, DIRECT_LIGHT_RANGE)
    gl.UniformInt(debugModeLoc, mode or 0)
    gl.Uniform(clearanceLoc, diagnosticClearance)

    gl.MatrixMode(GL.PROJECTION)
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.MatrixMode(GL.MODELVIEW)
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
    gl.PopMatrix()
    gl.MatrixMode(GL.PROJECTION)
    gl.PopMatrix()
    gl.MatrixMode(GL.MODELVIEW)

    gl.UseShader(0)
    for layer = 1, OCCLUSION_LAYER_COUNT do
        gl.Texture(layer - 1, false)
    end
    directLightReady = true
end

function widget:Initialize()
    if not gl.RenderToTexture or not gl.CreateTexture or not gl.UnitPiece
        or not gl.BeginEnd or not gl.UnitMultMatrix
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

    if gl.CreateShader then
        directLightTex = gl.CreateTexture(DIRECT_LIGHT_SIZE, DIRECT_LIGHT_SIZE, {
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        })

        local options = {
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        }
        unoccludedTex = gl.CreateTexture(DIRECT_LIGHT_SIZE, DIRECT_LIGHT_SIZE, options)
        firstHitTex = gl.CreateTexture(DIRECT_LIGHT_SIZE, DIRECT_LIGHT_SIZE, options)

        directLightShader = gl.CreateShader({
            fragment = loadDirectLightFragmentShader(),
            uniformInt = {
                occ0 = 0, occ1 = 1, occ2 = 2, occ3 = 3,
                occ4 = 4, occ5 = 5, occ6 = 6, occ7 = 7,
                occ8 = 8, occ9 = 9, occ10 = 10, occ11 = 11,
                occ12 = 12, occ13 = 13, occ14 = 14, occ15 = 15,
            },
        })

        if directLightTex and directLightShader and unoccludedTex and firstHitTex then
            directEmitterUVLoc = gl.GetUniformLocation(directLightShader, "emitterUV")
            directEmitterHeightLoc = gl.GetUniformLocation(directLightShader, "emitterHeight")
            directMapSizeLoc = gl.GetUniformLocation(directLightShader, "mapSize")
            directRangeLoc = gl.GetUniformLocation(directLightShader, "lightRange")
            debugModeLoc = gl.GetUniformLocation(directLightShader, "debugMode")
            clearanceLoc = gl.GetUniformLocation(directLightShader, "emitterClearance")
        else
            Spring.Echo(
                "NeonLight Radiance Cascade: direct-light debug pass disabled: " ..
                (gl.GetShaderLog() or "shader/FBO creation failed")
            )
            if directLightShader then
                gl.DeleteShader(directLightShader)
                directLightShader = nil
            end
            if directLightTex then
                gl.DeleteTexture(directLightTex)
                directLightTex = nil
            end
        end
    end

    if gl.CreateShader then
        local ok, factory = pcall(VFS.Include, "luaui/widgets_mosaic/include/radiance_propagation.lua")
        if ok and type(factory) == "function" then
            local reason
            propagation, reason = factory(ATLAS_SIZE)
            if not propagation then Spring.Echo("Neon propagation disabled: " .. tostring(reason)) end
        else
            Spring.Echo("Neon propagation module could not load: " .. tostring(factory))
        end
    end
    if propagation then
        WG.NeonRadiance = propagation
    else
        propagationView = false
    end

    widgetHandler:RegisterGlobal("RecieveAllNeonUnitsPieces", recieveNeonHoloLightPiecesByUnit)
    widgetHandler:RegisterGlobal("ReceiveBuildingShadowColumnsBegin", receiveBuildingShadowBegin)
    widgetHandler:RegisterGlobal("ReceiveBuildingShadowColumn", receiveBuildingShadowColumn)
    widgetHandler:RegisterGlobal("ReceiveBuildingShadowColumnsEnd", receiveBuildingShadowEnd)
    widgetHandler:RegisterGlobal("ReceiveBuildingShadowColumnsRemove", receiveBuildingShadowRemove)

    Spring.Echo(
        "NeonLight Radiance Cascade: compact building-column occlusion enabled (" ..
        OCCLUSION_LAYER_COUNT .. " layers)"
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
    -- Capture unit-intensity emission; day/night intensity is applied once at resolve.
    gl.Color(1, 1, 1, 1)
    if propagation then
        local bandHeight = OCCLUSION_WORLD_HEIGHT / OCCLUSION_LAYER_COUNT
        gl.UseShader(propagation.emissionShader)
        gl.Uniform(propagation.heightLoc, (propagationLayer-1)*bandHeight, propagationLayer*bandHeight)
    end

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

    gl.UseShader(0)
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

    if propagation then
        local bandHeight = OCCLUSION_WORLD_HEIGHT / OCCLUSION_LAYER_COUNT
        propagation:Draw(topDownTex, occlusionTex[propagationLayer], neonLightPercent,
            (propagationLayer-1)*bandHeight, propagationLayer*bandHeight)
    end

    if not propagationView and directLightShader and directLightTex then
        gl.RenderToTexture(directLightTex, function() drawDirectLight(0) end)
        gl.RenderToTexture(unoccludedTex, function() drawDirectLight(1) end)
        gl.RenderToTexture(firstHitTex, function() drawDirectLight(2) end)
    end
end

local function modelVertex(_, x, y, z)
    gl.Vertex(x, y, z)
end

local function emitDebugFaces(building, x0, y0, z0, x1, y1, z1)
    emitBoxFaces(modelVertex, building, x0, y0, z0, x1, y1, z1)
end

local function emitDebugLines(building, x0, y0, z0, x1, y1, z1)
    emitBoxLines(modelVertex, building, x0, y0, z0, x1, y1, z1)
end

function widget:DrawWorld()
    if not debugVoxelUnit then return end

    local building = occlusionBuildings[debugVoxelUnit]
    if not building or not Spring.ValidUnitID(debugVoxelUnit) or Spring.GetUnitIsDead(debugVoxelUnit) then
        debugVoxelUnit = nil
        debugVoxelSummary = ""
        return
    end

    gl.UseShader(0)
    gl.Texture(false)
    gl.DepthTest(false)
    gl.DepthMask(false)
    gl.Culling(false)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

    gl.PushMatrix()
    gl.UnitMultMatrix(debugVoxelUnit)

    gl.Color(0.1, 0.9, 1.0, 0.10)
    gl.BeginEnd(GL.QUADS, forEachColumnRun, building, emitDebugFaces)

    gl.LineWidth(1.25)
    gl.Color(0.1, 0.95, 1.0, 0.80)
    gl.BeginEnd(GL.LINES, forEachColumnRun, building, emitDebugLines)

    gl.PopMatrix()

    debugVoxelSummary = string.format(
        "Shadow house %d | columns %d | cell %g, floor %g elmos",
        debugVoxelUnit, building.columnCount, building.cellSize, building.levelHeight
    )

    gl.LineWidth(1)
    gl.Color(1, 1, 1, 1)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    gl.DepthTest(true)
end

function widget:DrawScreen()
    if not DEBUG_VIEW or not topDownTex then return end

    local size = math.floor(math.min(vsy * 0.28, (vsx - 80) / 4))
    local layer = math.max(1, math.min(OCCLUSION_LAYER_COUNT,
        math.floor((emitterY or 0) * OCCLUSION_LAYER_COUNT / OCCLUSION_WORLD_HEIGHT) + 1))
    local textures = {
        unoccludedTex or topDownTex,
        occlusionTex[layer],
        directLightTex or topDownTex,
        firstHitTex or topDownTex,
    }
    local titles = {
        "No occlusion (unit intensity)",
        "Column occupancy at emitter layer " .. layer,
        "Occluded (clearance " .. diagnosticClearance .. ")",
        "First hit: red=near receiver, blue=near emitter",
    }

    if propagationView and propagation and propagation.ready then
        textures = {topDownTex, occlusionTex[propagationLayer], propagation.unitTexture, propagation.texture}
        titles = {"Emission (unit intensity)", "Occupancy band " .. propagationLayer,
            "Propagated radiance (unit intensity)", "Radiance with day/night intensity"}
    end

    gl.UseShader(0)
    gl.Blending(false)
    for i = 1, 4 do
        local x, y = 16 + (i - 1) * (size + 16), 16
        gl.Color(1, 1, 1, 1)
        gl.Texture(textures[i])
        gl.TexRect(x, y, x + size, y + size, 0, 1, 1, 0)
        gl.Texture(false)
        if not propagationView and emitterU then
            local px, py = x + emitterU * size, y + (1 - emitterV) * size
            gl.Color(0, 1, 0, 1)
            gl.Rect(px - 4, py - 1, px + 4, py + 1)
            gl.Rect(px - 1, py - 4, px + 1, py + 4)
        end
        gl.Color(1, 1, 1, 1)
        gl.Text(titles[i], x, y + size + 6, 11, "o")
    end

    if propagationView and propagation then
        gl.Text(string.format("Radiance propagation | height %.0f–%.0f | buildings %d | emission %.2f | range %.0f elmos",
            propagation.heightMin or 0, propagation.heightMax or 128, occlusionBuildingCount,
            neonLightPercent, (propagation.baseInterval or 0)*85),16,size+44,13,"o")
    else
        gl.Text(string.format(
            "Radiance diagnostics | unit %s piece %s | height %.1f | column buildings %d | real emission %.2f",
            tostring(lockedUnit), tostring(lockedPiece), emitterY or 0, occlusionBuildingCount, neonLightPercent
        ), 16, size + 44, 13, "o")
    end

    if debugVoxelUnit then
        gl.Text(debugVoxelSummary, 16, size + 64, 13, "o")
    end

    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end

function widget:Shutdown()
    if propagation then
        if WG.NeonRadiance == propagation then WG.NeonRadiance = nil end
        propagation:Shutdown()
        propagation = nil
    end
    widgetHandler:DeregisterGlobal("RecieveAllNeonUnitsPieces")
    widgetHandler:DeregisterGlobal("ReceiveBuildingShadowColumnsBegin")
    widgetHandler:DeregisterGlobal("ReceiveBuildingShadowColumn")
    widgetHandler:DeregisterGlobal("ReceiveBuildingShadowColumnsEnd")
    widgetHandler:DeregisterGlobal("ReceiveBuildingShadowColumnsRemove")

    if unoccludedTex then gl.DeleteTexture(unoccludedTex) end
    if firstHitTex then gl.DeleteTexture(firstHitTex) end

    if topDownTex then
        gl.DeleteTexture(topDownTex)
        topDownTex = nil
    end

    if directLightShader then
        gl.DeleteShader(directLightShader)
        directLightShader = nil
    end
    if directLightTex then
        gl.DeleteTexture(directLightTex)
        directLightTex = nil
    end

    for layer = 1, #occlusionTex do
        if occlusionTex[layer] then
            gl.DeleteTexture(occlusionTex[layer])
        end
    end
    occlusionTex = {}
    occlusionBuildings = {}
    pendingBuildingColumns = {}
end


