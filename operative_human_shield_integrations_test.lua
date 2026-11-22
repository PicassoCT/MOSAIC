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
local held, alive, assigned, destroyed = {[10] = true},
    {[10] = true, [11] = true, [12] = true, [50] = true, [51] = true}, {}, {}
local transported, transportReads = {[12] = 51}, {}
local cityGG = {
    HumanShield = {IsHostage = function(id) return held[id] == true end},
    CivilianTable = {[10] = {startID = 50, defID = 2}, [11] = {startID = 50, defID = 2},
        [12] = {startID = 50, defID = 2}},
    UnitArrivedAtTarget = {[10] = true, [11] = true, [12] = true}, DisguiseCivilianFor = {},
}
local initialized, activities = 0, 0
local city = {
    GG = cityGG, gaiaTeamID = 0,
    GameConfig = {civilians = {activityStates = {started = 'started'}}},
    Spring = {
        ValidUnitID = function(id) return alive[id] ~= nil end,
        GetUnitIsDead = function(id) return alive[id] ~= true end,
        GetUnitTransporter = function(id)
            assert(type(id)=='number' and id==id,'only real numeric IDs reach the passenger query')
            transportReads[id]=(transportReads[id] or 0)+1
            return transported[id]
        end,
        UnitScript = {
            GetScriptEnv = function() return {startFleeing=function() activities=activities+1; return true end} end,
            CallAsUnit = function(_,fn,...) return fn(...) end,
        },
    },
    spGetUnitTeam = function() return 0 end,
    doesUnitExistAlive = function(id) return alive[id] == true end,
    packStep = function(pack) return pack end,
    travelInitialization = function(_, frame, pack)
        initialized = initialized + 1
        return true, frame + 30, pack
    end,
    giveWaypointsToUnit = function(id) assigned[id] = true end,
    civilianLife = {IsProtected = function() return false end},
    trafficActivities = {Cancel=function() end, Remove=function() end, Step=function() return false end},
    spDestroyUnit = function(id) destroyed[id], alive[id] = true, nil end,
}
local civilians = source('luarules/gadgets/game_civilians.lua')
local heldHelper = between(civilians, 'local function isCivilianPassenger(', 'function startInternalBehaviourOfState(')
local internal = between(civilians, 'function startInternalBehaviourOfState(', 'function callInternalFunction(')
local travel = between(civilians, 'function travellFunction(', 'function getTargetNodeInWalkingDistance(')
local arrivals = between(civilians, 'function issueArrivedUnitsCommands(', 'function decimateArrivedCivilians(')
local decimate = assert(civilians:match('(function decimateArrivedCivilians%([%s%S]-\nend)'))
run(heldHelper .. travel .. arrivals .. decimate .. '\n' .. internal .. '\npassenger = isCivilianPassenger', city)
assert(not city.passenger('10') and not city.passenger(0/0) and not city.passenger({}),
    'invalid IDs do not reach a native transporter query')
local pack = {unitID = 10, myTeam = 0, stuckCounter = 99, currPos = {0, 0, 0}}
pack.trafficRegistration=cityGG.CivilianTable[10]
local due, samePack = city.travellFunction(5, 100, pack, 0)
eq(due, 115, 'held traffic checks again without advancing its journey')
assert(samePack == pack and initialized == 0, 'held traffic skips ordinary initialization')
assert(pack.stuckCounter == 0 and pack.currPos == nil, 'stale stuck detection cannot kill a hostage')
eq(transportReads[10],nil,'known hostage ownership takes priority over the generic transport query')
local passengerPack={unitID=12,myTeam=0,stuckCounter=99,currPos={0,0,0}}
passengerPack.trafficRegistration=cityGG.CivilianTable[12]
due,samePack=city.travellFunction(6,100,passengerPack,0)
assert(due==115 and samePack==passengerPack and initialized==0,
    'ordinary truck rider retains a paused traffic journey')
assert(passengerPack.stuckCounter==0 and passengerPack.currPos==nil,
    'a truck rider is not classified as a stuck pedestrian')
assert(not city.startInternalBehaviourOfState(10,'startFleeing')
    and not city.startInternalBehaviourOfState(12,'startFleeing') and activities==0,
    'ambient reaction callbacks cannot seize either passenger animation')
city.issueArrivedUnitsCommands()
assert(not assigned[10] and not assigned[12] and assigned[11], 'arrival only redirects free civilians')
assert(cityGG.UnitArrivedAtTarget[10] and cityGG.UnitArrivedAtTarget[12]
    and not cityGG.UnitArrivedAtTarget[11], 'passenger arrivals survive for release or disembarking')
cityGG.UnitArrivedAtTarget[11] = true
city.decimateArrivedCivilians(10, {[2] = true})
assert(not destroyed[10] and not destroyed[12] and destroyed[11], 'population trimming preserves hostage and ordinary rider')
held[10] = nil
city.travellFunction(5, 115, pack, 0)
eq(initialized, 1, 'release resumes the ordinary traffic callback')
city.issueArrivedUnitsCommands()
assert(assigned[10], 'released arrival receives ordinary waypoints')
assert(cityGG.CivilianTable[10], 'civilian journey record survives captivity')
transported[12]=nil
city.travellFunction(6,115,passengerPack,0)
eq(initialized,2,'disembarking resumes the same ordinary traffic record')
city.issueArrivedUnitsCommands()
assert(assigned[12] and cityGG.CivilianTable[12] and not cityGG.UnitArrivedAtTarget[12],
    'disembarked civilian resumes waypoints without replacing or losing the journey record')
