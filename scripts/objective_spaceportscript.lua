include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

x,y,z = Spring.GetUnitPosition(unitID)
isSeaUnit = 0 < Spring.GetGroundHeight(x,z)
Ground = piece("Ground")
Water = piece("Water")
function script.Create()
    echo(UnitDefs[myDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    Show(Water)

    showT(TablesOfPiecesGroups["DroneShip"])
    showT(TablesOfPiecesGroups["Capsule"])
    showT(TablesOfPiecesGroups["Gauntry"])
    if isSeaUnit then

    else
        Show(Ground)
        showT(TablesOfPiecesGroups["Chains"])
    end
end
--Booster1
--Booster2
--Booster2
--SpaceX_Falcon_Heavy001
function landBooster(booster)

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

