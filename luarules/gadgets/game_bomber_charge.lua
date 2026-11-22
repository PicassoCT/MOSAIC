function gadget:GetInfo()
    return {name = "Bomber charge", desc = "Targeted approach, exposed sprint and contact detonation",
        author = "MOSAIC", license = "GPL3", layer = 2, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return end

VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("luarules/configs/commandsIDs.lua")
local config = getGameConfig().military.suicideBomber
local bomberTypes = getSuicideBombermanTypeTable(UnitDefs)
local ATTACK = CMD_BOMBER_ATTACK
local bombers, charges = {}, {}
local pendingOrders, deathDrawn = {}, {}
-- Each team's pair contains one detonation and one dud. Randomize only the
-- first draw; the second is its complement. Keep the pending draw on reload.
GG.BomberGunfireDraws = GG.BomberGunfireDraws or {}
local gunfireDraws = GG.BomberGunfireDraws
local gunfireNames = {
    ak47 = true, pistol = true, submachingegun = true,
    machinegun = true, heavymachinegun = true, aamachinegun = true,
    covermachinegun = true, escortmachinegun = true, escortantiair = true,
    cgunshipmg = true, supportgunshipmg = true,
    sniperrifle = true, slowsniperrifle = true,
}
local gunfireTypes = {}
for defID, def in pairs(WeaponDefs) do
    if gunfireNames[def.name] then gunfireTypes[defID] = true end
end
local internalOrder = false
local gaia = Spring.GetGaiaTeamID()
local allied = {allied = true}

local function alive(id)
    return type(id) == "number" and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end

local function targetVisible(id, target)
    if not alive(target) or target == id then return false end
    local def = UnitDefs[Spring.GetUnitDefID(target)]
    if def.canFly or (def.modCategories or {}).orbit then return false end
    if Spring.AreTeamsAllied(Spring.GetUnitTeam(id), Spring.GetUnitTeam(target)) then return false end
    local los = Spring.GetUnitLosState(target, Spring.GetUnitAllyTeam(id))
    return los and los.los
end

local function targetFromParams(id, params)
    if #params == 1 and targetVisible(id, params[1]) then
        local x, y, z = Spring.GetUnitPosition(params[1])
        if x then return {target = params[1], x = x, y = y, z = z} end
    elseif #params == 3 then
        local x, z = params[1], params[3]
        if type(x) == "number" and type(z) == "number"
            and x >= 0 and x <= Game.mapSizeX and z >= 0 and z <= Game.mapSizeZ then
            return {x = x, y = Spring.GetGroundHeight(x, z), z = z}
        end
    end
end

local function save(id, state)
    Spring.SetUnitRulesParam(id, "bomber_charge_target", state.target or -1, allied)
    for _, axis in ipairs({"x", "y", "z"}) do
        Spring.SetUnitRulesParam(id, "bomber_charge_" .. axis, state[axis], allied)
    end
end

local function panic(id, state, x, z)
    if not GG.StartCivilianBehaviour then return end
    state.fleeing = state.fleeing or {}
    for _, civilian in ipairs(Spring.GetUnitsInCylinder(x, z, config.panicRadius, gaia)) do
        if not (GG.DisguiseCivilianFor or {})[civilian] and not state.fleeing[civilian] then
            state.fleeing[civilian] = GG.StartCivilianBehaviour(civilian, "startFleeing", id) or nil
        end
    end
end

local function startCharge(id, state, restoring)
    charges[id] = state
    Spring.SetUnitRulesParam(id, "bomber_charging", 1, {inlos = true})
    Spring.SetUnitNoSelect(id, true)
    Spring.SetUnitCloak(id, false)
    Spring.SetUnitNeutral(id, false)
    -- Remove cover peacefully: the decoy's synchronization must not kill its owner.
    for body, owner in pairs(GG.DisguiseCivilianFor or {}) do
        if owner == id then
            GG.DiedPeacefully = GG.DiedPeacefully or {}
            GG.DiedPeacefully[body] = true
            GG.DisguiseCivilianFor[body] = nil
            if alive(body) then Spring.DestroyUnit(body, false, true) end
        end
    end
    local env = Spring.UnitScript.GetScriptEnv(id)
    if env and env.beginBomberCharge then
        Spring.UnitScript.CallAsUnit(id, env.beginBomberCharge, restoring)
    end
    Spring.MoveCtrl.SetGroundMoveTypeData(id, {
        maxSpeed = UnitDefs[Spring.GetUnitDefID(id)].speed * config.sprintSpeedMultiplier,
    })
    save(id, state)
    local x, _, z = Spring.GetUnitPosition(id)
    if x then panic(id, state, x, z) end
    if not restoring and GG.ReportBomberCharge then GG.ReportBomberCharge(id) end
end

function gadget:UnitCreated(id, defID)
    if not bomberTypes[defID] then return end
    bombers[id] = true
    if not Spring.FindUnitCmdDesc(id, ATTACK) then
        local desc = {id = ATTACK, type = CMDTYPE.ICON_UNIT_OR_MAP, name = "Attack",
            action = "attack", cursor = "Attack",
            tooltip = "Approach a target. Within " .. config.sprintRange ..
                " elmos, lose disguise and control, then sprint to contact and explode."}
        local oldAttack = Spring.FindUnitCmdDesc(id, CMD.ATTACK)
        if oldAttack then Spring.EditUnitCmdDesc(id, oldAttack, desc)
        else Spring.InsertUnitCmdDesc(id, desc) end
    end
    if Spring.GetUnitRulesParam(id, "bomber_charging") == 1 then
        local target = Spring.GetUnitRulesParam(id, "bomber_charge_target")
        local x = Spring.GetUnitRulesParam(id, "bomber_charge_x")
        if x then
            startCharge(id, {target = alive(target) and target or nil, x = x,
                y = Spring.GetUnitRulesParam(id, "bomber_charge_y"),
                z = Spring.GetUnitRulesParam(id, "bomber_charge_z")}, true)
        end
    end
end

function gadget:Initialize()
    gadgetHandler:RegisterCMDID(ATTACK)
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id, Spring.GetUnitDefID(id)) end
end

