-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Slightly based on the Kernel Panic AI by KDR_11k (David Becker) and zwzsg.
-- Thanks to lurker for providing hints on how to make the AI run unsynced.

-- In-game, type /luarules prometheus in the console to toggle the ai debug messages

function gadget:GetInfo()
	return {
		name = "Prometheus",
		desc = "Configurable Reusable Artificial Intelligence Gadget for MOSAIC",
		author = "Tobi Vollebregt",
		date = "2009-02-12",
		license = "GNU General Public License",
  		layer = 1,
		enabled = true
	}
end


-- Read mod options, we need this in both synced and unsynced code!
if (Spring.GetModOptions) then
    local modOptions = Spring.GetModOptions()
    local lookup = {"easy", "medium", "hard", "impossible"}
    difficulty = lookup[tonumber(modOptions.craig_difficulty) or 2]
else
    difficulty = "hard"
end

-- include configuration
include("LuaRules/Configs/prometheus/config.lua")


if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  SYNCED
--

local function Refill(myTeamID, resource)
    if gadget.difficulty ~= "easy" then
        local value,storage = Spring.GetTeamResources(myTeamID, resource)
        if gadget.difficulty == "medium" then
            -- medium: partial refill
            -- 1000 storage / 128 * 30 = approx. +234
            -- this means 100% cheat is bonus of +234 metal at 1k storage
            --Spring.AddTeamResource(myTeamID, resource, (storage - value) * 0.05)
        else
            -- hard: full refill
           -- Spring.AddTeamResource(myTeamID, resource, storage - value)
            if gadget.difficulty == "impossible" and resource == "energy" and storage < 1000.0 then
                -- Grant the AI always have at least 1000 ammo storage, so
                -- targeting the storages is not a possibility to win
               -- Spring.AddTeamResource(myTeamID, "es", 1000.0)
            end
        end
    end
end

function gadget:GameFrame(f)
    -- Perform economy cheating, this must be done in synced code!
    if f % 128 < 0.1 then
        for t,_ in pairs(team) do
            Refill(t, "metal")
            Refill(t, "energy")
        end
    end
end

else

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  UNSYNCED
--

--constants
local MY_PLAYER_ID = Spring.GetMyPlayerID()
local FIX_CONFIG_FOLDER = "LuaRules/configs/prometheus"
local CONFIG_FOLDER = "LuaRules/Config/prometheus"
local SAVE_PERIOD = 30 * 60  -- Save once per minute

local TRAINING_MODE = nil  -- Set it true to train, nil to releases
local MIN_TRAINING_TIME, MAX_TRAINING_TIME = 10 * 60, 40 * 60
local DELTA_TRAINING_TIME = 10

-- globals
waypointMgr = {}
base_gann = {}
intelligences = {}  -- One per team


-- include code
include("LuaRules/Gadgets/prometheus/base/buildsite.lua")
include("LuaRules/Gadgets/prometheus/base.lua")
include("LuaRules/Gadgets/prometheus/combat.lua")
include("LuaRules/Gadgets/prometheus/flags.lua")
include("LuaRules/Gadgets/prometheus/heatmap.lua")
include("LuaRules/Gadgets/prometheus/intelligence.lua")
include("LuaRules/Gadgets/prometheus/taxi.lua")
include("LuaRules/Gadgets/prometheus/team.lua")
include("LuaRules/Gadgets/prometheus/pathfinder.lua")
include("LuaRules/Gadgets/prometheus/waypoints.lua")
include("LuaRules/Gadgets/prometheus/gann/gann.lua")

-- locals
local prometheus_Debug_Mode =  0--1 -- Must be 0 or 1
local team = {}
local firstFrame = math.max(1,Spring.GetGameFrame()) + 1
local lastFrame = 0 -- To avoid repeated calls to GameFrame()
local training_time

--------------------------------------------------------------------------------

local function ChangeAIDebugVerbosity(cmd,line,words,player)
	local lvl = tonumber(words[1])
	if lvl then
		prometheus_Debug_Mode = lvl
		Spring.Echo("Prometheus: debug verbosity set to " .. prometheus_Debug_Mode)
	else
		if prometheus_Debug_Mode > 0 then
			prometheus_Debug_Mode = 0
		else
			prometheus_Debug_Mode = 1
		end

		Spring.Echo("Prometheus : debug verbosity toggled to " .. prometheus_Debug_Mode)
	end
	return true
end

local function SetupCmdChangeAIDebugVerbosity()
	local cmd,func,help
	cmd  = "prometheus"
	func = ChangeAIDebugVerbosity
	help = " [0|1]: make Prometheus shut up or fill your infolog"
	gadgetHandler:AddChatAction(cmd,func,help)
	--Script.AddActionFallback(cmd .. ' ',help)
