include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}


local GameConfig = getGameConfig()
myTeamID = Spring.GetUnitTeam(unitID)

function script.Create()
    Spring.SetUnitBlocking(unitID, false)
    Spring.SetUnitAlwaysVisible(unitID, true)

    hideAll(unitID)
    signS= randSign()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(AnimationTest)
    process(TablesOfPiecesGroups["Text"],
        function(id)
            Show(id)
            value= signS*42
            Spin(id, y_axis, math.rad(value),42)
            signS = signS *-1
        end)

end

function AnimationTest()
    Sleep(100)

    showT(TablesOfPiecesGroups["Ring"])
    interval = 5
    while true do
        for i=1, #TablesOfPiecesGroups["Ring"] do
            timers = (((Spring.GetGameFrame()/30)+ i*((interval/2)/#TablesOfPiecesGroups["Ring"]) % interval)/interval)* math.pi*2
            Move(TablesOfPiecesGroups["Ring"][i],z_axis, 500 + math.sin(timers)*500, 666 )
        end
        Sleep(50)
    end
end

function script.Killed(recentDamage, _)
    return 1
end

