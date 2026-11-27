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
    local spGetPlayerInfo = Spring.GetPlayerInfo
    local spValidUnitID = Spring.ValidUnitID
    local spGetUnitIsDead = Spring.GetUnitIsDead
    local spGetUnitDefID = Spring.GetUnitDefID

    local GameConfig = getGameConfig()

    local storedCommands = {}
    local LastAimFrame = {}
    local Cache = {}

    -- Match the three scripts/UI selections that implement manual aiming;
    -- getOperativeTypeTable also includes civilianagent, which has no aim hook.
    local manualAimNames = {
        operativeasset = true,
        operativepropagator = true,
        operativeinvestigator = true,
    }
    local manualAimDefs = {}
    for defID, def in pairs(UnitDefs) do
        if manualAimNames[def.name] then manualAimDefs[defID] = true end
    end

    -- Immediate updates, not a timer/debounce: 64 packets per simulation frame
    -- leaves room for high-refresh clients even at 0.4x slow motion (40 updates
    -- per sim frame at 480 render FPS). Excess work is dropped, never queued.
    -- The stock UI sends one unit; bounded lists remain supported.
    local MAX_MESSAGE_BYTES = 512
    local MAX_UNITS_PER_MESSAGE = 8
    local MAX_MESSAGES_PER_FRAME = 64
    local MAX_PLAYER_AIMS_PER_FRAME = 128
    local MAX_UNIT_AIMS_PER_FRAME = 64
    local playerBudgets, unitBudgets = {}, {}

    local moveCommands = {
        [CMD.MOVE] = true,
        [CMD.PATROL] = true,
        [CMD.FIGHT] = true
    }
    local AIM_TIMEOUT = 33  

    local GaiaTeamID = Spring.GetGaiaTeamID()

    local anglesUpperBodyTurnRad = math.rad(55)

    local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                         GameConfig.game.culture,
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

        local env = Spring.UnitScript.GetScriptEnv(id)
        if env and type(env[name]) == "function" then
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
            local dx,dz = positionT.x, positionT.z --fallback to mouseTargetPosition
            if len > 0 then
                dx = x + ((dx - x)/len) * 128
                dz = z + ((dz - z)/len) * 128
            end
            spSetUnitMoveGoal(id, dx, y, dz)
        end
    end


    local function rotateUnitTowardsPoint(id, positionT, gameFrame)
        local x,y,z = spGetUnitPosition(id)
        if not x then return end
        local dx, dy, dz = x-positionT.x, y-positionT.y, z-positionT.z
        local distanceSquared = dx*dx + dy*dy + dz*dz
        if distanceSquared > 964*964 or distanceSquared < 15*15 then return end
        local yaw, pitch, roll = spGetUnitRotation(id)
        if not yaw or not pitch or not roll then return end
        local env = Spring.UnitScript.GetScriptEnv(id)
        if not env or type(env.externalAimFunction) ~= "function" then return end
        local distanceToPoint = math.sqrt(distanceSquared)
        local newPitch = math.pi - math.atan2(dx, dz)
        local boolIsMoving = IsUnitMoving(id)

        optionalSmoothOutMovement(id, gameFrame, x,y,z, positionT, distanceToPoint, boolIsMoving)
   
        local pitchDiff = pitch - newPitch
        local internalPitch = 0
        if math.abs(pitchDiff) > anglesUpperBodyTurnRad then
            spSetUnitRotation(id, yaw, newPitch, roll) 
        else           
            internalPitch = pitchDiff -- including exact alignment: never 0/0
        end
        
        GG.OperativeTurnTable[id] = gameFrame
        Spring.UnitScript.CallAsUnit(id, env.externalAimFunction, positionT, internalPitch, boolIsMoving)

        -- Mouse updates can outnumber simulation frames. Aim stays immediate;
        -- civilian queries/emergencies need run only once per unit per frame.
        if Cache[id] ~= gameFrame then
            if Cache[id] then
                registerEmergency(x, z)
            end
            Cache[id] = gameFrame          

            foreach(
                getAllOfTypeNearUnit(id, civilianWalkingTypeTable, 256),
                 function(civId)
                  
                    if spGetUnitTeam(civId) == GaiaTeamID and not (GG.AerosolAffectedCivilians and GG.AerosolAffectedCivilians[civId]) then
                        startInternalBehaviourOfState(civId , "startFleeing", id)
                        return civId
                    end
                end)

        end
    end

    local function finiteNumber(value)
        return value and value == value and value > -math.huge and value < math.huge
    end

    local function ownedManualAimUnit(id, team)
        return spValidUnitID(id) and not spGetUnitIsDead(id)
            and spGetUnitTeam(id) == team and manualAimDefs[spGetUnitDefID(id)] == true
    end

    function gadget:RecvLuaMsg(msg, playerID)
        if type(msg) ~= "string" or msg:sub(1, 9) ~= "OPROTPOS|"
            or #msg > MAX_MESSAGE_BYTES then return end

        local name, active, spectator, team = spGetPlayerInfo(playerID, false)
        if not name or not active or spectator or team == nil then return end
        local frame = spGetGameFrame()
        local budget = playerBudgets[playerID]
        if not budget then
            budget = {}; playerBudgets[playerID] = budget
        end
        if budget.frame ~= frame then
            budget.frame, budget.messages, budget.aims = frame, 0, 0
        end
        if budget.messages >= MAX_MESSAGES_PER_FRAME then return end
        budget.messages = budget.messages + 1 -- malformed packets also cost budget

        local sx, sy, sz, ids = msg:match("^OPROTPOS|([^|]+)|([^|]+)|([^|]+)|(.+)$")
        if not ids then return end
        local x, y, z = tonumber(sx), tonumber(sy), tonumber(sz)
        if not finiteNumber(x) or not finiteNumber(y) or not finiteNumber(z)
            or x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ
            or math.abs(y) > 1000000 then return end

        -- Validate the entire bounded list before any rotation/order mutation.
        -- Empty separators are emitted by the existing three-type UI serializer.
        local units, seen, count = {}, {}, 0
        for token in ids:gmatch("[^|]+") do
            count = count + 1
            if count > MAX_UNITS_PER_MESSAGE or #token > 10 or not token:match("^%d+$") then return end
            local id = tonumber(token)
            if id > 2147483647 or not ownedManualAimUnit(id, team) then return end
            if not seen[id] then
                seen[id] = true
                units[#units+1] = id
            end
        end
        if #units == 0 or budget.aims + #units > MAX_PLAYER_AIMS_PER_FRAME then return end
        budget.aims = budget.aims + #units
        local position = {x=x, y=y, z=z}
        for i = 1, #units do
            local id = units[i]
            local unitBudget = unitBudgets[id]
            if not unitBudget then
                unitBudget = {}; unitBudgets[id] = unitBudget
            end
            if unitBudget.frame ~= frame then
                unitBudget.frame, unitBudget.aims = frame, 0
            end
            -- Recheck live ownership before executing each unit's script.
            if unitBudget.aims < MAX_UNIT_AIMS_PER_FRAME and ownedManualAimUnit(id, team) then
                unitBudget.aims = unitBudget.aims + 1
                rotateUnitTowardsPoint(id, position, frame)
            end
        end
    end

    local function clearUnitState(id)
        storedCommands[id], LastAimFrame[id], Cache[id], unitBudgets[id] = nil, nil, nil, nil
        if GG.OperativeTurnTable then GG.OperativeTurnTable[id] = nil end
    end

    function gadget:UnitDestroyed(id) clearUnitState(id) end
    function gadget:UnitTaken(id) clearUnitState(id) end
    function gadget:UnitGiven(id) clearUnitState(id) end



local CMD_OPT_ALT = CMD.OPT_ALT
local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_OPT_META = CMD.OPT_META
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT


local function buildCmdOptBitmask(alt, ctrl, meta, shift, right)

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

function assertTOnlyNumbers(T, commandName)
    for k,v in pairs(T) do
     assert(type(v) == "number",commandName.." : ".. k.." >> "..v.. " is not a number")
    end
end


function RestoreStoredMovements(id)
    if true then return end
    local stored = storedCommands[id]
    if not stored then return end


    -- Reinsert in original order
    for i = #stored, 1, -1 do
        local cmd = stored[i]
        local opts = buildCmdOptBitmask(
                cmd.options.alt,
                cmd.options.ctrl,
                cmd.options.meta,
                cmd.options.shift,
                cmd.options.right
            )

        assertTOnlyNumbers(cmd.params, cmd.id)

        spGiveOrderToUnit(
            id,
            CMD.INSERT,
            { 0, cmd.id, opts, unpack(cmd.params or {}) },
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
