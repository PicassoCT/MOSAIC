-- Run in the civilian's unit-script environment. The gadget owns attachment;
-- this helper owns captive motion and restores every changed transform.
return function(unitID, pieces)
    local saved
    local pose = {}
    local bodyPieces = {
        pieces.root, pieces.center, pieces.UpBody, pieces.Head1,
        pieces.UpArm1, pieces.UpArm2, pieces.LowArm1, pieces.LowArm2,
        pieces.UpLeg1, pieces.UpLeg2, pieces.LowLeg1, pieces.LowLeg2,
        pieces.Feet1, pieces.Feet2,
    }

    -- Killing a Lua coroutine does not cancel its native limb motion. Replace
    -- that destination first, then snap; otherwise an old walk/prayer target
    -- could pull the body out of the captive pose on the next engine frame.
    local function moveNow(part, axis, target)
        Move(part, axis, target, 1)
        Move(part, axis, target, 0)
    end
    local function turnNow(part, axis, target)
        Turn(part, axis, target, 1)
        Turn(part, axis, target, 0)
    end

    function pose:Capture(carrierID)
        if saved then return end
        saved = {}
        for _, part in ipairs(bodyPieces) do
            saved[part] = {
                move = {Spring.UnitScript.GetPieceTranslation(part)},
                turn = {Spring.UnitScript.GetPieceRotation(part)},
            }
            for axis = 1, 3 do
                moveNow(part, axis, 0)
                turnNow(part, axis, 0)
            end
        end

        -- UnitAttach places the model at the authored hostagePoint. Neutralize
        -- transient animation deltas without compensating for that point's
        -- position or collision hull; either would undo the artist's placement.
        turnNow(pieces.UpBody, x_axis, math.rad(8))
        turnNow(pieces.Head1, x_axis, math.rad(-8))
        turnNow(pieces.UpArm1, x_axis, math.rad(-65))
        turnNow(pieces.UpArm2, x_axis, math.rad(-65))
        turnNow(pieces.LowArm1, x_axis, math.rad(-80))
        turnNow(pieces.LowArm2, x_axis, math.rad(-80))
        turnNow(pieces.LowArm1, z_axis, math.rad(-20))
        turnNow(pieces.LowArm2, z_axis, math.rad(20))
        turnNow(pieces.UpLeg1, x_axis, math.rad(-4))
        turnNow(pieces.UpLeg2, x_axis, math.rad(-4))
        turnNow(pieces.LowLeg1, x_axis, math.rad(12))
        turnNow(pieces.LowLeg2, x_axis, math.rad(12))
        turnNow(pieces.Feet1, x_axis, math.rad(-8))
        turnNow(pieces.Feet2, x_axis, math.rad(-8))
    end

    function pose:Animate(carrierID, frame)
        if not saved then return false end
        local seated = Spring.GetUnitTransporter(carrierID) ~= nil
        local vx, _, vz = Spring.GetUnitVelocity(carrierID)
        local moving = not seated and vx and vz and vx * vx + vz * vz > 0.01
        local seconds = frame / 30
        local breath = math.sin(seconds * 2.1)
        local struggle = math.sin(seconds * 3.7) * math.sin(seconds * 0.7)^4
        -- The operative uses the same global-frame phase. Both bodies take
        -- short matching steps while the restrained upper body keeps its hold.
        local stride = moving and math.sin(seconds * 2 * math.pi * 1.2) or 0
        local leftLift, rightLift = math.max(0, -stride), math.max(0, stride)
        local hipRest, kneeRest, footRest = -4, 12, -8
        if seated then hipRest, kneeRest, footRest = -60, 75, -15 end
        local speed = 2.5
        local function turn(part, axis, degrees)
            Turn(part, axis, math.rad(degrees), speed)
        end

        turn(pieces.UpBody, x_axis, 8 + 1.5 * breath)
        turn(pieces.UpBody, y_axis, 2 * struggle)
        turn(pieces.Head1, x_axis, -8 - 1.5 * breath)
        turn(pieces.Head1, y_axis, 6 * struggle)
        turn(pieces.UpArm1, x_axis, -65 + 3 * struggle)
        turn(pieces.UpArm2, x_axis, -65 - 3 * struggle)
        turn(pieces.LowArm1, x_axis, -80 - 5 * struggle)
        turn(pieces.LowArm2, x_axis, -80 + 5 * struggle)
        turn(pieces.UpLeg1, x_axis, hipRest + 14 * stride)
        turn(pieces.UpLeg2, x_axis, hipRest - 14 * stride)
        turn(pieces.LowLeg1, x_axis, kneeRest + 10 * leftLift)
        turn(pieces.LowLeg2, x_axis, kneeRest + 10 * rightLift)
        turn(pieces.Feet1, x_axis, footRest - 4 * leftLift)
        turn(pieces.Feet2, x_axis, footRest - 4 * rightLift)
        return true
    end

    function pose:Release()
        if not saved then return end
        for _, part in ipairs(bodyPieces) do
            local previous = saved[part]
            for axis = 1, 3 do
                moveNow(part, axis, previous.move[axis])
                turnNow(part, axis, previous.turn[axis])
            end
        end
        saved = nil
    end

    return pose
end
