include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    StartThread(AnimationTest)

    for nr, part in pairs(TablesOfPiecesGroups["Container"]) do
        if maRa() == true then Hide(part) end
    end
end

function AnimationTest()
    StartThread(elevators)
    i = 0
    while true do
        i = (i + 1) % 10
        Sleep(1000)
        showT(TablesOfPiecesGroups["SigLightOn"])
        hideT(TablesOfPiecesGroups["SigLightOff"])
        Sleep(2000)
        hideT(TablesOfPiecesGroups["SigLightOn"])
        showT(TablesOfPiecesGroups["SigLightOff"])
        if i == 9 then
            Sleep(5000)
            showT(TablesOfPiecesGroups["SigLightOn"])
            hideT(TablesOfPiecesGroups["SigLightOff"])
            Sleep(2000)
        end
    end
end
elevatorHeight = 90
function elevators()
    while true do
        for nr, elevator in pairs(TablesOfPiecesGroups["Elevator"]) do
            Move(elevator, y_axis, -1 * elevatorHeight * math.random(0, 8), 50)
        end
        for nr, elevator in pairs(TablesOfPiecesGroups["Elevator"]) do
            WaitForMoves(elevator)
        end
        Sleep(500)
    end
end

function script.Killed(recentDamage, _) return 1 end
