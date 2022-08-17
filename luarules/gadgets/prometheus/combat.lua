-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--[[
This class is implemented as a single function returning a table with public
interface methods.  Private data is stored in the function's closure.

Public interface:

function CombatMgr.GameFrame(f)
function CombatMgr.UnitFinished(unitID, unitDefID, unitTeam)
function CombatMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
]]--

function CreateCombatMgr(myTeamID, myAllyTeamID, heatmapMgr, taxiMgr, Log)

-- Can not manage combat if we don't have waypoints..
if (not gadget.waypointMgr) then
    return false
end

local CombatMgr = {}
local gaiaTeamID = Spring.GetGaiaTeamID ()

-- constants
local SQUAD_SIZE = SQUAD_SIZE
local SQUAD_SPREAD = 500
local FEAR_THRESHOLD = 0.5 + (1.0 - 0.5) * math.random()
local TAXI_ETA = 180.0

-- speedups
local CMD_FIGHT = CMD.FIGHT
local CMD_MOVE = CMD.MOVE
local sqrt, random, min, hugefloat = math.sqrt, math.random, math.min, math.huge
local lower = string.lower
local waypointMgr = gadget.waypointMgr
local waypoints = waypointMgr.GetWaypoints()
local intelligence = gadget.intelligences[myTeamID]
local GetUnitNoSelect   = Spring.GetUnitNoSelect
local GetUnitPosition   = Spring.GetUnitPosition
local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitRulesParam = Spring.GetUnitRulesParam
local GetGroundHeight   = Spring.GetGroundHeight
local GetTeamResources  = Spring.GetTeamResources
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local FIRE_AT_WILL = "fireatwill"
local RETURN_FIRE = "returnfire"
local randVal = random(2,6)
-- members
local lastWaypoint = 0
local units = {}
local warheadDefID = UnitDefNames["physicspayload"].id
local launcherDefID = UnitDefNames["launcher"].id
local operativeTypeTable = {
[UnitDefNames["operativepropagator"].id]= true,
[UnitDefNames["operativeinvestigator"].id]= true,
[UnitDefNames["operativeasset"].id]= true
}

local newUnits = {}
local newUnitCount = 0


local function avgPosUnitMap(units)
    local x, z, n = 0, 0, 0
    for u, _ in pairs(units) do
        local xx, _, zz = GetUnitPosition(u)
        x, z = x + xx, z + zz
        n = n + 1
    end
    return x / n, z / n
end

local function avgPosUnitArray(units)
    local x, z = 0, 0, 0
    for _, u in ipairs(units) do
        local xx, _, zz = GetUnitPosition(u)
        x, z = x + xx, z + zz
    end
    return x / #units, z / #units
end

local function get_spread_vector(unitID, normal, t_radius)
    local nx, nz = unpack(normal)
    local tx, tz = -nz, nx

    local t_spread = random() * t_radius * 2 - t_radius

    local n_radius = 0.25 * t_radius
    local unitDefID = GetUnitDefID(unitID)
    local unitDef = UnitDefs[unitDefID]
    if  #unitDef.weapons > 0 then
        local weaponDef = WeaponDefs[unitDef.weapons[1].weaponDef]
        n_radius = 0.35 + 0.5 * weaponDef.range
    end
    local n_spread = -random() * n_radius

    return n_spread * nx + t_spread * tx, n_spread * nz + t_spread * tz
end

local function DoGiveOrdersToUnit(p, unitID, cmd, normal, spread)
    local dx, dz = get_spread_vector(unitID, normal, spread)
    GiveOrderToUnit(unitID, cmd, {p.x + dx, p.y, p.z + dz},  {})
end

local function GetUnitETA(unitID, dest)
    local x, _, z = GetUnitPosition(unitID)
    local dx, dz = dest.x - x, dest.z - z
    local d = sqrt(dx * dx + dz * dz)
    local v = UnitDefs[GetUnitDefID(unitID)].speed
    return d / v
end

local function GiveOrdersToUnitArray(orig, target, unitArray, cmd, normal, spread)
    for _,u in ipairs(unitArray) do
        if not operativeTypeTable[GetUnitDefID(u)] then
            DoGiveOrdersToUnit(target, u, cmd, normal, spread)
        end
    end
