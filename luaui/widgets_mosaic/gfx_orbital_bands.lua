function widget:GetInfo()
    return {
        name = "Orbital Plotter",
        desc = "Continuous orbital tracks, scan footprints, debris and Godrod warnings",
        author = "MOSAIC",
        date = "2026",
        license = "GNU GPL, v2 or later",
        layer = 42,
        enabled = true
    }
end

local spGetAllUnits = Spring.GetAllUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetTeamColor = Spring.GetTeamColor
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGameFrame = Spring.GetGameFrame
local spGetGameSeconds = Spring.GetGameSeconds

local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glDepthTest = gl.DepthTest
local glBlending = gl.Blending
local glUseShader = gl.UseShader
local glUniform = gl.Uniform

local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local satellites = {}
local shader
local timeLoc
local pulseLoc

local scanDefID = UnitDefNames["satellitescan"].id
local antiDefID = UnitDefNames["satelliteanti"].id
local godrodDefID = UnitDefNames["satellitegodrod"].id
local debrisDefID = UnitDefNames["satelliteshrapnell"].id
local orbitalDefs = {
    [scanDefID] = true,
    [antiDefID] = true,
    [godrodDefID] = true,
    [debrisDefID] = true
}

local SCAN_RADIUS = 500
local DEBRIS_RADIUS = 450
local GROUND_EPSILON = 8
local ENTRY_MARGIN = 2

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function moveToward(value, target, step)
    if value < target then return math.min(target, value + step) end
    if value > target then return math.max(target, value - step) end
    return value
end

local function groundY(x, z)
    return spGetGroundHeight(x, z) + GROUND_EPSILON
end

local function trackSpan(direction)
    return direction == 1 and mapSizeX or mapSizeZ
end

local function spoofedPrediction(unitID, direction, track)
    local myTeam = Spring.GetMyTeamID()
    if not myTeam or myTeam < 0 then return direction, track end

    if spGetUnitRulesParam(unitID, "orbital_is_godrod") == 1 and
        spGetUnitRulesParam(unitID, "godrod_positioning") == 1 then
        -- A committed Godrod path remains a public warning.
        return direction, track
    end

    local untilFrame =
        spGetTeamRulesParam(myTeam, "orbital_spoof_until") or 0
    if spGetGameFrame() > untilFrame then return direction, track end

    -- ECM lies about the predicted ground track, not the directly visible
    -- satellite hardware. Preserve continuity instead of snapping to fake bands.
    local seed = spGetTeamRulesParam(myTeam, "orbital_spoof_seed") or 0
    local falseDirection = ((seed + unitID) % 3 == 0) and
        (direction == 1 and 2 or 1) or direction

    local sourceSpan = math.max(1, trackSpan(direction))
    local targetSpan = math.max(1, trackSpan(falseDirection))
    local normalized = clamp(track / sourceSpan, 0, 1)
    local offset =
        ((((seed + unitID * 7) % 1000) / 999) - 0.5) * 0.35
    local falseTrack = clamp(
        (normalized + offset) * targetSpan,
        ENTRY_MARGIN,
        targetSpan - ENTRY_MARGIN
    )

    return falseDirection, falseTrack
end

local function drawTrack(direction, coord, r, g, b, alpha, dashed)
    coord = clamp(coord, ENTRY_MARGIN, trackSpan(direction) - ENTRY_MARGIN)
    local longSize = direction == 1 and mapSizeZ or mapSizeX
    local step = dashed and 420 or 256
    local gap = dashed and 170 or 0

    if dashed then
        glBeginEnd(GL.LINES, function()
            local p = 0
            while p < longSize do
                local p2 = math.min(longSize, p + step - gap)
                glColor(r, g, b, alpha)
                if direction == 1 then
                    glVertex(coord, groundY(coord, p), p)
                    glVertex(coord, groundY(coord, p2), p2)
                else
                    glVertex(p, groundY(p, coord), coord)
                    glVertex(p2, groundY(p2, coord), coord)
                end
                p = p + step
            end
        end)
    else
        glBeginEnd(GL.LINE_STRIP, function()
            local p = 0
            while p <= longSize do
                glColor(r, g, b, alpha)
                if direction == 1 then
                    glVertex(coord, groundY(coord, p), p)
                else
                    glVertex(p, groundY(p, coord), coord)
                end
                p = p + step
            end

            if longSize % step ~= 0 then
                if direction == 1 then
                    glVertex(coord, groundY(coord, longSize), longSize)
                else
                    glVertex(longSize, groundY(longSize, coord), coord)
                end
            end
        end)
    end