end

function gadget.IsDebug(teamID)
    if prometheus_Debug_Mode == 0 then return false end

    if teamID == nil then
        return prometheus_Debug_Mode ~= nil
    end
    return prometheus_Debug_Mode == teamID
end

function gadget.IsTraining()
    return TRAINING_MODE == true
end

local eachErrorOnlyOnce={}
function gadget.Log(...)
	if prometheus_Debug_Mode > 0 then
      local arg = {...};
      arg.n = #arg

    local message = "Prometheus: " 
	for i,v in ipairs(arg) do
        message = message .. tostring(v) .. "\t"
    end

	if not eachErrorOnlyOnce[message] then
 	  Spring.Echo(message)
        eachErrorOnlyOnce[message] = true	
	end
    end    
end    

-- This is for log messages which can not be turned off (e.g. while loading.)
function gadget.Warning(...)
	Spring.Echo("Prometheus: " .. table.concat{...})
end

-- To read/save data, they replace widgets GetConfigData() and SetConfigData()
-- callins
function SetConfigData()
    local data = {}
    if VFS.FileExists(CONFIG_FOLDER .. "/prometheus.lua") then
        Log("Found config file: ",
            VFS.GetFileAbsolutePath(CONFIG_FOLDER .. "/prometheus.lua"))
        data = VFS.Include(CONFIG_FOLDER .. "/prometheus.lua")
    elseif VFS.FileExists(FIX_CONFIG_FOLDER .. "/prometheus.lua") then
        data = VFS.Include(FIX_CONFIG_FOLDER .. "/prometheus.lua")
    end

    if gadget.IsTraining() then
        if data.training_time then
            training_time = math.min(MAX_TRAINING_TIME, math.max(MIN_TRAINING_TIME,
                                     data.training_time + DELTA_TRAINING_TIME))
        end
        local minutes = math.floor(training_time / 60)
        local seconds = training_time - minutes * 60
        Log("The game will last ", minutes, " minutes and ", seconds, " seconds")
    end

    base_gann.SetConfigData(data.base_gann or {})
end

function GetConfigData()
    local data = {}
    if gadget.IsTraining() then
        data.training_time = training_time
    end
    data.base_gann = base_gann.GetConfigData()
	if Script.LuaUI.CraigGetConfigData then
		Script.LuaUI.CraigGetConfigData(CONFIG_FOLDER,   "prometheus.lua",  table.serialize(data))
	end
end

