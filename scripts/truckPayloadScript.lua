include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"


TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)

function attachPayload(payLoadID, id)
    if payLoadID then
           Spring.SetUnitAlwaysVisible(payLoadID,true)

           Spring.UnitAttach(id, payLoadID, TablesOfPiecesGroups["RefugeeDeco"][math.random(1,#TablesOfPiecesGroups["RefugeeDeco"])])
           return payLoadID
    end
end

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
        StartThread(delayedAttachCivilianLoot)

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

function delayedAttachCivilianLoot()
    Sleep(500)
    civilianLootID = createUnitAtUnit(myTeamID, "civilianloot", unitID)
    attachPayload(civilianLootID, unitID)

end
