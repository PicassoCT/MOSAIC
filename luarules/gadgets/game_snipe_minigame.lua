function gadget:GetInfo()
    return {
        name = "game Snipe Mini Game",
        desc = "This gadget handles the minigame",
        author = "",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    -- variables
    local raidIconDefID = UnitDefNames["raidicon"].id
    local snipeIconDefID = UnitDefNames["snipeicon"].id
    local objectiveDefID = UnitDefNames["objectiveicon"].id
    local allRunningRaidRounds = {}
    local Aggressor = "Aggressor"
    local Defender = "Defender"
    local raidStates = getRaidStates()
    local raidResultStates = getRaidResultStates()
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local spGetUnitPosition = Spring.GetUnitPosition
    local spCreateUnit = Spring.CreateUnit
    local spGetUnitTeam = Spring.GetUnitTeam
    local spCallAsUnit = Spring.UnitScript.CallAsUnit
    local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
    local spGetUnitDefID = Spring.GetUnitDefID
    local spDestroyUnit = Spring.DestroyUnit
    local postRoundTimeInSeconds = 15
    local safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)

    GameConfig = getGameConfig()
    function alwaysShowUnit(id, observerTeam)
        -- transferUnitTeam(id, gaiaTeamID)
        showUnit(id)
        spSetUnitAlwaysVisible(id, true)
    end
    function gadget:Initialize()
        if not GG.raidStatus then GG.raidStatus = {} end
    end

    function alwaysHideUnit(id)
        spSetUnitAlwaysVisible(id, false)
        hideUnit(id)
    end

    function gadget:UnitCreated(unitID, unitDefID, unitTeam)
        if unitDefID == raidIconDefID then
            if not GG.raidStatus then GG.raidStatus = {} end
            if not GG.raidStatus[unitID] then GG.raidStatus[unitID] = {} end
            newRound(unitID, unitTeam, true)
        end

        if unitDefID == snipeIconDefID then
            alwaysHideUnit(snipeIconDefID)
            echo("Snipeicon created for team: " .. unitTeam)
        end
    end

    function getDefenderTeam(raidIconID, attackerteam, oldDefenderTeam)
        attackerAllyTeam = Spring.GetUnitAllyTeam(raidIconID)
        if oldDefenderTeam then return oldDefenderTeam end

        plausibleDefenderTeams = {}

        process(getAllNearUnit(raidIconID, 100), function(id)
            if id then
                defID = spGetUnitDefID(id)
                team = spGetUnitTeam(id)
                allyteam = Spring.GetUnitAllyTeam(id)
                if safeHouseTypeTable[defID] and team ~= attackerteam and team ~=
                    gaiaTeamID and attackerAllyTeam ~= allyteam then
                    plausibleDefenderTeams[#plausibleDefenderTeams + 1] = team
                end
            end
        end)

        if #plausibleDefenderTeams > 0 then
            -- chose a random one from the opppsing ally team
            if #plausibleDefenderTeams == 1 then
                return plausibleDefenderTeams[1]
            end
            return
                plausibleDefenderTeams[math.random(1, #plausibleDefenderTeams)]
        else -- no known defender - fall back to assigning a random one
            tl = Spring.GetTeamList()
            for i = 1, #tl do
                if tl[i] ~= gaiaTeamID and tl[i] ~= attackerteam then
                    return tl[i]
                end
            end
        end

        -- Spring.Echo("Finding opossing team defaults to gaia")
        return gaiaTeamID
    end

    function newRound(raidIconID, attackerteam, boolGameStart, oldRound)
        setRaidIconProgress(raidIconID, 0)
        -- get a defender
        defenderTeamID = gaiaTeamID
        if oldRound and oldRound.Defender and oldRound.Defender.team then
            defenderTeamID = getDefenderTeam(raidIconID, attackerteam,
                                             oldRound.Defender.team)
        else
            -- Spring.Echo("Reusing old defenderTeamID")
            defenderTeamID = getDefenderTeam(raidIconID, attackerteam)
        end

        setPublicRaidState(raidIconID, raidStates.OnGoing)
        local returnTable = {
            boolAIChecked = false,
            Objectives = {},
            Aggressor = {
                team = attackerteam,
                Points = GameConfig.SnipeMiniGame.Aggressor.StartPoints,
                PlacedFigures = {}
            },
            Defender = {
                team = defenderTeamID,
                Points = GameConfig.SnipeMiniGame.Defender.StartPoints,
                PlacedFigures = {}
            }
        }

        if boolGameStart == false and oldRound then
            returnTable.Defender.Points = oldRound.Defender.Points
            returnTable.Defender.team = oldRound.Defender.team
            returnTable.Aggressor.Points = oldRound.Aggressor.Points
            returnTable.Aggressor.team = oldRound.Aggressor.team
        end

        allRunningRaidRounds[raidIconID] = returnTable
        updatePointData(raidIconID, allRunningRaidRounds[raidIconID])
    end

    function updatePointData(raidIconID, roundRunning)
        env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.updateShownPoints then
            spCallAsUnit(raidIconID, env.updateShownPoints,
                         roundRunning.Aggressor.Points,
                         roundRunning.Defender.Points)
        end
    end

    function registerPlaceUnit(raidIconID, unitID, roundRunning)
        env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.registerPlaceUnit then
            spCallAsUnit(raidIconID, env.registerPlaceUnit, unitID,
                         Spring.GetUnitDefID(unitID) == objectiveDefID)
            updatePointData(raidIconID, roundRunning)
        end
    end

    function RegisterObjective(raidIconID)
        x, y, z = spGetUnitPosition(raidIconID)

        tx, ty, tz = x + math.random(0, 50) * randSign(), y,
                     z + math.random(0, 50) * randSign()
        randDirs = math.random(1, 3)
        objectiveIcon = spCreateUnit("objectiveicon", tx, ty, tz, randDirs,
                                     gaiaTeamID)
        spSetUnitAlwaysVisible(objectiveIcon, true)
        allRunningRaidRounds[raidIconID].Objectives[objectiveIcon] =
            objectiveIcon
        registerPlaceUnit(raidIconID, objectiveIcon,
                          allRunningRaidRounds[raidIconID])
        return objectiveIcon
    end

    local function RegisterSniperIcon(self, unitID, unitTeam, raidIconID)
        assert(unitID)
        assert(raidIconID)
        assert(type(unitID) == "number")
        assert(type(raidIconID) == "number")
        
        teamSelected = Defender -- defender as default
        if spGetUnitTeam(raidIconID) == spGetUnitTeam(unitID) then -- Aggressor
            teamSelected = Aggressor
        end

        if allRunningRaidRounds[raidIconID][teamSelected].Points > 0 then
            allRunningRaidRounds[raidIconID][teamSelected].PlacedFigures[unitID] =
                unitID
            allRunningRaidRounds[raidIconID][teamSelected].Points =
                allRunningRaidRounds[raidIconID][teamSelected].Points - 1
            registerPlaceUnit(raidIconID, unitID,
                              allRunningRaidRounds[raidIconID]) -- reach Into Icon and update Points
        else
            -- Spring.Echo("Points that lead to unit Killed:" .. allRunningRaidRounds[raidIconID][teamSelected].Points)
            GG.UnitsToKill:PushKillUnit(unitID)
        end
    end
    if GG.SniperIcon == nil then
        GG.SniperIcon = {Register = RegisterSniperIcon}
    end

    TheGloriousDead = {}
    Graph = {}

    function getUnitsInTriangle(id)
        env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.getUnitsInTriangle then
            return spCallAsUnit(id, env.getUnitsInTriangle)
        else
            -- Spring.Echo("Unit " .. id .. " is not a snipeIcon")
        end
        return {}
    end

    function getIconProgress(id)
        env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.getRoundProgressBar then
            return spCallAsUnit(id, env.getRoundProgressBar)
        end
        return 0
    end

    function setRaidIconProgress(id, value)
        env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.setRoundProgressBar then
            return spCallAsUnit(id, env.setRoundProgressBar, value)
        end
        return 0
    end

    allAllreadyExploredNodes = {}
    function depthFirstSearchForCycles(start) -- returns true if a cycle is found
        if not allAllreadyExploredNodes[start] then
            allAllreadyExploredNodes[start] = 0
        end
        if allAllreadyExploredNodes[start] > 1 then return true, start end
        allAllreadyExploredNodes[start] = allAllreadyExploredNodes[start] + 1

        if not Graph[start] then return false, {} end

        boolFoundCycle = false
        for to, _ in pairs(Graph[start]) do
            bResult, resultT = depthFirstSearchForCycles(to)
            boolFoundCycle = boolFoundCycle or bResult
        end

        filteredTable = {}
        if boolFoundCycle == true then
            for k, v in pairs(allAllreadyExploredNodes) do
                if v > 1 then filteredTable[k] = k end
            end
        end

        return boolFoundCycle, filteredTable
    end

    function getListOfSolitaryEdges()
        SolitaryEdges = {}
        EdgesPointedTowards = {}

        for from, toTable in pairs(Graph) do
            SolitaryEdges[from] = from
            if toTable then
                for to, _ in pairs(Graph) do
                    EdgesPointedTowards[to] = to
                end
            end
        end

        newSolitaryEdges = {}

        for from, _ in pairs(SolitaryEdges) do
            if not EdgesPointedTowards[from] then
                newSolitaryEdges[from] = from
            end
        end

        return newSolitaryEdges
    end

    function testShotForObsticle(raidIconID, id, ad)
        env = Spring.UnitScript.GetScriptEnv(raidIconID)

        if env and env.testTwoUnits then
            return spCallAsUnit(raidIconID, env.testTwoUnits, id, ad)
        end

        return false
    end

    function evaluateEndedRound(raidIconId, roundRunning, raidIconID)
        winningTeam = nil
        Graph = {}
        local OriginalGraph = {}
        boolFirstGraph = true

        --check House empty
        if GG.HouseRaidIconMap and GG.houseHasSafeHouseTable then
            local raidIconMap =  GG.HouseRaidIconMap
            local houseSafeHouseMap = GG.houseHasSafeHouseTable 
            for  houseID, iconID in pairs(raidIconMap) do
                --no safehouse attached to it
                if houseID and iconID == raidIconID then
                    if  not houseSafeHouseMap[houseID] then
                      setPublicRaidState(raidIconId, raidStates.VictoryStateSet, raidResultStates.HouseEmpty, nil, true)
                      return nil, roundRunning, raidResultStates.HouseEmpty, true
                    end
                end
            end
        end
        --[[ GG.HouseRaidIconMap[persPack.unitID] =  raidIconID--]]

        -- early out -if one side has not placed at all
        -- defenders did not play
        if count(roundRunning.Defender.PlacedFigures) == 0 and
            count(roundRunning.Aggressor.PlacedFigures) > 0 then
            setPublicRaidState(raidIconId, raidStates.WaitingForUplink, raidResultStates.AggressorWins, roundRunning.Aggressor.team, true)

            echo(
                "1 roundRunning.Aggressor.team, roundRunning, raidStates.AggressorWins")
            return roundRunning.Aggressor.team, roundRunning, raidStates.WaitingForUplink, true
        end

        -- Aggressor did not play
        if count(roundRunning.Aggressor.PlacedFigures) == 0 and
            count(roundRunning.Defender.PlacedFigures) > 0 then
            setPublicRaidState(raidIconId, raidStates.WaitingForUplink, raidResultStates.DefenderWins,roundRunning.Defender.team, true)
            echo(
                "2 roundRunning.Defender.team, roundRunning, raidStates.DefenderWins")
            return roundRunning.Defender.team, roundRunning, raidStates.WaitingForUplink, true
        end

        -- both did not play abort
        if count(roundRunning.Defender.PlacedFigures) == 0 and
            count(roundRunning.Aggressor.PlacedFigures) == 0 then
            setPublicRaidState(raidIconId,raidStates.Aborted, raidResultStates.DefenderWins, nil, true)

            echo("3  nil, roundRunning, raidStates.Aborted")
            return nil, roundRunning, raidStates.Aborted, true
        end

        -- both sides placed - there was a game
        TheGloriousDead = {}

        repeat
            Graph = {}

            -- find out who aims at who - add it to the graph (as pairs of from to)
            process(mergeDict(roundRunning.Defender.PlacedFigures,
                              roundRunning.Aggressor.PlacedFigures),
                    function(id)
                if TheGloriousDead[id] ~= nil then
                    process(getUnitsInTriangle(id),
                            function(ad) -- add those edges to the graph
                        if TheGloriousDead[ad] ~= nil and ad ~= id and
                            spGetUnitTeam(ad) ~= roundRunning.Aggressor and
                            testShotForObsticle(raidIconId, id, ad) == false then
                            Graph[id] = ad
                        end
                    end)
                end
            end)

            if boolFirstGraph == true then
                OriginalGraph = Graph
                boolFirstGraph = false
            end

            -- nobody aims at anybody
            if (count(Graph) < 1) then break end

            -- we now have a graph of only valid hits - filtered for team on team hits
            -- get a list of edges who nobody aims at
            SolitaryEdges = getListOfSolitaryEdges()

            -- detect solitary edges (ends of aim chains )
            while count(SolitaryEdges) > 0 do
                deadList = {}
                for nobodyAimsAt, _ in pairs(SolitaryEdges) do
                    for from, toT in pairs(Graph) do
                        for to, _ in pairs(toT) do
                            TheGloriousDead[to] = to
                        end
                    end
                end

                for from, toT in pairs(Graph) do
                    if TheGloriousDead[from] then
                        Graph[from] = nil
                    end
                end

                -- eliminate from the solitary edges inwards	from the graph
                SolitaryEdges = getListOfSolitaryEdges()
            end

            -- if it still contains cycles eliminate those entirely
            allAllreadyExploredNodes = {}
            for from, to in pairs(Graph) do
                if from then
                    bIsCycle, cyclicNodes = depthFirstSearchForCycles(from)
                    if bIsCycle == true then
                        process(cyclicNodes,
                                function(id)
                            TheGloriousDead[id] = id
                        end)
                    end
                end
            end

            for id, di in pairs(TheGloriousDead) do Graph[id] = nil end
        until count(Graph) <= 0
        -- Auswertung

        Survivors = findSurvivors(roundRunning, TheGloriousDead)
        process(TheGloriousDead, function(id)
            spawnCegAtUnit(id, "iconkill")
        end)

        -- condense the Dead into Points
        for k, v in pairs(TheGloriousDead) do
            uteam = spGetUnitTeam(k)
            if uteam == roundRunning.Aggressor.team then
                roundRunning.Defender.Points = roundRunning.Defender.Points + 1
            end
            if uteam == roundRunning.Defender.team then
                roundRunning.Agressor.Points = roundRunning.Agressor.Points + 1
            end
        end

        -- Objective Evaluation
        for nr, objective in pairs(roundRunning.Objectives) do
            process(Survivors, function(id)
                if distanceUnitToUnit(objective, id) < 5 then
                    if spGetUnitTeam(id) == roundRunning.Aggressor.team then
                        roundRunning.Aggressor.Points =
                            roundRunning.Aggressor.Points + 2
                    else
                        roundRunning.Defender.Points =
                            roundRunning.Defender.Points + 2
                    end
                end
            end)
        end

        echo("Defender Points:" .. roundRunning.Defender.Points ..
                 " Agressor Points:" .. roundRunning.Aggressor.Points)

        if roundRunning.Defender.Points <= 0 or roundRunning.Aggressor.Points <= 0 then
            -- defenders or agressors dead
            if roundRunning.Defender.Points <= 0 and
                roundRunning.Aggressor.Points > 0 then
                setPublicRaidState(raidIconId, raidState.WaitingForUplink, raidResultStates.AggressorWins, roundRunning.Aggressor.team, true)
                    
                echo("4 roundRunning.Aggressor.team, roundRunning, raidStates.AggressorWins")
                return roundRunning.Aggressor.team, roundRunning, raidStates.WaitingForUplink, true
            end

            -- Aggressor dead
            if roundRunning.Aggressor.Points <= 0 and
                roundRunning.Defender.Points > 0 then
                setPublicRaidState(raidIconId, raidStates.VictoryStateSet, raidResultStates.DefenderWins, roundRunning.Defender.team, true)
                echo( "5  roundRunning.Defender.team, roundRunning, raidStates.DefenderWins")
                return roundRunning.Defender.team, roundRunning, raidStates.VictoryStateSet, true
            end

            -- both died
            if roundRunning.Defender.Points <= 0 and
                roundRunning.Aggressor.Points <= 0 then
                setPublicRaidState(raidIconId, raidStates.Aborted, raidResultStates.DefenderWins, roundRunning.Defender.team, true)

                echo("6  nil, roundRunning, raidStates.Aborted")
                return  roundRunning.Defender.team, roundRunning, raidStates.Aborted, true
            end
        end

        echo("7  nil , roundRunning, raidStates.Ongoing")
        return nil, roundRunning, raidStates.OnGoing, false
    end

    function findEliminatedUnits(OriginalGraph, finalGraph)
        eliminatedUnits = {}
        if #finalGraph == 0 then return eliminatedUnits end

        for n = 1, #count(finalGraph) do
            v = finalGraph[n]
            eliminatedUnits[v.to] = true
        end

        return eliminatedUnits
    end

    function findSurvivors(roundRunning, eliminatedUnits)
        survivor = {} -- not the_Band
        for nr, id in pairs(roundRunning.Aggressor.PlacedFigures) do
            if eliminatedUnits[id] == nil then survivor[id] = id end
        end

        for nr, id in pairs(roundRunning.Defender.PlacedFigures) do
            if not eliminatedUnits[id] == nil then survivor[id] = id end
        end
        return survivor
    end

    function aiPlacementNeededForTeam(roundRunningTeam, teamID)
        if teamID == gaiaTeamID then
            return true
        end

        if count(roundRunningTeam.PlacedFigures) == 0 then
            echo(teamID .. " needs  aiplace")
            return true
        end
        if count(roundRunningTeam.PlacedFigures) > 0 then
            echo(teamID .. " needs no aiplace")
            return false
        end

        if roundRunningTeam.Points < 1 then
            echo(teamID .. " has no Points left")
            return false
        end

        nteamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier, customTeamKeys =
            Spring.GetTeamInfo(teamID)

        -- no teaminfo
        if isDead == nil or nTeamID == nil or isAiTeam == nil or side == nil then
            echo("No team info - ai placement")
            return true
        end

        if isDead == true then return false end

        if isAiTeam == true then return true end

        return false
    end

    function doAIPlacement(x, y, z, Team, roundRunning, boolDefender, raidIconID)
        -- for i = 1,  1 do
        tx, ty, tz = x + math.random(0, 50) * randSign(), y,
                     z + math.random(0, 50) * randSign()
        randDirs = math.random(1, 4)
        lastSniperIconID = spCreateUnit("snipeicon", tx, ty, tz, randDirs, Team)
        registersniperIconAttributes("snipeicon", Team, lastSniperIconID,
                                     raidIconID)
        if boolDefender == true then
            roundRunning.Defender.Points = roundRunning.Defender.Points - 1
        else
            roundRunning.Aggressor.Points = roundRunning.Aggressor.Points - 1
        end

        return roundRunning
    end

    function checkAIPlace(roundRunning, raidIconID)
        local aggTeam = roundRunning.Aggressor.team
        local defTeam = roundRunning.Defender.team
        x, y, z = spGetUnitPosition(raidIconID)

        if aiPlacementNeededForTeam(roundRunning.Aggressor, aggTeam) == true then
            roundRunning = doAIPlacement(x, y, z, aggTeam, roundRunning, false, raidIconID)
        end

        if aiPlacementNeededForTeam(roundRunning.Defender, defTeam) == true then
            roundRunning = doAIPlacement(x, y, z, defTeam, roundRunning, true, raidIconID)
        end
        return roundRunning
    end

    function setPublicRaidState(raidIconID, state, result, winningTeam, boolInterogationComplete)
        GG.raidStatus[raidIconID].state = state
        GG.raidStatus[raidIconID].result = result or raidResultStates.Unknown
        GG.raidStatus[raidIconID].winningTeam = winningTeam
        GG.raidStatus[raidIconID].boolInterogationComplete =  boolInterogationComplete or false
    end

    function checkRoundEnds()
        for raidIconId, roundRunning in pairs(allRunningRaidRounds) do
            if raidIconId and doesUnitExistAlive(raidIconId) == true then
                -- Round has ended
                raidPercentage = getIconProgress(raidIconId)
                boolSkip = false

                if raidPercentage > 50 and count(roundRunning.Objectives) == 0 then
                    RegisterObjective(raidIconId)
                end

                if (roundRunning and roundRunning.boolAIChecked == true and
                    raidPercentage >= 100 + postRoundTimeInSeconds) or
                    (roundRunning.Defender.Points <= 0 and
                        roundRunning.Aggressor.Points <= 0) then
                    -- find out who died, who survived, who collected objectives and if there is a new round
                    winningTeam, roundRunning, state, boolGameOver = evaluateEndedRound(raidIconId, roundRunning, raidIconId)
                    killAllPlacedObjects(roundRunning)

                    if roundRunning and state == raidStates.OnGoing or boolGameOver == false then
                        Spring.Echo("Raid continues in new Round") 
                        newRound(raidIconId, roundRunning.Aggressor.team, false, roundRunning)
                        roundRunning = nil
                    end

                    if roundRunning and state == raidStates.Aborted then
                        Spring.Echo("Raid was aborted")
                        allRunningRaidRounds[raidIconId] = nil
                        roundRunning = nil
                    end

                    if boolGameOver == true then
                      allRunningRaidRounds[raidIconId] = nil
                      roundRunning = nil
                    end                 
                    boolSkip = true
                end

                if roundRunning and boolSkip == false and
                    roundRunning.boolAIChecked == false and raidPercentage >= 90 then
                    -- check if a side was AI, if it was AI - do a random placement
                    allRunningRaidRounds[raidIconId] =
                        checkAIPlace(roundRunning, raidIconId)
                    roundRunning.boolAIChecked = true
                    for i = 1, #roundRunning.Defender.PlacedFigures do
                        alwaysShowUnit(roundRunning.Defender.PlacedFigures[i],
                                       roundRunning.Agressor.team)
                    end
                    for i = 1, #roundRunning.Aggressor.PlacedFigures do
                        alwaysShowUnit(roundRunning.Aggressor.PlacedFigures[i],
                                       roundRunning.Defender.team)
                    end
                    for i = 1, #roundRunning.Objectives do
                        alwaysShowUnit(roundRunning.Objectives[i])
                    end
                end
            else
                killAllPlacedObjects(roundRunning)
                allRunningRaidRounds[raidIconId] = nil
                Spring.Echo("Icon was killed")
            end
        end
    end

    function killAllPlacedObjects(roundRunning, delayMs)
        if not delayMs then delayMs = 0 end

        process(roundRunning.Defender.PlacedFigures,
                function(id) if id then spDestroyUnit(id, false, true) end; end)
        process(roundRunning.Aggressor.PlacedFigures,
                function(id) if id then spDestroyUnit(id, false, true) end; end)
        process(roundRunning.Objectives,
                function(id) if id then spDestroyUnit(id, false, true) end; end)
    end

    function registersniperIconAttributes(uType, teamID, lastSniperIconID,
                                          raidIconID)
        if string.lower(uType) == "snipeicon" then
            GG.DisplayedSniperIconParent[lastSniperIconID] = raidIconID
            GG.SniperIcon:Register(lastSniperIconID, teamID, raidIconID)
        end
    end

    function isNotEmptyHouse(houseID, raidIconID)
        return GG.houseHasSafeHouseTable and GG.houseHasSafeHouseTable[houseID] and doesUnitExistAlive(GG.houseHasSafeHouseTable[houseID])
    end

    GG.DisplayedSniperIconParent = {}
    local lastSniperIconID
    function gadget:RecvLuaMsg(msg, playerID)
        if msg and string.find(msg, "SPWN") then
  --          echo("game_snipe_minigame.lua: Recieved SPWN message")
            t = split(msg, "|")

            name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country, rank, _ =
                Spring.GetPlayerInfo(playerID)
            uType = t[2]
            local houseID = tonumber(t[6])
            if not GG.HouseRaidIconMap then  return end
            if not GG.HouseRaidIconMap[houseID] then return end
            raidIconID = GG.HouseRaidIconMap[houseID]

            if allRunningRaidRounds[raidIconID].Aggressor.team == teamID and
                allRunningRaidRounds[raidIconID].Aggressor.Points > 0 or
                (allRunningRaidRounds[raidIconID].Defender.team == teamID and
                allRunningRaidRounds[raidIconID].Defender.Points > 0 and
                isNotEmptyHouse(houseID, raidIconID) == true)
                then
                -- Spring.Echo("CreateUnit"..uType, tonumber(t[3]), tonumber(t[4]),  tonumber(t[5]),1, teamID)
                lastSniperIconID = spCreateUnit(uType, tonumber(t[3]),
                                                tonumber(t[4]), tonumber(t[5]),
                                                1, teamID)
                registersniperIconAttributes(uType, teamID, lastSniperIconID,
                                             raidIconID)
            end
        end

        if lastSniperIconID and doesUnitExistAlive(lastSniperIconID) == true then
            if lastSniperIconID and msg and string.find(msg, "ROTPOS") then
                t = split(msg, "|")
                Command(lastSniperIconID, "attack",
                        {tonumber(t[3]), tonumber(t[4]), tonumber(t[5])}, {})
            end

            if lastSniperIconID and msg and string.find(msg, "POSROT") then
                t = split(msg, "|")
                Command(lastSniperIconID, "attack",
                        {tonumber(t[3]), tonumber(t[4]), tonumber(t[5])}, {"shift"})
            end
        end
    end

    function gadget:GameFrame(frame)
        if frame % 30 == 0 then checkRoundEnds() end
    end
end -- gadgetend
