include "lib_UnitScript.lua"
include "lib_mosaic.lua"

local center = piece("center")

function script.Create()
    local groups = getPieceTableByNameGroups(false, true)
    hideT(groups.Data)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    -- Native movement handles pathfinding, stop and queued patrol orders.
    Move(center, y_axis, getGameConfig().presentation.icons.hoverGroundOffset, 0)
    Spin(center, y_axis, math.rad(20), 0)
end

function script.Killed() return 1 end
