include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

center = piece "center"

function script.Create()
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    showOnePiece(TablesOfPiecesGroups["Loot"])
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitBlocking (unitID, false,  false, false, false, true, false, false)
    StartThread(threadStarter)
    if math.random(1,4) == 1 then
        dVal = math.random(1,4)*90
        Turn(center,z_axis, math.rad(dVal),0)
    else
        Turn(center,z_axis, math.rad(-90),0)
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function threadStarter()
    while true do
        if Spring.GetUnitTransporter(unitID) then
            while Spring.GetUnitTransporter(unitID) do Sleep(100) end
            selfDestroyDelayedOnDetach()
        end
    Sleep(100)
    end
end


function selfDestroyDelayedOnDetach()
    Sleep(15000)
    Spring.DestroyUnit(unitID, false, true)
end