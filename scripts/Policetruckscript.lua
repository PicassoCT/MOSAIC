include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"
TablesOfPiecesGroups = {}

center = piece "center"
attachPoint = piece "attachPoint"
myDefID = Spring.GetUnitDefID(unitID)
boolIsCivilianTruck = (myDefID == UnitDefNames["truck"].id)



function showAndTell()

	showAll(unitID)

	if TablesOfPiecesGroups["Body"]  then
		hideT(TablesOfPiecesGroups["Body"])

			Show(TablesOfPiecesGroups["Body"][2])
	
	end

end

function script.Create()
	


    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
	showAndTell()

end

function script.HitByWeapon(x, z, weaponDefID, damage)
end
function script.Killed(recentDamage, _)
	if doesUnitExistAlive(loadOutUnitID) then Spring.DestroyUnit(loadOutUnitID,true,true) end

    createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving()
	spinT(TablesOfPiecesGroups["wheel"], x_axis ,0.3 , -160)
end

function script.StopMoving()
	stopSpinT(TablesOfPiecesGroups["wheel"], x_axis, 3)	
end

function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })

