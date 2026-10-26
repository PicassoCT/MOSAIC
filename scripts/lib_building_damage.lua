-- Per-building structural damage. No polling, physics units or per-frame scans.
-- The generated grid supplies conservative vertical supports: when one block
-- fails, every block above it in that column fails too (no invented cantilevers).
local M = {}
local unitEnv = _G
local config = VFS.Include('scripts/lib_mosaic.lua',
    setmetatable({MOSAIC_CONFIG_ONLY=true}, {__index=unitEnv})).getBuildingDamageConfig()
local effectsHelper = VFS.Include('scripts/lib_building_damage_effects.lua')
local unitScript = Spring.UnitScript
-- Header-local aliases dispatch to our hooks; bypass those aliases for native
-- commands so a structural move cannot call its own suppression hook.
local nativeShow, nativeHide = unitScript.Show, unitScript.Hide
local nativeMove, nativeTurn, nativeSpin = unitScript.Move, unitScript.Turn, unitScript.Spin
-- All three generators place floor heights on Move axis 2. Use that axis rather
-- than the shared header's y_axis alias, which is 3.
local HEIGHT_MOVE_AXIS = 2
local detached, retained, visible, offsets, rotations, attachments = {}, {}, {}, {}, {}, {}
local blocks, columns, owners, movable = {}, {}, {}, {}
local selected, rooftop, windowPieces, pieceMap
local floorHeight, cellSize, modelScale = 1, 1, 1
local ready, collapsing = false, false
local failures, falling, overloadedPending = {}, {}, false
local fireSlots, activeFires, detachedCount, remnantCount = {}, 0, 0, 0
local effects, activeEffects = {}, 0
local function publishStats()
    if Spring.SetUnitRulesParam then
        Spring.SetUnitRulesParam(unitID, 'building_structural_blocks', #blocks, {public=true})
        Spring.SetUnitRulesParam(unitID, 'building_detached_blocks', detachedCount, {public=true})
        Spring.SetUnitRulesParam(unitID, 'building_remnant_blocks', remnantCount, {public=true})
        Spring.SetUnitRulesParam(unitID, 'building_structural_ready', ready and 1 or 0, {public=true})
    end
end
local function removeBlockFire(p)
    if not fireSlots[p] then return end
    if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID, fireSlots[p]) end
    fireSlots[p] = nil
    activeFires = activeFires - 1
end

local function removeBlockEffect(p)
    removeBlockFire(p)
    if effects[p] then
        effects[p] = nil
        activeEffects = activeEffects - 1
    end
    if activeEffects == 0 and GG.BuildingDamageEffects then
        GG.BuildingDamageEffects[unitID] = nil
    end
    if GG.BuildingDamageAnchor and GG.BuildingDamageAnchor[unitID] == p then
        GG.BuildingDamageAnchor[unitID] = nil
    end
end

local function clearEffects()
    for p in pairs(effects) do removeBlockEffect(p) end
end

local function expireEffects(frame)
    for p, effect in pairs(effects) do
        if not visible[p] or frame >= effect.smokeUntil then
            removeBlockEffect(p)
        elseif frame >= effect.fireUntil then
            removeBlockFire(p)
        end
    end
end

local function lightBlockFire(p, cycle)
    if not visible[p] or effects[p] or activeEffects >= config.maxFires then
        return
    end
    -- A hit creates one finite lifetime. Subsequent ticks and repeated hits on
    -- this anchor cannot extend it; fire and smoke share the same bounded slots.
    local effect = {piece=p, started=cycle, fireUntil=cycle+config.fireLifetimeFrames,
        smokeUntil=cycle+config.smokeLifetimeFrames, visible=true}
    effects[p] = effect
    activeEffects = activeEffects + 1
    GG.BuildingDamageEffects = GG.BuildingDamageEffects or {}
    GG.BuildingDamageEffects[unitID] = effects
    GG.BuildingDamageAnchor = GG.BuildingDamageAnchor or {}
    GG.BuildingDamageAnchor[unitID] = p
    if not GG.SmokeRibbon then
        return
    end
    local slot='block_fire_'..tostring(p)
    local options = effectsHelper.FlameOptions(unitID, p,
        {floorHeight=floorHeight, cellSize=cellSize, modelScale=modelScale})
    options.endFrame, options.fadeFrames = effect.fireUntil, config.effectFadeFrames
    local ok=GG.SmokeRibbon.Set(unitID,slot,p,options)
    if ok then fireSlots[p]=slot;activeFires=activeFires+1 end
