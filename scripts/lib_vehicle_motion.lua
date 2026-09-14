-- Sample physical motion where trailer/tow animation consumes it. This still
-- detects pushing and blocked movement without two independent sensor threads.
return function(id)
    local oldX, _, oldZ = Spring.GetUnitPosition(id)
    local oldHeading = Spring.GetUnitHeading(id)
    local nextPositionFrame = Spring.GetGameFrame() + 3
    local moving = false
    return function()
        local frame = Spring.GetGameFrame()
        if frame >= nextPositionFrame then
            local x, _, z = Spring.GetUnitPosition(id)
            moving = math.abs(oldX - x) + math.abs(oldZ - z) > 5
            oldX, oldZ = x, z
            nextPositionFrame = frame + 3 -- old Sleep(125) cadence
        end
        local heading = Spring.GetUnitHeading(id)
        local delta = (heading - oldHeading + 32768) % 65536 - 32768
        oldHeading = heading
        return moving, delta ~= 0, delta < 0
    end
end
