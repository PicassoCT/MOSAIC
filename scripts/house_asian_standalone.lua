include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll()
    buildBuilding()

end

function buildBuilding()
    if randChance(5) then
        showOne(TablesOfPiecesGroups["StandAlone"], true)
        showOneDeterministic(TablesOfPiecesGroups["StandAloneLights"], unitID)
        boolDoneShowing = true
        return
    end
end
function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end



