include "lib_UnitScript.lua"
include "lib_Animation.lua"

local center = piece "center"
function script.Create()
    local pieces = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.SetUnitBlocking(unitID,false,false,false)
    Spring.MoveCtrl.Enable(unitID)
    local x,y,z=Spring.GetUnitPosition(unitID)
    Spring.MoveCtrl.SetPosition(unitID,x,y+25,z)
    Show(center)
    for i, rotor in ipairs(pieces.Rotor or {}) do
        Show(rotor)
        Spin(rotor,y_axis,math.rad(20+i*7),0)
    end
    -- Collection, provenance and expiry belong to the central betrayal gadget.
end
function script.HitByWeapon() return 0 end
function script.Killed() return 1 end
function script.StartMoving() end
function script.StopMoving() end
function script.Activate() return 1 end
function script.Deactivate() return 0 end
