-- Run from the repository root: lua tests/city_parade_route_test.lua
local Route = assert(loadfile("scripts/lib_city_parade_route.lua"))()
local function squared(a, b) return (a.x - b.x)^2 + (a.z - b.z)^2 end
local function point(x, z) return {x = x, y = 10, z = z} end
local function same(a, b) return squared(a, b) < 0.0001 end
local function fixture(count, config)
    local f = {positions = {}, graph = {}, requests = {}, handles = {}, ready = true}
    for id = 1, count do
        f.positions[id] = point(200 + ((id - 1) % 3) * 700, 200 + math.floor((id - 1) / 3) * 700)
        f.graph[id] = {}
        for other = 1, count do if id ~= other then f.graph[id][#f.graph[id] + 1] = other end end
    end
    f.GG = {BuildingTable = {}, CivilianTraffic = {}, CityAreaState = {}}
    for id = 1, count do f.GG.BuildingTable[id] = true end
    f.GG.CivilianTraffic.GetRoutes = function() return f.graph end
    f.GG.CivilianTraffic.Point = function(id, defID, towardID)
        assert(defID == 41 and f.positions[towardID])
        return f.positions[id]
    end
    f.GG.CityAreaState.IsDangerous = function(_, x, z) return f.danger and f.danger(x, z) or false end
    f.Spring = {
        ValidUnitID = function(id) return f.positions[id] ~= nil end,
        GetUnitIsDead = function(id) return f.dead == id end,
        GetUnitPosition = function(id)
            local p = f.positions[id]; if p then return p.x, p.y, p.z end
        end,
        GetGroundHeight = function(x, z) return f.water and f.water(x, z) and -10 or 10 end,
        TestMoveOrder = function(defID, x, y, z, dx, dy, dz, testTerrain, testObjects)
            assert(defID == 41 and y >= 0)
            if testObjects == false then
                assert(dx == 0 and dy == 0 and dz == 0 and testTerrain == true)
                f.terrainOnlyCalls = (f.terrainOnlyCalls or 0) + 1
            end
            return (not f.terrainBlocked or not f.terrainBlocked(x, z)) and
                (testObjects == false or not f.blocked or not f.blocked(x, z))
        end,
    }
    f.Spring.RequestPath = function(moveDefID, ax, ay, az, bx, by, bz, tolerance)
        assert(moveDefID == 17 and tolerance == 32, "incorrect carrier moveDef or radius")
        local a, b = point(ax, az), point(bx, bz)
        local index = #f.requests + 1
        f.requests[index] = {a = a, b = b}
        if f.failRequest then return nil end
        local handle = {}
        function handle:GetPathWayPoints()
            assert(self == handle, "native path lost its receiver")
            if not f.ready then return {} end
            if f.path then return f.path(a, b, index) end
            return {{ax, ay, az}, {(ax + bx) / 2, 10, (az + bz) / 2}, {bx, by, bz}}
        end
        f.handles[index] = handle
        return handle
    end
    f.builder = Route.new({Spring = f.Spring, GG = f.GG,
        UnitDefs = {[41] = {moveDef = {id = 17}}}, config = config or {}})
    return f
end

-- Deterministic variation uses the existing graph without consuming the game's
-- shared random stream. Every edge, including closure, is a native path request.
do
    local f, again, nextWeek = fixture(8), fixture(8), fixture(8)
    local route = assert(f.builder:Begin(7, 41))
    local repeated = assert(again.builder:Begin(7, 41))
    local later = assert(nextWeek.builder:Begin(14, 41))
    assert(#route.nodes >= 4 and #route.nodes <= 6)
    assert(table.concat(route.nodes, ",") == table.concat(repeated.nodes, ","))
    assert(table.concat(route.nodes, ",") ~= table.concat(later.nodes, ","))
    assert(#f.requests == #route.nodes and #route.paths == #route.nodes)
    assert(f.builder:Poll(route) == "ready")
    assert(same(route.points[1], route.points[#route.points]), "route must close at staging")
    assert(squared(route.points[1], route.points[2]) >= 80^2)
    assert(route.length >= 900 and #route.points == #route.nodes + 1)
    assert(f.builder:Poll(route) == "ready")
end

-- Sparse cities still get a fully checked out-and-back circuit.
do
    local f = fixture(2)
    local route = assert(f.builder:Begin(7, 41))
    assert(#route.nodes == 2 and f.builder:Poll(route) == "ready")
    assert(#route.points == 3 and same(route.points[1], route.points[3]))
end

-- Empty waypoints are asynchronous, and retaining the path userdata is part of
-- the contract. A pending result can never be mistaken for a drivable route.
do
    local f = fixture(6)
    f.ready = false
    local route = assert(f.builder:Begin(7, 41))
    assert(f.builder:Poll(route) == "pending")
    for index, handle in ipairs(f.handles) do assert(route.paths[index] == handle) end
    assert(f.builder:Poll(route) == "pending")
    f.ready = true
    assert(f.builder:Poll(route) == "ready")
    local timeout = fixture(4, {routePathPollLimit = 2})
    timeout.ready = false
    local waiting = assert(timeout.builder:Begin(7, 41))
    assert(timeout.builder:Poll(waiting) == "pending")
    assert(timeout.builder:Poll(waiting) == "invalid")
end

-- A truthy handle with a truncated route is not proof of reachability.
do
    local f = fixture(6)
    f.path = function(a, b) return {a, point((a.x + b.x) / 2, (a.z + b.z) / 2)} end
    local route = assert(f.builder:Begin(7, 41))
    assert(f.builder:Poll(route) == "invalid")
    assert(route.reason == "native path did not reach its curb")
end

-- Preserve real native corners while removing redundant collinear samples.
do
    local f = fixture(6)
    f.path = function(a, b) return {a, point(a.x, b.z), b} end
    local route = assert(f.builder:Begin(7, 41))
    assert(f.builder:Poll(route) == "ready")
    local corners = 0
    for _, request in ipairs(f.requests) do
        if request.a.x ~= request.b.x and request.a.z ~= request.b.z then
            local expected, found = point(request.a.x, request.b.z), false
            for _, p in ipairs(route.points) do if same(p, expected) then found = true; break end end
            assert(found, "native corner was cut")
            corners = corners + 1
        end
    end
    assert(corners > 0)
end

-- Safety covers the spaces between waypoints, not only building destinations.
for _, hazard in ipairs({"danger", "water", "terrainBlocked"}) do
    local f = fixture(4)
    local route = assert(f.builder:Begin(7, 41))
    local a, b = route.points[1], route.points[2]
    local mx, mz = (a.x + b.x) / 2, (a.z + b.z) / 2
    f[hazard] = function(x, z) return (x - mx)^2 + (z - mz)^2 < 65^2 end
    assert(f.builder:Poll(route) == "invalid", "route crossed " .. hazard)
end

-- Static geometry comes from the native path; civilian cars/pedestrians which
-- arrive after the curb was sampled do not veto all native path waypoints.
do
    local f = fixture(4)
    local route = assert(f.builder:Begin(7, 41))
    f.blocked = function() return true end
    assert(f.builder:Poll(route) == "ready" and f.terrainOnlyCalls > 0)
end

-- Assembly retries advance beyond rejected native circuits deterministically,
-- and the rejection cache cannot poison a later seventh evening.
do
    local f = fixture(8)
    local route = assert(f.builder:Begin(7, 41))
    local signature = table.concat(route.nodes, ",")
    f.path = function(a, b) return {a, point((a.x + b.x) / 2, (a.z + b.z) / 2)} end
    assert(f.builder:Poll(route) == "invalid")
    f.path = nil
    local retry = assert(f.builder:Begin(7, 41))
    assert(table.concat(retry.nodes, ",") ~= signature and f.builder:Poll(retry) == "ready")
    local later, clean = assert(f.builder:Begin(14, 41)), fixture(8)
    assert(table.concat(later.nodes, ",") == table.concat(assert(clean.builder:Begin(14, 41)).nodes, ","))
end

-- Native API, blocked curbs, dead nodes and unclosed graph edges fail closed.
do
    local f = fixture(4)
    f.Spring.RequestPath = nil
    assert(f.builder:Begin(7, 41) == nil)
    local blocked = fixture(4)
    blocked.blocked = function() return true end
    assert(blocked.builder:Begin(7, 41) == nil and #blocked.requests == 0)
    local disconnected = fixture(4)
    disconnected.graph = {[1] = {2}, [2] = {3}, [3] = {4}, [4] = {}}
    assert(disconnected.builder:Begin(7, 41) == nil)
    local dying = fixture(4)
    local route = assert(dying.builder:Begin(7, 41))
    dying.dead = route.nodes[1]
    assert(dying.builder:Poll(route) == "invalid")
end

-- Failed requests and safety work both have finite budgets.
do
    local f = fixture(8, {routeMaxRequests = 5, routeMaxAttempts = 12})
    f.failRequest = true
    assert(f.builder:Begin(7, 41) == nil and #f.requests > 0 and #f.requests <= 5)
    local samples = fixture(4, {routeMaxSamples = 32})
    local route = assert(samples.builder:Begin(7, 41))
    assert(samples.builder:Poll(route) == "invalid")
    assert(route.reason == "native path exceeded safety sample budget")
end

-- An immediate corner cannot be removed to make room for the staging convoy.
-- Another sampled curb may provide a safe first driving goal instead.
do
    local f = fixture(6)
    f.path = function(a, b, index)
        if index == 1 then return {a, point(a.x + 20, a.z + 20), b} end
        return {a, b}
    end
    local route = assert(f.builder:Begin(7, 41))
    local initial = route.nodes[1]
    assert(f.builder:Poll(route) == "ready")
    assert(route.nodes[1] ~= initial and squared(route.points[1], route.points[2]) >= 80^2)
    local trapped = fixture(4)
    trapped.path = function(a, b) return {a, point(a.x + 20, a.z + 20), b} end
    local short = assert(trapped.builder:Begin(7, 41))
    assert(trapped.builder:Poll(short) == "invalid" and short.reason == "no clear staging approach")
end

print("PASS: deterministic parade circuits, native endpoint proof, async retention, safety, corners and bounded staging")
