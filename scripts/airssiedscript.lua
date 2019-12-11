include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
aimpiece = center

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
function script.AimFromWeapon1()
    return aimpiece
end



function script.QueryWeapon1()
    return aimpiece
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

    return true
end


function script.FireWeapon1()

    return true
end



function script.StartMoving()
	Turn(center,y_axis,math.rad(180),90)
	spinT(TablesOfPiecesGroups["uprotor"],y_axis,350,9500)
	spinT(TablesOfPiecesGroups["downrotor"],y_axis,350,-8500)
end

function script.StopMoving()
	Turn(center,y_axis,math.rad(0),90)
	stopSpinT(TablesOfPiecesGroups["uprotor"],y_axis,math.pi)
	stopSpinT(TablesOfPiecesGroups["downrotor"],y_axis,math.pi)
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

Spring.SetUnitNanoPieces( unitID, { center })

