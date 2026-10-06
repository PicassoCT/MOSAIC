function gadget:GetInfo()
    return {
        name = "Orbital Tracks",
        desc = "Directly steered orbital ground tracks, downtime retasking and orbital hazards",
        author = "pica",
        date = "Anno Domini 2018 / rebuilt 2026",
        license = "GNU GPL, v2 or later",
        layer = 109,
        version = 3,
        enabled = true,
        hidden = true
    }
end

if not gadgetHandler:IsSyncedCode() then return end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_mosaic.lua")

local GameConfig = getGameConfig()
local SatelliteTypes = getOrbitalTypes(UnitDefs)
local SatelliteSpeed = getSatelliteTypesSpeedTable(UnitDefs)
local SatelliteAltitude = getSatelliteAltitudeTable(UnitDefs)
local SatelliteTimeout = getSatelliteTimeOutTable(UnitDefs)

local scanDefID = UnitDefNames["satellitescan"].id
local antiDefID = UnitDefNames["satelliteanti"].id
local godrodDefID = UnitDefNames["satellitegodrod"].id
local shrapnelDefID = UnitDefNames["satelliteshrapnell"].id
local nooneDefID = UnitDefNames["noone"].id

local gaiaTeamID = Spring.GetGaiaTeamID()
local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local ENTRY_MARGIN = 2
local TURN_EDGE_MARGIN = 96
local COURSE_SLEW_FRACTION = 0.25
local MIN_COURSE_SLEW = 0.80
local INTERCEPT_SLEW_MULTIPLIER = 1.25
local INTERCEPT_SPEED_DELTA = 0.35
local INTERCEPT_RANGE = 180
local GODROD_TRACK_TOLERANCE = 60
local allyTeamList = Spring.GetAllyTeamList()

local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spMoveCtrlSetPosition = Spring.MoveCtrl.SetPosition
local spMoveCtrlEnable = Spring.MoveCtrl.Enable
local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spSetUnitNeutral = Spring.SetUnitNeutral
local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spSetUnitSensorRadius = Spring.SetUnitSensorRadius

local Satellites = {}
local SatellitesWaiting = {}
local orbitalState = {}
local downlinkSpoofUntil = {}

GG.DiedPeacefully = GG.DiedPeacefully or {}
GG.NooneParent = GG.NooneParent or {}
GG.Orbital = GG.Orbital or {}

local PUBLIC = {public = true}
local PRIVATE = {private = true}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function moveToward(value, target, step)
    if value < target then return math.min(target, value + step) end
    if value > target then return math.max(target, value - step) end
    return value
end

local function alive(id)
    return type(id) == "number" and doesUnitExistAlive(id) == true
end

local function hostile(teamA, teamB)
    if teamA == nil or teamB == nil or teamA == teamB then return false end
    if Spring.AreTeamsAllied then
        return not Spring.AreTeamsAllied(teamA, teamB)
    end
    return true
end

local function directionCode(direction)
    return direction == "horizontal" and 2 or 1
end

local function directionFromCode(code)
    return code == 2 and "horizontal" or "vertical"
end

local function trackLimit(direction)
    return direction == "vertical" and mapSizeX or mapSizeZ
end

local function alongLimit(direction)
    return direction == "vertical" and mapSizeZ or mapSizeX
end

local function crossTrack(direction, x, z)
    return direction == "vertical" and x or z
end

local function alongTrack(direction, x, z)
    return direction == "vertical" and z or x
end

local function entryPosition(direction, track)
    track = clamp(track, ENTRY_MARGIN, trackLimit(direction) - ENTRY_MARGIN)
    if direction == "vertical" then
        return track, ENTRY_MARGIN
    end
    return ENTRY_MARGIN, track
end

local function initialCourse(unitID)
    local direction = (unitID % 2 == 0) and "vertical" or "horizontal"
    local span = trackLimit(direction)
    local seed = (unitID * 1103515245 + 12345) % 10000
    local fraction = 0.12 + 0.76 * (seed / 9999)
    return direction, clamp(span * fraction, ENTRY_MARGIN, span - ENTRY_MARGIN)
end

local function courseSlewSpeed(data)
    local base = SatelliteSpeed[data.utype] or 0
    local slew = math.max(MIN_COURSE_SLEW, base * COURSE_SLEW_FRACTION)
    if data.utype == antiDefID and data.interceptTarget then
        slew = slew * INTERCEPT_SLEW_MULTIPLIER
    end
    return slew
