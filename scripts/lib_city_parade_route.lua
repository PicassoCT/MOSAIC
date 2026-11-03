-- A bounded circuit through the existing civilian route graph. Native paths
-- must reach every curb before any parade vehicle is allowed to assemble.
local Route = {}
local huge = math.huge
local function finite(value)
    return type(value) == "number" and value == value and value > -huge and value < huge
end
local function distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.z - b.z)^2)
end
local function copyPoint(point)
    return {x = point.x, y = point.y, z = point.z}
end
local function rotate(values, start)
    local result = {}
    for offset = 0, #values - 1 do result[#result + 1] = values[(start + offset - 1) % #values + 1] end
    return result
end
local function rank(id, seed)
    return ((id * 48271) % 2147483647) * (seed % 65521 + 1) % 2147483647
end

function Route.new(context)
    local S, G, defs = context.Spring, context.GG, context.UnitDefs
    local config = context.config or {}
    local function option(key, default, low, high)
        local value = config[key]
        if not finite(value) then value = default end
        return math.max(low, math.min(high, value))
    end
    local maxAttempts = math.floor(option("routeMaxAttempts", 12, 1, 32))
    local maxRequests = math.floor(option("routeMaxRequests", 18, 2, 64))
    local minNodes = math.floor(option("routeMinNodes", 4, 2, 6))
    local maxNodes = math.floor(option("routeMaxNodes", 6, minNodes, 8))
    local maxCandidates = math.floor(option("routeMaxCandidates", 96, maxNodes, 256))
    local maxSearchSteps = math.floor(option("routeMaxSearchSteps", 1024, 16, 8192))
    local minLeg = option("routeMinLegDistance", 180, 32, 2048)
    local minLength = option("routeMinLength", 900, 64, 32768)
    local stagingGap = option("routeStagingGap", 80, 16, 2048)
    local endpointTolerance = option("routeEndpointTolerance", 32, 4, 64)
    local sampleSpacing = option("routeSampleSpacing", 40, 8, 64)
    local maxSamples = math.floor(option("routeMaxSamples", 4096, 32, 16384))
    local maxWaypoints = math.floor(option("routeMaxWaypoints", 2048, 16, 8192))
    local maxPolls = math.floor(option("routePathPollLimit", 60, 1, 300))
    local builder = {}
    local selectionKey, rejected, rejectionOrder = nil, {}, {}

    local function rejectCircuit(key, signature)
        if key ~= selectionKey or not signature or rejected[signature] then return end
        rejected[signature] = true
        rejectionOrder[#rejectionOrder + 1] = signature
        if #rejectionOrder > 32 then rejected[table.remove(rejectionOrder, 1)] = nil end
    end

    local function dangerous(x, z)
        return G.CityAreaState and G.CityAreaState.IsDangerous and G.CityAreaState:IsDangerous(x, z)
    end
    local function nodePosition(id)
        if type(id) ~= "number" or not S.ValidUnitID(id) or S.GetUnitIsDead(id) or
            (G.BuildingTable and not G.BuildingTable[id]) then return nil end
        local x, y, z = S.GetUnitPosition(id)
        if not finite(x) or not finite(y) or not finite(z) or dangerous(x, z) then return nil end
        return {x = x, y = y, z = z}
    end
    local function safePoint(point, defID, terrainOnly)
        if type(point) ~= "table" then return nil end
        local x, z = point.x or point[1], point.z or point[3]
        if not finite(x) or not finite(z) or dangerous(x, z) then return nil end
        local y = S.GetGroundHeight(x, z)
        if not finite(y) or y < 0 then return nil end
        local traversable
        if terrainOnly then
            -- Native paths provide static obstacle avoidance. Moving everyday
            -- traffic must not invalidate an otherwise usable procession route.
            traversable = S.TestMoveOrder(defID, x, y, z, 0, 0, 0, true, false)
        else
            traversable = S.TestMoveOrder(defID, x, y, z)
        end
        if not traversable then return nil end
        return {x = x, y = y, z = z}
    end
    local function invalidate(route, reason)
        route.status, route.reason = "invalid", reason
        rejectCircuit(route._key, route._signature)
        return "invalid"
    end

    function builder:Begin(day, defID)
        self.lastError = nil
        local traffic = G.CivilianTraffic
        local def = defs[defID]
        local moveDefID = def and def.moveDef and def.moveDef.id
        if not finite(day) or not finite(defID) or not finite(moveDefID) or
            type(S.RequestPath) ~= "function" or type(S.TestMoveOrder) ~= "function" or
            type(S.GetGroundHeight) ~= "function" or type(S.ValidUnitID) ~= "function" or
            type(S.GetUnitIsDead) ~= "function" or type(S.GetUnitPosition) ~= "function" or
            not traffic or type(traffic.GetRoutes) ~= "function" or type(traffic.Point) ~= "function" then
            self.lastError = "native path or civilian traffic API unavailable"
            return nil
        end
        local key = tostring(math.floor(day)) .. ":" .. tostring(defID)
        if key ~= selectionKey then selectionKey, rejected, rejectionOrder = key, {}, {} end
        local graph = traffic.GetRoutes()
        if type(graph) ~= "table" then self.lastError = "civilian route graph unavailable"; return nil end
        local allIDs = {}
        for id, edges in pairs(graph) do
            if type(id) == "number" and type(edges) == "table" and #edges > 0 then allIDs[#allIDs + 1] = id end
        end
        table.sort(allIDs)
        if #allIDs < 2 then self.lastError = "fewer than two route nodes"; return nil end
        local seed = (math.floor(day) * 104729 + defID * 97) % 2147483647
        local nodes, positions = {}, {}
        local first = seed % #allIDs
        for offset = 0, #allIDs - 1 do
            local id = allIDs[(first + offset) % #allIDs + 1]
            local position = nodePosition(id)
            if position then
                nodes[#nodes + 1], positions[id] = id, position
                if #nodes == maxCandidates then break end
            end
        end
        if #nodes < 2 then self.lastError = "fewer than two peaceful live nodes"; return nil end
        table.sort(nodes, function(a, b)
            local ar, br = rank(a, seed), rank(b, seed)
            return ar == br and a < b or ar < br
        end)
        local adjacency, connected = {}, {}
        for _, id in ipairs(nodes) do
            adjacency[id], connected[id] = {}, {}
            for _, other in ipairs(graph[id]) do
                if positions[other] and other ~= id and not connected[id][other] then
                    adjacency[id][#adjacency[id] + 1] = other
                    connected[id][other] = true
                end
            end
        end
        local searchSteps, requests = 0, 0
        local preferred = math.min(#nodes, minNodes + seed % (maxNodes - minNodes + 1))
        for attempt = 1, maxAttempts do
            local desired = preferred
            if attempt > math.floor(maxAttempts * 0.5) then desired = math.min(#nodes, minNodes) end
            -- A sparse reachable component may only offer an out-and-back pair.
            if attempt > math.floor(maxAttempts * 0.8) then desired = 2 end
            local start = nodes[(attempt - 1) % #nodes + 1]
            local selected, used = {start}, {[start] = true}
            local function extend(id)
                if #selected == desired then return connected[id][start] == true end
                local choices = {}
                for _, other in ipairs(adjacency[id]) do
                    if not used[other] then choices[#choices + 1] = other end
                end
                table.sort(choices, function(a, b)
                    local ar, br = rank(a, seed + attempt * 701), rank(b, seed + attempt * 701)
                    return ar == br and a < b or ar < br
                end)
                for _, other in ipairs(choices) do
                    searchSteps = searchSteps + 1
                    if searchSteps > maxSearchSteps then return false end
                    if distance(positions[id], positions[other]) >= minLeg then
                        used[other], selected[#selected + 1] = true, other
                        if extend(other) then return true end
                        used[other], selected[#selected] = nil, nil
                    end
                end
                return false
            end
            if extend(start) and not rejected[table.concat(selected, ",")] then
                local signature = table.concat(selected, ",")
                local curbs, length, valid = {}, 0, true
                for index, id in ipairs(selected) do
                    local nextID = selected[index % #selected + 1]
                    local point = safePoint(traffic.Point(id, defID, nextID), defID)
                    if not point then valid = false; break end
                    curbs[index] = point
                end
                if valid then
                    for index, point in ipairs(curbs) do
                        local legLength = distance(point, curbs[index % #curbs + 1])
                        if legLength < minLeg then valid = false; break end
                        length = length + legLength
                    end
                end
                local requiredLength = #selected < minNodes and math.min(minLength, minLeg * #selected) or minLength
                if valid and length >= requiredLength and requests + #curbs <= maxRequests then
                    local paths = {}
                    for index, origin in ipairs(curbs) do
                        local goal = curbs[index % #curbs + 1]
                        requests = requests + 1
                        local ok, path = pcall(S.RequestPath, moveDefID, origin.x, origin.y, origin.z,
                            goal.x, goal.y, goal.z, endpointTolerance)
                        if not ok or (type(path) ~= "table" and type(path) ~= "userdata") or
                            type(path.GetPathWayPoints) ~= "function" then valid = false; break end
                        paths[index] = path
                    end
                    if valid then
                        local points = {}
                        for _, point in ipairs(curbs) do points[#points + 1] = copyPoint(point) end
                        points[#points + 1] = copyPoint(curbs[1])
                        return {points = points, nodes = selected, length = length, paths = paths,
                            defID = defID, status = "pending", polls = 0, requests = requests,
                            _curbs = curbs, _segments = {}, _samples = 0, _key = key, _signature = signature}
                    end
                    rejectCircuit(key, signature)
                end
            end
            if searchSteps >= maxSearchSteps or requests >= maxRequests then break end
        end
        self.lastError = "no safe circuit within route search budget"
        return nil
    end

    local function validateSegment(route, origin, goal, waypoints)
        if #waypoints > maxWaypoints then return nil, "native path exceeded waypoint budget" end
        local last = waypoints[#waypoints]
        local terminal = last and safePoint(last, route.defID, true)
        if not terminal or distance(terminal, goal) > endpointTolerance then
            return nil, "native path did not reach its curb"
        end
        local raw = {origin}
        for _, waypoint in ipairs(waypoints) do
            local point = safePoint(waypoint, route.defID, true)
            if not point then return nil, "unsafe native waypoint" end
            if distance(raw[#raw], point) > 0.01 then raw[#raw + 1] = point end
        end
        if distance(raw[#raw], goal) > 0.01 then raw[#raw + 1] = goal end
        for index = 2, #raw do
            local a, b = raw[index - 1], raw[index]
            local count = math.max(1, math.ceil(distance(a, b) / sampleSpacing))
            route._samples = route._samples + count
            if route._samples > maxSamples then return nil, "native path exceeded safety sample budget" end
            for sample = 1, count do
                local fraction = sample / count
                if not safePoint({x = a.x + (b.x - a.x) * fraction,
                    z = a.z + (b.z - a.z) * fraction}, route.defID, true) then
                    return nil, "unsafe segment between native waypoints"
                end
            end
        end
        -- Drop only collinear samples, retaining every actual corner. Commands
        -- therefore follow the native route instead of cutting through blocks.
        local compact = {raw[1]}
        for index = 2, #raw - 1 do
            local a, b, c = raw[index - 1], raw[index], raw[index + 1]
            local ax, az, bx, bz = b.x - a.x, b.z - a.z, c.x - b.x, c.z - b.z
            local cross, dot = math.abs(ax * bz - az * bx), ax * bx + az * bz
            if dot <= 0 or cross > 0.00001 * math.sqrt((ax * ax + az * az) * (bx * bx + bz * bz)) then
                compact[#compact + 1] = b
            end
        end
        if #raw > 1 then compact[#compact + 1] = raw[#raw] end
        return compact
    end

    function builder:Poll(route)
        if type(route) ~= "table" or not route._curbs then return "invalid" end
        if route.status ~= "pending" then return route.status end
        route.polls = route.polls + 1
        for _, id in ipairs(route.nodes) do
            if not nodePosition(id) then return invalidate(route, "route building lost or unsafe") end
        end
        local pending, nativePoints = false, {}
        for index, path in ipairs(route.paths) do
            local ok, points = pcall(path.GetPathWayPoints, path)
            if not ok then return invalidate(route, "native path lookup failed") end
            if points == nil or type(points) == "table" and #points == 0 then pending = true
            elseif type(points) ~= "table" then return invalidate(route, "native path did not return waypoints")
            else nativePoints[index] = points end
        end
        if pending then
            if route.polls >= maxPolls then return invalidate(route, "native path wait expired") end
            return "pending"
        end
        -- Validate all legs together once every asynchronous result is ready.
        -- A completed leg cannot retain a stale safety verdict while another
        -- path is pending and combat changes the city around it.
        for index, points in ipairs(nativePoints) do
            local segment, reason = validateSegment(route, route._curbs[index],
                route._curbs[index % #route._curbs + 1], points)
            if not segment then return invalidate(route, reason) end
            route._segments[index] = segment
        end
        local stagingIndex
        for index, segment in ipairs(route._segments) do
            if #segment >= 2 and distance(segment[1], segment[2]) >= stagingGap then stagingIndex = index; break end
        end
        if not stagingIndex then return invalidate(route, "no clear staging approach") end
        route.nodes, route.paths = rotate(route.nodes, stagingIndex), rotate(route.paths, stagingIndex)
        route._curbs, route._segments = rotate(route._curbs, stagingIndex), rotate(route._segments, stagingIndex)
        local points, length = {}, 0
        for _, segment in ipairs(route._segments) do
            for _, point in ipairs(segment) do
                local previous = points[#points]
                if not previous or distance(previous, point) > 0.01 then
                    if previous then length = length + distance(previous, point) end
                    points[#points + 1] = copyPoint(point)
                end
            end
        end
        route.points, route.length, route.status = points, length, "ready"
        return "ready"
    end

    return builder
end

return Route
