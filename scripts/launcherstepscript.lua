include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}



function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(animation)
end

function script.Killed(recentDamage, _)
    return 1
end

upaxis = 2

function moveForthBack(pieces, i)
            WMove(pieces,3, -150*i,0)
            Show(pieces)
            WMove(pieces,3, 0, 50*i)
            end

function animation()
    Rotor = piece"Rotor"
    Spin(TablesOfPiecesGroups["TextRotor"][1], y_axis, math.rad(-42))
    Spin(TablesOfPiecesGroups["TextRotor"][2], y_axis, math.rad(42))
    Spin(Rotor, y_axis, math.rad(42))

    while true do
        WMove(Rotor,upaxis,-1200,1200)
        hideT(TablesOfPiecesGroups["Step"])
        for i=1,#TablesOfPiecesGroups["Step"] do
            StartThread(moveForthBack, TablesOfPiecesGroups["Step"][i], i)
        end
        Sleep(100)
        WaitForMoves(TablesOfPiecesGroups["Step"])
        WMove(Rotor,upaxis,1200,1200)
        Sleep(1000)
    end
end
