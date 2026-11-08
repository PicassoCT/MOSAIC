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
        TestMoveOrder = function(defID, x, y, z, dx, dy, dz, testTerrain, testObjects, centerOnly)
            assert(defID == 41 and y >= 0)
            if testObjects == false then
                assert(dx == 0 and dy == 0 and dz == 0 and testTerrain == true and centerOnly == true)
                f.terrainOnlyCalls = (f.terrainOnlyCalls or 0) + 1
            end
            return (not f.terrainBlocked or not f.terrainBlocked(x, z)) and
                (centerOnly == true or not f.footprintTerrainBlocked) and
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
    -- Skew the fixture so nearby-node ordering still exercises real turns.
    for id, p in pairs(f.positions) do p.x, p.z = p.x + id * 17, p.z + id * 23 end
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
    local f = fixture(4)
    local route = assert(f.builder:Begin(7, 41))
    -- A steep adjacent square is outside the driven centreline, as in QTPFS.
    f.footprintTerrainBlocked = true
    assert(f.builder:Poll(route) == "ready", "valid native road rejected by adjacent terrain")
    local blocked = fixture(4)
    blocked.footprintTerrainBlocked = true
    assert(blocked.builder:Begin(7, 41) == nil, "assembly curbs lost full footprint validation")
end

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

do
    local f = fixture(4)
    local route = assert(f.builder:Begin(7, 41))
    local a, b = route.points[1], route.points[2]
    local mx, mz = (a.x+b.x)/2, (a.z+b.z)/2
    f.terrainBlocked=function(x,z) return (x-mx)^2+(z-mz)^2<1 end
    assert(f.builder:Poll(route)=='invalid')
    assert(route.reason:find('unsafe native waypoint at x=',1,true))
    assert(route.reason:find('impassable terrain',1,true))
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

-- Widespread low-level incidents permit a circuit; heavy damage still rejects
-- native paths, including incidents occurring after path requests were sent.
do
    local f = fixture(6, {combatHeatThreshold = 450})
    local area = dofile('luarules/gadgets/include/city_area_state.lua')(
        dofile('luarules/configs/city_area.lua'), 8192, 8192, function() return 0 end)
    f.GG.CityAreaState = area
    area:ReportIncident(1000, 1000, 350, 4000)
    assert(area:IsDangerous(1000, 1000))
    local route = assert(f.builder:Begin(7, 41))
    assert(f.builder:Poll(route) == 'ready', 'minor combat prevented route')
    local pending = assert(f.builder:Begin(7, 41))
    area:ReportIncident(1000, 1000, 100, 4000)
    assert(f.builder:Poll(pending) == 'invalid', 'heavy combat crossed by route')
    assert(not f.builder:Begin(7, 41), 'heavy combat accepted as route nodes')
end
print('PASS parade route damage tolerance')

-- A bounded retry must explore alternatives from the same starting building,
-- rather than rediscovering its first rejected circuit and abandoning it.
do
    local f = fixture(6, {routeMaxAttempts = 1})
    local first = assert(f.builder:Begin(7, 41))
    local start, previousGoal = first.nodes[1], first.nodes[2]
    f.path = function(a, b) return {a} end
    assert(f.builder:Poll(first) == 'invalid')
    f.path = nil
    local retry = assert(f.builder:Begin(7, 41), 'rejected first circuit hid valid alternatives')
    assert(retry.nodes[1] == start and retry.nodes[2] ~= previousGoal)
    assert(f.builder:Poll(retry) == 'ready')
end

-- Neighbourhood routes try the nearest connected building before distant
-- cross-city links; the graph, minimum spacing and native validation still apply.
do
    local f = fixture(8, {routeMaxAttempts = 1})
    local route = assert(f.builder:Begin(7, 41))
    local start, goal = f.positions[route.nodes[1]], f.positions[route.nodes[2]]
    for id, p in pairs(f.positions) do
        if id ~= route.nodes[1] then
            assert(squared(start, goal) <= squared(start, p), 'distant link preferred to nearby circuit')
        end
    end
end
print('PASS nearby route selection and alternate circuits from a rejected start')

-- Native pathfinding does not know about nonblocking city houses. Their
-- independent footprints must reject a crossing even between sparse samples.
do
    local f=fixture(4)
    local calls=0
    local clearance={Refresh=function()end,SegmentClear=function(_,a,b)
        calls=calls+1
        return same(a,b) -- curbs pass; any connecting segment crosses a fixture house
    end}
    f.builder=Route.new({Spring=f.Spring,GG=f.GG,UnitDefs={[41]={moveDef={id=17}}},clearance=clearance})
    local route=assert(f.builder:Begin(7,41))
    -- Return a house ID for blocked segments, like the production index.
    clearance.SegmentClear=function(_,a,b)if same(a,b)then return true end;return false,99 end
    assert(f.builder:Poll(route)=='invalid' and route.reason:find('house footprint 99',1,true))
    assert(calls>0)
end

do
    local f=fixture(2,{routeRejectRetrace=true})
    local route=assert(f.builder:Begin(7,41))
    assert(f.builder:Poll(route)=='invalid' and route.reason=='circuit doubles back into the convoy lane')
    local short=fixture(2,{vehicleCount=12,vehicleSpacing=140})
    local r=assert(short.builder:Begin(7,41))
    assert(short.builder:Poll(r)=='invalid' and r.reason=='circuit is too short for convoy spacing')
end
print('PASS house crossing, head-on return lanes and convoy circuit capacity')
