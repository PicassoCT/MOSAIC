-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--[[
This class is implemented as a single function returning a table with public
interface methods.  Private data is stored in the function's closure.

Public interface:

local WaypointMgr = CreateWaypointMgr()

function WaypointMgr.GameStart()
function WaypointMgr.GameFrame(f)
function WaypointMgr.UnitCreated(unitID, unitDefID, unitTeam, builderID)

function WaypointMgr.GetGameFrameRate()
function WaypointMgr.GetWaypoints()
function WaypointMgr.GetTeamStartPosition(myTeamID)
function WaypointMgr.GetFrontline(myTeamID, myAllyTeamID)
    Returns frontline, previous. Frontline is the set of waypoints adjacent

]]--

function CreateWaypointMgr()

-- constants
local GAIA_TEAM_ID    = Spring.GetGaiaTeamID()
local GAIA_ALLYTEAM_ID      -- initialized later on..
local FLAG_RADIUS     = FLAG_RADIUS
local WAYPOINT_RADIUS = FLAG_RADIUS
local WAYPOINT_HEIGHT = 100
local REF_UNIT_DEF = UnitDefNames["civilian_arab0"] -- Reference unit to check paths
local WESTERN_HOUSE_DEFID = UnitDefNames["house_western0"].id
local ARAB_HOUSE_DEFID = UnitDefNames["house_arab0"].id
-- We enforce the map waypoints are all traversed once each 10s
local MAP_TRAVERSING_PERIOD = 310
-- The frontlines are updated at least once each 10s
local FRONTLINE_UPDATE_PERIOD = 313

-- speedups
local Log = Log
local GetUnitsInBox = Spring.GetUnitsInBox
local GetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitTeam = Spring.GetUnitTeam
local GetUnitAllyTeam = Spring.GetUnitAllyTeam
local GetUnitPosition = Spring.GetUnitPosition
local GetGroundHeight = Spring.GetGroundHeight
local GetUnitNeutral = Spring.GetUnitNeutral
local TestMoveOrder = Spring.TestMoveOrder
local sqrt = math.sqrt
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local isFlag = gadget.flags

-- class
local WaypointMgr = {}

-- Grid of waypoints to become parsed
local grid = {}
local n_grid_x, n_grid_y = floor(Game.mapSizeX / WAYPOINT_RADIUS),
                           floor(Game.mapSizeZ / WAYPOINT_RADIUS)
for i=1,n_grid_x do
    grid[i] = {}
    for j=1,n_grid_y do
        grid[i][j] = {
            valid = nil,
        }
    end
end
local parse_queue = {}

-- Array containing the waypoints and adjacency relations
-- Format: { { x = x, y = y, z = z, adj = {}, --[[ more properties ]]-- }, ... }
local waypoints = {}
local index = 0      -- where we are with updating waypoints

-- Dictionary mapping unitID of flag to waypoint it is in.
local flags = {}

-- Format: { [team1] = allyTeam1, [team2] = allyTeam2, ... }
local teamToAllyteam = {}

-- caches result of CalculateFrontline..
local frontlineCache = {}

-- caches result of Spring.GetTeamStartPosition
local teamStartPosition = {}

-- Last frontline updated
local teams = {}
local lastParsedFrontline = 0

local function GetDist2D(x, z, p, q)
    local dx = x - p
    local dz = z - q
    return sqrt(dx * dx + dz * dz)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Waypoint prototype (Waypoint public interface)
--  TODO: do I actually need this... ?
--

local Waypoint = {}
Waypoint.__index = Waypoint

function Waypoint:GetFriendlyUnitCount(myAllyTeamID)
    return self.allyTeamUnitCount[myAllyTeamID] or 0
end

function Waypoint:GetEnemyUnitCount(myAllyTeamID)
    local sum = 0
    for at,count in pairs(self.allyTeamUnitCount) do
        if (at ~= myAllyTeamID) then
            sum = sum + count
        end
    end
    return sum
end

