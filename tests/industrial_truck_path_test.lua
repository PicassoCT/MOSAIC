-- Run from repository root: lua tests/industrial_truck_path_test.lua
-- Exercise the real height worker with a rotated/scaled parent and animated
-- Move commands. This checks path isolation, not the in-engine appearance.
local function near(a, b, message)
    assert(math.abs(a - b) < 1e-7, (message or "mismatch") .. ": " .. a .. " ~= " .. b)
end

local function scenario(scale)
    local env = setmetatable({}, {__index = _G})
    local names, pieces = {}, {}
    local translation, targets = {0, 0, 0}, {}
    local heading, terrain = 0, 20
    local orbitRadius, clearance = 160, 7
    local function noop() end
    env.unitID, env.script = 1, {}
    env.piece = function(name)
        if not names[name] then
            names[name] = #pieces + 1
            pieces[#pieces + 1] = name
        end
        return names[name]
    end
    env.include = function()
        return function() return {Start = noop, Stop = noop, Shutdown = noop} end
    end
    env.Move = function(piece, axis, value, speed)
        assert(piece == names.TruckMove, "height worker moved another piece")
        if not speed or speed == 0 then
            translation[axis] = value
            targets[axis] = nil
        else
            targets[axis] = {value, speed}
        end
    end
    env.Sleep = function(ms)
        for axis, target in pairs(targets) do
            local distance = target[1] - translation[axis]
            local step = math.min(math.abs(distance), target[2] * ms / 1000)
            translation[axis] = translation[axis] + (distance < 0 and -step or step)
        end
        coroutine.yield()
    end
    local function position()
        local radius = orbitRadius + translation[1] * scale
        return math.cos(heading) * radius,
               20 + clearance + translation[3] * scale,
               math.sin(heading) * radius
    end
    env.Spring = {
        GetUnitPiecePosDir = function(_, piece)
            assert(piece == names.Truck)
            return position()
        end,
        GetGroundHeight = function() return terrain end,
        GetUnitPieceMatrix = function(_, piece)
            assert(piece == names.TruckRotate3)
            -- Local Z is world up after the DAE's baked -90 degree X rotation.
            return scale,0,0,0, 0,0,-scale,0, 0,scale,0,0, 0,0,0,1
        end,
        UnitScript = {GetPieceTranslation = function(piece)
            assert(piece == names.TruckMove)
            return unpack(translation)
        end},
    }
    for _, name in ipairs({"Turn", "WTurn", "WMove", "Show", "Hide", "Signal",
        "SetSignalMask", "StartThread", "hideAll", "resetAll", "showT"}) do
        env[name] = noop
    end
    env.reset = function(piece)
        assert(piece ~= 3, "departure reset an axis number as a piece ID")
    end
    env.getPieceTableByNameGroups = function() return {Claw = {}} end
    env.isPieceAboveGround = function()
        local x, y, z = position()
        return y > terrain, x, y, z, terrain
    end
    local source = "scripts/objective_IndustrialComplexscript.lua"
    if _VERSION == "Lua 5.1" then
        local chunk = assert(loadfile(source)); setfenv(chunk, env); chunk()
    else
        assert(loadfile(source, "t", env))()
    end
    env.script.Create()
    local worker = coroutine.create(env.truckAboveGround)
    local function tick()
        -- Robot/spark/weld workers mutate these globals while the truck runs.
        env.val, env.x, env.y, env.z, env.groundHeight = 180, -999, 999, 999, -999
        local ok, err = coroutine.resume(worker)
        assert(ok, err)
        near(env.val, 180, "height worker overwrote another animation's state")
        near(translation[1], -100, "terrain correction changed the driving radius")
        near(translation[2], 0, "terrain correction changed the other horizontal axis")
        local x, _, z = position()
        near(math.sqrt(x*x + z*z), orbitRadius - 100*scale, "orbit drift")
    end
    env.Move(names.TruckMove, 1, -100, 0)
    for i = 1, 360 do
        heading = math.rad(i)
        tick()
        local _, y = position()
        near(y, terrain + clearance, "flat ground height drift")
    end
    for _, height in ipairs({23, 17, 20}) do
        terrain = height
        for i = 1, 240 do heading = heading + 0.01; tick() end
        local _, y = position()
        near(y, terrain + clearance, "terrain correction did not settle")
    end
    -- A new arrival must use the actual current translation, without a +200 jump.
    worker = coroutine.create(env.truckAboveGround)
    tick()
    local _, y = position()
    near(y, terrain + clearance, "height jumped on worker restart")
    for _, step in ipairs(env.truckDepartingSequence) do
        if step[1] == env.reset then env.reset(step[2]) end
    end
end

scenario(1)
scenario(0.0254)
print("PASS: industrial truck keeps its orbit, tracks terrain and ignores shared animation globals")
