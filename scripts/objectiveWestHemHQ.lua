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
    
    val= math.random(-8,-3)
    for i = 1, 6 do
        Turn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(val), 0)
    end

    val= math.random(-10,-3)
    for i=7, #TablesOfPiecesGroups["HyperLoop"] do
        Turn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(val), 0)
    end
    
end

function script.Killed(recentDamage, _)
    return 1
end
