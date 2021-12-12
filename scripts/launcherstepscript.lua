include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

myDefID = Spring.GetUnitDefID(unitID)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(animation)
         StartThread(PlaySoundByUnitDefID, myDefID,
                            "sounds/icons/launchstepsiren.ogg", 1,
                            500, 2)
end

function script.Killed(recentDamage, _)
    return 1
end

upaxis = 2


function moveForthBack(pieces, i)
            Hide(pieces)
            WMove(pieces,3, -700*i,0)
            Show(pieces)
            WMove(pieces,3, 0, (700*i)/4)
            end

function animation()
    totalHeigth = 3500
    Rotor = piece"Rotor"
    Spin(TablesOfPiecesGroups["TextRotor"][1], y_axis, math.rad(-84))
    Spin(TablesOfPiecesGroups["TextRotor"][2], y_axis, math.rad(42))
    Spin(Rotor, y_axis, math.rad(42))

    while true do
        hideT(TablesOfPiecesGroups["Step"])
        WMove(Rotor,upaxis,-1200 + totalHeigth, 3200)
        val = math.sin(((Spring.GetGameFrame()/30 % 90)/90)*math.pi*2) * 500

        Move(TablesOfPiecesGroups["TextRotor"][1],y_axis, 0 + val, 500)
        WMove(TablesOfPiecesGroups["TextRotor"][2],y_axis, 0 + val, 500)
        for i=1,#TablesOfPiecesGroups["Step"] do
            StartThread(moveForthBack, TablesOfPiecesGroups["Step"][i], i)
        end
        Sleep(100)
        WaitForMoves(TablesOfPiecesGroups["Step"])
        WMove(Rotor,upaxis,1200 + totalHeigth,1200)
        Move(TablesOfPiecesGroups["TextRotor"][1],y_axis, 500 + val, 500)
        WMove(TablesOfPiecesGroups["TextRotor"][2],y_axis, -500 + val, 500)

        Sleep(2000)
    end
end
