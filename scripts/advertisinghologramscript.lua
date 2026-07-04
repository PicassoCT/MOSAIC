include "lib_Animation.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"



TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    StartThread(rotateProject)
end

rotor = piece("rotor")

function rotateProject()
    while true do
    hideAll(unitID)
    resetT(TablesOfPiecesGroups)
    Turn(rotor, x_axis, math.rad(math.random(-80, 0)), 0)
    Turn(rotor, y_axis, math.rad(math.random(360, 360)), 0)
    selectedPiece = showOnePiece(TablesOfPiecesGroups["adds"])
    measuredDistanceToGround = 4000
    WMove(selectedPiece, z_axis, measuredDistanceToGround + math.random(-300, 300), 150)
    Sleep(250)
end

