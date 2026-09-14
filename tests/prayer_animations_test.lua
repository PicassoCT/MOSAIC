-- Run from the repository root: lua tests/prayer_animations_test.lua
local function read(path)
    local file = assert(io.open(path))
    local contents = file:read("*a")
    file:close()
    return contents
end

local function compile(source, env)
    setmetatable(env, {__index = _G})
    if setfenv then
        local fn = assert(loadstring(source))
        setfenv(fn, env)
        return fn
    end
    return assert(load(source, "test", "t", env))
end

local axisEnv = {x_axis = 1, y_axis = 2, z_axis = 3}
local prayers = compile(read("scripts/animations_civilian_prayers.lua"), axisEnv)()
local allowed = {Head1=true, UpBody=true, UpArm1=true, UpArm2=true,
                 LowArm1=true, LowArm2=true}
assert(prayers.name(nil) == "UPBODY_PRAYER_1")
assert(prayers.name(9) == "UPBODY_PRAYER_1")

for _, script in ipairs({"civilianscript.lua", "civilianagentscript.lua"}) do
    local animations = compile(read("scripts/animations_civilian_female.lua"), axisEnv)()
    prayers.register(animations)
    local selected, originalAxes, map, offsets = {}, {}, {}, {}
    local nextID = 1
    for name in pairs(allowed) do
        map[name] = nextID
        offsets[nextID] = {0,0,0}
        nextID = nextID + 1
    end
    map.center = nextID
    for index = 1, 8 do
        local name = prayers.name(index)
        local animation = assert(animations[name])
        selected[name] = animation
        assert(#animation > 1)
        for _, frame in ipairs(animation) do
            for _, cmd in ipairs(frame.commands) do
                assert(cmd.c == "turn" and allowed[cmd.p], "non-upper-body prayer command")
                originalAxes[cmd] = cmd.a
            end
        end
    end
    -- Existing prayer was copied, rather than aliased/mutated twice in setup.
    assert(animations.UPBODY_PRAY[1].commands[1].c == "move")
    local src = read("scripts/" .. script)
    local setup = assert(src:match("(function setupAnimation%(%).-)local animCmd"))
    local env = {Animations=selected, map=map, unitID=1, x_axis=1, y_axis=2, z_axis=3,
        constructSkeleton=function() return offsets end}
    compile(setup .. "\nsetupAnimation()", env)()
    for cmd, sourceAxis in pairs(originalAxes) do
        local expected = ({1,3,2})[sourceAxis]
        assert(cmd.a == expected, script .. ": wrong axis conversion")
        assert(type(cmd.p) == "number")
    end
    -- Execute the real script entry point and prayer loop for every index.
    local entry = assert(src:match("(local prayerAnimationName = .-)\nboolStartAnarchyBehaviour"))
    for index = 1, 8 do
        local frame, played, queued = 0, 0, 0
        local e = {PrayerAnimations=prayers, unitID=1, NORMAL_WALK_SPEED=1,
            GG={CivilianUnitInternalLogicActive={}}, GameConfig={STATE_STARTED=1,STATE_ENDED=2},
            upperBodyPieces={}, Signal=function() end, SetSignalMask=function() end,
            StartThread=function() end, WaitForTurns=function() end,
            -- This test executes pray() directly below; dispatch is covered
            -- by event_thread_optimizations_test.lua.
            queueEventThread=function(key, handler, delay)
                assert(key == "behaviour" and delay == 250)
                queued = queued + 1
            end,
            resetUpperBodyNoTPose=function() end,
            getPrayDurationInFrames=function() return 900 end,
            Spring={GetGameFrame=function() return frame end},
            Sleep=function(ms) frame=frame+ms*30/1000 end,
            PlayAnimation=function(name, filter)
                assert(name == prayers.name(index) and filter == nil)
                frame=frame+200; played=played+1
            end}
        e.setSpeedEnv=function(_, speed) e.speed=speed end
        e.setCivilianUnitInternalStateMode=function(id, state, behaviour)
            e.GG.CivilianUnitInternalLogicActive[id]={state=state,behaviour=behaviour}
        end
        compile(entry, e)()
        assert(e.startPraying(index))
        assert(queued == 1, "prayer request was not dispatched")
        e.pray() -- no Move/Turn/SetUnitRotation mocks: forbidden calls fail.
        assert(played > 0 and frame >= 900 and e.speed == 1)
        assert(e.GG.CivilianUnitInternalLogicActive[1].state == 2)
    end
end

-- Real call-selection block: unordered filenames, empty directories, skipped
-- windows, repeated frames, and subsequent days must keep sound/index aligned.
local sunshine = read("luarules/gadgets/game_sunshine.lua")
local selection = assert(sunshine:match("(    local prayerCalls = {}.-)    %-%- set the sun"))
for _, culture in ipairs({"arabic", "international"}) do
    for _, empty in ipairs({false, true}) do
        local slot, roll, sounds = 0, 10, {}
        local e = {GameConfig={instance={culture=culture}}, GG={},
            getPrayerSlot=function() return slot end,
            VFS={DirList=function()
                if empty then return {} end
                return {"sounds/civilian/"..culture.."/callToPrayer8.ogg",
                        "sounds/civilian/"..culture.."/traffic.ogg",
                        "sounds/civilian/"..culture.."/callToPrayer2.ogg"}
            end},
            math={random=function(_, high) if high==10 then return roll end; return 1 end},
            Spring={PlaySoundFile=function(path) sounds[#sounds+1]=path end}}
        local update = compile(selection .. "\nreturn updatePrayerCall", e)()
        update(1); update(32)
        if empty then
            assert(#sounds == 0 and e.GG.ActivePrayerCall == nil)
        else
            assert(#sounds == 1 and e.GG.ActivePrayerCall.index == 2)
            assert(sounds[1]:match("callToPrayer2%.ogg$"))
            slot=nil; update(64); assert(e.GG.ActivePrayerCall == nil)
            slot=1; roll=1; update(96); roll=10; update(128)
            assert(#sounds == 1 and e.GG.ActivePrayerCall == nil)
            slot=2; update(160)
            assert(#sounds == 2 and e.GG.ActivePrayerCall.slot == 2)
        end
    end
end
print("Prayer animations: upper-body restriction, both axis conversions, 8 indices, cleanup and call selection passed")
