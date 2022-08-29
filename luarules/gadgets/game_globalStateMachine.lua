--
-- file: game_end.lua
-- brief: spawns start unit and sets storage levels
-- author: Andrea Piras
--
-- Copyright (C) 2010,2011.
-- Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
    return {
        name = "GameStateMachine",
        desc = "Detects Teamdeaths and Win/Loose Condtions",
        author = "Andrea Piras",
        date = "August, 2010",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true -- loaded by default?
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_UnitScript.lua")

local modOptions = Spring.GetModOptions()

-- teamDeathMode possible values: "none", "teamzerounits" , "allyzerounits"
local teamDeathMode = modOptions.teamdeathmode or "teamzerounits"

-- sharedDynamicAllianceVictory is a C-like bool
local sharedDynamicAllianceVictory = tonumber(
                                         modOptions.shareddynamicalliancevictory) or
                                         0

-- ignoreGaia is a C-like bool
local ignoreGaia = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gaiaTeamID = Spring.GetGaiaTeamID()
local gaiaTeamID = Spring.GetGaiaTeamID()
local spKillTeam = Spring.KillTeam
local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetTeamList = Spring.GetTeamList
local spGetTeamInfo = Spring.GetTeamInfo
local spGameOver = Spring.GameOver
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetTeamStats = Spring.GetTeamStatsHistory
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gaiaAllyTeamID
local allyTeams = spGetAllyTeamList()
local teamsUnitCount = {}
local allyTeamUnitCount = {}
local allyTeamAliveTeamsCount = {}
local teamToAllyTeam = {}
local aliveAllyTeamCount = 0
local killedAllyTeams = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local GameConfig = getGameConfig()

 GG.GlobalGameState = GameConfig.GameState.normal
 oldState = nil
function setGlobalGameState(state)
    GG.GlobalGameState = state
    Spring.SetGameRulesParam("GlobalGameState:", state)
    if oldState ~= state then
     Spring.Echo("Global GameState: "..state)
    end
end


local GameStateMachine = {
    Timer = Spring.GetGameFrame(),

    ["normal"] = function(frame)
        if GG.Launchers then
            for teamID, launchersT in pairs(GG.Launchers) do
                if teamID and launchersT then
                    for launcherID, data in pairs(launchersT) do
                        local step = data.steps
                        if doesUnitExistAlive(launcherID) == true and 
                            step > GameConfig.PreLaunchLeakSteps then
                            echo("Launcher "..launcherID.." is over PreLaunchLeakSteps going to launchleak")
                            Spring.SetUnitAlwaysVisible(launcherID, true)
                            GG.GameStateMachine.Timer = frame
                            return GameConfig.GameState.launchleak
                        end
                    end
                end
            end
        end

        return GameConfig.GameState.normal
    end,

    ["launchleak"] = function(frame)
        if GG.GameStateMachine.Timer + GameConfig.TimeForPanicSpreadInFrames <
            frame then
            GG.GameStateMachine.Timer = frame
            return GameConfig.GameState.anarchy
        end

        return GameConfig.GameState.launchleak
    end,

    ["postlaunch"] = function(frame)
        if LaunchedRockets then
            for teamID, launchedT in pairs(LaunchedRockets) do
                for id, launchedFrame in pairs(launchedT) do
                    if id and doesUnitExistAlive(id) == true and launchedFrame +
                        GameConfig.TimeForInterceptionInFrames < frame then
                        winners = {teamID}
                        spGameOver(winners)
                        return GameConfig.GameState.gameover
                    end
                end
            end
        end

        return GameConfig.GameState.postlaunch
    end,

    ["anarchy"] = function(frame)

        if GG.Launchers then
            boolNoReadyLaunchers = true
            for teamID, launchersT in pairs(GG.Launchers) do
                if teamID and launchersT then
                    for launcherID, data in pairs(launchersT) do
                        local step = data.steps
                        if launcherID and doesUnitExistAlive(launcherID) and step >= GameConfig.PreLaunchLeakSteps then
                            boolNoReadyLaunchers = false
                        end
                    end
                end
            end

            if boolNoReadyLaunchers == true then
                GG.GameStateMachine.Timer = frame
                return GameConfig.GameState.pacification
            end
        end

        return GameConfig.GameState.anarchy
    end,

    ["gameover"] = function(frame) return GameConfig.GameState.gameover end,

    ["pacification"] = function(frame)

        if GG.GameStateMachine.Timer + GameConfig.TimeForPacification < frame then
            GG.GameStateMachine.Timer = frame
            return GameConfig.GameState.normal
        end

        return GameConfig.GameState.pacification
    end
}

local gameStartFrame = Spring.GetGameFrame() +1
function gadget:Initialize()
    Spring.Echo(GetInfo().name .. " Initialization started")
    setGlobalGameState(GameConfig.GameState.normal)

    GG.Launchers = {}
    GG.GameStateMachine = GameStateMachine
    GG.GlobalGameStateOverride = nil
    GG.SetGameStateTo = nil
    if teamDeathMode == "none" then
        Spring.Echo("GameEndGadget: No teamDeathMode specified")
        gadgetHandler:RemoveGadget()
    end

    gaiaAllyTeamID = select(6, spGetTeamInfo(gaiaTeamID))

    -- at start, fill in the table of all alive allyteams
    for _, allyTeamID in ipairs(allyTeams) do
        local teamList = spGetTeamList(allyTeamID)
        local teamCount = 0
        for _, teamID in ipairs(teamList) do
            teamToAllyTeam[teamID] = allyTeamID
            if (ignoreGaia == 0) or (teamID ~= gaiaTeamID) then
                teamCount = teamCount + 1
            end
        end
        allyTeamAliveTeamsCount[allyTeamID] = teamCount
        if teamCount > 0 then aliveAllyTeamCount = aliveAllyTeamCount + 1 end
    end
    gameStartFrame = Spring.GetGameFrame() +1
    Spring.Echo(GetInfo().name .. " Initialization ended")
end

LaunchedRockets = {}

function gadget:GameOver()
    -- remove ourself after successful game over
    gadgetHandler:RemoveGadget()
end

local function IsCandidateWinner(allyTeamID)
    local isAlive = (killedAllyTeams[allyTeamID] ~= true)
    local gaiaCheck = ignoreGaia or (allyTeamID ~= gaiaAllyTeamID)
    return isAlive and gaiaCheck
end

local function CheckSingleAllyVictoryEnd()
    if aliveAllyTeamCount ~= 1 then return false end

    -- find the last remaining allyteam
    for _, candidateWinner in ipairs(allyTeams) do
        if IsCandidateWinner(candidateWinner) then
            return {candidateWinner}
        end
    end

    return {}
end

local function AreAllyTeamsDoubleAllied(firstAllyTeamID, secondAllyTeamID)
    -- we need to check for both directions of alliance
    return spAreTeamsAllied(firstAllyTeamID, secondAllyTeamID) and spAreTeamsAllied(secondAllyTeamID, firstAllyTeamID)
end

local function CheckSharedAllyVictoryEnd()
    -- we have to cross check all the alliances
    local candidateWinners = {}
    local winnerCountSquared = 0
    for _, firstAllyTeamID in ipairs(allyTeams) do
        if IsCandidateWinner(firstAllyTeamID) then
            for _, secondAllyTeamID in ipairs(allyTeams) do
                if IsCandidateWinner(secondAllyTeamID) and
                    AreAllyTeamsDoubleAllied(firstAllyTeamID, secondAllyTeamID) then
                    -- store both check directions
                    -- since we're gonna check if we're allied against ourself, only secondAllyTeamID needs to be stored
                    candidateWinners[secondAllyTeamID] = true
                    winnerCountSquared = winnerCountSquared + 1
                end
            end
        end
    end

    if winnerCountSquared == (aliveAllyTeamCount * aliveAllyTeamCount) then
        -- all the allyteams alive are bidirectionally allied against eachother, they are all winners
        local winnersCorrectFormat = {}
        for winner in pairs(candidateWinners) do
            winnersCorrectFormat[#winnersCorrectFormat + 1] = winner
        end
        return winnersCorrectFormat
    end

    -- couldn't find any winner
    return false
end

local function CheckGameOver()
    local winners
    if sharedDynamicAllianceVictory == 0 then
        winners = CheckSingleAllyVictoryEnd()
    else
        winners = CheckSharedAllyVictoryEnd()
    end

    if winners then spGameOver(winners) end
end

local function KillTeamsZeroUnits()
    -- kill all the teams that have zero units
    for teamID, unitCount in pairs(teamsUnitCount) do
        if teamID and unitCount then
            max = spGetTeamStats(teamID)
            Stratss = {}
            Stratss = spGetTeamStats(teamID, max, max)

            if unitCount == 0 and (Stratss[1].unitsDied >=
                (Stratss[1].unitsCaptured + Stratss[1].unitsReceived +
                    Stratss[1].unitsProduced)) then
                spKillTeam(teamID)
            end
        end
    end
end

local function KillAllyTeamsZeroUnits()
    -- kill all the allyteams that have zero units
    for allyTeamID, unitCount in pairs(allyTeamUnitCount) do
        if unitCount == 0 then
            -- kill all the teams in the allyteam
            local teamList = spGetTeamList(allyTeamID)
            for _, teamID in ipairs(teamList) do
                -- DelME
                spKillTeam(teamID)
            end
        end
    end
end

local function KillResignedTeams()
    -- Check for teams w/o leaders -> all players resigned & no AIs left in the team
    -- Note: In the case a player drops he will still be the leader of the team!
    -- So he can reconnect and take his units.
    local teamList = Spring.GetTeamList()
    for i = 1, #teamList do
        local teamID = teamList[i]
        local leaderID = select(2, spGetTeamInfo(teamID))
        if (leaderID < 0) then spKillTeam(teamID) end
    end
end

function constantCheck(frame)
    if GG.Launchers then
        for teamID, launchersT in pairs(GG.Launchers) do
            if teamID and launchersT then
                for launcherID, data in pairs(launchersT) do
                    step =data.steps
                       -- Spring.Echo("Launcher "..launcherID.." has "..step .." of "..GameConfig.LaunchReadySteps.." steps to go")
                    if launcherID and step >= GameConfig.LaunchReadySteps and  data.payload then
                        id = createUnitAtUnit(teamID, "launchedicbm",
                                              launcherID, 0, 70, 0)
                        if not LaunchedRockets[teamID] then
                            LaunchedRockets[teamID] = {}
                        end
                        LaunchedRockets[teamID][id] = frame
                        Spring.DestroyUnit(launcherID, false, true)
                        GG.Launchers[teamID][launcherID] = nil

                        GG.GameStateMachine.Timer = frame
                        setGlobalGameState(GameConfig.GameState.postlaunch)
                    end
                end
            end
        end
    end

    if frame + 100 > gameStartFrame then
        local teams = Spring.GetTeamList()
        for i = 1, #teams do
            if TeamHasMinimumNecessaryToWin(teams[i])  == false then
                Spring.KillTeam(teams[i])
            end
        end
    end
end
local teamHadAtLeastOneUnit = {}
local victoryStillPossibleTypeTables = getVictoryStillPossibleTypeSets(UnitDefs)
function TeamHasMinimumNecessaryToWin(teamID)
    if nil == teamHadAtLeastOneUnit[teamID] then      teamHadAtLeastOneUnit[teamID] = false end

   teamDefIDsUnitTable = Spring.GetTeamUnitsSorted(teamID) 
   for defID, unitCount in pairs(teamDefIDsUnitTable) do
        if unitCount ~= 0  then
            teamHadAtLeastOneUnit[teamID] = true
            for i=1, #victoryStillPossibleTypeTables do
                winningConditionUnitTypeSets = victoryStillPossibleTypeTables[i]
                if winningConditionUnitTypeSets[defID] then
                    return true
                end
            end
        end
   end

   return teamHadAtLeastOneUnit[teamID] == false
end

oldState = "normal"
function holdSpeach(transition)
    speaches = {
        [GameConfig.GameState.normal .. ">" .. GameConfig.GameState.launchleak] = "Transition from normal to launchleakpanic",
        [GameConfig.GameState.launchleak .. ">" .. GameConfig.GameState.anarchy] = "Transition from launchleak to anarchy",
        [GameConfig.GameState.anarchy .. ">" .. GameConfig.GameState.postlaunch] = "Transition from anarchy to postlaunch",
        [GameConfig.GameState.anarchy .. ">" ..
            GameConfig.GameState.pacification] = "Transition from anarchy to pacification",
        [GameConfig.GameState.pacification .. ">" .. GameConfig.GameState.normal] = "Transition from pacification to normal"
    }

    sounds = {
        [GameConfig.GameState.normal .. ">" .. GameConfig.GameState.launchleak] = nil,
        [GameConfig.GameState.launchleak .. ">" .. GameConfig.GameState.anarchy] = "sounds/gamestate/normal_anarchy.ogg",
        [GameConfig.GameState.anarchy .. ">" .. GameConfig.GameState.postlaunch] = nil,
        [GameConfig.GameState.anarchy .. ">" ..
            GameConfig.GameState.pacification] = "sounds/gamestate/anarchy_pacification.ogg",
        [GameConfig.GameState.pacification .. ">" .. GameConfig.GameState.normal] = nil
    }
    if speaches[transition] then echo(speaches[transition]) end
    if sounds[transition] then Spring.PlaySoundFile(sounds[transition], 1.0) end

end
function gadget:GameFrame(frame)
    -- only do a check in slowupdate
    if frame > 1 and (frame % 16) == 0 then

        constantCheck(frame)
        newGlobalGameState = GG.GameStateMachine[GG.GlobalGameState](frame) 
        if GG.GlobalGameStateOverride then --permanent overwrite for debugging
            newGlobalGameState =GG.GlobalGameStateOverride
        end
        if  GG.SetGameStateTo then --one time set and removal
            newGlobalGameState = GG.SetGameStateTo
            GG.SetGameStateTo = nil
        end
        setGlobalGameState(newGlobalGameState)

        if GG.GlobalGameState and oldState ~= GG.GlobalGameState then
            holdSpeach(oldState .. ">" .. GG.GlobalGameState)
            oldState = GG.GlobalGameState
        end

        CheckGameOver()
        -- kill teams after checking for gameover to avoid to trigger instantly gameover
        if teamDeathMode == "teamzerounits" then
            KillTeamsZeroUnits()
        elseif teamDeathMode == "allyzerounits" then
            KillAllyTeamsZeroUnits()
        end
        KillResignedTeams()
    end
end

function gadget:TeamDied(teamID)
    teamsUnitCount[teamID] = nil
    local allyTeamID = teamToAllyTeam[teamID]
    local aliveTeamCount = allyTeamAliveTeamsCount[allyTeamID]
    if aliveTeamCount then
        aliveTeamCount = aliveTeamCount - 1
        allyTeamAliveTeamsCount[allyTeamID] = aliveTeamCount
        if aliveAllyTeamCount == 1 then
            Spring.Echo("Team won")
        elseif aliveTeamCount <= 0 then
            -- one allyteam just died
            aliveAllyTeamCount = aliveAllyTeamCount - 1
            allyTeamUnitCount[allyTeamID] = nil
            killedAllyTeams[allyTeamID] = true
        end
    end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeamID)
    local teamUnitCount = teamsUnitCount[unitTeamID] or 0
    teamUnitCount = teamUnitCount + 1
    teamsUnitCount[unitTeamID] = teamUnitCount
    local allyTeamID = teamToAllyTeam[unitTeamID]
    local allyUnitCount = allyTeamUnitCount[allyTeamID] or 0
    allyUnitCount = allyUnitCount + 1
    allyTeamUnitCount[allyTeamID] = allyUnitCount
end

gadget.UnitGiven = gadget.UnitCreated
gadget.UnitCaptured = gadget.UnitCreated

function gadget:UnitDestroyed(unitID, unitDefID, unitTeamID)
    if unitTeamID == gaiaTeamID and ignoreGaia ~= 0 then
        -- skip gaia
        return
    end
    local teamUnitCount = teamsUnitCount[unitTeamID]
    if teamUnitCount then
        teamUnitCount = teamUnitCount - 1
        teamsUnitCount[unitTeamID] = teamUnitCount
    end
    local allyTeamID = teamToAllyTeam[unitTeamID]
    local allyUnitCount = allyTeamUnitCount[allyTeamID]
    if allyUnitCount then
        allyUnitCount = allyUnitCount - 1
        allyTeamUnitCount[allyTeamID] = allyUnitCount
    end
end

gadget.UnitTaken = gadget.UnitDestroyed
