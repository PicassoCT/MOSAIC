include "lib_Animation.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}

local rotor = piece("Rotor")

local GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(
    GameConfig.instance.culture,
    "civilian",
    UnitDefs
)

-- Tuning -------------------------------------------------------------

local SCAN_RADIUS = 1024

-- Where the hologram should stop relative to the citizen.
local HOLOGRAM_HEIGHT_ABOVE_CIVILIAN = 180

-- Used when no civilian is nearby.
local RANDOM_MIN_RADIUS = 256
local RANDOM_MAX_RADIUS = 900
local RANDOM_HOLOGRAM_HEIGHT = 220

-- Projection movement.
local PROJECTOR_SPEED = 150
local PROJECTION_REFRESH_MS = 3750

-- If your model's projection axis is reversed, set this to -1.
local PROJECTOR_FORWARD_SIGN = 1

-- If your Rotor piece is authored with an offset direction, adjust these.
local PROJECTOR_YAW_OFFSET = 0
local PROJECTOR_PITCH_OFFSET = 0

-- Clamp so the projector does not aim upward or fold through the zeppelin.
local MIN_PITCH = math.rad(-88)
local MAX_PITCH = math.rad(-5)

local TAU = math.pi * 2
local atan2 = math.atan2 or function(y, x)
    return math.atan(y, x)
end

-----------------------------------------------------------------------

function script.HitByWeapon(x, z, weaponDefID, damage)
end

local function tableIsEmpty(t)
    return t == nil or next(t) == nil
end

local function clamp(v, low, high)
    if v < low then return low end
    if v > high then return high end
    return v
end

local function normalizeAngle(a)
    while a > math.pi do a = a - TAU end
    while a < -math.pi do a = a + TAU end
    return a
end

local function getRandomUnitID(t)
    if tableIsEmpty(t) then
        return nil
    end

    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end

    local selected = math.random(1, count)
    for k, v in pairs(t) do
        selected = selected - 1

        if selected == 0 then
            -- Supports both:
            -- { [unitID] = true }
            -- and:
            -- { unitID1, unitID2, unitID3 }
            if type(v) == "number" then
                return v
            end

            if type(k) == "number" then
                return k
            end

            return nil
        end
    end

    return nil
end

local function getUnitWorldYaw(id)
    local dx, _, dz = Spring.GetUnitDirection(id)

    if dx and dz and (dx * dx + dz * dz) > 0.0001 then
        return atan2(dx, dz)
    end

    -- Fallback. Usually not needed, but useful if GetUnitDirection fails.
    local heading = Spring.GetUnitHeading(id) or 0
    return heading * TAU / 65536
end

local function getCivilianProjectionTarget(scanCenterID)
    local civiliansNearby = getAllOfTypeNearUnit(
        scanCenterID,
        civilianWalkingTypeTable,
        SCAN_RADIUS
    )

    if tableIsEmpty(civiliansNearby) then
        return nil
    end

    local civID = getRandomUnitID(civiliansNearby)
    if not civID then
        return nil
    end

    local x, y, z = Spring.GetUnitPosition(civID)
    if not x then
        return nil
    end

    return x, y + HOLOGRAM_HEIGHT_ABOVE_CIVILIAN, z, civID
end

local function getRandomProjectionTarget(sourceID)
    local sx, sy, sz = Spring.GetUnitPosition(sourceID)
    if not sx then
        return nil
    end

    local angle = math.random() * TAU
    local radius = math.random(RANDOM_MIN_RADIUS, RANDOM_MAX_RADIUS)

    local x = sx + math.sin(angle) * radius
    local z = sz + math.cos(angle) * radius
    local groundY = Spring.GetGroundHeight(x, z) or sy

    return x, groundY + RANDOM_HOLOGRAM_HEIGHT, z, nil
end

local function aimRotorAtWorldPoint(sourceID, tx, ty, tz)
    local sx, sy, sz = Spring.GetUnitPosition(sourceID)
    if not sx then
        return nil
    end

    local dx = tx - sx
    local dy = ty - sy
    local dz = tz - sz

    local horizontalDistance = math.sqrt(dx * dx + dz * dz)
    if horizontalDistance < 1 then
        return nil
    end

    local worldYaw = atan2(dx, dz)
    local sourceYaw = getUnitWorldYaw(sourceID)

    -- This is the important part:
    -- world target yaw minus current zeppelin/projection-unit yaw.
    -- Therefore the hologram stays aimed in world space even if the unit rotates.
    local localYaw = normalizeAngle(worldYaw - sourceYaw + PROJECTOR_YAW_OFFSET)

    -- Negative pitch means "aim down" for the usual Spring piece convention.
    local pitch = atan2(dy, horizontalDistance) + PROJECTOR_PITCH_OFFSET
    pitch = clamp(pitch, MIN_PITCH, MAX_PITCH)

    Turn(rotor, y_axis, localYaw, math.rad(180))
    Turn(rotor, x_axis, pitch, math.rad(180))

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance
end

local function waitForTransporter()
    local transporterID = Spring.GetUnitTransporter(unitID)

    while not transporterID do
        Sleep(1000)
        transporterID = Spring.GetUnitTransporter(unitID)
    end

    return transporterID
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    hideAll(unitID)

    StartThread(rotatedTowardsProjection)
end

function rotatedTowardsProjection()
    local transporterID = waitForTransporter()

    while true do
        transporterID = Spring.GetUnitTransporter(unitID) or transporterID

        -- Use the transporter as the scan center if available.
        -- Use this unit as the aiming frame, because its pieces belong to this script.
        local scanCenterID = transporterID or unitID
        local sourceID = unitID

        local tx, ty, tz, civID = getCivilianProjectionTarget(scanCenterID)

        if not tx then
            tx, ty, tz = getRandomProjectionTarget(scanCenterID)
        end

        hideAll(unitID)
        resetT(TablesOfPiecesGroups)

        local selectedPiece = nil
        if TablesOfPiecesGroups["adds"] then
            selectedPiece = showOnePiece(TablesOfPiecesGroups["adds"])
        end

        if selectedPiece and tx then
            Move(selectedPiece, z_axis, 0, 0)

            local distance = aimRotorAtWorldPoint(sourceID, tx, ty, tz)

            if distance then
                -- The hologram travels along the projector axis and stops
                -- at the calculated world-space target point above the citizen.
                WMove(
                    selectedPiece,
                    z_axis,
                    distance * PROJECTOR_FORWARD_SIGN,
                    PROJECTOR_SPEED
                )
            end
        end

        Sleep(PROJECTION_REFRESH_MS)
    end
end