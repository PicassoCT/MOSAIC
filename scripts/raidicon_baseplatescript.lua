include "lib_OS.lua"
include "lib_mosaic.lua"


myTeamID = Spring.GetUnitTeam(unitID)

function script.Created()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.MoveCtrl.Enable(unitID,true)
    StartThread(delayedMortallyDependent)
end

function delayedMortallyDependent()
    Sleep(10)
    parent = GG.myParent[unitID]
    if parent then
        StartThread(mortallyDependant, unitID, parent, 100, false, true)
    else
        StartThread(killNow)
    end
end

function killNow()
    Spring.DestroyUnit(unitID, true, false)
end
function script.Killed(recentDamage, _)
    return 1
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
