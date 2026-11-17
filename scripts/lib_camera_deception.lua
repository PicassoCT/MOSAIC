-- Shared cone geometry: simulation and presentation use the same moving lens.
local M = {
    broadcastRange = 180,
    countermeasureRange = 100,
    updateFrames = 15,
    halfAngle = math.rad(35),
    contactCount = 3,
}
local coneCosSquared = math.cos(M.halfAngle)^2

function M.Direction(id, eye)
    if eye then
        -- The spycam lens faces model +X. Read its actual animated basis,
        -- avoiding duplicated animation state or per-frame rules-param traffic.
        local mx, my, mz = Spring.GetUnitPieceMatrix(id, eye)
        local front, up, right = Spring.GetUnitVectors(id)
        if mx and front then
            local x = -right[1] * mx + up[1] * my + front[1] * mz
            local z = -right[3] * mx + up[3] * my + front[3] * mz
            local length = math.sqrt(x * x + z * z)
            if length > 0.001 then return x / length, z / length end
        end
    end
    local heading = (Spring.GetUnitHeading(id) or 0) * math.pi / 32768 + math.pi / 2
    return math.sin(heading), math.cos(heading)
end

function M.InCone(dx, dz, forwardX, forwardZ, range, dy)
    local distanceSquared = dx * dx + dz * dz
    local dot = dx * forwardX + dz * forwardZ
    return distanceSquared + (dy or 0)^2 <= range * range and dot >= 0
        and dot * dot >= distanceSquared * coneCosSquared
end

function M.Contact(cameraID, index, frame, range, forwardX, forwardZ)
    local phase = frame / 90 + cameraID * 0.37 + index * 2.1
    local angle = math.sin(phase * 0.7) * M.halfAngle * 0.75
    local distance = range * (0.45 + 0.35 * (0.5 + 0.5 * math.sin(phase)))
    local side, forward = math.sin(angle) * distance, math.cos(angle) * distance
    return forwardX * forward + forwardZ * side, forwardZ * forward - forwardX * side
end

return M
