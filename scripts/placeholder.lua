include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    echo(UnitDefs[unitDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    -- StartThread(AnimationTest)
    x,y,z = Spring.GetUnitPosition(unitID)
    echo("{name = \"placeholder\", x = "..x..", z = "..z..", rot = 0, scale = 1.000000}")
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

