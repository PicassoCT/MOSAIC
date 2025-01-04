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
    VFS.Include("scripts/lib_OS.lua")
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

    GaiaTeamID = Spring.GetGaiaTeamID()

    Cache= {}
    local anglesUpperBodyTurnRad = math.rad(55)
    local OneSecondFrames = 30
    function rotateUnitTowardsPoint(id, positionT)

        x,y,z = spGetUnitPosition(id)
        distanceToPoint = distance(x,y,z, positionT.x, positionT.y, positionT.z) 
        if distanceToPoint > 964 or distanceToPoint < 15  then return end --sniperrifle or to close
        yaw, pitch, roll = spGetUnitRotation(id)
        newPitch = math.pi - math.atan2(x-positionT.x, z-positionT.z) 
        pitchDiff = pitch - newPitch
        rotationSign = pitchDiff/math.abs(pitchDiff)
        pitchDiff = math.abs(pitchDiff)
        internalPitch = 0
        if pitchDiff >  anglesUpperBodyTurnRad then
            spSetUnitRotation(id, yaw, newPitch, roll) 
        else           
            internalPitch = pitchDiff * rotationSign 
        end
        
        gameFrame = Spring.GetGameFrame()
        if (GG.OperativeTurnTable[id] == nil) or GG.OperativeTurnTable[id] < gameFrame + OneSecondFrames then
            GG.OperativeTurnTable[id] = gameFrame
            env = Spring.UnitScript.GetScriptEnv(id)
            if env and env.setOverrideAnimationState then
                Spring.UnitScript.CallAsUnit(id, env.externalAimFunction, positionT, internalPitch)
            end      
        end   

        if not Cache[id] or Cache[id] < Spring.GetGameFrame() + 100 then
            Cache[id] = Spring.GetGameFrame() 

            foreach(getAllOfTypeNearUnit(id, civilianWalkingTypeTable, 256),
                    function(civId)
                      
                        if spGetUnitTeam(civId) == GaiaTeamID and
                        not GG.AerosolAffectedCivilians[civId] then
                            Spring.Echo("Sending units fleeing ".. civId)
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
