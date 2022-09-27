include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
local ecmIconTypes = getECMIconTypes(UnitDefs)
function script.HitByWeapon(x, z, weaponDefID, damage) end
GameConfig= getGameConfig()

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
        StartThread(hoverAboveGround, unitID, GameConfig.iconHoverGroundOffset, 0.3)  
        Spring.SetUnitNeutral(unitID,true)
        Spring.SetUnitBlocking(unitID,false)
        Spring.MoveCtrl.Enable(unitID)
        ox, oy, oz = Spring.GetUnitPosition(unitID)
        Spring.SetUnitPosition(unitID, ox, oy + GameConfig.iconHoverGroundOffset, oz)

  
     StartThread(eatAIcon)
end

function eatAIcon()
    boolFoundSomething = false
    while true do
        foreach(getAllNearUnit(unitID, 100),
            function (id)
                defID = Spring.GetUnitDefID(id)
                if ecmIconTypes[defID] then
                    return id
                end
            end,
            function (id)
                if Spring.GetUnitTeam(id) ~= myTeamID then
                    Spring.DestroyUnit(id, false, true)
                    boolFoundSomething = true
                end
            end
            )
        Sleep(500)
        if boolFoundSomething then
            Spring.DestroyUnit(unitID, false, true)
        end
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end



