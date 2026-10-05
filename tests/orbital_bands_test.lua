-- Run from repository root: lua tests/orbital_bands_test.lua
-- Standalone regression coverage for the synced orbital band state machine.

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
    MOVE = 10,
    PATROL = 15,
    FIGHT = 16,
    ATTACK = 20,
    AREA_ATTACK = 21,
    GUARD = 25,
}
CMDTYPE = {ICON_MAP = 6}
CMD_ORBITAL_BAND = 33461

GG = {DiedPeacefully = {}, NooneParent = {}}
gadget = {}
gadgetHandler = {
    IsSyncedCode = function() return true end,
    RegisterCMDID = function() end,
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
    cmdDescs = {},
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
    FindUnitCmdDesc = function(id, cmd)
        return w.cmdDescs[id] and w.cmdDescs[id][cmd] and 1 or nil
    end,
    InsertUnitCmdDesc = function(id, desc)
        w.cmdDescs[id] = w.cmdDescs[id] or {}
        w.cmdDescs[id][desc.id] = desc
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

-- Initial constellation: ids 11 and 21 deliberately share horizontal band 1.
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

-- Completed satellites enter predictable flight and only scan owns ground LOS.
tick(1)
assert(w.rules[10].orbital_state == 1)
assert(w.rules[11].orbital_state == 1)
assert(w.rules[12].orbital_state == 1)
assert(w.sensors[10].los == 500, "scan satellite must provide ground LOS")
assert(w.sensors[11].los == 0 and w.sensors[12].los == 0,
    "non-observation satellites must not provide ground LOS")

-- Non-Godrod orbital control is band-only.
assert(gadget:AllowCommand(10, D.satellitescan, 1, CMD.MOVE, {1, 0, 1}) == false)
assert(gadget:AllowCommand(11, D.satelliteanti, 1, CMD.ATTACK, {21}) == false)
assert(gadget:AllowCommand(12, D.satellitegodrod, 1, CMD.ATTACK, {2000, 0, 2000}) == true)

-- Retasking queues during flight, applies only after a full timeout.
local oldBand = w.rules[10].orbital_band
gadget:AllowCommand(10, D.satellitescan, 1, CMD_ORBITAL_BAND, {5000, 0, 3000})
assert(w.rules[10].orbital_pending_band > 0)
assert(w.rules[10].orbital_band == oldBand)

-- Unit 10 begins in a vertical band. Force it to the exit to enter downtime.
w.units[10].z = 5999
tick(2)
assert(w.rules[10].orbital_state == 2)
assert(w.sensors[10].los == 0, "scan LOS must be off during orbital downtime")

for frame = 3, 6 do tick(frame) end
assert(w.rules[10].orbital_state == 1)
assert(w.sensors[10].los == 500)
assert(w.rules[10].orbital_pending_band == 0)

-- Godrod targeting publicly commits a band but cannot fire until a timeout.
assert(GG.Orbital.RequestGodRodStrike(12, 3000, 3000))
assert(w.rules[12].godrod_positioning == 1)
assert(not GG.Orbital.CanGodRodFire(12))

-- Force its current pass to end; the queued target band is applied after downtime.
local dir = w.rules[12].orbital_direction
if dir == 1 then w.units[12].z = 5999 else w.units[12].x = 5999 end
tick(7)
assert(w.rules[12].orbital_state == 2)
for frame = 8, 13 do tick(frame) end
assert(w.rules[12].orbital_state == 1)

-- Move along-track into the target window; cross-track is represented by the band.
dir = w.rules[12].orbital_direction
if dir == 1 then
    w.units[12].z = 3000
else
    w.units[12].x = 3000
end
local canFire, tx, _, tz = GG.Orbital.CanGodRodFire(12)
assert(canFire and tx == 3000 and tz == 3000)
GG.Orbital.ConsumeGodRodPositioning(12)
assert(w.rules[12].godrod_positioning == 0)

-- Same-band Noone counter-satellite acquisition is allowed and consumes its parent.
add(30, D.noone, 1, w.units[11].x, w.units[11].z)
GG.NooneParent[30] = 11
assert(gadget:AllowWeaponTarget(30, 21, 1, 1, 1) == true)
assert(GG.Orbital.ResolveAntiSatelliteStrike(11, 30, 21))
assert(w.units[21].dead and w.units[11].dead)

-- Destroying the target creates one neutral drifting debris cloud.
local debrisID
for id, u in pairs(w.units) do
    if u.defID == D.satelliteshrapnell and not u.dead then
        debrisID = id
        break
    end
end
assert(debrisID, "anti-satellite kill must create a debris cloud")
tick(14) -- finish debris creation and enter continuous drift
local dx0, dz0 = w.units[debrisID].x, w.units[debrisID].z
tick(15)
assert(w.units[debrisID].x ~= dx0 or w.units[debrisID].z ~= dz0,
    "debris cloud must continue drifting rather than parking")

-- Nimrod ECM spoofing is private team state with a finite expiry.
GG.Orbital.SpoofDownlink(1, 90, 91, 60)
assert(w.teamRules[1].orbital_spoof_until == 60)
assert(type(w.teamRules[1].orbital_spoof_seed) == "number")

print("orbital bands: tasking, downtime, visibility, Godrod, Noone, debris and spoofing PASS")
