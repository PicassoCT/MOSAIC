-- Visual-only, deterministic choreography. No units, orders or MoveCtrl are
-- created here. Stations stay at their original world positions while a float
-- passes, then crossfade to the next curb audience instead of sliding people
-- and candles along the road.
local scene = {}
local sin, cos, pi, sqrt = math.sin, math.cos, math.pi, math.sqrt
local function clamp(value, low, high) return math.max(low, math.min(high, value)) end
local function smooth(value)
    value = clamp(value, 0, 1)
    return value * value * (3 - 2 * value)
end

function scene.updateStations(state, parent, x, z, dx, dz, seconds, config)
    local length = sqrt((dx or 0)^2 + (dz or 0)^2)
    if length < 0.001 then dx, dz = 0, 1 else dx, dz = dx / length, dz / length end
    if state.parent ~= parent or not state.lastSeen
        or seconds - state.lastSeen > config.visibilityResetSeconds or seconds < state.lastSeen then
        state.stations = nil
    end
    state.parent, state.lastSeen = parent, seconds
    state.stations = state.stations or {}
    local current = state.stations[#state.stations]
    if not current or (x - current.x)^2 + (z - current.z)^2 >= config.stationSpacing^2 then
        if current then current.retired = seconds end
        state.stations[#state.stations + 1] = {x = x, z = z, dx = dx, dz = dz,
            born = seconds, grounds = {}}
        -- Only the previous and current station are ever retained.
        while #state.stations > 2 do table.remove(state.stations, 1) end
    end
    local previous = state.stations[1]
    if previous and previous.retired and seconds - previous.retired >= config.stationFadeSeconds then
        table.remove(state.stations, 1)
    end
    return state.stations
end

function scene.stationOpacity(station, seconds, config)
    local alpha = smooth((seconds - station.born) / config.stationFadeSeconds)
    if station.retired then alpha = alpha * (1 - smooth((seconds - station.retired) / config.stationFadeSeconds)) end
    return alpha
end

function scene.pose(item, seconds, payloadID)
    local clock = seconds + (item.phase or 0) + payloadID * 0.173
    local pose = {x = item.x, y = item.hover or item.y or 0, z = item.z,
        yaw = item.x < 0 and 90 or -90, tilt = 0, headTilt = 0,
        opacity = item.opacity or 1, activity = "rest"}
    if item.category == "helper" then
        -- More than half of every cycle is a genuine pause. Two short trips,
        -- a deliberate task gesture and small hops provide the busy contrast
        -- to the still main audience without constant jitter.
        local cycle = clock % 10
        local travel, hop = 0, 0
        if cycle >= 5 and cycle < 6.4 then
            local t = (cycle - 5) / 1.4
            travel, hop = smooth(t), 0.58 * math.abs(sin(t * pi * 2))
            pose.activity = "approach"
        elseif cycle >= 6.4 and cycle < 8 then
            travel = 1
            pose.headTilt = 18 * sin((cycle - 6.4) / 1.6 * pi)
            pose.tilt = item.task == "gather" and 13 * sin((cycle - 6.4) / 1.6 * pi) or 0
            pose.activity = item.task or "tend"
        elseif cycle >= 8 and cycle < 9.4 then
            local t = (cycle - 8) / 1.4
            travel, hop = 1 - smooth(t), 0.58 * math.abs(sin(t * pi * 2))
            pose.activity = "return"
        end
        local direction = item.x < 0 and 1 or -1
        pose.x = pose.x + direction * travel * 2.8
        pose.z = pose.z + travel * (item.task == "gather" and 2.2 or 0.8)
        pose.y = pose.y + hop
        if hop > 0 then pose.tilt = sin(clock * pi) * 5 end
        if item.task == "guide" and pose.activity == "guide" then pose.yaw = pose.yaw + 22 * sin((cycle - 6.4) * pi) end
    elseif item.category == "dead" then
        pose.y = pose.y + 0.10 * sin(clock * 0.55)
        pose.headTilt = 1.4 * sin(clock * 0.21)
    elseif item.category == "ai" then
        pose.y = pose.y + 0.14 * sin(clock * 0.43)
        pose.headTilt = 1.1 * sin(clock * 0.19)
    elseif item.category == "civilian" then
        pose.headTilt = 1.5 * sin(clock * 0.17)
    elseif not item.ground then
        pose.y = pose.y + 0.18 * sin(clock * 0.6)
        pose.tilt = 2.0 * sin(clock * 0.31)
    end
    -- Never modulate a dead person's silhouette with data-loss/glitch effects.
    pose.opacity = pose.opacity * (0.98 + 0.02 * sin(clock * (item.ground and 2.1 or 0.7)))
    return pose
end

function scene.worldPose(station, item, seconds, payloadID, ground)
    local pose = scene.pose(item, seconds, payloadID)
    local localX, localZ = pose.x, pose.z
    pose.x = station.x + station.dz * localX + station.dx * localZ
    pose.z = station.z - station.dx * localX + station.dz * localZ
    pose.y = ground + pose.y
    -- Native figures face +Z; side audiences turn inward toward the route.
    local heading
    if math.atan2 then heading = math.atan2(station.dx, station.dz)
    elseif station.dz == 0 then heading = station.dx >= 0 and pi / 2 or -pi / 2
    else
        heading = math.atan(station.dx / station.dz)
        if station.dz < 0 then heading = heading + pi end
    end
    pose.yaw = pose.yaw + heading * 180 / pi
    return pose
end

return scene
