include "createCorpse.lua"
include "lib_mosaic.lua"
include "lib_UnitScript.lua"


local TablesOfPiecesGroups = {}
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 

Icon = piece("Icon")
local ToShowTable = {piece("House")}
function script.HitByWeapon(x, z, weaponDefID, damage) end
boolHouseHidden = false

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    -- StartThread(AnimationTest)
    x,y,z = Spring.GetUnitPosition(unitID)
       StartThread(buildBuilding)
end

local RoofTopPieces ={}
function registerRooftopSubPieces(pieceToShow)
    name = pieceNr_pieceName[pieceToShow].."Roof"
    if TablesOfPiecesGroups[name] then
        for nr,id in pairs(TablesOfPiecesGroups[name]) do
            RoofTopPieces[#RoofTopPieces +1] = id
        end
    end
end


function buildBuilding()
  hideAll(unitID)
  Show(Icon)
  registerRooftopSubPieces(piece("House"))
  Sleep(9000)
  showHouse()
end

function showHouse()
    boolHouseHidden = false
    showT(ToShowTable)
    Hide(Icon)
end

function hideHouse()
    boolHouseHidden = true
    hideT(ToShowTable)
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

function traceRayRooftop(  vector_position, vector_direction)
    return  GetRayIntersectPiecesPosition(unitID, RoofTopPieces, vector_position, vector_direction)
end


