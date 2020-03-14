--no need to understand this for the beginning.
--this script spawns the start unit from sidedata.lua for each player

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- file: game_spawn.lua
-- brief: spawns start unit and sets storage levels
-- author: Tobi Vollebregt
--
-- Copyright (C) 2010.
-- Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
    return {
        name = "Spawn",
        desc = "spawns start unit and sets storage levels",
        author = "Tobi Vollebregt",
        date = "January, 2010",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true -- loaded by default?
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
    return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

local modOptions = Spring.GetModOptions()
GameConfig = getGameConfig()
function GetAIStartUnit(teamID, leader, isDead, boolIsAI, side, playerInfo)

    aiName = Spring.GetTeamLuaAI(teamID)

    if aiName and aiName == "spawner" then
        if side == "antagon" then
            return "operativepropagator"
        end

        if side == "protagon" then
            return "operativeinvestigator"
        end

        return "operativepropagator"
    end

 

    if aiName and aiName == "" then
        if side == "antagon" then
            return "operativepropagator"
        else
            return "operativeinvestigator"
        end
    end
	
	
	  return "operativepropagator"
end

local function GetStartUnit(teamID)
    -- get the team startup info

    local startUnit = ""
    local AI_Type = "Spawner"



    --if side is a AI



    local playerInfo = Spring.GetPlayerList(teamID)
    local foundAtHorses = false
    local foundAtSpawner = false
    local teamID, leader, isDead, boolIsAI, side = Spring.GetTeamInfo(teamID)
    local sidedata = Spring.GetSideData(side)

    if boolIsAI == true then
        return GetAIStartUnit(teamID, leader, isDead, boolIsAI, side, playerInfo)
    end

    if sidedata and sidedata.startunitspawner then
        if not GG.AtLeastOneSpawner then GG.AtLeastOneSpawner = true end

        return sidedata.startunitspawner
    elseif sidedata and sidedata.startunitai then
        return sidedata.startunitai
    end

    -- we are human

    if sidedata and sidedata.startunit and sidedata.startunit ~= "" then return sidedata.startunit end

    if side == "antagon" then return "operativepropagator" end
    if side == "protagon" then return "operativeinvestigator" end

    return "operativepropagator"
end

local function SpawnStartUnit(teamID)
    local startUnit = GetStartUnit(teamID)
    if (startUnit and startUnit ~= "") then
        --Spring.Echo("GameStart::Called for 3 team .."..teamID)
        -- spawn the specified start unit
        local x, y, z = Spring.GetTeamStartPosition(teamID)
        -- snap to 16x16 grid
        x, z = 16 * math.floor((x + 8) / 16), 16 * math.floor((z + 8) / 16)
        y = Spring.GetGroundHeight(x, z)
        -- facing toward map center
        local facing = math.abs(Game.mapSizeX / 2 - x) > math.abs(Game.mapSizeZ / 2 - z)
                and ((x > Game.mapSizeX / 2) and "west" or "east")
                or ((z > Game.mapSizeZ / 2) and "north" or "south")
        local unitID = Spring.CreateUnit(startUnit, x, y + GameConfig.OperativeDropHeigthOffset, z, facing, teamID)
				giveParachutToUnit(unitID,  x, y + GameConfig.OperativeDropHeigthOffset, z)
       -- Here be additional units
    end

    -- set start resources, either from mod options or custom team keys
    local m = 1500
    local e =  1500

    -- using SetTeamResource to get rid of any existing resource without affecting stats
    -- using AddTeamResource to add starting resource and counting it as income
    if (m and tonumber(m) ~= 0) then
        -- remove the pre-existing storage
        -- must be done after the start unit is spawned,
        -- otherwise the starting resources are lost!
        Spring.SetTeamResource(teamID, "ms", tonumber(m))
        Spring.SetTeamResource(teamID, "m", 0)
        Spring.AddTeamResource(teamID, "m", tonumber(m))
    end
    if (e and tonumber(e) ~= 0) then
        -- remove the pre-existing storage
        -- must be done after the start unit is spawned,
        -- otherwise the starting resources are lost!
        Spring.SetTeamResource(teamID, "es", tonumber(e))
        Spring.SetTeamResource(teamID, "e", 0)
        Spring.AddTeamResource(teamID, "e", tonumber(e))
    end
end

function noStartUnitsNeeded(teams)
if #Spring.GetAllUnits() == 0 then return false end

  for i = 1, #teams do
		local teamID = teams[i]

        if (teamID ~= gaiaTeamID) then
				--Get all team Units
           T= Spring.GetTeamUnitsSorted(teamID)
				if not T[UnitDefNames["operativeinvestigator"].id] and not T[UnitDefNames["operativepropagator"].id] then 
					return false
				end		   
        end
  end
  return true
end

function gadget:GameStart()
	
	Spring.Echo("Starting game MOSAIC Version "..GameConfig.Version)
    --creates a Tech Tree in GG
    local teams = Spring.GetTeamList()
	
    -- only activate if engine didn't already spawn units (compatibility)
    if (noStartUnitsNeeded(teams)==true) then
        return
    end
	
    -- spawn start units
    local gaiaTeamID = Spring.GetGaiaTeamID()

    for i = 1, #teams do
        local teamID = teams[i]
        --Spring.Echo("GameStart::Called for team .."..teamID)
        -- don't spawn a start unit for the Gaia team
        if (teamID ~= gaiaTeamID) then
            SpawnStartUnit(teamID)
        end
    end
end

