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
end

function script.Killed(recentDamage, _)
    return 1
end
 