include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    -- echo(UnitDefs[unitDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    hideAll(unitID)
    showOnePiece(TablesOfPiecesGroups)
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

