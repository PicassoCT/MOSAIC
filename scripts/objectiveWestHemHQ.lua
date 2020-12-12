include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

function script.Create()
    
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    
    resetAll(unitID)
    
    val = math.random(-360, 360)
    Turn(TablesOfPiecesGroups["HyperLoop"][1], y_axis, math.rad(val), 0)
    Turn(TablesOfPiecesGroups["HyperLoop"][6], y_axis, math.rad(val), 0)
    
    for i = 1, #TablesOfPiecesGroups["HyperLoop"] do
        Turn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(-2), 0)
    end
    
end

function script.Killed(recentDamage, _)
    
    --createCorpseCUnitGeneric(recentDamage)
    return 1
end