end

local function drawCircle(x, z, radius, r, g, b, alpha, segments)
    segments = segments or 48
    glBeginEnd(GL.LINE_LOOP, function()
        for i = 0, segments - 1 do
            local a = i / segments * math.pi * 2
            local px = x + math.cos(a) * radius
            local pz = z + math.sin(a) * radius
            glColor(r, g, b, alpha)
            glVertex(px, groundY(px, pz), pz)
        end
    end)
end

local function plottedFeedPosition(unitID, x, z, direction, track)
    local plottedDirection, plottedTrack =
        spoofedPrediction(unitID, direction, track)

    if plottedDirection == direction and math.abs(plottedTrack - track) < 0.01 then
        return x, z
    end

    if plottedDirection == 1 then
        return plottedTrack, z
    end
    return x, plottedTrack
end

local function drawScanFootprint(x, z, r, g, b)
    local segments = 56
    glBeginEnd(GL.TRIANGLE_FAN, function()
        glColor(r, g, b, 0.10)
        glVertex(x, groundY(x, z), z)
        for i = 0, segments do
            local a = i / segments * math.pi * 2
            local px = x + math.cos(a) * SCAN_RADIUS
            local pz = z + math.sin(a) * SCAN_RADIUS
            glColor(r, g, b, 0.0)
            glVertex(px, groundY(px, pz), pz)
        end
    end)
    drawCircle(x, z, SCAN_RADIUS, r, g, b, 0.32, segments)
end

local function drawDebrisHazard(x, z, life)
    life = math.max(0, math.min(1, life or 1))
    local alpha = 0.12 + 0.33 * life
    local phase = spGetGameSeconds() * 0.09

    for ring = 1, 3 do
        local radius = DEBRIS_RADIUS * (0.50 + ring * 0.16)
        local segments = 30
        glBeginEnd(GL.LINES, function()
            for i = 0, segments - 1 do
                if (i + ring) % 3 ~= 0 then
                    local a1 = phase + i / segments * math.pi * 2
                    local a2 = phase + (i + 0.62) / segments * math.pi * 2
                    local x1, z1 =
                        x + math.cos(a1) * radius,
                        z + math.sin(a1) * radius
                    local x2, z2 =
                        x + math.cos(a2) * radius,
                        z + math.sin(a2) * radius
                    glColor(0.78, 0.80, 0.76, alpha)
                    glVertex(x1, groundY(x1, z1), z1)
                    glVertex(x2, groundY(x2, z2), z2)
                end
            end
        end)
    end
end

local function drawGlyph(unitID, defID, x, z, r, g, b)
    local size = defID == godrodDefID and 54 or 42
    local y = groundY(x, z) + 3

    if defID == scanDefID then
        glBeginEnd(GL.LINE_LOOP, function()
            glColor(r, g, b, 0.90)
            glVertex(x, y, z - size)
            glVertex(x + size, y, z)
            glVertex(x, y, z + size)
            glVertex(x - size, y, z)
        end)
        glBeginEnd(GL.LINES, function()
            glVertex(x - size * 0.55, y, z)
            glVertex(x + size * 0.55, y, z)
            glVertex(x, y, z - size * 0.55)
            glVertex(x, y, z + size * 0.55)
        end)
    elseif defID == antiDefID then
        glBeginEnd(GL.LINES, function()
            glColor(r, g, b, 0.95)
            glVertex(x - size, y, z - size)
            glVertex(x, y, z)
            glVertex(x, y, z)
            glVertex(x + size, y, z - size)
            glVertex(x - size * 0.62, y, z + size)
            glVertex(x, y, z)
            glVertex(x, y, z)
            glVertex(x + size * 0.62, y, z + size)
        end)
    elseif defID == godrodDefID then
        glBeginEnd(GL.LINE_LOOP, function()
            glColor(r, g, b, 1.0)
            glVertex(x, y, z - size * 1.25)
            glVertex(x + size * 0.48, y, z + size * 0.65)
            glVertex(x, y, z + size * 0.35)
            glVertex(x - size * 0.48, y, z + size * 0.65)
        end)
    end
