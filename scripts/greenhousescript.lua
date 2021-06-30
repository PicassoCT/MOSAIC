--most simple unit script
--allows the unit to be created & killed

include "lib_UnitScript.lua"


function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)

end


function script.Killed(recentDamage, maxHealth)	
end