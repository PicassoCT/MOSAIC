include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
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
end

function script.StopMoving()
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

