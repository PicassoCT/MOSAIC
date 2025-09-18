include "lib_OS.lua"
include "lib_mosaic.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local hours   = 0
local minutes = 0
local seconds = 0
local percent = 0

local GameConfig = getGameConfig()
local pieceID_NameMap = Spring.GetUnitPieceList(unitID)
local TableOfPiecesGroups = {}
local cachedCopyDict ={}
local oldCachedCopyDict ={}

local lastFrame = Spring.GetGameFrame()
local crossRotatePiece1 =  piece("HoloSpin72")
local crossRotatePiece2 =  piece("HoloSpin74")
local jumpScareRotor = piece("jumpScareRotor")
hours, minutes, seconds, percent = getDayTime()
function clock()
    while true do
        hours, minutes, seconds, percent = getDayTime()
        Sleep(1000)
    end
end

--Error: [string "scripts/house_asian_hologram_script.lua"]:462: bad argument #1 to 'Spin' (number expected, got nil)
function updateCheckCache()
    local frame = Spring.GetGameFrame()
    if frame ~= lastFrame then   
        if oldCachedCopyDict ~= cachedCopyDict then
            oldCachedCopyDict = cachedCopyDict      
            GG.VisibleUnitPieces[unitID] = dictToTable(cachedCopyDict)
            lastFrame = frame
        end
    end
end

function ShowReg(pieceID)
    if pieceID == nil then return end
    Show(pieceID)
    cachedCopyDict[pieceID] = pieceID
    updateCheckCache()
end

function displayPieceTable(T)
    if type(T) == "number" then  return  pieceID_NameMap[T] end

    concatString = ""
    for i=1, #T do
       concatString= concatString.."|".. pieceID_NameMap[T[i]]
    end
    return concatString
end

function HideReg(pieceID)
    if pieceID == nil then return end
    --assert(pieceID_NameMap[pieceID], "Not a piece".. displayPieceTable(pieceID))
    Hide(pieceID)  
    cachedCopyDict[pieceID] = nil
    updateCheckCache()
end

local  pieceMap = Spring.GetUnitPieceMap(unitID)
-- > Hide all Pieces of a Unit
function showAllReg()
    for k, v in pairs(pieceMap) do ShowReg(v) end
end

-- > Hide all Pieces of a Unit
function hideAllReg()
    for k, v in pairs(pieceMap) do HideReg(v) end
end

-- > Hides a PiecesTable, 
function hideTReg(l_tableName, l_lowLimit, l_upLimit, l_delay)
    if not l_tableName then return end
    --assert( type(l_tableName) == "table" , UnitDefs[Spring.GetUnitDefID(unitID)].name.." has invalid hideT")
    boolDebugActive =  (lib_boolDebug == true and l_lowLimit and type(l_lowLimit) ~= "string")

    if l_lowLimit and l_upLimit then
        for i = l_upLimit, l_lowLimit, -1 do
            if l_tableName[i] then
                HideReg(l_tableName[i])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. l_lowLimit ..
                         " contains a empty entry")
            end

            if l_delay and l_delay > 0 then Sleep(l_delay) end
        end

    else
        for i = 1, table.getn(l_tableName), 1 do
            if l_tableName[i] then
                HideReg(l_tableName[i])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. l_lowLimit .. " contains a empty entry")
            end
        end
    end
end

-- >Shows a Pieces Table
function showTReg(l_tableName, l_lowLimit, l_upLimit, l_delay)
    if not l_tableName then
        Spring.Echo("No table given as argument for showT")
        assert(false)
        return
    end

    if l_lowLimit and l_upLimit then
        for i = l_lowLimit, l_upLimit, 1 do
            if l_tableName[i] then ShowReg(l_tableName[i]) end
            if l_delay and l_delay > 0 then Sleep(l_delay) end
        end

    else
        for k,v in pairs(l_tableName)do
            if v then
                ShowReg(v)
            end
        end
    end
end

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = spGetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

--Direction = piece("Direction")

px,py,pz = Spring.GetUnitPosition(unitID)

function technoDancer()
    while (true) do
        hideT(TableOfPiecesGroups["Dancer"])
        showOne(TableOfPiecesGroups["Dancer"])
        Sleep(1000)
        hideT(TableOfPiecesGroups["Dancer"])
        Sleep(1000)
    end

