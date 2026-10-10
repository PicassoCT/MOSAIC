-- Per-building structural damage. No polling, physics units or per-frame scans.
-- The generated grid supplies conservative vertical supports: when one block
-- fails, every block above it in that column fails too (no invented cantilevers).
local M = {}
local nativeShow, nativeHide, nativeMove, nativeTurn, nativeSpin = Show, Hide, Move, Turn, Spin
local detached, visible, offsets, rotations, attachments = {}, {}, {}, {}, {}
local blocks, columns, owners, movable = {}, {}, {}, {}
local selected, rooftop, windowPieces, pieceMap
local floorHeight, cellSize, modelScale = 1, 1, 1
local ready, collapsing = false, false
local failures, falling = {}, {}
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
    if ready or collapsing then return end
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
    for _, p in ipairs(block.roots) do
        for axis = 1, 3 do StopSpin(p, axis, 0) end
        if drop > 0 then
            nativeMove(p, y_axis, (offsets[p] or 0) - drop, (travel or drop) / seconds)
        end
        local rotation = rotations[p] or {}
        nativeTurn(p, x_axis, (rotation[x_axis] or 0) + block.leanX, math.rad(5) / seconds)
        nativeTurn(p, z_axis, (rotation[z_axis] or 0) + block.leanZ, math.rad(5) / seconds)
    end
end

local function finishFall(block)
    for _, p in ipairs(block.pieces) do hidePiece(p) end
end

local function detach(block, frame)
    if block.gone then return end
    block.gone = true
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
    else
        finishFall(block)
    end
end

local function nearestBlock(hitPiece, x, y, z)
    if type(hitPiece) == "string" then hitPiece = pieceMap[hitPiece] end
    local hit = hitPiece and owners[hitPiece]
    if hit and not hit.gone and visible[hit.piece] then return hit end
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
-- pending failures and settling sections. Hits contain damage below 50% HP.
function M.update(hits, frame)
    if not ready or collapsing or #blocks == 0 then return false end
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
    if changed then refreshGeometry() end

    local _, maxHP = Spring.GetUnitHealth(unitID)
    if not maxHP then return #failures > 0 or #falling > 0 end
    local strength = math.max(1, maxHP * 0.5 / #blocks)
    -- Accumulate by struck block first, then resolve a bounded number of new
    -- support failures. Unresolved accumulated damage stays on the block.
    for _, hit in ipairs(hits or {}) do
        local block = nearestBlock(hit.piece, hit.x, hit.y, hit.z)
        if block and not block.pending then block.damage = block.damage + hit.damage end
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
    local alive = false
    for _, block in ipairs(blocks) do if not block.gone then alive = true; break end end
    if not alive and #falling == 0 then
        Spring.DestroyUnit(unitID, false, false)
        return false
    end
    return overloaded or #failures > 0 or #falling > 0
end

function M.collapse(levels, shown)
    if collapsing then return 1 end
    collapsing = true
    failures = {}
    for _, entry in ipairs(falling) do finishFall(entry.block) end
    falling = {}
    for p in pairs(attachments) do removeAttachments(p) end
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
    for _, p in ipairs(shown or {}) do hidePiece(p) end
    hideAll(unitID)
    refreshGeometry()
    return 1
end

return M
