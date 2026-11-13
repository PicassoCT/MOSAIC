-- Scoped to the Tiglil performer: keep authored poses and native wait semantics.
-- One worker changes speeds toward the FINAL target, never temporary waypoints.
return function(api, lifetime)
    local STEP, TICK, MIN_DURATION = 1 / 30, 33, 3 / 30
    local SIG_MOTION = 16384 -- Tiglil's other private bits end at SIG_BALL=8192.
    local channels, spins, running = {}, {}, false
    local tau = 2 * math.pi
    local function difference(target, current, turn)
        if turn then return (target - current + math.pi) % tau - math.pi end
        return target - current
    end
    local function position(id, axis, turn)
        local getter = turn and api.GetPieceRotation or api.GetPieceTranslation
        local x, y, z = getter(id)
        if axis == 1 then return x elseif axis == 2 then return y else return z end
    end
    local function key(id, axis, turn) return id * 6 + axis + (turn and 3 or 0) end
    local function clock() return Spring.GetGameFrame() / 30 end

    -- Quintic blend: zero endpoint acceleration, and zero ending velocity.
    -- Carry forward velocity when an overlapping pose continues in the same
    -- direction; clamp it to the monotonic range so limbs cannot overshoot.
    local function displacement(c, t)
        local u = math.min(1, math.max(0, t / c.duration))
        local u2, u3 = u * u, u * u * u
        local u4, u5 = u3 * u, u3 * u2
        return c.distance * (10*u3 - 15*u4 + 6*u5)
            + c.velocity * c.duration * (u - 6*u3 + 8*u4 - 3*u5)
    end

    local function drive(c, now)
        local current = position(c.id, c.axis, c.turn)
        local remaining = difference(c.target, current, c.turn)
        local desired = c.start + displacement(c, now - c.time + STEP)
        local advance = difference(desired, current, c.turn)
        local direction = c.distance < 0 and -1 or 1
        -- A positive floor keeps the native animation/wait alive until arrival.
        -- Recoil treats speed zero as a teleport, not as a paused animation.
        c.speed = math.max(0.000001, advance * direction / STEP)
        if now - c.time >= c.duration then
            c.speed = math.max(0.000001, math.abs(remaining) / STEP)
        end
        local command = c.turn and api.Turn or api.Move
        command(c.id, c.axis, c.target, c.speed)
    end

    local function worker()
        SetSignalMask(lifetime + SIG_MOTION)
        while next(channels) do
            Sleep(TICK)
            local now = clock()
            for k, c in pairs(channels) do
                local busy = c.turn and api.IsInTurn or api.IsInMove
                if now - c.time >= c.duration and not busy(c.id, c.axis) then
                    channels[k] = nil
                else
                    drive(c, now)
                end
            end
        end
        running = false
    end

    local function command(id, axis, target, speed, turn)
        local k = key(id, axis, turn)
        local previous = channels[k]
        local native = turn and api.Turn or api.Move
        if turn and spins[id] then spins[id][axis] = nil end
        if not speed or speed == 0 then
            channels[k] = nil
            -- A snap alone leaves an old Recoil animation queued.
            native(id, axis, target, 1)
            return native(id, axis, target, 0)
        end
        speed = math.abs(speed)
        if previous and previous.target == target and previous.authoredSpeed == speed then return end
        local start = position(id, axis, turn)
        local distance = difference(target, start, turn)
        if math.abs(distance) < 0.000001 then
            channels[k] = nil
            return native(id, axis, target, speed)
        end
        local duration = math.max(MIN_DURATION, math.abs(distance) / speed)
        local direction = distance < 0 and -1 or 1
        local velocity = previous and previous.speed * (previous.distance < 0 and -1 or 1) or 0
        velocity = direction * math.min(2.5 * math.abs(distance) / duration,
                                       math.max(0, direction * velocity))
        local c = {id=id, axis=axis, turn=turn, start=start, target=target,
                   distance=distance, duration=duration, velocity=velocity,
                   time=clock(), authoredSpeed=speed}
        channels[k] = c
        drive(c, c.time)
        if not running then running=true;StartThread(worker) end
    end

    local motion = {}
    function motion.Turn(id, axis, target, speed) command(id, axis, target, speed, true) end
    function motion.Move(id, axis, target, speed) command(id, axis, target, speed, false) end
    function motion.TurnInTime(id, axis, target, milliseconds)
        local distance = math.abs(difference(target, position(id,axis,true), true))
        command(id,axis,target,distance / math.max(0.001,math.abs(milliseconds)/1000),true)
    end
    function motion.MoveInTime(id, axis, target, milliseconds)
        local distance = math.abs(target-position(id,axis,false))
        command(id,axis,target,distance / math.max(0.001,math.abs(milliseconds)/1000),false)
    end
    function motion.Spin(id, axis, speed, acceleration)
        channels[key(id, axis, true)] = nil
        spins[id] = spins[id] or {};spins[id][axis] = speed
        api.Spin(id, axis, speed, acceleration or math.abs(speed) / 0.18)
    end
    function motion.StopSpin(id, axis, deceleration)
        local speed = spins[id] and spins[id][axis]
        api.StopSpin(id, axis, deceleration or (speed and math.abs(speed) / 0.18) or 0)
        if spins[id] then spins[id][axis] = nil end
    end
    function motion.cancel()
        Signal(SIG_MOTION)
        -- Freeze outstanding targets before a new setup or a hidden reset.
        for _, c in pairs(channels) do
            local native = c.turn and api.Turn or api.Move
            native(c.id, c.axis, position(c.id, c.axis, c.turn), 1)
        end
        channels, spins, running = {}, {}, false
    end
    return motion
end
