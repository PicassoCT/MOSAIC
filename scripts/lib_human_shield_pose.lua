-- Run in the civilian's unit-script environment. The gadget owns attachment;
-- this helper only places the visible body and restores every changed transform.
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
                if part ~= pieces.root then moveNow(part, axis, 0) end
                turnNow(part, axis, 0)
            end
        end

        local carrierPieces = Spring.GetUnitPieceMap(carrierID) or {}
        local anchor = carrierPieces.center or carrierPieces.root
        local ax, ay, az = 0, 0, 0
        if anchor then
            ax, ay, az = Spring.GetUnitPiecePosition(carrierID, anchor)
            ax, ay, az = ax or 0, ay or 0, az or 0
        end
        local _, _, carrierDepth = Spring.GetUnitCollisionVolumeData(carrierID)
        local _, _, civilianDepth = Spring.GetUnitCollisionVolumeData(unitID)
        -- Both hull depths are engine model units. Their combined half-depths
        -- keep the bodies just apart, with a little overlap for the hold.
        local forward = math.max(2, ((carrierDepth or 10) + (civilianDepth or 10)) * 0.4)
        local rootMove = saved[pieces.root].move
        -- These read APIs return native engine XYZ. The unit-script header's
        -- animation labels swap y_axis/z_axis for the exported civilian rig;
        -- keep physical placement in raw XYZ so vertical compensation remains
        -- vertical and forward separation remains on the unit's Z axis.
        moveNow(pieces.root, 1, rootMove[1] - ax)
        moveNow(pieces.root, 2, rootMove[2] - ay)
        moveNow(pieces.root, 3, rootMove[3] + forward - az)

        turnNow(pieces.UpBody, x_axis, math.rad(8))
        turnNow(pieces.Head1, x_axis, math.rad(-8))
        turnNow(pieces.UpArm1, x_axis, math.rad(-65))
        turnNow(pieces.UpArm2, x_axis, math.rad(-65))
        turnNow(pieces.LowArm1, x_axis, math.rad(-80))
        turnNow(pieces.LowArm2, x_axis, math.rad(-80))
        turnNow(pieces.LowArm1, z_axis, math.rad(-20))
        turnNow(pieces.LowArm2, z_axis, math.rad(20))
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