end

local function GiveOrdersToUnitMap(orig, target, unitMap, cmd, normal, spread)
    local unitArray = {}
    for u, _ in pairs(unitMap) do
        unitArray[#unitArray + 1] = u
    end
    return GiveOrdersToUnitArray(orig, target, unitArray, cmd, normal, spread)
end

local function getEnemysAtTargetInRange(target, radius, myTeamID)
    local unitsAtTarget = Spring.GetUnitsInCylinder ( target.x, target.z,  radius)
    local result = {}
    if unitsAtTarget and #unitsAtTarget > 0 then
        --filter out gaia and myTeam
        for i=1, #unitsAtTarget do
            local unitTeamID = unitsAtTarget[i]

            if unitTeamID ~= gaiaTeamID and unitTeamID ~= myTeamID then
                result[#result+1] = unitsAtTarget[i]
            end
        end
    end
    return result
end

local function setUnitFireState(unitID, firestateStr)
    local states = {}
    states.holdfire = 0
    states.returnfire = 1
    states.fireatwill = 2
    local fireState = states[lower(firestateStr)] or 0 
    Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {fireState}, {})
end

local function setUnitArrayFireState(unitsArray, firestateStr, nthUnit)
    local states = {}
    states.holdfire = 0
    states.returnfire = 1
    states.fireatwill = 2
    local fireState = states[lower(firestateStr)] or 0 

    for i=1,#unitsArray do
        if i % nthUnit == 0 then
            Spring.GiveOrderToUnit(unitsArray[i], CMD.FIRE_STATE, {fireState}, {})
        end
    end  
end

local function assignUnitsTargetsAtTarget(target, unitsArray, normal, spread)
    local boolAssignedSuccesfully = false
    local enemyUnitArray = getEnemysAtTargetInRange(target, 250, Spring.GetUnitTeam(unitsArray[1]))
    if enemyUnitArray and #enemyUnitArray > 0 then
        for i=1,#unitsArray do
            local randomizedPriority = math.random(0,3)
            local unitID = unitsArray[i]
            local enemyID = enemyUnitArray[((i+randomizedPriority) % #enemyUnitArray)+1]
            Spring.Echo("Prometheus: Unit "..unitID.." assigned to attack "..enemyID)
            GiveOrderToUnit(unitID, CMD.ATTACK, enemyID,  {"shift"})
            boolAssignedSuccesfully = true
        end
    end
    randVal = random(2,6)
    setUnitArrayFireState(unitsArray, FIRE_AT_WILL, randVal)

    return boolAssignedSuccesfully
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--


function CombatMgr.GameFrame(f)
    if newUnitCount >= SQUAD_SIZE then
        -- Don't use units which user wouldn't be able to use..
        for u,_ in pairs(newUnits) do
            if GetUnitNoSelect(u) then
                newUnits[u] = nil
                newUnitCount = newUnitCount - 1
            end
        end
    end

    if gadget.IsDebug(myTeamID) then
        local frontline, normals, _ = waypointMgr.GetFrontline(myTeamID, myAllyTeamID)
        for i = 1,#frontline do
            local x, y, z = frontline[i].x, frontline[i].y, frontline[i].z
            local dx, dy, dz = 15 * normals[i][1], 0, 15 * normals[i][2]
            Spring.MarkerAddPoint(x, y, z)
            Spring.MarkerAddLine(x, y, z, x + dx, y + dy, z+ dz)
        end        
    end

    if newUnitCount >= SQUAD_SIZE then
        local x, z = avgPosUnitMap(newUnits)
        local target, normal, previous = intelligence.GetTarget(x, z)
        if target ~= nil then
            local orig = waypointMgr.GetNearestWaypoint2D(x, z)
            local unitArray, taxiUnitArray = {}, {}
            for u, _ in pairs(newUnits) do
                setUnitFireState(u, RETURN_FIRE)
                units[u] = target -- remember where we are going for UnitIdle
                unitArray[#unitArray + 1] = u
                local eta = GetUnitETA(u, target)
                if UnitDefs[GetUnitDefID(u)].mass <= 100 and eta > TAXI_ETA then
                    taxiUnitArray[#taxiUnitArray + 1] = u
                end
            end

            GiveOrdersToUnitArray(orig, target, unitArray, CMD.FIGHT, normal, SQUAD_SPREAD)
           
            if #taxiUnitArray > 0 then
                -- Don't unload the units straight at the combat line
                target = waypointMgr.GetNext(target, -normal[1], -normal[2])
                target = waypointMgr.GetNext(target, -normal[1], -normal[2])
                taxiMgr.AddTransportMission(taxiUnitArray,
                                            {target.x, target.y, target.z})
            end

            newUnits = {}
            newUnitCount = 0
        end
    end


    -- make temporary data structure of squads (units at or moving towards same waypoint)
    local squads = {} -- waypoint -> array of unitIDs
    for u,p in pairs(units) do
        local squad = (squads[p] or {})
        squad[#squad+1] = u
        squads[p] = squad
    end

    -- give each orders towards the nearest relevant waypoint
    for p,unitArray in pairs(squads) do
        local x, z = avgPosUnitArray(unitArray)
        local target, normal, previous = intelligence.GetTarget(x, z)
        if target ~= nil then
            target = waypointMgr.GetNext(target, normal[1], normal[2])
            for i = 1, 3 do
                local gx, gz = heatmapMgr.FirepowerGradient(target.x, target.z)
                local l2 = gx * gx + gz * gz
                if l2 < FEAR_THRESHOLD * FEAR_THRESHOLD then
                    break
                end
                -- Let's retreat
                local l = sqrt(l2)
                target = waypointMgr.GetNext(target, -gx / l, -gz / l)
            end
            if target and (target ~= p) then
                local orig = waypointMgr.GetNearestWaypoint2D(x, z)

                if #unitArray % 2 == 1 then
                    GiveOrdersToUnitArray(orig, target, unitArray, CMD.FIGHT, normal, SQUAD_SPREAD)
                    setUnitArrayFireState(unitArray, RETURN_FIRE, 1)
                else
                    local boolAssignedTargets = assignUnitsTargetsAtTarget(target, unitArray, normal, SQUAD_SPREAD)
                    if not boolAssignedTargets then
                        GiveOrdersToUnitArray(orig, target, unitArray, CMD.FIGHT, normal, SQUAD_SPREAD)
                    end
                end

                for _,u in ipairs(unitArray) do
                    units[u] = target --assume next call this unit will be at target
                end
            end
        end
    end

    local warheads = spGetTeamUnitsByDefs(myTeamID, warheadDefID)
    if warheads and #warheads then
        local result = {}
        for i=1, #warheads do
            if not Spring.GetUnitTransporter(warheads[i]) then
                result[#result+1]=warheads[i] 
            end
        end
        local launcherTargets = spGetTeamUnitsByDefs(myTeamID, launcherDefID)
        local index = 1
        local nrOfLaunchTargets = #launcherTargets
        if launcherTargets and #result > 0 and nrOfLaunchTargets > 0 then
            for i=1, #result do

                if nrOfLaunchTargets > 1 then index = math.random(1, nrOfLaunchTargets) end
                if  launcherTargets[index] then
                local target = {x=0,y=0,z=0}
                target.x,target.y,target.z = spGetUnitPosition( launcherTargets[index])
                taxiMgr.AddTransportMission({result[i]},
                                            {target.x, target.y, target.z})
                end
            end

        end
    end

end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function CombatMgr.UnitFinished(unitID, unitDefID, unitTeam)
    if not waypointMgr then
        return false
    end
    local unitDef = UnitDefs[unitDefID]
    if unitDef.speed ~= 0 then
        -- if it's a mobile unit, give it orders towards frontline
        newUnits[unitID] = true
        newUnitCount = newUnitCount + 1

        return true --signal Team.UnitFinished that we will control this unit
    end

    return false
end

function CombatMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    units[unitID] = nil
    if newUnits[unitID] then
        newUnits[unitID] = nil
        newUnitCount = newUnitCount - 1
    end
end

--------------------------------------------------------------------------------
--
--  Initialization
--

return CombatMgr
end
