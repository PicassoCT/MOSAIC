include "lib_mosaic.lua"
include "lib_UnitScript.lua"


TablesOfPiecesGroups = {}

function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
end

function script.HitByWeapon(x, z, weaponDefID, damage) 
return damage
end

function script.Killed(recentDamage, maxHealth)
	
end