end

local function isOperationalSatellite(defID)
    return defID == scanDefID or defID == antiDefID or defID == godrodDefID
end

local function makeOrbitPublic(unitID)
    if not alive(unitID) then return end
    spSetUnitAlwaysVisible(unitID, true)
    for i = 1, #allyTeamList do
        Spring.SetUnitLosState(unitID, allyTeamList[i], {
            los = true,
            prevLos = true,
            radar = true,
            contRadar = true
        })
    end
end

local function setGroundVision(unitID, defID, active)
    if not spSetUnitSensorRadius then return end
    if defID == scanDefID and active then
        local radius =
            UnitDefs[defID].losRadius or UnitDefs[defID].sightDistance or 500
        spSetUnitSensorRadius(unitID, "los", radius)
    else
        spSetUnitSensorRadius(unitID, "los", 0)
        spSetUnitSensorRadius(unitID, "airLos", 0)
        spSetUnitSensorRadius(unitID, "radar", 0)
    end
end

local function publish(unitID, data)
    if not data then return end

    spSetUnitRulesParam(unitID, "orbital_direction", directionCode(data.direction), PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_state",
        data.state == "flying" and 1 or (data.state == "timeout" and 2 or 0), PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_timeout_remaining", data.timeoutRemaining or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_timeout_total", data.timeoutTotal or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_timeout_serial", data.timeoutSerial or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_speed",
        data.currentSpeed or SatelliteSpeed[data.utype] or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_slew_speed", courseSlewSpeed(data), PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_track", data.track or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_target_track",
        data.desiredTrack or data.track or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_scan", data.utype == scanDefID and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_anti", data.utype == antiDefID and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_godrod", data.utype == godrodDefID and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_debris", data.utype == shrapnelDefID and 1 or 0, PUBLIC)

    if data.pendingDirection then
        spSetUnitRulesParam(unitID, "orbital_pending_direction",
            directionCode(data.pendingDirection), PUBLIC)
        spSetUnitRulesParam(unitID, "orbital_pending_track",
            data.pendingTrack or 0, PUBLIC)
    else
        spSetUnitRulesParam(unitID, "orbital_pending_direction", 0, PUBLIC)
        spSetUnitRulesParam(unitID, "orbital_pending_track", 0, PUBLIC)
    end

    local changing =
        data.pendingDirection or
        math.abs((data.desiredTrack or data.track or 0) - (data.track or 0)) > 1
    spSetUnitRulesParam(unitID, "orbital_course_changing", changing and 1 or 0, PUBLIC)

    local godrod = data.godrod
    spSetUnitRulesParam(unitID, "godrod_positioning", godrod and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "godrod_target_direction",
        godrod and directionCode(godrod.direction) or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "godrod_target_track",
        godrod and godrod.track or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "godrod_target_x", godrod and godrod.x or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "godrod_target_z", godrod and godrod.z or 0, PUBLIC)
end

local function setFlightPresentation(unitID, active)
    if not alive(unitID) then return end
    spSetUnitAlwaysVisible(unitID, true)
    spSetUnitBlocking(unitID, false, false, false)
    spSetUnitNeutral(unitID, false)
    showHideIconEnv(unitID, not active)
end

local function configureSatellite(unitID, data)
    spSetUnitBlocking(unitID, false, false, false)
    setGroundVision(unitID, data.utype, false)
end

local function timeoutTarget(data)
    if data.pendingDirection then
        local track = data.pendingTrack or
            clamp(data.desiredTrack or data.track or ENTRY_MARGIN,
                  ENTRY_MARGIN,
                  trackLimit(data.pendingDirection) - ENTRY_MARGIN)
        return entryPosition(data.pendingDirection, track)
    end

    local track = clamp(data.desiredTrack or data.track or ENTRY_MARGIN,
        ENTRY_MARGIN, trackLimit(data.direction) - ENTRY_MARGIN)
    return entryPosition(data.direction, track)
end

