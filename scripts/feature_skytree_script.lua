include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

Tree = piece("Tree")
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    x,y,z = Spring.GetUnitPosition(unitID)
    echo("{name = \"feature_skytree\", x = "..x..", z = "..z..", rot = 0 } ")

    hideAll(unitId)
    showOnePiece(TablesOfPiecesGroups["Add"])
    for i=1,10 do
        if randChanc(99) then
            if randChance(90) then
               Show(TablesOfPiecesGroups["ForrestPlate"][i])
            else       
                Show(TablesOfPiecesGroups["ErrorPlate"][i])
            end
        end
    end
    Show(Tree)        
    Spring.SetUnitAlwaysVisible(unitId, true)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
