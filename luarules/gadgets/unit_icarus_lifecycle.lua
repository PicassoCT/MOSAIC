function gadget:GetInfo()
    return {
        name = "Icarus lifecycle events",
        desc = "Forward native Icarus weapon and command events to its unit script",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 0,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

local icarusDef = UnitDefNames.air_plane_artillery
local bombDef = WeaponDefNames.icarusglidebomb
if not icarusDef or not bombDef then return false end
local icarusDefID, bombDefID = icarusDef.id, bombDef.id
local projectileOwners, ownerProjectiles = {}, {}
local destroying = {}

local function IsIcarus(unitID, unitDefID)
    return unitID and (unitDefID or Spring.GetUnitDefID(unitID)) == icarusDefID
end

local function CallScript(unitID, name, ...)
    local env = Spring.UnitScript.GetScriptEnv(unitID)
    local handler = env and env[name]
    if type(handler) == "function" then
        -- Event callbacks cannot yield. The unit-script handlers start their
        -- own deferred threads for animation, queue refresh and blast grace.
        Spring.UnitScript.CallAsUnit(unitID, handler, ...)
    end
end

function gadget:Initialize()
    Script.SetWatchWeapon(bombDefID, true)
    -- No initialization scan: ProjectileDestroyed can recover an existing
    -- bomb's owner directly after a relay reload. The unit script also retains
    -- its finite cleanup deadline if an event is missed entirely.
end

function gadget:ProjectileCreated(projectileID, ownerID, weaponDefID)
    weaponDefID = weaponDefID or Spring.GetProjectileDefID(projectileID)
    if weaponDefID ~= bombDefID or not IsIcarus(ownerID) then return end
    local previous = ownerProjectiles[ownerID]
    if previous and previous ~= projectileID then
        -- Icarus releases once. Do not leave an obsolete owner mapping behind
        -- if another source nevertheless creates a second projectile for it.
        projectileOwners[previous] = nil
    end
    projectileOwners[projectileID] = ownerID
    ownerProjectiles[ownerID] = projectileID
    CallScript(ownerID, "IcarusProjectileCreated", projectileID)
end

function gadget:ProjectileDestroyed(projectileID)
    if destroying[projectileID] then return end
    local ownerID = projectileOwners[projectileID]
    if not ownerID then
        -- Recoil emits this before removing the projectile, including after
        -- a gadget reload. Recover only an already released Icarus carrier;
        -- never replay creation or reset its release/cleanup deadline.
        if Spring.GetProjectileDefID(projectileID) ~= bombDefID then return end
        ownerID = Spring.GetProjectileOwnerID(projectileID)
        if not IsIcarus(ownerID)
            or Spring.GetUnitRulesParam(ownerID, "icarus_released") ~= 1
            or (ownerProjectiles[ownerID] and ownerProjectiles[ownerID] ~= projectileID) then
            return
        end
    end
    projectileOwners[projectileID] = nil
    if ownerProjectiles[ownerID] == projectileID then ownerProjectiles[ownerID] = nil end
    destroying[projectileID] = true
    if IsIcarus(ownerID) then CallScript(ownerID, "IcarusProjectileDestroyed", projectileID) end
    destroying[projectileID] = nil
end

local function CommandChanged(unitID, unitDefID)
    if IsIcarus(unitID, unitDefID) then CallScript(unitID, "IcarusCommandChanged") end
end

function gadget:UnitCommand(unitID, unitDefID)
    -- UnitCommand runs before the engine changes its queue. The script must
    -- coalesce this notification and read the queue on a later frame.
    CommandChanged(unitID, unitDefID)
end

function gadget:UnitCmdDone(unitID, unitDefID)
    CommandChanged(unitID, unitDefID)
end

function gadget:UnitIdle(unitID, unitDefID)
    CommandChanged(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID)
    local projectileID = ownerProjectiles[unitID]
    if projectileID then projectileOwners[projectileID] = nil end
    ownerProjectiles[unitID] = nil
    -- An already released bomb continues its native ballistic flight even
    -- when another system forcibly removes its owner.
end

-- No GameFrame, movement calls, command polling, or global-watch shutdown:
-- other effect gadgets share this weapon's projectile notifications.
