-- Headless behavior contracts: fixed world ground, restrained main figures,
-- meaningful helper pauses, bounded station history and export-name handling.
local scene = dofile("luarules/gadgets/include/parade_hologram_scene.lua")
local config = dofile("luarules/configs/parade_hologram_scene.lua")
local model = dofile("scripts/lib_truck_parade_model.lua")
local function check(name, test) test(); print("PASS: " .. name) end
local function close(a, b) return math.abs(a - b) < 0.000001 end

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
    for _, item in ipairs(config.props) do assert(generated.props[item.model].piece == "parade" .. item.model) end
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
