-- As with truckPayloadScript.lua, one numbered container piece supplies the
-- complete visible body. Carrier movement and transport rules remain native.
include "lib_UnitScript.lua"
local catalog = VFS.Include("scripts/lib_truck_service_payloads.lua")
local variant
local center = piece("center")
local parentID, originalTooltip, installedTooltip

local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end

local function clearParentDescription()
    -- Do not erase later changes, such as refugee or ownership descriptions.
    if alive(parentID) and installedTooltip
        and Spring.GetUnitTooltip(parentID) == installedTooltip then
        Spring.SetUnitTooltip(parentID, originalTooltip)
    end
    parentID, originalTooltip, installedTooltip = nil, nil, nil
end

local function followParent()
    local attachedMs = 0
    while alive(unitID) do
        local parent = Spring.GetUnitTransporter(unitID)
        if parent and not alive(parent) then parent = nil end
        if parent ~= parentID then
            clearParentDescription()
            local offset
            if alive(parent) then
                parentID = parent
                local definition = UnitDefs[Spring.GetUnitDefID(parent)]
                offset = definition and catalog.carrierOffsets[definition.name]
            end
            -- Fit once per attachment; all visible meshes descend from center.
            -- Reset after detachment so a later carrier cannot inherit its fit.
            Move(center, y_axis, offset and offset.y or 0, 0)
            Move(center, z_axis, offset and offset.z or 0, 0)
            attachedMs = 0
            -- TransportDrop enables selection for ordinary passengers. These
            -- visual bodies remain unselectable and nonblocking when detached.
            Spring.SetUnitNoSelect(unitID, true)
            Spring.SetUnitBlocking(unitID, false)
        end
        -- The carrier sets its registration plate in its own Create callback.
        if parentID and not installedTooltip and attachedMs >= 1000 then
            originalTooltip = Spring.GetUnitTooltip(parentID) or "Civilian truck"
            installedTooltip = originalTooltip .. " transporting " .. variant.description
            Spring.SetUnitTooltip(parentID, installedTooltip)
        end
        local interval = parentID and 500 or 100
        Sleep(interval)
        attachedMs = attachedMs + interval
    end
end

function script.Create()
    hideAll(unitID)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    local groups = getPieceTableByNameGroups(false, true)
    GG.CivilianServicePayloadVariants = GG.CivilianServicePayloadVariants or {}
    local displayedPiece
    variant, displayedPiece = catalog.selectVariant(groups.container or {}, GG.CivilianServicePayloadVariants)
    if not variant then
        Spring.Echo("truckpayloadservice: model has no numbered container pieces")
        return
    end
    Show(displayedPiece)
    -- CONTAINER<NR>Spin<id> belongs only to the selected payload body.
    -- Keep legacy lowercase names working; spinner IDs may have gaps.
    for _, groupName in ipairs({variant.pieceName:upper() .. "Spin",
        variant.pieceName .. "Spin"}) do
        for _, spinner in pairs(groups[groupName] or {}) do
            Show(spinner)
            Spin(spinner, y_axis, math.rad(42), math.pi)
        end
    end
    Spring.SetUnitTooltip(unitID, variant.description)
    if variant.passenger then
        -- Reuse the existing bus arrival/departure routines for this body.
        GG.BusesTable = GG.BusesTable or {}
        GG.BusesTable[unitID] = unitID
    end
    StartThread(followParent)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
end

function script.Killed(recentDamage, maxHealth)
    clearParentDescription()
    if GG.BusesTable then GG.BusesTable[unitID] = nil end
    return 1
end
