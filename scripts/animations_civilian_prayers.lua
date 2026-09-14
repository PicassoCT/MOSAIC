-- Register before setupAnimation(): these are SOURCE/Blender axes, just like
-- animations_civilian_female.lua. The existing setup swaps Y/Z exactly once.
-- X = forward bend; source Y becomes engine Z (arm spread); source Z becomes
-- engine Y (twist). Never issue engine-axis turns from this data file.
local PrayerAnimations = {}
local sourceAxes = {x_axis, y_axis, z_axis}
local pieces = {"Head1", "UpBody", "UpArm1", "UpArm2", "LowArm1", "LowArm2"}
local allowed = {}
for _, name in ipairs(pieces) do allowed[name] = true end

-- Each pose is {forward bend, spread, twist}, in degrees, on source axes.
-- Hands are part of the forearm meshes; this rig has no finger/hand joints.
local function pose(time, values)
    local commands = {}
    for _, name in ipairs(pieces) do
        local angles = values[name] or {0, 0, 0}
        for axis, value in ipairs(angles) do
            commands[#commands + 1] = {
                c = "turn", p = name, a = sourceAxes[axis], t = math.rad(value), s = 0.8,
            }
        end
    end
    return {time = time, commands = commands}
end

local function arms(head, torso, shoulder, spread, elbow, twist)
    return {
        Head1 = {head, 0, 0}, UpBody = {torso, 0, 0},
        UpArm1 = {shoulder, -spread, 0}, UpArm2 = {shoulder, spread, 0},
        LowArm1 = {elbow, 0, twist}, LowArm2 = {elbow, 0, -twist},
    }
end

local function cycle(first, second, third)
    return {pose(0, first), pose(45, second), pose(100, third), pose(160, first),
            {time = 200, commands = {}}}
end

function PrayerAnimations.register(animations)
    -- Keep the original gestures/timing, but strip center translations and all
    -- leg commands. Copy commands: setupAnimation mutates piece IDs and axes.
    local legacy = {}
    for _, frame in ipairs(animations.UPBODY_PRAY) do
        local commands = {}
        for _, command in ipairs(frame.commands) do
            if command.c == "turn" and allowed[command.p] then
                local copy = {}
                for key, value in pairs(command) do copy[key] = value end
                commands[#commands + 1] = copy
            end
        end
        legacy[#legacy + 1] = {time = frame.time, commands = commands}
    end
    animations.UPBODY_PRAYER_1 = legacy
    -- 2: hands gathered near the chest, a small bow.
    animations.UPBODY_PRAYER_2 = cycle(arms(12, 0, -15, 18, -95, 20),
        arms(23, 8, -15, 18, -100, 20), arms(12, 0, -15, 18, -95, 20))
    -- 3: open-handed offering, extending and gathering the forearms.
    animations.UPBODY_PRAYER_3 = cycle(arms(8, 0, -30, 25, -65, 45),
        arms(0, -3, -45, 32, -35, 55), arms(12, 3, -25, 22, -75, 40))
    -- 4: raised invocation, with a restrained upward pulse.
    animations.UPBODY_PRAYER_4 = cycle(arms(-10, -3, -100, 30, -35, 0),
        arms(-16, -5, -120, 35, -20, 10), arms(-8, 0, -95, 28, -45, 0))
    -- 5: one hand over the heart, the other presenting outward.
    local heart = arms(12, 0, -10, 15, -65, 0)
    heart.UpArm1 = {-25, -12, 15}; heart.LowArm1 = {-110, 0, 35}
    local offering = arms(18, 5, -10, 15, -65, 0)
    offering.UpArm1 = {-25, -12, 15}; offering.LowArm1 = {-110, 0, 35}
    offering.UpArm2 = {-45, 30, 0}; offering.LowArm2 = {-45, 0, -45}
    animations.UPBODY_PRAYER_5 = cycle(heart, offering, heart)
    -- 6: contemplative hands held near the face, head inclined.
    animations.UPBODY_PRAYER_6 = cycle(arms(20, 0, -35, 12, -120, 12),
        arms(30, 6, -40, 12, -125, 12), arms(18, 0, -35, 12, -115, 12))
    -- 7: broad welcome, then drawing the hands inward.
    animations.UPBODY_PRAYER_7 = cycle(arms(0, 0, -35, 55, -40, 30),
        arms(-8, -4, -55, 70, -25, 40), arms(12, 4, -20, 20, -95, 20))
    -- 8: alternating testimony, a measured right/left hand emphasis.
    local left = arms(8, 0, -20, 22, -75, 10)
    left.UpArm1 = {-65, -28, 0}; left.LowArm1 = {-80, 0, 15}
    local right = arms(8, 0, -20, 22, -75, 10)
    right.UpArm2 = {-65, 28, 0}; right.LowArm2 = {-80, 0, -15}
    animations.UPBODY_PRAYER_8 = cycle(left, right, arms(18, 5, -15, 18, -95, 20))
end

function PrayerAnimations.name(index)
    -- Preserve a useful fallback for direct script calls and future audio files.
    if type(index) ~= "number" or index < 1 or index > 8 or index % 1 ~= 0 then
        index = 1
    end
    return "UPBODY_PRAYER_" .. index
end

return PrayerAnimations
