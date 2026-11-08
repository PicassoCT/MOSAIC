function gadget:GetInfo()
    return {
        name = "Parade holographic scenery",
        desc = "Pixel ornaments and masked spirit audiences accompanying parade floats",
        author = "MOSAIC contributors", license = "GPL3", layer = 3, enabled = true,
    }
end
if gadgetHandler:IsSyncedCode() then return false end

local catalog = VFS.Include("scripts/lib_truck_parade_payloads.lua")
local decorations = VFS.Include("luarules/configs/parade_hologram_decorations.lua")
local figures = VFS.Include("luarules/configs/parade_hologram_figures.lua")
local paradeModel = VFS.Include("scripts/lib_truck_parade_model.lua")
local sceneConfig = VFS.Include("luarules/configs/parade_hologram_scene.lua")
if sceneConfig.enabled == false then return false end
local sceneBehavior = VFS.Include("luarules/gadgets/include/parade_hologram_scene.lua")
local modelOK, sceneModels = pcall(VFS.Include, "luarules/configs/parade_hologram_models.lua")
if not modelOK or type(sceneModels) ~= "table" then sceneModels = {figures = {}, props = {}} end
local glyphs, themes = {}, {}
-- Keep the complete original ornaments and outlined spectators available for
-- distance/capacity LOD and machines or models without the native scene.
for _, source in ipairs({decorations, figures}) do
    for name, glyph in pairs(source.glyphs) do
        assert(not glyphs[name], "duplicate parade hologram glyph: " .. name)
        glyphs[name] = glyph
    end
    for key, placements in pairs(source.themes) do
        themes[key] = themes[key] or {}
        for _, placement in ipairs(placements) do
            themes[key][#themes[key] + 1] = placement
        end
    end
end
local payloads, glyphLists, glyphTimings = {}, {}, {}
local payloadDefID, shader, sizeUniform, opacityUniform
local sceneShader, sceneDisabled
local maxDistance, fadeStart, maxVisiblePayloads = 1500, 900, 12
local maxDistanceSquared = maxDistance * maxDistance

-- Expand pixels in eye space AFTER transforming their origin. gl.Billboard
-- alone would retain the truck's rotation and turn a glyph edge-on at corners.
-- Native unit/piece matrices retain attachment interpolation and bed offsets.
local vertexShader = [[
#version 120
uniform float pixelSize;
void main() {
    vec4 anchor = gl_ModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 pixel = vec4(gl_Vertex.xy * pixelSize, 0.0, 0.0);
    gl_Position = gl_ProjectionMatrix * (anchor + pixel);
    gl_FrontColor = gl_Color;
}
]]
local fragmentShader = [[
#version 120
uniform float opacity;
void main() {
    gl_FragColor = vec4(gl_Color.rgb, gl_Color.a * opacity);
}
]]

-- gl.UnitPiece draws raw original vertices without the unit or piece matrix.
-- The appended meshes use final world-unit coordinates. Intentionally do not
-- inherit the artist's FBX scene scaling, container rotation or bed offset.
local sceneVertexShader = [[
#version 120
varying vec2 atlasUV;
void main() {
    atlasUV = gl_MultiTexCoord0.xy;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_FrontColor = gl_Color;
}
]]
local sceneFragmentShader = [[
#version 120
uniform sampler2D atlas;
uniform sampler2D material;
varying vec2 atlasUV;
void main() {
    // Diffuse alpha is the engine's TEAM-COLOR mask (zero on this atlas).
    // The packed material's alpha supplies opacity, as in native unit shading.
    vec4 packed = texture2D(material, atlasUV);
    vec4 color = vec4(texture2D(atlas, atlasUV).rgb * (0.30 + 0.70 * packed.r),
        packed.a) * gl_Color;
    if (color.a < 0.005) discard;
    gl_FragColor = color;
}
]]

local function releaseResources()
    for _, frames in pairs(glyphLists) do
        for _, list in ipairs(frames) do gl.DeleteList(list) end
    end
    glyphLists = {}
    glyphTimings = {}
    if shader then gl.DeleteShader(shader); shader = nil end
    if sceneShader then gl.DeleteShader(sceneShader); sceneShader = nil end
end

local function disable(reason)
    Spring.Echo("Parade pixel holograms disabled: " .. tostring(reason))
    releaseResources()
    gadgetHandler:RemoveGadget(gadget)
end

local function drawPixels(glyph, frame)
    local height, width = #frame, #frame[1]
    gl.BeginEnd(GL.QUADS, function()
        -- A faint square halo surrounds each crisp pixel, preserving the grid.
        for pass = 1, 2 do
            local inset, strength = -0.06, 0.10
            if pass == 2 then inset, strength = 0.10, 0.88 end
            for row, line in ipairs(frame) do
                for column = 1, width do
                    local symbol = line:sub(column, column)
                    local color = glyph.palette[symbol]
                    if symbol ~= "." and color then
                        local x, y = column - 1 - width * 0.5, height - row
                        gl.Color(color[1], color[2], color[3], (color[4] or 1) * strength)
                        gl.Vertex(x + inset, y + inset, 0)
                        gl.Vertex(x + 1 - inset, y + inset, 0)
                        gl.Vertex(x + 1 - inset, y + 1 - inset, 0)
                        gl.Vertex(x + inset, y + 1 - inset, 0)
                    end
                end
            end
        end
    end)
end

local function rememberUnit(id, defID)
    if payloadDefID and defID == payloadDefID then
        payloads[id] = payloads[id] or {}
    end
end

local function cacheTiming(name, glyph)
    if not glyph.frameDurations then return true end
    if #glyph.frameDurations ~= #glyph.frames then return false end
    local ends, total = {}, 0
    for index, duration in ipairs(glyph.frameDurations) do
        if type(duration) ~= "number" or duration <= 0 or duration ~= duration
            or duration == math.huge then return false end
        total = total + duration
        ends[index] = total
    end
    if total == 0 or total == math.huge then return false end
    glyphTimings[name] = {ends = ends, total = total}
    return true
end

local function animationFrame(name, glyph, frames, clock)
    local timing = glyphTimings[name]
    if timing then
        local cycle = clock % timing.total
        for index, ending in ipairs(timing.ends) do
            if cycle < ending then return index end
        end
        return #frames
    end
    return math.floor(clock / (glyph.frameSeconds or 0.20)) % #frames + 1
end

function gadget:Initialize()
    local definition = UnitDefNames[catalog.unitName]
    if not definition then gadgetHandler:RemoveGadget(self); return end
    payloadDefID = definition.id
    if not gl.CreateShader or not gl.ActiveShader or not gl.CreateList then
        disable("required rendering support is unavailable")
        return
    end
    shader = gl.CreateShader({vertex = vertexShader, fragment = fragmentShader,
        uniform = {pixelSize = 0.5, opacity = 1}})
    if not shader or shader == 0 then
        disable(gl.GetShaderLog and gl.GetShaderLog() or "shader compilation failed")
        return
    end
    sizeUniform = gl.GetUniformLocation(shader, "pixelSize")
    opacityUniform = gl.GetUniformLocation(shader, "opacity")
    for name, glyph in pairs(glyphs) do
        if not cacheTiming(name, glyph) then
            disable("invalid frame durations for " .. name)
            return
        end
        local frames = {}
        glyphLists[name] = frames
        for index, frame in ipairs(glyph.frames) do
            local list = gl.CreateList(drawPixels, glyph, frame)
            if not list or list == 0 then disable("could not cache " .. name); return end
            frames[index] = list
        end
    end
    -- Seed once for widget/gadget reloads. Subsequent discovery is event-driven.
    for _, id in ipairs(Spring.GetAllUnits() or {}) do
        rememberUnit(id, Spring.GetUnitDefID(id))
    end
end

function gadget:UnitCreated(id, defID) rememberUnit(id, defID) end
function gadget:UnitFinished(id, defID) rememberUnit(id, defID) end
function gadget:UnitEnteredLos(id, teamID, allyTeamID, defID)
    rememberUnit(id, defID or Spring.GetUnitDefID(id))
end
function gadget:UnitDestroyed(id) payloads[id] = nil end

local function visiblePayloads()
    local cx, cy, cz = Spring.GetCameraPosition()
    local _, fullView = Spring.GetSpectatingState()
    local allyTeamID = Spring.GetMyAllyTeamID()
    local visible = {}
    for id, state in pairs(payloads) do
        if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then
            payloads[id] = nil
        else
            local parent = Spring.GetUnitTransporter(id)
            -- No orphaned symbols during delayed attachment or carrier death.
            if parent and Spring.ValidUnitID(parent) and not Spring.GetUnitIsDead(parent) then
                local los = fullView or Spring.GetUnitLosState(parent, allyTeamID)
                local index = Spring.GetUnitRulesParam(id, "city_parade_variant")
                local variant = index and catalog.variants[index]
                local theme = variant and themes[variant.hologramTheme or variant.key]
                local x, y, z = Spring.GetUnitPosition(parent)
                local noDraw = Spring.GetUnitNoDraw and Spring.GetUnitNoDraw(parent)
                local cloaked = Spring.GetUnitIsCloaked and Spring.GetUnitIsCloaked(parent)
                if theme and x and (fullView or (los and los.los)) and not noDraw and not cloaked then
                    local distanceSquared = (cx-x)^2 + (cy-y)^2 + (cz-z)^2
                    if distanceSquared < maxDistanceSquared
                        and Spring.IsSphereInView(x, y + 30, z, sceneConfig.viewRadius) then
                        if not state.index then
                            local getInfo = Spring.GetUnitPieceInfo and function(pieceID)
                                return Spring.GetUnitPieceInfo(id, pieceID)
                            end
                            state.index = paradeModel.inspect(Spring.GetUnitPieceMap(id) or {}, getInfo)
                            state.center = state.index.center
                            if state.center ~= nil and Spring.GetUnitPieceMatrix and gl.Scale then
                                state.spriteScale = paradeModel.inverseMatrixScale(
                                    {Spring.GetUnitPieceMatrix(id, state.center)})
                            end
                        end
                        if state.center ~= nil then
                            visible[#visible + 1] = {id = id, center = state.center,
                                theme = theme, distanceSquared = distanceSquared,
                                state = state, parent = parent, x = x, y = y, z = z}
                        end
                    end
                end
            else
                state.scene = nil
            end
        end
    end
    table.sort(visible, function(a, b)
        if a.distanceSquared == b.distanceSquared then return a.id < b.id end
        return a.distanceSquared < b.distanceSquared
    end)
    return visible
end

local function sceneTemplates(payload)
    local state = payload.state
    if state.sceneTemplates then return state.sceneTemplates end
    local templates = {}
    local function add(item, definition, isFigure)
        if not definition then return end
        if isFigure then
            local pieces = definition.pieces or {}
            local body, head, mask = state.index.find(pieces.body),
                state.index.find(pieces.head), state.index.find(pieces.mask)
            if body ~= nil and head ~= nil and mask ~= nil then
                templates[#templates + 1] = {item = item, body = body, head = head, mask = mask,
                    headPivot = definition.headPivot or {0, (definition.height or 7) * 0.8, 0}}
            end
        else
            local choices = definition.variants
            local choice = choices and choices[(payload.id + #templates) % #choices + 1] or definition
            local pieceID = state.index.find(choice.piece)
            local wings, complete = {}, true
            for _, wing in ipairs(choice.wings or {}) do
                local id = state.index.find(wing.piece)
                if id == nil then complete = false; break end
                wings[#wings + 1] = {piece = id, pivot = wing.pivot, axis = wing.axis, sign = wing.sign}
            end
            if pieceID ~= nil and complete then
                templates[#templates + 1] = {item = item, piece = pieceID, wings = wings}
            end
        end
    end
    for _, item in ipairs(sceneConfig.figures) do add(item, (sceneModels.figures or {})[item.model], true) end
    for _, item in ipairs(sceneConfig.props) do add(item, (sceneModels.props or {})[item.model], false) end
    -- A partial native cast must not replace the complete fallback. Require
    -- every configured figure part and prop before this payload owns a scene.
    if #templates ~= #sceneConfig.figures + #sceneConfig.props then templates = {} end
    state.sceneTemplates = templates
    return templates
end

local function worldStations(payload, seconds)
    if Spring.GetUnitRulesParam(payload.parent, "city_parade_retiring") == 1 then
        payload.state.scene = nil
        return {}
    end
    local dx, dz = 0, 1
    if Spring.GetUnitDirection then
        local x, _, z = Spring.GetUnitDirection(payload.parent)
        dx, dz = x or 0, z or 1
    end
    payload.state.scene = payload.state.scene or {}
    return sceneBehavior.updateStations(payload.state.scene, payload.parent,
        payload.x, payload.z, dx, dz, seconds, sceneConfig)
end

local function sceneQueue(visible, seconds)
    local queue, ownership = {}, {}
    if sceneDisabled or not gl.UnitPiece or not gl.Texture or not gl.Rotate
        or not Spring.GetGroundHeight then return queue, ownership end
    local cx, cy, cz = Spring.GetCameraPosition()
    for index = 1, math.min(#visible, sceneConfig.maxVisiblePayloads) do
        local payload = visible[index]
        local distance = math.sqrt(payload.distanceSquared)
        if Spring.GetUnitRulesParam(payload.parent, "city_parade_retiring") == 1 then
            -- A dismissed procession can keep its decorated cargo on the trip
            -- home, but it must not keep creating fresh curb audiences.
            payload.state.scene = nil
        elseif distance < sceneConfig.maxDistance then
            local templates = sceneTemplates(payload)
            if #templates > 0 then
                local stations = worldStations(payload, seconds)
                local distanceFade = math.min(1, (sceneConfig.maxDistance - distance)
                    / (sceneConfig.maxDistance - sceneConfig.fadeStart))
                -- Ownership does not depend on the station's entry fade: a
                -- close scene materializes without flashing old floating
                -- candles or duplicate silhouettes underneath it.
                ownership[payload.id] = distanceFade
                for _, station in ipairs(stations) do
                    local fade = distanceFade * sceneBehavior.stationOpacity(station, seconds, sceneConfig)
                    if fade > 0.002 then
                        for number, template in ipairs(templates) do
                            local item = template.item
                            local pose = sceneBehavior.worldPose(station, item, seconds, payload.id,
                                0, sceneConfig)
                            local worldX, worldZ = pose.x, pose.z
                            local onMap = (not Game.mapSizeX or (worldX >= 0 and worldX <= Game.mapSizeX))
                                and (not Game.mapSizeZ or (worldZ >= 0 and worldZ <= Game.mapSizeZ))
                            if onMap and pose.visible ~= false and pose.opacity > 0.002 then
                                local ground = station.grounds[number]
                                if not ground or seconds >= ground.expires
                                    or ground.x ~= worldX or ground.z ~= worldZ then
                                    ground = {height = Spring.GetGroundHeight(worldX, worldZ),
                                        x = worldX, z = worldZ,
                                        expires = seconds + sceneConfig.groundRefreshSeconds}
                                    station.grounds[number] = ground
                                end
                                pose.y = pose.y + ground.height
                                queue[#queue + 1] = {id = payload.id, parent = payload.parent, template = template, pose = pose,
                                    opacity = fade * pose.opacity,
                                    distanceSquared = (pose.x-cx)^2 + (pose.y-cy)^2 + (pose.z-cz)^2}
                            end
                        end
                    end
                end
            end
        end
    end
    -- Standard alpha preserves dark clothing, mask eye holes and the darker
    -- dead. Draw world objects from back to front instead of adding black away.
    table.sort(queue, function(a, b) return a.distanceSquared > b.distanceSquared end)
    return queue, ownership
end

local drawSceneGeometry = VFS.Include("scripts/lib_parade_scene_draw.lua")
local function publishRadiance(queue)
    if Script and Script.LuaUI and Script.LuaUI('ReceiveParadeRadianceScene') then
        Script.LuaUI.ReceiveParadeRadianceScene(queue or {}, payloadDefID)
    end
end
local function drawSceneObjects(queue)
    gl.Texture(0, string.format("%%%d:0", payloadDefID))
    gl.Texture(1, string.format("%%%d:1", payloadDefID))
    drawSceneGeometry(gl, queue)
end

local function drawScene(visible, seconds)
    local queue, ownership = sceneQueue(visible, seconds)
    if not next(ownership) then return end
    if not sceneShader then
        sceneShader = gl.CreateShader({vertex = sceneVertexShader, fragment = sceneFragmentShader,
            uniformInt = {atlas = 0, material = 1}})
        if not sceneShader or sceneShader == 0 then
            sceneShader, sceneDisabled = nil, true
            Spring.Echo("Parade mesh spectators unavailable; keeping pixel holograms")
            return
        end
    end
    if #queue == 0 then return ownership end
    gl.PushAttrib()
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(false)
    gl.Culling(GL.BACK)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    local ok, reason = pcall(gl.ActiveShader, sceneShader, drawSceneObjects, queue)
    gl.Texture(0, false)
    gl.Texture(1, false)
    gl.PopAttrib()
    if not ok then
        Spring.Echo("Parade mesh spectators disabled: " .. tostring(reason) .. "; keeping pixel holograms")
        gl.DeleteShader(sceneShader)
        sceneShader, sceneDisabled = nil, true
        return
    end
    publishRadiance(queue)
    return ownership
end

local function drawFallbackLanterns(payload, decoration, seconds, fade)
    local glyph, frames = glyphs.lantern, glyphLists.lantern
    if not glyph or not frames then return end
    for _, station in ipairs(worldStations(payload, seconds)) do
        local stationFade = sceneBehavior.stationOpacity(station, seconds, sceneConfig)
        for _, item in ipairs(sceneConfig.props) do
            if item.motion == "lantern" then
                local pose = sceneBehavior.worldPose(station, item, seconds, payload.id, 0, sceneConfig)
                local onMap = (not Game.mapSizeX or (pose.x >= 0 and pose.x <= Game.mapSizeX))
                    and (not Game.mapSizeZ or (pose.z >= 0 and pose.z <= Game.mapSizeZ))
                local opacity = fade * stationFade * pose.opacity
                if onMap and pose.visible ~= false and opacity > 0.002 then
                    local ground = Spring.GetGroundHeight and Spring.GetGroundHeight(pose.x, pose.z) or 0
                    local clock = seconds + item.lanternSlot * 0.37 + payload.id * 0.173
                    local frame = animationFrame("lantern", glyph, frames, clock)
                    gl.Uniform(sizeUniform, decoration.pixelSize)
                    gl.Uniform(opacityUniform, opacity)
                    -- Billboard art is retained at distance, but its lifecycle,
                    -- world anchor and daemon release are the same as the mesh.
                    gl.PushPopMatrix(function()
                        gl.Translate(pose.x, ground + pose.y, pose.z)
                        gl.CallList(frames[frame])
                    end)
                end
            end
        end
    end
end

local function drawVisible(visible, seconds, ownership)
    for index = 1, math.min(#visible, maxVisiblePayloads) do
        local payload = visible[index]
        local fallbackWeight = 1 - (ownership and ownership[payload.id] or 0)
        if fallbackWeight > 0.002 then
            local distance = math.sqrt(payload.distanceSquared)
            local fade = fallbackWeight * math.min(1, (maxDistance - distance) / (maxDistance - fadeStart))
            local lantern
            gl.PushPopMatrix(function()
                gl.UnitMultMatrix(payload.id)
                gl.UnitPieceMultMatrix(payload.id, payload.center)
                -- The FBX re-export's root contains a .0254 import scale. Placement
                -- coordinates below are world-sized, like the camera-facing pixels;
                -- remove only that scale while retaining attachment and translation.
                local scale = payload.state.spriteScale
                if scale then gl.Scale(scale[1], scale[2], scale[3]) end
                for number, decoration in ipairs(payload.theme) do
                    local glyph = glyphs[decoration.glyph]
                    local frames = glyphLists[decoration.glyph]
                    if decoration.glyph == "lantern" then
                        lantern = lantern or decoration
                    elseif glyph and frames then
                        local phase = (decoration.phase or number * 0.37) + payload.id * 0.173
                        local clock = seconds + phase
                        local frame = animationFrame(decoration.glyph, glyph, frames, clock)
                        local shimmer = 0.91 + 0.06 * math.sin(clock * 4.1)
                        gl.Uniform(sizeUniform, decoration.pixelSize)
                        gl.Uniform(opacityUniform, fade * shimmer * (decoration.opacity or 1))
                        gl.PushPopMatrix(function()
                            local bob = (decoration.bobAmplitude or 0.24)
                                * math.sin(clock * (decoration.bobSpeed or 1.7))
                            local sway = (decoration.swayAmplitude or 0) * math.sin(clock * 0.83)
                            gl.Translate(decoration.x + sway, decoration.y + bob, decoration.z)
                            gl.CallList(frames[frame])
                        end)
                    end
                end
            end)
            if lantern then drawFallbackLanterns(payload, lantern, seconds, fade) end
        end
    end
end

function gadget:DrawWorld()
    publishRadiance({})
    if not shader or not next(payloads) then return end
    local visible = visiblePayloads()
    if #visible == 0 then return end
    local seconds = Spring.GetGameSeconds()
    if Spring.GetFrameTimeOffset then
        seconds = seconds + Spring.GetFrameTimeOffset() / (Game.gameSpeed or 30)
    end
    -- Native succeeds before suppressing any fallback, so shader/mesh failures
    -- restore the original show in this same frame. Between 750 and 1150 units
    -- the two complete scenes crossfade; closer native scenes are exclusive.
    local ownership = drawScene(visible, seconds)
    gl.PushAttrib()
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(false)
    gl.Culling(false)
    gl.Blending(GL.SRC_ALPHA, GL.ONE)
    -- ActiveShader and PushPopMatrix preserve the caller's program/matrices.
    -- The attribute stack is also restored if a rendering callback fails.
    local ok, reason = pcall(gl.ActiveShader, shader, drawVisible, visible, seconds, ownership)
    gl.PopAttrib()
    if not ok then disable(reason); return end
end

function gadget:Shutdown()
    publishRadiance({})
    releaseResources()
    payloads = {}
end
