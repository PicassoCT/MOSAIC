include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
myDefID = Spring.GetUnitDefID(unitID)

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    Spring.SetUnitNoSelect(unitID, true)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    if myDefID == UnitDefNames["truckpayloadrefugee"].id then
        hideT(TablesOfPiecesGroups["container"])
        showOnePiece(TablesOfPiecesGroups["RefugeePayload"])
        for k,v in pairs(TablesOfPiecesGroups["RefugeeDeco"]) do
            if maRa() == true then
                Show(v)
            end
        end
    else
        hideAll(unitID)
        showOnePiece(TablesOfPiecesGroups["container"])
    end

end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end