function CreateTeamGann(teamID)
    base_gann.Procreate(teamID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

-- Execution order:
--  gadget:Initialize
--  gadget:GamePreload
--  gadget:UnitCreated (for each HQ / comm)
--  gadget:GameStart
--  gadget:GameFrame

function gadget:Initialize()
    setmetatable(gadget, {
        __index = function() error("Attempt to read undeclared global variable", 2) end,
        __newindex = function() error("Attempt to write undeclared global variable", 2) end,
    })
    SetupCmdChangeAIDebugVerbosity()
    if gadget.IsTraining() then
        training_time = MIN_TRAINING_TIME
    end
   firstFrame = math.max(1,Spring.GetGameFrame()) + 1
   if not waypointMgr.UnitCreated then waypointMgr = CreateWaypointMgr() end

	base_gann = CreateGANN()
    local base_gann_inputs = VFS.Include("LuaRules/Gadgets/prometheus/base/gann_inputs.lua")
    for _, input in ipairs(base_gann_inputs) do
        base_gann.DeclareInput(input)
    end
    base_gann.DeclareOutput("score")

    SetConfigData()
end

function gadget:GamePreload()
    -- This is executed BEFORE headquarters / commander is spawned
    Log("gadget:GamePreload")
    Spring.Echo("gadet:GamePreload:GetConfigData")
    GetConfigData()
    waypointMgr = CreateWaypointMgr()
end

local function CreateTeams()
	Spring.Echo("Prometheus:CreateTeams")
	-- Initialise AI for all team that are set to use it
	local sidedata = Spring.GetSideData()
	local name = gadget:GetInfo().name

	for _,t in ipairs(Spring.GetTeamList()) do
		if (Spring.GetTeamLuaAI(t) == name) then
			local _,leader,_,_,_,at = Spring.GetTeamInfo(t)
			if (leader == MY_PLAYER_ID) then
				local units = Spring.GetTeamUnits(t)
				-- Figure out the side we're on by searching for our
				-- startUnit in Spring's sidedata.
				--local tteam = select(4,Spring.GetPlayerInfo(leader))
				local side    =  string.lower(select(5,Spring.GetTeamInfo(t)))
				Log("Team "..t.. " is of side " .. side)

				if (side) then
				   -- Intialise intelligence and the gann individual
					    intelligences[t] = CreateIntelligence(t, at)
					    CreateTeamGann(t)
					team[t] = CreateTeam(t, at, side)
					team[t].GameStart()
					-- Call UnitCreated and UnitFinished for the units we have.
					-- (the team didn't exist when those were originally called)
					for _,u in ipairs(units) do
						if (not Spring.GetUnitIsDead(u)) then
							local ud = Spring.GetUnitDefID(u)
							team[t].UnitCreated(u, ud, t)
							team[t].UnitFinished(u, ud, t)
						end
					end
				else
					Warning(" Startunit not found, don't know as which side I'm supposed to be playing.")
				end			
			end
		end
	end
end

function gadget:GameFrame(f)
    if gadget.IsTraining() and Spring.GetGameSeconds() > training_time then
        Spring.Echo("gadet:GameFrame:GetConfigData1")
        GetConfigData()
        Spring.Quit()
    end

    if (f < 1) or (f == lastFrame) then
        return
    end
    lastFrame = f

	if  f == firstFrame then
	        -- This is executed AFTER headquarters / commander is spawned
        Log("gadget:GameFrame 1")
        waypointMgr.GameStart()

        -- We perform this only this late, and then fake UnitFinished for all units
        -- in the team, to support random faction (implemented by swapping out HQ
        -- in GameStart of that gadget.)
        CreateTeams()

        for _, intelligence in pairs(intelligences) do
            intelligence.GameStart()
        end
    end
    if f > firstFrame  then
	    if f % SAVE_PERIOD < 0.01 then
        --Spring.Echo("gadet:GameFrame:GetConfigData2")
		--GetConfigData()
	    end
        if not  waypointMgr.GameFrame then
            waypointMgr = CreateWaypointMgr()
        end
	    waypointMgr.GameFrame(f)
	    for _, intelligence in pairs(intelligences) do
		intelligence.GameFrame(f)
	    end
	    for _,t in pairs(team) do
		t.GameFrame(f)
	    end
    end
end

--------------------------------------------------------------------------------
--
--  Game call-ins
--

function gadget:TeamDied(teamID)
    if team[teamID] then
        team[teamID] = nil
        Log("removed team ", teamID)
    end

    --TODO: need to call this for other/enemy teams too, so a team
    -- can adjust it's fight orders to the remaining living teams.
    --for _,t in pairs(team) do
    --    t.TeamDied(teamID)
    --end
end

function gadget:GameOver(winningAllyTeams)
    if gadget.IsTraining() then
        GetConfigData()
        Spring.Quit()
    end
end

--------------------------------------------------------------------------------
--
--  Unit call-ins
--
storedUnitCreations = {}
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    if not waypointMgr.UnitCreated then
        waypointMgr = CreateWaypointMgr()
    end
    waypointMgr.UnitCreated(unitID, unitDefID, unitTeam, builderID)
    if team[unitTeam] then
        team[unitTeam].UnitCreated(unitID, unitDefID, unitTeam, builderID)
    end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
    if team[unitTeam] then
        team[unitTeam].UnitFinished(unitID, unitDefID, unitTeam)
    end
    for _, intelligence in pairs(intelligences) do
        intelligence.UnitFinished(unitID, unitDefID, unitTeam)
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    waypointMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    for teamID, t in pairs(team) do
        t.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    end
    for _, intelligence in pairs(intelligences) do
        intelligence.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    end
end

function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if team[unitTeam] then
        team[unitTeam].UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if team[unitTeam] then
        team[unitTeam].UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    if team[unitTeam] then
        team[unitTeam].UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    end
end

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    if team[unitTeam] then
        team[unitTeam].UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    end
end

-- This may be called by engine from inside Spring.GiveOrderToUnit (e.g. if unit limit is reached)
function gadget:UnitIdle(unitID, unitDefID, unitTeam)
    if team[unitTeam] then
        team[unitTeam].UnitIdle(unitID, unitDefID, unitTeam)
    end
end

function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    for _, intelligence in pairs(intelligences) do
        intelligence.UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    end
end

function gadget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
    for _, intelligence in pairs(intelligences) do
        intelligence.UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
    end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
    for _, intelligence in pairs(intelligences) do
        intelligence.UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
    end
end

end

-- Set up LUA AI framework.
callInList = {
    --"GamePreload",
    --"GameStart",
    --"GameFrame",
    --"TeamDied",
    --"UnitCreated",
    --"UnitFinished",
    --"UnitDestroyed",
    --"UnitTaken",
    --"UnitGiven",
    --"UnitIdle",
    --"UnitEnteredLos",
    --"UnitLeftLos",
}

VFS.Include("LuaRules/Gadgets/prometheus/framework.lua", nil, VFS.ZIP)
