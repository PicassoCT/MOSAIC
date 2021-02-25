include "lib_mosaic.lua"
include "lib_UnitScript.lua"

center= piece"center"
TablesOfPiecesGroups = {}

function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)

	StartThread(bodyBuilder)
	
end
function bodyBuilder()
	TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	
	
	process(TablesOfPiecesGroups["Prop"],
			function(id)
				if math.random(0,1)==1 then Show(id) else Hide(id) end			
			end
			)
end

function script.Killed(recentDamage, maxHealth)
	
end