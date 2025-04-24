include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)

function script.HitByWeapon(x, z, weaponDefID, damage)
    if damage > 50 then
        Explode(randDict(TablesOfPiecesGroups["RuinSub"]),  SFX.FALL + SFX.FIRE)
    end
    return damage
end

Ruin = piece("Ruin")
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Show(Ruin)
    foreach(TablesOfPiecesGroups["RuinSub"],
        function(id)
            if maRa() then 
                Show(id) 
            else
                Hide(id)
            end
        end
        )
    Spring.SetUnitNoSelect(unitID, true)
end

function script.Killed(recentDamage, _)
    WMove(Ruin,y_axis, -500, 190)
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

