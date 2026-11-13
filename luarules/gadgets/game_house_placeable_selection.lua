function gadget:GetInfo()
    return {
        name='Shared house placeable selection',
        desc='Deterministic least-used prop selection across the city',
        author='MOSAIC contributors', license='GPL3', layer=0, enabled=true,
    }
end
if not gadgetHandler:IsSyncedCode() then return false end

local newService=VFS.Include('luarules/gadgets/include/house_placeable_selection.lua')
-- Keep pending unit-script callbacks and completed tickets on gadget reload.
GG.HousePlaceableSelectionState=GG.HousePlaceableSelectionState or {}
local service=newService(Spring,Game.mapName,GG.HousePlaceableSelectionState)
function gadget:Initialize() GG.HousePlaceableSelection=service end
function gadget:GameID(id) service:GameID(id) end
function gadget:GameFrame(frame) service:GameFrame(frame) end
function gadget:UnitDestroyed(id) service:UnitDestroyed(id) end
function gadget:Shutdown()
    if GG.HousePlaceableSelection==service then GG.HousePlaceableSelection=nil end
end
