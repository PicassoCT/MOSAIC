function gadget:GetInfo()
    return {
        name = "Orbital Bands",
        desc = "Predictable orbital ground tracks, downtime retasking and orbital hazards",
        author = "pica",
        date = "Anno Domini 2018 / rebuilt 2026",
        license = "GNU GPL, v2 or later",
        layer = 109,
        version = 2,
        enabled = true,
        hidden = true
    }
end

if not gadgetHandler:IsSyncedCode() then return end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("luarules/configs/commandsIDs.lua")

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
local BAND_COUNT = 5
local ENTRY_MARGIN = 2
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

GG.DiedPeacefully = GG.DiedPeacefully or {}
GG.NooneParent = GG.NooneParent or {}
GG.Orbital = GG.Orbital or {}

local PUBLIC = {public = true}
local PRIVATE = {private = true}

local function alive(id)
    return type(id) == "number" and doesUnitExistAlive(id) == true
end

local function directionCode(direction)
    return direction == "horizontal" and 2 or 1
end

local function directionFromCode(code)
    return code == 2 and "horizontal" or "vertical"
end

local function bandCoordinate(direction, band)
    band = math.max(1, math.min(BAND_COUNT, math.floor(band or 1)))
    local size = direction == "vertical" and mapSizeX or mapSizeZ
    return size * band / (BAND_COUNT + 1)
end

local function entryPosition(direction, band)
    if direction == "vertical" then
        return bandCoordinate(direction, band), ENTRY_MARGIN
    end
    return ENTRY_MARGIN, bandCoordinate(direction, band)
end

local function exitPosition(direction, band)
    if direction == "vertical" then
        return bandCoordinate(direction, band), mapSizeZ - ENTRY_MARGIN
    end
    return mapSizeX - ENTRY_MARGIN, bandCoordinate(direction, band)
end

local function closestBandForPoint(x, z)
    local bestDirection, bestBand, bestDistance
    for band = 1, BAND_COUNT do
        local vx = bandCoordinate("vertical", band)
        local vd = math.abs(x - vx)
        if not bestDistance or vd < bestDistance then
            bestDirection, bestBand, bestDistance = "vertical", band, vd
        end

        local hz = bandCoordinate("horizontal", band)
        local hd = math.abs(z - hz)
        if hd < bestDistance then
            bestDirection, bestBand, bestDistance = "horizontal", band, hd
        end
    end
    return bestDirection, bestBand
end

