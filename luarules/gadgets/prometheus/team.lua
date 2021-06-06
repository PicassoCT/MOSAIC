-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--[[
This class is implemented as a single function returning a table with public
interface methods.  Private data is stored in the function's closure.

Public interface:

local Team = CreateTeam(myTeamID, myAllyTeamID, mySide)

function Team.Log(...)
function Team.UnitCreated(unitID, unitDefID, unitTeam, builderID)
function Team.UnitFinished(unitID, unitDefID, unitTeam)
function Team.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
function Team.UnitTaken(unitID, unitDefID, unitTeam, newTeam)
function Team.UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
]]--
VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

function CreateTeam(myTeamID, myAllyTeamID, mySide)

local Team = {}

do
    local GadgetLog = gadget.Log
    function Team.Log(...)
        GadgetLog("Team[", myTeamID, "] ", ...)
    end
end
local Log = Team.Log

-- constants
local GAIA_TEAM_ID = Spring.GetGaiaTeamID()
local TEAMS_UPDATE_PERIOD = 128  -- In frames (128 ~ 4.5 seconds)
local TEAMS_UPDATE_LAG = 16      -- In frames (16 ~ 0.5 seconds)

-- Enemy start positions (assumes this are base positions)
local enemyBases = {}
local enemyBaseCount = 0
local enemyBaseLastAttacked = 0
local checkTeamTable = {}

-- Base building (one global buildOrder)
local baseMgr = CreateBaseMgr(myTeamID, myAllyTeamID, mySide, Log)

-- Unit building (one buildOrder per factory)
local unitBuildOrder = {}
if mySide == "antagon"  then
	unitBuildOrder = gadget.unitBuildOrderAntagon
else
	unitBuildOrder = gadget.unitBuildOrderProtagon
end

local minBuildOrderAntagon = gadget.minBuildRequirementAntagon
local minBuildOrderProtagon = gadget.minBuildRequirementProtagon

-- Unit limits
local unitLimitsMgr = CreateUnitLimitsMgr(myTeamID)

-- Combat management
local waypointMgr = gadget.waypointMgr
local lastWaypoint = 0
local combatMgr = CreateCombatMgr(myTeamID, myAllyTeamID, Log)

-- Flag capping
local flagsMgr = CreateFlagsMgr(myTeamID, myAllyTeamID, mySide, Log)
local ANTAGONSAFEHOUSEDEFID 	= UnitDefNames["antagonsafehouse"].id
local PROTAGONSAFEHOUSEDEFID 	= UnitDefNames["protagonsafehouse"].id
local PROPAGANDASERVER 		= UnitDefNames["propagandaserver"].id

