-- Run through run.sh against the game checkout with Lua 5.1+.
-- Exercise the actual impact/interrogation and city-traffic entry points. The
-- narrow chunks keep unrelated projectile setup and city generation out of the
-- fixture, while retaining the production functions and their side-effect order.
local compile = loadstring or load
local function source(path)
    local file = assert(io.open(path))
    local text = file:read('*a'):gsub('\r\n', '\n')
    file:close()
    return text
end
local function between(text, first, following)
    local a = assert(text:find(first, 1, true), first)
    local b = assert(text:find(following, a + #first, true), following)
    return text:sub(a, b - 1)
end
local function run(text, env)
    setmetatable(env, {__index = _G})
    if setfenv then return setfenv(assert(compile(text)), env)() end
    return assert(load(text, 'human shield integrations', 't', env))()
end
local function eq(actual, expected, message)
    assert(actual == expected, message .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected))
end

local protected = true
local effectCount, fireCount, cleanupCount, eventCount, interrogatorChecks = 0, 0, 0, 0, 0
local callback, eventPack
local shared = {
    DisguiseCivilianFor = {[101] = 1}, InterrogationTable = {},
    HumanShield = {IsProtected = function(id, team, weapon)
        return protected and id == 1 and team == 2 and weapon ~= 12
    end},
}
local impact = {
    GG = shared, gadget = {}, RaidExternalAbort = {}, houseTypeTable = {},
    spGetUnitTeam = function(id) return id == 20 and 2 or 1 end,
    doesUnitExistAlive = function() return true end,
    isEngagedInAnotherRaidAlready = function() return false end,
    isInterrogatingAttacker = function()
        interrogatorChecks = interrogatorChecks + 1
        return false
    end,
    UnitDamageFuncT = {
        [10] = function() effectCount = effectCount + 1 end,
        [12] = function() effectCount = effectCount + 1 end,
    },
    FireWeapons = {[10] = true},
    setUnitOnFire = function() fireCount = fireCount + 1 end,
    createStreamEvent = function(_, fn, _, pack)
        eventCount, callback, eventPack = eventCount + 1, fn, pack
    end,
    postInterrogationCleanUp = function(victim, interrogator)
        eq(victim, 1, 'cleanup victim'); eq(interrogator, 20, 'cleanup interrogator')
        cleanupCount = cleanupCount + 1
    end,
}
local impacts = source('luarules/gadgets/game_ProjectileImpacts.lua')
local protectionHelper = between(impacts, '    local function humanShieldProtects(', '    local MobileInterrogateAbleType')
local damageHandler = between(impacts, '    function gadget:UnitDamaged(', '    -- ===========Projectile Persistence Functions')
local interrogation = between(impacts, '   interrogationEventStreamFunction = function(', '    UnitDamageFuncT[stunpistoldWeaponDefID]')
run(protectionHelper .. damageHandler .. interrogation, impact)

-- Zero damage is not enough to suppress the existing scripted stun/fire paths.
impact.gadget:UnitDamaged(1, 1, 1, 0, true, 10, 999, 20, 4, 2)
eq(effectCount, 0, 'blocked zero-damage impact never dispatches a stun')
eq(fireCount, 0, 'blocked impact never sets the carrier on fire')
eq(interrogatorChecks, 0, 'blocked hit cannot abort a running interrogation first')
impact.gadget:UnitDamaged(101, 2, 0, 0, true, 10, 999, 20, 4, nil)
eq(effectCount, 0, 'disguise alias and attacker-team fallback preserve protection')
impact.gadget:UnitDamaged(1, 1, 1, 580, false, 12, 999, 20, 4, 2)
eq(effectCount, 1, 'sniper impact continues into existing handlers')
impact.gadget:UnitDamaged(1, 1, 1, 1, true, 10, 999, 30, 4, 3)
eq(effectCount, 2, 'other factions retain their original effects')
eq(fireCount, 1, 'non-Protagon fire remains active')

impact.interrogationEventStreamFunction(1, 1, 1, 0, true, 10, 20, 4, 2, 'interrogationIcon')
eq(eventCount, 0, 'protected operative cannot start interrogation')
assert(shared.InterrogationTable[1] == nil, 'blocked attempt creates no interrogation record')
protected = false
impact.interrogationEventStreamFunction(1, 1, 1, 0, true, 10, 20, 4, 2, 'interrogationIcon')
eq(eventCount, 1, 'ordinary interrogation starts normally')
protected = true
local done, returned = callback(eventPack)
assert(done and returned == eventPack, 'protection gained during an interrogation stops its event')
eq(cleanupCount, 1, 'interrupted interrogation runs the existing cleanup')
shared.HumanShield = nil
impact.gadget:UnitDamaged(1, 1, 1, 0, true, 10, 999, 20, 4, 2)
eq(effectCount, 3, 'impact behavior is unchanged when the ability gadget is absent')

-- A hostage must survive arrival, traffic pruning and social activity without
-- losing their traffic record. Release resumes the ordinary path next tick.
local held, alive, assigned, destroyed = {[10] = true}, {[10] = true, [11] = true, [50] = true}, {}, {}
local cityGG = {
    HumanShield = {IsHostage = function(id) return held[id] == true end},
    CivilianTable = {[10] = {startID = 50, defID = 2}, [11] = {startID = 50, defID = 2}},
    UnitArrivedAtTarget = {[10] = true, [11] = true}, DisguiseCivilianFor = {},
}
local initialized = 0
local city = {
    GG = cityGG, gaiaTeamID = 0,
    spGetUnitTeam = function() return 0 end,
    doesUnitExistAlive = function(id) return alive[id] == true end,
    packStep = function(pack) return pack end,
    travelInitialization = function(_, frame, pack)
        initialized = initialized + 1
        return true, frame + 30, pack
    end,
    giveWaypointsToUnit = function(id) assigned[id] = true end,
    civilianLife = {IsProtected = function() return false end},
    spDestroyUnit = function(id) destroyed[id], alive[id] = true, nil end,
}
local civilians = source('luarules/gadgets/game_civilians.lua')
local heldHelper = between(civilians, 'local function isHumanShieldHostage(', 'function startInternalBehaviourOfState(')
local travel = between(civilians, 'function travellFunction(', 'function getTargetNodeInWalkingDistance(')
local arrivals = between(civilians, 'function issueArrivedUnitsCommands(', 'function decimateArrivedCivilians(')
local decimate = assert(civilians:match('(function decimateArrivedCivilians%([%s%S]-\nend)'))
run(heldHelper .. travel .. arrivals .. decimate, city)
local pack = {unitID = 10, myTeam = 0, stuckCounter = 99, currPos = {0, 0, 0}}
local due, samePack = city.travellFunction(5, 100, pack, 0)
eq(due, 115, 'held traffic checks again without advancing its journey')
assert(samePack == pack and initialized == 0, 'held traffic skips ordinary initialization')
assert(pack.stuckCounter == 0 and pack.currPos == nil, 'stale stuck detection cannot kill a hostage')
city.issueArrivedUnitsCommands()
assert(not assigned[10] and assigned[11], 'arrival only redirects free civilians')
assert(cityGG.UnitArrivedAtTarget[10] and not cityGG.UnitArrivedAtTarget[11], 'held arrival survives for release')
cityGG.UnitArrivedAtTarget[11] = true
city.decimateArrivedCivilians(10, {[2] = true})
assert(not destroyed[10] and destroyed[11], 'population trimming preserves hostage')
held[10] = nil
city.travellFunction(5, 115, pack, 0)
eq(initialized, 1, 'release resumes the ordinary traffic callback')
city.issueArrivedUnitsCommands()
assert(assigned[10], 'released arrival receives ordinary waypoints')
assert(cityGG.CivilianTable[10], 'civilian journey record survives captivity')

print('PASS: Human Shield impact dispatch, disguise aliases, sniper exception, interrogation start/cancellation, traffic pause, arrival retention and population pruning')
