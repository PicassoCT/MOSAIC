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
    fatherID = fatherID or unitID
    x,y,z = Spring.GetUnitPosition(fatherID)
    id = Spring.CreateUnit("motorbike", x,y,z, math.random(1,4), myTeamID)
    Sleep(1)  
    if doesUnitExistAlive(id) == true then
        Spring.SetUnitLoadingTransport(fatherID, id)
    end
    Spring.DestroyUnit(unitID, false, true)
end

function script.Killed(recentDamage, _)
    return 1
end
