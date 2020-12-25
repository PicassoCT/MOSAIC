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
    id =  piece(pieceName)
    px,py,pz = Spring.GetUnitPiecePosDir(unitID, id)
    dir =  math.random(1,4)
    Spring.CreateUnit("agriculture_decal01",  px, py, pz,dir, Spring.GetGaiaTeamID())
end

function script.Killed(recentDamage, _)
    return 1
end
function outsideMap(pieces)
x,y,z = Spring.GetUnitPiecePosDir(unitID, pieces)
if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then 
    return true 
end
return false
end

function deployPipes()
    StartThread(forInterval,1,6, Irrigation1)
    StartThread(forInterval,7,#TablesOfPiecesGroups["HyperLoop"], Irrigation2)
    spawnDecalAtPiece("Irrigation1")
    spawnDecalAtPiece("Irrigation002")
end

function forInterval(start,stop, endElement, irrigation)
    discoverSign= randSign()
    firstVal = math.random(-8, 8)*45
    while(outsideMap(irrigation)== true) do
       WTurn(TablesOfPiecesGroups["HyperLoop"][start], y_axis, math.rad(firstVal), 0)
       firstVal= firstVal + 45*discoverSign
    end

 accumulateddeg= 0
 for i = start, stop do
        if i ~= stop then
        nextElement= TablesOfPiecesGroups["HyperLoop"][i+1]
        if i == stop then nextElement = endElement end

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
               Sleep(1)
            end
         end
    end    
    accumulateddeg= accumulateddeg*-1
    WTurn(endElement, x_axis, math.rad(accumulateddeg), 0)
    showT(TablesOfPiecesGroups["HyperLoop"],start,stop)
end
