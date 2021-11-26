include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
center= piece"PowerPlant"
heightOfsset= nil
function script.Create()
    Spring.SetUnitBlocking(unitID,false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Mirror"])
    Show(TablesOfPiecesGroups["Mirror"][math.random(1,#TablesOfPiecesGroups["Mirror"])])

    sensorTurn(TablesOfPiecesGroups["PowerTower"][1])
    tValue = math.random(1, 10) / 10
    for i = 2, #TablesOfPiecesGroups["PowerPillar"], 1 do
        Turn(TablesOfPiecesGroups["PowerPillar"][i], y_axis, math.rad(tValue), 0)
    end

    StartThread(camAnimation)
    heightOfsset= getObjectiveAboveGroundOffset(unitID)
    Move(center,y_axis, heightOfsset, 0)
end

 orgUnitHeigth= getUnitGroundHeigth(unitID)
 maxdepth= orgUnitHeigth
function sensorTurn(tower)
    hideT(TablesOfPiecesGroups["PowerPillar"])
    lowestDeg= 0
    x,y,z =Spring.GetUnitPosition(unitID)
    lowestValue=Spring.GetGroundHeight(x,z)
   
    for k = 1, #TablesOfPiecesGroups["PowerPillar"] do
        Show(TablesOfPiecesGroups["PowerPillar"][k])
        for i = 1, 360, 10 do
            WTurn(tower, y_axis, math.rad(i), 0)

            x, y, z = Spring.GetUnitPiecePosDir(unitID,
                                                TablesOfPiecesGroups["PowerPillar"][k])

            if k == #TablesOfPiecesGroups["PowerPillar"] then
                hval = Spring.GetGroundHeight(x,z)
                if hval < lowestValue then
                    lowestValue = hval
                    lowestDeg = i
                end
            end

            if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
                break
            end
        end
    end

    u = math.random(1, 360)
    WTurn(tower, y_axis, math.rad(u), 0)

    while (heightOfsset == nil)do
        Sleep(10)
    end
    WTurn (TablesOfPiecesGroups["PowerPillar"][1],y_axis,math.rad(lowestDeg),0)
    for k = 1, #TablesOfPiecesGroups["PowerPillar"] do
        x, y, z = Spring.GetUnitPiecePosDir(unitID, TablesOfPiecesGroups["PowerPillar"][k])
        gh = Spring.GetGroundHeight(x,z) -orgUnitHeigth
        Move(TablesOfPiecesGroups["PowerPillar"][k],y_axis, -heightOfsset,0)
    end

end

function camAnimation()
    while true do
        for i = 1, #TablesOfPiecesGroups["Cam"] do
            local cam = TablesOfPiecesGroups["Cam"][i]

            if i ~= 3 and i ~= 5 then
                Move(cam, z_axis, math.random(0, 250), math.random(3, 12))
            else
                Move(cam, x_axis, math.random(-750, 0), math.random(3, 25))
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

