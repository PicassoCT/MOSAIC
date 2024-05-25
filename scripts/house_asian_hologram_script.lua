include "lib_OS.lua"
include "lib_mosaic.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local hours  =0
local minutes=0
local seconds=0
local percent=0

local GameConfig = getGameConfig()
local pieceID_NameMap = Spring.GetUnitPieceList(unitID)
local cachedCopy ={}
local lastFrame = Spring.GetGameFrame()
local TableOfPiecesGroups = {}
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

function updateCheckCache()
  local frame = Spring.GetGameFrame()
  if frame ~= lastFrame then 
    if not GG.VisibleUnitPieces then GG.VisibleUnitPieces = {} end
    if GG.VisibleUnitPieces[unitID] ~= cachedCopy then
        GG.VisibleUnitPieces[unitID] = cachedCopy
        lastFrame = frame
    end
  end
end

function ShowReg(pieceID)
    if not pieceID then return end
    Show(pieceID)
    table.insert(cachedCopy, pieceID)
    updateCheckCache()
end

function HideReg(pieceID)
    if not pieceID then return end
    Hide(pieceID)  
    --TODO make dictionary for efficiency
    for i=1, #cachedCopy do
        if cachedCopy[i] == pieceID then
            table.remove(cachedCopy, i)
            break
        end
    end
    updateCheckCache()
end

-- > Hide all Pieces of a Unit
function hideAllReg()
    pieceMap = Spring.GetUnitPieceMap(unitID)
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

function restartHologram()
    Signal(SIG_CORE)
    SetSignalMask(SIG_CORE)
    resetAll(unitID)
    hideAllReg(unitID)
    deployHologram()
    StartThread(checkForBlackOut)
    StartThread(clock)
    StartThread(grid)

    if randChance(25) then
        StartThread(showStreetSigns)
    end

    if randChance(25)  then
       Sleep(500)
       showHoloWall()
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
                HideReg(theGrid)
                ShowReg(theGrid[i])
                Turn(theGrid[i], y_axis, math.rad(i * 90),0)
                Sleep(33)
                if maRa()then
                    Sleep(66)
                end
            end
            for i= upVal, lowVal, -1 do 
                HideReg(theGrid)
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

function showSubSpins(pieceID)
   local pieceName = getUnitPieceName(unitID, pieceID)
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
            showSubSpins(logoPiece)
            ShowReg(logoPiece)
            Spin(logoPiece, y_axis, math.rad(1.2)*randSign(), 0)
            if maRa() then
                legoPiece = deterministicElement(getSafeRandom(TableOfPiecesGroups["HoloLogo"]), TableOfPiecesGroups["HoloLogo"])
                showSubSpins(legoPiece)
                ShowReg(legoPiece)
                Spin(legoPiece, y_axis, math.rad(1.2)*randSign(), 0)
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

function checkForBlackOut()
    while true do
        if  GG.BlackOutDeactivationTime and  GG.BlackOutDeactivationTime[unitID] then
            if GG.BlackOutDeactivationTime[unitID] > (spGetGameFrame() - 5*30) then
                Signal(SIG_HOLO)
                Sleep(500)
                hideAllReg(unitID)
                restTime = 5*60*1000
                Sleep(restTime)
                deployHologram()
                GG.BlackOutDeactivationTime[unitID] = nil
            end
        end
    Sleep(1000)
    end
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
                                    Hide(tile)
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
                Hide(tileFallingOff)
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
