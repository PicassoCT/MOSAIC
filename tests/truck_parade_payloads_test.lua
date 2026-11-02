-- Lua 5.1+: exercise the complete payload unitscript with transport lifecycles.
local catalog = dofile("scripts/lib_truck_parade_payloads.lua")
local function loadEnv(path, env)
    setmetatable(env, {__index = _G})
    if setfenv then
        local chunk = assert(loadfile(path)); setfenv(chunk, env); return chunk()
    end
    return assert(loadfile(path, "t", env))()
end
local function check(name, test)
    test(); print("PASS: " .. name)
end
local function fixture()
    local f = {alive = {[5] = true, [20] = true, [21] = true}, parent = nil,
        visible = {}, moves = {}, turns = {}, spins = {}, stops = {}, threads = {},
        tooltips = {[20] = "Plate 20", [21] = "Plate 21"}, destroyed = {},
        map = {center = 1}, blocks = {}, selects = {}}
    local nextID = 1
    for _, v in ipairs(catalog.variants) do
        for _, name in ipairs(v.pieces) do nextID = nextID + 1; f.map[name] = nextID end
    end
    local function noop() end
    local env = {unitID = 5, script = {}, GG = {}, Spring = {},
        x_axis = 1, y_axis = 2, z_axis = 3,
        UnitDefs = {[1] = {name = "truck_arab6"}, [2] = {name = "truck_arab8"}},
        VFS = {Include = function(path) return dofile(path) end}, include = noop,
        piece = function(name) return f.map[name] end,
        hideAll = function() f.visible = {} end,
        Show = function(id) assert(id); f.visible[id] = true end,
        Move = function(id, axis, value, speed) f.moves[axis] = value end,
        Turn = function(id, axis, value, speed) f.turns[#f.turns + 1] = {id, axis, value, speed} end,
        Spin = function(id, axis, value) f.spins[#f.spins + 1] = {id, axis, value} end,
        StopSpin = function(id, axis, value) f.stops[#f.stops + 1] = {id, axis, value} end}
    local running
    env.Signal = function(mask)
        for _, thread in ipairs(f.threads) do if thread.mask == mask then thread.cancelled = true end end
    end
    env.SetSignalMask = function(mask) assert(running); running.mask = mask end
    env.Sleep = function(ms) return coroutine.yield(ms) end
    local function resume(thread, ...)
        if thread.cancelled or coroutine.status(thread.co) == "dead" then return end
        running = thread
        local ok, result = coroutine.resume(thread.co, ...)
        running = nil
        assert(ok, result); thread.delay = result
    end
    env.StartThread = function(fn, ...)
        local thread = {co = coroutine.create(fn)}
        f.threads[#f.threads + 1] = thread
        resume(thread, ...)
    end
    f.step = function()
        local copy = {}; for i, thread in ipairs(f.threads) do copy[i] = thread end
        for _, thread in ipairs(copy) do resume(thread) end
    end
    env.Spring.ValidUnitID = function(id) return f.alive[id] ~= nil end
    env.Spring.GetUnitIsDead = function(id) return not f.alive[id] end
    env.Spring.GetUnitTransporter = function(id) assert(id == 5); return f.parent end
    env.Spring.GetUnitDefID = function(id) return id == 21 and 2 or 1 end
    env.Spring.GetUnitPieceMap = function() return f.map end
    env.Spring.GetUnitTooltip = function(id) return f.tooltips[id] end
    env.Spring.SetUnitTooltip = function(id, text) f.tooltips[id] = text end
    env.Spring.SetUnitNoSelect = function(id, value) f.selects[id] = value end
    env.Spring.SetUnitBlocking = function(id, value) f.blocks[id] = value end
    env.Spring.SetUnitAlwaysVisible, env.Spring.SetUnitNeutral, env.Spring.Echo = noop, noop, noop
    env.Spring.DestroyUnit = function(id, selfDestruct, reclaimed)
        assert(id == 5 and selfDestruct == false and reclaimed == true)
        f.destroyed[#f.destroyed + 1] = id; f.alive[id] = false
    end
    loadEnv("scripts/truckParadePayloadScript.lua", env)
    f.env = env
    return f
end

check("variant selection before Create retains all and only the selected float pieces", function()
    local f = fixture()
    assert(f.env.SetParadeVariant(3))
    f.env.script.Create()
    for index, v in ipairs(catalog.variants) do
        for _, name in ipairs(v.pieces) do assert((f.visible[f.map[name]] == true) == (index == 3)) end
    end
    assert(not f.visible[f.map.center])
    assert(not f.env.SetParadeVariant(0) and not f.env.SetParadeVariant(1.5)
        and not f.env.SetParadeVariant("2") and not f.env.SetParadeVariant(7))
    assert(f.env.SetParadeVariant(5))
    for index, v in ipairs(catalog.variants) do
        for _, name in ipairs(v.pieces) do assert((f.visible[f.map[name]] == true) == (index == 5)) end
    end
    f.step()
    assert(#f.spins == 1)
    local spin = f.spins[1]
    assert(spin[1] == f.map.container70ActWindmillRotor and spin[2] == 3,
        "horizontal mill rotor must rotate around Z, not the vertical axis")
    f.step()
    assert(f.stops[#f.stops][1] == spin[1] and f.stops[#f.stops][3] == 0)
end)

check("delayed attachment fits carriers and detachment removes orphaned float", function()
    local f = fixture(); f.env.SetParadeVariant(1); f.env.script.Create()
    for _ = 1, 10 do f.step() end
    assert(#f.destroyed == 0)
    f.parent = 20; f.step()
    assert(f.moves[2] == 0 and f.moves[3] == -3.5)
    for _ = 1, 5 do f.step() end
    assert(f.tooltips[20] == "Plate 20 carrying The Forest Dreamer")
    f.parent = 21; f.step()
    assert(f.tooltips[20] == "Plate 20" and f.moves[2] == -1.8 and f.moves[3] == 0)
    for _ = 1, 5 do f.step() end
    f.tooltips[21] = "External ownership description"
    f.parent = nil; f.step()
    assert(f.tooltips[21] == "External ownership description")
    assert(f.moves[2] == 0 and f.moves[3] == 0)
    for _ = 1, 8 do f.step() end
    assert(#f.destroyed == 1 and f.selects[5] and f.blocks[5] == false)
end)

check("never-attached and dead-carrier payloads retire without leaving hover models", function()
    local f = fixture(); f.env.SetParadeVariant(1); f.env.script.Create()
    for _ = 1, 20 do f.step() end
    assert(#f.destroyed == 1)
    f = fixture(); f.parent = 20; f.env.SetParadeVariant(1); f.env.script.Create()
    f.alive[20] = false
    for _ = 1, 8 do f.step() end
    assert(#f.destroyed == 1)
end)

check("missing model piece fails explicitly and never selects generic cargo", function()
    local f = fixture(); f.map.container66 = nil
    assert(f.env.SetParadeVariant(1)); f.env.script.Create()
    assert(#f.destroyed == 1 and next(f.visible) == nil)
end)

check("rigid parade carriers stay civilian in every culture without changing military loadouts", function()
    local definitions = {
        [1] = {name="truck_arab6"}, [2] = {name="truck_arab7"}, [3] = {name="truck_arab8"},
        [4] = {name="truck_western0"}, [5] = {name="ground_truck_mg"},
    }
    for _, culture in ipairs({"arabic", "western", "asian", "international"}) do
        local localTypes = (culture == "arabic" and {[1]=1,[2]=2,[3]=3})
            or (culture == "international" and {[1]=1,[2]=2,[3]=3,[4]=4}) or {[4]=4}
        local cases = {1,2,3,5}
        if localTypes[4] then cases[#cases+1]=4 end
        for _, defID in ipairs(cases) do
            local registration, threads = 0, {}
            local function noop() end
            local env = {unitID=10, unitDefID=defID, script={}, Game={},
                UnitDefs=definitions, UnitDefNames={policetruck={id=99}},
                include=function() return noop end, VFS={Include=dofile},
                getTruckLoadOutTypeTable=function() return {[5]=51} end,
                getNotTruckLoadableTypeTable=function() return {} end,
                getGameConfig=function() return {game={culture=culture}} end,
                getCultureUnitModelTypes=function() return localTypes end,
                getDeadGuyInTowTypeTable=function() return {} end,
                getPieceTableByNameGroups=function() return {} end,
                piece=function(name) return name == "center" and 1 or 2 end,
                assingCivilianTruckRegistration=function() registration=registration+1 end,
                Hide=noop, showAll=noop, showRandomPieceSubset=noop,
                StartThread=function(fn) assert(type(fn)=="function"); threads[#threads+1]=fn end,
                Spring={GetUnitTeam=function() return 0 end, GetGaiaTeamID=function() return 0 end,
                    GetUnitPieceMap=function() return {center=1,attachPoint=2} end, SetUnitNanoPieces=noop}}
            loadEnv("scripts/Truckscript.lua",env)
            env.script.Create()
            local loadoutThreads=0
            for _, fn in ipairs(threads) do if fn == env.loadLoadOutLoop then loadoutThreads=loadoutThreads+1 end end
            if defID == 5 then
                assert(loadoutThreads == 1 and registration == 0, culture .. ": military loadout changed")
            else
                assert(loadoutThreads == 0 and registration == 1, culture .. ": civilian carrier became military")
            end
        end
    end
end)

check("new payload definition inherits native transport properties and emissive atlas", function()
    local function lowerkeys(t)
        local result = {}; for k, v in pairs(t) do result[type(k) == "string" and k:lower() or k] = v end
        return result
    end
    local env = {lowerkeys = lowerkeys, VFS = {}}
    env.VFS.Include = function(path) return loadEnv(path, env) end
    local d = loadEnv("units/neutral/truckPayloadParade.lua", env).truckpayloadparade
    assert(d and d.objectname == catalog.modelName and d.script == "truckParadePayloadScript.lua")
    assert(d.cantbetransported == false and d.blocking == false and d.mass == 2020)
    assert(d.customparams.civilian_parade_payload and d.customparams.normaltex == "unittextures/house_asian_normal.dds")
    local material = dofile("objects3d/truckPayloadParade.dae.lua")
    assert(material.tex1 == "house_asian_diffuse.dds" and material.tex2 == "house_asian_selfilu_reflection.png")
end)

print("PASS: parade payload regression suite")
