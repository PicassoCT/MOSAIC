include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    
    resetAll(unitID)
    crook = math.random(2, 5)
    crookVal = math.random(1, 4) * 90
    
    val = math.random(-360, 360)
    Turn(TablesOfPiecesGroups["HyperLoop"][1], y_axis, math.rad(val), 0)
    
    val = math.random(-360, 360)
    Turn(TablesOfPiecesGroups["HyperLoop"][6], y_axis, math.rad(val), 0)
    
    for i = 1, #TablesOfPiecesGroups["HyperLoop"] do
        upDownVal = math.random(0, -6)
        Turn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(upDownVal), 0)
    end
    
    if crook then
        index = crook
        index2 = crook + 6
        Turn(TablesOfPiecesGroups["HyperLoop"][index], y_axis, math.rad(crookVal), 0)
        Turn(TablesOfPiecesGroups["HyperLoop"][index2], y_axis, math.rad(crookVal), 0)
    end
    
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-120), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(145), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-189), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-145), 1)
    
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(230), 1)
end

function script.Killed(recentDamage, _)
    return 1
end
