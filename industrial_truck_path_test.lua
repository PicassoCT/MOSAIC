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
    local heading, terrain = 0, -30 -- authored initial pivot is already floating
    local worker, workerActive, groundQueries = nil, false, 0
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
        GetGroundHeight = function() groundQueries=groundQueries+1;return terrain end,
        GetUnitPosition = function() return 0, 0, 0 end,
        GetUnitVectors = function() return {0,0,1},{0,1,0},{-1,0,0} end,
        GetUnitPieceInfo = function(_, piece)
            assert(piece == names.Truck)
            return {min={-2,-1,-clearance/scale},max={2,1,3/scale}}
        end,
        GetUnitPieceMatrix = function(_, piece)
            if piece == names.Truck then
                local x,y,z = position()
                local c,s = math.cos(heading),math.sin(heading)
                return scale*c,0,scale*s,0, scale*s,0,-scale*c,0,
                       0,scale,0,0, x,y,z,1
            end
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
        env[name] = function() return name end
    end
    -- Model the height worker's signal lifecycle; unrelated Create threads
    -- remain stubbed out in this focused animation harness.
    env.Signal = function(mask)
        if mask == env.SIG_TRUCK_ABOVE then workerActive=false end
    end
    env.SetSignalMask = function(mask)
        assert(mask==env.SIG_TRUCK_ABOVE);workerActive=true
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
    worker = coroutine.create(env.truckAboveGround)
    local function resumeWorker()
        if workerActive then
            local ok,err=coroutine.resume(worker);assert(ok,err)
        end
    end
    workerActive=true
    local function tick()
        -- Robot/spark/weld workers mutate these globals while the truck runs.
        env.val, env.x, env.y, env.z, env.groundHeight = 180, -999, 999, 999, -999
        resumeWorker()
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
    local starts, rampTurns = 0, 0
    local function runSequence(sequence, departing)
        for _,step in ipairs(sequence)do
            local fn=step[1]
            if fn==env.StartThread and step[2]==env.truckAboveGround then
                if departing then assert(rampTurns==2,'ground tracking resumed before leaving the ramp') end
                starts=starts+1
                worker=coroutine.create(env.truckAboveGround);workerActive=true
                resumeWorker()
                local _,y=position()
                near(y,terrain+clearance,'ground tracking did not resume')
            elseif fn==env.Signal or fn==env.Move then
                fn(unpack(step,2))
            elseif fn==env.WMove then
                -- Complete the authored drive; tracking must already be off
                -- for the final approach to the loading position.
                if not departing and step[4]==0 then
                    assert(not workerActive,'terrain worker remained active on dock approach')
                    near(translation[3],0,'dock approach retained a terrain offset')
                end
                env.Move(step[2],step[3],step[4],0)
            elseif fn==env.WTurn and (step[2]==names.TruckRotate1 or step[2]==names.TruckRotate2) then
                assert(not workerActive,'terrain worker pulled the truck through the ramp')
                near(translation[3],0,'ramp turn must use zero relative height')
                rampTurns=rampTurns+1
                local queries=groundQueries
                resumeWorker()
                assert(groundQueries==queries,'ramp animation still sampled terrain')
            end
        end
    end
    -- Exercise repeated arrival, unloading dwell and departure on uneven
    -- terrain, including the DAE's small import scale.
    for cycle=1,2 do
        rampTurns=0;runSequence(env.truckArrivingSequence,false)
        assert(rampTurns==2 and not workerActive)
        near(translation[3],0,'loading/unloading must remain relative to factory')
        terrain=terrain-15
        local queries=groundQueries
        for i=1,30 do resumeWorker() end
        near(translation[3],0,'docked height changed with terrain')
        assert(queries==groundQueries,'docked truck still ran terrain checks')
        rampTurns=0;runSequence(env.truckDepartingSequence,true)
        assert(not workerActive,'hidden departing truck left terrain worker running')
    end
    assert(starts==4,'each trip must retain arrival and departure ground tracking')
end

scenario(1)
scenario(0.0254)
print("PASS: industrial truck tracks terrain while driving and keeps zero relative height through ramp/loading phases")