local function initialBand(unitID)
    local band = ((math.floor(unitID / 2)) % BAND_COUNT) + 1
    local direction = (unitID % 2 == 0) and "vertical" or "horizontal"
    return direction, band
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

    spSetUnitRulesParam(unitID, "orbital_band_count", BAND_COUNT, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_band", data.band or 1, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_direction", directionCode(data.direction), PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_state",
        data.state == "flying" and 1 or (data.state == "timeout" and 2 or 0), PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_timeout_remaining", data.timeoutRemaining or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_timeout_total", data.timeoutTotal or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_timeout_serial", data.timeoutSerial or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_speed", SatelliteSpeed[data.utype] or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_scan", data.utype == scanDefID and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_anti", data.utype == antiDefID and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_godrod", data.utype == godrodDefID and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "orbital_is_debris", data.utype == shrapnelDefID and 1 or 0, PUBLIC)

    if data.pendingBand then
        spSetUnitRulesParam(unitID, "orbital_pending_band", data.pendingBand, PUBLIC)
        spSetUnitRulesParam(unitID, "orbital_pending_direction",
            directionCode(data.pendingDirection), PUBLIC)
    else
        spSetUnitRulesParam(unitID, "orbital_pending_band", 0, PUBLIC)
        spSetUnitRulesParam(unitID, "orbital_pending_direction", 0, PUBLIC)
    end

    local godrod = data.godrod
    spSetUnitRulesParam(unitID, "godrod_positioning", godrod and 1 or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "godrod_target_band", godrod and godrod.band or 0, PUBLIC)
    spSetUnitRulesParam(unitID, "godrod_target_direction",
        godrod and directionCode(godrod.direction) or 0, PUBLIC)
end

local function orbitalCmdDesc()
    return {
        id = CMD_ORBITAL_BAND,
        type = CMDTYPE.ICON_MAP,
        name = "Orbital band",
        action = "orbitalband",
        cursor = "Move",
        tooltip = "Choose a predictable ground-track band. Retasking is queued and only executed during orbital downtime."
    }
end

local function installBandCommand(unitID, defID)
    if defID == shrapnelDefID then return end
    if not Spring.FindUnitCmdDesc(unitID, CMD_ORBITAL_BAND) then
        Spring.InsertUnitCmdDesc(unitID, orbitalCmdDesc())
    end
end

local function setFlightPresentation(unitID, active)
    if not alive(unitID) then return end
    spSetUnitAlwaysVisible(unitID, true)
    spSetUnitBlocking(unitID, false, false, false)
    spSetUnitNeutral(unitID, false)
    showHideIconEnv(unitID, not active)
end

local function configureSatellite(unitID, data)
    spMoveCtrlEnable(unitID, true)
    makeOrbitPublic(unitID)
    spSetUnitBlocking(unitID, false, false, false)
    setGroundVision(unitID, data.utype, false)
    installBandCommand(unitID, data.utype)
end

local function beginFlight(unitID, data)
    data.state = "flying"
    data.timeoutRemaining = 0
    data.timeoutTotal = 0

    if data.pendingBand then
        data.band = data.pendingBand
        data.direction = data.pendingDirection
        data.pendingBand = nil
        data.pendingDirection = nil
    end

    local x, z = entryPosition(data.direction, data.band)
    spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
    setGroundVision(unitID, data.utype, true)
    setFlightPresentation(unitID, true)
    publish(unitID, data)
end

local function timeoutTarget(data)
    local direction = data.pendingDirection or data.direction
    local band = data.pendingBand or data.band
    return entryPosition(direction, band)
end

local function beginTimeout(unitID, data)
    if data.utype == shrapnelDefID then return end

    data.state = "timeout"
    data.timeoutSerial = (data.timeoutSerial or 0) + 1
    data.timeoutTotal = math.max(1, SatelliteTimeout[data.utype] or 1)
    data.timeoutRemaining = data.timeoutTotal

    local x, _, z = spGetUnitPosition(unitID)
    data.shiftStartX, data.shiftStartZ = x or 0, z or 0
    data.shiftTargetX, data.shiftTargetZ = timeoutTarget(data)

    setGroundVision(unitID, data.utype, false)
    setFlightPresentation(unitID, false)
    publish(unitID, data)
end

local function updateTimeoutTarget(data)
    if data.state ~= "timeout" then return end
    local x, z = timeoutTarget(data)
    data.shiftTargetX, data.shiftTargetZ = x, z
end

local function queueBand(unitID, x, z)
    local data = Satellites[unitID] or SatellitesWaiting[unitID]
    if not data or data.utype == shrapnelDefID then return false end
    if type(x) ~= "number" or type(z) ~= "number" then return false end

    local direction, band = closestBandForPoint(x, z)
    data.pendingDirection = direction
    data.pendingBand = band
    updateTimeoutTarget(data)
    publish(unitID, data)
    return true
end

local function flyingPosition(data, x, z)
    local speed = SatelliteSpeed[data.utype] or 0
    if data.direction == "vertical" then
        x = bandCoordinate("vertical", data.band)
        z = z + speed
    else
        x = x + speed
        z = bandCoordinate("horizontal", data.band)
    end
    return x, z
end

local function reachedExit(data, x, z)
    if data.direction == "vertical" then
        return z >= mapSizeZ - ENTRY_MARGIN
    end
    return x >= mapSizeX - ENTRY_MARGIN
end

local function updateTimeout(unitID, data)
    data.timeoutRemaining = math.max(0, (data.timeoutRemaining or 1) - 1)

    local elapsed = (data.timeoutTotal or 1) - data.timeoutRemaining
    local t = math.max(0, math.min(1, elapsed / math.max(1, data.timeoutTotal or 1)))
    local smooth = t * t * (3 - 2 * t)

    local tx, tz = timeoutTarget(data)
    data.shiftTargetX, data.shiftTargetZ = tx, tz
    local x = data.shiftStartX + (tx - data.shiftStartX) * smooth
    local z = data.shiftStartZ + (tz - data.shiftStartZ) * smooth

    spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)

    if data.timeoutRemaining <= 0 then
        beginFlight(unitID, data)
    elseif Spring.GetGameFrame() % 30 == 0 then
        publish(unitID, data)
    end
end

