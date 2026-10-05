function gadget:GetInfo()
    return {
        name = "game Snipe Mini Game",
        desc = "Handles the raid/sniping minigame",
        author = "",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true
    }
end

if gadgetHandler:IsSyncedCode() then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    local raidIconDefID = UnitDefNames["icon_raid"].id
    local snipeIconDefID = UnitDefNames["snipeicon"].id
    local objectiveDefID = UnitDefNames["objectiveicon"].id

    local Aggressor = "Aggressor"
    local Defender = "Defender"
    local Neutral = "Neutral"

    local PhasePlacement = "Placement"
    local PhaseReveal = "Reveal"

    local objectiveProgress = 50
    local revealProgress = 85
    local resolutionProgress = 100
    local placementRadius = 220
    local aimRadius = 360

    local raidStates = getRaidStates()
    local raidResultStates = getRaidResultStates()
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)
    local GameConfig = getGameConfig()

    local spGetUnitPosition = Spring.GetUnitPosition
    local spCreateUnit = Spring.CreateUnit
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetUnitDefID = Spring.GetUnitDefID
    local spDestroyUnit = Spring.DestroyUnit
    local spCallAsUnit = Spring.UnitScript.CallAsUnit
    local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible

    local allRunningRaidRounds = {}
    local playerSniperIcons = {}

    local function tableCount(t)
        local n = 0
        if not t then return n end
        for _ in pairs(t) do n = n + 1 end
        return n
    end

    local function isFiniteNumber(value)
        return type(value) == "number" and value == value and
            value ~= math.huge and value ~= -math.huge
    end

    local function setUnitHidden(unitID)
        if not unitID or not doesUnitExistAlive(unitID) then return end
        spSetUnitAlwaysVisible(unitID, false)
        Spring.SetUnitStealth(unitID, true)
        Spring.SetUnitCloak(unitID, true, 4)
    end

    local function setUnitRevealed(unitID)
        if not unitID or not doesUnitExistAlive(unitID) then return end
        Spring.SetUnitStealth(unitID, false)
        Spring.SetUnitCloak(unitID, false, 1)
        spSetUnitAlwaysVisible(unitID, true)
    end

    local function setPublicRaidState(raidIconID, state, result, winningTeam, boolInterrogationComplete)
        GG.raidStatus = GG.raidStatus or {}
        GG.raidStatus[raidIconID] = GG.raidStatus[raidIconID] or {}

        local status = GG.raidStatus[raidIconID]
        status.state = state
        status.result = result or raidResultStates.Unknown
        status.winningTeam = winningTeam
        status.boolInterogationComplete = boolInterrogationComplete == true
        if state == raidStates.OnGoing then
            status.boolAnimationComplete = false
        end
    end

    local function getRaidHouseID(raidIconID)
        if not GG.HouseRaidIconMap then return nil end
        for houseID, iconID in pairs(GG.HouseRaidIconMap) do
            if iconID == raidIconID then
                return houseID
            end
        end
        return nil
    end

    -- nil means that the house/safehouse maps are not ready yet.
    local function isHouseEmptyForRaid(raidIconID)
        if not GG.HouseRaidIconMap or not GG.houseHasSafeHouseTable then
            return nil
        end

        local houseID = getRaidHouseID(raidIconID)
        if not houseID then return nil end

        local safeHouseID = GG.houseHasSafeHouseTable[houseID]
        if not safeHouseID then return true, houseID end
        return not doesUnitExistAlive(safeHouseID), houseID
    end

    local function getDefenderTeam(raidIconID, attackerTeam, oldDefenderTeam)
        if oldDefenderTeam ~= nil then return oldDefenderTeam end

        local attackerAllyTeam = Spring.GetUnitAllyTeam(raidIconID)
        local plausibleDefenderTeams = {}

        foreach(getAllNearUnit(raidIconID, 100), function(id)
            if not id then return end

            local defID = spGetUnitDefID(id)
            local teamID = spGetUnitTeam(id)
            local allyTeamID = Spring.GetUnitAllyTeam(id)
            if safeHouseTypeTable[defID] and
                teamID ~= attackerTeam and
                teamID ~= gaiaTeamID and
                attackerAllyTeam ~= allyTeamID then
                plausibleDefenderTeams[#plausibleDefenderTeams + 1] = teamID
            end
        end)

        if #plausibleDefenderTeams == 1 then
            return plausibleDefenderTeams[1]
        elseif #plausibleDefenderTeams > 1 then
            return plausibleDefenderTeams[math.random(1, #plausibleDefenderTeams)]
        end

        local teamList = Spring.GetTeamList()
        for i = 1, #teamList do
            if teamList[i] ~= gaiaTeamID and teamList[i] ~= attackerTeam then
                return teamList[i]
            end
        end

        return gaiaTeamID
    end

    local function getIconProgress(raidIconID)
        local env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.getRoundProgressBar then
            return spCallAsUnit(raidIconID, env.getRoundProgressBar) or 0
        end
        return 0
    end

    local function setRaidIconProgress(raidIconID, value)
        local env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.setRoundProgressBar then
            return spCallAsUnit(raidIconID, env.setRoundProgressBar, value)
        end
        return false
    end

    local function updatePointData(raidIconID, roundRunning)
        local env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.updateShownPoints then
            spCallAsUnit(
                raidIconID,
                env.updateShownPoints,
                roundRunning.Aggressor.Points,
                roundRunning.Defender.Points
            )
        end
    end

    local function registerPlaceUnit(raidIconID, unitID, roundRunning)
        if not unitID then return false end

        local env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.registerPlaceUnit then
            spCallAsUnit(
                raidIconID,
                env.registerPlaceUnit,
                unitID,
                spGetUnitDefID(unitID) == objectiveDefID
            )
            updatePointData(raidIconID, roundRunning)
            return true
        end
        return false
    end

    local function newRound(raidIconID, attackerTeam, boolGameStart, oldRound)
        setRaidIconProgress(raidIconID, 0)

        local defenderTeam = getDefenderTeam(
            raidIconID,
            attackerTeam,
            oldRound and oldRound.Defender and oldRound.Defender.team
        )

        local round = {
            roundNumber = oldRound and ((oldRound.roundNumber or 1) + 1) or 1,
            phase = PhasePlacement,
            boolAIChecked = false, -- compatibility with the old state data
            revealDone = false,
            objectiveSpawned = false,
            emptyHouseFirstRound = false,
            citizenSpawnAttempted = false,
            Objectives = {},
            NeutralFigures = {},
            Aggressor = {
                team = attackerTeam,
                Points = GameConfig.espionage.sniping.aggressorStartPoints,
                PlacedFigures = {}
            },
            Defender = {
                team = defenderTeam,
                Points = GameConfig.espionage.sniping.defenderStartPoints,
                PlacedFigures = {}
            }
        }

        if boolGameStart == false and oldRound then
            round.Defender.Points = oldRound.Defender.Points
            round.Defender.team = oldRound.Defender.team
            round.Aggressor.Points = oldRound.Aggressor.Points
            round.Aggressor.team = oldRound.Aggressor.team
        end

        allRunningRaidRounds[raidIconID] = round
        setPublicRaidState(
            raidIconID,
            raidStates.OnGoing,
            raidResultStates.Unknown,
            nil,
            false
        )
        updatePointData(raidIconID, round)
        return round
    end

    local function getRoundSideForTeam(roundRunning, teamID)
        if teamID == roundRunning.Aggressor.team then return Aggressor end
        if teamID == roundRunning.Defender.team then return Defender end
        return nil
    end

    local function registerSniperIcon(self, unitID, unitTeam, raidIconID)
        if type(unitID) ~= "number" or type(raidIconID) ~= "number" then
            return false
        end

        local roundRunning = allRunningRaidRounds[raidIconID]
        if not roundRunning or roundRunning.phase ~= PhasePlacement then
            if doesUnitExistAlive(unitID) then spDestroyUnit(unitID, false, true) end
            return false
        end

        local actualTeam = spGetUnitTeam(unitID)
        local teamSelected = getRoundSideForTeam(roundRunning, actualTeam)
        if not teamSelected then
            if doesUnitExistAlive(unitID) then spDestroyUnit(unitID, false, true) end
            return false
        end

        local side = roundRunning[teamSelected]
        if side.Points <= 0 then
            if GG.UnitsToKill and GG.UnitsToKill.PushKillUnit then
                GG.UnitsToKill:PushKillUnit(unitID)
            elseif doesUnitExistAlive(unitID) then
                spDestroyUnit(unitID, false, true)
            end
            return false
        end

        side.PlacedFigures[unitID] = unitID
        side.Points = side.Points - 1
        registerPlaceUnit(raidIconID, unitID, roundRunning)
        return true
    end

    local function registerSniperIconAttributes(unitID, raidIconID)
        if not unitID or not raidIconID then return false end
        GG.DisplayedSniperIconParent[unitID] = raidIconID
        return GG.SniperIcon:Register(
            unitID,
            spGetUnitTeam(unitID),
            raidIconID
        )
    end

    local function registerObjective(raidIconID)
        local roundRunning = allRunningRaidRounds[raidIconID]
        if not roundRunning then return nil end

        local x, y, z = spGetUnitPosition(raidIconID)
        if not x then return nil end

        local tx = x + math.random(0, 50) * randSign()
        local tz = z + math.random(0, 50) * randSign()
        local objectiveIcon = spCreateUnit(
            "objectiveicon",
            tx, y, tz,
            math.random(0, 3),
            gaiaTeamID
        )
        if not objectiveIcon then return nil end

        spSetUnitAlwaysVisible(objectiveIcon, true)
        roundRunning.Objectives[objectiveIcon] = objectiveIcon
        roundRunning.objectiveSpawned = true
        registerPlaceUnit(raidIconID, objectiveIcon, roundRunning)
        return objectiveIcon
    end

    local function getUnitsInTriangle(unitID)
        local env = Spring.UnitScript.GetScriptEnv(unitID)
        if env and env.getUnitsInTriangle then
            return spCallAsUnit(unitID, env.getUnitsInTriangle) or {}
        end
        return {}
    end

    local function hasClearShot(raidIconID, shooterID, targetID)
        local env = Spring.UnitScript.GetScriptEnv(raidIconID)
        if env and env.testTwoUnits then
            return spCallAsUnit(
                raidIconID,
                env.testTwoUnits,
                shooterID,
                targetID
            ) == true
        end
        return true
    end

    local function rolesHostile(shooterRole, targetRole)
        if shooterRole == Aggressor then
            return targetRole == Defender or targetRole == Neutral
        elseif shooterRole == Defender then
            return targetRole == Aggressor
        elseif shooterRole == Neutral then
            return targetRole == Aggressor
        end
        return false
    end

    local function buildParticipantRoleMap(roundRunning)
        local roles = {}

        for _, unitID in pairs(roundRunning.Aggressor.PlacedFigures) do
            if doesUnitExistAlive(unitID) then roles[unitID] = Aggressor end
        end
        for _, unitID in pairs(roundRunning.Defender.PlacedFigures) do
            if doesUnitExistAlive(unitID) then roles[unitID] = Defender end
        end
        for _, unitID in pairs(roundRunning.NeutralFigures) do
            if doesUnitExistAlive(unitID) then roles[unitID] = Neutral end
        end

        return roles
    end

    -- A raid volley is simultaneous. A shooter that is also hit still gets the
    -- shot that was lined up at resolution time.
    local function resolveVolley(raidIconID, roundRunning)
        local participantRoles = buildParticipantRoleMap(roundRunning)
        local dead = {}

        for shooterID, shooterRole in pairs(participantRoles) do
            local targets = getUnitsInTriangle(shooterID)
            for _, targetID in pairs(targets) do
                local targetRole = participantRoles[targetID]
                if targetRole and
                    targetID ~= shooterID and
                    rolesHostile(shooterRole, targetRole) and
                    hasClearShot(raidIconID, shooterID, targetID) then
                    dead[targetID] = targetID
                end
            end
        end

        for unitID in pairs(dead) do
            if doesUnitExistAlive(unitID) then
                spawnCegAtUnit(unitID, "iconkill")
            end
        end

        return dead, participantRoles
    end

    local function findSurvivors(participantRoles, dead)
        local survivors = {
            [Aggressor] = {},
            [Defender] = {},
            [Neutral] = {}
        }

        for unitID, role in pairs(participantRoles) do
            if not dead[unitID] then
                survivors[role][unitID] = unitID
            end
        end
        return survivors
    end

    local function awardKillPoints(roundRunning, dead, participantRoles)
        for unitID in pairs(dead) do
            local role = participantRoles[unitID]
            if role == Aggressor then
                roundRunning.Defender.Points = roundRunning.Defender.Points + 1
            elseif role == Defender then
                roundRunning.Aggressor.Points = roundRunning.Aggressor.Points + 1
            end
            -- The armed citizen is a neutral hazard: killing it yields no point.
        end
    end

    local function scoreObjectives(roundRunning, survivors)
        for _, objectiveID in pairs(roundRunning.Objectives) do
            if doesUnitExistAlive(objectiveID) then
                for _, unitID in pairs(survivors[Aggressor]) do
                    if doesUnitExistAlive(unitID) and
                        distanceUnitToUnit(objectiveID, unitID) < 5 then
                        roundRunning.Aggressor.Points =
                            roundRunning.Aggressor.Points + 2
                    end
                end
                for _, unitID in pairs(survivors[Defender]) do
                    if doesUnitExistAlive(unitID) and
                        distanceUnitToUnit(objectiveID, unitID) < 5 then
                        roundRunning.Defender.Points =
                            roundRunning.Defender.Points + 2
                    end
                end
            end
        end
    end

    local function finishRound(
        raidIconID,
        winningTeam,
        roundRunning,
        publicState,
        result
    )
        setPublicRaidState(
            raidIconID,
            publicState,
            result,
            winningTeam,
            true
        )
        return winningTeam, roundRunning, publicState, true
    end

    local function evaluateEndedRound(raidIconID, roundRunning)
        local houseEmpty = isHouseEmptyForRaid(raidIconID)

        -- If a populated safehouse disappears after the first-round citizen
        -- decision, the raid has nothing left to discover.
        if houseEmpty == true and
            not roundRunning.emptyHouseFirstRound then
            return finishRound(
                raidIconID,
                nil,
                roundRunning,
                raidStates.VictoryStateSet,
                raidResultStates.HouseEmpty
            )
        end

        local aggressorPlaced = tableCount(roundRunning.Aggressor.PlacedFigures)
        local defenderPlaced = tableCount(roundRunning.Defender.PlacedFigures)
        local neutralPlaced = tableCount(roundRunning.NeutralFigures)

        if aggressorPlaced == 0 and defenderPlaced == 0 and neutralPlaced == 0 then
            return finishRound(
                raidIconID,
                nil,
                roundRunning,
                raidStates.Aborted,
                raidResultStates.Unknown
            )
        end

        -- An empty house with the hidden citizen must resolve its volley before
        -- any "one side did not play" shortcut is applied.
        if not roundRunning.emptyHouseFirstRound then
            if defenderPlaced == 0 and aggressorPlaced > 0 then
                return finishRound(
                    raidIconID,
                    roundRunning.Aggressor.team,
                    roundRunning,
                    raidStates.WaitingForUplink,
                    raidResultStates.AggressorWins
                )
            elseif aggressorPlaced == 0 and defenderPlaced > 0 then
                return finishRound(
                    raidIconID,
                    roundRunning.Defender.team,
                    roundRunning,
                    raidStates.WaitingForUplink,
                    raidResultStates.DefenderWins
                )
            end
        elseif aggressorPlaced == 0 then
            return finishRound(
                raidIconID,
                nil,
                roundRunning,
                raidStates.Aborted,
                raidResultStates.Unknown
            )
        end

        local dead, participantRoles = resolveVolley(raidIconID, roundRunning)
        local survivors = findSurvivors(participantRoles, dead)

        awardKillPoints(roundRunning, dead, participantRoles)
        scoreObjectives(roundRunning, survivors)
        updatePointData(raidIconID, roundRunning)

        if roundRunning.emptyHouseFirstRound then
            if tableCount(survivors[Aggressor]) == 0 then
                return finishRound(
                    raidIconID,
                    gaiaTeamID,
                    roundRunning,
                    raidStates.WaitingForUplink,
                    raidResultStates.DefenderWins
                )
            end

            return finishRound(
                raidIconID,
                nil,
                roundRunning,
                raidStates.VictoryStateSet,
                raidResultStates.HouseEmpty
            )
        end

        if roundRunning.Defender.Points <= 0 or
            roundRunning.Aggressor.Points <= 0 then

            if roundRunning.Defender.Points <= 0 and
                roundRunning.Aggressor.Points > 0 then
                return finishRound(
                    raidIconID,
                    roundRunning.Aggressor.team,
                    roundRunning,
                    raidStates.WaitingForUplink,
                    raidResultStates.AggressorWins
                )
            elseif roundRunning.Aggressor.Points <= 0 and
                roundRunning.Defender.Points > 0 then
                return finishRound(
                    raidIconID,
                    roundRunning.Defender.team,
                    roundRunning,
                    raidStates.WaitingForUplink,
                    raidResultStates.DefenderWins
                )
            else
                return finishRound(
                    raidIconID,
                    nil,
                    roundRunning,
                    raidStates.Aborted,
                    raidResultStates.Unknown
                )
            end
        end

        return nil, roundRunning, raidStates.OnGoing, false
    end

    local function teamNeedsFallbackPlacement(roundTeam, teamID)
        if roundTeam.Points < 1 or tableCount(roundTeam.PlacedFigures) > 0 then
            return false
        end

        if teamID == gaiaTeamID then return true end

        local nTeamID, _, isDead, isAiTeam =
            Spring.GetTeamInfo(teamID)
        if nTeamID == nil or isDead == nil or isAiTeam == nil then
            return true
        end
        if isDead then return false end

        -- Keep the old anti-AFK behaviour deliberately: an AI team or a human
        -- team that placed nothing receives one random fallback figure.
        return true
    end

    local function doFallbackPlacement(
        raidIconID,
        teamID
    )
        local x, y, z = spGetUnitPosition(raidIconID)
        if not x then return nil end

        local unitID = spCreateUnit(
            "snipeicon",
            x + math.random(0, 50) * randSign(),
            y,
            z + math.random(0, 50) * randSign(),
            math.random(0, 3),
            teamID
        )
        if not unitID then return nil end

        if not registerSniperIconAttributes(unitID, raidIconID) then
            return nil
        end
        return unitID
    end

    local function aimHiddenCitizen(roundRunning, raidIconID)
        local citizenID
        for _, unitID in pairs(roundRunning.NeutralFigures) do
            if doesUnitExistAlive(unitID) then
                citizenID = unitID
                break
            end
        end
        if not citizenID then return end

        local targets = {}
        for _, unitID in pairs(roundRunning.Aggressor.PlacedFigures) do
            if doesUnitExistAlive(unitID) then
                targets[#targets + 1] = unitID
            end
        end

        local targetID = #targets > 0 and
            targets[math.random(1, #targets)] or nil
        if targetID and math.random() < 0.7 then
            local tx, ty, tz = spGetUnitPosition(targetID)
            if tx then
                Command(
                    citizenID,
                    "attack",
                    {
                        tx + math.random(-22, 22),
                        ty,
                        tz + math.random(-22, 22)
                    },
                    {}
                )
                return
            end
        end

        local x, y, z = spGetUnitPosition(raidIconID)
        if x then
            Command(
                citizenID,
                "attack",
                {
                    x + math.random(35, 90) * randSign(),
                    y,
                    z + math.random(35, 90) * randSign()
                },
                {}
            )
        end
    end

    local function ensureFirstRoundCitizen(roundRunning, raidIconID)
        if roundRunning.roundNumber ~= 1 or
            roundRunning.citizenSpawnAttempted then
            return
        end

        local houseEmpty = isHouseEmptyForRaid(raidIconID)
        if houseEmpty == nil or houseEmpty == false then return end

        roundRunning.emptyHouseFirstRound = true
        roundRunning.citizenSpawnAttempted = true

        local x, y, z = spGetUnitPosition(raidIconID)
        if not x then return end

        local citizenID = spCreateUnit(
            "snipeicon",
            x + math.random(18, 55) * randSign(),
            y,
            z + math.random(18, 55) * randSign(),
            math.random(0, 3),
            gaiaTeamID
        )
        if not citizenID then return end

        GG.DisplayedSniperIconParent[citizenID] = raidIconID
        roundRunning.NeutralFigures[citizenID] = citizenID
        registerPlaceUnit(raidIconID, citizenID, roundRunning)

        Spring.SetUnitNeutral(citizenID, true)
        Spring.SetUnitNoSelect(citizenID, true)
        setUnitHidden(citizenID)
        aimHiddenCitizen(roundRunning, raidIconID)
    end

    local function revealRound(roundRunning, raidIconID)
        if roundRunning.revealDone then return end

        ensureFirstRoundCitizen(roundRunning, raidIconID)

        if teamNeedsFallbackPlacement(
            roundRunning.Aggressor,
            roundRunning.Aggressor.team
        ) then
            doFallbackPlacement(
                raidIconID,
                roundRunning.Aggressor.team
            )
        end

        if not roundRunning.emptyHouseFirstRound and
            teamNeedsFallbackPlacement(
                roundRunning.Defender,
                roundRunning.Defender.team
            ) then
            doFallbackPlacement(
                raidIconID,
                roundRunning.Defender.team
            )
        end

        aimHiddenCitizen(roundRunning, raidIconID)

        for _, unitID in pairs(roundRunning.Defender.PlacedFigures) do
            setUnitRevealed(unitID)
        end
        for _, unitID in pairs(roundRunning.Aggressor.PlacedFigures) do
            setUnitRevealed(unitID)
        end
        for _, unitID in pairs(roundRunning.Objectives) do
            setUnitRevealed(unitID)
        end
        -- NeutralFigures deliberately remain hidden.

        roundRunning.boolAIChecked = true
        roundRunning.revealDone = true
        roundRunning.phase = PhaseReveal
    end

    local function killAllPlacedObjects(roundRunning)
        if not roundRunning then return end

        local function killTable(t)
            for _, unitID in pairs(t or {}) do
                if unitID then
                    GG.DisplayedSniperIconParent[unitID] = nil
                    if doesUnitExistAlive(unitID) then
                        spDestroyUnit(unitID, false, true)
                    end
                end
            end
        end

        killTable(roundRunning.Defender.PlacedFigures)
        killTable(roundRunning.Aggressor.PlacedFigures)
        killTable(roundRunning.NeutralFigures)
        killTable(roundRunning.Objectives)
    end

    local function checkRoundEnds()
        for raidIconID, roundRunning in pairs(allRunningRaidRounds) do
            if raidIconID and doesUnitExistAlive(raidIconID) then
                ensureFirstRoundCitizen(roundRunning, raidIconID)

                local raidPercentage = getIconProgress(raidIconID)

                if raidPercentage >= objectiveProgress and
                    not roundRunning.objectiveSpawned and
                    not roundRunning.emptyHouseFirstRound then
                    registerObjective(raidIconID)
                end

                if raidPercentage >= revealProgress and
                    not roundRunning.revealDone then
                    revealRound(roundRunning, raidIconID)
                end

                if raidPercentage >= resolutionProgress then
                    local _, evaluatedRound, state, boolGameOver =
                        evaluateEndedRound(raidIconID, roundRunning)

                    killAllPlacedObjects(evaluatedRound)

                    if boolGameOver then
                        allRunningRaidRounds[raidIconID] = nil
                    elseif state == raidStates.OnGoing then
                        newRound(
                            raidIconID,
                            evaluatedRound.Aggressor.team,
                            false,
                            evaluatedRound
                        )
                    else
                        -- Defensive fallback: a terminal state must never keep a
                        -- stale round alive.
                        allRunningRaidRounds[raidIconID] = nil
                    end
                end
            else
                killAllPlacedObjects(roundRunning)
                allRunningRaidRounds[raidIconID] = nil
            end
        end
    end

    local function validPositionNearRaid(raidIconID, x, y, z, radius)
        if not (isFiniteNumber(x) and isFiniteNumber(y) and isFiniteNumber(z)) then
            return false
        end

        local rx, _, rz = spGetUnitPosition(raidIconID)
        if not rx then return false end

        local dx, dz = x - rx, z - rz
        return dx * dx + dz * dz <= radius * radius
    end

    local function cleanupPlayerIconReference(unitID)
        for playerID, data in pairs(playerSniperIcons) do
            if data.unitID == unitID then
                playerSniperIcons[playerID] = nil
            end
        end
    end

    function gadget:Initialize()
        GG.raidStatus = GG.raidStatus or {}
        GG.myParent = GG.myParent or {}
        GG.DisplayedSniperIconParent = GG.DisplayedSniperIconParent or {}

        if GG.SniperIcon == nil then
            GG.SniperIcon = { Register = registerSniperIcon }
        else
            GG.SniperIcon.Register = registerSniperIcon
        end
    end

    function gadget:UnitCreated(unitID, unitDefID, unitTeam)
        if unitDefID == raidIconDefID then
            GG.raidStatus[unitID] = GG.raidStatus[unitID] or {}
            newRound(unitID, unitTeam, true)
        elseif unitDefID == snipeIconDefID then
            -- The old code accidentally passed the UnitDef ID here.
            setUnitHidden(unitID)
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if unitDefID == snipeIconDefID then
            GG.DisplayedSniperIconParent[unitID] = nil
            cleanupPlayerIconReference(unitID)
            for _, roundRunning in pairs(allRunningRaidRounds) do
                roundRunning.Aggressor.PlacedFigures[unitID] = nil
                roundRunning.Defender.PlacedFigures[unitID] = nil
                roundRunning.NeutralFigures[unitID] = nil
            end
        elseif unitDefID == raidIconDefID then
            local roundRunning = allRunningRaidRounds[unitID]
            if roundRunning then
                killAllPlacedObjects(roundRunning)
                allRunningRaidRounds[unitID] = nil
            end
        end
    end

    function gadget:RecvLuaMsg(msg, playerID)
        if type(msg) ~= "string" then return end

        if string.sub(msg, 1, 9) == "LOCATION:" then
            local location = split(msg, "|")
            GG.Location = {
                region = location[2],
                country = location[3],
                province = location[4],
                cityname = location[5],
                citypart = location[6]
            }
            return
        end

        local playerName, active, spectator, teamID =
            Spring.GetPlayerInfo(playerID)
        if not playerName or not active or spectator or not teamID then return end

        if string.sub(msg, 1, 5) == "SPWN|" then
            local t = split(msg, "|")
            if t[2] ~= "snipeicon" then return end

            local x = tonumber(t[3])
            local y = tonumber(t[4])
            local z = tonumber(t[5])
            local houseID = tonumber(t[6])
            if not houseID or not GG.HouseRaidIconMap then return end

            local raidIconID = GG.HouseRaidIconMap[houseID]
            local roundRunning = raidIconID and allRunningRaidRounds[raidIconID]
            if not roundRunning or
                roundRunning.phase ~= PhasePlacement or
                getIconProgress(raidIconID) >= revealProgress then
                return
            end

            local sideName = getRoundSideForTeam(roundRunning, teamID)
            if not sideName then return end

            local houseEmpty = isHouseEmptyForRaid(raidIconID)
            if sideName == Defender and houseEmpty == true then
                return
            end

            if roundRunning[sideName].Points <= 0 then return end
            if not validPositionNearRaid(
                raidIconID,
                x, y, z,
                placementRadius
            ) then
                return
            end

            local unitID = spCreateUnit(
                "snipeicon",
                x, y, z,
                1,
                teamID
            )
            if not unitID then return end

            if registerSniperIconAttributes(unitID, raidIconID) then
                playerSniperIcons[playerID] = {
                    unitID = unitID,
                    raidIconID = raidIconID
                }
            end
            return
        end

        if string.sub(msg, 1, 7) == "ROTPOS|" or
            string.sub(msg, 1, 7) == "POSROT|" then

            local selected = playerSniperIcons[playerID]
            if not selected or
                not doesUnitExistAlive(selected.unitID) then
                playerSniperIcons[playerID] = nil
                return
            end

            local roundRunning =
                allRunningRaidRounds[selected.raidIconID]
            if not roundRunning or
                roundRunning.phase ~= PhasePlacement then
                playerSniperIcons[playerID] = nil
                return
            end

            if spGetUnitTeam(selected.unitID) ~= teamID then
                playerSniperIcons[playerID] = nil
                return
            end

            local t = split(msg, "|")
            local x = tonumber(t[3])
            local y = tonumber(t[4])
            local z = tonumber(t[5])
            if not validPositionNearRaid(
                selected.raidIconID,
                x, y, z,
                aimRadius
            ) then
                return
            end

            Command(
                selected.unitID,
                "attack",
                { x, y, z },
                string.sub(msg, 1, 7) == "POSROT|" and {"shift"} or {}
            )

            if string.sub(msg, 1, 7) == "POSROT|" then
                playerSniperIcons[playerID] = nil
            end
        end
    end

    function gadget:GameFrame(frame)
        if frame % 30 == 0 then
            checkRoundEnds()
        end
    end
end