assert(city.startInternalBehaviourOfState(12,'startFleeing') and activities==1,
    'ordinary ambient reactions resume after disembarking')

print('PASS: Human Shield impact dispatch, disguise aliases, sniper exception, interrogation start/cancellation, traffic pause, arrival retention and population pruning')


-- Execute the real civilian filming entry points and animation lifecycle.
local civilianSource = source('scripts/civilianscript.lua')
local eligible, filmingFrames, stopped, cleared, shown, hidden = true, 0, 0, 0, 0, 0
local targetX, targetZ = 10, 20
local filmGG = {CivilianUnitInternalLogicActive={}, HumanShield={
    CanWitness=function(id, carrier) assert(id==40 and carrier==1); return eligible end,
}}
local filmEnv = {
    unitID=40, GG=filmGG, CMD={STOP=0}, bodyConfig={},
    GameConfig={civilians={activityStates={started='STARTED',ended='ENDED'}}},
    eAnimState={standing='standing'}, SIG_INTERNAL=128, cellphone1=5,
    NORMAL_WALK_SPEED=1, lowerBodyPieces={},
    paradeParticipation={Stop=function() end},
    Signal=function() end, SetSignalMask=function() end,
    setSpeedEnv=function() end, setOverrideAnimationState=function() end,
    getWalkingState=function() return 'walking' end,
    Hide=function() hidden=hidden+1 end, Show=function() shown=shown+1 end,
    queueEventThread=function() end, threadStateStarter=function() end,
    Spring={
        GetUnitPosition=function(id) assert(id==1); return targetX,0,targetZ end,
        GiveOrderToUnit=function(id,cmd) assert(id==40 and cmd==0); stopped=stopped+1 end,
        ClearUnitGoal=function(id) assert(id==40); cleared=cleared+1 end,
    },
    setCivilianUnitInternalStateMode=function(id,state,behaviour)
        filmGG.CivilianUnitInternalLogicActive[id]={state=state,behaviour=behaviour}
    end,
    PlayAnimation=function(name) assert(name=='UPBODY_FILMING'); return 3 end,
    frameToMs=function(frames) return frames*1000/30 end,
    setUnitRotationToPoint=function(id,x,y,z) assert(id==40 and x==targetX and z==targetZ) end,
    Sleep=function() coroutine.yield() end,
}
run(between(civilianSource,'function externalInterruptCivilian()','function canBeHumanShield()')
    .. between(civilianSource,'filmLocation = {}','wailingTime = 0')
    .. between(civilianSource,'function filmingLocation()','function throwArmsUp()'), filmEnv)
filmEnv.boolStartFleeing=true
assert(filmEnv.startFilmingHostage(1,200))
assert(not filmEnv.boolStartFleeing and stopped==1 and cleared==1, 'witness must stop fleeing and clear its move goal')
assert(filmEnv.isFilmingHostage(1,true) and not filmEnv.isFilmingHostage(1), 'pending request is not active filming')
filmEnv.boolStartFilming=false
local thread=coroutine.create(filmEnv.filmingLocation)
assert(coroutine.resume(thread)); assert(filmEnv.isFilmingHostage(1) and shown==1)
targetX,targetZ=30,40
assert(coroutine.resume(thread)); assert(coroutine.resume(thread))
assert(not filmEnv.isFilmingHostage(1,true) and hidden>=2, 'finished film must stop and hide phone')
assert(filmEnv.startFilmingHostage(1,10000)); filmEnv.boolStartFilming=false
thread=coroutine.create(filmEnv.filmingLocation); assert(coroutine.resume(thread))
eligible=false; assert(coroutine.resume(thread))
assert(coroutine.status(thread)=='dead' and not filmEnv.isFilmingHostage(1), 'lost/ranged-out carrier ends filming')
assert(not filmEnv.startFilmingHostage(1,10000), 'invalid witness rejected')
eligible=true; assert(filmEnv.startFilmingHostage(1,10000)); filmEnv.stopFilmingHostage()
assert(not filmEnv.isFilmingHostage(1,true), 'release cancels a queued film')
assert(filmEnv.startFilmLocation(5,0,5,200) and filmEnv.filmLocation.hostage==nil,
    'ordinary disaster filming is not a hostage witness')

-- Witnesses retain their journey and arrivals while their phone owns movement.
local witnessing=true
alive[11]=true; cityGG.CivilianTable[11]={startID=50,defID=2}
cityGG.HumanShield={IsHostage=function() return false end,IsWitness=function(id) return witnessing and id==11 end}
local witnessPack={unitID=11,myTeam=0,stuckCounter=99,currPos={0,0,0}}
witnessPack.trafficRegistration=cityGG.CivilianTable[11]
local beforeInit=initialized
city.travellFunction(7,200,witnessPack,0)
assert(initialized==beforeInit and witnessPack.stuckCounter==0 and witnessPack.currPos==nil)
assigned[11]=nil; cityGG.UnitArrivedAtTarget[11]=true
city.issueArrivedUnitsCommands(); assert(not assigned[11] and cityGG.UnitArrivedAtTarget[11])
witnessing=false; city.issueArrivedUnitsCommands(); assert(assigned[11])
print('PASS: real hostage filming, pending/active distinction, movement pause, expiry, interruption and ordinary filming')