end

function restartHologram()
    Signal(SIG_CORE)
    SetSignalMask(SIG_CORE)
    resetAll(unitID)
    hideAllReg(unitID)
    deployHologram()
    StartThread(checkForBlackOut)
    StartThread(clock)
    StartThread(grid)
    if randChance(2) then
        StartThread(technoDancer)
    end

    if randChance(25) or isNearCityCenter(px,pz, GameConfig) then
        StartThread(showStreetSigns)
    end

    if randChance(25) or isNearCityCenter(px,pz, GameConfig) then
       Sleep(500)
       showHoloWall()
    end

    if randChance(10) or isNearCityCenter(px,pz, GameConfig) then
        StartThread(sakuraTree)
    end

    if randChance(5)  then
        StartThread(butterflyExplosion)
    end

    if randChance(10) or GG.GlobalGameState ~= GameConfig.GameState.normal then
        StartThread(pixelArt)
    end
end

function flapWing(wingPiece, wingPiece2, speedUp, speedDown)
    Turn(wingPiece, x_axis, math.rad(-35), speedUp)
    WTurn(wingPiece2, x_axis, math.rad(35), speedUp)

    Turn(wingPiece, x_axis, math.rad(-10), speedDown)
    WTurn(wingPiece2, x_axis, math.rad(10), speedDown)
    
    Turn(wingPiece,x_axis, math.rad(0), speedDown)
    WTurn(wingPiece2,x_axis, math.rad(0), speedDown)
end

function showButterflys()
    for i = 1, #TableOfPiecesGroups["Butterfly"] do
        butterfly = TableOfPiecesGroups["Butterfly"][i]
        ShowReg(butterfly)
        for k = 1, 2 do
            wing = piece("Butterfly"..i.."wing"..k)
           ShowReg(wing)
        end
    end 
end


function hideButterflys()
    for i=1, #TableOfPiecesGroups["Butterfly"] do
        butterfly = TableOfPiecesGroups["Butterfly"][i]
        HideReg(butterfly)
        for k=1, 2 do
            wing = piece("Butterfly"..i.."wing"..k)
           HideReg(wing)
        end
    end 
end


function resetButterflys()
   hideButterflys()
    val= math.random(5,15)
    Spin(ButterflyRotator,y_axis, math.rad(val),0)

    resetT(TableOfPiecesGroups["Butterfly"])
    for i=1, #TableOfPiecesGroups["Butterfly"] do
        butterfly = TableOfPiecesGroups["Butterfly"][i]
        val = math.random(1,360)
        Turn(butterfly, y_axis, math.rad(val) ,0)
        rotated = (i * 33)+ math.random(-5, 10)
        outValue = math.random(250, 3500)
        Move(butterfly, x_axis, outValue, 10)
        upValue = math.random(1000,19500)
        Move(butterfly, y_axis, upValue, math.random(10,100))
    end
   showButterflys()
end

ButterflyRotator = piece("ButterFlyRotator")
function butterflyExplosion()
    resetButterflys()
    while true do
        if randChance(1) then
           resetButterflys()        
        end

        for i=1, #TableOfPiecesGroups["Butterfly"] do
            if randChance(75)  then                
                wing1= ("Butterfly"..i.."wing"..1)
                wing2= ("Butterfly"..i.."wing"..2)
                assert(wing1)
                assert(wing2)
                StartThread(flapWing, piece(wing1), piece(wing2),  1, 2)
            end 
        end
       -- echoLoc(unitID,"butterflyExplosion at")
        Sleep(5000)
    end
end

function throwPetal(chip, interval)
    if maRa() then      
        Sleep(interval)
    end 
    sakuraValues =  GG.Sakura
    reset(chip)
    val = math.random(15, 55)*randSign()
    Spin(chip, x_axis, math.rad(val), 0)
    val = math.random(15, 55)*randSign()
    Spin(chip, z_axis, math.rad(val), 0)
    ShowReg(chip)

    randX = math.random(150, 1500) *sakuraValues.dirx
    randY = math.random(150, 1500) *sakuraValues.diry
    randZ = math.random(150, 1500) *sakuraValues.dirz

    mP(chip, randX, randY, randZ, sakuraValues.speed +  math.random(0,3)/10)
    Sleep(15000)
