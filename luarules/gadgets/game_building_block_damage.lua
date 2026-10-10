function gadget:GetInfo()
    return {
        name = "Procedural building block damage",
        desc = "Dispatches actual health damage to generated building supports",
        author = "MOSAIC contributors",
        layer = 0,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

local eligible = {}
local active = {}
local UPDATE_FRAMES = 6 -- 0.2 seconds at the simulation's 30 Hz
local MAX_IMPACTS = 8
local fxInterval, dustLeft = -1, 0
local function allowEffect(kind)
    local interval = math.floor(Spring.GetGameFrame() / UPDATE_FRAMES)
    if interval ~= fxInterval then
        fxInterval, dustLeft = interval, 16
    end
    if kind == "dust" and dustLeft > 0 then
        dustLeft = dustLeft - 1
        return true
    end
    return false
end

function gadget:Initialize()
    GG.AllowBuildingBlockDamageEffect = allowEffect
end

function gadget:Shutdown()
    if GG.AllowBuildingBlockDamageEffect == allowEffect then
        GG.AllowBuildingBlockDamageEffect = nil
    end
end
for id, def in pairs(UnitDefs) do
    local cp = def.customParams or {}
    if def.name == "house_asian0" or def.name == "house_western0"
        or def.name == "house_arab0" or cp.house_asian_base == "house_asian0" then
        eligible[id] = true
    end
end

function gadget:UnitDamaged(id, defID, team, damage, paralyzer, weaponID, projectileID, attackerID)
    if not eligible[defID] or paralyzer or damage <= 0 then return end
    local hp, maxHP = Spring.GetUnitHealth(id)
    if not hp or hp <= 0 or hp >= maxHP * 0.5 then return end
    local hitPiece, frame = Spring.GetUnitLastAttackedPiece(id)
    if frame ~= Spring.GetGameFrame() then hitPiece = nil end
    local x, y, z
    if projectileID and projectileID >= 0 then x, y, z = Spring.GetProjectilePosition(projectileID) end
    -- Most houses use a whole-unit collision box, so an exact piece hit is not
    -- available. Prefer the impact projectile, then the attacker-facing facade.
    if not x and attackerID then x, y, z = Spring.GetUnitPosition(attackerID) end
    local hits = active[id]
    if not hits then hits = {}; active[id] = hits end
    -- Bound queue size even for rapid-fire area damage. Nearby impacts merge;
    -- overflow merges into the nearest existing impact, preserving damage.
    local bucket, bestDistance
    for _, hit in ipairs(hits) do
        local d = x and hit.x and ((x-hit.x)^2 + (y-hit.y)^2 + (z-hit.z)^2) or math.huge
        if hitPiece then
            d = hit.piece == hitPiece and 0 or math.huge
        elseif not x and not hit.x then d = 0 end
        if not bestDistance or d < bestDistance then bucket, bestDistance = hit, d end
    end
    if not bucket or (#hits < MAX_IMPACTS and bestDistance > 64) then
        bucket = {damage = 0, piece = hitPiece, x = x, y = y, z = z}
        hits[#hits + 1] = bucket
    end
    bucket.damage = bucket.damage + math.min(damage, maxHP * 0.5 - hp)
end

function gadget:GameFrame(frame)
    if frame % UPDATE_FRAMES ~= 0 or not next(active) then return end
    local ids = {}
    for id in pairs(active) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local hits = active[id]
        active[id] = nil
        local env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.BuildingBlockDamaged and not Spring.GetUnitIsDead(id) then
            local waiting = Spring.UnitScript.CallAsUnit(id, env.BuildingBlockDamaged, hits, frame)
            if waiting then active[id] = {} end
        end
    end
end

function gadget:UnitDestroyed(id)
    active[id] = nil
end
