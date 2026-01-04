function gadget:GetInfo()
    return {
        name = "operative rotation",
        desc = "This gadget handles the minigame",
        author = "",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    -- variables

    local spGetUnitPosition = Spring.GetUnitPosition
    

    local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
    local spGetUnitDefID = Spring.GetUnitDefID
    local spDestroyUnit = Spring.DestroyUnit
    local postRoundTimeInSeconds = 15
    local spGetUnitRotation = Spring.GetUnitRotation
    local spSetUnitRotation = Spring.SetUnitRotation
    local spGetUnitTeam = Spring.GetUnitTeam
    local GameConfig = getGameConfig()
    InjectedMove = {}

    local GaiaTeamID = Spring.GetGaiaTeamID()
    local LastAimFrame = {}
    local Cache= {}
    local anglesUpperBodyTurnRad = math.rad(55)
    local OneSecondFrames = 30

    local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                         GameConfig.instance.culture,
                                         "civilian", UnitDefs)

    function gadget:Initialize()
        if not GG.OperativeTurnTable then GG.OperativeTurnTable = {} end
    end

    function startInternalBehaviourOfState(id, name, ...)
        local arg = arg;
        if (not arg) then
            arg = {...};
            arg.n = #arg
        end

        env = Spring.UnitScript.GetScriptEnv(id)
        if env  then
            Spring.UnitScript.CallAsUnit(id, 
                                         env[name],
                                         arg[1] or nil,
                                         arg[2] or nil,
                                         arg[3] or nil,
                                         arg[4] or nil
                                         )
        end
    end    

    local moveCommands = {
        [CMD.MOVE] = true,
        [CMD.PATROL] = true,
        [CMD.FIGHT] = true
    }

    local function IsUnitMoving(unitID)
        local cmds = Spring.GetCommandQueue(unitID, 3)
        if not cmds then  
           echo("IsUnitMoving:No commands")
           return false 
       end
       commandSting = ""
        for i = 1, #cmds do
            local id = cmds[i].id
            commandSting = commandSting ..id.." >> "
            if moveCommands[id] then
                echo(" Move cmmand in queue :"..commandSting)
                return true
            end
        end
        echo("No Move cmmand in queue :"..commandSting)
        return false
    end

    

    function optionalSmoothOutMovement(id, gf, x,y,z, positionT, len)   
        if not  LastAimFrame[id] then LastAimFrame[id] = gf end

        if  gf - LastAimFrame[id] > 15 and IsUnitMoving(id) then
            LastAimFrame[id] = gf
            dx,dz = positionT.x, positionT.z --fallback to mouseTargetPosition
            if len > 0 then
                dx = x + ((dx - x)/len) * 128
                dz = z + ((dz - z)/len) * 128
            end
            Spring.SetUnitMovegoal(id, dx, y, dz)
            
        else
            Spring.Echo("Unit not moving while turning")
        end
    end

    function rotateUnitTowardsPoint(id, positionT)
        local gameFrame = Spring.GetGameFrame()
        local x,y,z = spGetUnitPosition(id)
 
        distanceToPoint = distance(x,y,z, positionT.x, positionT.y, positionT.z) 
        if distanceToPoint > 964 or distanceToPoint < 15  then return end --sniperrifle or to close
        yaw, pitch, roll = spGetUnitRotation(id)
        newPitch = math.pi - math.atan2(x-positionT.x, z-positionT.z) 

        optionalSmoothOutMovement(id, gameFrame, x,y,z, positionT, distanceToPoint)
   
        pitchDiff = pitch - newPitch
        rotationSign = pitchDiff/math.abs(pitchDiff)
        pitchDiff = math.abs(pitchDiff)
        internalPitch = 0
        if pitchDiff >  anglesUpperBodyTurnRad then
            spSetUnitRotation(id, yaw, newPitch, roll) 
        else           
            internalPitch = pitchDiff * rotationSign 
        end
        

        if (GG.OperativeTurnTable[id] == nil) or GG.OperativeTurnTable[id] < gameFrame + OneSecondFrames then
            GG.OperativeTurnTable[id] = gameFrame
            env = Spring.UnitScript.GetScriptEnv(id)
            if env and env.setOverrideAnimationState then
                Spring.UnitScript.CallAsUnit(id, env.externalAimFunction, positionT, internalPitch)
                if setWantCloak then
                    Spring.UnitScript.CallAsUnit(id, env.setWantCloak, false)
                end                   
            end      
        end   

        if not Cache[id] or Cache[id] < Spring.GetGameFrame() + (15*30) then
            if Cache[id] then
                registerEmergency(x, z)
            end
            Cache[id] = Spring.GetGameFrame()            

            foreach(getAllOfTypeNearUnit(id, civilianWalkingTypeTable, 256),
                    function(civId)
                      
                        if spGetUnitTeam(civId) == GaiaTeamID and not GG.AerosolAffectedCivilians[civId] then                            
                            startInternalBehaviourOfState(civId , "startFleeing", id)
                            return civId
                        end
                    end)

        end
    end

    function gadget:RecvLuaMsg(msg, playerID)
        if msg and string.find(msg, "OPROTPOS") then
            T = split(msg, "|")
            position = {}
            position.x = tonumber(T[2])
            position.y = tonumber(T[3])
            position.z = tonumber(T[4])
            for i = 5, #T do
                local unitID = T[i]
                if string.len(unitID) > 0 then
                    rotateUnitTowardsPoint(tonumber(unitID), position)
                end
            end
        end
    end
end 
