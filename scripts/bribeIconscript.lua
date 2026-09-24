include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}
local gameConfig = getGameConfig()
function script.HitByWeapon(x, z, weaponDefID, damage) end

 DollarSign = piece "DollarSign"



boolInMove = false
function script.Create()

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
        Spring.SetUnitNeutral(unitID,true)
        Spring.SetUnitBlocking(unitID,false)
        Spring.SetUnitNoSelect(unitID,false)
        Spring.MoveCtrl.Enable(unitID)
        local ox, oy, oz = Spring.GetUnitPosition(unitID)
        Spring.MoveCtrl.SetPosition(unitID, ox, oy + gameConfig.iconHoverGroundOffset, oz)
        value =42*randSign()
        Spin(DollarSign,y_axis,math.rad(value),0)
        hideT(TablesOfPiecesGroups["MoneyFlying"])
        foreach(TablesOfPiecesGroups["Money"],
            function(id)
                Spin(id,y_axis,math.rad(value*randSign()),0)
            end
            )
        foreach(TablesOfPiecesGroups["Title"],
            function(id)
                Spin(id,y_axis,math.rad(value*randSign()),0)
            end
            )
        -- game_police owns movement, duration and effects after construction.
        StartThread(percentageUpdate, gameConfig.Bribe.durationFrames * 1000 / 30)
        for i=1, #TablesOfPiecesGroups["MoneyFlying"] do
            StartThread(dropCashOnMove, TablesOfPiecesGroups["MoneyFlying"][i])
        end

end

function percentageUpdate(timeMs)
    waitTillComplete(unitID)
    local pieces = TablesOfPiecesGroups["Percentage"] or {}
    if #pieces == 0 then return end
    local step= math.ceil(timeMs/#pieces)
    for i=1, #pieces, 1 do
        Sleep(step)
        Hide(pieces[i])
    end
end

function dropCashOnMove(pieceName)
    while true do
        reset(pieceName)
        Show(pieceName)
        spinRand(pieceName, 15, 70)
        Move(pieceName,x_axis, math.random(-1000,1000), 250)
        Move(pieceName,y_axis, math.random(-1000,1000), 250)
        WMove(pieceName,z_axis, -5000, 1000)
        Hide(pieceName)
        timeSleepStep = math.random(1000,4000)
        Sleep(timeSleepStep)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end