local function beginFlight(unitID, data)
    spMoveCtrlEnable(unitID, true)
    data.state = "flying"
    data.timeoutRemaining = 0
    data.timeoutTotal = 0

    if data.pendingDirection then
        data.direction = data.pendingDirection
        data.track = clamp(
            data.pendingTrack or data.desiredTrack or data.track or ENTRY_MARGIN,
            ENTRY_MARGIN,
            trackLimit(data.direction) - ENTRY_MARGIN
        )
        data.desiredTrack = data.track
        data.pendingDirection = nil
        data.pendingTrack = nil
    else
        data.track = clamp(
            data.desiredTrack or data.track or ENTRY_MARGIN,
            ENTRY_MARGIN,
            trackLimit(data.direction) - ENTRY_MARGIN
        )
    end

    local x, z = entryPosition(data.direction, data.track)
    spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
    data.lastX, data.lastY, data.lastZ =
        x, SatelliteAltitude[data.utype], z
    makeOrbitPublic(unitID)
    setGroundVision(unitID, data.utype, true)
    setFlightPresentation(unitID, true)
    publish(unitID, data)
end

local function beginTimeout(unitID, data)
    if data.utype == shrapnelDefID then return end

    data.state = "timeout"
    data.timeoutSerial = (data.timeoutSerial or 0) + 1
    data.timeoutTotal = math.max(1, SatelliteTimeout[data.utype] or 1)
    data.timeoutRemaining = data.timeoutTotal
    data.currentSpeed = 0

    local x, _, z = spGetUnitPosition(unitID)
    data.shiftStartX, data.shiftStartZ = x or 0, z or 0
    data.shiftTargetX, data.shiftTargetZ = timeoutTarget(data)

    setGroundVision(unitID, data.utype, false)
    setFlightPresentation(unitID, false)
    publish(unitID, data)
end

local function requestedDirectionChange(data, x, z)
    local xEdge = math.min(x, mapSizeX - x)
    local zEdge = math.min(z, mapSizeZ - z)

    if xEdge <= TURN_EDGE_MARGIN and xEdge <= zEdge and
        data.direction ~= "horizontal" then
        return "horizontal", clamp(z, ENTRY_MARGIN, mapSizeZ - ENTRY_MARGIN)
    end

    if zEdge <= TURN_EDGE_MARGIN and zEdge < xEdge and
        data.direction ~= "vertical" then
        return "vertical", clamp(x, ENTRY_MARGIN, mapSizeX - ENTRY_MARGIN)
    end

    return nil
end

local function setCourse(unitID, x, z)
    local data = Satellites[unitID] or SatellitesWaiting[unitID]
    if not data or data.utype == shrapnelDefID then return false end
    if type(x) ~= "number" or type(z) ~= "number" then return false end

    data.interceptTarget = nil
    data.commandX, data.commandZ = x, z

    local targetTrack = crossTrack(data.direction, x, z)
    data.desiredTrack = clamp(
        targetTrack,
        ENTRY_MARGIN,
        trackLimit(data.direction) - ENTRY_MARGIN
    )

    local pendingDirection, pendingTrack =
        requestedDirectionChange(data, x, z)

    data.pendingDirection = pendingDirection
    data.pendingTrack = pendingTrack

    if data.state == "timeout" then
        data.shiftTargetX, data.shiftTargetZ = timeoutTarget(data)
    end

    publish(unitID, data)
    return true
end

local function setInterceptTarget(unitID, targetID)
    local data = Satellites[unitID]
    local targetData = Satellites[targetID]
    if not data or data.utype ~= antiDefID or
        not targetData or targetData.utype == shrapnelDefID or
        not hostile(spGetUnitTeam(unitID), spGetUnitTeam(targetID)) then
        return false
    end

    data.interceptTarget = targetID

    local tx, _, tz = spGetUnitPosition(targetID)
    if tx then
        data.desiredTrack = clamp(
            crossTrack(data.direction, tx, tz),
            ENTRY_MARGIN,
            trackLimit(data.direction) - ENTRY_MARGIN
        )
    end

    if targetData.direction ~= data.direction and tx then
        data.pendingDirection = targetData.direction
        data.pendingTrack = clamp(
            crossTrack(targetData.direction, tx, tz),
            ENTRY_MARGIN,
            trackLimit(targetData.direction) - ENTRY_MARGIN
        )
    else
        data.pendingDirection = nil
        data.pendingTrack = nil
    end

    if data.state == "timeout" then
        data.shiftTargetX, data.shiftTargetZ = timeoutTarget(data)
    end

    publish(unitID, data)
    return true
end

