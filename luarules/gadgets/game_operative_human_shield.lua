function gadget:GetInfo()
    return {
        name = "Operative human shield",
        desc = "Propagators hold civilian hostages; Protagon must use sniper weapons",
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
local propagatorDef = UnitDefNames.operativepropagator.id
local gaia = Spring.GetGaiaTeamID()
local civilianDefs = getCultureUnitModelTypes("international", "civilian", UnitDefs)
local carriers, hostages = {}, {}
local sniperWeapons, sniperUnits, factionStarters = {}, {}, {}
local visibility = {inlos = true}
local api = {}
local targetWatchesRegistered = false

for name in pairs(config.sniperWeapons) do
    local def = WeaponDefNames[name]
    if def then sniperWeapons[def.id] = true end
end
for defID, def in pairs(UnitDefs) do
    for _, weapon in ipairs(def.weapons or {}) do
        if sniperWeapons[weapon.weaponDef] then sniperUnits[defID] = true end
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

local function detained(id)
    if GG.CloseCombatInvolved and GG.CloseCombatInvolved[id] then return true end
    local interrogation = GG.InterrogationTable and GG.InterrogationTable[id]
    if interrogation then
        for _, active in pairs(interrogation) do
            if active then return true end
        end
    end
    local stunned, _, building = Spring.GetUnitIsStunned(id)
    return stunned or building
end

function api.HasShield(id)
    local state = carriers[id]
    return state ~= nil and alive(state.civilian)
        and Spring.GetUnitTransporter(state.civilian) == id
end

function api.IsHostage(id)
    return hostages[id] ~= nil
end

function api.IsProtected(target, attackerTeam, weaponDefID)
    if sniperWeapons[weaponDefID] then return false end
    local carrier = hostages[target] or target
    if not api.HasShield(carrier) or sideOf(attackerTeam) ~= "protagon" then return false end
    local team = Spring.GetUnitTeam(carrier)
    return team ~= nil and not Spring.AreTeamsAllied(team, attackerTeam)
end

function api.BlockShot(attacker, weaponNum, target)
    if hostages[attacker] then return true end
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
    if take then Spring.EditUnitCmdDesc(id, take, {hidden = state ~= nil, disabled = state ~= nil}) end
    local release = Spring.FindUnitCmdDesc(id, RELEASE)
    if release then Spring.EditUnitCmdDesc(id, release, {hidden = state == nil, disabled = state == nil}) end
end

local function release(id)
    local state = carriers[id]
    if not state then return end
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
        callScript(civilian, "setHumanShieldCarrier", nil)
    end
    if alive(id) then
        callScript(id, "setHumanShieldActive", false)
        refresh(id)
        setSpeedEnv(id, state.baseSpeed or 1)
    end
end
api.Release = release

local function canTake(id, civilian)
    if not alive(id) or Spring.GetUnitDefID(id) ~= propagatorDef or carriers[id]
        or Spring.GetUnitTransporter(id) or detained(id) then return false end
    if Spring.GetUnitRulesParam(id, "betrayal_defector") == 1
        or Spring.GetUnitRulesParam(id, "betrayal_pending") == 1 then return false end
    if not alive(civilian) or Spring.GetUnitTeam(civilian) ~= gaia
        or not civilianDefs[Spring.GetUnitDefID(civilian)] or hostages[civilian]
        or Spring.GetUnitTransporter(civilian) or detained(civilian) then return false end
    if GG.DisguiseCivilianFor and GG.DisguiseCivilianFor[civilian] then return false end
    local los = Spring.GetUnitLosState(civilian, Spring.GetUnitAllyTeam(id))
    if not los or not los.los then return false end
    return callScript(civilian, "canBeHumanShield") == true
end

local function take(id, civilian)
    local pieces = Spring.GetUnitPieceMap(id) or {}
    if not pieces.center then return false end
    local state = {
        civilian = civilian,
        blocking = {Spring.GetUnitBlocking(civilian)},
        baseSpeed = 1,
    }
    if GG.CivilianLife then GG.CivilianLife:Interrupt(civilian) end
    Spring.GiveOrderToUnit(civilian, CMD.STOP, {}, {})
    if callScript(civilian, "setHumanShieldCarrier", id) ~= true then return false end
    carriers[id], hostages[civilian] = state, id
    Spring.UnitAttach(id, civilian, pieces.center, true)
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
    Spring.SetUnitCloak(id, false)
    callScript(id, "setHumanShieldActive", true)
    setSpeedEnv(id, 1)
    refresh(id)
    return true
end

local function allowed(id, defID, team, cmd, params)
    if hostages[id] then return false end
    if cmd == TAKE then return #params == 1 and canTake(id, params[1]) end
    if cmd == RELEASE then return defID == propagatorDef and carriers[id] ~= nil and #params == 0 end
    if #params == 1 and api.IsProtected(params[1], team, nil) then
        if cmd == CMD_INVESTIGATE then return false end
        if cmd == CMD.ATTACK or cmd == CMD.DGUN then return sniperUnits[defID] == true end
    end
    return true
end

function gadget:AllowCommand(id, defID, team, cmd, params)
    if cmd == CMD.INSERT then
        if #params < 3 then return false end
        local inserted = {}
        for i = 4, #params do inserted[#inserted + 1] = params[i] end
        return allowed(id, defID, team, params[2], inserted)
    end
    return allowed(id, defID, team, cmd, params)
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
    if not (carriers[target] or hostages[target]) then return true, priority end
    return not api.IsProtected(target, Spring.GetUnitTeam(attacker), weaponDefID), priority
end

function gadget:UnitPreDamaged(id, defID, team, damage, paralyzer, weaponDefID,
    projectileID, attackerID, attackerDefID, attackerTeam)
    attackerTeam = attackerTeam or (attackerID and Spring.GetUnitTeam(attackerID))
    if api.IsProtected(id, attackerTeam, weaponDefID) then return 0, 0 end
end

function gadget:UnitCreated(id, defID)
    if defID ~= propagatorDef then return end
    if not Spring.FindUnitCmdDesc(id, TAKE) then
        Spring.InsertUnitCmdDesc(id, {
            id = TAKE, type = CMDTYPE.ICON_UNIT, name = "Human Shield", action = "humanshield",
            cursor = "HumanShield", texture = "luaui/images/commands/human_shield.png",
            tooltip = "Take a civilian hostage. Move at 60% speed; Protagon cannot attack or interrogate you except with sniper weapons. Carrying a hostage reveals you.",
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

function gadget:Initialize()
    GG.HumanShield = api
    gadgetHandler:RegisterCMDID(TAKE)
    gadgetHandler:RegisterCMDID(RELEASE)
    gadgetHandler:RemoveCallIn("AllowWeaponTarget")
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id, Spring.GetUnitDefID(id)) end
end

function gadget:GameFrame(frame)
    if frame % 5 ~= 0 then return end
    for id, state in pairs(carriers) do
        if not alive(id) or not api.HasShield(id) or Spring.GetUnitTransporter(id)
            or Spring.GetUnitTeam(state.civilian) ~= gaia then
            release(id)
        else
            Spring.SetUnitCloak(id, false)
        end
    end
end

function gadget:UnitDestroyed(id)
    release(hostages[id] or id)
end

function gadget:UnitTaken(id)
    release(hostages[id] or id)
end

function gadget:UnitGiven(id, defID)
    release(hostages[id] or id)
    self:UnitCreated(id, defID)
end

function gadget:Shutdown()
    local ids = {}
    for id in pairs(carriers) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do release(id) end
    if GG.HumanShield == api then GG.HumanShield = nil end
end
