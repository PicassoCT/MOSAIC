include "createCorpse.lua"
include "lib_UnitScript.lua"
include "lib_OS.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    x,y,z = Spring.GetUnitPosition(unitID)
    StartThread(buildMemorial)
end

function candleLightFlickering(candleLight)
    Show(candleLight)
    while true do        
        randVal = math.random(1,360)
        Turn(candleLight,y_axis, math.rad(randVal),0)
        spinVal =  math.random(1,360) * randSign()
        Spin(candleLight,y_axis, math.rad(randVal),0)
        rest = math.random(1,5)*250
        Sleep(rest)
    end
end

function showSubSpins(pieceID)
   local pieceName = getUnitPieceName(unitID, pieceID)
   local spinName = pieceName.."Spin"
   if TablesOfPiecesGroups[spinName] and TablesOfPiecesGroups[spinName][1] then
        StartThread(candleLightFlickering, TablesOfPiecesGroups[spinName][1])   
    end
end

function waveBioHazardFlag()
    showT(TablesOfPiecesGroups["BioHazardFlag"])
    fractionOfPie = math.pi/7
    while true do
        _, _ ,_, windStrength = Spring.GetWind ( )

        secondsIn = Spring.GetGameFrame()/(30)
        accumulatedChange = 0
        for i=1, #TablesOfPiecesGroups["BioHazardFlag"] do
            tVal = math.sin(secondsIn + i* fractionOfPie) * windStrength
            accumulatedChange = accumulatedChange  -tVal
            Turn(TablesOfPiecesGroups["BioHazardFlag"][i], x_axis, math.rad(accumulatedChange + tVal), math.abs(tVal))
        end
        Sleep(250)
    end
end
function placeCandle(candle, rIndX, rIndY, maxIndex, sizeOfField)
    Show(candle)
    Move(candle, x_axis, (rIndX-(maxIndex*0.5))* sizeOfField + math.random(-sizeOfField,sizeOfField)*0.5, 0)
    Move(candle, y_axis, (rIndY-(maxIndex*0.5))* sizeOfField + math.random(-sizeOfField,sizeOfField)*0.5, 0)
    --StartThread(showSubSpins, candle)
    candleGrid[rIndX][rIndY] = true
    Turn(candle,y_axis, math.rad(val + math.random(-15, 15)),0)
end

bioHazardPole = piece("BiohazardWarn")
maxIndex = 4
sizeOfField= 50
candleGrid = makeTable(false, maxIndex, maxIndex)
function buildMemorial()
    attempts = 0
    val = math.random(-360, 360)

    popularity = math.random(5, 25)
    while popularity > 0 and attempts < 6 do

        dice = math.random(1, #TablesOfPiecesGroups["Candle"])
        if TablesOfPiecesGroups["Candle"][dice] then 

            candle = TablesOfPiecesGroups["Candle"][dice] 
            if candle then
                Move(candle,z_axis, -200, 0)
                Move(candle,z_axis, 0, 10)
                boolPlaced = false
         
                for rIndX = math.random(-4, 4), 4 do
                    rIndY = math.random(-4, 4)               
                    if candleGrid[rIndX] and candleGrid[rIndX][rIndY] == false  then
                       placeCandle(candle, rIndX, rIndY, maxIndex, sizeOfField)
                        popularity = popularity -1
                        boolPlaced= true
                        break
                    end
                end
                if not boolPlaced then
                for rIndX = -4, 4 do
                    rIndY = math.random(-4, 4)
                    if candleGrid[rIndX] and candleGrid[rIndX][rIndY] == false  then
                       placeCandle(candle, rIndX, rIndY, maxIndex, sizeOfField)
                        popularity = popularity -1
                        boolPlaced = true
                        break
                    end                
                end
                if not boolPlaced then
                    attempts = attempts +1
                end
                end
            end
        else
            attempts = attempts +1
        end
        Sleep(250)
    end

    if UnitDefs[Spring.GetUnitDefID(unitID)].name == "biohazardmemorial" then
        Show(bioHazardPole)
        StartThread(waveBioHazardFlag)
    else
        StartThread(lifeTime, unitID,  6 * 60 * 1000, true, false)
    end
end