end

local function drawTimeoutArc(x, z, remaining, total, r, g, b)
    if not total or total <= 0 then return end
    local fraction = 1 - math.max(0, math.min(1, remaining / total))
    local segments = math.max(1, math.floor(40 * fraction))
    local radius = 68
    glBeginEnd(GL.LINE_STRIP, function()
        for i = 0, segments do
            local a = -math.pi * 0.5 + i / 40 * math.pi * 2
            local px = x + math.cos(a) * radius
            local pz = z + math.sin(a) * radius
            glColor(r, g, b, 0.85)
            glVertex(px, groundY(px, pz) + 4, pz)
        end
    end)
end

local function drawFutureTicks(
    unitID, x, z, direction, track, targetTrack, speed, slew, r, g, b
)
    local predictDirection, predictTrack =
        spoofedPrediction(unitID, direction, track)
    local targetDirection, predictTarget =
        spoofedPrediction(unitID, direction, targetTrack)

    if targetDirection ~= predictDirection then
        predictTarget = predictTrack
    end

    for tick = 1, 4 do
        local framesAhead = tick * 15 * 30
        local travel = (speed or 0) * framesAhead
        local cross = moveToward(
            predictTrack,
            predictTarget,
            (slew or 0) * framesAhead
        )
        local px, pz

        if predictDirection == 1 then
            px = cross
            pz = z + travel
            if pz >= mapSizeZ then break end
        else
            px = x + travel
            pz = cross
            if px >= mapSizeX then break end
        end

        local s = 13 - tick
        glBeginEnd(GL.LINES, function()
            glColor(r, g, b, 0.40 - tick * 0.055)
            glVertex(px - s, groundY(px - s, pz), pz)
            glVertex(px + s, groundY(px + s, pz), pz)
            glVertex(px, groundY(px, pz - s), pz - s)
            glVertex(px, groundY(px, pz + s), pz + s)
        end)
    end

    -- There is no lattice and no numbered band. The dashed line is simply the
    -- continuously steerable ground track the satellite is currently seeking.
    drawTrack(
        predictDirection,
        predictTarget,
        r, g, b,
        0.16,
        true
    )
end

local function drawGodrodCorridor(unitID, r, g, b)
    if spGetUnitRulesParam(unitID, "godrod_positioning") ~= 1 then return end

    local direction = spGetUnitRulesParam(unitID, "godrod_target_direction") or 0
    local track = spGetUnitRulesParam(unitID, "godrod_target_track") or 0
    if direction == 0 or track <= 0 then return end

    local width = 220

    if shader and pulseLoc then glUniform(pulseLoc, 1.0) end

    glBeginEnd(GL.QUADS, function()
        glColor(r, g, b, 0.085)
        if direction == 1 then
            local x1, x2 = track - width, track + width
            glVertex(x1, groundY(x1, 0), 0)
            glVertex(x2, groundY(x2, 0), 0)
            glVertex(x2, groundY(x2, mapSizeZ), mapSizeZ)
            glVertex(x1, groundY(x1, mapSizeZ), mapSizeZ)
        else
            local z1, z2 = track - width, track + width
            glVertex(0, groundY(0, z1), z1)
            glVertex(mapSizeX, groundY(mapSizeX, z1), z1)
            glVertex(mapSizeX, groundY(mapSizeX, z2), z2)
            glVertex(0, groundY(0, z2), z2)
        end
    end)

    glLineWidth(3.2)
    drawTrack(direction, track, r, g, b, 0.82, false)
    glLineWidth(1.0)

    if shader and pulseLoc then glUniform(pulseLoc, 0.0) end
end

local function addUnit(unitID, defID)
    if orbitalDefs[defID] then satellites[unitID] = defID end
end

function widget:UnitCreated(unitID, unitDefID)
    addUnit(unitID, unitDefID)
end

function widget:UnitDestroyed(unitID)
    satellites[unitID] = nil
end

