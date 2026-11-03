-- Run from the game root: lua tests/civilian_parade_test.lua
-- Real script entry points and queue helper under a deterministic coroutine
-- scheduler exercise cancellation, ownership and moving prayer participation.
local function read(path)
    local file = assert(io.open(path)); local source = file:read("*a"); file:close()
    return source
end
local function run(source, env)
    setmetatable(env, {__index = _G})
    if setfenv then return setfenv(assert(loadstring(source)), env)() end
    return assert(load(source, "parade test", "t", env))()
end
local function overlaps(a, b)
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then return true end
        a, b = math.floor(a / 2), math.floor(b / 2)
    end
    return false
end
local function runtime(env)
    local now, current, threads = 0, nil, {}
    local function resume(thread, ...)
        local previous = current; current = thread
        local ok, wait = coroutine.resume(thread.co, ...)
        current = previous
        assert(ok, wait)
        if coroutine.status(thread.co) == "dead" then thread.dead = true
        else thread.wake = now + math.max(1, wait or 1) end
    end
    env.StartThread = function(action, ...)
        local thread = {mask = current and current.mask or 0, co = coroutine.create(action)}
        threads[#threads + 1] = thread
        resume(thread, ...)
    end
    env.Sleep = function(ms) return coroutine.yield(ms) end
    env.SetSignalMask = function(mask) assert(current); current.mask = mask end
    env.Signal = function(mask)
        for _, thread in ipairs(threads) do
            if overlaps(thread.mask, mask) then thread.dead = true end
        end
    end
    return function(milliseconds)
        for _ = 1, milliseconds do
            now = now + 1
            local count = #threads
            for index = 1, count do
                local thread = threads[index]
                if not thread.dead and thread.wake <= now then resume(thread) end
            end
        end
    end
end

for _, path in ipairs({"scripts/civilianscript.lua", "scripts/civilianagentscript.lua"}) do
    local source = read(path)
    local plays, restores, selected, transported = 0, 0, nil, false
    local env = {unitID = 51, gaiaTeamID = 0, SIG_PARADE = 1024,
        GameConfig = {game = {states = {normal = "normal"}},
            civilians = {activityStates = {started = 1, ended = 2}}},
        GG = {GlobalGameState = "normal", CivilianUnitInternalLogicActive = {}},
        bodyConfig = {}, damagedCoolDown = 0, boolWalking = false,
        PrayerAnimations = {name = function(index) return "UPBODY_PRAYER_" .. tostring(index or 1) end},
        upperBodyPieces = {}, eAnimState = {walking = "walking", standing = "standing"},
        getWalkingState = function() return "walking" end,
        spGetUnitTeam = function() return 0 end,
        Spring = {GetUnitTransporter = function() return transported end},
        WaitForTurns = function() end,
        resetUpperBodyNoTPose = function() end,
        animationStateMachineUpper = function() end,
        -- No speed/order APIs are provided: using either from the pose fails.
        setOverrideAnimationState = function(upper, lower)
            restores = restores + 1
            assert(upper == lower, "cleanup must restore ordinary whole-body animation")
            selected = lower
        end}
    local advance = runtime(env)
    env.PlayAnimation = function(name)
        plays = plays + 1; selected = name
        env.Sleep(120)
    end
    env.queueEventThread = run(read("scripts/lib_event_threads.lua"), env)
    env.newParadeParticipation = run(read("scripts/lib_civilian_parade.lua"), env)
    run(assert(source:match("(local prayerAnimationName = .-)\nboolStartAnarchyBehaviour")), env)
    run(assert(source:match("(function setCivilianUnitInternalStateMode%(.-\nend)")), env)

    -- A citizen can be released before the asynchronously queued pose starts.
    assert(env.startParadeParticipation(3))
    assert(env.GG.CivilianUnitInternalLogicActive[51].behaviour == "parade" and plays == 0)
    assert(env.stopParadeParticipation())
    advance(20)
    assert(plays == 0 and restores == 1)
    assert(not env.stopParadeParticipation())

    -- Followers retain their walking state and get the same religious gesture.
    env.boolWalking = true
    assert(env.startParadeParticipation(5))
    advance(20)
    assert(plays == 1 and selected == "UPBODY_PRAYER_5")
    assert(env.stopParadeParticipation())
    assert(selected == "walking" and restores == 2)
    advance(500)
    assert(plays == 1, "stopped follower continued posing")

    -- Fleeing and aerosol states take ownership immediately. Later stop calls
    -- must not clear their state or replace their animation with a parade idle.
    assert(env.startParadeParticipation(4))
    advance(20)
    env.setCivilianUnitInternalStateMode(51, 1, "fleeing")
    local fleeing = env.GG.CivilianUnitInternalLogicActive[51]
    local previousPlays, previousRestores = plays, restores
    assert(fleeing.behaviour == "fleeing")
    assert(not env.stopParadeParticipation())
    advance(500)
    assert(plays == previousPlays and restores == previousRestores)
    assert(env.GG.CivilianUnitInternalLogicActive[51] == fleeing)
    assert(not env.startParadeParticipation(1), "busy civilian joined the parade")

    env.GG.CivilianUnitInternalLogicActive[51] = nil
    assert(env.startParadeParticipation(6))
    advance(20)
    local aerosol = {state = 1, behaviour = "aerosol"}
    env.GG.CivilianUnitInternalLogicActive[51] = aerosol
    assert(env.stopParadeParticipation())
    advance(500)
    assert(env.GG.CivilianUnitInternalLogicActive[51] == aerosol and restores == previousRestores)

    -- Script-side eligibility backs up the gadget's healthy/ambient checks.
    env.GG.CivilianUnitInternalLogicActive[51] = nil
    for _, key in ipairs({"boolArmed", "boolInfluenced", "boolWounded", "boolCoverWalk", "boolLoaded"}) do
        env.bodyConfig[key] = true
        assert(not env.startParadeParticipation(2), key .. " civilian was recruited")
        env.bodyConfig[key] = false
    end
    transported = 12
    assert(not env.startParadeParticipation(2))
    transported = false
    env.GG.GlobalGameState = "anarchy"
    assert(not env.startParadeParticipation(2))
    env.GG.GlobalGameState = "normal"

    -- Even if the gadget misses a release, normal-city eligibility ends the
    -- gesture coroutine and releases its own internal travel lock.
    assert(env.startParadeParticipation(8))
    advance(20)
    env.GG.GlobalGameState = "anarchy"
    advance(500)
    assert(env.GG.CivilianUnitInternalLogicActive[51].state == 2)
    assert(restores == previousRestores + 1)
end

print("PASS: both civilian parade APIs, religious follower poses, cancellation, emergency ownership and eligibility")
