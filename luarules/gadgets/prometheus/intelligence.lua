-- Author: Jose Luis Cercos-Pita
-- License: GNU General Public License v2

--[[
This class provides information regarding enemy units. There are 3 levels of
intelligence, dependending on the difficulty level:

* easy = Just information about units on LOS is handled. Information on
         permanent structures is preserved
* medium = Information about units attacking or getting attacked are also
           considered
* hard = All the enemy units is perfectly known

Public interface:

function Intelligence.GetUnits(n)
function Intelligence.GameStart()
function Intelligence.GameFrame(f)
function Intelligence.UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
function Intelligence.UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
function Intelligence.UnitFinished(unitID, unitDefID, unitTeam)
function Intelligence.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
function Intelligence.UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
]]--

function CreateIntelligence(myTeamID, myAllyTeamID)

local FLAG_RELEVANCE_MULT = 5
local DIST2_MULT = 1.0 / (FLAG_RADIUS * FLAG_RADIUS)
local DIFFICULTY = gadget.difficulty
local waypointMgr = gadget.waypointMgr
local waypoints = waypointMgr.GetWaypoints()

local GetUnitRulesParam = Spring.GetUnitRulesParam
local GetUnitPosition   = Spring.GetUnitPosition
local HOUSE_PRODUCTION_VALUE = 25

local Intelligence = {}

local enemyTeams = {}
for _,t in ipairs(Spring.GetTeamList()) do
    if t ~= Spring.GetGaiaTeamID() then
        local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(t)
        if allyTeamID ~= myAllyTeamID then
            enemyTeams[#enemyTeams + 1] = t
        end
    end
end

local units = {}
local unitIDs = {}
local time_to_forget = {}

local function tableConcat(t1, t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function remember(id)
    if id and not unitIDs[id] then units[#units+1]=id;unitIDs[id]=#units end
end
local function forget(id)
    local index=unitIDs[id]
    if not index then return end
    local last=units[#units]
    units[index]=last;units[#units]=nil
    unitIDs[id]=nil
    if last~=id then unitIDs[last]=index end
    time_to_forget[id]=nil
end

local function doesUnitExistAlive(id)
    local valid = Spring.ValidUnitID(id)
    if valid == nil or valid == false then
        -- echo("doesUnitExistAlive::Invalid ID")
        return false
    end

    local dead = Spring.GetUnitIsDead(id)
    if dead == nil or dead == true then
        -- echo("doesUnitExistAlive::Dead Unit")
        return false
    end

    return true
end

local isFlag = gadget.flags
local flags = {}
local strategic_relevance = {}
local last_waypoint = 0

local function parseWaypointStrategicRelevance(waypoint)
    assert(waypoint)
    local relevance = 1
    for _, flag in ipairs(flags) do
        if doesUnitExistAlive(flag) == true then
        local prod = HOUSE_PRODUCTION_VALUE
        local x, y, z = GetUnitPosition(flag)
        assert(waypoint.x)
        local dx, dz = waypoint.x - x, waypoint.z - z
        local r2 = math.max(1, (dx * dx + dz * dz) * DIST2_MULT)
        relevance = relevance + FLAG_RELEVANCE_MULT * prod / r2
     end
    end

    strategic_relevance[waypoint] = relevance
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-out routines
--

function Intelligence.GetTarget(x, z)
    local frontline, normals, previous = waypointMgr.GetFrontline(myTeamID, myAllyTeamID)
    local target, normal, score = nil, {0, 0}, -1

    for i,waypoint in ipairs(frontline) do
        local dx, dz = waypoint.x - x, waypoint.z - z
        local r2 = math.max(1, (dx * dx + dz * dz) * DIST2_MULT)
        local visitor_score = (strategic_relevance[waypoint] ~= nil and strategic_relevance[waypoint] or 1) / r2
        -- Spring.MarkerAddPoint(waypoint.x, waypoint.y, waypoint.z, string.format("%.2f", visitor_score))
        if visitor_score > score then
            score = visitor_score
            target = waypoint
            normal = normals[i]
        end
    end

    return target, normal, previous
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

local first_unit = 1

function Intelligence.GetUnits(n)
    local last_unit = math.min(first_unit + n - 1, #units)
    local to_return = {}
    for i = first_unit, last_unit do
        to_return[#to_return + 1] = units[i]
    end
    first_unit = last_unit + 1
    if first_unit > #units then
        first_unit = 1
    end
    return to_return
end

function Intelligence.GameStart()
    -- Get all the flags
    for _, u in ipairs(Spring.GetAllUnits()) do
        if isFlag[Spring.GetUnitDefID(u)] then
            flags[#flags + 1] = u
        end
    end

    if DIFFICULTY ~= "hard" then
        return
    end
    units = {}
    time_to_forget = {}
    for _, t in ipairs(enemyTeams) do
        units = tableConcat(units, Spring.GetTeamUnits(t))
    end
    for i, unitID in ipairs(units) do
        unitIDs[unitID] = i
    end
end

function Intelligence.GameFrame(f)
    if #waypoints > 0 then
        last_waypoint = (last_waypoint % #waypoints) + 1
        assert(last_waypoint)
        assert(waypoints[last_waypoint])
        parseWaypointStrategicRelevance(waypoints[last_waypoint])
    end

    if DIFFICULTY == "hard" then
        return
    end
end

function Intelligence.UnitFinished(unitID, unitDefID, unitTeam)
    if DIFFICULTY ~= "hard" then
        return
    end
    for _, t in ipairs(enemyTeams) do
        if t == unitTeam then
            remember(unitID)
            return
        end
    end
end

function Intelligence.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    forget(unitID)
end

function Intelligence.UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    if allyTeam ~= myAllyTeamID then return end
    if DIFFICULTY == "hard" then
        return
    end
    for _, t in ipairs(enemyTeams) do
        if t == unitTeam then
            remember(unitID)
            return
        end
    end
end

function Intelligence.UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
    if allyTeam ~= myAllyTeamID then return end
    if DIFFICULTY == "hard" then
        return
    end
    forget(unitID)
end

function Intelligence.UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
    if not Spring.AreTeamsAllied(myTeamID, unitTeam) and not (attackerTeam and Spring.AreTeamsAllied(myTeamID, attackerTeam)) then return end
    if DIFFICULTY ~= "medium" then
        return
    end

    local alliedVsEnemy = 0
    for _, t in ipairs(enemyTeams) do
        if t == unitTeam then
            alliedVsEnemy = alliedVsEnemy + 1
        end
        if t == attackerTeam then
            alliedVsEnemy = alliedVsEnemy - 1
        end
    end

    if alliedVsEnemy == 1 then
        remember(unitID)
    elseif alliedVsEnemy == -1 then
        remember(attackerID)
    end
end

--------------------------------------------------------------------------------
--
--  Initialization
--

return Intelligence
end
