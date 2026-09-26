function gadget:GetInfo()
    return {
        name = "Aircraft crashing",
        desc = "Disabled aircraft fall using the engine's plane and gunship crash physics",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 1000, -- Decide after the damage modifiers.
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end

local crashable = {}
for id, def in pairs(UnitDefs) do
    -- Opted in through AIRCRAFT/Aero/VTOL inheritance: flying icons and orbit
    -- units also have canFly, but must not become crashing aircraft.
    if def.canFly and tonumber((def.customParams or {}).crashable) == 1 then
        crashable[id] = true
    end
end

local crashing, selfDestructing = {}, {}
local timeoutFrames = 15 * (Game.gameSpeed or 30)
local ruleName = "aircraft_crash_deadline"

local function DisableAircraft(unitID, unitDefID, deadline)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitCloak(unitID, false)
    for _, sensor in ipairs({"los", "airLos", "radar", "sonar"}) do
        Spring.SetUnitSensorRadius(unitID, sensor, 0)
    end
    for weapon = 1, #UnitDefs[unitDefID].weapons do
        Spring.SetUnitWeaponState(unitID, weapon, {
            reloadState = deadline + timeoutFrames,
            reloadTime = 99999,
            range = 0,
            aimReady = 0,
            salvoLeft = 0,
            nextSalvo = deadline + timeoutFrames,
        })
    end
    local env = Spring.UnitScript.GetScriptEnv(unitID)
    if env and env.BeginAircraftCrash then
        Spring.UnitScript.CallAsUnit(unitID, env.BeginAircraftCrash)
    end
end

local function BeginCrash(unitID, attackerID)
    if crashing[unitID] then return true end
    local unitDefID = Spring.GetUnitDefID(unitID)
    if not crashable[unitDefID] or Spring.GetUnitIsDead(unitID) then return false end
    local health, _, _, _, build = Spring.GetUnitHealth(unitID)
    if not health or (build and build < 1) or Spring.GetUnitTransporter(unitID) then
        return false
    end
    local x, y, z = Spring.GetUnitPosition(unitID)
    if not x or y <= math.max(0, Spring.GetGroundHeight(x, z)) + 5 then return false end

    local scripted = Spring.MoveCtrl.GetTag(unitID) ~= nil
    local move = Spring.GetUnitMoveTypeData(unitID)
    if not scripted and (not move or move.aircraftState == "landed") then return false end
    -- E.g. an artillery drone can be shot during its scripted launch.
    if scripted then Spring.MoveCtrl.Disable(unitID) end
    local started = Spring.SetUnitCrashing and Spring.SetUnitCrashing(unitID, true)
    if not started then
        -- Spring 105 compatibility, also covering a scripted airborne launch
        -- whose underlying air move type still considers itself landed.
        Spring.SetUnitCOBValue(unitID, COB.CRASHING, 1)
    end
    move = Spring.GetUnitMoveTypeData(unitID)
    if not move or move.aircraftState ~= "crashing" then return false end

    if (Spring.GetUnitSelfDTime(unitID) or 0) > 0 then
        Spring.GiveOrderToUnit(unitID, CMD.SELFD, {}, 0) -- cancel the countdown
    end
    local deadline = Spring.GetGameFrame() + timeoutFrames
    crashing[unitID] = {deadline = deadline, attacker = attackerID}
    selfDestructing[unitID] = nil
    Spring.SetUnitRulesParam(unitID, ruleName, deadline, {private = true})
    DisableAircraft(unitID, unitDefID, deadline)
    return true
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
        weaponDefID, projectileID, attackerID)
    if crashing[unitID] then return 0, 0 end
    if not crashable[unitDefID] or paralyzer or damage <= 0 then return damage, 1 end
    local health = Spring.GetUnitHealth(unitID)
    if health and damage >= health and BeginCrash(unitID, attackerID) then
        -- Keep the lethal damage for engine damage/experience accounting.
        -- CUnit::KillUnit defers death while IsCrashing(); the move type runs
        -- ForcedKillUnit on impact, including the existing Killed() script.
        return damage, 0
    end
    return damage, 1
end

function gadget:AllowCommand(unitID)
    return not crashing[unitID]
end

function gadget:AllowUnitBuildStep(builderID, builderTeam, unitID)
    return not crashing[unitID]
end

function gadget:UnitCommand(unitID, unitDefID, unitTeam, cmdID)
    if cmdID == CMD.SELFD and crashable[unitDefID] and not crashing[unitID] then
        selfDestructing[unitID] = true
    end
end

function gadget:GameFrame(frame)
    -- Only watch aircraft with an armed self-destruct, not every flying unit.
    for unitID in pairs(selfDestructing) do
        local countdown = Spring.GetUnitSelfDTime(unitID)
        if not countdown or countdown <= 0 then
            selfDestructing[unitID] = nil
        elseif countdown == 1 and not Spring.GetUnitIsStunned(unitID) then
            BeginCrash(unitID)
        end
    end
    if frame % 5 ~= 0 or not next(crashing) then return end
    -- Bound the lifetime even if an older engine fails to finish an impact.
    -- Collect first; DestroyUnit synchronously calls UnitDestroyed.
    local expired = {}
    for unitID, state in pairs(crashing) do
        if frame >= state.deadline then expired[#expired + 1] = unitID end
    end
    table.sort(expired)
    for _, unitID in ipairs(expired) do
        local state = crashing[unitID]
        if state then
            local attacker = state.attacker
            if attacker and (not Spring.ValidUnitID(attacker) or Spring.GetUnitIsDead(attacker)) then
                attacker = nil
            end
            -- DestroyUnit uses ForcedKillUnit, even while crashing. Do not
            -- reclaim here: the normal impact explosion/wreck must still run.
            Spring.DestroyUnit(unitID, true, false, attacker)
        end
    end
end

function gadget:UnitDestroyed(unitID)
    crashing[unitID] = nil
    selfDestructing[unitID] = nil
end

function gadget:Initialize()
    GG.AircraftCrash = BeginCrash
    for _, unitID in ipairs(Spring.GetAllUnits()) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        if crashable[unitDefID] then
            local move = Spring.GetUnitMoveTypeData(unitID)
            if move and move.aircraftState == "crashing" then
                local deadline = Spring.GetUnitRulesParam(unitID, ruleName)
                    or (Spring.GetGameFrame() + timeoutFrames)
                crashing[unitID] = {deadline = deadline}
                Spring.SetUnitRulesParam(unitID, ruleName, deadline, {private = true})
                DisableAircraft(unitID, unitDefID, deadline)
            elseif (Spring.GetUnitSelfDTime(unitID) or 0) > 0 then
                selfDestructing[unitID] = true
            end
        end
    end
end

function gadget:Shutdown()
    if GG.AircraftCrash == BeginCrash then GG.AircraftCrash = nil end
end
