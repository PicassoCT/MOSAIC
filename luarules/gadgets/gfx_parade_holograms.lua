function gadget:GetInfo()
    return {
        name = "Parade pixel holograms",
        desc = "Stationary native neon projections beside passing lantern floats",
        author = "MOSAIC contributors", license = "GPL3", layer = 3, enabled = true,
    }
end
if not gadgetHandler:IsSyncedCode() then return false end
local config = VFS.Include("luarules/configs/parade_hologram_spawning.lua")
local factory = VFS.Include("luarules/gadgets/include/parade_hologram_spawning.lua")
local catalog = VFS.Include("scripts/lib_truck_parade_payloads.lua")
local decorations = VFS.Include("luarules/configs/parade_hologram_decorations.lua")
local ghosts = VFS.Include("luarules/configs/parade_ghost_parts.lua")
local projections
function gadget:Initialize()
    projections = factory.New(Spring,GG,Game,config,catalog,decorations,ghosts)
    -- A synced reload discards old ownership. Retire only our visual units;
    -- the active director will repopulate roadside projections next tick.
    local definition = UnitDefNames[config.unitName]
    for _, id in ipairs(Spring.GetAllUnits()) do
        if definition and Spring.GetUnitDefID(id) == definition.id then
            projections.holograms[id] = {}
        end
    end
    projections:Clear()
end
function gadget:GameFrame(frame)
    if frame % config.tickFrames == 0 then projections:Frame(frame) end
end
function gadget:UnitDestroyed(id)
    if projections then projections.holograms[id] = nil; projections.sources[id] = nil end
end
function gadget:Shutdown()
    if projections then projections:Clear() end
end