end
local FAILURE_DELAY_FRAMES = 6
local FALL_FRAMES = 6
local MAX_BROKEN_COLUMNS_PER_UPDATE = 3
local FLOOR_TIME_MS = 320

-- Construction, day/night switching and piece animations must never resurrect
-- detached geometry. These wrappers belong only to the three procedural scripts.
local function showBuildingPiece(p)
    if not collapsing and not detached[p] then
        visible[p] = true
        return (unitEnv.CloudPieceShow or nativeShow)(p)
    end
end
local function hideBuildingPiece(p)
    -- Retained ruins are frozen geometry. Assembly/day-night threads must not
    -- hide them after their old structural entries have been removed.
    if retained[p] and not collapsing then return end
    visible[p] = nil
    removeBlockEffect(p)
    return (unitEnv.CloudPieceHide or nativeHide)(p)
end

function IsBuildingPieceDetached(p)
    return collapsing or detached[p] == true
end

function IsBuildingPieceVisible(p)
    return not collapsing and visible[p] == true
end

function RegisterBuildingPieceAttachment(p, id)
    if IsBuildingPieceDetached(p) then
        if Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) then
            Spring.DestroyUnit(id, false, true)
        end
        return
    end
    attachments[p] = attachments[p] or {}
    attachments[p][#attachments[p]+1] = id
end

local nativeSetRadiancePiece = SetRadiancePiece
if nativeSetRadiancePiece then
    function SetRadiancePiece(p, on, ...)
        if on and IsBuildingPieceDetached(p) then return end
        return nativeSetRadiancePiece(p, on, ...)
    end
end
local function moveBuildingPiece(p, axis, goal, speed, ...)
    if collapsing or detached[p] then return end
    if axis == HEIGHT_MOVE_AXIS and (not ready or movable[p]) then offsets[p] = goal end
    return nativeMove(p, axis, goal, speed, ...)
end
local function turnBuildingPiece(p, axis, goal, speed, ...)
    if collapsing or detached[p] then return end
    if not ready or movable[p] then
        rotations[p] = rotations[p] or {}
        rotations[p][axis] = goal
    end
    return nativeTurn(p, axis, goal, speed, ...)
end
local function spinBuildingPiece(p, ...)
    if not collapsing and not detached[p] then return nativeSpin(p, ...) end
end

-- Explicit environment writes reach every separately compiled script/include.
-- Plain global aliases also cover callers which do not have a script header.
unitEnv.BuildingDamageShow, unitEnv.BuildingDamageHide = showBuildingPiece, hideBuildingPiece
unitEnv.BuildingDamageMove, unitEnv.BuildingDamageTurn, unitEnv.BuildingDamageSpin =
    moveBuildingPiece, turnBuildingPiece, spinBuildingPiece
unitEnv.Show, unitEnv.Hide = showBuildingPiece, hideBuildingPiece
unitEnv.Move, unitEnv.Turn, unitEnv.Spin = moveBuildingPiece, turnBuildingPiece, spinBuildingPiece

local function key(x, z)
    return math.floor(x / cellSize + 0.5) .. ":" .. math.floor(z / cellSize + 0.5)
end

local function position(p)
    return Spring.GetUnitPiecePosDir(unitID, p)
end

local function bind(p, block, inherited)
    if owners[p] then return end
    owners[p] = block
    block.pieces[#block.pieces + 1] = p
    if not inherited then
        movable[p] = block
        block.roots[#block.roots+1] = p
    end
    local info = Spring.GetUnitPieceInfo(unitID, p)
    for _, child in ipairs(info and info.children or {}) do
        local childID = type(child) == "number" and child or pieceMap[child]
        if childID then bind(childID, block, true) end
    end
end

function M.initialize(levels, shown, roofs, windows, height, width, scale, cachedPieceMap)
    if ready or collapsing then
        return
    end
    floorHeight, cellSize, modelScale = height, width, scale
    selected, rooftop, windowPieces = shown, roofs, windows
    pieceMap = cachedPieceMap or Spring.GetUnitPieceMap(unitID)
    local worldGrid = {}
    local placements = levels.placements or {}
    local order = {}
    for level in pairs(levels) do
        if type(level) == "number" then order[#order + 1] = level end
    end
    table.sort(order)
    for _, level in ipairs(order) do
        for _, p in ipairs(levels[level]) do
            local at = placements[p]
            if at and not owners[p] then
                local columnKey = key(at.x, at.z)
                local bx, by, bz = position(p)
                local block = {piece = p, level = level, y = at.y,
                    x = bx, worldY = by, z = bz,
                    column = columnKey, pieces = {}, roots = {}, damage = 0}
                local length = math.sqrt(at.x * at.x + at.z * at.z)
                local dx, dz = at.x, at.z
                if length < 0.01 then dx, dz, length = 1, 0, 1 end
                local columnCode = math.floor(at.x / cellSize) + 3 * math.floor(at.z / cellSize)
                local angle = math.rad(3 + (unitID + columnCode) % 3)
                block.leanX, block.leanZ = dz / length * angle, -dx / length * angle
                local wk = key(bx / modelScale, bz / modelScale)
                worldGrid[wk] = worldGrid[wk] or {}
                worldGrid[wk][#worldGrid[wk]+1] = block
                blocks[#blocks + 1] = block
                columns[columnKey] = columns[columnKey] or {}
                local col = columns[columnKey]
                col[#col + 1] = block
                bind(p, block)
            end
        end
    end
    for _, col in pairs(columns) do
        table.sort(col, function(a, b)
            if a.y == b.y then return a.piece < b.piece end
            return a.y < b.y
        end)
    end

    -- Selected independent decorations are attached to the closest block in
    -- their grid column. Use world positions to include authored piece offsets
    -- and the model's import scale; restrict candidates to neighbouring cells.
    for _, p in ipairs(shown) do
        if not owners[p] then
            local x, y, z = position(p)
            if x then
                local lx, lz = x / modelScale, z / modelScale
                local best, distance
                for ox = -1, 1 do for oz = -1, 1 do
                    local col = worldGrid[key(lx + ox * cellSize, lz + oz * cellSize)]
                    for _, block in ipairs(col or {}) do
                        local d = (x-block.x)^2 + (y-block.worldY)^2 + (z-block.z)^2
                        if not distance or d < distance then best, distance = block, d end
                    end
                end end
                if best and distance <= (cellSize * modelScale * 1.5)^2 then
                    bind(p, best)
                end
            end
        end
    end
    -- Day/night roof alternatives can be siblings instead of child meshes.
    for name, p in pairs(pieceMap) do
        local daytime = name:gsub("Night", "Day")
        local owner = owners[pieceMap[daytime]]
        if daytime ~= name and owner then bind(p, owner) end
    end
    for p in pairs(offsets) do if not movable[p] then offsets[p] = nil end end
    for p in pairs(rotations) do if not movable[p] then rotations[p] = nil end end
    ready = true
    publishStats()
end

local function removeAttachments(p)
    for _, id in ipairs(attachments[p] or {}) do
        if Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) then
            Spring.DestroyUnit(id, false, true)
        end
    end
    attachments[p] = nil
end

local function hidePiece(p)
    detached[p] = true
    retained[p] = nil
    hideBuildingPiece(p)
    if windowPieces then windowPieces[p] = nil end
    if GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID, p, false)
    end
    removeAttachments(p)
end

local function refreshGeometry()
    if selected then
        local n = 0
        for i = 1, #selected do
            if not detached[selected[i]] then n = n + 1; selected[n] = selected[i] end
        end
        for i = #selected, n + 1, -1 do selected[i] = nil end
    end
    for i, p in pairs(rooftop or {}) do
        if detached[p] then rooftop[i] = nil end
    end
    if GG.MarkBuildingShadowVolumeDirty then GG.MarkBuildingShadowVolumeDirty(unitID) end
    if unitEnv.OnBuildingGeometryChanged then unitEnv.OnBuildingGeometryChanged() end
end

local function dust(p)
    if GG.AllowBuildingBlockDamageEffect and not GG.AllowBuildingBlockDamageEffect("dust") then return end
    local x, y, z = position(p)
    if x then Spring.SpawnCEG("building_block_dust", x, y, z, 0, 1, 0) end
end

-- Keep each model section local: retained upper sections sink into the base;
-- the other sections make a short controlled drop before disappearing.
-- There are no emitted model pieces, projectiles or separate debris units.
local function settle(block, drop, seconds, travel)
    for _, p in ipairs(block.roots) do
        for axis = 1, 3 do StopSpin(p, axis, 0) end
        if drop > 0 then
            nativeMove(p, HEIGHT_MOVE_AXIS, (offsets[p] or 0) - drop, (travel or drop) / seconds)
        end
        local rotation = rotations[p] or {}
        nativeTurn(p, x_axis, (rotation[x_axis] or 0) + block.leanX, math.rad(5) / seconds)
        nativeTurn(p, z_axis, (rotation[z_axis] or 0) + block.leanZ, math.rad(5) / seconds)
    end
end

local function finishFall(block)
    if block.keepVisible and not collapsing then return end
    if block.keepVisible then
        block.keepVisible = false
        remnantCount = remnantCount - 1
        publishStats()
    end
    for _, p in ipairs(block.pieces) do hidePiece(p) end
end

local function removeBlockShadow(block)
    if not block.shadowRemoved and RemoveBuildingShadowPiece then
        RemoveBuildingShadowPiece(block.piece)
        block.shadowRemoved = true
    end
end

local function keepUpperRemnant(block)
    -- A private integer seed gives each section a stable roll without consuming
    -- or depending on the simulation's shared random-number sequence.
    local seed = (unitID * 65537 + block.piece * 8191) % 2147483647
    local roll = ((seed * 48271) % 2147483647) / 2147483647
    return roll < config.upperRemnantChance
end

local function detach(block, frame)
    if block.gone then return end
    local bottom = columns[block.column][1]
    block.keepVisible = not collapsing and visible[block.piece]
        and (block == bottom or keepUpperRemnant(block)) or false
    block.gone = true
    detachedCount = detachedCount + 1
    if block.keepVisible then remnantCount = remnantCount + 1 end
    publishStats()
    for _, p in ipairs(block.pieces) do
        -- Descendant spinners also survive Hide and rejected future commands.
        for axis = 1, 3 do StopSpin(p, axis, 0) end
        detached[p] = true
        -- Preserve only the pieces actually drawn at the moment of failure;
        -- hidden alternative meshes and decorations must remain hidden.
        retained[p] = block.keepVisible and visible[p] or nil
        if windowPieces then windowPieces[p] = nil end
        removeAttachments(p)
        if GG.SetObjectiveRadiancePieceVisible then
            GG.SetObjectiveRadiancePieceVisible(unitID, p, false)
        end
    end
    if unitEnv.OnBuildingPiecesDetached then
        unitEnv.OnBuildingPiecesDetached(block.pieces)
    end
    -- A retained bottom still occupies the bottom shadow cell. Sunken upper
    -- remnants overlap that cell, so their old elevated shadow bits are removed.
    if not block.keepVisible or block ~= bottom then removeBlockShadow(block) end
    if frame and visible[block.piece] then
        local drop = 0
        if block ~= bottom then
            if block.keepVisible then
                drop = math.max(0, block.y - (bottom.y + floorHeight * config.remnantHeightFraction))
            else
                drop = math.min(floorHeight * 0.45, math.max(0, block.y - bottom.y))
            end
        end
        settle(block, drop, FALL_FRAMES / 30)
        falling[#falling+1] = {block = block, frame = frame + FALL_FRAMES}
    else
        finishFall(block)
    end
end

local function nearestBlock(hitPiece, x, y, z)
    if type(hitPiece) == "string" then hitPiece = pieceMap[hitPiece] end
    local hit = hitPiece and owners[hitPiece]
    if hit and not hit.gone and visible[hit.piece] then
        return hit
    end
    local best, distance
    for _, block in ipairs(blocks) do
        if not block.gone and not block.pending and visible[block.piece] then
            local d = block.level
            if x then
                d = (x-block.x)^2 + (y-block.worldY)^2 + (z-block.z)^2
            end
            if not distance or d < distance then best, distance = block, d end
        end
    end
    return best
end

-- Called only on the gadget's fixed update tick, including one final tick for
-- pending failures, settling sections and finite effects. Hits contain only the
-- damage admitted below the shared configured health threshold.
function M.update(hits, frame)
    -- Once structural work has finished, only two bounded effect records need
    -- ticking. Avoid a health query and support scan on every fire tick.
    if ready and not collapsing and #blocks > 0 and (not hits or #hits == 0)
        and #failures == 0 and #falling == 0 and not overloadedPending then
        expireEffects(frame)
        return activeEffects > 0
    end
    if not ready or collapsing or #blocks == 0 then
        return false
    end
    expireEffects(frame)
    local settling, geometrySettled = {}, false
    for _, entry in ipairs(falling) do
        if frame >= entry.frame then finishFall(entry.block); geometrySettled = true
        else settling[#settling+1] = entry end
    end
    falling = settling
    local changed = false
    local waiting = {}
    for _, failure in ipairs(failures) do
        if frame >= failure.frame then
            local block = failure.block
            if not block.gone then
                dust(block.piece)
                for _, above in ipairs(columns[block.column]) do
                    if above.y >= block.y then detach(above, frame) end
                end
                changed = true
            end
        else
            waiting[#waiting + 1] = failure
        end
    end
    failures = waiting
    if changed then
        refreshGeometry()
    elseif geometrySettled and unitEnv.OnBuildingGeometryChanged then
        -- Moving remnants have reached their final pose; their cached window
        -- capture needs one more refresh, without rebuilding static shadows.
        unitEnv.OnBuildingGeometryChanged()
    end

    local _, maxHP = Spring.GetUnitHealth(unitID)
    if not maxHP then
        return #failures > 0 or #falling > 0 or activeEffects > 0
    end
    local strength = math.max(1, maxHP * config.healthThreshold / #blocks)
    -- Accumulate by struck block first, then resolve a bounded number of new
    -- support failures. Unresolved accumulated damage stays on the block.
    for _, hit in ipairs(hits or {}) do
        local block = nearestBlock(hit.piece, hit.x, hit.y, hit.z)
        if block and not block.pending then
            block.damage = block.damage + hit.damage
            -- Shared structural anchor: visual damage and smoke never pick a
            -- random decoration or the geometric centre of the house.
            lightBlockFire(block.piece, frame)
        end
    end
    local scheduled, overloaded = 0, false
    for _, block in ipairs(blocks) do
        if not block.gone and not block.pending and block.damage >= strength then
            if scheduled < MAX_BROKEN_COLUMNS_PER_UPDATE then
                failures[#failures + 1] = {block = block, frame = frame + FAILURE_DELAY_FRAMES}
                for _, above in ipairs(columns[block.column]) do
                    if above.y >= block.y then above.pending = true end
                end
                scheduled = scheduled + 1
            else
                overloaded = true
            end
        end
    end
    overloadedPending = overloaded
    local alive = false
    for _, block in ipairs(blocks) do if not block.gone then alive = true; break end end
    if not alive and #falling == 0 then
        clearEffects()
        Spring.DestroyUnit(unitID, false, false)
        return false
    end
    return overloaded or #failures > 0 or #falling > 0 or activeEffects > 0
end

function M.collapse(levels, shown)
    if collapsing then return 1 end
    collapsing = true
    failures = {}
    overloadedPending = false
    for _, entry in ipairs(falling) do finishFall(entry.block) end
    falling = {}
    for p in pairs(attachments) do removeAttachments(p) end
    clearEffects()
    Sleep(200) -- brief structural hesitation before the first floor gives way
    -- If killed during assembly there may not yet be a completed support graph.
    -- Hide partial geometry and suppress subsequent construction-thread Shows.
    if not ready then
        for _, p in ipairs(shown or {}) do hidePiece(p) end
        hideAll(unitID)
        return 1
    end
    local floors, order = {}, {}
    for _, block in ipairs(blocks) do
        if not block.gone and visible[block.piece] then
            if not floors[block.level] then floors[block.level] = {}; order[#order+1] = block.level end
            floors[block.level][#floors[block.level]+1] = block
        end
    end
    table.sort(order)
    local displacement = 0
    -- Lower floors give way in sequence. The entire remaining upper mass moves
    -- down together, including roofs and independent facade/roof decorations.
    for _, level in ipairs(order) do
        for i, block in ipairs(floors[level]) do
            if i <= 2 then dust(block.piece) end
            detach(block)
        end
        refreshGeometry()
        displacement = displacement + floorHeight
        for _, block in ipairs(blocks) do
            if not block.gone then settle(block, displacement, FLOOR_TIME_MS / 1000, floorHeight) end
        end
        Sleep(FLOOR_TIME_MS)
    end
    -- Unattached ground furniture, cranes and foundations disappear only after
    -- the structural mass has finished collapsing.
    -- Retained partial-collapse sections are absent from shown and the live
    -- support lists, so explicitly clear their geometry and shadow bits too.
    for _, block in ipairs(blocks) do
        for _, p in ipairs(block.pieces) do hidePiece(p) end
        removeBlockShadow(block)
        block.keepVisible = false
    end
    remnantCount = 0
    publishStats()
    for _, p in ipairs(shown or {}) do hidePiece(p) end
    hideAll(unitID)
    refreshGeometry()
    return 1
end

return M
