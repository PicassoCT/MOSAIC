include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}


function script.HitByWeapon(x, z, weaponDefID, damage)
    if damage > 50 then
        Explode(randDict(TablesOfPiecesGroups["RuinSub"]),  SFX.FALL + SFX.FIRE)
    end
    return damage
end

Ruin = piece("Ruin")
RuinCore = piece("RuinCore")
pieceID_NameMap = Spring.GetUnitPieceList(unitID)
Name_PieceIdMap = Spring.GetUnitPieceMap(unitID)
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    validatePieceGroups(TablesOfPiecesGroups)

    hideAll(unitID)
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

    if DeterministicRandom(unitID) < 0.25 then
        Show(RuinCore)
        foreach(TablesOfPiecesGroups["RuinCoreSub"],
            function(id)
                if DetMaRa(unitID) then 
                    Show(id) 
                    name = pieceID_NameMap[id]
                    if name then
                        subPiece = name.."Sub1"
                        if Name_PieceIdMap[subPiece]  and DetMaRa(unitID) then
                            Show(Name_PieceIdMap[subPiece])
                        end
                    end
                end
            end
            )
    end
    --Spring.SetUnitNoSelect(unitID, true)
end

function script.Killed(recentDamage, _)
    Move(Ruin,y_axis, -500, 190)
    Sleep(800)
    WMove(RuinCore,y_axis, -500, 190)
    
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