local function updateDebris(unitID, data)
    local x, _, z = spGetUnitPosition(unitID)
    if not x then return end

    x, z = flyingPosition(data, x, z)
    if data.direction == "vertical" and z >= mapSizeZ then
        z = ENTRY_MARGIN
    elseif data.direction == "horizontal" and x >= mapSizeX then
        x = ENTRY_MARGIN
    end

    spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
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
        data.band = sourceData.band
        data.pendingDirection = nil
        data.pendingBand = nil
        publish(cloudID, data)
    end
    return cloudID
end

local function sameActiveBand(a, b)
    return a and b and
        a.state == "flying" and b.state == "flying" and
        a.direction == b.direction and
        a.band == b.band
end

local function resolveAntiSatelliteStrike(parentID, childID, targetID)
    if not alive(parentID) or not alive(childID) or not alive(targetID) then
        return false
    end

    local parentData = Satellites[parentID]
    local targetData = Satellites[targetID]
    if not parentData or parentData.utype ~= antiDefID or
        not targetData or targetData.utype == shrapnelDefID or
        spGetUnitTeam(parentID) == spGetUnitTeam(targetID) or
        not sameActiveBand(parentData, targetData) then
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

    local direction, band = closestBandForPoint(x, z)
    data.pendingDirection = direction
    data.pendingBand = band
    updateTimeoutTarget(data)

    local needsSerial = (data.timeoutSerial or 0)
    if data.state ~= "timeout" then
        needsSerial = needsSerial + 1
    end

    data.godrod = {
        x = x,
        z = z,
        direction = direction,
        band = band,
        requiredTimeoutSerial = needsSerial
    }

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
        data.direction ~= target.direction or
        data.band ~= target.band then
        return false
    end

    local x, _, z = spGetUnitPosition(unitID)
    if not x then return false end

    local dropDistance =
        GameConfig.military.satellites.godRod.dropDistance or 50
    local alongTrackDistance =
        data.direction == "vertical" and math.abs(z - target.z) or
        math.abs(x - target.x)

    if alongTrackDistance <= dropDistance then
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
    local seed = ((ecmID or 0) * 131 + (nimrodID or 0) * 17 + victimTeamID * 7) % 997

    spSetTeamRulesParam(victimTeamID, "orbital_spoof_until", untilFrame, PRIVATE)
    spSetTeamRulesParam(victimTeamID, "orbital_spoof_seed", seed, PRIVATE)
end

function gadget:Initialize()
    gadgetHandler:RegisterCMDID(CMD_ORBITAL_BAND)

    GG.Orbital.QueueBand = queueBand
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
        GG.Orbital.QueueBand = nil
        GG.Orbital.RequestGodRodStrike = nil
        GG.Orbital.CanGodRodFire = nil
        GG.Orbital.ConsumeGodRodPositioning = nil
        GG.Orbital.ResolveAntiSatelliteStrike = nil
        GG.Orbital.SpoofDownlink = nil
    end
end

function gadget:UnitCreated(unitID, unitDefID)
    if not SatelliteTypes[unitDefID] then return end

    local direction, band = initialBand(unitID)
    local data = {
        utype = unitDefID,
        direction = direction,
        band = band,
        state = "waiting",
        timeoutSerial = 0
    }

    SatellitesWaiting[unitID] = data
    orbitalState[unitID] = data
    configureSatellite(unitID, data)
    publish(unitID, data)
    showHideIconEnv(unitID, true)
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
            spawnDebris(x, y, z, data)
        end
    end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams)
    if not SatelliteTypes[unitDefID] or unitDefID == shrapnelDefID then
        return true
    end

    if cmdID == CMD_ORBITAL_BAND then
        if cmdParams and #cmdParams >= 3 then
            queueBand(unitID, cmdParams[1], cmdParams[3])
        end
        return false
    end

    -- Direct movement would turn orbital control back into aircraft
    -- micromanagement. The only positional control is choosing a band.
    if cmdID == CMD.MOVE or cmdID == CMD.PATROL then
        return false
    end

    -- Observation and counter-satellites act on their selected band rather
    -- than on individually clicked targets. Godrod is the deliberate
    -- exception and keeps ground-target attack commands.
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
    local parentData = parentID and Satellites[parentID]
    local targetData = Satellites[targetID]
    local allowed = parentData and
        targetData and
        targetData.utype ~= shrapnelDefID and
        sameActiveBand(parentData, targetData)

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
            if frame % 30 == 0 then makeOrbitPublic(unitID) end
            local x, _, z = spGetUnitPosition(unitID)
            if x then
                x, z = flyingPosition(data, x, z)
                spMoveCtrlSetPosition(unitID, x, SatelliteAltitude[data.utype], z)
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
