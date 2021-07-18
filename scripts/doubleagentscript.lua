include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
Text = piece"Text"
center = piece "center"
one = piece "One"
other = piece "Other"
Rotor = piece "Rotor"

if not center then
    echo("Unit of type" .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no center")
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(animation)
    StartThread(onDeCloakNeverRecloak, unitID)
    Spin(Rotor, z_axis, math.rad(42),0)
    Hide(Rotor)
    Spring.SetUnitBlocking ( unitID, false, false, false, false, false, false, false ) 
end

function animation()
    while true do
        axisDice = 1
        Movementsize = 250
        WMove(one, axisDice, Movementsize, Movementsize)
        WMove(other, axisDice, -1*Movementsize, Movementsize)
        Sleep(500)
        WMove(one, axisDice, 0, Movementsize)
        WMove(other, axisDice, 0, Movementsize)
        Sleep(500)
    end
end

function script.Killed(recentDamage, _) return 1 end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
