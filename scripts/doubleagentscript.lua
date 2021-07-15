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
        WMove(one, x_axis, 100, 100)
        WMove(other, x_axis, -100, 100)
        Sleep(500)
        WMove(one, x_axis, 0, 100)
        WMove(other, x_axis, 0, 100)
        Sleep(500)
    end
end

function script.Killed(recentDamage, _) return 1 end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