local function updateInterceptGuidance(unitID, data)
    if data.utype ~= antiDefID or not data.interceptTarget then return end

    local targetID = data.interceptTarget
    local targetData = Satellites[targetID]
    if not alive(targetID) or not targetData or
        targetData.utype == shrapnelDefID or
        not hostile(spGetUnitTeam(unitID), spGetUnitTeam(targetID)) then
        data.interceptTarget = nil
        data.pendingDirection = nil
        data.pendingTrack = nil
        return
    end

    local tx, _, tz = spGetUnitPosition(targetID)
    if not tx then return end

    data.desiredTrack = clamp(
        crossTrack(data.direction, tx, tz),
        ENTRY_MARGIN,
        trackLimit(data.direction) - ENTRY_MARGIN
    )

    if targetData.direction ~= data.direction then
        data.pendingDirection = targetData.direction
        data.pendingTrack = clamp(
            crossTrack(targetData.direction, tx, tz),
            ENTRY_MARGIN,
            trackLimit(targetData.direction) - ENTRY_MARGIN
        )
    else
        data.pendingDirection = nil
        data.pendingTrack = nil
    end
end

local function signedCircularDelta(target, source, span)
    local delta = target - source
    if delta > span * 0.5 then
        delta = delta - span
    elseif delta < -span * 0.5 then
        delta = delta + span
    end
    return delta
end

local function forwardSpeed(unitID, data, x, z)
    local base = SatelliteSpeed[data.utype] or 0
    if data.utype ~= antiDefID or not data.interceptTarget then
        return base
    end

    local targetID = data.interceptTarget
    local targetData = Satellites[targetID]
    if not targetData or targetData.state ~= "flying" or
        targetData.direction ~= data.direction then
        return base
    end

    local tx, _, tz = spGetUnitPosition(targetID)
    if not tx then return base end

    local span = alongLimit(data.direction)
    local delta = signedCircularDelta(
        alongTrack(data.direction, tx, tz),
        alongTrack(data.direction, x, z),
        span
    )
    local responseWindow = math.max(600, span * 0.12)
    local factor = clamp(delta / responseWindow,
        -INTERCEPT_SPEED_DELTA, INTERCEPT_SPEED_DELTA)

    return base * (1 + factor)
end

local function flyingPosition(unitID, data, x, z)
    updateInterceptGuidance(unitID, data)

    local speed = forwardSpeed(unitID, data, x, z)
    local slew = courseSlewSpeed(data)
    local desired = clamp(
        data.desiredTrack or crossTrack(data.direction, x, z),
        ENTRY_MARGIN,
        trackLimit(data.direction) - ENTRY_MARGIN
    )

    if data.direction == "vertical" then
        x = moveToward(x, desired, slew)
        z = z + speed
        data.track = x
    else
        z = moveToward(z, desired, slew)
        x = x + speed
        data.track = z
    end

    data.currentSpeed = speed
    return x, z
end

local function reachedExit(data, x, z)
    if data.direction == "vertical" then
        return z >= mapSizeZ - ENTRY_MARGIN
    end
    return x >= mapSizeX - ENTRY_MARGIN
end

local function updateTimeout(unitID, data)
    updateInterceptGuidance(unitID, data)

    local remainingBeforeStep = math.max(1, data.timeoutRemaining or 1)
    local tx, tz = timeoutTarget(data)
    data.shiftTargetX, data.shiftTargetZ = tx, tz

    local x, _, z = spGetUnitPosition(unitID)
    if not x then return end

    -- Keep the existing visible "go round the planet" downtime motion: move
    -- one remaining-time fraction toward the next entry point. Retasking during
    -- downtime bends that path immediately instead of snapping on re-entry.
    x = x + (tx - x) / remainingBeforeStep
    z = z + (tz - z) / remainingBeforeStep
    data.timeoutRemaining = math.max(0, remainingBeforeStep - 1)
    data.track = crossTrack(data.pendingDirection or data.direction, x, z)

    spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
    data.lastX, data.lastY, data.lastZ =
        x, SatelliteAltitude[data.utype], z

    if data.timeoutRemaining <= 0 then
        beginFlight(unitID, data)
    elseif Spring.GetGameFrame() % 30 == 0 then
        publish(unitID, data)
    end
end

