-- Run in the operative's unit-script environment. The authored hostagePoint
-- owns attachment placement; this helper animates the carrier's body only.
return function(unitID, pieces, options)
    options = options or {}
    local animation = {}
    local active, saved = false, nil
    local generation = 0
    local aimYaw, aimPitch, aimUntil = 0, 0, -1
    local wasAiming = false
    local yawAxis = options.yawAxis or 3
    local rollAxis = yawAxis == 3 and 2 or 3
    local signal = options.signal or 65536
    local owned = {}
    local gripUpper, gripLower, gunUpper, gunLower
    local function calibrateGun(pitch)
        if not options.retarget then return end
        -- Semantic torso frame: forward -Y, up Z. Aim rotates the forearm
        -- direction; the other arm stays wrapped across the captive's chest.
        gunUpper, gunLower = options.retarget(1, {-0.30, -0.75, -0.30},
            {0.12, -math.cos(pitch), 0.12 + math.sin(pitch)})
    end
    if options.retarget then
        gripUpper, gripLower = options.retarget(2, {0.35, -0.85, -0.30}, {-0.85, -0.5, 0.15})
        calibrateGun(0)
    end
    for _, name in ipairs({"center", "Torso", "Head", "UpArm1", "UpArm2",
        "LowArm1", "LowArm2", "Hand1", "Hand2", "UpLeg1", "UpLeg2",
        "LowLeg1", "LowLeg2"}) do
        if pieces[name] then owned[#owned + 1] = pieces[name] end
    end

    local function snap(command, part, axis, target)
        -- A zero-speed call alone leaves the preceding native animation queued.
        command(part, axis, target, 1)
        command(part, axis, target, 0)
    end

    local function turn(name, axis, degrees, speed)
        local part = pieces[name]
        if part then Turn(part, axis, math.rad(degrees), speed or 4) end
    end

    function animation:IsActive()
        return active
    end

    function animation:IsAiming()
        return active and Spring.GetGameFrame() <= aimUntil
    end

    function animation:Aim(yaw, pitch)
        if not active then return end
        aimYaw = type(yaw) == "number" and yaw == yaw and yaw or 0
        aimPitch = type(pitch) == "number" and pitch == pitch and pitch or 0
        calibrateGun(aimPitch)
        aimUntil = Spring.GetGameFrame() + 33
    end

    function animation:Step(frame, moving, seated)
        if not active then return end
        local aiming = frame <= aimUntil
        if aiming ~= wasAiming then
            if not aiming then calibrateGun(0) end
            wasAiming = aiming
            if options.onAimChanged then options.onAimChanged(aiming) end
        end
        -- Match the captive's shuffling legs using the shared simulation frame.
        local phase = frame * (2 * math.pi / 30) * 1.2
        local stride = moving and math.sin(phase) or 0
        local breath = math.sin(frame * (2 * math.pi / 90))
        turn("Torso", 1, 3 + breath * 0.7)
        Turn(pieces.Torso, yawAxis, aiming and aimYaw or 0, 8)
        turn("Head", 1, -3 - breath * 0.7)
        Turn(pieces.Head, yawAxis, aiming and aimYaw * -0.2 or 0, 8)

        -- The left arm remains across the captive's upper body. The right arm
        -- stays at gunpoint even outside aim mode; the gadget blocks discharges.
        if gripUpper then
            -- Each operative has different bind axes (notably the T-pose
            -- Propagator). Compile once per aim change, then play native Turns.
            for axis=1,3 do
                turn("UpArm2", axis, gripUpper[axis])
                turn("LowArm2", axis, gripLower[axis])
                turn("UpArm1", axis, gunUpper[axis])
                turn("LowArm1", axis, gunLower[axis])
            end
        else
            turn("UpArm2", 1, -65 + breath)
            turn("UpArm2", rollAxis, 20)
            turn("LowArm2", 1, -55)
            turn("LowArm2", yawAxis, -35)
            turn("LowArm2", rollAxis, -25)
            turn("UpArm1", 1, -80 - (aiming and math.deg(aimPitch) or 0))
            turn("UpArm1", rollAxis, -8)
            turn("LowArm1", 1, -12)
            turn("LowArm1", rollAxis, 0)
        end
        turn("Hand2", rollAxis, -12)
        turn("Hand1", 1, 0)

        turn("UpLeg1", 1, seated and -60 or -4 + 14 * stride)
        turn("UpLeg2", 1, seated and -60 or -4 - 14 * stride)
        turn("LowLeg1", 1, seated and 75 or 12 + 10 * math.max(0, -stride))
        turn("LowLeg2", 1, seated and 75 or 12 + 10 * math.max(0, stride))
    end

    local function animate(token)
        SetSignalMask(signal)
        while active and token == generation do
            local vx, _, vz = Spring.GetUnitVelocity(unitID)
            local moving = vx and vz and vx * vx + vz * vz > 0.01 or false
            animation:Step(Spring.GetGameFrame(), moving, Spring.GetUnitTransporter(unitID) ~= nil)
            Sleep(100)
        end
    end

    function animation:Capture()
        if active then return end
        generation = generation + 1
        active, saved = true, {}
        aimYaw, aimPitch, aimUntil, wasAiming = 0, 0, -1, false
        calibrateGun(0)
        for _, part in ipairs(owned) do
            saved[part] = {
                move = {Spring.UnitScript.GetPieceTranslation(part)},
                turn = {Spring.UnitScript.GetPieceRotation(part)},
            }
            for axis = 1, 3 do
                snap(Move, part, axis, 0)
                snap(Turn, part, axis, 0)
            end
        end
        self:Step(Spring.GetGameFrame(), false)
        Signal(signal)
        StartThread(animate, generation)
    end

    function animation:Release()
        if not active then return end
        generation = generation + 1
        active = false
        Signal(signal)
        for _, part in ipairs(owned) do
            for axis = 1, 3 do
                snap(Move, part, axis, saved[part].move[axis])
                snap(Turn, part, axis, saved[part].turn[axis])
            end
        end
        saved = nil
        if wasAiming and options.onAimChanged then options.onAimChanged(false) end
        wasAiming = false
    end

    return animation
end
