include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
aimpiece = piece "aimpiece"
nano = piece "nano"
shotemit = piece "shotemit"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
function script.AimFromWeapon1()
    return shotemit
end



function script.QueryWeapon1()
    return shotemit
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

        WTurn(center, y_axis, Heading, 0.4)
        WTurn(aimpiece, x_axis, -pitch, 1.3)
    return true
end


function script.FireWeapon1()

    return true
end



function script.StartBuilding()
end

function script.StopBuilding()
end
function script.Activate()



    SetUnitValue(COB.YARD_OPEN, 1)

    SetUnitValue(COB.BUGGER_OFF, 1)

    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end



function script.Deactivate()

    SetUnitValue(COB.YARD_OPEN, 0)

    SetUnitValue(COB.BUGGER_OFF, 0)

    SetUnitValue(COB.INBUILDSTANCE, 0)

    return 0
end




function script.QueryBuildInfo()
    return aimpiece
end

Spring.SetUnitNanoPieces(unitID, { nano })

