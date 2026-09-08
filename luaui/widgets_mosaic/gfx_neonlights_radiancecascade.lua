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
local occlusionDirty = true
local occlusionBuildingCount = 0
local directLightTex
local unoccludedTex, firstHitTex
local debugModeLoc, clearanceLoc
local lockedUnit, lockedPiece
local emitterU, emitterV, emitterY
local diagnosticClearance = 0
local directLightShader
local directEmitterUVLoc
local directEmitterHeightLoc
local directMapSizeLoc
local directRangeLoc
local directLightReady = false
local refreshAccumulator = ATLAS_REFRESH_SECONDS
local vsx, vsy = gl.GetViewSizes()

local function receiveBuildingShadowVolumes(buildings)
    occlusionBuildings = buildings or {}
    occlusionDirty = true
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

local function drawOcclusionQuad(sizeX, sizeZ)
    local halfX = sizeX * 0.5
    local halfZ = sizeZ * 0.5

    gl.BeginEnd(GL.QUADS, function()
        gl.Vertex(-halfX, -halfZ, 0)
        gl.Vertex( halfX, -halfZ, 0)
        gl.Vertex( halfX,  halfZ, 0)
        gl.Vertex(-halfX,  halfZ, 0)
    end)
end

local function drawOcclusionEllipse(sizeX, sizeZ)
    local segments = 20
    gl.BeginEnd(GL.TRIANGLE_FAN, function()
        gl.Vertex(0, 0, 0)
        for i = 0, segments do
            local angle = i * math.pi * 2 / segments
            gl.Vertex(
                math.cos(angle) * sizeX * 0.5,
                math.sin(angle) * sizeZ * 0.5,
                0
            )
        end
    end)
end

local function drawOcclusionLayer(layerIndex)
    local worldY = (layerIndex + 0.5) * OCCLUSION_WORLD_HEIGHT / OCCLUSION_LAYER_COUNT

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

    for _, volumes in pairs(occlusionBuildings) do
        for i = 1, #volumes do
            local volume = volumes[i]
            local halfY = volume.sy * 0.5
            local relativeY = (worldY - volume.y) / halfY

            if relativeY >= -1 and relativeY <= 1 then
                local sizeX = volume.sx
                local sizeZ = volume.sz
                local rounded = volume.volumeType ~= 2

                -- Ellipsoid/sphere sections shrink towards their top and bottom.
                if volume.volumeType == 0 or volume.volumeType == 3 then
                    local sectionScale = math.sqrt(math.max(0, 1 - relativeY * relativeY))
                    sizeX = sizeX * sectionScale
                    sizeZ = sizeZ * sectionScale
                end

                gl.PushMatrix()
                gl.Translate(volume.x, volume.z, 0)
                gl.Rotate(-(volume.heading or 0) * 360 / 65536, 0, 0, 1)
                if rounded then
                    drawOcclusionEllipse(sizeX, sizeZ)
                else
                    drawOcclusionQuad(sizeX, sizeZ)
                end
                gl.PopMatrix()
            end
        end
    end

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
        or not gl.BeginEnd
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

        local options = {min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE, fbo = true}
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

    widgetHandler:RegisterGlobal(
        "RecieveAllNeonUnitsPieces",
        recieveNeonHoloLightPiecesByUnit
    )
    widgetHandler:RegisterGlobal(
        "ReceiveBuildingShadowVolumes",
        receiveBuildingShadowVolumes
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

    if directLightShader and directLightTex then
        gl.RenderToTexture(directLightTex, function() drawDirectLight(0) end)
        gl.RenderToTexture(unoccludedTex, function() drawDirectLight(1) end)
        gl.RenderToTexture(firstHitTex, function() drawDirectLight(2) end)
    end
end

function widget:DrawScreen()
    if not DEBUG_VIEW or not topDownTex then return end
    local size = math.floor(math.min(vsy * 0.28, (vsx - 80) / 4))
    local layer = math.max(1, math.min(OCCLUSION_LAYER_COUNT,
        math.floor((emitterY or 0) * OCCLUSION_LAYER_COUNT / OCCLUSION_WORLD_HEIGHT) + 1))
    local textures = {unoccludedTex or topDownTex, occlusionTex[layer],
        directLightTex or topDownTex, firstHitTex or topDownTex}
    local titles = {"No occlusion (unit intensity)", "Occupancy at emitter layer " .. layer,
        "Occluded (clearance " .. diagnosticClearance .. ")", "First hit: red=near receiver, blue=near emitter"}
    gl.UseShader(0)
    gl.Blending(false)
    for i = 1, 4 do
        local x, y = 16 + (i - 1) * (size + 16), 16
        gl.Color(1, 1, 1, 1)
        gl.Texture(textures[i])
        gl.TexRect(x, y, x + size, y + size, 0, 1, 1, 0)
        gl.Texture(false)
        if emitterU then
            local px, py = x + emitterU * size, y + (1 - emitterV) * size
            gl.Color(0, 1, 0, 1)
            gl.Rect(px - 4, py - 1, px + 4, py + 1)
            gl.Rect(px - 1, py - 4, px + 1, py + 4)
        end
        gl.Color(1, 1, 1, 1)
        gl.Text(titles[i], x, y + size + 6, 11, "o")
    end
    gl.Text(string.format("Radiance diagnostics | unit %s piece %s | height %.1f | buildings %d | real emission %.2f",
        tostring(lockedUnit), tostring(lockedPiece), emitterY or 0, occlusionBuildingCount, neonLightPercent),
        16, size + 44, 13, "o")
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end

function widget:Shutdown()
    if unoccludedTex then gl.DeleteTexture(unoccludedTex) end
    if firstHitTex then gl.DeleteTexture(firstHitTex) end
    widgetHandler:DeregisterGlobal("RecieveAllNeonUnitsPieces")
    widgetHandler:DeregisterGlobal("ReceiveBuildingShadowVolumes")

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
end
