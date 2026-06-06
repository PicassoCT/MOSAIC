include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"


local TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

 Tree = piece("tree")
function script.Create()
    
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    
    if Spring.GetUnitDefID(unitID) == UnitDefNames["cegtest"].id then
        x,y,z =Spring.GetUnitPosition(unitID)
        Spring.MoveCtrl.SetPosition(unitID, x,y+500,z) 
        echo("{name = \"placeholder\", x = "..x..", z = "..z..", rot = 0 } ")
     end   
    hideAll(unitId)
    showOne(TablesOfPiecesGroups["Add"])
    for i=1,10 do
        if randChanc(99) then
        if randChance(90)
           Show(TablesOfPiecesGroups["Panel"][i])
        else       
            Show(TablesOfPiecesGroups["ErrorPanel"][i])
        end
        end
    end
    end
end
Show(tree)
    
Spring.SetUnitAlwaysVisible(unitId, true)
end

function script.Killed(recentDamage, _)
    return 1
en
function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

