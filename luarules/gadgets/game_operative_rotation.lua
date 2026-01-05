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
    local spGetUnitRotation = Spring.GetUnitRotation
    local spSetUnitRotation = Spring.SetUnitRotation
    local spSetUnitMoveGoal = Spring.SetUnitMoveGoal
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetGameFrame = Spring.GetGameFrame
    local spGetCommandQueue= Spring.GetCommandQueue
    local spGiveOrderToUnit = Spring.GiveOrderToUnit

    local GameConfig = getGameConfig()

    local storedCommands = {}
    LastAimFrame = {}
    local Cache = {}

    local moveCommands = {
        [CMD.MOVE] = true,
        [CMD.PATROL] = true,
        [CMD.FIGHT] = true
    }
    local AIM_TIMEOUT = 33  

    local GaiaTeamID = Spring.GetGaiaTeamID()

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

    local function IsUnitMoving(unitID)
        local cmds = spGetCommandQueue(unitID, 3)
        if not cmds then  
           return false 
        end

        for i = 1, #cmds do
            local id = cmds[i].id
            if moveCommands[id] then
                return true
            end
        end

        return false
    end

    function StoreAwayAndRemoveCommands(id)
         if storedCommands[id] then return end

        local cmds = spGetCommandQueue(id, 20)
        if not cmds or #cmds == 0 then return end

        local stored = {}

        for i = #cmds, 1, -1 do
            local cmd = cmds[i]
            if moveCommands[cmd.id] and not cmd.options.internal then
                stored[#stored+1] = {
                    id = cmd.id,
                    params = cmd.params,
                    options = cmd.options,
                }
                spGiveOrderToUnit(id, CMD.REMOVE, { cmd.tag }, {})
            end
        end

        if #stored > 0 then
            storedCommands[id] = stored
        end
    end

    function optionalSmoothOutMovement(id, gf, x,y,z, positionT, len, boolIsMoving)   
        if not  LastAimFrame[id] then 
            LastAimFrame[id] = gf 
            StoreAwayAndRemoveCommands(id)
        end

        if  gf - LastAimFrame[id] > 5 and boolIsMoving then
            LastAimFrame[id] = gf
            dx,dz = positionT.x, positionT.z --fallback to mouseTargetPosition
            if len > 0 then
                dx = x + ((dx - x)/len) * 128
                dz = z + ((dz - z)/len) * 128
            end
            spSetUnitMoveGoal(id, dx, y, dz)
        end
    end


    function rotateUnitTowardsPoint(id, positionT)
        local gameFrame = spGetGameFrame()
        local x,y,z = spGetUnitPosition(id)
 
        distanceToPoint = distance(x,y,z, positionT.x, positionT.y, positionT.z) 
        if distanceToPoint > 964 or distanceToPoint < 15  then return end --sniperrifle or to close
        yaw, pitch, roll = spGetUnitRotation(id)
        newPitch = math.pi - math.atan2(x-positionT.x, z-positionT.z) 
        boolIsMoving = IsUnitMoving(id)

        optionalSmoothOutMovement(id, gameFrame, x,y,z, positionT, distanceToPoint, boolIsMoving)
   
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
                Spring.UnitScript.CallAsUnit(id, env.externalAimFunction, positionT, internalPitch, boolIsMoving)                 
            end      
        end   

        if not Cache[id] or Cache[id] < gameFrame + (15*30) then
            if Cache[id] then
                registerEmergency(x, z)
            end
            Cache[id] = gameFrame          

            foreach(
                getAllOfTypeNearUnit(id, civilianWalkingTypeTable, 256),
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

local function SanitizeParams(params)
    local out = {}
    for i = 1, #params do
        local v = params[i]
        if type(v) == "number" then
            out[#out + 1] = v
        end
    end
    return out
end

local CMD_OPT_ALT = CMD.OPT_ALT
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_META = CMD.OPT_META
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT


local function GetCmdOpts(alt, ctrl, meta, shift, right)

    local opts = { alt=alt, ctrl=ctrl, meta=meta, shift=shift, right=right }
    local coded = 0

    if alt   then coded = coded + CMD_OPT_ALT   end
    if ctrl  then coded = coded + CMD_OPT_CTRL  end
    if meta  then coded = coded + CMD_OPT_META  end
    if shift then coded = coded + CMD_OPT_SHIFT end
    if right then coded = coded + CMD_OPT_RIGHT end

    opts.coded = coded
    return opts
end


function RestoreStoredMovements(id)
    echo("Restoring Movement  ")
    if true then return end
    local stored = storedCommands[id]
    if not stored then return end


    -- Reinsert in original order
    for i = #stored, 1, -1 do
        local cmd = stored[i]
        local opts = GetCmdOpts(
                cmd.options.alt,
                cmd.options.ctrl,
                cmd.options.meta,
                cmd.options.shift,
                cmd.options.right
            )

        local params = SanitizeParams(cmd.params or {})
        spGiveOrderToUnit(
            id,
            CMD.INSERT,
            { 0, cmd.id, opts, unpack(params) },
            {}
            )
    end
    storedCommands[id] = nil
end

function gadget:GameFrame(gf)
    if LastAimFrame then
        for unitID, lastFrame in pairs(LastAimFrame) do
            if lastFrame and gf - lastFrame > AIM_TIMEOUT then
                RestoreStoredMovements(unitID)
                LastAimFrame[unitID] = nil
            end
        end
    end
end

end