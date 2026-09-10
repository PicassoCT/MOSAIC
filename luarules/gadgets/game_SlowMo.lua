function gadget:GetInfo()
    return {
        name = "Slowmotion gadget",
        desc = "Coordinates temporal dilation for Hiveminds and AI-Cores",
        author = "PicassoCT",
        date = "September 2026",
        license = "GNU GPL, v2 or later",
        layer = 0,
        version = 2,
        enabled = true
    }
end

if gadgetHandler:IsSyncedCode() then
    local TARGET_SLOWMO_SPEED = 0.40
    local DRAIN_INTERVAL_FRAMES = 3
    local DRAIN_MS = 100

    local slowMoActive = false
    local activeTeams = {}
    local activeTeamSignature = ""
    local reportedWantedSpeed = 1.0
    local reportedActualSpeed = 1.0
    local savedGameSpeed = 1.0

    local function isTemporalNodeData(data)
        return type(data) == "table"
            and data.rewindMilliSeconds ~= nil
            and data.boolActive ~= nil
    end

    local function getSelectedNode(uTab, requireActive)
        local selectedUnit
        local selectedData

        for unitID, data in pairs(uTab or {}) do
            if isTemporalNodeData(data)
                and (data.rewindMilliSeconds or 0) > 0
                and ((not requireActive) or data.boolActive == true)
            then
                if selectedUnit == nil or unitID < selectedUnit then
                    selectedUnit = unitID
                    selectedData = data
                end
            end
        end

        return selectedUnit, selectedData
    end

    local function anySlowMoRequested()
        if not GG.HiveMind then
            return false
        end

        for _, uTab in pairs(GG.HiveMind) do
            local _, data = getSelectedNode(uTab, true)
            if data then
                return true
            end
        end

        return false
    end

    local function activateChargedTeams()
        if not GG.HiveMind then
            GG.HiveMind = {}
            return
        end

        for _, uTab in pairs(GG.HiveMind) do
            if type(uTab) == "table" then
                local selectedUnit, selectedData = getSelectedNode(uTab, true)
                if not selectedData then
                    selectedUnit, selectedData = getSelectedNode(uTab, false)
                end

                for unitID, data in pairs(uTab) do
                    if isTemporalNodeData(data) then
                        data.boolActive = selectedData ~= nil and unitID == selectedUnit
                    end
                end
            end
        end
    end

    local function rebuildActiveTeams()
        local teams = {}
        local keys = {}

        if GG.HiveMind then
            for teamID, uTab in pairs(GG.HiveMind) do
                local _, data = getSelectedNode(uTab, true)
                if data then
                    teams[teamID] = true
                    keys[#keys + 1] = tostring(teamID)
                end
            end
        end

        table.sort(keys)
        return teams, table.concat(keys, ",")
    end

    local function sendSlowMoState()
        SendToUnsynced(
            "setSlowMoState",
            slowMoActive,
            activeTeams,
            TARGET_SLOWMO_SPEED
        )
    end

    local function enterSlowMo()
        activateChargedTeams()
        activeTeams, activeTeamSignature = rebuildActiveTeams()

        if next(activeTeams) == nil then
            return
        end

        savedGameSpeed = tonumber(reportedWantedSpeed) or 1.0
        if savedGameSpeed <= 0 then
            savedGameSpeed = 1.0
        end

        slowMoActive = true
        GG.GameSpeed = reportedActualSpeed
        Spring.SetGameRulesParam("slowMoActive", 1)
        Spring.SetGameRulesParam("slowMoTargetSpeed", TARGET_SLOWMO_SPEED)

        Spring.SendCommands("setSpeed " .. TARGET_SLOWMO_SPEED)
        Spring.PlaySoundFile("sounds/HiveMind/StartLoop.ogg", 1.0)
        sendSlowMoState()
    end

    local function stopAllTemporalNodes()
        if not GG.HiveMind then
            return
        end

        for _, uTab in pairs(GG.HiveMind) do
            if type(uTab) == "table" then
                for _, data in pairs(uTab) do
                    if isTemporalNodeData(data) then
                        data.boolActive = false
                    end
                end
            end
        end
    end

    local function leaveSlowMo()
        slowMoActive = false
        activeTeams = {}
        activeTeamSignature = ""

        stopAllTemporalNodes()

        Spring.SetGameRulesParam("slowMoActive", 0)
        Spring.SetGameRulesParam("slowMoTargetSpeed", TARGET_SLOWMO_SPEED)
        Spring.SendCommands("setSpeed " .. savedGameSpeed)
        Spring.PlaySoundFile("sounds/HiveMind/EndLoop.ogg", 1.0)
        sendSlowMoState()
    end

    local function drainTemporalCharge()
        if not GG.HiveMind then
            return
        end

        for _, uTab in pairs(GG.HiveMind) do
            local selectedUnit, data = getSelectedNode(uTab, true)
            if selectedUnit and data then
                data.rewindMilliSeconds = math.max(
                    0,
                    (data.rewindMilliSeconds or 0) - DRAIN_MS
                )

                if data.rewindMilliSeconds <= 0 then
                    data.boolActive = false
                end
            end
        end
    end

    function gadget:Initialize()
        if not GG.HiveMind then
            GG.HiveMind = {}
        end

        GG.GameSpeed = 1.0
        Spring.SetGameRulesParam("slowMoActive", 0)
        Spring.SetGameRulesParam("slowMoTargetSpeed", TARGET_SLOWMO_SPEED)
        sendSlowMoState()
    end

    function gadget:GameFrame(frame)
        if not slowMoActive then
            if anySlowMoRequested() then
                enterSlowMo()
            end
            return
        end

        if frame % DRAIN_INTERVAL_FRAMES == 0 then
            drainTemporalCharge()
        end

        local newActiveTeams, newSignature = rebuildActiveTeams()
        activeTeams = newActiveTeams

        if next(activeTeams) == nil then
            leaveSlowMo()
            return
        end

        if newSignature ~= activeTeamSignature then
            activeTeamSignature = newSignature
            sendSlowMoState()
        end
    end

    function gadget:AllowCommand(
        unitID,
        unitDefID,
        unitTeam,
        cmdID,
        cmdParams,
        cmdOptions,
        cmdTag,
        arg8,
        arg9,
        arg10
    )
        if not slowMoActive or activeTeams[unitTeam] then
            return true
        end

        -- Recoil has had both AllowCommand signatures in circulation:
        -- (..., cmdTag, synced, fromLua)
        -- (..., cmdTag, playerID, fromSynced, fromLua)
        local fromSynced
        local fromLua

        if arg10 ~= nil then
            fromSynced = arg9
            fromLua = arg10
        else
            fromSynced = arg8
            fromLua = arg9
        end

        -- Internal Lua/synced orders keep running. Player-issued orders from
        -- teams outside the temporal field are rejected while time is dilated.
        if fromLua == true or fromSynced == true then
            return true
        end

        return false
    end

    function gadget:RecvLuaMsg(msg, playerID)
        local wanted, actual = string.match(
            msg,
            "^CurrentGameSpeed:([%d%.%-]+):([%d%.%-]+)$"
        )

        if wanted then
            reportedWantedSpeed = tonumber(wanted) or reportedWantedSpeed
            reportedActualSpeed = tonumber(actual) or reportedActualSpeed
            GG.GameSpeed = reportedActualSpeed
        end
    end

else
    local reportTimer = 0

    local function setSlowMoState(_, active, teams, targetSpeed)
        local myTeamID = Spring.GetMyTeamID()
        local privileged = active == true
            and type(teams) == "table"
            and teams[myTeamID] == true

        Spring.SendLuaUIMsg(
            string.format(
                "SlowMoShader|%d|%d|%.3f",
                active and 1 or 0,
                privileged and 1 or 0,
                targetSpeed or 0.40
            ),
            "a"
        )
    end

    local function reportGameSpeed()
        local wantedSpeed, actualSpeed = Spring.GetGameSpeed()
        if not wantedSpeed or not actualSpeed then
            return
        end

        Spring.SendLuaRulesMsg(
            string.format(
                "CurrentGameSpeed:%.4f:%.4f",
                wantedSpeed,
                actualSpeed
            )
        )
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("setSlowMoState", setSlowMoState)
        reportGameSpeed()
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("setSlowMoState")
    end

    function gadget:Update(dt)
        reportTimer = reportTimer + dt
        if reportTimer >= 0.25 then
            reportTimer = 0
            reportGameSpeed()
        end
    end
end
