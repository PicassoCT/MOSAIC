include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece("Hedgehog")
aimpiece = center
boolDeployed = true

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitCloak(unitID, 2)
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return aimpiece end

function script.AimWeapon1(Heading, pitch) return true end

function script.FireWeapon1()
   return true
end
