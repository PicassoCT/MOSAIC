include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"

if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
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
