
include "lib_UnitScript.lua"


TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Wall"])
    dice = math.random(1, #TablesOfPiecesGroups["Wall"])
    Show(TablesOfPiecesGroups["Wall"][dice])
    if maRa() == maRa()then
        dice = math.random(1, #TablesOfPiecesGroups["Wall"])
        Show(TablesOfPiecesGroups["Wall"][dice])
    end
end

function script.Killed(recentDamage, _)
    return 1
end


