include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Mirror"])
    Show(TablesOfPiecesGroups["Mirror"][math.random(1,
                                                    #TablesOfPiecesGroups["Mirror"])])

    sensorTurn(TablesOfPiecesGroups["PowerTower"][1])
    tValue = math.random(1, 10) / 10
    for i = 1, #TablesOfPiecesGroups["PowerPillar"], 1 do
        Turn(TablesOfPiecesGroups["PowerPillar"][i], y_axis, math.rad(tValue), 0)
    end

    StartThread(camAnimation)
end

function sensorTurn(tower)
    hideT(TablesOfPiecesGroups["PowerPillar"])
    for k = 1, #TablesOfPiecesGroups["PowerPillar"] do
        Show(TablesOfPiecesGroups["PowerPillar"][k])
        for i = 1, 360, 10 do
            WTurn(tower, y_axis, math.rad(i), 0)

            x, y, z = Spring.GetUnitPiecePosDir(unitID,
                                                TablesOfPiecesGroups["PowerPillar"][k])

            if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
                return
            end
        end
    end

    u = math.random(1, 360)
    WTurn(tower, y_axis, math.rad(u), 0)
end

function camAnimation()
    while true do
        for i = 1, #TablesOfPiecesGroups["Cam"] do
            local cam = TablesOfPiecesGroups["Cam"][i]

            if i ~= 3 and i ~= 5 then
                Move(cam, z_axis, math.random(0, 50), math.random(3, 12))
            else
                Move(cam, x_axis, math.random(-200, 0), math.random(3, 25))
            end
        end
        WaitForMoves(TablesOfPiecesGroups["Cam"])
        Sleep(1000)
    end
end

function script.Killed(recentDamage, _)
    for k, v in pairs(TablesOfPiecesGroups) do
        if maRa() == true then
            explodeT(v, SFX.SHATTER)
        else
            explodeT(v, SFX.FALL)
        end
        hideT(v)
    end
    return 1
end

