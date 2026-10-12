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

local destructionTrace = VFS.Include('scripts/lib_building_destruction_trace.lua')
local trace = destructionTrace.Log
trace(nil, 'damage_gadget_load_begin')
VFS.Include('scripts/lib_mosaic.lua')
local blockDamageableHouseTypeTable = getStructuralBuildingTypeTable(UnitDefs)
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
    local eligibleCount = 0
    for _ in pairs(blockDamageableHouseTypeTable) do eligibleCount = eligibleCount + 1 end
    trace(nil, 'damage_gadget_ready', {eligible_types=eligibleCount,
        update_frames=UPDATE_FRAMES, max_impacts=MAX_IMPACTS, repeated_trace_frames=30})
end

function gadget:Shutdown()
    trace(nil, 'damage_gadget_shutdown')
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
    trace(id, 'damage_received', {def=defID, damage=damage,
        paralyzer=paralyzer, weapon=weaponID, projectile=projectileID, attacker=attackerID}, 30)
    if paralyzer or damage <= 0 then
        trace(id, 'damage_skipped', {reason=paralyzer and 'paralyzer' or 'nonpositive_damage', damage=damage}, 30)
        return
    end

    local hp, maxHP = spGetUnitHealth(id)
    if not hp or not maxHP or hp <= 0 or hp >= maxHP * 0.5 then
        local reason = not hp and 'health_unavailable' or not maxHP and 'max_health_unavailable'
            or hp <= 0 and 'lethal_damage' or 'at_or_above_half_health'
        trace(id, 'damage_skipped', {reason=reason, hp=hp, max_hp=maxHP, damage=damage}, 30)
        return
    end
    trace(id, 'damage_accepted', {damage=damage, hp=hp, max_hp=maxHP}, 30)
    local hitPiece, frame = spGetUnitLastAttackedPiece(id)
    if frame ~= spGetGameFrame() then
        trace(id, 'hit_piece_discarded', {reason='stale_frame', piece=hitPiece, reported_frame=frame}, 30)
        hitPiece = nil
    end
    local x, y, z
    local positionSource = 'none'
    if projectileID and projectileID >= 0 then
        x, y, z = spGetProjectilePosition(projectileID)
        if x then positionSource = 'projectile' end
    end
    -- Most houses use a whole-unit collision box, so an exact piece hit is not
    -- available. Prefer the impact projectile, then the attacker-facing facade.
    if not x and attackerID then
        x, y, z = spGetUnitPosition(attackerID)
        if x then positionSource = 'attacker' end
    end
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
    trace(id, 'damage_queued', {piece=hitPiece, bucket_piece=bucket.piece,
        buckets=#hits, bucket_damage=bucket.damage, admitted_damage=math.min(damage, maxHP * 0.5 - hp),
        position_source=positionSource, x=x, y=y, z=z, merge_distance_squared=bestDistance}, 30)
end

function gadget:GameFrame(frame)
    if frame % UPDATE_FRAMES ~= 0 or not next(active) then return end
    local ids = {}
    for id in pairs(active) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local hits = active[id]
        active[id] = nil
        trace(id, 'damage_dispatch_begin', {buckets=#hits}, 30)
        local env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.BuildingBlockDamaged and not Spring.GetUnitIsDead(id) then
            local waiting = Spring.UnitScript.CallAsUnit(id, env.BuildingBlockDamaged, hits, frame)
            trace(id, 'damage_dispatch_complete', {buckets=#hits, waiting=not not waiting}, 30)
            if waiting then active[id] = {} end
        else
            local reason = not env and 'script_environment_missing'
                or not env.BuildingBlockDamaged and 'callback_missing' or 'unit_dead'
            trace(id, 'damage_dispatch_skipped', {reason=reason, discarded_buckets=#hits}, 30)
        end
    end
end

function gadget:UnitCreated(id)
    destructionTrace.Forget(id)
end

function gadget:UnitDestroyed(id, defID)
    local hits = active[id]
    if hits or blockDamageableHouseTypeTable[defID] then
        trace(id, 'damage_unit_destroyed', {discarded_buckets=hits and #hits or 0}, 30)
    end
    active[id] = nil
    if GG.BuildingDamageAnchor then GG.BuildingDamageAnchor[id] = nil end
    destructionTrace.Forget(id)
end
