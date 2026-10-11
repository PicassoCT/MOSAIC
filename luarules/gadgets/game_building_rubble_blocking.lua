function gadget:GetInfo()
    return {
        name = "Building rubble blocking",
        desc = "Applies the shared building-scrapheap category's ground blocking policy",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = -10,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local rubbleTypes = getBuildingScrapHeapTypeTable(UnitDefs)

local function apply(id, defID)
    if rubbleTypes[defID] and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) then
        -- Enable the footprint and solid collision; do not make rubble crushable.
        -- The UnitDef owns its closed yardmap. This never modifies a house or
        -- creates a hole corresponding to a missing/render-hidden model piece.
        Spring.SetUnitBlocking(id, true, true, true, true, false, true, true)
    end
end

function gadget:Initialize()
    -- Includes preplaced ruins and restores the policy after a rules reload.
    for _, id in ipairs(Spring.GetAllUnits()) do
        apply(id, Spring.GetUnitDefID(id))
    end
end

function gadget:UnitCreated(id, defID)
    apply(id, defID)
end

function gadget:UnitFinished(id, defID)
    apply(id, defID)
end
