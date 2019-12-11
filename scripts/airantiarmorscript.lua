include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

firepiece = piece "firepiece"
center = piece "MosaicJavelin"
gun = piece "MosaicJavelin"

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	--Hide(firepiece)
end

function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
function script.AimFromWeapon1()
    return firepiece
end



function script.QueryWeapon1()
    return firepiece
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

    return true
end


function script.FireWeapon1()
	destroyUnitConditional(unitID, false, true)
    return true
end



function script.StartMoving()
spinT(TablesOfPiecesGroups["uprotor"],y_axis,350,9500)
spinT(TablesOfPiecesGroups["lowrotor"],y_axis,350,-9500)
end

function script.StopMoving()
stopSpinT(TablesOfPiecesGroups["uprotor"],y_axis,1)
stopSpinT(TablesOfPiecesGroups["lowrotor"],y_axis,1)
end

function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end



