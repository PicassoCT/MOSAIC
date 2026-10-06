-- Run from repository root: lua tests/orbital_bands_test.lua
-- Regression coverage for directly steered continuous orbital tracks.

local D = {
    satellitescan = 1,
    satelliteanti = 2,
    satellitegodrod = 3,
    satelliteshrapnell = 4,
    noone = 5,
}

UnitDefNames = {}
UnitDefs = {}
for name, id in pairs(D) do
    UnitDefNames[name] = {id = id}
    UnitDefs[id] = {
        id = id,
        name = name,
        sightDistance = name == "satellitescan" and 500 or 0,
        losRadius = name == "satellitescan" and 500 or 0,
    }
end

Game = {mapSizeX = 6000, mapSizeZ = 6000, gravity = 0.1}
CMD = {
    STOP = 0,
    MOVE = 10,
    PATROL = 15,
    FIGHT = 16,
    ATTACK = 20,
    AREA_ATTACK = 21,
    GUARD = 25,
}

GG = {DiedPeacefully = {}, NooneParent = {}}
gadget = {}
gadgetHandler = {
    IsSyncedCode = function() return true end,
}
VFS = {Include = function() end}

function getOrbitalTypes()
    return {
        [D.satellitescan] = true,
        [D.satelliteanti] = true,
        [D.satellitegodrod] = true,
        [D.satelliteshrapnell] = true,
    }
end

function getSatelliteTypesSpeedTable()
    return {
        [D.satellitescan] = 3,
        [D.satelliteanti] = 1,
        [D.satellitegodrod] = 1,
        [D.satelliteshrapnell] = 4,
    }
end

function getSatelliteAltitudeTable()
    return {
        [D.satellitescan] = 1500,
        [D.satelliteanti] = 1550,
        [D.satellitegodrod] = 1450,
        [D.satelliteshrapnell] = 1500,
    }
end

function getSatelliteTimeOutTable()
    return {
        [D.satellitescan] = 4,
        [D.satelliteanti] = 5,
        [D.satellitegodrod] = 6,
        [D.satelliteshrapnell] = 1,
    }
end

function getGameConfig()
    return {
        military = {
            satellites = {
                godRod = {dropDistance = 50},
            },
        },
    }
end

local w = {
    units = {},
    rules = {},
    teamRules = {},
    sensors = {},
    frame = 0,
    nextID = 100,
}

local function add(id, defID, team, x, z)
    w.units[id] = {
        defID = defID,
        team = team,
        x = x or 1000,
        y = 0,
        z = z or 1000,
        dead = false,
    }
    return id
end

function doesUnitExistAlive(id)
    return w.units[id] ~= nil and not w.units[id].dead
end

function showHideIconEnv() end

Spring = {
    GetGaiaTeamID = function() return 0 end,
    GetAllyTeamList = function() return {0, 1, 2} end,
    GetAllUnits = function()
        local ids = {}
        for id, u in pairs(w.units) do
            if not u.dead then ids[#ids + 1] = id end
        end
        table.sort(ids)
        return ids
    end,
    GetUnitDefID = function(id)
        return w.units[id] and w.units[id].defID
    end,
    GetUnitTeam = function(id)
        return w.units[id] and w.units[id].team
    end,
    AreTeamsAllied = function(a, b) return a == b end,
    GetUnitPosition = function(id)
        local u = w.units[id]
        if u then return u.x, u.y, u.z end
    end,
    GetUnitHealth = function(id)
        if w.units[id] then return 500, 500, 0, 0, 1 end
    end,
    GetGameFrame = function() return w.frame end,
    GetGroundHeight = function() return 0 end,
    SetUnitAlwaysVisible = function() end,
    SetUnitNeutral = function() end,
    SetUnitBlocking = function() end,
    SetUnitLosState = function() end,
    SetUnitSensorRadius = function(id, kind, radius)
        w.sensors[id] = w.sensors[id] or {}
        w.sensors[id][kind] = radius
        return radius
    end,
    SetUnitRulesParam = function(id, key, value)
        w.rules[id] = w.rules[id] or {}
        w.rules[id][key] = value
    end,
    GetUnitRulesParam = function(id, key)
        return w.rules[id] and w.rules[id][key]
    end,
    SetTeamRulesParam = function(team, key, value)
        w.teamRules[team] = w.teamRules[team] or {}
        w.teamRules[team][key] = value
    end,
    MoveCtrl = {
        Enable = function() end,
        SetPosition = function(id, x, y, z)
            local u = assert(w.units[id])
            u.x, u.y, u.z = x, y, z
        end,
    },
    CreateUnit = function(name, x, y, z, facing, team)
        w.nextID = w.nextID + 1
        local id = add(w.nextID, assert(D[name]), team, x, z)
        w.units[id].y = y or 0
        if gadget.UnitCreated then
            gadget:UnitCreated(id, w.units[id].defID, team)
        end
        return id
    end,
    DestroyUnit = function(id)
        local u = assert(w.units[id], "destroying missing unit")
        if u.dead then return end
        u.dead = true
        if gadget.UnitDestroyed then
            gadget:UnitDestroyed(id, u.defID, u.team)
        end
    end,
}

-- IDs deliberately give scan/Godrod vertical courses and both anti/target
-- horizontal courses. Positions are replaced with orbital entry points at tick 1.
add(10, D.satellitescan, 1, 1000, 1000)
add(11, D.satelliteanti, 1, 1000, 1000)
add(12, D.satellitegodrod, 1, 1000, 1000)
add(21, D.satellitescan, 2, 1000, 1000)

assert(loadfile("luarules/gadgets/game_sattelite.lua"))()
gadget:Initialize()

local function tick(frame)
    w.frame = frame
    gadget:GameFrame(frame)
end

tick(1)
assert(w.rules[10].orbital_state == 1)
assert(w.rules[11].orbital_state == 1)
assert(w.rules[12].orbital_state == 1)
assert(w.sensors[10].los == 500, "scan satellite must provide ground LOS")
assert(w.sensors[11].los == 0 and w.sensors[12].los == 0,
    "non-observation satellites must not provide ground LOS")
assert(w.rules[10].orbital_track and not w.rules[10].orbital_band,
    "continuous track state must replace numbered bands")

-- The satellite itself is the control surface. A normal MOVE click is consumed
-- as an orbital steering order and must visibly start changing course at once.
local x0 = w.units[10].x
local targetX = x0 < 4000 and x0 + 1000 or x0 - 1000
assert(gadget:AllowCommand(
    10, D.satellitescan, 1, CMD.MOVE, {targetX, 0, 3000}
) == false)
assert(math.abs(w.rules[10].orbital_target_track - targetX) < 0.01)
tick(2)
local x1 = w.units[10].x
assert(x1 ~= x0, "course change must be visible on the next simulation frame")
assert(math.abs(targetX - x1) < math.abs(targetX - x0),
    "satellite must slew toward the clicked ground track")
assert(math.abs(targetX - x1) > 10,
    "course changes must remain slow rather than snapping to the click")

-- Exiting the map keeps the current downtime visual, and a new MOVE during
-- downtime bends the re-entry path immediately.
w.units[10].z = 5999
tick(3)
assert(w.rules[10].orbital_state == 2)
assert(w.sensors[10].los == 0, "scan LOS must be off during orbital downtime")

local targetX2 = targetX < 3000 and 4200 or 1800
gadget:AllowCommand(
    10, D.satellitescan, 1, CMD.MOVE, {targetX2, 0, 3500}
)
assert(math.abs(w.rules[10].orbital_target_track - targetX2) < 0.01)
for frame = 4, 7 do tick(frame) end
assert(w.rules[10].orbital_state == 1)
assert(w.sensors[10].los == 500)
assert(math.abs(w.units[10].x - targetX2) < 0.01,
    "downtime must finish at the continuously requested track")

-- Old-style edge steering remains graspable: while travelling vertically,
-- clicking the left/right map edge visibly slews toward it and requests a
-- horizontal course after the next downtime. There are no H1/V4 abstractions.
gadget:AllowCommand(
    10, D.satellitescan, 1, CMD.MOVE, {10, 0, 4200}
)
assert(w.rules[10].orbital_pending_direction == 2)
assert(math.abs(w.rules[10].orbital_pending_track - 4200) < 0.01)
w.units[10].z = 5999
tick(8)
for frame = 9, 12 do tick(frame) end
assert(w.rules[10].orbital_state == 1)
assert(w.rules[10].orbital_direction == 2)
assert(math.abs(w.units[10].z - 4200) < 0.01)

-- Godrod targeting begins a visible continuous slew immediately but still
-- requires one complete downtime before the committed strike can occur.
assert(GG.Orbital.RequestGodRodStrike(12, 3000, 3000))
assert(w.rules[12].godrod_positioning == 1)
assert(math.abs(w.rules[12].godrod_target_track - 3000) < 0.01)
assert(not GG.Orbital.CanGodRodFire(12))

w.units[12].z = 5999
tick(13)
assert(w.rules[12].orbital_state == 2)
for frame = 14, 19 do tick(frame) end
assert(w.rules[12].orbital_state == 1)
w.units[12].z = 3000
local canFire, tx, _, tz = GG.Orbital.CanGodRodFire(12)
assert(canFire and tx == 3000 and tz == 3000)
GG.Orbital.ConsumeGodRodPositioning(12)
assert(w.rules[12].godrod_positioning == 0)

-- Clicking a hostile satellite with the interceptor is a normal ATTACK gesture.
-- It continuously steers toward the target's track and adjusts along-track speed.
local antiZ0 = w.units[11].z
local targetZ = w.units[21].z
assert(gadget:AllowCommand(
    11, D.satelliteanti, 1, CMD.ATTACK, {21}
) == false)
tick(20)
assert(math.abs(w.units[11].z - targetZ) < math.abs(antiZ0 - targetZ),
    "interceptor must visibly converge onto the target course")

-- Merely sharing an abstract band is no longer enough: the vehicles must be
-- physically close while travelling in the same direction.
add(30, D.noone, 1, w.units[11].x, w.units[11].z)
GG.NooneParent[30] = 11
assert(gadget:AllowWeaponTarget(30, 21, 1, 1, 1) == false)

w.units[21].x = w.units[11].x + 80
w.units[21].z = w.units[11].z + 40
assert(gadget:AllowWeaponTarget(30, 21, 1, 1, 1) == true)
assert(GG.Orbital.ResolveAntiSatelliteStrike(11, 30, 21))
assert(w.units[21].dead and w.units[11].dead)

-- The target kill still creates a neutral drifting debris cloud.
local debrisID
for id, u in pairs(w.units) do
    if u.defID == D.satelliteshrapnell and not u.dead then
        debrisID = id
        break
    end
end
assert(debrisID, "anti-satellite kill must create a debris cloud")
tick(21)
local dx0, dz0 = w.units[debrisID].x, w.units[debrisID].z
tick(22)
assert(w.units[debrisID].x ~= dx0 or w.units[debrisID].z ~= dz0,
    "debris cloud must continue drifting rather than parking")

-- Nimrod ECM remains private team state and suppresses only the victim's scan
-- feed; the physical contact remains public.
GG.Orbital.SpoofDownlink(1, 90, 91, 40)
assert(w.teamRules[1].orbital_spoof_until == 40)
assert(type(w.teamRules[1].orbital_spoof_seed) == "number")
tick(30)
assert(w.sensors[10].los == 0,
    "spoofed Nimrod must suppress the victim's true scan feed")
tick(60)
assert(w.sensors[10].los == 500,
    "scan feed must recover after ECM leaves and spoof expires")

print("orbital tracks: direct steering, downtime, interception, Godrod, debris and spoofing PASS")