function Waypoint:GetNextUncappedFlagByAllyTeam(myAllyTeamID)
    local HouseHasSafeHouseTable = GG.houseHasSafeHouseTable
    if HouseHasSafeHouseTable == nil then return false end
    for _,f in pairs(self.flags) do
        if (HouseHasSafeHouseTable[f] and GetUnitAllyTeam(HouseHasSafeHouseTable[f]) ~= myAllyTeamID) then
            return f
        end
    end
    return nil
end

function Waypoint:AreAllFlagsCappedByAllyTeam(myAllyTeamID)
    local HouseHasSafeHouseTable = GG.houseHasSafeHouseTable
    if HouseHasSafeHouseTable == nil then return false end

    for _,f in pairs(self.flags) do
        if (HouseHasSafeHouseTable[f] and GetUnitAllyTeam(HouseHasSafeHouseTable[f]) ~= myAllyTeamID) then
            return false
        end
    end
    return true
end

local function AddWaypoint(x, y, z)
    local waypoint = {
        x = x, y = y, z = z, --position
        adj = {},            --map of adjacent waypoints -> edge distance
        flags = {},          --array of flag unitIDs
        allyTeamUnitCount = {},
    }
    setmetatable(waypoint, Waypoint)
    waypoints[#waypoints+1] = waypoint
    return waypoint
end

-- Returns the nearest waypoint to point x, z, and the distance to it.
local function GetNearestWaypoint2D(x, z)
    assert(x)
    assert(z)
    local minDist = 1.0e9
    local nearest = {
        x = x, y = 0, z = z, --position
        adj = {},            --map of adjacent waypoints -> edge distance
        flags = {},          --array of flag unitIDs
        allyTeamUnitCount = {},
    }
--    Spring.Echo("Number of waypoints "..#waypoints)

     if #waypoints < 2 then  
        return nearest   
    end

    local boolNotChecked = true
    local boolFoundNearest = false

    for _,p in ipairs(waypoints) do
        boolNotChecked = false
        local dist = GetDist2D(x, z, p.x, p.z)
        if (dist < minDist) and p ~= nil then
            minDist = dist
            nearest = p
            boolFoundNearest = true
        end
    end
    assert(boolFoundNearest)
    assert(type(nearest) == "table")
    return nearest, minDist
end

local function adj_grid_nodes(i, j)
    local nodes = {}
    for ii = i-1,i+1 do
        if ii > 0 and ii <= n_grid_x then
            for jj = j-1,j+1 do
                if jj > 0 and jj <= n_grid_y and not (ii == i and jj == j) then
                    nodes[#nodes + 1] = {ii, jj}
                end
            end
        end
    end
    return nodes
end

local function AddWaypointPerUnit(id)
local x, y, z = GetUnitPosition(id)
    if x and x ~= 0 then
        -- Add a waypoint right there
        local i, j = world2grid(x, z)
        if not grid or not grid[i] or not grid[i][j] then return end

        if grid[i][j].valid == nil then
            grid[i][j].valid = true
            local gx, gy, gz = grid2world(i, j)
            grid[i][j].waypoint = AddWaypoint(gx, gy, gz)
        end
        teamStartPosition[t] = GetNearestWaypoint2D(x, z) 
        -- Add also the surrounding waypoints, to avoid failures in
        -- TestMoveOrder() due to the already built HQ
        local neighs = adj_grid_nodes(i, j)
        for _, neigh in ipairs(neighs) do
            if grid[neigh[1]][neigh[2]].valid == nil then
                grid[neigh[1]][neigh[2]].valid = true
                local gx, gy, gz = grid2world(neigh[1], neigh[2])
                grid[neigh[1]][neigh[2]].waypoint = AddWaypoint(gx, gy, gz)
                AddConnection(grid[i][j].waypoint,
                              grid[neigh[1]][neigh[2]].waypoint)
                -- Add the adjacent grid nodes to the parsing queue
                local candidates = adj_grid_nodes(neigh[1], neigh[2])
                for _, c in ipairs(candidates) do
                    if grid[c[1]][c[2]].valid == nil then
                        parse_queue[#parse_queue + 1] = c
                    end
                end
            end
        end
    end
end

-- This calculates the set of waypoints which are
--  1) owned by allies
--  2) adjacent to waypoints non-possesed by allies
--  3) reachable from hq, without going through enemy waypoints
local function CalculateFrontline(myTeamID, myAllyTeamID, dilate)
    Log("Updating frontline for team " .. myTeamID .. "...")

    if dilate == nil then
        dilate = 3
    end

    -- Get the allied and enemy actual control areas
    local allied, enemy = {}, {}
    local allied_frontier, enemy_frontier = {}, {}
    for _,p in ipairs(waypoints) do
        if p.owner ~= nil then
            if p.owner == myAllyTeamID then
                allied[p] = true
                for a, edge in pairs(p.adj) do
                    if (a.owner ~= myAllyTeamID) then
                        allied_frontier[#allied_frontier + 1] = p
                        break
                    end
                end
            else
                enemy[p] = true
                for a, edge in pairs(p.adj) do
                    if (a.owner ~= p.owner) then
                        enemy_frontier[#enemy_frontier + 1] = p
                        break
                    end
                end
            end
        end
    end

    -- Dilate all the control areas until they collide
    -- Mark as frontline candidates all allied waypoints adjacent to
    -- non-allied ones.
    local marked = {}
    while #allied_frontier + #enemy_frontier > 0 do
        for i=1,#allied_frontier do
            local p = allied_frontier[#allied_frontier]
            allied_frontier[#allied_frontier] = nil
            for a, edge in pairs(p.adj) do
                if allied[a] == nil then
                    if enemy[a] == nil then
                        allied[a] = true
                        table.insert(allied_frontier, 1, a)
                    else
                        marked[p] = true
                    end
                end
            end            
        end
        for i=1,#enemy_frontier do
            local p = enemy_frontier[#enemy_frontier]
            enemy_frontier[#enemy_frontier] = nil
            for a, edge in pairs(p.adj) do
                if enemy[a] == nil then
                    if allied[a] == nil then
                        enemy[a] = true
                        table.insert(enemy_frontier, 1, a)
                    end
                end
            end            
        end
    end

    -- Rebuild the allied boundary
    for _,p in ipairs(allied) do
        for a, edge in pairs(p.adj) do
            if not allied[a] then
                allied_frontier[#allied_frontier + 1] = p
                break
            end
        end
    end
    -- Artificially dilate the allied area to enforce incursion in enemy lines
    for i = 1,dilate do
        for i=1,#allied_frontier do
            local p = allied_frontier[#allied_frontier]
            allied_frontier[#allied_frontier] = nil
            for a, edge in pairs(p.adj) do
                if enemy[a] == true then
                    enemy[a] = nil
                    allied[a] = true
                    table.insert(allied_frontier, 1, a)
                    marked[p] = false
                    marked[a] = true
                end
            end            
        end
    end

    -- mark as blocked all the enemy owned waypoints
    local blocked = enemy

    -- block all edges which connect two frontline waypoints
    -- (ie. prevent units from pathing over the frontline..)
    for p,_ in pairs(marked) do
        for a,edge in pairs(p.adj) do
            if marked[a] then
                blocked[edge] = true
            end
        end
    end

    -- Release all the connections departing from the HQ
    local hq = teamStartPosition[myTeamID]
    if hq == nil then
        local x,y,z = Spring.GetTeamStartPosition(myTeamID) 
        if not x then             
            x = math.random(1,99)*(Game.mapSizeX/100)
            y = 0
            z = math.random(1,99)*(Game.mapSizeZ/100) 
        end
        hq = GetNearestWaypoint2D(x, z)
    end

    blocked[hq] = nil
    for a, edge in pairs(hq.adj) do
        blocked[edge] = nil
    end

    -- "perform a Dijkstra" starting at HQ
    local previous = PathFinder.Dijkstra(waypoints, hq, blocked)

    -- now 'frontline' is intersection between 'marked' and 'previous'
    local frontline = {}
    for p,_ in pairs(marked) do
        if previous[p] then
            frontline[#frontline + 1] = p
        end
    end

    -- Remove all the frontline points with just a single connection with enemy
    -- nodes, to avoid convex corners
    for i=#frontline,1,-1 do
        local p = frontline[i]
        local n_conn = 0
        for a, edge in pairs(p.adj) do
            if not allied[a] then
                n_conn = n_conn + 1
                if n_conn >= 2 then
                    break
                end
            end
        end
        if n_conn < 2 then
            table.remove(frontline, i)
        end
    end

    -- Compute the normal (the mean direction to the enemy lines).
    local normals = {}
    for i,p in ipairs(frontline) do
        local nx, nz = 0, 0
        for a, edge in pairs(p.adj) do
            if enemy[a] == true then
                nx = nx + (a.x - p.x) / edge.dist
                nz = nz + (a.z - p.z) / edge.dist
            end
        end
        local l = sqrt(nx * nx + nz * nz)
        nx = nx / l
        nz = nz / l
        normals[i] = {nx, nz}
    end

    return frontline, normals, previous
end


-- Called everytime a waypoint changes owner.
-- A waypoint changes owner when compared to previous update,
-- a different allyteam now possesses ALL units near the waypoint.
local function WaypointOwnerChange(waypoint, newOwner)
    local oldOwner = waypoint.owner
    waypoint.owner = newOwner

    Log("WaypointOwnerChange ", waypoint.x, ", ", waypoint.z, ": ",
        (oldOwner or "neutral"), " -> ", (newOwner or "neutral"))

    if (oldOwner ~= nil) then
        -- invalidate cache for oldOwner
        for t,at in pairs(teamToAllyteam) do
            if (at == oldOwner) then
                frontlineCache[t] = nil
            end
        end
    end

    if (newOwner ~= nil) then
        -- invalidate cache for newOwner
        for t,at in pairs(teamToAllyteam) do
            if (at == newOwner) then
                frontlineCache[t] = nil
            end
        end
    end
end

local function grid2world(i, j)
    local x, z = (i - 0.5) * WAYPOINT_RADIUS, (j - 0.5) * WAYPOINT_RADIUS
    return x, GetGroundHeight(x, z), z
end

local function world2grid(x, z)
    local i, j = math.floor(x / WAYPOINT_RADIUS) + 1,
                             math.floor(z / WAYPOINT_RADIUS) + 1
    return math.floor(x / WAYPOINT_RADIUS) + 1,
           math.floor(z / WAYPOINT_RADIUS) + 1
end






local function UpdateWaypoint(p)
    p.flags = {}

    -- Update p.allyTeamUnitCount
    -- Box check (as opposed to Rectangle, Sphere, Cylinder),
    -- because this allows us to easily exclude aircraft.
    local x1, y1, z1 = p.x - WAYPOINT_RADIUS, p.y - WAYPOINT_HEIGHT, p.z - WAYPOINT_RADIUS
    local x2, y2, z2 = p.x + WAYPOINT_RADIUS, p.y + WAYPOINT_HEIGHT, p.z + WAYPOINT_RADIUS
    local occupationTeams = {}
    local allyTeamUnitCount = {}
    for _,u in ipairs(GetUnitsInBox(x1, y1, z1, x2, y2, z2)) do
        local ud = GetUnitDefID(u)
        local at = GetUnitAllyTeam(u)
        if isFlag[ud] then
            local x, y, z = GetUnitPosition(u)
            local dist = GetDist2D(x, z, p.x, p.z)
            if (dist < FLAG_RADIUS) then
                p.flags[#p.flags+1] = u
                flags[p] = u
                --Log("Flag ", u, " (", at, ") is near ", p.x, ", ", p.z)
            end
            occupationTeams[#occupationTeams + 1] = at
        end
        if at ~= GAIA_ALLYTEAM_ID and not GetUnitNeutral(u) then
            if allyTeamUnitCount[at] == nil then
                occupationTeams[#occupationTeams + 1] = at
            end
            allyTeamUnitCount[at] = (allyTeamUnitCount[at] or 0) + 1
        end
    end
    p.allyTeamUnitCount = allyTeamUnitCount

    -- Update p.owner. The owner of a way point is whatever team is occupying
    -- it. If no-one is currently occupying the waypoint, we just simply
    -- preserve it. If several teams are disputing a waypoint, is it demoted
    -- to neutral
    if #occupationTeams == 1 then
        p.owner = occupationTeams[1]
    elseif #occupationTeams > 1 then
        p.owner = nil
    end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  WaypointMgr public interface
--

function WaypointMgr.GetWaypoints()
    return waypoints
end

function WaypointMgr.GetTeamStartPosition(myTeamID)
    local x,y,z = Spring.GetTeamStartPosition(myTeamID) 
    local startPos = GetNearestWaypoint2D(x, z) 
    return startPos
end

function WaypointMgr.GetFrontline(myTeamID, myAllyTeamID)
    if (not frontlineCache[myTeamID]) then
        frontlineCache[myTeamID] = { CalculateFrontline(myTeamID, myAllyTeamID) }
    end
    return unpack(frontlineCache[myTeamID])
end

function WaypointMgr.GetNext(p, dx, dz)
    local waypoint, accuracy = p, 0.0
    for visitor, edge in pairs(p.adj) do
        local dir_x = (visitor.x - p.x) / edge.dist
        local dir_z = (visitor.z - p.z) / edge.dist
        local dot = dx * dir_x + dz * dir_z
        if dot > accuracy then
            waypoint = visitor
            accuracy = dot
        end
    end
    return waypoint
end

WaypointMgr.GetNearestWaypoint2D = GetNearestWaypoint2D

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--
local function GetWaypointDist2D(a, b)
    local dx = a.x - b.x
    local dz = a.z - b.z
    return sqrt(dx * dx + dz * dz)
end

local function AddConnection(a, b)
    local edge = {dist = GetWaypointDist2D(a, b)}
    a.adj[b] = edge
    b.adj[a] = edge
end

function WaypointMgr.GameStart()
    -- Can not run this in the initialization code at the end of this file,
    -- because at that time Spring.GetTeamStartPosition seems to always return 0,0,0.
    for _,t in ipairs(Spring.GetTeamList()) do
        if (t ~= GAIA_TEAM_ID) then
            local x, y, z = Spring.GetTeamStartPosition(t)
            if x and x ~= 0 then
                -- Add a waypoint right there
                local i, j = world2grid(x, z)
                    if not grid or not grid[i] or not grid[i][j] then return end

                if grid[i][j].valid == nil then
                    grid[i][j].valid = true
                    local gx, gy, gz = grid2world(i, j)
                    grid[i][j].waypoint = AddWaypoint(gx, gy, gz)
                end
                teamStartPosition[t] = GetNearestWaypoint2D(x, z) 
                -- Add also the surrounding waypoints, to avoid failures in
                -- TestMoveOrder() due to the already built HQ
                local neighs = adj_grid_nodes(i, j)
                for _, neigh in ipairs(neighs) do
                    if grid[neigh[1]][neigh[2]].valid == nil then
                        grid[neigh[1]][neigh[2]].valid = true
                        local gx, gy, gz = grid2world(neigh[1], neigh[2])
                        grid[neigh[1]][neigh[2]].waypoint = AddWaypoint(gx, gy, gz)
                        AddConnection(grid[i][j].waypoint,
                                      grid[neigh[1]][neigh[2]].waypoint)
                        -- Add the adjacent grid nodes to the parsing queue
                        local candidates = adj_grid_nodes(neigh[1], neigh[2])
                        for _, c in ipairs(candidates) do
                            if grid[c[1]][c[2]].valid == nil then
                                parse_queue[#parse_queue + 1] = c
                            end
                        end
                    end
                end
            end
        end
    end
end

function WaypointMgr.GameFrame(f)
    -- Parse another grid waypoint
    for i=#parse_queue,1,-1 do
        local gi, gj = parse_queue[i][1], parse_queue[i][2]
        parse_queue[i] = nil
        if grid[gi][gj].valid == nil then
            local dst_x, dst_y, dst_z = grid2world(gi, gj)
            -- Assume the point cannot be reached
            grid[gi][gj].valid = false
            -- Look for the connectivity with the adjacent nodes
            local candidates = adj_grid_nodes(gi, gj)
            for _, c in ipairs(candidates) do
                if grid[c[1]][c[2]].valid == true then
                    local src_x, src_y, src_z = grid2world(c[1], c[2])
                    local dx, dy, dz = dst_x - src_x, dst_y - src_y, dst_z - src_z
                    if TestMoveOrder(REF_UNIT_DEF.id, src_x, src_y, src_z, dx, dy, dz) then
                        grid[gi][gj].valid = true
                        if grid[gi][gj].waypoint == nil then
                            grid[gi][gj].waypoint = AddWaypoint(dst_x, dst_y, dst_z)
                        end
                        -- connect the waypoint with the neighbor
                        AddConnection(grid[c[1]][c[2]].waypoint,
                                      grid[gi][gj].waypoint)
                    end
                end
            end

            if grid[gi][gj].valid == true then
                -- Ask to parse the pending adjacent nodes
                for _, c in ipairs(candidates) do
                    if grid[c[1]][c[2]].valid == nil then
                        table.insert(parse_queue, 1, {c[1], c[2]})
                    end
                end
            end

            -- A grid node per frame is enough
            break
        end
    end

    -- Update the next frontline (lazy mode)
    if #teams == 0 or f % FRONTLINE_UPDATE_PERIOD < .1 then
        lastParsedFrontline = (lastParsedFrontline % #teams) + 1
        frontlineCache[teams[lastParsedFrontline]] = nil
    end

    -- Update the way points, if available
    if #waypoints == 0 then
        return
    end

    local waypoints_per_frame = ceil(#waypoints / MAP_TRAVERSING_PERIOD)
    for i=1,waypoints_per_frame do
        index = (index % #waypoints) + 1
        UpdateWaypoint(waypoints[index])
    end
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function WaypointMgr.UnitCreated(unitID, unitDefID, unitTeam, builderID)
    if isFlag[unitDefID] then
       -- Spring.Echo("Flag created")
        -- This is O(n*m), with n = number of flags and m = number of waypoints.
        local x, y, z = GetUnitPosition(unitID)
        AddWaypoint(x,y,z)    
        local p, dist = GetNearestWaypoint2D(x, z)
        if p then
            p.flags[#p.flags+1] = unitID
            flags[unitID] = p
            Log("Flag ", unitID, " is near ", p.x, ", ", p.z)
        end
    end
end

function WaypointMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    if isFlag[unitDefID] then
        local p = flags[unitID]
        if p then
            flags[unitID] = nil
            for i=1,#p.flags do
                if (p.flags[i] == unitID) then
                    table.remove(p.flags, i)
                    break
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
--
--  Initialization
--

do
    -- make map of teams to allyTeams
    -- this must contain not only AI teams, but also player teams!
    for _,t in ipairs(Spring.GetTeamList()) do
        if (t ~= GAIA_TEAM_ID) then
            teams[#teams + 1] = t
            local _,_,_,_,_,at = Spring.GetTeamInfo(t)
            teamToAllyteam[t] = at
        end
    end

    -- find GAIA_ALLYTEAM_ID
    local _,_,_,_,_,at = Spring.GetTeamInfo(GAIA_TEAM_ID)
    GAIA_ALLYTEAM_ID = at
end

return WaypointMgr
end

