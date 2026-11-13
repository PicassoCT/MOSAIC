-- Deterministic parade-only cargo. Native UnitAttach supplies all movement.
include "lib_UnitScript.lua"
local catalog = VFS.Include("scripts/lib_truck_parade_payloads.lua")
local SIG_ANIMATION = 1
local center = piece("center")
local axes = {x = x_axis, y = y_axis, z = z_axis}
local pieceMap, variant, pendingVariant
local parentID, originalTooltip, installedTooltip

local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end

local function clearParentDescription()
    if alive(parentID) and installedTooltip
        and Spring.GetUnitTooltip(parentID) == installedTooltip then
        Spring.SetUnitTooltip(parentID, originalTooltip)
    end
    parentID, originalTooltip, installedTooltip = nil, nil, nil
end

local function animatePiece(motion)
    SetSignalMask(SIG_ANIMATION)
    local id, axis = pieceMap[motion.pieceName], axes[motion.axis]
    local direction = 1
    if motion.delayMs then Sleep(motion.delayMs) end
    while alive(unitID) do
        if motion.spin then
            Sleep(motion.pauseMs)
            if not alive(unitID) then return end
            Spin(id, axis, math.rad(motion.spin), math.rad(36))
            Sleep(motion.spinMs)
            if not alive(unitID) then return end
            StopSpin(id, axis, 0)
        else
            local seconds = motion.halfPeriodMs / 1000
            Turn(id, axis, math.rad(motion.angle * direction),
                math.rad(2 * math.abs(motion.angle) / seconds))
            Sleep(motion.halfPeriodMs)
            direction = -direction
        end
    end
end

-- May be called directly after CreateUnit, before the engine runs Create.
-- Missing pieces fail explicitly; ordinary cargo is never substituted.
function SetParadeVariant(index)
    if type(index) ~= "number" or index ~= math.floor(index) or not catalog.variants[index] then
        return false
    end
    if not pieceMap then pendingVariant = index; return true end
    local selected = catalog.variants[index]
    for _, name in ipairs(selected.pieces) do
        if not pieceMap[name] then
            Spring.Echo("truckpayloadparade: missing float piece " .. name)
            return false
        end
    end
    Signal(SIG_ANIMATION)
    clearParentDescription()
    hideAll(unitID)
    for _, entry in ipairs(catalog.variants) do
        for _, motion in ipairs(entry.motion or {}) do
            local id = pieceMap[motion.pieceName]
            if id then
                StopSpin(id, axes[motion.axis], 0)
                Turn(id, axes[motion.axis], 0, 0)
            end
        end
    end
    if GG.SetObjectiveRadiancePieceVisible then
        if variant then
            for _, name in ipairs(variant.pieces) do
                GG.SetObjectiveRadiancePieceVisible(unitID, pieceMap[name], false)
            end
        end
        for _, name in ipairs(selected.pieces) do
            GG.SetObjectiveRadiancePieceVisible(unitID, pieceMap[name], true, "material", "parade_float")
        end
    end
    variant = selected
    for _, name in ipairs(variant.pieces) do Show(pieceMap[name]) end
    -- The unsynced pixel decorations must follow the actual selected payload,
    -- including selections queued before Create and later variant changes.
    Spring.SetUnitRulesParam(unitID, "city_parade_variant", index, {inlos = true})
    Spring.SetUnitTooltip(unitID, variant.title .. " - " .. variant.description)
    for _, motion in ipairs(variant.motion or {}) do StartThread(animatePiece, motion) end
    return true
end

local function followParent()
    local unattachedMs, attachedMs, everAttached = 0, 0, false
    while alive(unitID) do
        local parent = Spring.GetUnitTransporter(unitID)
        if not alive(parent) then parent = nil end
        if parent ~= parentID then
            clearParentDescription()
            local offset
            if parent then
                parentID = parent
                local definition = UnitDefs[Spring.GetUnitDefID(parent)]
                offset = definition and catalog.carrierOffsets[definition.name]
            end
            local scale = catalog.centerMoveScale or 1
            Move(center, y_axis, (offset and offset.y or 0) * scale, 0)
            Move(center, z_axis, (offset and offset.z or 0) * scale, 0)
            attachedMs = 0
            Spring.SetUnitNoSelect(unitID, true)
            Spring.SetUnitBlocking(unitID, false)
        end
        if parentID then
            everAttached, unattachedMs = true, 0
            if not installedTooltip and attachedMs >= 1000 then
                originalTooltip = Spring.GetUnitTooltip(parentID) or "Civilian truck"
                installedTooltip = originalTooltip .. " carrying " .. variant.title .. " - " .. variant.description
                Spring.SetUnitTooltip(parentID, installedTooltip)
            end
            attachedMs = attachedMs + 250
        else
            unattachedMs = unattachedMs + 250
            -- Allow delayed transport attachment; detached visual cargo must
            -- not remain hovering after its carrier dies or is removed.
            if unattachedMs >= (everAttached and 2000 or 5000) then
                Spring.DestroyUnit(unitID, false, true)
                return
            end
        end
        Sleep(250)
    end
end

function script.Create()
    hideAll(unitID)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    pieceMap = Spring.GetUnitPieceMap(unitID) or {}
    if not pieceMap.center then
        Spring.Echo("truckpayloadparade: missing center piece")
        Spring.DestroyUnit(unitID, false, true)
        return
    end
    if not SetParadeVariant(pendingVariant or ((unitID - 1) % #catalog.variants + 1)) then
        Spring.DestroyUnit(unitID, false, true)
        return
    end
    if GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID, center, true, "lamp", "parade_procession")
    end
    StartThread(followParent)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
end

function script.Killed(recentDamage, maxHealth)
    Signal(SIG_ANIMATION)
    clearParentDescription()
    return 1
end
