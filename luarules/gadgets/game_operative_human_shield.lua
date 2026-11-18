function gadget:GetInfo()
    return {
        name = "Operative human shield",
        desc = "Antagon operatives hold civilian hostages; sniper fire or melee counters the hold",
        author = "MOSAIC contributors",
        license = "GPL v2 or later",
        layer = 10,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("luarules/configs/commandsIDs.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local config = VFS.Include("luarules/configs/human_shield.lua")
local TAKE, RELEASE = CMD_HUMAN_SHIELD, CMD_RELEASE_HUMAN_SHIELD
local gaia = Spring.GetGaiaTeamID()
local civilianDefs = getCultureUnitModelTypes("international", "civilian", UnitDefs)
-- The ordinary civilian road-vehicle pool excludes motorcycles and aircraft.
local carDefs = getCultureUnitModelTypes("international", "truck", UnitDefs)
local carriers, hostages = {}, {}
local pendingFireOrders = {}
local operativeUnits, carrierDefs, sniperWeapons, meleeWeapons, counterUnits, factionStarters = {}, {}, {}, {}, {}, {}
local fireCommands, workCommands = {}, {}
local meleeTransports = {}
local visibility = {inlos = true}
local api = {}
local targetWatchesRegistered = false

for name in pairs(config.carrierUnits) do
    local def = UnitDefNames[name]
    if def then carrierDefs[def.id] = true end
end
for _, name in ipairs({"ATTACK", "DGUN", "AREA_ATTACK"}) do
    if CMD[name] then fireCommands[CMD[name]] = true end
end
for _, name in ipairs({"REPAIR", "RECLAIM", "RESURRECT", "CAPTURE", "RESTORE"}) do
    if CMD[name] then workCommands[CMD[name]] = true end
end
workCommands[CMD_INVESTIGATE] = true
workCommands[CMD_ASSET_ROOFTOP] = true
if UnitDefNames.closecombatarena then meleeTransports[UnitDefNames.closecombatarena.id] = true end

for name in pairs(config.sniperWeapons) do
    local def = WeaponDefNames[name]
    if def then sniperWeapons[def.id] = true end
end
for name in pairs(config.meleeWeapons) do
    local def = WeaponDefNames[name]
    if def then meleeWeapons[def.id] = true end
end
for defID, def in pairs(UnitDefs) do
    for _, weapon in ipairs(def.weapons or {}) do
        if sniperWeapons[weapon.weaponDef] or meleeWeapons[weapon.weaponDef] then counterUnits[defID] = true end
    end
end
for name, side in pairs({operativeinvestigator = "protagon", operativepropagator = "antagon"}) do
    local def = UnitDefNames[name]
    if def then factionStarters[def.id] = side end
end

local function alive(id)
    return type(id) == "number" and id == id and Spring.ValidUnitID(id)
        and not Spring.GetUnitIsDead(id)
end

local function sideOf(team)
    if team == nil or team == gaia then return nil end
    local side = select(5, Spring.GetTeamInfo(team, false))
    side = type(side) == "string" and side:lower() or nil
    if side == "protagon" or side == "antagon" then return side end
    return factionStarters[tonumber(Spring.GetTeamRulesParam(team, "startUnit"))]
end

local function callScript(id, name, ...)
    local env = Spring.UnitScript.GetScriptEnv(id)
    if env and env[name] then return Spring.UnitScript.CallAsUnit(id, env[name], ...) end
end

local function eligibleCarrier(id)
    return alive(id) and carrierDefs[Spring.GetUnitDefID(id)] == true
        and sideOf(Spring.GetUnitTeam(id)) == "antagon"
end

function api.IsTransportAllowed(id)
    local transport = Spring.GetUnitTransporter(id)
    return transport == nil or (alive(transport) and carDefs[Spring.GetUnitDefID(transport)] ~= nil
        and Spring.GetUnitTransporter(transport) == nil)
end

local function detained(id)
    if GG.CloseCombatInvolved and GG.CloseCombatInvolved[id] then return true end
    local interrogation = GG.InterrogationTable and GG.InterrogationTable[id]
    if interrogation then
        for _, active in pairs(interrogation) do
            if active then return true end
        end
    end
    -- Interrogations outlive their original attack command. The table is
    -- indexed by victim, so the interrogator must also be checked as a value.
    if GG.InterrogationTable then
        for _, interrogators in pairs(GG.InterrogationTable) do
            if interrogators[id] then return true end
        end
    end
    local stunned, _, building = Spring.GetUnitIsStunned(id)
    return stunned or building
end

local function releaseReason(id)
    if GG.CloseCombatInvolved and GG.CloseCombatInvolved[id] then return "melee" end
    -- Arena attachment can stun the operative before its script receives the
    -- close-combat callback. The passenger must still escape that transition.
    local transport = Spring.GetUnitTransporter(id)
    if transport and meleeTransports[Spring.GetUnitDefID(transport)] then return "melee" end
end

local function carrierReady(id)
    if not eligibleCarrier(id) or not api.IsTransportAllowed(id) or detained(id)
        or Spring.GetUnitIsBuilding(id) or Spring.GetUnitRulesParam(id, "asset_rooftop") == 1
        or Spring.GetUnitRulesParam(id, "betrayal_defector") == 1
        or Spring.GetUnitRulesParam(id, "betrayal_pending") == 1 then return false end
    local command = Spring.GetUnitCurrentCommand(id)
    if command and (command < 0 or workCommands[command]) then return false end
    return callScript(id, "canUseHumanShield") == true
end

local function attachmentPiece(id)
    return (Spring.GetUnitPieceMap(id) or {})[config.attachmentPiece]
end

function api.HasShield(id)
    local state = carriers[id]
    return state ~= nil and eligibleCarrier(id) and alive(state.civilian)
        and Spring.GetUnitTransporter(state.civilian) == id
end

function api.IsHostage(id)
    return hostages[id] ~= nil
end

function api.IsProtected(target, attackerTeam, weaponDefID)
    if sniperWeapons[weaponDefID] or meleeWeapons[weaponDefID] then return false end
    local carrier = hostages[target] or target
    if not api.HasShield(carrier) or not carrierReady(carrier)
        or sideOf(attackerTeam) ~= "protagon" then return false end
    local team = Spring.GetUnitTeam(carrier)
    return team ~= nil and not Spring.AreTeamsAllied(team, attackerTeam)
end

function api.BlockShot(attacker, weaponNum, target)
    -- Aim mode may keep tracking a target; no weapon can fire from the hold.
    if carriers[attacker] or hostages[attacker] then return true end
    if not target or not (carriers[target] or hostages[target]) then return false end
    local def = UnitDefs[Spring.GetUnitDefID(attacker)]
    local weapon = def and def.weapons[weaponNum]
    return api.IsProtected(target, Spring.GetUnitTeam(attacker), weapon and weapon.weaponDef)
end

-- Every scripted speed change composes with this factor, including cloak and stun cleanup.
function api.AdjustSpeed(id, factor)
    local state = carriers[id]
    if not state then return factor end
    state.baseSpeed = factor
    return factor * config.speedFactor
end

local function refresh(id)
    local state = carriers[id]
    Spring.SetUnitRulesParam(id, "human_shield_hostage", state and state.civilian or 0, visibility)
    Spring.SetUnitRulesParam(id, "human_shield_speed_factor", state and config.speedFactor or 1, visibility)
    local take = Spring.FindUnitCmdDesc(id, TAKE)
    if take then
        Spring.EditUnitCmdDesc(id, take, {
            hidden = state ~= nil,
            disabled = state ~= nil or not carrierReady(id) or attachmentPiece(id) == nil,
        })
    end
    local release = Spring.FindUnitCmdDesc(id, RELEASE)
    if release then Spring.EditUnitCmdDesc(id, release, {hidden = state == nil, disabled = state == nil}) end
end

local function release(id, reason)
    local state = carriers[id]
    if not state then return end
    pendingFireOrders[id] = nil
    carriers[id], hostages[state.civilian] = nil, nil
    if next(carriers) == nil then gadgetHandler:RemoveCallIn("AllowWeaponTarget") end
    local civilian = state.civilian
    -- UnitDestroyed precedes the dying civilian's animation. Detach immediately
    -- even while that valid engine object is already marked dead.
    if Spring.ValidUnitID(civilian) and Spring.GetUnitTransporter(civilian) == id then
        Spring.UnitDetach(civilian)
    end
    if alive(civilian) then
        local x, _, z = Spring.GetUnitPosition(civilian)
        if x then Spring.SetUnitPosition(civilian, x, z) end
        Spring.SetUnitRulesParam(civilian, "human_shield_carrier", 0, visibility)
        Spring.SetUnitBlocking(civilian, unpack(state.blocking, 1, 7))
        callScript(civilian, "setHumanShieldCarrier", nil, reason)
    end
    if alive(id) then
        callScript(id, "setHumanShieldActive", false)
        refresh(id)
        setSpeedEnv(id, state.baseSpeed or 1)
    end
end
api.Release = release

local function canTake(id, civilian)
    if not carrierReady(id) or carriers[id] or attachmentPiece(id) == nil then return false end
    if not alive(civilian) or Spring.GetUnitTeam(civilian) ~= gaia
        or not civilianDefs[Spring.GetUnitDefID(civilian)] or hostages[civilian]
        or Spring.GetUnitTransporter(civilian) or detained(civilian) then return false end
    if GG.DisguiseCivilianFor and GG.DisguiseCivilianFor[civilian] then return false end
    local los = Spring.GetUnitLosState(civilian, Spring.GetUnitAllyTeam(id))
    if not los or not los.los then return false end
    return callScript(civilian, "canBeHumanShield") == true
end

local function take(id, civilian)
    local anchor = attachmentPiece(id)
    if anchor == nil then return false end
    local state = {
        civilian = civilian,
        blocking = {Spring.GetUnitBlocking(civilian)},
        baseSpeed = 1,
    }
    if GG.CivilianLife then GG.CivilianLife:Interrupt(civilian) end
    Spring.GiveOrderToUnit(civilian, CMD.STOP, {}, {})
    if callScript(civilian, "setHumanShieldCarrier", id) ~= true then return false end
    carriers[id], hostages[civilian] = state, id
    Spring.UnitAttach(id, civilian, anchor, true)
    if Spring.GetUnitTransporter(civilian) ~= id then
        release(id)
        return false
    end
    -- Avoid new targeting callbacks before anyone has used the ability. Watch
    -- flags are shared with other gadgets, so never clear somebody else's flag.
    if not targetWatchesRegistered then
        for weaponDefID in pairs(WeaponDefs) do
            if Script.SetWatchAllowTarget then Script.SetWatchAllowTarget(weaponDefID, true)
            else Script.SetWatchWeapon(weaponDefID, true) end
        end
        targetWatchesRegistered = true
    end
    gadgetHandler:UpdateCallIn("AllowWeaponTarget")
    -- Sniper shots must reach the operative instead of colliding with the captive.
    Spring.SetUnitBlocking(civilian, false, false, false, false, false, false, false)
    Spring.SetUnitRulesParam(civilian, "human_shield_carrier", id, visibility)
    -- BlockShot is consulted at burst start, not for every remaining salvo
    -- round. Cancel an in-progress burst without changing reload or ammo costs.
    for weaponNum in ipairs(UnitDefs[Spring.GetUnitDefID(id)].weapons or {}) do
        Spring.SetUnitWeaponState(id, weaponNum, {salvoLeft = 0})
    end
    Spring.SetUnitCloak(id, false)
    callScript(id, "setHumanShieldActive", true)
    setSpeedEnv(id, 1)
    refresh(id)
    return true
end

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function validFireTarget(cmd, params)
    if #params == 1 then return alive(params[1]) end
    if #params ~= 3 and not (cmd == CMD.AREA_ATTACK and #params == 4) then return false end
    for _, value in ipairs(params) do if not finite(value) then return false end end
    return #params ~= 4 or params[4] >= 0
end

local function allowed(id, defID, team, cmd, params)
    if hostages[id] then return false end
    if cmd == TAKE then return #params == 1 and canTake(id, params[1]) end
    if cmd == RELEASE then return eligibleCarrier(id) and carriers[id] ~= nil and #params == 0 end
    if carriers[id] and fireCommands[cmd] and not validFireTarget(cmd, params) then return false end
    if #params == 1 and api.IsProtected(params[1], team, nil) then
        if cmd == CMD_INVESTIGATE then return false end
        if fireCommands[cmd] then return counterUnits[defID] == true end
    end
    return true
end

local function unpackOrder(cmd, params, options)
    if cmd ~= CMD.INSERT then return cmd, params, options end
    if #params < 3 then return nil end
    local inserted = {}
    for i = 4, #params do inserted[#inserted + 1] = params[i] end
    return params[2], inserted, params[3]
end

function gadget:AllowCommand(id, defID, team, cmd, params)
    cmd, params = unpackOrder(cmd, params)
    if not cmd then return false end
    return allowed(id, defID, team, cmd, params)
end

local function internalOrder(options)
    if type(options) == "table" then
        if options.internal then return true end
        options = options.coded
    end
    local flag = CMD.OPT_INTERNAL
    return type(options) == "number" and flag ~= nil and options % (flag * 2) >= flag
end

function gadget:UnitCommand(id, defID, team, cmd, params, options)
    local state = carriers[id]
    if not state or internalOrder(options) then return end
    cmd, params, options = unpackOrder(cmd, params, options)
    if not cmd or internalOrder(options) then return end
    -- UnitCommand follows the Lua vetoes but precedes native validation and
    -- insertion. Wait for a new queue tag so rejected commands, invalid insert
    -- tags and shift-click cancellation cannot execute a hostage.
    if fireCommands[cmd] and validFireTarget(cmd, params) then
        local previousTags, target = {}, {}
        for _, order in ipairs(Spring.GetUnitCommands(id, -1) or {}) do
            if order.tag then previousTags[order.tag] = true end
        end
        for i, value in ipairs(params) do target[i] = value end
        local pending = pendingFireOrders[id] or {}
        pending[#pending + 1] = {state = state, command = cmd, target = target, previousTags = previousTags}
        pendingFireOrders[id] = pending
    elseif cmd == CMD.CLOAK and params[1] == 1 then
        release(id)
    end
end

local function matchesFireOrder(pending, order)
    if order.id ~= pending.command or not order.tag or pending.previousTags[order.tag] then return false end
    local target, params = pending.target, order.params or {}
    if #target == 1 then return #params == 1 and params[1] == target[1] end
    -- The native command parser may replace ground Y with terrain elevation.
    return #params >= 3 and params[1] == target[1] and params[3] == target[3]
        and (#target ~= 4 or params[4] == target[4])
end

local function resolveFireOrders()
    for id, pending in pairs(pendingFireOrders) do
        pendingFireOrders[id] = nil
        local queue = Spring.GetUnitCommands(id, -1) or {}
        local execute = false
        for _, candidate in ipairs(pending) do
            if carriers[id] == candidate.state and api.HasShield(id) and carrierReady(id) then
                for _, order in ipairs(queue) do
                    if matchesFireOrder(candidate, order) then execute = true; break end
                end
            end
            if execute then break end
        end
        if execute then
            local civilian = carriers[id].civilian
            Spring.DestroyUnit(civilian, false, false, id)
            release(id)
        end
    end
end

function gadget:CommandFallback(id, defID, team, cmd, params)
    if cmd == RELEASE then
        release(id)
        return true, true
    end
    if cmd ~= TAKE then return false end
    local civilian = params[1]
    if #params ~= 1 or not canTake(id, civilian) then
        Spring.ClearUnitGoal(id)
        return true, true
    end
    local x, y, z = Spring.GetUnitPosition(id)
    local tx, ty, tz = Spring.GetUnitPosition(civilian)
    if not x or not tx then return true, true end
    if (x-tx)^2 + (y-ty)^2 + (z-tz)^2 > config.takeRange^2 then
        Spring.SetUnitMoveGoal(id, tx, ty, tz, config.takeRange * 0.75)
        return true, false
    end
    Spring.ClearUnitGoal(id)
    take(id, civilian)
    return true, true
end

function gadget:AllowWeaponTarget(attacker, target, weaponNum, weaponDefID, priority)
    if carriers[attacker] or hostages[attacker] then return false, priority end
    if not (carriers[target] or hostages[target]) then return true, priority end
    return not api.IsProtected(target, Spring.GetUnitTeam(attacker), weaponDefID), priority
end

function gadget:UnitPreDamaged(id, defID, team, damage, paralyzer, weaponDefID,
    projectileID, attackerID, attackerDefID, attackerTeam)
    attackerTeam = attackerTeam or (attackerID and Spring.GetUnitTeam(attackerID))
    if api.IsProtected(id, attackerTeam, weaponDefID) then return 0, 0 end
end

local function updateCommands(id)
    if not eligibleCarrier(id) then
        local take = Spring.FindUnitCmdDesc(id, TAKE)
        if take then Spring.RemoveUnitCmdDesc(id, take) end
        local releaseCommand = Spring.FindUnitCmdDesc(id, RELEASE)
        if releaseCommand then Spring.RemoveUnitCmdDesc(id, releaseCommand) end
        return
    end
    if not Spring.FindUnitCmdDesc(id, TAKE) then
        Spring.InsertUnitCmdDesc(id, {
            id = TAKE, type = CMDTYPE.ICON_UNIT, name = "Human Shield", action = "humanshield",
            cursor = "HumanShield", texture = "luaui/images/commands/human_shield.png",
            tooltip = "Take a civilian hostage. Move at 60% speed; sniper weapons can hit you and melee lets the hostage escape. Aim mode keeps the hostage; a fire order kills them. No disguise, building, parachuting or rooftops. Cars remain vulnerable.",
        })
    end
    if not Spring.FindUnitCmdDesc(id, RELEASE) then
        Spring.InsertUnitCmdDesc(id, {
            id = RELEASE, type = CMDTYPE.ICON, name = "Release Hostage", action = "releasehostage",
            cursor = "HumanShield", texture = "luaui/images/commands/human_shield.png",
            tooltip = "Release the civilian and restore normal movement and vulnerability.",
        })
    end
    refresh(id)
end

function gadget:UnitCreated(id, defID)
    if not carrierDefs[defID] then return end
    operativeUnits[id] = true
    updateCommands(id)
end

function gadget:Initialize()
    GG.HumanShield = api
    gadgetHandler:RegisterCMDID(TAKE)
    gadgetHandler:RegisterCMDID(RELEASE)
    gadgetHandler:RemoveCallIn("AllowWeaponTarget")
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id, Spring.GetUnitDefID(id)) end
end

function gadget:GameFrame(frame)
    resolveFireOrders()
    if frame % 5 ~= 0 then return end
    for id, state in pairs(carriers) do
        if not api.HasShield(id) or not carrierReady(id)
            or Spring.GetUnitTeam(state.civilian) ~= gaia then
            release(id, releaseReason(id))
        else
            Spring.SetUnitCloak(id, false)
        end
    end
    if frame % 15 == 0 then
        for id in pairs(operativeUnits) do updateCommands(id) end
    end
end

function gadget:UnitDestroyed(id)
    release(hostages[id] or id)
    operativeUnits[id] = nil
end

function gadget:UnitTaken(id)
    release(hostages[id] or id)
end

function gadget:UnitGiven(id, defID)
    release(hostages[id] or id)
    self:UnitCreated(id, defID)
end

function gadget:UnitLoaded(id)
    if carriers[id] and not api.IsTransportAllowed(id) then release(id, releaseReason(id)) end
end

function gadget:UnitStunned(id, defID, team, stunned)
    if stunned then release(id, releaseReason(id)) end
end

function gadget:UnitCloaked(id)
    -- Forced cloak transitions outside the normal request loop also end a hold.
    release(id)
end

function gadget:Shutdown()
    local ids = {}
    for id in pairs(carriers) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do release(id) end
    if GG.HumanShield == api then GG.HumanShield = nil end
end
