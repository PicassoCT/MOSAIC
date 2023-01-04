include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    echo(UnitDefs[myDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(lifeTime, unitID,  60 * 1000, true, false,
                  function()
                    Spring.MoveCtrl.Enable(unitID, true)
                    for i=1, 200 do
                        x,y,z = Spring.GetUnitPosition(unitID)
                        h = Spring.GetGroundHeight(x,z)
                        y = y -3 
                        if h + 10 > y then
                            break
                        end
                        Spring.MoveCtrl.SetPosition(x,y,z)
                        Sleep(30)
                    end
                    Spring.MoveCtrl.Enable(unitID, false)
                  end)

    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    -- StartThread(AnimationTest)
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
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

