include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
myDefID = Spring.GetUnitDefID(unitID)

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.SetUnitNoSelect(unitID,true)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    if myDefID == UnitDefNames["truckpayloadrefugee"].id then
        showOnePiece(TablesOfPiecesGroups["RefugeePayload"])

        for i=1, #TablesOfPiecesGroups["RefugeeDeco"] do
            if maRa() == true then
                Show(TablesOfPiecesGroups["RefugeeDeco"][i] )
            end
        end
    else
        showOnePiece(TablesOfPiecesGroups["container"])
    end

end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end
