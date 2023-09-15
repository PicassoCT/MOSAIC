include "lib_mosaic.lua"
include "lib_UnitScript.lua"

TablesOfPiecesGroups = {}

function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
	StartThread(bodyBuilder)	
end
center = piece"center"

function bodyBuilder()
	TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideAll(unitID)
	Show(center)
	if maRa() == true then
		mapNameHashIndex = hashString(Game.mapName) % #TablesOfPiecesGroups["flag"]
		Show(TablesOfPiecesGroups["flag"][mapNameHashIndex])
	end

	for i=1, #TablesOfPiecesGroups["CameraPole"] do
		value = i* 45 + math.random(-10,10)

		Turn(TablesOfPiecesGroups["CameraPole"][i], y_axis, math.rad(value), 0)
		Show(TablesOfPiecesGroups["CameraPole"][i])
		cameraDecider = (i-1)*2 + math.random(1,2)
		Show(TablesOfPiecesGroups["Camera"][cameraDecider])

		if maRa()== true then
			Show(TablesOfPiecesGroups["Cable"][i])
			rVal = math.random(0,360)
			Turn(TablesOfPiecesGroups["Cable"][i], x_axis, math.rad(rVal),0)
		end
	end
end

 
function script.HitByWeapon(x, z, weaponDefID, damage) 
	return damage
end

function script.Killed(recentDamage, maxHealth)
	return 0
end