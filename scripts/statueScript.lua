include "lib_UnitScript.lua"


function script.Create()
    hideAll(unitID)
    showOneOfUnit(unitID)
    Spring.SetUnitAlwaysVisible(unitID, true)
end


function script.Killed(recentDamage, _)
    return 1
end
