-- Sample physical motion where trailer/tow animation consumes it. This still
-- detects pushing and blocked movement without two independent sensor threads.
return function(id)
    local getVelocity = Spring.GetUnitVelocity
    local oldX, _, oldZ = Spring.GetUnitPosition(id)
    local oldHeading = Spring.GetUnitHeading(id)
    local nextMotionFrame = Spring.GetGameFrame() + 3
    local moving = false
    return function()
        local frame = Spring.GetGameFrame()
        if frame >= nextMotionFrame then
            if getVelocity then
                -- GroundMoveType uses 0.01 as its physical moving threshold.
                -- Velocity does not misclassify a turn-in-place because a long
                -- model's visible ends sweep across the map.
                local vx, _, vz = getVelocity(id)
                moving = vx ~= nil and (vx * vx + vz * vz) > 0.0001
            else
                -- Test/legacy fallback where GetUnitVelocity is unavailable.
                local x, _, z = Spring.GetUnitPosition(id)
                moving = math.abs(oldX - x) + math.abs(oldZ - z) > 5
                oldX, oldZ = x, z
            end
            nextMotionFrame = frame + 3 -- old Sleep(125) cadence
        end
        local heading = Spring.GetUnitHeading(id)
        local delta = (heading - oldHeading + 32768) % 65536 - 32768
        oldHeading = heading
        -- Fourth return is the wrapped signed TA heading delta. Existing
        -- callers using only the first three results remain compatible.
        return moving, delta ~= 0, delta < 0, delta
    end
end
