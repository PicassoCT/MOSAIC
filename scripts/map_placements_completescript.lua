include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"


TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    hideUnit(unitID)

    StartThread(lifeTime, unitID, 1500, true, false )
end


function script.Killed(recentDamage, _)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
