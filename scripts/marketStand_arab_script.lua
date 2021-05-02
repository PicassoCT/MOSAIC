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
counter = math.random(3,10)
function script.HitByWeapon(x, z, weaponDefID, damage) 
	if counter > 0 then 
		counter = counter -1
	Explode(TablesOfPiecesGroups["Prop"][math.random(1,#TablesOfPiecesGroups["Prop"])], SFX.FALL + SFX.NO_HEATCLOUD)
	end
return damage
end

function script.Killed(recentDamage, maxHealth)
	
end