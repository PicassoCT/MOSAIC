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

VFS.Include('scripts/lib_mosaic.lua')
local blockDamageableHouseTypeTable = getStructuralBuildingTypeTable(UnitDefs)
local damageHealthFraction = getBuildingDamageConfig().healthThreshold
local trace = VFS.Include('luarules/gadgets/include/execution_trace.lua').New('BuildingDestruction')
local active = {}
local UPDATE_FRAMES = 6 -- 0.2 seconds at the simulation's 30 Hz
local MAX_IMPACTS = 8
local fxInterval, dustLeft = -1, 0
local blockDestroyableHouseTypes = getBlockDestroyableHouseTypes(UnitDefs)
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
    local eligible = 0
    for _ in pairs(blockDamageableHouseTypeTable) do eligible = eligible + 1 end
    trace.Log(nil, 0, 'damage_gadget_ready', {trace_version=2, eligible_definitions=eligible,
        update_frames=UPDATE_FRAMES, max_impacts=MAX_IMPACTS})
end

function gadget:Shutdown()
    if GG.AllowBuildingBlockDamageEffect == allowEffect then
        GG.AllowBuildingBlockDamageEffect = nil
    end
end


local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitLastAttackedPiece = Spring.GetUnitLastAttackedPiece
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetUnitPosition = Spring.GetUnitPosition
function gadget:UnitDamaged(id, defID, team, damage, paralyzer, weaponID, projectileID, attackerID)
    if not blockDamageableHouseTypeTable[defID] then return end
    local cycle = spGetGameFrame()
    trace.Log(id, cycle, 'damage_received', {definition=defID, damage=damage,
        paralyzer=paralyzer, weapon=weaponID, projectile=projectileID, attacker=attackerID})
    if paralyzer or damage <= 0 then
        trace.Log(id, cycle, 'damage_skipped', {reason=paralyzer and 'paralyzer' or 'nonpositive_damage'})
        return
    end

    local hp, maxHP = spGetUnitHealth(id)
    if not hp or not maxHP or hp <= 0 or hp >= maxHP * damageHealthFraction then
        trace.Log(id, cycle, 'damage_skipped', {hp=hp, max_hp=maxHP,
            reason=(not hp or not maxHP) and 'missing_health' or hp <= 0 and 'lethal_hit' or 'above_damage_threshold'})
        return
    end
    local hitPiece, frame = spGetUnitLastAttackedPiece(id)
    if frame ~= spGetGameFrame() then hitPiece = nil end
    local x, y, z
    if projectileID and projectileID >= 0 then x, y, z = spGetProjectilePosition(projectileID) end
    -- Most houses use a whole-unit collision box, so an exact piece hit is not
    -- available. Prefer the impact projectile, then the attacker-facing facade.
    if not x and attackerID then x, y, z = spGetUnitPosition(attackerID) end
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
    local admitted = math.min(damage, maxHP * damageHealthFraction - hp)
    bucket.damage = bucket.damage + admitted
    trace.Log(id, cycle, 'damage_queued', {hp=hp, max_hp=maxHP, admitted=admitted,
        piece=hitPiece, x=x, y=y, z=z, buckets=#hits, bucket_damage=bucket.damage})
end

function gadget:GameFrame(frame)
    if frame % UPDATE_FRAMES ~= 0 or not next(active) then return end
    local ids = {}
    for id in pairs(active) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local hits = active[id]
        active[id] = nil
        local total = 0
        for index, hit in ipairs(hits) do
            total = total + hit.damage
            trace.Log(id, frame, 'damage_dispatch_impact', {slot=index, piece=hit.piece,
                damage=hit.damage, x=hit.x, y=hit.y, z=hit.z})
        end
        trace.Log(id, frame, 'damage_dispatch_begin', {hits=#hits, total_damage=total})
        local env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.BuildingBlockDamaged and not Spring.GetUnitIsDead(id) then
            local waiting = Spring.UnitScript.CallAsUnit(id, env.BuildingBlockDamaged, hits, frame)
            if waiting then active[id] = {} end
            trace.Log(id, frame, 'damage_dispatch_complete', {waiting=not not waiting})
        else
            trace.Log(id, frame, 'damage_dispatch_skipped',
                {reason=not env and 'no_script_env' or not env.BuildingBlockDamaged and 'no_callback' or 'dead_unit'})
        end
    end
end

function gadget:UnitDestroyed(id)
    if active[id] or (GG.BuildingDamageAnchor and GG.BuildingDamageAnchor[id]) then
        trace.Log(id, spGetGameFrame(), 'damage_tracking_removed', {reason='unit_destroyed'})
    end
    active[id] = nil
    if GG.BuildingDamageAnchor then GG.BuildingDamageAnchor[id] = nil end
    if GG.BuildingDamageEffects then GG.BuildingDamageEffects[id] = nil end
    trace.Forget(id)
end