local function updateDebris(unitID, data)
    local x, _, z = spGetUnitPosition(unitID)
    if not x then return end

    local speed = SatelliteSpeed[data.utype] or 0
    if data.direction == "vertical" then
        z = z + speed
        if z >= mapSizeZ then z = ENTRY_MARGIN end
        data.track = x
    else
        x = x + speed
        if x >= mapSizeX then x = ENTRY_MARGIN end
        data.track = z
    end

    data.currentSpeed = speed
    spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
    data.lastX, data.lastY, data.lastZ =
        x, SatelliteAltitude[data.utype], z
end

local function spawnDebris(x, y, z, sourceData)
    if not x then return nil end

    local cloudID = spCreateUnit(
        "satelliteshrapnell",
        x, y or SatelliteAltitude[shrapnelDefID], z,
        1,
        gaiaTeamID
    )
    if not cloudID then return nil end

    local data = SatellitesWaiting[cloudID] or Satellites[cloudID]
    if data and sourceData then
        data.direction = sourceData.direction
        data.track = crossTrack(data.direction, x, z)
        data.desiredTrack = data.track
        data.pendingDirection = nil
        data.pendingTrack = nil
        publish(cloudID, data)
    end
    return cloudID
end

local function sameCourseAndClose(parentID, targetID)
    local a = Satellites[parentID]
    local b = Satellites[targetID]
    if not a or not b or
        a.state ~= "flying" or b.state ~= "flying" or
        a.direction ~= b.direction then
        return false
    end

    local ax, _, az = spGetUnitPosition(parentID)
    local bx, _, bz = spGetUnitPosition(targetID)
    if not ax or not bx then return false end

    local dx, dz = ax - bx, az - bz
    return dx * dx + dz * dz <= INTERCEPT_RANGE * INTERCEPT_RANGE
end

local function resolveAntiSatelliteStrike(parentID, childID, targetID)
    if not alive(parentID) or not alive(childID) or not alive(targetID) then
        return false
    end

    local parentData = Satellites[parentID]
    local targetData = Satellites[targetID]
    if not parentData or parentData.utype ~= antiDefID or
        parentData.interceptTarget ~= targetID or
        not targetData or targetData.utype == shrapnelDefID or
        not hostile(spGetUnitTeam(parentID), spGetUnitTeam(targetID)) or
        not sameCourseAndClose(parentID, targetID) then
        return false
    end

    GG.DiedPeacefully[parentID] = true
    spDestroyUnit(targetID, false, true)
    if alive(parentID) then
        spDestroyUnit(parentID, true, false)
    end
    return true
end

local function requestGodRodStrike(unitID, x, z)
    local data = Satellites[unitID]
    if not data or data.utype ~= godrodDefID then return false end
    if type(x) ~= "number" or type(z) ~= "number" then return false end

    if data.godrod and
        math.abs(data.godrod.x - x) < 1 and
        math.abs(data.godrod.z - z) < 1 then
        return true
    end

    local direction = data.direction
    local track = clamp(
        crossTrack(direction, x, z),
        ENTRY_MARGIN,
        trackLimit(direction) - ENTRY_MARGIN
    )
    data.desiredTrack = track
    data.pendingDirection = nil
    data.pendingTrack = nil

    local needsSerial = data.timeoutSerial or 0
    if data.state ~= "timeout" then
        needsSerial = needsSerial + 1
    else
        -- A Godrod warning must remain visible for one complete downtime after
        -- commitment, even when the order arrives late in an existing downtime.
        data.timeoutRemaining = math.max(
            1,
            SatelliteTimeout[data.utype] or data.timeoutTotal or 1
        )
        data.timeoutTotal = data.timeoutRemaining
        local sx, _, sz = spGetUnitPosition(unitID)
        data.shiftStartX, data.shiftStartZ = sx or 0, sz or 0
    end

    data.godrod = {
        x = x,
        z = z,
        direction = direction,
        track = track,
        requiredTimeoutSerial = needsSerial
    }

    if data.state == "timeout" then
        data.shiftTargetX, data.shiftTargetZ = timeoutTarget(data)
    end

    publish(unitID, data)
    return true
end

