-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--[[
This class is implemented as a single function returning a table with public
interface methods.  Private data is stored in the function's closure.

Public interface:

local FlagsMgr = CreateFlagsMgr(myTeamID, myAllyTeamID, mySide, Log)

function FlagsMgr.GameStart()
function FlagsMgr.GameFrame(f)
function FlagsMgr.UnitFinished(unitID, unitDefID, unitTeam)
function FlagsMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
]]--

function CreateFlagsMgr(myTeamID, myAllyTeamID, mySide, Log)

-- Can not do flag capping if we don't have waypoints..
if (not gadget.waypointMgr) then
	return false
end

local FlagsMgr = {}

-- constants
local RESERVED_FLAG_CAPPERS = gadget.reservedFlagCappers[mySide] or 24

-- speedups
local GetUnitPosition   = Spring.GetUnitPosition
local GetUnitTeam       = Spring.GetUnitTeam
local GetUnitSeparation = Spring.GetUnitSeparation
local GetGroundHeight   = Spring.GetGroundHeight

local flagCappers = gadget.flagCappers
local waypointMgr = gadget.waypointMgr
local waypoints = waypointMgr.GetWaypoints()

-- members
local units = {}
local unitCount = 0
local startpos

--------------------------------------------------------------------------------

local function SendToNearestWaypointWithUncappedFlags(source, unitArray)
    local previous, target = PathFinder.Dijkstra(waypoints, source, {}, function(p)
        return (not p:AreAllFlagsCappedByAllyTeam(myAllyTeamID)) and (#p.flags > 0)
    end)
    if target then
        Log("Flag capper found target: ", target.x, ", ", target.z)
        local cmd = CMD.FIGHT
        -- HACK: special exception for Russia, cause with fight the commissars will
        -- only eat all map features and help base building, instead of capping flags.
        -- if (mySide == "rus") then cmd = CMD.MOVE end
        -- give orders
        for _,u in ipairs(unitArray) do
            units[u] = target --assume next call this unit will be at target
            PathFinder.GiveOrdersToUnit(previous, target, u, cmd, 0.5 * FLAG_RADIUS)
        end
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

function FlagsMgr.GameStart()
    startpos = waypointMgr.GetTeamStartPosition(myTeamID)
    for u,_ in pairs(units) do
        units[u] = startpos
        GiveOrderToUnit(u, CMD.MOVE, {startpos.x, startpos.y, startpos.z}, {})
    end
end

function FlagsMgr.GameFrame(f)
    -- make temporary data structure of squads (units at or moving towards same waypoint)
    local squads = {} -- waypoint -> array of unitIDs
    for u,p in pairs(units) do
        local squad = (squads[p] or {})
        squad[#squad+1] = u
        squads[p] = squad
    end
    for p, unitArray in pairs(squads) do
        if p then
            if p:AreAllFlagsCappedByAllyTeam(myAllyTeamID) then
                -- give each such squad new orders if the flags near it's destination are capped
                Log("All flags capped near: ", p.x, ", ", p.z)
                SendToNearestWaypointWithUncappedFlags(p, unitArray)
            else
                local f = p:GetNextUncappedFlagByAllyTeam(myAllyTeamID)
                -- Ask units close to the flag to fulfill the mission
                for _,u in ipairs(unitArray) do
                    local d = GetUnitSeparation(u, f, true)
                    if d and d < 2.0 * FLAG_RADIUS and d > 0.49 * FLAG_RADIUS then
                        Log("Unit ", u, " is close to flag ", f, "...")
                        local x, _, z = GetUnitPosition(f)
                        local y = GetGroundHeight(x, z)
                        GiveOrderToUnit(u, CMD.FIGHT, {x, y, z}, {})
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function FlagsMgr.UnitFinished(unitID, unitDefID, unitTeam)
    if (unitCount < RESERVED_FLAG_CAPPERS) and (flagCappers[unitDefID] ~= nil) then

        if (UnitDefs[unitDefID].speed == 0) then return end
        assert(type(unitID) == "number")
        units[unitID] = startpos
        if (not units[unitID]) then
            Log("No start position!")
            units[unitID] = true
        end

        unitCount = unitCount + 1
        Log("Capping flags using: ", UnitDefs[unitDefID].humanName)

        if (startpos ~= nil) then
            GiveOrderToUnit(unitID, CMD.MOVE, {startpos.x, startpos.y, startpos.z}, {})
        end

        return true --signal Team.UnitFinished that we will control this unit
    end
end

function FlagsMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    if units[unitID] then
        units[unitID] = nil
        unitCount = unitCount - 1
        Log("Flag capper destroyed.")
    end
end

--------------------------------------------------------------------------------
--
--  Initialization
--

return FlagsMgr
end
