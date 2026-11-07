-- Headless behavior contracts: fixed world ground, restrained main figures,
-- meaningful helper pauses, bounded station history and export-name handling.
local scene = dofile("luarules/gadgets/include/parade_hologram_scene.lua")
local config = dofile("luarules/configs/parade_hologram_scene.lua")
local model = dofile("scripts/lib_truck_parade_model.lua")
local function check(name, test) test(); print("PASS: " .. name) end
local function close(a, b) return math.abs(a - b) < 0.000001 end
local lanterns, emitters = {}, {}
for _, item in ipairs(config.props) do
    if item.model == "lantern" then lanterns[#lanterns + 1] = item end
end
table.sort(lanterns, function(a, b) return a.lanternSlot < b.lanternSlot end)
for _, item in ipairs(config.figures) do
    if item.lanternEmitter then emitters[item.model] = item end
end
local function stationAt(seconds)
    return scene.updateStations({}, 20, 100, 200, 0, 1, seconds, config)[1]
end

check("all four spectator families have four complete model choices and every motif remains", function()
    local counts, models, props = {}, {}, {}
    for _, item in ipairs(config.figures) do
        counts[item.category] = (counts[item.category] or 0) + 1
        assert(not models[item.model]); models[item.model] = true
    end
    for _, category in ipairs({"civilian", "dead", "ai", "helper"}) do assert(counts[category] == 4) end
    assert(models.paradeai1, "Null Lux retains its own avatar slot")
    for _, item in ipairs(config.props) do props[item.model] = true end
    for _, name in ipairs({"candle", "lantern", "moon", "envelope", "money", "koi", "lotus", "leaf", "star", "cloud", "pinwheel", "moth"}) do
        assert(props[name], name)
    end
end)

check("runtime choices resolve the generated native meshes and measured head pivots", function()
    local generated = dofile("luarules/configs/parade_hologram_models.lua")
    assert(generated.root == "paradeholograms")
    for _, item in ipairs(config.figures) do
        local definition = assert(generated.figures[item.model], item.model)
        assert(definition.category == item.category and definition.height > 0)
        assert(#definition.headPivot == 3 and definition.headPivot[2] > 0
            and definition.headPivot[2] < definition.height)
        for _, role in ipairs({"body", "head", "mask"}) do assert(definition.pieces[role] == item.model .. role) end
    end
    assert(generated.figures.paradeai1.label:lower():find("null lux", 1, true))
    for _, item in ipairs(config.props) do
        local definition = assert(generated.props[item.model])
        assert(definition.piece == definition.variants[1].piece)
    end
    assert(#generated.props.moth.variants == 3)
    for _, bird in ipairs(generated.props.moth.variants) do assert(#bird.wings == 2) end
end)

check("ground candles stay planted as the parade passes and stations fade instead of sliding", function()
    local state = {}
    local stations = scene.updateStations(state, 20, 100, 200, 0, 1, 10, config)
    local station = stations[1]
    local candle
    for _, item in ipairs(config.props) do if item.ground then candle = item; break end end
    local before = scene.worldPose(station, candle, 12, 5, 6.75)
    scene.updateStations(state, 20, 145, 220, 1, 0, 12.5, config)
    local after = scene.worldPose(station, candle, 12.5, 5, 6.75)
    assert(close(before.x, after.x) and close(before.z, after.z) and before.y == 6.75 and after.y == 6.75)
    assert(station.dx == 0 and station.dz == 1, "a truck turn must not rotate the planted audience")
    stations = scene.updateStations(state, 20, 220, 200, 1, 0, 13, config)
    assert(#stations == 2 and stations[1] == station and station.retired == 13)
    assert(scene.stationOpacity(stations[2], 13, config) == 0)
    stations = scene.updateStations(state, 20, 222, 200, 1, 0, 15, config)
    assert(#stations == 1 and stations[1].x == 220)
    for time = 16, 60 do
        stations = scene.updateStations(state, 20, time * 180, 200, 1, 0, time, config)
        assert(#stations <= 2)
    end
end)

check("attachment changes, visibility gaps and time rewinds reset old world audiences", function()
    local state = {}
    local original = scene.updateStations(state, 20, 10, 20, 0, 1, 10, config)[1]
    local changed = scene.updateStations(state, 21, 10, 20, 0, 1, 11, config)[1]
    assert(changed ~= original)
    local resumed = scene.updateStations(state, 21, 10, 20, 0, 1, 20, config)[1]
    assert(resumed ~= changed)
    assert(scene.updateStations(state, 21, 10, 20, 0, 1, 5, config)[1] ~= resumed)
end)

check("main spectators remain still and the darker period dead hover near living head height", function()
    for _, item in ipairs(config.figures) do
        if item.category ~= "helper" then
            for time = 0, 400 do
                local pose = scene.pose(item, time * 0.1, 5)
                assert(pose.x == item.x and pose.z == item.z and pose.tilt == 0)
                assert(math.abs(pose.headTilt) <= 1.5)
                if item.category == "civilian" then assert(pose.y == 0) end
                if item.category == "dead" then assert(pose.y >= 8.7 and pose.y <= 8.9 and pose.opacity <= 0.55) end
                if item.category == "ai" then assert(pose.y >= 0.96 and pose.y <= 1.24) end
            end
        end
    end
end)

check("helpers pause, approach a task, gesture and return with bounded hops", function()
    for _, item in ipairs(config.figures) do
        if item.category == "helper" then
            local offset = (item.phase or 0) + 5 * 0.173
            local a, b = scene.pose(item, 1-offset, 5), scene.pose(item, 4-offset, 5)
            assert(a.activity == "rest" and b.activity == "rest")
            assert(a.x == b.x and a.y == b.y and a.z == b.z and a.headTilt == 0 and b.headTilt == 0)
            local active = scene.pose(item, 7.2-offset, 5)
            assert(active.activity == item.task and math.abs(active.headTilt) > 17)
            local hop = scene.pose(item, 5.35-offset, 5)
            assert(hop.y > 0.57 and hop.y < 0.59)
            local settled = scene.pose(item, 9.8-offset, 5)
            assert(settled.activity == "rest" and settled.x == item.x and settled.z == item.z)
            for tick = 0, 100 do
                local pose = scene.pose(item, tick / 10-offset, 5)
                assert(math.abs(pose.x-item.x) <= 2.800001 and math.abs(pose.z-item.z) <= 2.200001)
                assert(pose.y >= 0 and pose.y <= 0.580001)
            end
        end
    end
end)

check("six daemon-owned lanterns retain exact thirds and half fixed behavior across switches", function()
    assert(#lanterns == 6, "one complete cohort needs six lantern identities")
    local sources, histories, fixed = {}, {}, {}
    for index, item in ipairs(lanterns) do
        assert(item.lanternSlot == index and item.motion == "lantern")
        assert(emitters[item.emitter], "each lantern needs a real helper daemon")
        sources[item.emitter] = (sources[item.emitter] or 0) + 1
        histories[index] = {}
    end
    local sourceCount = 0
    for _, count in pairs(sources) do assert(count == 2); sourceCount = sourceCount + 1 end
    assert(sourceCount == 3, "three daemons each place one pair")
    local station, settings = stationAt(17.25), config.lanterns
    local interval = settings.switchSeconds
    for epoch = 0, 15 do
        for _, offset in ipairs({0.00001, interval / 2, interval - 0.00001}) do
            local seconds = station.born + settings.releaseSeconds + epoch * interval + offset
            local counts, fixedCount, visibleCount = {stationary = 0, up = 0, down = 0}, 0, 0
            local visibility
            for index, item in ipairs(lanterns) do
                local pose = scene.lanternPose(station, item, seconds, config)
                if pose.visible then
                    visibleCount = visibleCount + 1
                    assert(counts[pose.lanternMode], "every visible lantern needs a supported mode")
                    counts[pose.lanternMode] = counts[pose.lanternMode] + 1
                    histories[index][pose.lanternMode] = true
                    assert(pose.opacity == item.opacity, "a live lantern cannot dim during its lifecycle")
                else
                    assert(pose.opacity == 0 and pose.activity == "hidden")
                end
                if pose.fixedBehavior then fixedCount = fixedCount + 1 end
                if fixed[index] == nil then fixed[index] = pose.fixedBehavior end
                assert(fixed[index] == pose.fixedBehavior, "an identity cannot change its fixed/switching class")
                if visibility ~= nil then assert(pose.visible == visibility, "the whole cohort must blink together") end
                visibility = pose.visible
            end
            assert(visibleCount == 0 or visibleCount == 6, "a release or blink cannot leave a partial cohort")
            assert(counts.stationary == visibleCount / 3 and counts.up == visibleCount / 3
                and counts.down == visibleCount / 3, "switches must preserve one third in each visible mode")
            assert(fixedCount == 3, "exactly half retain their original behavior")
        end
    end
    local fixedModes, switchingPairs = {}, {}
    for index, history in ipairs(histories) do
        local modes = {}; for mode in pairs(history) do modes[#modes + 1] = mode end
        table.sort(modes)
        if fixed[index] then
            assert(#modes == 1, "a fixed lantern must never reverse or become stationary")
            fixedModes[modes[1]] = (fixedModes[modes[1]] or 0) + 1
        else
            assert(#modes == 2, "each switching lantern uses exactly two behaviors")
            local pair = table.concat(modes, ":")
            switchingPairs[pair] = (switchingPairs[pair] or 0) + 1
        end
    end
    assert(fixedModes.stationary == 1 and fixedModes.up == 1 and fixedModes.down == 1)
    assert(switchingPairs["stationary:up"] == 1 and switchingPairs["down:up"] == 1
        and switchingPairs["down:stationary"] == 1)
end)

check("lantern heights stay continuous and the cohort blinks off before recycling", function()
    local station, settings = stationAt(11.5), config.lanterns
    local interval, period = settings.switchSeconds, 4 * settings.switchSeconds
    local release, epsilon = station.born + settings.releaseSeconds, 0.00001
    for _, item in ipairs(lanterns) do
        for epoch = 0, 3 do
            local previous
            for _, fraction in ipairs({0.1, 0.3, 0.7, 0.85}) do
                local pose = scene.lanternPose(station, item, release + (epoch + fraction) * interval, config)
                assert(pose.visible and pose.opacity == item.opacity)
                assert(pose.y >= 0 and pose.y <= settings.airborneHeight + settings.speed * period)
                assert(pose.x == item.x and pose.z == item.z)
                if previous then
                    local delta = pose.y - previous.y
                    assert(pose.lanternMode == previous.lanternMode)
                    if pose.lanternMode == "stationary" then
                        assert(close(delta, 0) and pose.tilt == 0 and pose.headTilt == 0,
                            "stationary lanterns cannot retain the generic bob or tilt")
                    elseif pose.lanternMode == "up" then assert(delta > 0, "rising lantern moved down or stopped")
                    else assert(delta < 0, "falling lantern moved up or stopped") end
                end
                previous = pose
            end
        end
        for epoch = 1, 3 do
            local boundary = release + epoch * interval
            local before = scene.lanternPose(station, item, boundary - epsilon, config)
            local at = scene.lanternPose(station, item, boundary, config)
            local after = scene.lanternPose(station, item, boundary + epsilon, config)
            assert(math.abs(after.y - before.y) < 0.0001, "a behavior switch teleported the lantern")
            if not at.fixedBehavior then
                assert(math.abs((at.y - before.y) / epsilon) < 0.001
                    and math.abs((after.y - at.y) / epsilon) < 0.001,
                    "switching motion must ease to rest at the mode boundary")
            end
        end
        local expiry = release + period - settings.blinkSeconds
        local before = scene.lanternPose(station, item, expiry - epsilon, config)
        assert(before.visible and before.opacity == item.opacity, "the last live instant must not fade")
        for _, offset in ipairs({0, settings.blinkSeconds / 2, settings.blinkSeconds - epsilon}) do
            local pose = scene.lanternPose(station, item, expiry + offset, config)
            assert(pose.visible == false and pose.opacity == 0 and pose.activity == "hidden",
                "the entire recycle window must be invisible")
        end
        local replacement = scene.lanternPose(station, item, release + period + epsilon, config)
        assert(replacement.visible and replacement.opacity == item.opacity
            and close(replacement.spawnTime, release + period), "the next release must appear without a fade-in")
        if item.lanternSlot == 1 then
            assert(scene.lanternPose(station, item, release + period / 2, config).y == 0)
        elseif item.lanternSlot == 3 then
            assert(before.y < 0.001, "the fixed falling lantern reaches ground just before blinking off")
        end
    end
end)

check("ground lanterns appear during a visible daemon gesture and stay at the placement point", function()
    local station, settings = stationAt(100.25), config.lanterns
    station.dx, station.dz = 0.6, 0.8
    local release, ground = station.born + settings.releaseSeconds, 6.75
    local pairsBySource = {}
    for _, item in ipairs(lanterns) do
        local waiting = scene.worldPose(station, item, release - 0.00001, 5, ground, config)
        assert(waiting.visible == false and waiting.opacity == 0)
        local placed = scene.worldPose(station, item, release, 5, ground, config)
        assert(placed.visible and placed.opacity == item.opacity
            and placed.spawnedBy == item.emitter and close(placed.spawnTime, release))
        pairsBySource[item.emitter] = pairsBySource[item.emitter] or {}
        table.insert(pairsBySource[item.emitter], placed)
        if item.lanternSlot == 1 or item.lanternSlot == 4 then
            assert(close(placed.y, ground), "the initial stationary pair must actually touch ground")
        end
    end
    for modelName, pair in pairs(pairsBySource) do
        local emitter = emitters[modelName]
        local task = scene.worldPose(station, emitter, release, 5, ground, config)
        assert(task.activity == "spawn_lanterns" and math.abs(task.headTilt) > 17
            and math.abs(task.tilt) > 9, "a ground appearance needs a visible placement gesture")
        local direction = emitter.x < 0 and 1 or -1
        local middleX, middleZ = (pair[1].x + pair[2].x) / 2, (pair[1].z + pair[2].z) / 2
        assert(close(middleX - task.x, station.dz * direction * settings.reach)
            and close(middleZ - task.z, -station.dx * direction * settings.reach),
            "the pair must be placed within the daemon's reach, in the station's rotated frame")
        local separation = math.sqrt((pair[1].x - pair[2].x)^2 + (pair[1].z - pair[2].z)^2)
        assert(close(separation, 2 * settings.pairSpacing))
        local rested = scene.worldPose(station, emitter, station.born + 3, 5, ground, config)
        assert(rested.activity == "rest" and close(rested.y, ground))
        assert(not close(task.x, rested.x) or not close(task.z, rested.z), "the daemon should return after placing")
    end
    local early = scene.worldPose(station, lanterns[1], release, 5, ground, config)
    local later = scene.worldPose(station, lanterns[1], station.born + 3, 5, ground, config)
    assert(close(early.x, later.x) and close(early.y, later.y) and close(early.z, later.z),
        "a placed ground lantern must not follow the departing daemon")
end)

check("emitting daemons retain a long pause and the fourth helper keeps its original task", function()
    local station = stationAt(0)
    station.x, station.z = 0, 0
    local period = 4 * config.lanterns.switchSeconds
    for _, item in ipairs(config.figures) do
        if item.category == "helper" then
            local resting = 0
            for tick = 0, 639 do
                local seconds = tick * period / 640
                local pose = scene.worldPose(station, item, seconds, 5, 0, config)
                if item.lanternEmitter then
                    if pose.activity == "rest" then resting = resting + 1 end
                    assert(pose.y >= -0.000001 and pose.y <= 0.350001)
                else
                    local original = scene.pose(item, seconds, 5)
                    assert(pose.activity == original.activity and pose.x == original.x
                        and pose.y == original.y and pose.z == original.z
                        and pose.headTilt == original.headTilt and pose.tilt == original.tilt)
                end
            end
            if item.lanternEmitter then
                assert(resting > 320, "daemons must genuinely pause for most of a cycle")
                local retiring = stationAt(0)
                local duringApproach = period + config.lanterns.approachSeconds / 2
                local before = scene.worldPose(retiring, item, duringApproach, 5, 0, config)
                retiring.retired = duringApproach
                local after = scene.worldPose(retiring, item, duringApproach, 5, 0, config)
                assert(before.activity == "approach" and after.activity == before.activity
                    and close(before.x, after.x) and close(before.y, after.y) and close(before.z, after.z),
                    "retirement should fade a moving daemon, not teleport it home")
            end
        end
    end
end)

check("fast moving stations release a whole cohort and switch before the carrier moves on", function()
    local state, first, releasedAt, switchedAt = {}
    -- Ordinary western truck at maxVelocity 5.2, 30Hz and parade speedFactor .22.
    local speed = 34.32
    for tick = 0, 160 do
        local seconds = tick * 0.05
        local stations = scene.updateStations(state, 20, 100 + speed * seconds, 200, 1, 0, seconds, config)
        first = first or stations[1]
        assert(#stations <= 2)
        for _, station in ipairs(stations) do
            local visible = 0
            for _, item in ipairs(lanterns) do
                local pose = scene.lanternPose(station, item, seconds, config)
                if pose.opacity * scene.stationOpacity(station, seconds, config) > 0.002 then
                    visible = visible + 1
                    if station == first then
                        releasedAt = releasedAt or seconds
                        if item.lanternSlot == 4 and pose.lanternMode == "up" then switchedAt = switchedAt or seconds end
                    end
                end
            end
            assert(visible == 0 or visible == 6, "partial releases would change the requested ratios")
        end
    end
    assert(first.retired and releasedAt and switchedAt)
    assert(releasedAt < switchedAt and switchedAt < first.retired,
        "a traveling audience must demonstrate its switching behavior before retirement")
    for _, station in ipairs(state.stations) do assert(station ~= first) end
end)

check("cohort recycling is bounded and retired or reset stations cannot emit stale lanterns", function()
    local station, settings = stationAt(10), config.lanterns
    local period = 4 * settings.switchSeconds
    local reference = scene.lanternPose(station, lanterns[5], 10 + settings.releaseSeconds + 0.4, config)
    for generation = 200, 0, -1 do
        for _, item in ipairs(lanterns) do
            local seconds = station.born + settings.releaseSeconds + generation * period + 0.4
            local pose = scene.lanternPose(station, item, seconds, config)
            assert(pose.y >= 0 and pose.y <= settings.airborneHeight + settings.speed * period)
            assert(pose.spawnTime <= seconds and seconds - pose.spawnTime < period)
            if item.lanternSlot == 5 then
                assert(close(pose.y, reference.y) and close(pose.opacity, reference.opacity),
                    "skipped frames or a long-running procession must not accumulate vertical drift")
            end
        end
    end
    station.retired = station.born + settings.releaseSeconds + period - 0.1
    assert(scene.lanternPose(station, lanterns[1], station.retired - settings.blinkSeconds, config).visible)
    for _, item in ipairs(lanterns) do
        assert(scene.lanternPose(station, item, station.born + settings.releaseSeconds + period + 0.4, config).opacity == 0)
    end
    local early = stationAt(10)
    early.retired = early.born + settings.releaseSeconds - 0.1
    assert(scene.lanternPose(early, lanterns[1], 10 + settings.releaseSeconds + 0.4, config).opacity == 0)
    local state = {}
    scene.updateStations(state, 20, 100, 200, 0, 1, 10, config)
    scene.updateStations(state, 20, 100, 200, 0, 1, 12, config)
    for _, reset in ipairs({{21, 13}, {21, 20}, {21, 5}}) do
        local fresh = scene.updateStations(state, reset[1], 100, 200, 0, 1, reset[2], config)[1]
        assert(fresh.born == reset[2] and #state.stations == 1)
        for _, item in ipairs(lanterns) do
            assert(scene.lanternPose(fresh, item, reset[2] + settings.releaseSeconds / 2, config).opacity == 0,
                "attachment changes, visibility gaps and rewinds require a new daemon placement")
        end
    end
end)

check("banknotes only descend to terrain while koi keep their bounded floating height", function()
    local money, koi
    for _, item in ipairs(config.props) do
        if item.model == "money" then money = item elseif item.model == "koi" then koi = item end
    end
    assert(money and money.motion == "fall" and koi and koi.motion == "hover")
    local station, ground = stationAt(41.25), 9.5
    local minimum, maximum = math.huge, -math.huge
    local period, epsilon = money.fallSeconds + money.blinkSeconds, 0.00001
    local waiting = scene.worldPose(station, money, station.born - epsilon, 5, ground, config)
    assert(waiting.visible == false and waiting.opacity == 0)
    for cycle = 0, 2 do
        local born = station.born + cycle * period
        local initial = scene.worldPose(station, money, born + epsilon, 5, ground, config)
        assert(initial.visible and initial.opacity == money.opacity and close(initial.spawnTime, born))
        local previous
        for tick = 1, 199 do
            local seconds = born + tick / 200 * money.fallSeconds
            local note = scene.worldPose(station, money, seconds, 5, ground, config)
            assert(note.visible and note.opacity == money.opacity
                and note.y >= ground and note.y <= ground + money.y)
            assert(note.activity == "down")
            if previous then
                assert(note.y < previous.y and note.x == previous.x and note.z == previous.z,
                    "visible notes must fall strictly down without a rising or sideways leg")
            end
            previous = note
            local fish = scene.worldPose(station, koi, seconds, 5, ground, config)
            assert(math.abs(fish.y - ground - koi.y) <= 0.180001,
                "a koi should float around its authored height without accumulating a fall")
            minimum, maximum = math.min(minimum, fish.y), math.max(maximum, fish.y)
        end
        local expiry = born + money.fallSeconds
        local last = scene.worldPose(station, money, expiry - epsilon, 5, ground, config)
        assert(last.visible and last.opacity == money.opacity and last.y < ground + 0.001,
            "a banknote must remain undimmed until it reaches the ground")
        for _, offset in ipairs({0, money.blinkSeconds / 2, money.blinkSeconds - epsilon}) do
            local hidden = scene.worldPose(station, money, expiry + offset, 5, ground, config)
            assert(hidden.visible == false and hidden.opacity == 0 and hidden.y == ground,
                "banknotes must stay hidden at ground level before resetting above")
        end
    end
    assert(maximum - minimum > 0.3, "the koi retains its gentle floating motion")
end)

check("artist export case, underscores, descendant meshes and baked fins are preserved", function()
    local pieces = {Scene = 0, CONTAINER68 = 1, CONTAINER1 = 2,
        CONTAINER70 = 3, CONTAINER70Act_WindmillRotor = 4, CONTAINER70_MountingSkid = 5,
        paradeholograms = 6, paradecivilian1body = 7}
    local info = {
        [0] = {parent = "[null]", children = {"CONTAINER68", "CONTAINER70", "paradeholograms"}},
        [1] = {children = {"CONTAINER1"}}, [2] = {children = {}},
        [3] = {children = {"CONTAINER70Act_WindmillRotor", "CONTAINER70_MountingSkid"}},
        [4] = {children = {}}, [5] = {children = {}},
        [6] = {children = {"paradecivilian1body"}}, [7] = {children = {}},
    }
    local index = model.inspect(pieces, function(id) return info[id] end)
    assert(index.center == 0)
    local catalog = dofile("scripts/lib_truck_parade_payloads.lua")
    local moon = assert(model.selection(index, {pieceName="container68", pieces={"container68"}}))
    assert(#moon.pieces == 2 and moon.pieces[1] == 1 and moon.pieces[2] == 2 and #moon.motions == 0)
    local mill = assert(model.selection(index, {pieceName="container70", pieces={"container70"}, motion={{pieceName="container70ActWindmillRotor", axis="x", spin=18}}}))
    assert(#mill.pieces == 3 and #mill.motions == 1 and mill.motions[1].id == 4)
    for _, id in ipairs(mill.pieces) do assert(id ~= 6 and id ~= 7, "hologram stock stays engine-hidden") end
    assert(not model.selection(index, catalog.variants[1]), "a genuinely missing sculpture must fail")
end)

check("legacy billboard placements compensate import scale without modifying native mesh vertices", function()
    local inv = model.inverseMatrixScale({0,0,0.0254,0, -0.0254,0,0,0, 0,-0.0254,0,0, 12,3,-8,1})
    for i = 1, 3 do assert(close(inv[i], 1/0.0254)) end
    assert(not model.inverseMatrixScale({}))
    assert(not model.inverseMatrixScale({0,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}))
end)

print("PASS: parade scene behavior suite")

check("origami bird flaps then glides; cherry petal drifts, lands and respawns invisibly", function()
    local bird, petal
    for _, item in ipairs(config.props) do
        if item.motion == "origami" then bird = item end
        if item.motion == "petal" then petal = item end
    end
    assert(bird and petal)
    local offset = bird.phase + 5 * 0.173
    local up = scene.pose(bird, 0.4-offset, 5)
    local down = scene.pose(bird, 1.2-offset, 5)
    local glide = scene.pose(bird, 4-offset, 5)
    assert(close(up.wingFlap,78) and close(down.wingFlap,18))
    assert(glide.activity == "glide" and close(glide.wingFlap,48))
    local station = {born=0, x=0, z=0, dx=0, dz=1}
    local previous = 100
    for tick=0,160 do
        local pose = scene.worldPose(station,petal,tick/10,5,0,config)
        assert(pose.y <= previous and pose.y >= 0)
        assert(math.abs(pose.x-petal.x) <= 3.1 and math.abs(pose.z-petal.z) <= 1.11)
        assert(math.abs(pose.tilt) <= 24 and math.abs(pose.roll) <= 32)
        previous = pose.y
    end
    local hidden = scene.worldPose(station,petal,16.2,5,0,config)
    assert(not hidden.visible and hidden.opacity == 0)
    local restart = scene.worldPose(station,petal,16.4,5,0,config)
    assert(close(restart.opacity,0))
end)