function widget:Initialize()
    for _, unitID in ipairs(spGetAllUnits()) do
        addUnit(unitID, spGetUnitDefID(unitID))
    end

    if gl.CreateShader then
        shader = gl.CreateShader({
            uniform = {
                time = 0.0,
                pulseStrength = 0.0
            },
            vertex = [[
                #version 150 compatibility
                varying vec4 vColor;
                void main() {
                    vColor = gl_Color;
                    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
                }
            ]],
            fragment = [[
                #version 150 compatibility
                varying vec4 vColor;
                uniform float time;
                uniform float pulseStrength;
                void main() {
                    float pulse = 0.72 + 0.28 * sin(time * 3.1);
                    float a = vColor.a * mix(1.0, pulse, pulseStrength);
                    gl_FragColor = vec4(vColor.rgb, a);
                }
            ]]
        })

        if shader then
            timeLoc = gl.GetUniformLocation(shader, "time")
            pulseLoc = gl.GetUniformLocation(shader, "pulseStrength")
        else
            Spring.Echo("Orbital Plotter: shader compile failed; using fixed-function fallback")
        end
    end
end

function widget:Shutdown()
    if shader then gl.DeleteShader(shader) end
end

function widget:DrawWorldPreUnit()
    if not next(satellites) then return end

    glDepthTest(true)
    glBlending(GL.SRC_ALPHA, GL.ONE)
    glLineWidth(1.35)

    if shader then
        glUseShader(shader)
        if timeLoc then glUniform(timeLoc, spGetGameSeconds()) end
        if pulseLoc then glUniform(pulseLoc, 0.0) end
    end

    for unitID, defID in pairs(satellites) do
        local x, _, z = spGetUnitPosition(unitID)
        if x then
            local teamID = spGetUnitTeam(unitID)
            local r, g, b = spGetTeamColor(teamID)
            if not r then r, g, b = 0.8, 0.8, 0.8 end

            local direction = spGetUnitRulesParam(unitID, "orbital_direction") or 1
            local state = spGetUnitRulesParam(unitID, "orbital_state") or 0
            local speed = spGetUnitRulesParam(unitID, "orbital_speed") or 0
            local slew = spGetUnitRulesParam(unitID, "orbital_slew_speed") or 0
            local track = spGetUnitRulesParam(unitID, "orbital_track") or
                (direction == 1 and x or z)
            local targetTrack =
                spGetUnitRulesParam(unitID, "orbital_target_track") or track

            if defID == debrisDefID then
                local life =
                    spGetUnitRulesParam(unitID, "orbital_debris_life") or 1
                drawDebrisHazard(x, z, life)
            elseif state == 1 or state == 2 then
                -- The physical contact is always truthful. ECM only corrupts
                -- prediction/footprint overlays.
                drawGlyph(unitID, defID, x, z, r, g, b)

                if state == 1 then
                    drawFutureTicks(
                        unitID, x, z,
                        direction, track, targetTrack,
                        speed, slew,
                        r, g, b
                    )

                    if defID == scanDefID then
                        local feedX, feedZ = plottedFeedPosition(
                            unitID, x, z, direction, track
                        )
                        drawScanFootprint(feedX, feedZ, r, g, b)
                    end
                elseif state == 2 then
                    local remaining =
                        spGetUnitRulesParam(unitID, "orbital_timeout_remaining") or 0
                    local total =
                        spGetUnitRulesParam(unitID, "orbital_timeout_total") or 1
                    drawTimeoutArc(x, z, remaining, total, r, g, b)

                    local pendingDirection =
                        spGetUnitRulesParam(unitID, "orbital_pending_direction") or 0
                    local pendingTrack =
                        spGetUnitRulesParam(unitID, "orbital_pending_track") or 0
                    if pendingDirection > 0 and pendingTrack > 0 then
                        drawTrack(
                            pendingDirection,
                            pendingTrack,
                            r, g, b,
                            0.26,
                            true
                        )
                    end
                end

                if defID == godrodDefID then
                    drawGodrodCorridor(unitID, r, g, b)
                end
            end
        end
    end

    if shader then glUseShader(0) end
    glLineWidth(1.0)
    glBlending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    glDepthTest(false)
    glColor(1, 1, 1, 1)
end
