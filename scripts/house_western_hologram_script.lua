include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
local buisnessNeonSigns =  include('buissnesNamesNeonLogos.lua')
local casinoNamesNeonSigns = include('casinoNamesNeonLogos.lua')
local brothelNamesNeonSigns = include('brothelNamesNeonLogos.lua')
local creditNeonSigns = include('creditNamesNeonLogos.lua')
buisness_spin = piece("buisness_spin")
brothel_spin = piece("brothel_spin")
casino_spin = piece("casino_spin")
local TablesOfPiecesGroups = {}
boolDebugHologram = true

myDefID = Spring.GetUnitDefID(unitID)
boolIsCasino= UnitDefNames["house_western_hologram_casino"].id == myDefID
boolIsBrothel= UnitDefNames["house_western_hologram_brothel"].id == myDefID
boolIsBuisness= UnitDefNames["house_western_hologram_buisness"].id == myDefID 
sizeDownLetter = 225
sizeSpacingLetter = 175
local _x_axis = 1
local _y_axis = 2
local _z_axis = 3

rotatorTable ={}

GameConfig = getGameConfig()

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(HoloGrams)
end

function nilNeonSigns()
   brothelNamesNeonSigns = nil
    casinoNamesNeonSigns = nil
    buisnessNeonSigns = nil
    creditNeonSigns= nil
end

function holoGramNightTimes(boolDayLightSavings, name, axisToRotateAround)
    interval = math.random(1,3)*60*1000
    while true do
        hours, minutes, seconds, percent = getDayTime()
        if ( boolDayLightSavings == true and (hours > 17 or hours < 7)) then
            showTellTable = {}
            for i=1, #TablesOfPiecesGroups[name] do
                Sleep(500)
                hologramPiece= TablesOfPiecesGroups[name][i] 
                if maRa()then 
                    showTellTable[hologramPiece] = hologramPiece
                    val= math.random(10,42)*randSign()
                    Spin(hologramPiece,  axisToRotateAround, math.rad(val),0)
                else
                    Hide(hologramPiece)
                end
            end

            showT(showTellTable)
            Sleep(30000)
            resetT(TablesOfPiecesGroups[name], 1.2)
            WaitForTurns(TablesOfPiecesGroups[name])                     
        else
            hideT(TablesOfPiecesGroups[name])
            Sleep(interval)
        end
      
    end
end

function showWallDayTime(name)

    while true do
        hours, minutes, seconds, percent = getDayTime()
        if (hours > 18 or hours < 7) then     
            for i=1, #TablesOfPiecesGroups[name] do
                if maRa() then
                    Show(TablesOfPiecesGroups[name][i])
                end
            end 
            while (hours > 18 or hours < 7) do
                hours, minutes, seconds, percent = getDayTime()
                Sleep(5000)
            end
            hideT(TablesOfPiecesGroups[name])
        end
    val = math.random(25, 45)*1000
    Sleep(val)
    end
end

