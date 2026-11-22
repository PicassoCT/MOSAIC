-- Pure frame-clock weather: reloads, spectators and replays choose the same events.
-- MOSAIC starts at noon and advances one day in 28800 simulation frames.
local Weather = {dayLength = 28800}
Weather.profiles = {
    fog = {color = {0.65, 0.72, 0.76}, bottom = -15, fade = 55, height = 170,
        scale = 540, extinction = 0.0048, opacity = 0.66, speed = 0.12, kind = 1},
    smog = {color = {0.51, 0.47, 0.37}, bottom = -15, fade = 135, height = 390,
        scale = 850, extinction = 0.0018, opacity = 0.62, speed = 0.07, kind = 2},
    sandstorm = {color = {0.76, 0.49, 0.25}, bottom = -20, fade = 390, height = 1050,
        scale = 1100, extinction = 0.0028, opacity = 0.84, speed = 0.65, kind = 3},
}

local function smooth(a, b, x)
    local t = math.max(0, math.min(1, (x-a)/(b-a)))
    return t*t*(3-2*t)
end

function Weather.New(seed)
    seed = math.floor(math.abs(tonumber(seed) or 70427)) % 2147483646 + 1
    local cachedDay, events
    local function schedule(day)
        -- Integer products stay exactly representable in Lua's doubles.
        local state = (seed + day * 104729) % 2147483646 + 1
        local function random()
            state = (state * 48271) % 2147483647
            return state / 2147483647
        end
        local result = {}
        local dawnChance, dawnStart, dawnDuration = random(), random(), random()
        if dawnChance < 0.48 then
            result[#result+1] = {mode = 'fog', start = 0.18 + 0.025*dawnStart,
                duration = 0.13 + 0.025*dawnDuration}
        end
        local afternoonChance, afternoonStart, afternoonDuration = random(), random(), random()
        -- A day's afternoon has either smog or a storm, with a clear gap after dawn.
        if afternoonChance < 0.14 then
            result[#result+1] = {mode = 'sandstorm', start = 0.59 + 0.055*afternoonStart,
                duration = 0.105 + 0.035*afternoonDuration}
        elseif afternoonChance < 0.42 then
            result[#result+1] = {mode = 'smog', start = 0.42 + 0.06*afternoonStart,
                duration = 0.10 + 0.04*afternoonDuration}
        end
        return result
    end

    local controller = {}
    function controller.Evaluate(frame, wetness, forced)
        if forced == 'off' then return 'clear', 0, nil, 0 end
        if Weather.profiles[forced] then return forced, 1, Weather.profiles[forced], 0.5 end
        local clock = math.max(0, frame) + Weather.dayLength*0.5
        local day = math.floor(clock/Weather.dayLength)
        local percent = (clock % Weather.dayLength)/Weather.dayLength
        if day ~= cachedDay then events, cachedDay = schedule(day), day end
        wetness = math.max(0, math.min(1, tonumber(wetness) or 0))
        for _, event in ipairs(events) do
            local phase = (percent-event.start)/event.duration
            if phase > 0 and phase < 1 then
                local strength = smooth(0, 0.23, phase)*(1-smooth(0.68, 1, phase))
                if event.mode == 'sandstorm' then
                    strength = strength*(1-smooth(0.08, 0.32, wetness))
                elseif event.mode == 'smog' then
                    strength = strength*(1-smooth(0.2, 0.65, wetness))
                else
                    strength = strength*(1-0.4*wetness)
                end
                return event.mode, strength, Weather.profiles[event.mode], phase
            end
        end
        return 'clear', 0, nil, 0
    end
    return controller
end

return Weather
