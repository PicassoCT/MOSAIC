include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

Body = piece "Body"
Rotor = piece "Rotor"
FireEmit1 = piece "FireEmit1"
FireEmit2 = piece "FireEmit2"

function script.Create()
    Spin(Rotor, z_axis, math.rad(9000), 0)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["FireEmit"])
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return FireEmit1 end

function script.QueryWeapon1() return FireEmit1 end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon1() return true end

--- -aimining & fire weapon
function script.AimFromWeapon2() return FireEmit2 end

function script.QueryWeapon2() return FireEmit2 end

function script.AimWeapon2(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon2() return true end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate()
    Spin(Rotor, z_axis, math.rad(900), 100)
    return 1
end

function script.Deactivate()
    StopSpin(Rotor, z_axis, 100)
    return 0
end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

