include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    x,y,z = Spring.GetUnitPosition(unitID)
    buildMemorial()
end

function candleLightFlickering(candleLight)
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
   subSpinPieceName = pieceName.."Spin"    
   if TableOfPiecesGroups[subSpinPieceName] then            
    for i=1, #TableOfPiecesGroups[subSpinPieceName] do
        spinPiece = TableOfPiecesGroups[subSpinPieceName][i]
        StartThread(candleLightFlickering, spinPiece)
    end
   end
end

function waveBioHazardFlag()
    showT(TablesOfPiecesGroups["bioHazardFlag"])
    fractionOfPie = math.pi/7
    while true do
      _, _ ,_, windStrength = Spring.GetWind ( )

      secondsIn = Spring.GetGameFrame()/(30* 25)
      accumulatedChange = 0
      for i=1, #TablesOfPiecesGroups["bioHazardFlag"] do
            tVal = math.sin(secondsIn + i* fractionOfPie) * windStrength
            accumulatedChange = accumulatedChange  -tVal
            Turn(TablesOfPiecesGroups["bioHazardFlag"][i], x_axis, math.rad(accumulatedChange + tVal), math.abs(tVal))
      end
    Sleep(250)
    end
end

bioHazardPole = piece("bioHazardPole")

maxIndex = 6
candleGrid = makeTable(false, maxIndex, maxIndex)
function buildMemorial()
    for i=1,#TablesOfPiecesGroups["Candle"] do
        if randChance(25) then
            local candle = TablesOfPiecesGroups["Candle"][i]
            Show(candle)
            rIndX, rIndY = math.random(1,maxIndex) - maxIndex*0.5, math.random(1,maxIndex) -maxIndex*0.5
            if candleGrid[rIndX][rIndY] == false then
            Move(candle, x_axis, rIndX* 10, 0)
            Move(candle, z_axis, rIndY* 10, 0)
            showSubSpins(candle)
            candleGrid[rIndX][rIndY]= true
            end
        end
    end

    if UnitDefNames[Spring.GetUnitDefID(unitID)].name = "biohazardmemorial" then
        Show(bioHazardPole)
        StartThread(waveBioHazardFlag)
    end
end
