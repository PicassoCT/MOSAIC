include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

myTeamID = Spring.GetUnitTeam(unitID)

function script.Create()

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
   
    StartThread(loadRider)
end

function loadRider()
    Sleep(100)
    waitTillComplete(unitID)
    assert(fatherID)
    id = createUnitAtUnit(myTeamID, "motorbike", unitID, 0, 0, 0, fatherID, 0)
    if doesUnitExistAlive(id) == true then
        Spring.SetUnitLoadingTransport(fatherID, id)
    end
    Spring.DestroyUnit(unitID, false, true)
end

function script.Killed(recentDamage, _)
    return 1
end
