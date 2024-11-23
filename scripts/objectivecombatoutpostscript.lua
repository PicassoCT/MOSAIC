include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitBlocking(unitID,false)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    -- StartThread(AnimationTest)
    makeWeaponsTable()
end



function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end



function mgAimFunc(weaponID, heading, pitch)
    WTurn(TablesOfPiecesGroups["Gun"][weaponID], y_axis, heading, 5)
    return true
end

function mgFireFunc(weaponID, heading, pitch)
    return true
end


WeaponsTable = {}
function makeWeaponsTable()
    for i=1, #TablesOfPiecesGroups["Gun"] do
    WeaponsTable[i] = {
        aimpiece = TablesOfPiecesGroups["Gun"][i],
        emitpiece = TablesOfPiecesGroups["Gun"][i],
        aimfunc = mgAimFunc,
        firefunc = mgFireFunc
    }
    end
end

function script.AimFromWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].aimpiece
    end
end

function script.QueryWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].emitpiece
    end
end

function script.AimWeapon(weaponID, heading, pitch)
    if WeaponsTable[weaponID] and WeaponsTable[weaponID].aimfunc then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)    
    end
    return false
end