local function canGodRodFire(unitID)
    local data = Satellites[unitID]
    local target = data and data.godrod
    if not data or not target or data.state ~= "flying" then
        return false
    end

    if (data.timeoutSerial or 0) < target.requiredTimeoutSerial or
        data.direction ~= target.direction then
        return false
    end

    local x, _, z = spGetUnitPosition(unitID)
    if not x then return false end

    local currentTrack = crossTrack(data.direction, x, z)
    if math.abs(currentTrack - target.track) > GODROD_TRACK_TOLERANCE then
        return false
    end

    local dropDistance =
        GameConfig.military.satellites.godRod.dropDistance or 50
    local distanceAlong =
        data.direction == "vertical" and math.abs(z - target.z) or
        math.abs(x - target.x)

    if distanceAlong <= dropDistance then
        return true, target.x, Spring.GetGroundHeight(target.x, target.z), target.z
    end
    return false
end

local function consumeGodRodPositioning(unitID)
    local data = Satellites[unitID]
    if not data then return end
    data.godrod = nil
    publish(unitID, data)
end

local function spoofDownlink(victimTeamID, ecmID, nimrodID, untilFrame)
    if type(victimTeamID) ~= "number" then return end
    local frame = Spring.GetGameFrame()
    untilFrame = math.max(untilFrame or (frame + 30), frame + 1)
    local seed =
        ((ecmID or 0) * 131 + (nimrodID or 0) * 17 + victimTeamID * 7) % 997

    downlinkSpoofUntil[victimTeamID] =
        math.max(downlinkSpoofUntil[victimTeamID] or 0, untilFrame)

    spSetTeamRulesParam(victimTeamID, "orbital_spoof_until", untilFrame, PRIVATE)
    spSetTeamRulesParam(victimTeamID, "orbital_spoof_seed", seed, PRIVATE)
end

function gadget:Initialize()
    GG.Orbital.SetCourse = setCourse
    GG.Orbital.SetInterceptTarget = setInterceptTarget
    GG.Orbital.RequestGodRodStrike = requestGodRodStrike
    GG.Orbital.CanGodRodFire = canGodRodFire
    GG.Orbital.ConsumeGodRodPositioning = consumeGodRodPositioning
    GG.Orbital.ResolveAntiSatelliteStrike = resolveAntiSatelliteStrike
    GG.Orbital.SpoofDownlink = spoofDownlink

    for _, unitID in ipairs(Spring.GetAllUnits()) do
        local defID = spGetUnitDefID(unitID)
        if SatelliteTypes[defID] then
            self:UnitCreated(unitID, defID)
        end
    end
end

function gadget:Shutdown()
    if GG.Orbital then
        GG.Orbital.SetCourse = nil
        GG.Orbital.SetInterceptTarget = nil
        GG.Orbital.RequestGodRodStrike = nil
        GG.Orbital.CanGodRodFire = nil
        GG.Orbital.ConsumeGodRodPositioning = nil
        GG.Orbital.ResolveAntiSatelliteStrike = nil
        GG.Orbital.SpoofDownlink = nil
    end
end

function gadget:UnitCreated(unitID, unitDefID)
    if not SatelliteTypes[unitDefID] then return end

    local direction, track = initialCourse(unitID)
    local data = {
        utype = unitDefID,
        direction = direction,
        track = track,
        desiredTrack = track,
        state = "waiting",
        timeoutSerial = 0
    }

    orbitalState[unitID] = data
    configureSatellite(unitID, data)

    if unitDefID == shrapnelDefID then
        -- Debris is born at the intercept/destruction point and keeps drifting
        -- from that physical position; it never enters satellite downtime.
        spMoveCtrlEnable(unitID, true)
        data.state = "flying"
        Satellites[unitID] = data
        local dx, dy, dz = spGetUnitPosition(unitID)
        if dx then
            data.track = crossTrack(data.direction, dx, dz)
            data.desiredTrack = data.track
        end
        data.lastX, data.lastY, data.lastZ = dx, dy, dz
        makeOrbitPublic(unitID)
        setFlightPresentation(unitID, true)
        publish(unitID, data)
    else
        SatellitesWaiting[unitID] = data
        publish(unitID, data)
        showHideIconEnv(unitID, true)
    end
end

