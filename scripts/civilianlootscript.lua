include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
GameConfig = getGameConfig()
local TablesOfPiecesGroups = {}

center = piece "center"
shownPiece= center
barrel = piece "Loot024"

function script.Create()
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    loot = showOnePiece(TablesOfPiecesGroups["Loot"])
    shownPiece = TablesOfPiecesGroups["Loot"][loot]
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitBlocking (unitID, false,  false, false, false, true, false, false)
    StartThread(threadStarter)
    if math.random(1,4) == 1 then
        dVal = math.random(1,4)*90
        Turn(center,z_axis, math.rad(dVal),0)
    else
        Turn(center,z_axis, math.rad(-90),0)
    end
end

function script.Killed(recentDamage, _)
    if shownPiece == barrel then
        spawnCegAtUnit(unitID, "bigbulletimpact")
    end
    return 1
end

function threadStarter()
    while true do
        if Spring.GetUnitTransporter(unitID) then
            while Spring.GetUnitTransporter(unitID) do Sleep(100) end
            selfDestroyDelayedOnDetach()
        end
    Sleep(300)
    end
end


local lifeTimeMS= 15000
local spGetUnitTeam = Spring.GetUnitTeam
local gaiaTeamID = Spring.GetGaiaTeamID()
-- Allow for loot collecting
function selfDestroyDelayedOnDetach()
    while lifeTimeMS > 0 do
        Sleep(500)
        lifeTimeMS = lifeTimeMS - 500
        foreach(getAllNearUnit(unitID, 150),
            function(id)
                if gaiaTeamID ~= spGetUnitTeam(id) then
                    GG.Bank:TransferToTeam(GameConfig.lootCollectionReward, unitID, id, colourBlue)
                    Spring.DestroyUnit(unitID, false, true)
                end
            end)
    end
    Spring.DestroyUnit(unitID, false, true)
end