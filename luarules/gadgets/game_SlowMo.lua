function gadget:GetInfo()
    return {
        name = "Slowmotion gadget",
        desc = "This gadget coordinates gamespeed sets by hiveMinds and AI-Cores",
        author = "PicassoCT",
        date = "Juli. 2017",
        license = "GNU GPL, v2 or later",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_UnitScript.lua")

    local boolPreviouslyActive = false
    function detectRisingEdge(boolValue)
        boolResult = false
        if boolPreviouslyActive == false and boolValue == true then
            boolResult = true
        end
        
        boolPreviouslyActive = boolValue
        return boolResult
    end
    
    local boolPreviouslyActiveV2 = false
    function detectFallingEdge(boolValue)
        boolResult = false
        if boolPreviouslyActiveV2 == true and boolValue == false then
            boolResult = true
        end
        
        boolPreviouslyActiveV2 = boolValue
        return boolResult
    end

    local startFrame = -2
    local endFrame = -1
    local InitialFrame = Spring.GetGameFrame()
 
    function gadget:Initialize()
        if not GG.HiveMind then GG.HiveMind = {} end
        SendToUnsynced("Initialize")
        InitialFrame = Spring.GetGameFrame()
        GG.GameSpeed = 1.0
    end

    function gadget:GameFrame(n)      

        if frame == InitialFrame then 
            SendToUnsynced("setSlowMoShaderActive", false) 
            return
        end

        handleSlowMoStateMachine(n)
    end

    -- check for active HiveMinds and AI Nodes
    function areHiveMindsActive()
        if not GG.HiveMind then
            GG.HiveMind = {};
            return false, {}
        end

        tableTeamsActive = {}
        boolActive = false
        for team, uTab in pairs(GG.HiveMind) do
            if uTab then
                for unit, data in pairs(uTab) do
                    if type(data) ~= "boolean" then
                        if data.boolActive == true then
                            tableTeamsActive[team] = unit
                            boolActive = true
                        end
                    end
                end
            end
        end
        return boolActive, tableTeamsActive
    end

    -- if active ones, find others that could be active
    function activateOtherHiveminds(tableTeamsActive)
        hiveMindMaxTime = DurationInSeconds * 1000
        if not GG.HiveMind then GG.HiveMind = {} end

        for team, uTab in pairs(GG.HiveMind) do
            if not tableTeamsActive[team] then
                for unit, data in pairs(uTab) do
                    hiveMindMaxTime = math.max(hiveMindMaxTime,
                                               data.rewindMilliSeconds)
                    if data.rewindMilliSeconds > 0 then
                        env = Spring.UnitScript.GetScriptEnv(unit)
                        if env then
                            Spring.UnitScript.CallAsUnit(unit, env.setActive)
                            tableTeamsActive[team] = unit
                        end
                        break
                    end
                end
            end
        end
        return tableTeamsActive, hiveMindMaxTime
    end

    oldGameSpeed = 1.0
    targetSlowMoSpeed = 0.4
    DurationInSeconds = 30 * 40
    -- set SlowMotion effect

    currentSpeed = 1.0
    
    activeHiveMinds = {}
    local State = {
        NotActive = "NotActive",
        Starting = "Starting",
        SlowMotion = "SlowMotion",
        Ending ="Ending"
    }
   local slowMoStateMachine = {
        ["NotActive"]  = function (frame, previousState)
                        boolSlowMoRequested, activeHiveMinds = areHiveMindsActive()
                        if detectRisingEdge(boolSlowMoRequested) then
                            SendToUnsynced("setSlowMoShaderActive", true)
                            Spring.PlaySoundFile("sounds/HiveMind/StartLoop.ogg", 1.0)
                            activeHiveMinds, MaxTimeInMs = activateOtherHiveminds(activeHiveMinds)
                            deactivateCursorForNormalTeams(activeHiveMinds)
                            oldGameSpeed = currentSpeed
                            startFrame = frame + 1
                            endFrame = (frame + (math.ceil(MaxTimeInMs / 1000) * 30))

                            return State.Starting
                        end
                    
                        return State.NotActive
                    end,
     
        ["Starting"]  = function (frame, previousState)
            
                            if frame % 10 == 0 and currentSpeed > targetSlowMoSpeed - 0.11 then --SlowDown
                                 Spring.Echo("slowdown to " .. currentSpeed)
                                 Spring.SendCommands("slowdown")
                                return State.Starting
                            end
          
                           if currentSpeed <= targetSlowMoSpeed - 0.11 then
                             return State.SlowMotion
                           end
              
                            return State.Starting
                        end, 
     
        ["SlowMotion"]  = function (frame, previousState)

                        
                        if frame - startFrame > 0 and frame - startFrame % 210 == 0 then
                            if side == "antagon" then
                                Spring.PlaySoundFile("sounds/HiveMind/Antagonloop.ogg", 1.0)
                            else
                                Spring.PlaySoundFile("sounds/HiveMind/Protagonloop.ogg", 1.0)
                            end
                        end                       
            
                        if frame < startFrame or frame > endFrame or detectFallingEdge(boolSlowMoRequested) then 
                            SendToUnsynced("setSlowMoShaderActive", false)
                            restoreCursorNonActiveTeams(activeHiveMinds)
                            SendToUnsynced("setDefaultGameSpeed", frame)
                            Spring.PlaySoundFile("sounds/HiveMind/EndLoop.ogg", 1.0)
                            return State.Ending
                        end
            
                        return State.SlowMotion
                    end,   
        ["Ending"]  = function (frame, previousState)
                         
                        if frame % 10 == 0 and currentSpeed < oldGameSpeed  then
                            Spring.Echo("speedup to from " .. currentSpeed.. " to ".. oldGameSpeed)
                            Spring.SendCommands("speedup ")
                            return State.Ending
                        end

                        if currentSpeed>= oldGameSpeed then
                            startFrame = frame -1
                            endFrame = frame -2    
                            return State.NotActive
                         end          
        
                        return State.Ending
                    end      
    
    }
    local currentState = "NotActive"
    local lastState = "NotActive"
    function handleSlowMoStateMachine(frame)        
        currentState = slowMoStateMachine[currentState](frame, lastState)
        lastState = currentState
    end

    -- for teams without a active node or no node at all - hide the cursor during the slowMotionPhase
    function deactivateCursorForNormalTeams(tableTeamsActive)
        process(Spring.GetTeamList(), function(team)
            if not tableTeamsActive[team] then
                SendToUnsynced("hideCursor", team)
            end
        end)
    end

    -- restore Cursor for non-active teams
    function restoreCursorNonActiveTeams(tableTeamsActive)
        process(Spring.GetTeamList(), function(team)
            if not tableTeamsActive[team] then
                SendToUnsynced("restoreCursor", team)
            end
        end)
    end

    function gadget:RecvLuaMsg(msg, playerID)
        start, ends = string.find(msg, "CurrentGameSpeed:")
        if ends then
            currentSpeed = tonumber(string.sub(msg, ends + 1, #msg))
            GG.GameSpeed = currentSpeed
        end
    end

else -- Unsynced
    local formerCommandTable = {}
    local alt, ctrl, meta, shift, left, right = 0, 0, 0, 0, 0, 0
    local side
    -- deactivate mouse icon

    local boolShaderActive = false

    local function restoreCursor(_, team)
        myTeam = Spring.GetMyTeamID()
        if myTeam == team then

            oldCommand = Spring.GetActiveCommand()
            formerCommandTable[team] = oldCommand

            alt, ctrl, meta, shift = Spring.GetModKeyState()
            local _, _, left, _, right = Spring.GetMouseState()
        end
    end

    local function setDefaultGameSpeed(_, n)
        if n % 5 == 0 then
            currentGameSpeed = Spring.GetGameSpeed() or 1.0
            Spring.SendLuaRulesMsg("CurrentGameSpeed:" .. currentGameSpeed)
        end
    end

    local function hideCursor(_, team)
        myTeam = Spring.GetMyTeamID()
        if myTeam == team then
            Spring.SetActiveCommand(formerCommandTable[team], 1, left, right,
                                    alt, ctrl, meta, shift)
        end
    end

    local function setSlowMoShaderActive(_, boolActivate)
            if boolActivate == true then
                Spring.SendLuaUIMsg("SlowMoShader_Active","a")
            else
                Spring.SendLuaUIMsg("SlowMoShader_Deactivated","a")
            end
        end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("Initialize", Initialize)
        gadgetHandler:AddSyncAction("setSlowMoShaderActive",setSlowMoShaderActive)
        gadgetHandler:AddSyncAction("restoreCursor", restoreCursor)
        gadgetHandler:AddSyncAction("hideCursor", hideCursor)
        gadgetHandler:AddSyncAction("setDefaultGameSpeed", setDefaultGameSpeed)


        local playerID = Spring.GetMyPlayerID()
        local tteam = select(4,Spring.GetPlayerInfo(playerID))
        side    = select(5,Spring.GetTeamInfo(tteam)) or "antagon"
    end
end
