include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    resetAll(unitID)
    val = math.random(-360, 360)
    Turn(TablesOfPiecesGroups["HyperLoop"][1], y_axis, math.rad(val), 0)
    Turn(TablesOfPiecesGroups["HyperLoop"][6], y_axis, math.rad(val), 0)
    hideT(TablesOfPiecesGroups["HyperLoop"])
    StartThread(forInterval,1,6)
    StartThread(forInterval,7,#TablesOfPiecesGroups["HyperLoop"])
end

function script.Killed(recentDamage, _)
    return 1
end


function forInterval(start,stop)
    hideT(TablesOfPiecesGroups["HyperLoop"],start,stop)
 for i = start, stop do
        if i ~= stop then
        nextElement= TablesOfPiecesGroups["HyperLoop"][i+1]
        thisElement= TablesOfPiecesGroups["HyperLoop"][i]
        boolIsAboveGround = false
        val= 0
        counter = 0
            while boolIsAboveGround == false and counter < 10 do
                x,y,z= Spring.GetUnitPiecePosDir(unitID, nextElement)
                gh =Spring.GetGroundHeight(x,z)
                counter = counter +1

                if y  > gh + 50 then
                    val = val - 1
                elseif y  < gh + 50 then
                    val = val + 1
                else
                    break
                end
                if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
                    Hide(thisElement)
                else
                    Show(thisElement)
                end
               WTurn(thisElement, x_axis, math.rad(val), 0)
               Sleep(1)
            end
         end
    end    
  
    showAll()
end