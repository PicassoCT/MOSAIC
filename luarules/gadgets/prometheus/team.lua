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

-- Enemy start positions (assumes this are base positions)
local enemyBases = {}
local enemyBaseCount = 0
local enemyBaseLastAttacked = 0

-- Base building (one global buildOrder)
local baseMgr = CreateBaseMgr(myTeamID, myAllyTeamID, mySide, Log)

-- Unit building (one buildOrder per factory)
local unitBuildOrder = gadget.unitBuildOrder
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
local ANTAGONSAFEHOUSEDFID 	= UnitDefNames["antagonsafehouse"].id
local PROTAGONSAFEHOUSEDEFID = UnitDefNames["protagonsafehouse"].id
local PROPAGANDASERVER = UnitDefNames["propagandaserver"].id



local upgradeTypeTable = {
 [UnitDefNames["nimrod"] .id]=true,
 [UnitDefNames["propagandaserver" ].id]=true,
 [UnitDefNames["assembly"].id]=true,
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

function Team.GameStart()
	-- Spring.Echo("Prometheus: GameStart")
	-- Can not run this in the initialization code at the end of this file,
	-- because at that time Spring.GetTeamStartPosition seems to always return 0,0,0.
	for _,t in ipairs(Spring.GetTeamList()) do
		if (t ~= GAIA_TEAM_ID) and (not Spring.AreTeamsAllied(myTeamID, t)) then
			local x,y,z = Spring.GetTeamStartPosition(t)
			if x and x ~= 0 then
				enemyBaseCount = enemyBaseCount + 1
				enemyBases[enemyBaseCount] = {x,y,z}
				Log("Enemy base spotted at coordinates: ", x, ", ", z)
			else
				Log("Oops, Spring.GetTeamStartPosition failed")
			end
		end
	end
	if waypointMgr then
		flagsMgr.GameStart()
	end
	Log("Preparing to attack ", enemyBaseCount, " enemies")
end

function Team.GameFrame(f)
	--Log("GameFrame")
	-- Spring.Echo("Prometheus GameFrame")
	baseMgr.GameFrame(f)

	if waypointMgr then
		flagsMgr.GameFrame(f)
		combatMgr.GameFrame(f)
	end
end


function Team.hasEnoughPropagandaservers(teamID)
	local teamIDCount = Spring.GetTeamUnitsCounts(teamID)
	local allOthersCounted = 0 
	local propagandaserverCount= 0	
	
	for defID, count in ipairs(teamIDCount) do
		if defID == ANTAGONSAFEHOUSEDFID or defID== PROTAGONSAFEHOUSEDEFID or Team.upgradeTypeTable[defID] then
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
--  Game call-ins
--

-- Short circuit callin which would otherwise only forward the call..
Team.AllowUnitCreation = unitLimitsMgr.AllowUnitCreation

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

function Team.minBuildOrderFullfilled(unitTeam)
	-- Spring.Echo("Prometheus: Checking Min Buildorder fullfilled")
local _,leader,isDead,isAiTeam, side =Spring.GetTeamInfo(unitTeam)

local checkTable={}
	if side and side == "protagon" then
		checkTable = minBuildOrderProtagon
	else
		checkTable = minBuildOrderAntagon
	end
local unitCounts= Spring.GetTeamUnitsCounts(unitTeam)

local boolMinBuildFullfilled = true
local unitsToBuild = {}

	for unitDefID, Nr in pairs(checkTable) do
		if Nr and  unitDefID and unitCounts[unitDefID] and  Nr > unitCounts[unitDefID] then
			boolMinBuildFullfilled = false
			unitsToBuild[unitDefID] = Nr - unitCounts[unitDefID] 
			-- Log("Prometheus: ".. UnitDefs[unitDefID].name .." missing min amount "..unitsToBuild[unitDefID] )
		end
	end
	
local	boolString= "true"
	if boolMinBuildFullfilled == false then boolString = "false" end
	
	Log("Prometheus: MinBuilder is fullfiled:",boolString, " for side ".. side)
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
			
			if  (unitDefID == ANTAGONSAFEHOUSEDFID or unitDefID == PROTAGONSAFEHOUSEDEFID ) then
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
			Log("Warning: unitBuildOrder can only be used to control factories")
		end
	end
	
end

function Team.UnitFinished(unitID, unitDefID, unitTeam)
	-- Log(" UnitFinished: ", UnitDefs[unitDefID].humanName)
	local boolMinBuildOrderFullfilled, stillMissingUnitsTable, side = Team.minBuildOrderFullfilled(unitTeam)
	-- idea from BrainDamage: instead of cheating huge amounts of resources,
	-- just cheat in the cost of the units we build.
	--Spring.AddTeamResource(myTeamID, "metal", UnitDefs[unitDefID].metalCost)
	--Spring.AddTeamResource(myTeamID, "energy", UnitDefs[unitDefID].energyCost)

	-- queue unitBuildOrders if we have any for this unitDefID
	-- if boolMinBuildOrderFullfilled == true then
		-- Team.normalBuildOrder(unitID,unitDefID, unitTeam)	
	-- else

		Team.minBuildOrder(unitID,unitDefID,unitTeam, stillMissingUnitsTable, side)		

	-- if any unit manager takes care of the unit, return
	-- managers are in order of preference

	if waypointMgr then
		if flagsMgr.UnitFinished(unitID, unitDefID, unitTeam) then return end
	end

	if baseMgr.UnitFinished(unitID, unitDefID, unitTeam) then return end

	if waypointMgr then
		if combatMgr.UnitFinished(unitID, unitDefID, unitTeam) then return end
	end
end

function Team.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	-- Spring.Echo("Prometheus: UnitDestroyed: ", UnitDefs[unitDefID].humanName)

	baseMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)

	if waypointMgr then
		flagsMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
		combatMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	end
end

function Team.UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	Team.UnitDestroyed(unitID, unitDefID, unitTeam)
end

function Team.UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	Team.UnitCreated(unitID, unitDefID, unitTeam, nil)
	local _, _, inBuild = Spring.GetUnitIsStunned(unitID)
	Log("Unit given")
	if not inBuild then
		Team.UnitFinished(unitID, unitDefID, unitTeam)
	end
end

function Team.UnitIdle(unitID, unitDefID, unitTeam)
	Log("UnitIdle: ", UnitDefs[unitDefID].humanName)
end

--------------------------------------------------------------------------------
--
--  Initialization
--

Log("assigned to ", gadget.ghInfo.name, " (allyteam: ", myAllyTeamID, ", side: ", mySide, ")")

return Team
end
