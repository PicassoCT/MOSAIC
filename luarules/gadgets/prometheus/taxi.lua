-- Author: Jose Luis Cercos-Pita
-- License: GNU General Public License v2

--[[
This class is implemented as a single function returning a table with public
interface methods.  Private data is stored in the function's closure.

Public interface:

local TaxiService = CreateTaxiService(myTeamID, myAllyTeamID, Log)
function TaxiService.AddTransportMission(unitIDs, dest)
function TaxiService.AddSupplyMission(unitID)

function TaxiService.GameFrame(f)
function TaxiService.UnitFinished(unitID, unitDefID, unitTeam)
function TaxiService.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
]]--

function CreateTaxiService(myTeamID, myAllyTeamID, Log)

local TaxiService = {}

-- speedups
local CMD_LOAD, CMD_UNLOAD = CMD.LOAD_UNITS, CMD.UNLOAD_UNITS
local CMD_GUARD = CMD.GUARD
local random, min, max = math.random, math.min, math.max
local GetUnitDefID       = Spring.GetUnitDefID
local GetUnitCommands    = Spring.GetUnitCommands
local GetTeamResources   = Spring.GetTeamResources
local GetUnitIsDead      = Spring.GetUnitIsDead
local GetUnitRulesParam  = Spring.GetUnitRulesParam

-- Taxis and ammo suppliers
local taxis = {}         -- unitID (taxi) -> true
local busyUnits = {}     -- unitID (taxi) -> mission
local missions = {}      -- List of missions to still become attended
local onMission = {}     -- unitID (target) -> mission
local missionID = 0


function TaxiService.AddTransportMission(unitIDs, dest, retries)
    retries = retries or 5

    local targets = {}
    for _, u in ipairs(unitIDs) do
        if not onMission[u] then
            targets[#targets + 1] = u
        end
    end
    if #targets == 0 then
        return nil
    end

    Log("Adding taxi order (", missionID + 1, ") till destination ", dest[1], ", ", dest[2], ", ", dest[3])

    missionID = missionID + 1
    missions[#missions + 1] = {id=missionID,
                               cmd=CMD_LOAD,
                               targets=targets,
                               dest=dest,
                               taxi=nil,
                               retries=retries}
    for _, u in ipairs(targets) do
        onMission[u] = missionID
    end
    return missions[#missions]
end

local freeTaxis, freeSuppliers = nil, nil

local function dispatch_taxi_mission(mission)
    if freeTaxis == nil then
        freeTaxis = {}
        for u, _ in pairs(taxis) do
            if not busyUnits[u] then
                freeTaxis[#freeTaxis + 1] = u
            end
        end
    end

    if #freeTaxis == 0 then
        Log("No free taxis found...")
        if mission.retries == 0 then
            Log("Giving up taxi order ", mission.id)
            return true
        end
        mission.retries = mission.retries - 1
        return false
    end

    local u, ud = nil, nil
    while u == nil and #freeTaxis > 0 do
        u = freeTaxis[#freeTaxis]
        freeTaxis[#freeTaxis] = nil
        ud = UnitDefs[GetUnitDefID(u)]
        if ud == nil then
            busyUnits[u] = nil
            taxis[u] = nil
        end
    end
    if u == nil then
        Log("All taxis seems invalid... Debug this!")
        if mission.retries == 0 then
            Log("Giving up taxi order ", mission.id)
            return true
        end
        mission.retries = mission.retries - 1
        return false        
    end
    busyUnits[u] = mission
    mission.taxi = u
    mission.transportCapacity = ud.transportCapacity
    mission.transportMass = ud.transportMass

    -- It may happens that this taxi might not carry out the whole mission
    local targets, pending = {}, {}
    local passengers, mass = mission.transportCapacity, mission.transportMass
    local guns = 1  -- NOTE: Number of tow points shall be checked
    for _, target in ipairs(mission.targets) do
        local tud = UnitDefs[GetUnitDefID(target)]
        if not GetUnitIsDead(target) and tud then
            local m = tud.mass
            if passengers == 0 or mass < m or (m >= 100 and guns == 0) then
                pending[#pending + 1] = target
            else
                targets[#targets + 1] = target
                passengers = passengers - 1
                mass = mass - m
                if mass >= 100 then
                    -- Gun
                    guns = guns - 1
                end
            end
        end
    end

    if #targets == 0 then
        -- The mission cannot be carried out anymore
        Log("Taxi job ", mission.id, " became unfeasible...")
        return true
    end

    -- Traverse the unit commands
    Log("Assigning taxi job ", mission.id, " to ", u, "...")
    local options = {}
    for _, target in ipairs(targets) do
        GiveOrderToUnit(u, CMD_LOAD, {target}, options)
        options = {"shift"}
    end
    GiveOrderToUnit(u, CMD_UNLOAD, {mission.dest[1],
                                    mission.dest[2],
                                    mission.dest[3], 50}, {"shift"})
    -- Add a new mission if there are pending units
    if #pending > 0 then
        TaxiService.AddTransportMission(pending, mission.dest)
    end

    return true
end


local function dispatch_mission(mission)
    if mission.cmd == CMD_GUARD then
        return false
    else
        return dispatch_taxi_mission(mission)
    end
    return false
end

local function finished_mission(unitID)
    local mission = busyUnits[unitID]
    busyUnits[unitID] = nil
    if mission then
        for _, u in ipairs(mission.targets) do
            onMission[u] = nil
        end
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

function TaxiService.GameFrame(f)
    Log("Missions pending: ", #missions)
    local eCurr = GetTeamResources(myTeamID, "energy")

    -- Traverse the units looking for those who are free
    for u, mission in pairs(busyUnits) do
        if (GetUnitCommands(u, 0) or 0) == 0 then
            finished_mission(u)
        end
        if mission.cmd == CMD_GUARD then
            local ammo = tonumber(GetUnitRulesParam(mission.targets[1], "ammo") or 0)
            if eCurr < mission.weaponcost or ammo == mission.maxammo then
                finished_mission(u)
            end
        end
    end

    freeTaxis, freeSuppliers = nil, nil
    -- Traverse the pending missions, and assign as many as possible
    for i = #missions,1,-1 do
        if dispatch_mission(missions[i]) then
            table.remove(missions, i)
        end
    end
end

function TaxiService.UnitFinished(unitID, unitDefID, unitTeam)
    local udef = UnitDefs[unitDefID]
    local get_this_unit = false
    if udef.transportCapacity >= SQUAD_SIZE and not udef.customParams.infgun and not udef.customParams.mother then
        get_this_unit = true
        taxis[unitID] = true
        Log("Unit ", unitID, " (", udef.name, ") hired as taxi")
    end

    return get_this_unit
end

function TaxiService.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    onMission[unitID] = nil
    busyUnits[unitID] = nil
    taxis[unitID] = nil
end

return TaxiService
end
