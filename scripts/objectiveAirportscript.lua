include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
Airport = piece"Airport"
statusTable = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    setup()
    StartThread(comingAndGoing)
end

function setup()
    hideAll(unitID)
    Show(Airport)
    showT(TablesOfPiecesGroups["gateway"])
    for i=1, #TablesOfPiecesGroups["Shuttle"] do
        if maRa() == true then
        statusTableTablesOfPiecesGroups["Shuttle"][i] ="landed"
        Show(statusTableTablesOfPiecesGroups["Shuttle"][i])
        Show(statusTableTablesOfPiecesGroups["Engine"][i])
        else
            statusTableTablesOfPiecesGroups["Shuttle"][i] ="docked"
        end
    end
end

function comingAndGoing()
    while true do
        Sleep(10000)
        arrival()
        ferryingGoods()
        departure()
    end
end

function arrival()

end

function ferryingGoods()

end

function departure()
    
end

function script.Killed(recentDamage, _)
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

