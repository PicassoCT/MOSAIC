-- Per-building structural damage. No polling, physics units or per-frame scans.
-- The generated grid supplies conservative vertical supports: when one block
-- fails, every block above it in that column fails too (no invented cantilevers).
local M = {}
local destructionTrace = VFS.Include('scripts/lib_building_destruction_trace.lua')
local nativeShow, nativeHide, nativeMove, nativeTurn, nativeSpin = Show, Hide, Move, Turn, Spin
local detached, visible, offsets, rotations, attachments = {}, {}, {}, {}, {}
local blocks, columns, owners, movable = {}, {}, {}, {}
local selected, rooftop, windowPieces, pieceMap
local floorHeight, cellSize, modelScale = 1, 1, 1
local ready, collapsing = false, false
local failures, falling = {}, {}
local fireSlots, activeFires, detachedCount = {}, 0, 0
local MAX_BUILDING_FIRES = 2
local function publishStats()
    if Spring.SetUnitRulesParam then
        Spring.SetUnitRulesParam(unitID, 'building_structural_blocks', #blocks, {public=true})
        Spring.SetUnitRulesParam(unitID, 'building_detached_blocks', detachedCount, {public=true})
        Spring.SetUnitRulesParam(unitID, 'building_structural_ready', ready and 1 or 0, {public=true})
    end
end
local function lightBlockFire(p)
    if not GG.SmokeRibbon or fireSlots[p] or activeFires >= MAX_BUILDING_FIRES then
        destructionTrace.Log(unitID, 'block_fire_skipped', {piece=p, active=activeFires,
            reason=not GG.SmokeRibbon and 'no_provider' or fireSlots[p] and 'already_active' or 'fire_limit'}, 30)
        return
    end
    local slot='block_fire_'..tostring(p)
    destructionTrace.Log(unitID, 'block_fire_requested', {piece=p, slot=slot}, 30)
    local ok=GG.SmokeRibbon.Set(unitID,slot,p,{
        directionSpace='world',direction={0,1,0},
        length=24,width=5,strands=2,curl=0.45,speed=1.8,
        windAffected=false,motionAffected=false,
        colorStart={1,0.55,0.18,0.85},colorEnd={0.75,0.08,0.015,0},
        emission={2.5,0.6},sourceGlow={1,0.42,0.09,0.3},
        distanceFactor=35,
    })
    if ok then fireSlots[p]=slot;activeFires=activeFires+1 end
    destructionTrace.Log(unitID, 'block_fire_result', {piece=p, accepted=not not ok, active=activeFires}, 30)
end
local FAILURE_DELAY_FRAMES = 6
local FALL_FRAMES = 6
local MAX_BROKEN_COLUMNS_PER_UPDATE = 3
local FLOOR_TIME_MS = 320

-- Construction, day/night switching and piece animations must never resurrect
-- detached geometry. These wrappers belong only to the three procedural scripts.
function Show(p)
    if not collapsing and not detached[p] then visible[p] = true; return nativeShow(p) end
end
function Hide(p)
    visible[p] = nil
    return nativeHide(p)
end

function IsBuildingPieceDetached(p)
    return collapsing or detached[p] == true
end

function RegisterBuildingPieceAttachment(p, id)
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
function Move(p, axis, goal, speed)
    if collapsing or detached[p] then return end
    if axis == y_axis and (not ready or movable[p]) then offsets[p] = goal end
    return nativeMove(p, axis, goal, speed)
end
function Turn(p, axis, goal, speed)
    if collapsing or detached[p] then return end
    if not ready or movable[p] then
        rotations[p] = rotations[p] or {}
        rotations[p][axis] = goal
    end
    return nativeTurn(p, axis, goal, speed)
end
function Spin(p, ...)
    if not collapsing and not detached[p] then return nativeSpin(p, ...) end
end

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
        destructionTrace.Log(unitID, 'structure_initialize_skipped', {reason=ready and 'already_ready' or 'collapsing'}, 30)
        return
    end
    destructionTrace.Log(unitID, 'structure_initialize_begin', {height=height, width=width, scale=scale,
        cachedPieceMap=cachedPieceMap ~= nil, shown=shown and #shown or 0})
    floorHeight, cellSize, modelScale = height, width, scale
    selected, rooftop, windowPieces = shown, roofs, windows
    pieceMap = cachedPieceMap or Spring.GetUnitPieceMap(unitID)
    destructionTrace.Log(unitID, 'structure_piece_map_ready', {available=pieceMap ~= nil})
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
    local columnCount = 0 -- Diagnostic count in the existing traversal.
    for _, col in pairs(columns) do
        columnCount = columnCount + 1
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
    destructionTrace.Log(unitID, 'structure_initialize_ready', {blocks=#blocks, columns=columnCount,
        reason=#blocks == 0 and 'empty_structure' or 'support_graph_registered'})
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
    if fireSlots[p] then
        if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,fireSlots[p]) end
        fireSlots[p]=nil;activeFires=math.max(0,activeFires-1)
    end
    detached[p] = true
    Hide(p)
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
end

local function dust(p)
    if GG.AllowBuildingBlockDamageEffect and not GG.AllowBuildingBlockDamageEffect("dust") then return end
    local x, y, z = position(p)
    if x then Spring.SpawnCEG("building_block_dust", x, y, z, 0, 1, 0) end
end

-- Keep the existing model section local: a short, controlled drop and tilt.
-- There are no emitted model pieces, projectiles or separate debris units.
local function settle(block, drop, seconds, travel)
    destructionTrace.Log(unitID, 'block_settle_begin', {piece=block.piece, column=block.column, level=block.level,
        roots=#block.roots, pieces=#block.pieces, drop=drop, seconds=seconds, travel=travel or drop})
    for _, p in ipairs(block.roots) do
        for axis = 1, 3 do StopSpin(p, axis, 0) end
        if drop > 0 then
            nativeMove(p, y_axis, (offsets[p] or 0) - drop, (travel or drop) / seconds)
        end
        local rotation = rotations[p] or {}
        nativeTurn(p, x_axis, (rotation[x_axis] or 0) + block.leanX, math.rad(5) / seconds)
        nativeTurn(p, z_axis, (rotation[z_axis] or 0) + block.leanZ, math.rad(5) / seconds)
    end
    destructionTrace.Log(unitID, 'block_settle_issued', {piece=block.piece, roots=#block.roots})
end

local function finishFall(block)
    destructionTrace.Log(unitID, 'block_fall_hide_begin', {piece=block.piece, pieces=#block.pieces})
    for _, p in ipairs(block.pieces) do hidePiece(p) end
    destructionTrace.Log(unitID, 'block_fall_hide_complete', {piece=block.piece, pieces=#block.pieces})
end

local function detach(block, frame)
    if block.gone then
        destructionTrace.Log(unitID, 'block_detach_skipped', {piece=block.piece, reason='already_gone'}, 30)
        return
    end
    destructionTrace.Log(unitID, 'block_detach_begin', {piece=block.piece, column=block.column, level=block.level,
        visible=not not visible[block.piece], pieces=#block.pieces, animate=not not (frame and visible[block.piece])})
    block.gone = true
    detachedCount = detachedCount + 1
    publishStats()
    for _, p in ipairs(block.pieces) do
        detached[p] = true
        removeAttachments(p)
        if GG.SetObjectiveRadiancePieceVisible then
            GG.SetObjectiveRadiancePieceVisible(unitID, p, false)
        end
    end
    if RemoveBuildingShadowPiece then RemoveBuildingShadowPiece(block.piece) end
    if frame and visible[block.piece] then
        -- Never push the lowest block into the terrain. Its upper stack settles
        -- by less than half a floor, then disappears in the local dust puff.
        local baseY = columns[block.column][1].y
        local drop = math.min(floorHeight * 0.45, math.max(0, block.y - baseY))
        settle(block, drop, FALL_FRAMES / 30)
        falling[#falling+1] = {block = block, frame = frame + FALL_FRAMES}
        destructionTrace.Log(unitID, 'block_fall_scheduled', {piece=block.piece, dueFrame=frame+FALL_FRAMES, drop=drop})
    else
        finishFall(block)
    end
end

local function nearestBlock(hitPiece, x, y, z)
    destructionTrace.Log(unitID, 'block_lookup_begin', {piece=hitPiece, x=x, y=y, z=z}, 30)
    if type(hitPiece) == "string" then hitPiece = pieceMap[hitPiece] end
    local hit = hitPiece and owners[hitPiece]
    if hit and not hit.gone and visible[hit.piece] then
        destructionTrace.Log(unitID, 'block_lookup_selected', {piece=hit.piece, source='piece_owner',
            pending=not not hit.pending, column=hit.column, level=hit.level}, 30)
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
    if best then
        destructionTrace.Log(unitID, 'block_lookup_selected', {piece=best.piece, source=x and 'cached_position' or 'lowest_level',
            metric=x and 'distance_squared' or 'level', score=distance,
            x=best.x, y=best.worldY, z=best.z, column=best.column, level=best.level}, 30)
    else
        destructionTrace.Log(unitID, 'block_lookup_skipped', {piece=hitPiece, blocks=#blocks, reason='no_eligible_visible_block'}, 30)
    end
    return best
end

-- Called only on the gadget's fixed update tick, including one final tick for
-- pending failures and settling sections. Hits contain damage below 50% HP.
function M.update(hits, frame)
    destructionTrace.Log(unitID, 'structural_update_received', {hits=hits and #hits or 0, failures=#failures, falling=#falling}, 30)
    if not ready or collapsing or #blocks == 0 then
        destructionTrace.Log(unitID, 'structural_update_skipped', {reason=not ready and 'not_ready' or collapsing and 'collapsing' or 'no_blocks'}, 30)
        return false
    end
    local settling = {}
    for _, entry in ipairs(falling) do
        if frame >= entry.frame then finishFall(entry.block)
        else settling[#settling+1] = entry end
    end
    falling = settling
    local changed = false
    local waiting = {}
    for _, failure in ipairs(failures) do
        if frame >= failure.frame then
            local block = failure.block
            if not block.gone then
                destructionTrace.Log(unitID, 'block_failure_due', {piece=block.piece, column=block.column,
                    level=block.level, dueFrame=failure.frame})
                dust(block.piece)
                for _, above in ipairs(columns[block.column]) do
                    if above.y >= block.y then detach(above, frame) end
                end
                changed = true
                destructionTrace.Log(unitID, 'block_failure_applied', {piece=block.piece, detached=detachedCount, falling=#falling})
            else
                destructionTrace.Log(unitID, 'block_failure_skipped', {piece=block.piece, reason='already_gone'}, 30)
            end
        else
            waiting[#waiting + 1] = failure
        end
    end
    failures = waiting
    if changed then refreshGeometry() end

    local _, maxHP = Spring.GetUnitHealth(unitID)
    if not maxHP then
        destructionTrace.Log(unitID, 'structural_update_skipped', {reason='health_unavailable', failures=#failures, falling=#falling}, 30)
        return #failures > 0 or #falling > 0
    end
    local strength = math.max(1, maxHP * 0.5 / #blocks)
    -- Accumulate by struck block first, then resolve a bounded number of new
    -- support failures. Unresolved accumulated damage stays on the block.
    for _, hit in ipairs(hits or {}) do
        local block = nearestBlock(hit.piece, hit.x, hit.y, hit.z)
        if block and not block.pending then
            block.damage = block.damage + hit.damage
            destructionTrace.Log(unitID, 'block_damage_accumulated', {piece=block.piece, increment=hit.damage,
                damage=block.damage, strength=strength, column=block.column, level=block.level}, 30)
            -- Shared structural anchor: visual damage and smoke never pick a
            -- random decoration or the geometric centre of the house.
            GG.BuildingDamageAnchor = GG.BuildingDamageAnchor or {}
            GG.BuildingDamageAnchor[unitID] = block.piece
            lightBlockFire(block.piece)
        else
            destructionTrace.Log(unitID, 'block_damage_skipped', {piece=block and block.piece or hit.piece,
                damage=hit.damage, reason=block and 'pending_failure' or 'no_selected_block'}, 30)
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
                destructionTrace.Log(unitID, 'block_failure_scheduled', {piece=block.piece, column=block.column,
                    level=block.level, damage=block.damage, strength=strength, dueFrame=frame+FAILURE_DELAY_FRAMES})
            else
                overloaded = true
                destructionTrace.Log(unitID, 'block_failure_deferred', {piece=block.piece, damage=block.damage,
                    strength=strength, reason='update_column_limit'}, 30)
            end
        end
    end
    local alive = false
    for _, block in ipairs(blocks) do if not block.gone then alive = true; break end end
    if not alive and #falling == 0 then
        destructionTrace.Log(unitID, 'all_blocks_gone_destroy_requested', {blocks=#blocks, detached=detachedCount})
        Spring.DestroyUnit(unitID, false, false)
        return false
    end
    return overloaded or #failures > 0 or #falling > 0
end

function M.collapse(levels, shown)
    if collapsing then
        destructionTrace.Log(unitID, 'collapse_skipped', {reason='already_collapsing'}, 30)
        return 1
    end
    destructionTrace.Log(unitID, 'collapse_begin', {ready=ready, blocks=#blocks, failures=#failures, falling=#falling})
    collapsing = true
    failures = {}
    for _, entry in ipairs(falling) do finishFall(entry.block) end
    falling = {}
    for p in pairs(attachments) do removeAttachments(p) end
    for p,slot in pairs(fireSlots) do
        if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,slot) end
        fireSlots[p]=nil
    end
    activeFires=0
    destructionTrace.Log(unitID, 'collapse_hesitation', {milliseconds=200})
    Sleep(200) -- brief structural hesitation before the first floor gives way
    -- If killed during assembly there may not yet be a completed support graph.
    -- Hide partial geometry and suppress subsequent construction-thread Shows.
    if not ready then
        destructionTrace.Log(unitID, 'collapse_partial_cleanup_begin', {shown=shown and #shown or 0, reason='not_ready'})
        for _, p in ipairs(shown or {}) do hidePiece(p) end
        hideAll(unitID)
        destructionTrace.Log(unitID, 'collapse_complete', {result=1, reason='partial_structure_hidden'})
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
        destructionTrace.Log(unitID, 'collapse_floor_begin', {level=level, blocks=#floors[level], displacement=displacement})
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
        destructionTrace.Log(unitID, 'collapse_floor_complete', {level=level, displacement=displacement, milliseconds=FLOOR_TIME_MS})
    end
    -- Unattached ground furniture, cranes and foundations disappear only after
    -- the structural mass has finished collapsing.
    destructionTrace.Log(unitID, 'collapse_cleanup_begin', {shown=shown and #shown or 0})
    for _, p in ipairs(shown or {}) do hidePiece(p) end
    hideAll(unitID)
    refreshGeometry()
    destructionTrace.Log(unitID, 'collapse_complete', {result=1, floors=#order, detached=detachedCount})
    return 1
end

return M
