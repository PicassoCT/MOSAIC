--most simple unit script
--allows the unit to be created & killed

include "lib_UnitScript.lua"

center= piece"center"
TablesOfPiecesGroups = {}
function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)

	TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideT(TablesOfPiecesGroups["Pine"])
	dice= math.ceil(math.random(1,3))
	Show(TablesOfPiecesGroups["Pine"][dice])
end

function script.Killed(recentDamage, maxHealth)
	
end