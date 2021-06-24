include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}



function script.Create()
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.SetUnitNoSelect(unitID,true)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(findHeightPosition)
end

function findHeightPosition()
    Sleep(1)
    x,y,z = Spring.GetUnitPosition(unitID)
    mins, maxs = getExtremasInArea(math.max(0, x - window),math.max(0, z - window), 
        x + window, z + window, 
        128)
    Spring.SetUnitPosition(unitID, maxs.x, 0, maxs.z)
end

function script.Killed(recentDamage, _)
    return 1
end
 