function HoloGrams()
    rotatorTable[#rotatorTable+1] = piece("brothel_spin")
    rotatorTable[#rotatorTable+1] = piece("casino_spin")
    rotatorTable[#rotatorTable+1] = piece("buisness_spin")
    rotatorTable[#rotatorTable+1] = piece("general_spin")
    
    val = math.random(10,42)/10*randSign()
    Spin(rotatorTable[1], y_axis, math.rad(val), 0)
    val = math.random(10,42)/10*randSign()
    Spin(rotatorTable[2], y_axis, math.rad(val), 0)
    val = math.random(10,42)/10*randSign()
    Spin(rotatorTable[4], y_axis, math.rad(val), 0)
    Sleep(15000)
    
    local flickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    hideT(flickerGroup)
    hideT(CasinoflickerGroup)
    StartThread(holoGramNightTimes, true, "GeneralDeco", _y_axis)

    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if getDeterministicCityOfSin(getCultureName(), Game)== true and isNearCityCenter(px,pz, GameConfig) == true or mapOverideSinCity() then
        if boolIsBrothel then
            if maRa() then
              StartThread(showWallDayTime, "BrothelWall")
            end
            StartThread(localflickerScript, flickerGroup, function() return maRa()==maRa(); end, 5, 250, 4, true, 2, 5)
            if maRa()  then
              StartThread(holoGramNightTimes, true, "Japanese", _y_axis)
            end
            addHologramLetters(brothelNamesNeonSigns[math.random(1,#brothelNamesNeonSigns)])
            nilNeonSigns()
            return 
        end
  
        if boolIsCasino then 
           StartThread(localflickerScript, CasinoflickerGroup, function() return maRa()==maRa(); end, 5, 250, 4, true, 3, math.sqrt(#CasinoflickerGroup))
            if maRa() then
                addHologramLetters(casinoNamesNeonSigns[math.random(1,#casinoNamesNeonSigns)])         
                nilNeonSigns()
                return 
            end
        end
    end

    if boolIsBuisness then 
        if maRa() then
            StartThread(showWallDayTime, "BuisnessWall")
        end
        logo = nil
        boolDone = false
        if not GG.HoloLogoRegister  then GG.HoloLogoRegister = {}  end   

        lowestIndex= nil
        lowestCounter = math.huge
        start = math.random(1,#TablesOfPiecesGroups["buisness_holo"])
        for i=start, #TablesOfPiecesGroups["buisness_holo"] do
            element = TablesOfPiecesGroups["buisness_holo"][i]
            if not GG.HoloLogoRegister[element] then
                GG.HoloLogoRegister[element] = 1
                logo = element
                boolDone = true
                break
            elseif GG.HoloLogoRegister[element] < lowestCounter then
                lowestIndex = element
                lowestCounter = GG.HoloLogoRegister[element]
            end
        end

        if not boolDone then
            for i=1, start do
                element = TablesOfPiecesGroups["buisness_holo"][i]
                if not GG.HoloLogoRegister[element] then
                    GG.HoloLogoRegister[element] = 1
                    logo = element
                    boolDone = true
                    break
                elseif GG.HoloLogoRegister[element] < lowestCounter then
                    lowestIndex = element
                    lowestCounter = GG.HoloLogoRegister[element]
                end
            end
        end

        if not boolDone then
            echo("Found no index for logo, selecting lowest")
            logo = lowestIndex
            GG.HoloLogoRegister[logo] = GG.HoloLogoRegister[logo] +1      
        end
        
        if not GG.RestaurantCounter then GG.RestaurantCounter = 0 end
        if GG.RestaurantCounter < 4 and (maRa()== maRa()) then    
            logo = piece("buisness_holo18")
        end

        if logo == piece("buisness_holo18") then            
            GG.RestaurantCounter = GG.RestaurantCounter + 1
        end

        spinLogos = {
                        [piece("buisness_holo18")] = "buisness_holo18",
                        [piece("buisness_holo19")] = "buisness_holo19",
                        [piece("buisness_holo22")] = "buisness_holo22"
                    }

        Spin(logo,y_axis, math.rad(5),0)
        Show(logo)
        if maRa() then
           if (spinLogos[logo]) then
                logoTableName = spinLogos[logo].."Spin"
                for i=1, #TablesOfPiecesGroups[logoTableName] do
                    if maRa() then
                        spinLogoPiece = TablesOfPiecesGroups[logoTableName][i]
                        Show(spinLogoPiece)
                        Spin(spinLogoPiece,y_axis, math.rad(-42),0)
                    end
                end
                addHologramLetters(buisnessNeonSigns[math.random(1,#buisnessNeonSigns)])
           end
        else
            if maRa() == maRa() then
                addHologramLetters(creditNeonSigns[math.random(1,#creditNeonSigns)])
            else
                addHologramLetters(buisnessNeonSigns[math.random(1,#buisnessNeonSigns)])
            end
        end
        nilNeonSigns()
        return 
    end 
end

function localflickerScript(flickerGroup,  NoErrorFunction, errorDrift, timeoutMs, maxInterval, boolDayLightSavings, minImum, minMaximum)
    assert(flickerGroup)
    local fGroup = flickerGroup
    if not minImum then minImum = 2 end 
    if not minMaximum then minMaximum = #flickerGroup end

    flickerIntervall = math.ceil(1000/25)
    boolNewDay = true
    toShowTableT= {}
    while true do
        hideT(fGroup)
        assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        hours, minutes, seconds, percent = getDayTime()
        if boolDayLightSavings == nil or ( boolDayLightSavings == true and (hours > 17 or hours < 7)) then
                if boolNewDay == true then
                    toShowTableT= {}
                    for x=1,math.random(minImum,minMaximum) do
                        toShowTableT[#toShowTableT+1] = fGroup[math.random(1,#fGroup)]
                    end
                    boolNewDay = false
                end

                for i=1,(3000/flickerIntervall) do
                    if i % 2 == 0 then      
                       showT(toShowTableT) 
                    else
                        hideT(toShowTableT) 
                    end
                    if NoErrorFunction() == true then showT(toShowTableT) end
                    for ax=1,3 do
                        moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
                    end
                    Sleep(flickerIntervall)
                end
                hideT(toShowTableT)
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
            Show(v)          
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
            Show(val)
        end
        return
    end
end
--myMessage = neonSigns[math.random(1,#neonSigns)]
function addHologramLetters( myMessage)
    axis= 2
    boolUpRight = maRa()
    boolSpinning = maRa()
    downIndex = 1
    --echo("Adding Grafiti with message:" ..myMessage)
    counter={}
    stringlength = string.len(myMessage)
    rowIndex= 0
    columnIndex= 0

    val = math.random(5,45)
    text_spin = piece("text_spin")
    if boolSpinning then
        Spin(text_spin, y_axis, math.rad(val),0)
    end
    for i=1, stringlength do
        columnIndex = columnIndex +1
        local letter = string.upper(string.sub(myMessage,i,i))
        if letter ~= " " and TablesOfPiecesGroups[letter] then
            if not counter[letter] then 
                counter[letter] = 0 
            end            
            counter[letter] = counter[letter] + 1 

            if counter[letter] < 4 then                 
                if TablesOfPiecesGroups[letter] and counter[letter] and TablesOfPiecesGroups[letter][counter[letter]] then
                    pieceName = TablesOfPiecesGroups[letter][counter[letter]] 
                    if pieceName then                     
                        Show(pieceName)
                        Move(pieceName, 3, -1*sizeDownLetter*rowIndex, 0)
                        Move(pieceName,axis, -sizeSpacingLetter*(columnIndex), 0)
                        if boolUpRight then
                            columnIndex= 0
                            rowIndex= rowIndex +1
                        end
                        
                        if boolSpinning and boolUpright then
                            val = i *5
                            Turn(pieceName, 2, math.rad(val), 0)
                        end
                    end
                end
            end
        else
            rowIndex= rowIndex +1
            columnIndex= 0
        end
    end
end