end


function setSakuraValue()
    if not GG.Sakura then GG.Sakura = {} end
    if not GG.Sakura.frame or GG.Sakura.frame < Spring.GetGameFrame() + (30 * 30) then
        GG.Sakura.frame =  Spring.GetGameFrame()
          GG.Sakura.dirx= randSign()
          GG.Sakura.diry= randSign()
          GG.Sakura.dirz= randSign()
          GG.Sakura.speed= math.random(1,5)/10
    end
end


function sakuraTree()
   chips = {}
   Sleep(100)
   sakura = piece("Sakura")
    for i=1, 12 do
        petalPiece= piece("Petal"..i)
        if petalPiece then
            chips[#chips +1] = petalPiece
        else
            echo("No petal piece for "..i)
        end
    end

    while true do
        if (hours > 16 or hours < 8)  then
            ShowReg(sakura)
            while (hours > 16 or hours < 8)  do
                setSakuraValue()
                restTime = math.random(15,20)*1000   
                interval = math.ceil(restTime/24)
                for i=1, 12 do    
                    chip= piece("Petal"..i)
                    StartThread(throwPetal, chip, math.random(1,12)*interval)  
                end
                Sleep(restTime)
            end

            foreach(chips,
                function(chip)
                    WaitForMoves(chip)
                    HideReg(chip)
                end)            
            HideReg(sakura)               
        end
        Sleep(1000)
    end
end

allGrids = nil

function showStreetSigns()
    Sleep(100)
    foreach(TableOfPiecesGroups["StreetSign"],
        function(id)
            if maRa() then
                ShowReg(id)
            end
        end)
end

function grid()
    Sleep(100)
    while true do
        if (hours > 19 or hours < 6) then
            theGrid = TableOfPiecesGroups["Grid"]
            assert(theGrid)
            boolFlip = maRa()
            upVal=math.random(3,4)
            lowVal= math.random(1,2)
            if boolFlip then Turn(theGrid[1], x_axis, math.rad(180), 0) end
            Sleep(33)
            for i= lowVal, upVal do 
                hideTReg(theGrid)
                ShowReg(theGrid[i])
                Turn(theGrid[i], y_axis, math.rad(i * 90),0)
                Sleep(33)
                if maRa()then
                    Sleep(66)
                end
            end
            for i= upVal, lowVal, -1 do 
                hideTReg(theGrid)
                ShowReg(theGrid[i])
                Turn(theGrid[i], y_axis, math.rad(i * 90),0)
                Sleep(33)
                if maRa()then
                    Sleep(66)
                end
            end
            if maRa() == maRa() then
                Sleep(500)
            end
            if boolFlip then Turn(theGrid[1], x_axis, math.rad(0), 0) end

        end
        Sleep(33)
    end
end

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TableOfPiecesGroups = getPieceTableByNameGroups(false, true)
    restartHologram()
end

function deployHologram()
    StartThread(HoloGrams)
end

function shapeSymmetry()
    for i=1, 10 do
        if not (maRa() == maRa()) or i < 4 then
            sympPieceOrgName = "Symmetry0"..i
            symPieceName = "Symmetry0"..(i + 10)
            a = piece(sympPieceOrgName)
            b = piece(symPieceName)
            randVal = math.random(1,8)*randSign()*45
            ShowReg(a)
            Turn(a, x_axis, math.rad(randVal), 0)
            ShowReg(b)
            orgVal = 0 
            if i == 1 then orgVal = 180 end
            symValue =  orgVal -randVal
            Turn(b, x_axis, math.rad(symValue), 0)
        end
    end
end


function showSubs(pieceID)
   local pieceName = getUnitPieceName(unitID, pieceID)
   subSpinPieceName = pieceName.."Sub"    
   if TableOfPiecesGroups[subSpinPieceName] then  
    hideTReg(TableOfPiecesGroups[subSpinPieceName] )              
    for i=1, #TableOfPiecesGroups[subSpinPieceName] do
        subPiece = TableOfPiecesGroups[subSpinPieceName][i]
        ShowReg(spinPiece)
    end
   end
end

function showSpins(pieceID)
   local pieceName = getUnitPieceName(unitID, pieceID)
   showSubs(piecID)
   subSpinPieceName = pieceName.."Spin"    
   if TableOfPiecesGroups[subSpinPieceName] then  
    hideTReg(TableOfPiecesGroups[subSpinPieceName] )              
    for i=1, #TableOfPiecesGroups[subSpinPieceName] do
        spinPiece = TableOfPiecesGroups[subSpinPieceName][i]
        ShowReg(spinPiece)
        Spin(spinPiece,y_axis, math.rad(-42 * randSign()),0)
    end
   end
end

function rotoScope()
    oldPiece = TableOfPiecesGroups["HoloLogo"][math.random(49,68)]
    while true do
        restTime = math.random(5,12)*100
        Sleep(restTime)
        newPiece = TableOfPiecesGroups["HoloLogo"][math.random(49,68)]
        HideReg(oldPiece)
        ShowReg(newPiece)
        oldPiece = newPiece
    end

end

logoPiece = nil
spinPieces = {}
jumpScarePieces = {}
function deterministiceSetup()

        if randChance(5) then
            StartThread(rotoScope)
            return
        end
       if randChance(25) then
           shapeSymmetry()
       end
        
        if randChance(75) then
            logoPiece = deterministicElement( getDeterministicRandom(getLocationHash(unitID), #TableOfPiecesGroups["HoloLogo"]), TableOfPiecesGroups["HoloLogo"])
            if logoPiece then
                showSpins(logoPiece)
                ShowReg(logoPiece)
                Spin(logoPiece, y_axis, math.rad(1.2)*randSign(), 0)
                if maRa() then
                    legoPiece, index = getSafeRandom(TableOfPiecesGroups["HoloLogo"])
                    if legoPiece then
                    showSpins(legoPiece)
                    ShowReg(legoPiece)
                    Spin(legoPiece, y_axis, math.rad(1.2)*randSign(), 0)
                    else
                        echo("No HologLogo for "..index)
                        assert(false)
                    end
                end
            end
        end
        nrSpins = unitID % 10
        for i=1, nrSpins, 1 do
            spinPiece = deterministicElement( getDeterministicRandom(getLocationHash(unitID), #TableOfPiecesGroups["HoloSpin"]), TableOfPiecesGroups["HoloSpin"])
            table.insert(spinPieces, spinPiece)
        end

        jumpScareNr = unitID % 5
        for i=1, jumpScareNr, 1 do
            jumpScare = deterministicElement( getDeterministicRandom(getLocationHash(unitID), #TableOfPiecesGroups["JumpScare"]), TableOfPiecesGroups["JumpScare"])
            table.insert(jumpScarePieces, jumpScare)
        end        
end

function moveJumpScare(id)
    reset(id)
    if maRa() then
        Turn(id, y_axis, math.rad(90), 0)
    end
    ShowReg(id)
    Move(id, x_axis, math.random(5000,15000), math.random(1000,4000))
    WaitForMoves(id)
    val = math.random(1000,8000)
    Sleep(val)
    HideReg(id)
end

local scale = 2500
local total = math.sqrt(36)
local mid = (total/2)*scale
local pixelSize = 64
local colT = {"R","G", "B"}
function getRandomColor()
    return colT[math.random(1,3)]
end


function getRandomPixel()
    colSelect = getRandomColor()
    colSelectPieces = TableOfPiecesGroups[colSelect]
    return colSelectPieces[math.random(1,#colSelectPieces)]
end

function RainDrop(pieces, delayMS, speed)
    if not pieceID then return end
    maxDistance = 4000
    downAxis = 2
    Sleep(delayMS)
    x,z = math.random(30,maxDistance)*randSign(), math.random(30,maxDistance)*randSign()
    y = math.sqrt((maxDistance-x)^2 + (maxDistance-z)^2)
    local pieceID = pieces[1]
    for i=1, #pieces do
        local pieceID = pieces[i]
        Move(pieceID, 1, x, 0)
        Move(pieceID, 3, z, 0)
        Move(pieceID, downAxis, y + (i*pixelSize), 0)
        Move(pieceID, downAxis, 0, speed)
        ShowReg(pieceID)
    --Spin(pieceID, downAxis, math.rad(42),0)
    end
    WMove(pieceID, downAxis, 0, speed)
    HideReg(pieceID)
end

function getRandomTimeZAxisFormula()
    formulas = {
        function(x, y, time, tScale) -- rings going outwards
            return (math.sqrt(x^2 + y^2) / math.sin(time)) * tScale
        end,
        function(x, y, time, tScale) -- radial ripple wave
            local dist = math.sqrt(x^2 + y^2)
            return math.sin(dist - time * 2) * tScale
        end,
        function(x, y, time, tScale) -- checkerboard wave
            return math.sin(x * 0.5 + time) * math.cos(y * 0.5 + time) * tScale
        end,
        function(x, y, time, tScale) -- spiraling vortex
            local angle = math.atan2(y, x)
            local radius = math.sqrt(x^2 + y^2)
            return math.sin(radius + time + angle) * tScale
        end,
        function(x, y, time, tScale) -- sphere popping up
            local radius = 5
            local dist = math.sqrt(x^2 + y^2)
            if dist <= radius then
                return math.sin(time) * (1 - dist / radius)^2 * tScale * 2
            else
                return 0
            end
        end,
        function(x, y, time, tScale) -- cube rising and falling
            local size = 6
            if math.abs(x) <= size and math.abs(y) <= size then
                return math.abs(math.sin(time)) * tScale * 2
            else
                return 0
            end
        end,
        function(x, y, time, tScale) -- simple face pattern
            local z = 0
            -- Head circle
            local dist = math.sqrt(x^2 + y^2)
            if dist < 6 then
                z = z + math.sin(time) * 0.2 * tScale
            end
            -- Eyes
            if (x > -3 and x < -1 and y > 1 and y < 3) or (x > 1 and x < 3 and y > 1 and y < 3) then
                z = z + math.sin(time * 2) * 0.5 * tScale
            end
            -- Mouth
            if x > -2 and x < 2 and y > -3 and y < -2 then
                z = z - math.sin(time * 3) * 0.3 * tScale
            end
            return z
        end
    }


    return formulas[math.random(1,#formulas)]
end

function getPixelEffect()
    local effects = {
        function()-- cube grid
            tScale = 25
            total = math.sqrt(math.floor(count(TableOfPiecesGroups["R"]) * 1.33))
            for x=1, total do
                for y=1, total do                    
                    for z= 1, total do
                        if not (x % 2 == 0 and y % 2== 0 and z % 2 == 0) then
                            randomPixel = getRandomPixel()
                            Move(randomPixel,x_axis, (x*tScale), 0)
                            Move(randomPixel,y_axis, (y*tScale), 0)
                            Move(randomPixel,z_axis, (z*tScale), 0)
                        end
                    end
                end
            end     
        end,
        function () -- random coloured cube      
            randomColA = getRandomColor()
            assert(TableOfPiecesGroups[randomColA], randomColA )
            total = math.ceil(math.sqrt(count(TableOfPiecesGroups[randomColA]))) 
            for x=1, total do
                for y=1, total do
                    for z= 1, total do
                        randomPixel = getRandomPixel()
                        if randomPixel then
                            Move(randomPixel,x_axis, (x*scale)- mid, 0)
                            Move(randomPixel,y_axis, (y*scale), 0)
                            Move(randomPixel,z_axis, (z*scale)- mid, 0)
                            ShowReg(randomPixel)
                        end
                    end
                end
            end
        end,
        function() -- plane of pixelart
            time = math.random(10,35)* 1000
            randomColA = getRandomColor()
            assert(TableOfPiecesGroups[randomColA], randomColA )
            total = math.ceil(math.sqrt(count(TableOfPiecesGroups[randomColA])))
            timeFormula = getRandomTimeZAxisFormula()
            interPolationStep = 125
            tScale = 25
            while (time > 0 ) do
                for pxIndex = 1, #TableOfPiecesGroups[randomColA] do
                    px = TableOfPiecesGroups[randomColA][pxIndex]
                    for x=1, total do
                        for y=1, total do
                            Move(px, x_axis, (x * tScale) - mid, 0)
                            Move(px, y_axis, (y * tScale), 0)
                            Move(px, z_axis, timeFormula(x - total*0.5, y - total*0.5, time, tScale), 0)
                            ShowReg(px)
                        end
                    end
                end           
                Sleep(interPolationStep)
                time = time - interPolationStep
            end
        end,
        function() -- pixel line error
            direction = math.random(1,3)
            otherValues = {}
            for x=1,3 do otherValues[x] = scale*(math.random(-10,10)/10) end
            for i=1, 32 do
                randomPixel = getRandomPixel()
                for k=1,3 do
                    if randomPixel then
                        if k ~= direction then
                            Move(randomPixel,direction, (i*pixelSize), 0)
                        else
                            Move(randomPixel,k, otherValues[k], 0)
                        end
                        ShowReg(randomPixel)
                    end
                end
            end
        end,
        function () -- chase the rain 
             while isRaining(hours) do
              
                color = colT[math.random(1,3)]
                    
                local delayMS = math.random(1,5)*1000

                RainDrop(TableOfPiecesGroups[color], delayMS, math.pi * 2000)
                Sleep(100)
            end
        end   ,
        function()-- cached copy artifacts
            for k, cachedPiece in pairs(cachedCopyDict) do
                if cachedPiece then
                    pieceInfo = Spring.GetUnitPieceInfo(unitID, cachedPiece) 
                    randomPixel= getRandomPixel()
                    for p=1,math.random(2,32) do                 
                        x = getRandomArgument(pieceInfo.min[1], pieceInfo.max[1])
                        y = getRandomArgument(pieceInfo.min[2], pieceInfo.max[2])
                        z = getRandomArgument(pieceInfo.min[3], pieceInfo.max[3])
                        movePieceToPiece(unitID, randomPixel, cachedPiece, 0, {x=x, y=y, z=z})
                    end
                end

            end
        end
    }
    return effects[math.random(1,#effects)]
end


function pixelArt()
    while true do
       -- echo("PixelArt active at"..locationstring(unitID))
        pixelEffect = getPixelEffect()
        pixelEffect()
        restVal= math.random(1,5)*250
        Sleep(restVal)
        hideTReg(TableOfPiecesGroups["R"])
        hideTReg(TableOfPiecesGroups["G"])
        hideTReg(TableOfPiecesGroups["B"])
        restVal= math.random(1,15)*1000
       Sleep(restVal)
    end
end

function HoloGrams()
    Signal(SIG_HOLO)
    SetSignalMask(SIG_HOLO)
    deterministiceSetup()
    Spin(crossRotatePiece1, z_axis, math.rad(42), 0)
    Spin(crossRotatePiece2, x_axis, math.rad(42), 0)

    while true do
        if logoPiece then
            ShowReg(logoPiece)
        end
        for i=1, #spinPieces do
            ShowReg(spinPieces[i])
            Spin(spinPieces[i], y_axis, math.rad(math.random(5,10) * randSign()) , math.pi/3)
        end
        WTurn(jumpScareRotor, y_axis, math.rad(math.random(0,180) * randSign()) ,0)
        for i=1, #jumpScarePieces do
            StartThread(moveJumpScare, jumpScarePieces[i])
        end
        
        Sleep(9000)
    end
end


function turnPixelOff(pixel)
    if pixel then
        HideReg(pixel)
    end
end

function turnPixelOn(pixel)
    if pixel then
        ShowReg(pixel)
    end
end

function showHoloWall()
    HoloPieces = {}
    AltHoloPieces = {}    

    hideTReg(TableOfPiecesGroups["HoloTile"])
    step = 6*4
    hindex = math.random(0,(#TableOfPiecesGroups["HoloTile"]/step)-1)
    althindex = math.random(0,(#TableOfPiecesGroups["HoloTile"]/step)-1)
    if maRa() == maRa() then
            ai= althindex * step
        for i=hindex * step,  (hindex+1) * step, 1 do
            if TableOfPiecesGroups["HoloTile"][i] then
                if (maRa() == maRa()) ~= maRa() then
                    HideReg(TableOfPiecesGroups["HoloTile"][i])
                else
                    HoloPieces[#HoloPieces +1] = TableOfPiecesGroups["HoloTile"][i]
                    if TableOfPiecesGroups["HoloTile"][ai] then
                        AltHoloPieces[#AltHoloPieces +1] = TableOfPiecesGroups["HoloTile"][ai]
                    end
                    ShowReg(TableOfPiecesGroups["HoloTile"][i])
                end
            end
            ai= ai+1
        end
        HoloFlicker(HoloPieces, AltHoloPieces)   
    end
    --TODO the engine has a problem, right here and then. No error on erroneous access, just dead function and worser still, post processing shutd
    --showT(TableOfPiecesGroups["HoloTile"],index * step, (index+1) * step)
end

local fiveMinutes = 5 * 60 * 1000
local fiveSecondsInFrames = 5 * 30
function checkForBlackOut()
    while true do
        timeOutActive, timeoutTimeMs =checkSetTimeOutConditions()
        if timeOutActive then 
            Signal(SIG_HOLO)
            Sleep(500)
            hideAllReg(unitID)
            Sleep(timeoutTimeMs)
            deployHologram()
            GG.BlackOutDeactivationTime[unitID] = nil     
            boolExternalTimeOutActive = false       
        end
    Sleep(1000)
    end
end

function setTimeOutExternal(timeoutMs)
    boolExternalTimeOutActive = true
    storedExternalTimeOut = timeoutMs
end

boolExternalTimeOutActive = false
storedExternalTimeOut = 0
function checkSetTimeOutConditions()
    timeoutMs = 0
    if  GG.BlackOutDeactivationTime and  GG.BlackOutDeactivationTime[unitID] then
        return true, fiveMinutes
    end

    if boolExternalTimeOutActive == true then 
        return true, storedExternalTimeOut
    end

    return false, 0
end

function fadeIn(piecesTable, rest)
    hideTReg(piecesTable)
    for i = 1, #piecesTable do
        --assert(piecesTable[i], i.." not in piecesTable")
        ShowReg(piecesTable[i])
        Sleep(rest)
    end
end

function fadeOut(piecesTable, rest)
    --dissappearing
    for i =  #piecesTable, 1, -1 do
        --assert(piecesTable[i], i.." not in piecesTable")
        HideReg(piecesTable[i])
        Sleep(rest)
    end
    hideTReg(piecesTable)
end

function localflickerScript(flickerGroup,  NoErrorFunction, errorDrift, timeoutMs, maxInterval, boolDayLightSavings, minImum, minMaximum)
    --assert(flickerGroup)
    local fGroup = flickerGroup
    if not minImum then minImum = 2 end 
    if not minMaximum then minMaximum = #flickerGroup end

    flickerIntervall = math.ceil(1000/25)
    boolNewDay = true
    toShowTableT= {}
    while true do
        hideTReg(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup"..getUnitPieceName(unitID, fGroup[1]))
        Sleep(500)
        if boolDayLightSavings == nil or ( boolDayLightSavings == true and 
            (hours > 17 or hours < 7)) and isANormalDay() then
                if boolNewDay == true then
                    toShowTableT= {}
                    for x=1,math.random(minImum,minMaximum) do
                        toShowTableT[#toShowTableT+1] = fGroup[math.random(1,#fGroup)]
                    end
                    boolNewDay = false
                end

                for i=1,(3000/flickerIntervall) do
                    if i % 2 == 0 then      
                       showTReg(toShowTableT) 
                    else
                        hideTReg(toShowTableT) 
                    end
                    if NoErrorFunction() == true then showTReg(toShowTableT) end
                    for ax=1,3 do
                        moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
                    end
                    Sleep(flickerIntervall)
                end
                hideTReg(toShowTableT)
        else
            boolNewDay = true
        end
        breakTime = math.random(1,maxInterval)*timeoutMs
        Sleep(breakTime)
    end
end

function showOne(T)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then   
            ShowReg(v)          
            return v
        end
    end
end

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T, true)
    else
        return
    end
end

function showOneOrAll(T)
    if not T then return end
    
    if chancesAre(10) > 0.5 then
        return showOne(T)
    else
        for num, val in pairs(T) do 
            ShowReg(val)
        end
        return
    end
end


function HoloFlicker(tiles,alttiles)
    if not tiles or #tiles < 2 then return end
    holoDecoFunctions= {}
        --dead pixel
    holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
                                one = math.random(1,#tiles)
                                if not tiles[one] then return end
                                tile =tiles[one]
                                if tile then
                                    for i=1,5 do
                                        turnPixelOff(tile)
                                        restTimeMs = 250*i
                                        Sleep(restTimeMs)
                                        reset(tile)
                                        Sleep(restTimeMs)
                                    end
                                        turnPixelOff(tile)
                                        restTimeMs = (math.random(1,100)/100)*10000
                                        Sleep(restTimeMs)
                                        for i=1, #tiles do
                                            turnPixelOn(tiles[i])
                                        end
                                        Sleep(restTimeMs)
                                 end    
                            end 

    --Send Pixel drifting upwards
    holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
                                function moveUpardwsFlicker(tile)
                                    Show(tile)
                                    dist = math.random(100,250)
                                    Move(tile, y_axis,  dist, 25)   
                                    WaitForMoves(tile)
                                    HideReg(tile)
                                    reset(tile)
                                end
                                for k, v in pairs(tiles) do
                                    StartThread(moveUpardwsFlicker, v)
                                end
                                Sleep(250)
                                WaitForMoves(tiles)
                                Sleep(10000)
                            end
    --whole wall flicker dead
    holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
                                for k, v in pairs(tiles) do
                                    turnPixelOff(v)
                                end
                                restTimeMs = (math.random(1,500)/100)*10000
                                Sleep(restTimeMs)
                                for i=1, #tiles do
                                    turnPixelOn(tiles[i])
                                end
                            end 
    --short dead line
    holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
                                for i=1,#tiles, 6 do
                                    for j=i, i+6 do
                                       turnPixelOff(tiles[j])
                                    end                     
                                    restTimeMs = (math.random(1,100)/100)*1000
                                    Sleep(restTimeMs)
                                    for j=i, i+6 do
                                       turnPixelOn(tiles[j])
                                    end                                 
                                end
                            end 
    --Hide one Tile
    holoDecoFunctions[#holoDecoFunctions+1] = function (tiles)
            dice = getDeterministicRandom(unitID, #tiles) +1
            tileFallingOff = tiles[dice]
            if tileFallingOff then
                WMove(tileFallingOff,y_axis, -10, 100)
                HideReg(tileFallingOff)
                restTime = math.random(1,100)*25000
                Sleep(restTime)
                reset(tileFallingOff)
                Show(tileFallingOff)
            end
        end
    --scaleflair effect
    holoDecoFunctions[#holoDecoFunctions+1] = function (tiles)
            axis = y_axis
            for i=1, #tiles do
                factor = ((i%6)+1)/6
                fraction = factor* 45
                Move(tiles[i], z_axis, factor *-20 , 15)
                Turn(tiles[i], axis, math.rad(fraction), 5)
            end
            WaitForTurns(tiles)
            Sleep(5000)
            for i=1, #tiles do
                Move(tiles[i], z_axis, 0 , 15)
                Turn(tiles[i], axis,0, 5)
            end
            WaitForTurns(tiles)
            WaitForMoves(tiles)
        end
    --whole wall flicker dead
    holoDecoFunctions[#holoDecoFunctions+1]= function(tiles, alttiles)
                                for k, v in pairs(tiles) do
                                    turnPixelOff(v)                                    
                                end
                                WaitForTurns(tiles)                                
                                restTimeMs = (math.random(1,500)/100)*10000
                                Sleep(restTimeMs)
                                hideTReg(tiles)
                                for k, v in pairs(alttiles) do
                                    turnPixelOff(v)
                                end
                                showTReg(alttiles)
                                for i=1, #alttiles do
                                    turnPixelOn(alttiles[i])
                                end
   
                                restTimeMs = (math.random(1,500)/100)*10000
                                Sleep(restTimeMs)
                                hideTReg(alttiles)
                                showTReg(tiles)
                                for i=1, #tiles do
                                    turnPixelOn(tiles[i])
                                end
                            end 
    mergedTiles = mergeTables(tiles, alttiles)
    while true do
        Sleep(10000)
        for i=1, #tiles do
            turnPixelOn(tiles[i])
        end
        showTReg(tiles)
        dice= math.random(1, #holoDecoFunctions)
        --lecho("HololWallFunction"..dice)
        hideTReg(mergedTiles)
        holoDecoFunctions[dice](tiles, alttiles)
    end
end