local upgradeTypeTable = {
 [UnitDefNames["nimrod"].id]=true,
 [PROPAGANDASERVER]=true,
 [UnitDefNames["assembly"].id]=true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

function Team.GameStart()
 Log("GameStart")
    -- Can not run this in the initialization code at the end of this file,
    -- because at that time Spring.GetTeamStartPosition seems to always return 0,0,0.
    for _,t in ipairs(Spring.GetTeamList()) do
        if (t ~= GAIA_TEAM_ID) and (not Spring.AreTeamsAllied(myTeamID, t)) then
            local x,y,z = Spring.GetTeamStartPosition(t)
            if x and x ~= 0 then
                enemies_number = enemies_number + 1
                Log("Enemy base spotted at coordinates: ", x, ", ", z)
            else
                Log("Oops, Spring.GetTeamStartPosition failed")
            end
        end
    end
    flagsMgr.GameStart()
    heatmapMgr.GameStart()
    Log("Preparing to attack ", enemies_number, " enemies")
end

function Team.GameFrame(f)
    heatmapMgr.GameFrame(f)

    if gadget.IsDebug(myTeamID) then
        -- Erase the map marks the frame before updating again
        if (f + TEAMS_UPDATE_LAG * myTeamID) % TEAMS_UPDATE_PERIOD > (TEAMS_UPDATE_PERIOD - 1.1) then
            Spring.SendCommands({"ClearMapMarks"})
        end
    end

    if (f + TEAMS_UPDATE_LAG * myTeamID) % TEAMS_UPDATE_PERIOD > .1 then
        return
    end

    baseMgr.GameFrame(f)
    flagsMgr.GameFrame(f)
    taxiMgr.GameFrame(f)
    combatMgr.GameFrame(f)
end


function Team.hasEnoughPropagandaservers(teamID)
	local teamIDCount = Spring.GetTeamUnitsCounts(teamID)
	local allOthersCounted = 0 
	local propagandaserverCount= 0	
	
	for defID, count in ipairs(teamIDCount) do
		if 	defID == ANTAGONSAFEHOUSEDEFID or 
			defID== PROTAGONSAFEHOUSEDEFID or 
			Team.upgradeTypeTable[defID] then
			allOthersCounted = allOthersCounted + count
		end
	end	

	if teamIDCount[PROPAGANDASERVER] then 
		propagandaserverCount = teamIDCount[PROPAGANDASERVER]
	end
		
	return propagandaserverCount  > allOthersCounted
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--

-- Currently unitTeam always equals myTeamID (enforced in gadget)

-- Short circuit callin which would otherwise only forward the call..
Team.UnitCreated = baseMgr.UnitCreated

local function unitIsBusyBuilding( unitID )
	local queue = Spring.GetFullBuildQueue(unitID)
	return queue and #queue > 0
end

function Team.checkMinBuildOrderFullfilled(unitTeam)
	-- Spring.Echo("Prometheus: Checking Min Buildorder fullfilled")
local _,leader,isDead,isAiTeam, side =Spring.GetTeamInfo(unitTeam)

local checkTable={}

	if side then
		if  side == "protagon" then
			checkTable = minBuildOrderProtagon
		elseif side == "antagon" then
			checkTable = minBuildOrderAntagon
		end
	else
		local teamUnits = Spring.GetTeamUnitsCounts(unitTeam)
		if teamUnits[UnitDefNames["operativepropagator"].id] > 0 then
			checkTable = minBuildOrderAntagon
		elseif teamUnits[UnitDefNames["operativeinvestigator"].id] > 0 then
			checkTable = minBuildOrderProtagon
		end

		if teamUnits[UnitDefNames["operativeinvestigator"].id] == 0 and 
			teamUnits[UnitDefNames["operativepropagator"].id]  == 0 then
				Spring.Echo("Error: No minbuildorder checktable assigned")
		end
	end

	local unitCounts = Spring.GetTeamUnitsCounts(unitTeam)
	local boolMinBuildFullfilled = true
	local unitsToBuild = {}
	if unitCounts then
		for unitDefID, Nr in pairs(checkTable) do
			if UnitDefs[unitDefID] and Nr and  unitDefID and (unitCounts[unitDefID] and unitCounts[unitDefID] < Nr) or not unitCounts[unitDefID] then
				boolMinBuildFullfilled = false
				local actualUnitAmount = 0
				if  unitCounts[unitDefID] then actualUnitAmount =  unitCounts[unitDefID] end
				unitsToBuild[unitDefID] = Nr - actualUnitAmount
			end
		end
	end
		
	local	boolString= "true"
	if boolMinBuildFullfilled == false then boolString = "false" end
	
	Log("MinBuilder is fullfiled:", boolString, " for side ".. side)
	return boolMinBuildFullfilled, unitsToBuild, side
end

function Team.minBuildOrder(unitID, unitDefID, unitTeam, stillMissingUnitsTable, side) 
	if unitBuildOrder[unitDefID]   then
		-- factory or builder?
		if not (UnitDefs[unitDefID].speed > 0) then --factory
			-- If there are no enemies, don't bother lagging Spring to death:
			-- just go through the build queue exactly once, instead of repeating it.
			if (enemyBaseCount > 0 or Spring.GetGameSeconds() < 0.1) then
				GiveOrderToUnit(unitID, CMD.REPEAT, {1}, {})
				-- Each next factory gives fight command to next enemy.
				-- Didn't use math.random() because it's really hard to establish
				-- a 100% correct distribution when you don't know whether the
				-- upper bound of the RNG is inclusive or exclusive.
				if (not waypointMgr) then
					enemyBaseLastAttacked = enemyBaseLastAttacked + 1
					if enemyBaseLastAttacked > enemyBaseCount then
						enemyBaseLastAttacked = 1
					end
					-- queue up a bunch of fight orders towards all enemies
					local idx = enemyBaseLastAttacked
					for i=1,enemyBaseCount do
						-- enemyBases[] is in the right format to pass into GiveOrderToUnit...
						GiveOrderToUnit(unitID, CMD.FIGHT, enemyBases[idx], {})
						idx = idx + 1
						if idx > enemyBaseCount then idx = 1 end
					end
				end
			end
			
			if  (unitDefID == ANTAGONSAFEHOUSEDEFID or unitDefID == PROTAGONSAFEHOUSEDEFID ) then
				if Team.hasEnoughPropagandaservers(unitTeam) == true then
					GiveOrderToUnit(unitID, -PROPAGANDASERVER, {}, {})	
				else
					for bo,defID in ipairs(unitBuildOrder[unitDefID]) do
						if defID and UnitDefs[defID] then
							if maRa()==true then
								GiveOrderToUnit(unitID, -defID, {}, {})
							end
						else 
							Spring.Echo("Invalid buildorder found: " .. UnitDefs[unitDefID].humanName .. " -> " .. (UnitDefs[defID].humanName or 'nil'))
						end
					end
				end
			else		
				if  unitIsBusyBuilding(unitID) == false then
					for _,defID in ipairs(unitBuildOrder[unitDefID]) do
						if defID and UnitDefs[defID]  then
							Spring.Echo("Prometheus: Queueing: ", UnitDefs[defID].humanName)
							GiveOrderToUnit(unitID, -defID, {}, {})
							-- Spring.Echo("Factory ".. unitID.." ordered to build ".. UnitDefs[bo].humanName)
						else
							 Spring.Echo("Prometheus: invalid buildorder found: " .. UnitDefs[unitDefID].humanName .. " -> " .. (UnitDefs[defID].humanName or 'nil'))
						end
					end
				end
			end
		else
			Log("Warning: unitBuildOrder can only be used to control factories, is used on "..UnitDefs[unitDefID].name.. " instead")
		end
	end
	
end


function Team.UnitFinished(unitID, unitDefID, unitTeam)
    local ud = UnitDefs[unitDefID]
    Log("UnitFinished: ", ud.name)

    -- idea from BrainDamage: instead of cheating huge amounts of resources,
    -- just cheat in the cost of the units we build.
    --Spring.AddTeamResource(myTeamID, "metal", UnitDefs[unitDefID].metalCost)
    --Spring.AddTeamResource(myTeamID, "energy", UnitDefs[unitDefID].energyCost)


    -- need to prefer flag capping over building to handle Russian commissars
    if flagsMgr.UnitFinished(unitID, unitDefID, unitTeam) then
        return
    end

	-- queue unitBuildOrders if we have any for this unitDefID
	if boolMinBuildOrderFullfilled == false then
		Team.minBuildOrder(unitID,unitDefID,unitTeam, stillMissingUnitsTable, side)		
	end
    if baseMgr.UnitFinished(unitID, unitDefID, unitTeam) then
        -- Special case of static units with supply range, which shall be
        -- considered by the combat manager (which is not controlling them by
        -- any means)
        if ud.speed == 0 and ud.customParams.supplyrange then
            combatMgr.UnitFinished(unitID, unitDefID, unitTeam)
        end
        return
    end
    if taxiMgr.UnitFinished(unitID, unitDefID, unitTeam) then
        return
    end
    if combatMgr.UnitFinished(unitID, unitDefID, unitTeam) then
        return
    end
end



function Team.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    Log("UnitDestroyed: ", UnitDefs[unitDefID].humanName)

    heatmapMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    if unitTeam ~= myTeamID then
        return
    end

    baseMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    flagsMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    taxiMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    combatMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
end

function Team.UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    Team.UnitDestroyed(unitID, unitDefID, unitTeam)
end

function Team.UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    Team.UnitCreated(unitID, unitDefID, unitTeam, nil)
    local _, _, inBuild = Spring.GetUnitIsStunned(unitID)
    if not inBuild then
        Team.UnitFinished(unitID, unitDefID, unitTeam)
    end
end

function Team.UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    combatMgr.UnitDestroyed(unitID, unitDefID, unitTeam, transportID, Spring.GetUnitDefID(transportID), transportTeam)
end

function Team.UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    combatMgr.UnitFinished(unitID, unitDefID, unitTeam)
end


function Team.UnitIdle(unitID, unitDefID, unitTeam)
    Log("UnitIdle: ", UnitDefs[unitDefID].humanName)
end

function Team.UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    heatmapMgr.UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
end

function Team.UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
    heatmapMgr.UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
end

--------------------------------------------------------------------------------
--
--  Initialization
--

Log("assigned to ", gadget.ghInfo.name, " (allyteam: ", myAllyTeamID, ", side: ", mySide, ")")

return Team
end