function gadget:AllowCommand(id, defID, team, command, params, options)
    if internalOrder then return true end
    if charges[id] then return false end
    if not bombers[id] then return true end
    local insertedAttack = command == CMD.INSERT and params[2] == CMD.ATTACK
    if command == CMD.ATTACK or insertedAttack or pendingOrders[id] then
        if command == CMD.ATTACK and not targetFromParams(id, params) then return false end
        local converted = {}; for i, value in ipairs(params) do converted[i] = value end
        if insertedAttack then converted[2] = ATTACK end
        local queue = pendingOrders[id] or {}
        pendingOrders[id] = queue
        queue[#queue + 1] = {command = command == CMD.ATTACK and ATTACK or command,
            params = converted, options = options and options.coded or 0}
        -- Engine GiveOrderToUnit forbids recursion from a Lua-issued order.
        -- Replay this ordered batch next frame, including any later cancellation.
        return false
    end
    if command == ATTACK then return targetFromParams(id, params) ~= nil end
    return true
end

function gadget:CommandFallback(id, defID, team, command, params)
    if command ~= ATTACK then return false end
    if not bombers[id] then return true, true end
    if charges[id] then return true, false end
    local state = targetFromParams(id, params)
    if not state then Spring.ClearUnitGoal(id); return true, true end
    local stunned, _, inBuild = Spring.GetUnitIsStunned(id)
    if stunned or inBuild or Spring.GetUnitTransporter(id) then return true, false end
    local x, y, z = Spring.GetUnitPosition(id)
    local radius = state.target and Spring.GetUnitRadius(state.target) or 0
    if (x-state.x)^2 + (y-state.y)^2 + (z-state.z)^2 <= (config.sprintRange + radius)^2 then
        startCharge(id, state)
    else
        Spring.SetUnitMoveGoal(id, state.x, state.y, state.z, config.contactRange + radius)
    end
    return true, false
end

function gadget:GameFrame(frame)
    for id, queue in pairs(pendingOrders) do
        pendingOrders[id] = nil
        for _, order in ipairs(queue) do
            if not alive(id) or charges[id] then break end
            internalOrder = true
            Spring.GiveOrderToUnit(id, order.command, order.params, order.options)
            internalOrder = false
        end
    end
    for id, state in pairs(charges) do
        if not state.ordersCleared then
            internalOrder = true
            Spring.GiveOrderToUnit(id, CMD.STOP, {}, 0)
            internalOrder = false
            state.ordersCleared = true
        end
        -- Only follow visible targets. A lost/destroyed target leaves its last
        -- known destination; commitment cannot be cancelled to recover control.
        if state.target and targetVisible(id, state.target) then
            state.x, state.y, state.z = Spring.GetUnitPosition(state.target)
        end
        local x, y, z = Spring.GetUnitPosition(id)
        local radius = state.target and alive(state.target) and Spring.GetUnitRadius(state.target) or 0
        local stunned = Spring.GetUnitIsStunned(id)
        if not stunned and x and (x-state.x)^2 + (y-state.y)^2 + (z-state.z)^2 <= (config.contactRange + radius)^2 then
            -- Native self-destruction uses the authored ssied blast and damage.
            Spring.DestroyUnit(id, true, false)
        elseif x and frame % 3 == 0 then
            Spring.SetUnitMoveGoal(id, state.x, state.y, state.z, math.max(1, radius))
        end
        if alive(id) and frame % 15 == 0 then
            save(id, state)
            if x then panic(id, state, x, z) end
        end
    end
end

function gadget:AllowUnitCloak(id) return not charges[id] end
function gadget:AllowUnitTransfer(id) return not charges[id] end
function gadget:AllowUnitTransport(transporter, transporterDef, transporterTeam, id)
    return not charges[id]
end

function gadget:UnitDamaged(body, defID, team, damage, paralyzer, weaponDefID, projectileID, attacker)
    if paralyzer or damage <= 0 or not gunfireTypes[weaponDefID] then return end
    local id = (GG.DisguiseCivilianFor or {})[body] or body
    if not bombers[id] or deathDrawn[id] then return end
    local health = Spring.GetUnitHealth(body)
    if not health or health > 0 then return end
    deathDrawn[id] = true
    local owner = Spring.GetUnitTeam(id)
    local detonate = gunfireDraws[owner]
    if detonate == nil then
        detonate = math.random(0, 1) == 1
        gunfireDraws[owner] = not detonate
    else
        gunfireDraws[owner] = nil
    end
    if detonate then
        if body ~= id then
            GG.DiedPeacefully = GG.DiedPeacefully or {}
            GG.DiedPeacefully[body] = true
        end
        -- UnitDamaged runs after health subtraction and before normal death.
        -- Use the native ssied self-destruct, preserving the killing attacker.
        Spring.DestroyUnit(id, true, false, attacker)
    end
end

function gadget:UnitDestroyed(id)
    bombers[id], charges[id] = nil, nil
    pendingOrders[id], deathDrawn[id] = nil, nil
    for bomber, state in pairs(charges) do
        if state.target == id then state.target = nil; save(bomber, state) end
        if state.fleeing then state.fleeing[id] = nil end
    end
end
