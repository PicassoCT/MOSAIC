function gadget:GetInfo()
    return {
        name = "Parade pixel holograms",
        desc = "Animated pixel ornaments and outlined spirit audiences on parade floats",
        author = "MOSAIC contributors", license = "GPL3", layer = 3, enabled = true,
    }
end
if gadgetHandler:IsSyncedCode() then return false end

local catalog = VFS.Include("scripts/lib_truck_parade_payloads.lua")
local decorations = VFS.Include("luarules/configs/parade_hologram_decorations.lua")
local figures = VFS.Include("luarules/configs/parade_hologram_figures.lua")
local glyphs, themes = {}, {}
-- Keep the original six ornaments, positions, and animation phases intact.
-- Outlined spectators are an additional group, using the same cached renderer.
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

local function releaseResources()
    for _, frames in pairs(glyphLists) do
        for _, list in ipairs(frames) do gl.DeleteList(list) end
    end
    glyphLists = {}
    glyphTimings = {}
    if shader then gl.DeleteShader(shader); shader = nil end
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
                        and Spring.IsSphereInView(x, y + 30, z, 80) then
                        if not state.center then
                            state.center = (Spring.GetUnitPieceMap(id) or {}).center
                        end
                        if state.center then
                            visible[#visible + 1] = {id = id, center = state.center,
                                theme = theme, distanceSquared = distanceSquared}
                        end
                    end
                end
            end
        end
    end
    table.sort(visible, function(a, b)
        if a.distanceSquared == b.distanceSquared then return a.id < b.id end
        return a.distanceSquared < b.distanceSquared
    end)
    return visible
end

local function drawVisible(visible, seconds)
    for index = 1, math.min(#visible, maxVisiblePayloads) do
        local payload = visible[index]
        local distance = math.sqrt(payload.distanceSquared)
        local fade = math.min(1, (maxDistance - distance) / (maxDistance - fadeStart))
        gl.PushPopMatrix(function()
            gl.UnitMultMatrix(payload.id)
            gl.UnitPieceMultMatrix(payload.id, payload.center)
            for number, decoration in ipairs(payload.theme) do
                local glyph = glyphs[decoration.glyph]
                local frames = glyphLists[decoration.glyph]
                if glyph and frames then
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
    end
end

function gadget:DrawWorld()
    if not shader or not next(payloads) then return end
    local visible = visiblePayloads()
    if #visible == 0 then return end
    local seconds = Spring.GetGameSeconds()
    if Spring.GetFrameTimeOffset then
        seconds = seconds + Spring.GetFrameTimeOffset() / (Game.gameSpeed or 30)
    end
    gl.PushAttrib()
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(false)
    gl.Culling(false)
    gl.Blending(GL.SRC_ALPHA, GL.ONE)
    -- ActiveShader and PushPopMatrix preserve the caller's program/matrices.
    -- The attribute stack is also restored if a rendering callback fails.
    local ok, reason = pcall(gl.ActiveShader, shader, drawVisible, visible, seconds)
    gl.PopAttrib()
    if not ok then disable(reason) end
end

function gadget:Shutdown()
    releaseResources()
    payloads = {}
end
