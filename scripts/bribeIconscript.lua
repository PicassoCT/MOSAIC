include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
gameConfig = getGameConfig()
function script.HitByWeapon(x, z, weaponDefID, damage) end

 DollarSign = piece "DollarSign"
 Rotator1 = piece "Rotator1"


function script.Create()

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

        Spring.SetUnitNeutral(unitID,true)
        Spring.SetUnitBlocking(unitID,false)
        Spring.SetUnitNoSelect(unitID,true)
        Spring.MoveCtrl.Enable(unitID)
        ox, oy, oz = Spring.GetUnitPosition(unitID)
        Spring.SetUnitPosition(unitID, ox, oy + GameConfig.iconHoverGroundOffset, oz)
        value =42*randSign()
        Spin(DollarSign,z_axis,math.rad(value),0)
        Spin(Rotator1,z_axis,math.rad(value*-1),0)
        process(TablesOfPiecesGroups["Base"],
            function()
                Spin(id,z_axis,math.rad(value*randSign()),0)
            end
            )
        Spin(Base,z_axis,math.rad(value),0)
        StartThread(lifeTime, unitID, gameConfig.LifeTimeBribeIcon, true, false)
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end
