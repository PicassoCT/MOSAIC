-- One pose owner for ordinary passengers. Hostages and death animations have
-- higher priority; vehicle scripts still own attachment, orders and boarding.
return function(unitID, pieces, context)
    local transport = {}
    local state
    local profilesByDef = {}
    local namedProfiles = {
        truckpayloadrefugee = "truck",
        air_parachut = "parachute",
    }
    for defID, def in pairs(UnitDefs) do
        local baseclass = (def.customParams or {}).baseclass
        if type(baseclass) == "string" and baseclass:lower() == "truck" then
            profilesByDef[defID] = "truck"
        end
    end
    for name, profile in pairs(namedProfiles) do
        local def = UnitDefNames[name]
        if def then profilesByDef[def.id] = profile end
    end

    local bodyPieces = {
        pieces.root, pieces.center, pieces.UpBody, pieces.Head1,
        pieces.UpArm1, pieces.UpArm2, pieces.LowArm1, pieces.LowArm2,
        pieces.UpLeg1, pieces.UpLeg2, pieces.LowLeg1, pieces.LowLeg2,
        pieces.Feet1, pieces.Feet2,
    }
    local upperPieces = {
        [pieces.center] = true, [pieces.UpBody] = true, [pieces.Head1] = true,
        [pieces.UpArm1] = true, [pieces.UpArm2] = true,
        [pieces.LowArm1] = true, [pieces.LowArm2] = true,
    }
    local allPieces = {}
    for _, part in ipairs(bodyPieces) do allPieces[part] = true end

    local function clamp(value, minimum, maximum)
        return math.max(minimum, math.min(maximum, value))
    end
    local function moveNow(part, axis, target)
        Move(part, axis, target, 1)
        Move(part, axis, target, 0)
    end
    local function turnNow(part, axis, target)
        Turn(part, axis, target, 1)
        Turn(part, axis, target, 0)
    end
    local function turn(part, axis, degrees, speed)
        Turn(part, axis, math.rad(degrees), speed or 2.5)
    end

    local function savePiece(part)
        return {
            move = {Spring.UnitScript.GetPieceTranslation(part)},
            turn = {Spring.UnitScript.GetPieceRotation(part)},
        }
    end

    local function restorePiece(part, saved)
        for axis = 1, 3 do
            moveNow(part, axis, saved.move[axis])
            turnNow(part, axis, saved.turn[axis])
        end
    end

    function transport:IsActive()
        return state ~= nil
    end

    function transport:OwnsUpperBody()
        return state ~= nil and not state.upperFree
    end

    function transport:OwnsPiece(part)
        return state ~= nil and allPieces[part] == true
            and (not state.upperFree or not upperPieces[part])
    end

    local function neutralizeOwnedPieces()
        for _, part in ipairs(bodyPieces) do
            if transport:OwnsPiece(part) then
                for axis = 1, 3 do
                    moveNow(part, axis, 0)
                    turnNow(part, axis, 0)
                end
            end
        end
    end

    function transport:Stop(resume)
        local previous = state
        if not previous then return false end
        state = nil
        for _, part in ipairs(bodyPieces) do
            local saved = previous.saved[part]
            if saved then restorePiece(part, saved) end
        end
        context.finish(resume ~= false)
        return true
    end

    local function motionCarrier(passengerCarrier)
        local current, seen = passengerCarrier, {}
        -- Refugee seats are a transported payload. Their own velocity can be
        -- zero while the truck moves, so sample the actual vehicle at the top.
        while current and not seen[current] do
            seen[current] = true
            local parent = Spring.GetUnitTransporter(current)
            if not parent or seen[parent] then return current end
            current = parent
        end
        return passengerCarrier
    end

    local function animate(frame, vehicle)
        local vx, _, vz = Spring.GetUnitVelocity(vehicle)
        vx, vz = vx or 0, vz or 0
        local front, _, right = Spring.GetUnitVectors(vehicle)
        front, right = front or {0, 0, 1}, right or {1, 0, 0}
        local elapsed = math.max(1, frame - (state.frame or frame))
        local ax = state.vx and (vx - state.vx) / elapsed or 0
        local az = state.vz and (vz - state.vz) / elapsed or 0
        local pitchTarget = clamp(-(ax * front[1] + az * front[3]) * 80, -7, 7)
        local rollTarget = clamp((ax * right[1] + az * right[3]) * 80, -6, 6)
        state.pitch = state.pitch + (pitchTarget - state.pitch) * 0.35
        state.roll = state.roll + (rollTarget - state.roll) * 0.35
        state.vx, state.vz, state.frame = vx, vz, frame

        local seconds = frame / 30
        local breath = math.sin(seconds * 2 + unitID * 0.7)
        local roadMotion = math.min(1.2, math.sqrt(vx * vx + vz * vz) * 0.35)
        local bounce = roadMotion * math.sin(seconds * 11 + unitID)
        if state.profile == "parachute" then
            -- Suspended legs and raised hands belong to the parachute only.
            -- Road passengers keep their knees folded and hands braced below.
            turn(pieces.UpLeg1, x_axis, -12 + 3 * breath)
            turn(pieces.UpLeg2, x_axis, -12 - 3 * breath)
            turn(pieces.LowLeg1, x_axis, 24)
            turn(pieces.LowLeg2, x_axis, 28)
            turn(pieces.Feet1, x_axis, -6)
            turn(pieces.Feet2, x_axis, -6)
            turn(pieces.UpBody, x_axis, 4 + breath)
            turn(pieces.UpBody, z_axis, state.roll)
            turn(pieces.Head1, x_axis, -5)
            turn(pieces.UpArm1, x_axis, -145)
            turn(pieces.UpArm2, x_axis, -145)
            turn(pieces.UpArm1, z_axis, -12)
            turn(pieces.UpArm2, z_axis, 12)
            turn(pieces.LowArm1, x_axis, -30)
            turn(pieces.LowArm2, x_axis, -30)
            return
        end

        turn(pieces.UpLeg1, x_axis, -65)
        turn(pieces.UpLeg2, x_axis, -65)
        turn(pieces.UpLeg1, z_axis, -7)
        turn(pieces.UpLeg2, z_axis, 7)
        turn(pieces.LowLeg1, x_axis, 95 + bounce)
        turn(pieces.LowLeg2, x_axis, 95 - bounce)
        turn(pieces.Feet1, x_axis, -25)
        turn(pieces.Feet2, x_axis, -25)
        if not state.upperFree then
            turn(pieces.UpBody, x_axis, 8 + state.pitch + breath + bounce)
            turn(pieces.UpBody, z_axis, state.roll)
            turn(pieces.Head1, x_axis, -6 - state.pitch * 0.5)
            turn(pieces.Head1, y_axis, math.sin(seconds * 0.65 + unitID) * 5)
            turn(pieces.UpArm1, x_axis, -25 - state.pitch * 0.5)
            turn(pieces.UpArm2, x_axis, -25 - state.pitch * 0.5)
            turn(pieces.UpArm1, z_axis, -10)
            turn(pieces.UpArm2, z_axis, 10)
            turn(pieces.LowArm1, x_axis, -75 - state.roll)
            turn(pieces.LowArm2, x_axis, -75 + state.roll)
        end
    end

    function transport:Update(frame)
        if context.blocked() then self:Stop(false); return false end
        local carrier = Spring.GetUnitTransporter(unitID)
        local profile = carrier and profilesByDef[Spring.GetUnitDefID(carrier)]
        if not profile then self:Stop(true); return false end
        local upperFree = profile == "truck" and context.upperBodyFree()
        if state and (state.carrier ~= carrier or state.profile ~= profile) then
            self:Stop(false)
        end
        if not state then
            state = {carrier = carrier, profile = profile, upperFree = upperFree,
                saved = {}, pitch = 0, roll = 0}
            for _, part in ipairs(bodyPieces) do
                if self:OwnsPiece(part) then state.saved[part] = savePiece(part) end
            end
            context.begin()
            neutralizeOwnedPieces()
        elseif state.upperFree ~= upperFree then
            -- Give aiming arms back without leaving bracing targets queued.
            -- When the torso becomes ours again, remember its current pose;
            -- unloading must not rewind an armed passenger's later aiming.
            for _, part in ipairs(bodyPieces) do
                if upperPieces[part] then
                    if upperFree then
                        if state.saved[part] then restorePiece(part, state.saved[part]) end
                        state.saved[part] = nil
                    else
                        state.saved[part] = savePiece(part)
                    end
                end
            end
            state.upperFree = upperFree
            if not upperFree and context.reclaimUpper then context.reclaimUpper() end
            neutralizeOwnedPieces()
        end
        animate(frame, motionCarrier(carrier))
        return true
    end

    return transport
end