function gadget:UnitDestroyed(unitID, unitDefID)
    local data = Satellites[unitID] or SatellitesWaiting[unitID]
    Satellites[unitID] = nil
    SatellitesWaiting[unitID] = nil
    orbitalState[unitID] = nil
    GG.NooneParent[unitID] = nil

    if SatelliteTypes[unitDefID] and unitDefID ~= shrapnelDefID then
        local diedPeacefully = GG.DiedPeacefully[unitID] == true
        GG.DiedPeacefully[unitID] = nil

        if not diedPeacefully then
            local x, y, z = spGetUnitPosition(unitID)
            if not x and data then
                x, y, z = data.lastX, data.lastY, data.lastZ
            end
            spawnDebris(x, y, z, data)
        end
    end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams)
    if not SatelliteTypes[unitDefID] or unitDefID == shrapnelDefID then
        return true
    end

    -- Normal RTS interaction is the orbital course-control surface. There is
    -- deliberately no custom band button: select the satellite and right-click.
    if cmdID == CMD.MOVE or cmdID == CMD.PATROL then
        if cmdParams and #cmdParams >= 3 then
            setCourse(unitID, cmdParams[1], cmdParams[3])
        end
        return false
    end

    if cmdID == CMD.STOP then
        local data = Satellites[unitID] or SatellitesWaiting[unitID]
        if data then
            data.interceptTarget = nil
            data.pendingDirection = nil
            data.pendingTrack = nil
            local x, _, z = spGetUnitPosition(unitID)
            if x then
                data.track = crossTrack(data.direction, x, z)
                data.desiredTrack = data.track
            end
            publish(unitID, data)
        end
        return false
    end

    if unitDefID == antiDefID and cmdID == CMD.ATTACK then
        local targetID = cmdParams and cmdParams[1]
        if type(targetID) == "number" and Satellites[targetID] then
            setInterceptTarget(unitID, targetID)
        end
        return false
    end

    -- The Godrod deliberately keeps ordinary ground-target attack commands.
    if unitDefID ~= godrodDefID and
        (cmdID == CMD.ATTACK or
         cmdID == CMD.AREA_ATTACK or
         cmdID == CMD.FIGHT or
         cmdID == CMD.GUARD) then
        return false
    end

    return true
end

function gadget:AllowWeaponTarget(attackerID, targetID, weaponNum, weaponDefID, priority)
    local attackerDefID = spGetUnitDefID(attackerID)
    if attackerDefID ~= nooneDefID then
        return true, priority
    end

    local parentID = GG.NooneParent[attackerID]
    local targetData = Satellites[targetID]
    local parentData = parentID and Satellites[parentID]
    local allowed = parentData and
        parentData.interceptTarget == targetID and
        targetData and
        targetData.utype ~= shrapnelDefID and
        hostile(spGetUnitTeam(parentID), spGetUnitTeam(targetID)) and
        sameCourseAndClose(parentID, targetID)

    return allowed == true, priority
end

function gadget:GameFrame(frame)
    for unitID, data in pairs(SatellitesWaiting) do
        if alive(unitID) then
            local _, _, _, _, buildProgress = spGetUnitHealth(unitID)
            if buildProgress and buildProgress >= 1.0 then
                Satellites[unitID] = data
                SatellitesWaiting[unitID] = nil
                beginFlight(unitID, data)
            end
        else
            SatellitesWaiting[unitID] = nil
            orbitalState[unitID] = nil
        end
    end

    for unitID, data in pairs(Satellites) do
        if not alive(unitID) then
            Satellites[unitID] = nil
        elseif data.utype == shrapnelDefID then
            if frame % 30 == 0 then makeOrbitPublic(unitID) end
            updateDebris(unitID, data)
        elseif data.state == "flying" then
            if frame % 30 == 0 then
                makeOrbitPublic(unitID)

                if data.utype == scanDefID then
                    local teamID = spGetUnitTeam(unitID)
                    local spoofed =
                        (downlinkSpoofUntil[teamID] or 0) >= frame
                    -- ECM can poison the downlink feed, never the directly
                    -- visible physical satellite.
                    setGroundVision(unitID, data.utype, not spoofed)
                end
            end

            local x, _, z = spGetUnitPosition(unitID)
            if x then
                x, z = flyingPosition(unitID, data, x, z)
                spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
                data.lastX, data.lastY, data.lastZ =
                    x, SatelliteAltitude[data.utype], z

                if reachedExit(data, x, z) then
                    beginTimeout(unitID, data)
                elseif frame % 30 == 0 then
                    publish(unitID, data)
                end
            end
        elseif data.state == "timeout" then
            if frame % 30 == 0 then makeOrbitPublic(unitID) end
            updateTimeout(unitID, data)
        end
    end
end
