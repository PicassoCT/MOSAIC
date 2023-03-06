include "lib_mosaic.lua"
include "lib_UnitScript.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
    StartThread(EyeSwivel)
    StartThread(ShowHideDayTime)
end

function ShowHideDayTime()
    DayCupola = piece("DayCupola")

    while true do
        hours, minutes, seconds, percent = getDayTime()
        if hours < 7 or hours > 19 then
            Hide(DayCupola)
            Sleep(1000)
        else
            Show(DayCupola)
            Sleep(25000)
        end
    end
end

function EyeSwivel()
    Eye = piece("Eye")
    while true do
        EyeSpeed = math.random(20, 100) / 50
        yVal= math.random(0,180)
        zVal= math.random(-15, 15)
        Turn(Eye,z_axis, math.rad(zVal), EyeSpeed)
        WTurn(Eye,y_axis, math.rad(yVal), EyeSpeed)
        Sleep(2000)
    end
end

function script.Killed(recentDamage, _)
    return 1
end
