include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center"
aimpiece = center

function script.Create()

    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    StartThread(unfold)
end
function unfold()
    turnT(TablesOfPiecesGroups["Arm"], y_axis, 180, 0)
    Sleep(100)
    turnT(TablesOfPiecesGroups["Arm"], y_axis, 0, 15)
end
function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return aimpiece end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon1() return true end

function script.StartMoving()
    Turn(center, x_axis, math.rad(40), 0)
    spinT(TablesOfPiecesGroups["uprotor"], y_axis, 9500, 350)
    spinT(TablesOfPiecesGroups["downrotor"], y_axis, -8500, 350)
    turnT(TablesOfPiecesGroups["Arm"], y_axis, 0, 15)
end

function script.StopMoving()
    Turn(center, x_axis, math.rad(0), 0)
    stopSpinT(TablesOfPiecesGroups["uprotor"], y_axis, math.pi)
    stopSpinT(TablesOfPiecesGroups["downrotor"], y_axis, math.pi)
    turnT(TablesOfPiecesGroups["Arm"], y_axis, 180, 1)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

