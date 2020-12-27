include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
Irrigation1 = piece"Irrigation1"
Irrigation2 = piece"Irrigation002"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    resetAll(unitID)
    Spin(piece("Logo"),z_axis,math.rad(42),0) 

    StartThread(deployPipes)
    
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-120), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(145), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-189), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-145), 1)
    
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(230), 1)  
end

function spawnDecalAtPiece(pieceName)
    Sleep(500)

    px,py,pz = Spring.GetUnitPiecePosDir(unitID, pieceName)
    dir =  math.random(1,4)
    Spring.CreateUnit("agriculture_decal01",  px, py, pz,dir, Spring.GetGaiaTeamID())
end

function script.Killed(recentDamage, _)
    return 1
end
function outsideMap(pieces)
    assert(pieces)
x,y,z = Spring.GetUnitPiecePosDir(unitID, pieces)
if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then 
    return true 
end
return false
end

function deployPipes()
    StartThread(forInterval,1, 5, Irrigation1)
    Sleep(100)
    StartThread(forInterval,6 ,#TablesOfPiecesGroups["HyperLoop"], Irrigation2)
end

takenValues={}

function forInterval(start,stop, irrigation)
    discoverSign= randSign()
    rotationValue = math.random(-8, 8)*45
    attempts= 0
    while(outsideMap(irrigation)== true or takenValues[rotationValue] and attempts < 10) do
       WTurn(TablesOfPiecesGroups["HyperLoop"][start], y_axis, math.rad(rotationValue), 0)
       rotationValue= rotationValue + 45*discoverSign
       attempts = inc(attempts)
    end
    takenValues[rotationValue] = true

 accumulateddeg= 0
 for i = start, stop do
        if i ~= stop then
        nextElement= TablesOfPiecesGroups["HyperLoop"][i+1]
        if i == stop then nextElement = irrigation end

        boolIsAboveGround = false
        val= 0
        counter = 0
            while boolIsAboveGround == false and counter < 25 do
                x,y,z= Spring.GetUnitPiecePosDir(unitID, nextElement)
                gh =Spring.GetGroundHeight(x,z)
                counter = counter +1

                if y  > gh  +20 then
                    val = val - 1
                    accumulateddeg= accumulateddeg -1
                elseif y  < gh   +20  then
                    val = val + 1
                    accumulateddeg= accumulateddeg +1
                else
                    break
                end
                if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
                    Hide(nextElement)
                end
               WTurn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(val), 0)
            end
         end
    end    
    accumulateddeg= accumulateddeg*-1
    WTurn(endElement, x_axis, math.rad(accumulateddeg), 0)
    showT(TablesOfPiecesGroups["HyperLoop"],start,stop)
    StartThread(spawnDecalAtPiece, irrigation)
end
