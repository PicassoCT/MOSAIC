include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"


myDefID = Spring.GetUnitDefID(unitID)
local boolIsCasino    = UnitDefNames["house_western_hologram_casino"].id == myDefID
local boolIsBrothel   = UnitDefNames["house_western_hologram_brothel"].id == myDefID
local boolIsBuisness  = UnitDefNames["house_western_hologram_buisness"].id == myDefID 

local creditNeonSigns =  include('creditNamesNeonLogos.lua')
local casinoNamesNeonSigns = include('casinoNamesNeonLogos.lua')
local brothelNamesNeonSigns = include('brothelNamesNeonLogos.lua')
local buisnessNeonSigns =  include('buissnesNamesNeonLogos.lua')
local sloganNamesNeonSigns = include('SlogansNewsNeonLogos.lua')
local brothelsloganNamesNeonSigns = include('SloganBrothelNeonLogos.lua')

local hours  =0
local minutes=0
local seconds=0
local percent=0
hours, minutes, seconds, percent = getDayTime()

local buisness_spin = piece("buisness_spin")
local wallSpin = piece("wallSpin")
local RainCenter = piece("RainCenter")
local general_spin = piece("general_spin")
local text_spin = piece("text_spin")
local brothel_spin = piece("brothel_spin")
local casino_spin = piece("casino_spin")
local JLantern = piece("JLantern")
local idleAnimations = {}
local technoAnimations = {}

local tldrum = piece "tldrum"
local dancepivot = piece "dancepivot"
local deathpivot = piece "deathpivot"
local tigLil = piece "tigLil"
local tlHead = piece "tlHead"
local tlhairup = piece "tlhairup"
local tlhairdown = piece "tlhairdown"
local tlarm = piece "tlarm"
local tlarmr = piece "tlarmr"
local tllegUp = piece "tllegUp"
local tllegLow = piece "tllegLow"
local tllegLowR = piece "tllegLowR"
local tllegUpR = piece "tllegUpR"
local tlpole = piece "tlpole"
local tlflute = piece "tlflute"
local spGetGameFrame = Spring.GetGameFrame
local qrcode = piece"buisness_holo056"

DirectionArcPoint = piece "DirectionArcPoint"
BallArcPoint = piece "BallArcPoint"
handr = piece "handr"
handl = piece "handl"
ball = piece "ball"
tigLilHoloPices = {
    tldrum ,
    dancepivot, 
    deathpivot ,
    tigLil ,
    tlHead ,
    tlhairup, 
    tlhairdown ,
    tlarm,
    tlarmr, 
    tllegUp,
    tllegLow, 
    tllegLowR, 
    tllegUpR ,
    tlpole ,
    tlflute,
    handr,
    handl,
    ball
}

spins ={buisness_spin,wallSpin,general_spin, text_spin, brothel_spin, casino_spin}
local TableOfPiecesGroups = {}
local boolDebugHologram = true

sizeDownLetter  = 350
sizeSpacingLetter = 300
local _x_axis = 1
local _y_axis = 2
local _z_axis = 3

rotatorTable ={}
local SIG_HOLO = 1
local SIG_CORE = 2
local SIG_HAIR = 4
local SIG_INCIRCLE = 8
local SIG_TALKHEAD = 16
local SIG_GESTE = 32
local SIG_ONTHEMOVE = 64
local SIG_TIGLIL = 128
local GameConfig = getGameConfig()
local pieceID_NameMap = Spring.GetUnitPieceList(unitID)
local cachedCopy ={}
local lastFrame = Spring.GetGameFrame()

local function updateCheckCache()
  local frame = Spring.GetGameFrame()
  if frame ~= lastFrame then 
    if not GG.VisibleUnitPieces then GG.VisibleUnitPieces = {} end
        cachedTable = {}
        for k,v in pairs(cachedCopy) do
            if v then 
                table.insert(cachedTable, v)
            end
        end
    GG.VisibleUnitPieces[unitID] = cachedTable
    lastFrame = frame
  end
end

local function ShowReg(pieceID)
    Show(pieceID)
    cachedCopy[pieceID] = pieceID
    updateCheckCache()
end

local function HideReg(pieceID)
    Hide(pieceID)  
    --TODO make dictionary for efficiency
    cachedCopy[pieceID] = nil
    updateCheckCache()
end

-- > Hide all Pieces of a Unit
local function hideAllReg()
    pieceMap = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(pieceMap) do HideReg(v) end
end

-- > Hides a PiecesTable, 
local function hideTReg(l_tableName, l_lowLimit, l_upLimit, l_delay)
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
local function showTReg(l_tableName, l_lowLimit, l_upLimit, l_delay)
    assert(l_tableName)
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

local function tiglLilLoop()
    if unitID % 5 ~= 0 then return end
    if not GG.TiglilHoloTable then GG.TiglilHoloTable = {} end
    if count(GG.TiglilHoloTable) > 3 and not GG.TiglilHoloTable[unitID]  then  return end

    GG.TiglilHoloTable[unitID] = unitID

    while true do
        if (hours > 20 or hours < 6) then
            if boolIsBuisness or boolIsCasino then
                StartThread(dancingTiglil, technoAnimations, true)
            else
                StartThread(dancingTiglil, idleAnimations)
            end
            while  (hours > 20 or hours < 6) do
                Sleep(30000)
            end
            Signal(SIG_TIGLIL)
            Hide(tlpole)
            Hide(tldrum)
            Hide(tlflute)
            hideTReg(TableOfPiecesGroups["GlowStick"])
            hideTReg(tigLilHoloPices)
        end
        Sleep(9000)
    end
end

function dancingTiglil(animations, boolTechno)
    SetSignalMask(SIG_TIGLIL)
    if boolTechno then
        showOne(TableOfPiecesGroups["GlowStick"])
        showOne(TableOfPiecesGroups["GlowStick"])
    end

    while (hours > 20 or hours < 6) do
        TigLilSetup()
        Signal(SIG_GESTE)
        Signal(SIG_TALKHEAD)
        rest = math.random(512, 4096)
        Sleep(rest)
        animations[math.random(1,#animations)]()
    end
end

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = spGetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

--Direction = piece("Direction")

function showSubSpins(pieceID)
   pieceName = getUnitPieceName(unitID, pieceID)
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

function hideSubSpins(pieceID)
    pieceName = getUnitPieceName(unitID, pieceID)
    subSpinPieceName = pieceName.."Spin"    
    if TableOfPiecesGroups[subSpinPieceName] then  
        hideTReg(TableOfPiecesGroups[subSpinPieceName]) 
    end
end
    
rPlayerName = getRandomPlayerName()
function getDramatisPersona()

    if maRa() and rPlayerName then
        return rPlayerName
    else
        return GG.LastAssignedName or "ANON"
    end
end

boolJustOnce= true
function restartHologram()
    Sleep(500)

    if boolIsEverChanging and boolJustOnce then
        location_region, location_country, location_province, location_cityname, location_citypart = getLocation()

        if boolIsBrothel then 
            for i=1, #brothelsloganNamesNeonSigns do
                brothelsloganNamesNeonSigns[i] = brothelsloganNamesNeonSigns[i]:gsub( "<suspect>", getDramatisPersona())
            end
             brothelNamesNeonSigns = mergeTables(brothelNamesNeonSigns, brothelsloganNamesNeonSigns)
             assert(brothelNamesNeonSigns)
        end
  
        for i=1, #sloganNamesNeonSigns do
            sloganNamesNeonSigns[i] = sloganNamesNeonSigns[i]:gsub( "<suspect>", getDramatisPersona())
            if maRa() then
                sloganNamesNeonSigns[i] = sloganNamesNeonSigns[i]:gsub( "<cityname>", location_cityname)
            else
                sloganNamesNeonSigns[i] = sloganNamesNeonSigns[i]:gsub( "<cityname>", location_citypart)
            end
        end
        buisnessNeonSigns =  sloganNamesNeonSigns
        assert(buisnessNeonSigns)
        boolJustOnce = false
    end
    Signal(SIG_CORE)
    SetSignalMask(SIG_CORE)
    resetAll(unitID)
    hideAllReg(unitID)
    StartThread(clock)
    deployHologram()    
    hideTReg(spins)
    StartThread(checkForBlackOut)    
    StartThread(tiglLilLoop)
end

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TableOfPiecesGroups = getPieceTableByNameGroups(false, true)

    restartHologram()
    StartThread(grid)
    StartThread(emergencyWatcher)
end

EmergencyIcon = piece("EmergencyIcon")
function ShowEmergencyElements () 
  EmergencyText = piece("EmergencyText")
  if maRa() then ShowReg(EmergencyIcon) end
  ShowReg(EmergencyText)
  id = showOne(TableOfPiecesGroups["EmergencyPillar"]) 
  element=showOne(TableOfPiecesGroups["EmergencyMessage" ]) 
  Spin(element , y_axis, math.rad(randSign() * 42), 0)
end

function emergencyWatcher()
    while true do
        if GG.GlobalGameState ~= GameConfig.GameState.normal then
            Signal(SIG_CORE)
            hideAllReg(unitID)
            ShowEmergencyElements()
            --echo("emergency mode active") 
            while GG.GlobalGameState ~= GameConfig.GameState.normal do
                Sleep(1000)
            end
            hideAllReg(unitID)
            restartHologram()
        end
        Sleep(3000)
    end
end


function clock()
    while true do
        hours, minutes, seconds, percent = getDayTime()
        Sleep(1000)
    end
end

allGrids = nil

function getGrid()
    if not allGrids then    
        allGrids = {}
        allGrids[#allGrids+1] = TableOfPiecesGroups["BrothelGrid"][1]
        allGrids[#allGrids+1] = TableOfPiecesGroups["BuisnessGrid"][1]
        allGrids[#allGrids+1] = TableOfPiecesGroups["CasinoGrid"][1]
    
        allGrids[#allGrids+1] = TableOfPiecesGroups["BrothelGrid"][2]
        allGrids[#allGrids+1] = TableOfPiecesGroups["BuisnessGrid"][2]
        allGrids[#allGrids+1] = TableOfPiecesGroups["CasinoGrid"][2]
        for i=1, #allGrids do
            --assert(allGrids[i])
        end
    end

    if boolIsBrothel then
        return TableOfPiecesGroups["BrothelGrid"][math.random(1,2)]
    end

    if (maRa()== maRa())== maRa()then
        return getSafeRandom(allGrids, allGrids[1])
    end
    if boolIsBuisness then
        return TableOfPiecesGroups["BuisnessGrid"][math.random(1,2)]
    end

    if boolIsCasino then
        return TableOfPiecesGroups["CasinoGrid"][math.random(1,2)]
    end    
end


function grid()
    Sleep(100)
    while true do
        if (hours > 19 or hours < 6) then
            theGrid = getGrid()
            upVal=math.random(3,4)
            lowVal= math.random(0,2)
            ShowReg(theGrid)
            Sleep(33)
            for i= lowVal, upVal do 
                Turn(theGrid, y_axis, math.rad(i*90),0)
                Sleep(33)
                if maRa()then
                    Sleep(66)
                end
            end
            for i= upVal, lowVal, -1 do 
                Turn(theGrid, y_axis, math.rad(i*90),0)
                Sleep(33)
                if maRa()then
                    Sleep(66)
                end
            end
            if maRa() == maRa() then
                Sleep(500)
            end

            HideReg(theGrid)
        end
        Sleep(33)
    end
end

function deployHologram()
    StartThread(HoloGrams)
    StartThread(holoGramRain)
end

function checkForBlackOut()
    while true do
        if  GG.BlackOutDeactivationTime and  GG.BlackOutDeactivationTime[unitID] then
            if GG.BlackOutDeactivationTime[unitID] > (spGetGameFrame() - 5*30) then
                Signal(SIG_HOLO)
                Sleep(500)
                hideAll(unitID)
                restTime = 5*60*1000
                Sleep(restTime)
                deployHologram()
                GG.BlackOutDeactivationTime[unitID] = nil
            end
        end
    Sleep(1000)
    end
end

boolIsEverChanging= math.random(1,10) < 3 

function RainDrop(pieceID, delayMS, speed)
	if not pieceID then return end
    maxDistance = 4000
    downAxis = 2
    Sleep(delayMS)
    x,z = math.random(30,maxDistance)*randSign(), math.random(30,maxDistance)*randSign()
    y = math.sqrt((maxDistance-x)^2 + (maxDistance-z)^2)
    Move(pieceID, 1, x, 0)
    Move(pieceID, 3, z, 0)
    Move(pieceID, downAxis, y, 0)
    ShowReg(pieceID)
    --Spin(pieceID, downAxis, math.rad(42),0)
    WMove(pieceID, downAxis, 0, speed)
    HideReg(pieceID)
end

function holoRain(Name, speed)
    groupName = Name.."Rain"
    for i=1,#TableOfPiecesGroups[groupName] do
        delay= math.random(1,10)*50
		StartThread(RainDrop,TableOfPiecesGroups[groupName][i], delay, speed)
    end
end

RainCenter = piece("RainCenter")
function holoGramRain()
    Sleep(100)
    speed = math.pi * 2000
    if unitID % 3 == 0 then
        StartThread(glowWormFlight, 5.0)
    end
    while true do
        if (hours > 19 or hours < 6) and isANormalDay() then
            rainDirectioinCopy = GG.RainDirection
            if isRaining(hours) and rainDirectioinCopy then
                Turn(RainCenter,x_axis,math.rad(rainDirectioinCopy.x),0)
                Turn(RainCenter,z_axis,math.rad(rainDirectioinCopy.z),0)
                while(hours > 19 or hours < 6) do
                    if boolIsBrothel then
                        holoRain("Brothel", speed)
                    end
                    if boolIsBuisness then
                        holoRain("Buisness", speed)
                    end
                    if maRa() == maRa() then
                        holoRain("Neutral", speed)
                    end
                    Sleep(1000)
                end
                hideT(TableOfPiecesGroups["BuisnessRain"])
                hideT(TableOfPiecesGroups["NeutralRain"])
                hideT(TableOfPiecesGroups["BrothelRain"])
            end           
        end
        Sleep(1000)
    end
end

function holoGramNightTimes( name, axisToRotateAround, max)
    if max == nil then
        max = 5
    end
    interval = math.random(1,3)*60*1000
    alreadyShowing = {}
    while true do
        if ( (hours > 17 or hours < 7) or boolDebugHologram) and isANormalDay() then
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/advertising/hologramnoise.ogg", 0.25, 25000, 1)
            showTellDict= {}
            hcounter = math.random(3, 6)
            assert(#TableOfPiecesGroups[name] > 0, name)
            for i=1, #TableOfPiecesGroups[name] do
                Sleep(500)
                _, hologramPiece= randDict(TableOfPiecesGroups[name])
                if not alreadyShowing[hologramPiece] and hcounter > 0 then 
                    alreadyShowing[hologramPiece] = true
                    hcounter = hcounter - 1
                    showTellDict[hologramPiece] = hologramPiece
                    val= math.random(10,42) * randSign()
                    if axisToRotateAround then
                        Spin(hologramPiece, axisToRotateAround, math.rad(val), 0)
                    end
                else
                    HideReg(hologramPiece)
                end
            end

            showTReg(showTellDict)
            Sleep(90000)
            resetT(TableOfPiecesGroups[name], 1.2)
            WaitForTurns(TableOfPiecesGroups[name])   
            hideTReg(showTellDict)                    
        else
            hideTReg(TableOfPiecesGroups[name])
            Sleep(interval)
        end
       Sleep(10)
    end
end

function fadeIn(piecesTable, rest)
    hideTReg(piecesTable)
    for i = 1, #piecesTable do
        Sleep(rest)
        ShowReg(piecesTable[i])
    end
end

function fadeOut(piecesTable, rest)
    --dissappearing
    for i =  #piecesTable, 1, -1 do
        Sleep(rest)
        HideReg(piecesTable[i])
    end
    hideTReg(piecesTable)
end

function disAppearGlowWorm(piecesTable, fadeInTimeMs, lifeTimeMs, fadeOutTimeMs)
    -- appear
    fadeIn(piecesTable, fadeInTimeMs/#piecesTable)

    --lifeTime
    if maRa() then
        Sleep(lifeTimeMs)
    else-- flicker
        fadeOut(piecesTable, lifeTimeMs/(#piecesTable/2))
        fadeIn(piecesTable, lifeTimeMs/(#piecesTable/2))
    end

    fadeOut(piecesTable, fadeOutTimeMs/(#piecesTable))
end


function disAppearGlowWormSwarm( fadeInTimeMs, lifeTimeMs, fadeOutTimeMs)
    for i=1, #TableOfPiecesGroups["GlowSwarm"] do
        if maRa() then
            mx,my,mz = math.random(-5,5), math.random(-5,5) , math.random(-5,5)
            mP(TableOfPiecesGroups["GlowSwarm"][i], mx,my,mz, 0.5)
            StartThread(disAppearGlowWorm, {TableOfPiecesGroups["GlowSwarm"][i]}, math.random(0,fadeInTimeMs), math.random(0, lifeTimeMs), math.random(0, fadeOutTimeMs))
        end
    end
end

function glowWormFlight(speed)
    speed = 5
    local glowWormCenter = piece("GlowMove")
    local heightDiff = 25
    local fadeInTimeMs = 1000
    local lifeTimeMs =  2500
    local fadeOutTimeMs = 1000
    local targetHeight = 0
    posX, posY,posZ = 0,0,0
    intervalLength = math.random(5, 10)
    for i=1, #TableOfPiecesGroups["GlowSwarm"] do
        --assert(TableOfPiecesGroups["GlowSwarm"][i])
    end

    hideTReg(TableOfPiecesGroups["GlowSwarm"])
    targetHeight = math.random(0,heightDiff)
    posX = math.random(0, 500)*randSign() 
    intervalLength = math.random(5, 10)
    subPart = intervalLength/4
    fadeInTimeMs = math.ceil(subPart*750*math.random(1,2))
    lifeTimeMs =  math.ceil(subPart*2*1000)
    fadeOutTimeMs = math.ceil(subPart*750*math.random(1,2))
    for i=1, #TableOfPiecesGroups["GlowSwarm"] do 
        spinRand( TableOfPiecesGroups["GlowSwarm"][i], -42, 42, speed)
    end

    while true do
        if (hours > 19 or hours < 6) then
            timeInSeconds = (spGetGameFrame()/30) % 90

            if math.ceil(timeInSeconds) % 15 == 0 then
                hideTReg(TableOfPiecesGroups["GlowWorm"])
                hideTReg(TableOfPiecesGroups["GlowSwarm"])
                targetHeight = math.random(0,heightDiff)
                posX = math.random(0, 500)*randSign() 
                intervalLength = math.random(5, 10)
                subPart = intervalLength/4
                fadeInTimeMs = math.ceil(subPart*750*math.random(1,2))
                lifeTimeMs =  math.ceil(subPart*2*1000)
                fadeOutTimeMs = math.ceil(subPart*750*math.random(1,2))
                for i=1, #TableOfPiecesGroups["GlowSwarm"] do 
                    spinRand( TableOfPiecesGroups["GlowSwarm"][i], -42, 42, math.random(0, speed))
                end
            end

            posY = math.abs(math.sin(timeInSeconds*math.pi))*targetHeight
            posZ = math.cos(timeInSeconds*math.pi)
            mP(glowWormCenter, posX, posY, posZ, 50)

            if timeInSeconds % intervalLength < 1.0 then
                if maRa() then
                    StartThread(disAppearGlowWorm, TableOfPiecesGroups["GlowWorm"],fadeInTimeMs, lifeTimeMs, fadeOutTimeMs)
                else
                    StartThread(disAppearGlowWormSwarm,fadeInTimeMs, lifeTimeMs, fadeOutTimeMs)
                end
            end
        end
        Sleep(1000)
    end
end

function showWallDayTime(name)
    wallGrid = TableOfPiecesGroups["WallGrid"][math.random(1,#TableOfPiecesGroups["WallGrid"])]
    while true do
        randOffset =  randSign() 
        if (hours > 18 +randOffset or hours < 7 or boolDebugHologram) and isANormalDay() then 
            if maRa() then
                ShowReg(wallGrid)
            end
            encounter = math.random(4,7)    
            while encounter > 0 do
                _, element = randDict(TableOfPiecesGroups[name])
                if element then
                    encounter = encounter - 1
                    ShowReg(element)
                    showSubSpins(element)
                end
                Sleep(10)   
            end         
        
            while (hours > 18 +randOffset or hours < 7) do
                wallRest= math.ceil(math.random(100,1000))
                Sleep(wallRest)
                val = math.random(0,3)* 90
                offsetVal= val + math.random(-10,10)/10
                Turn(wallGrid,x_axis, math.rad(offsetVal) , 0)
                WTurn(wallGrid,x_axis, math.rad(val) , 0.25)
                if maRa() == maRa() then
                    Move(wallGrid,y_axis, math.random(5, 50),10)
                else
                    mVal = (math.sin((hours/24)*math.pi*2)+1)*25
                    Move(wallGrid,y_axis, mVal,25)
                end
            end

            for i=1, #TableOfPiecesGroups[name] do
                HideReg(TableOfPiecesGroups[name][i])
                hideSubSpins(TableOfPiecesGroups[name][i])
                rest= ((i % 3)+1)*1000
                Sleep(rest)
            end
            HideReg(wallGrid)
        end
        val = math.random(25, 45)*1000
        Sleep(val)
    end
end

symmetryPiece = piece("buisness_holo064")

function localflickerScript(flickerGroup,  NoErrorFunction, errorDrift, timeoutMs, maxInterval,  minImum, minMaximum)
    --assert(flickerGroup)
    local fGroup = flickerGroup

    if not minImum then minImum = 1 end 
    if not minMaximum then minMaximum = #flickerGroup end

    flickerIntervall = 60--math.ceil(1000/25)
    boolNewDay = true
    toShowTableT= {}
    while true do
        hideTReg(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup"..getUnitPieceName(unitID, fGroup[1]))
        Sleep(500)
        if (hours > 17 or hours < 7) and isANormalDay() then
                if boolNewDay == true then
                    toShowTableT= {}
                    for x=1, math.random(minImum, minMaximum) do
                        toShowTableT[#toShowTableT+1] = fGroup[math.random(1, #fGroup)]
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
        breakTime = math.random(1, maxInterval) * timeoutMs
        Sleep(breakTime)
    end
end

function HoloGrams()
    SetSignalMask(SIG_HOLO)
    assert(brothelNamesNeonSigns)
    assert(buisnessNeonSigns)
    assert(buisnessNeonSigns)
    rotatorTable[#rotatorTable+1] = piece("brothel_spin")
    rotatorTable[#rotatorTable+1] = piece("casino_spin")
    rotatorTable[#rotatorTable+1] = piece("buisness_spin")
    rotatorTable[#rotatorTable+1] = piece("general_spin")
    
    val = math.random(10,42)/10*randSign()
    Spin(rotatorTable[1], y_axis, math.rad(val), 0)
    val = math.random(10,42)/10*randSign()
    Spin(rotatorTable[2], y_axis, math.rad(val), 0)
    val = math.random(10,42)/10*randSign()
    Spin(rotatorTable[4], 2, math.rad(val), 0)
    Sleep(15000)

    
    local flickerGroup = TableOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TableOfPiecesGroups["CasinoFlicker"]
    hideTReg(flickerGroup)
    hideTReg(CasinoflickerGroup)
    
    StartThread(holoGramNightTimes, "GeneralDeco", nil, 3)
    
    --sexxxy time
    if boolIsBrothel then   
        if maRa() then
          StartThread(showWallDayTime, "BrothelWall")
        end
        StartThread(localflickerScript, flickerGroup, function() return maRa()==maRa(); end, 5, 250, 4,  2, math.random(5,7))
        if maRa()  then
          StartThread(holoGramNightTimes, "Japanese", _y_axis)
          StartThread(addJHologramLetters)
        end
        addHologramLetters(brothelNamesNeonSigns)

        return 
    end
  
    if boolIsCasino then 
        StartThread(localflickerScript, CasinoflickerGroup, function() return maRa()==maRa(); end, 5, 250, 4,  3, math.random(4,7))
    
        if maRa() then
          StartThread(showWallDayTime, "CasinoWall")
          StartThread(addJHologramLetters)
          if maRa() then
            StartThread(fireWorks)
          end
        end           
        if maRa() then
            addHologramLetters(casinoNamesNeonSigns)         
            return 
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
        start = math.random(1,#TableOfPiecesGroups["buisness_holo"])
        for i=start, #TableOfPiecesGroups["buisness_holo"] do
            element = TableOfPiecesGroups["buisness_holo"][i]

            if not GG.HoloLogoRegister[element] then
                GG.HoloLogoRegister[element] = 1
                logo = element
                showSubSpins(element)
                boolDone = true
                break
            elseif GG.HoloLogoRegister[element] < lowestCounter then
                lowestIndex = element
                lowestCounter = GG.HoloLogoRegister[element]
            end
        end

        if not boolDone then
            for i=1, start do
                element = TableOfPiecesGroups["buisness_holo"][i]
                if not GG.HoloLogoRegister[element] then
                    GG.HoloLogoRegister[element] = 1
                    logo = element
                    showSubSpins(element)
                    boolDone = true
                    break
                elseif GG.HoloLogoRegister[element] < lowestCounter then
                    lowestIndex = element
                    lowestCounter = GG.HoloLogoRegister[element]
                end
            end
        end

        if not boolDone then
            --echo("Found no index for logo, selecting lowest")
            logo = lowestIndex
            GG.HoloLogoRegister[logo] = GG.HoloLogoRegister[logo] +1      
        end
        
        if not GG.RestaurantCounter then GG.RestaurantCounter = 0 end
        if GG.RestaurantCounter < 4 and (maRa()== maRa()) then    
            logo = piece("buisness_holo18")
        end

        if logo == piece("buisness_holo18") then            
            GG.RestaurantCounter = GG.RestaurantCounter + 1
            symbol = math.random(8,11)
            ShowReg(TableOfPiecesGroups["buisness_holo18Spin"][symbol])
            StartThread(holoGramNightTimes, "GeneralDeco", nil, 5)
            StartThread(addJHologramLetters)
        end

        if logo == symmetryPiece then
            shapeSymmetry(symmetryPiece)
            return            
        end

        if logo == qrcode then 
            for i=1, #TableOfPiecesGroups["buisness_holo56Spin"] do
                if TableOfPiecesGroups["buisness_holo56Spin"][i] and maRa() then
                    ShowReg(TableOfPiecesGroups["buisness_holo56Spin"][i])
                end
            end

        end

        Spin(logo,y_axis, math.rad(5),0)     
           
        ShowReg(logo)
        if maRa() then
           pieceName = getUnitPieceName(unitID, logo)
           logoTableName = pieceName.."Spin"
           if TableOfPiecesGroups[logoTableName] then   
                for i=1, #TableOfPiecesGroups[logoTableName] do
                    _, element = randDict(TableOfPiecesGroups[logoTableName])             
                    if maRa() then
                        spinLogoPiece = element
                        ShowReg(spinLogoPiece)
                        Spin(spinLogoPiece,y_axis, math.rad(-42),0)
                    end
                end
                addHologramLetters(buisnessNeonSigns)
           end
        else
            if maRa() == maRa() then
                addHologramLetters(creditNeonSigns)
                if maRa() then
                    StartThread(LightChain, TableOfPiecesGroups["Techno"], 4, 110)
                end
            else
                addHologramLetters(buisnessNeonSigns)
            end
        end
        return 
    end 
end

function dragonDance()
    local DragonTable = TableOfPiecesGroups["Dragon"]
    local DragonHead = DragonTable[1]
    dx,dz = math.random(-200,200),math.random(-200,200)

    while true do
        if (hours > 20 or hours < 6)  then
            showTReg(DragonTable)
            interval = 2 * math.pi
            step = interval / #DragonTable
            while (hours > 20 or hours < 6)  do
                --movement                   
                Move(DragonHead,1, dx, 50)
                Move(DragonHead,3, dz, 50)       
                --rotations
                times = percent*30
                for i=1, #DragonTable do
                    val = math.sin(times * step * i)
                    Turn(DragonTable[i], 3, val, 0.1)
                end
                Sleep(250)
            end
            hideTReg(DragonTable)
            dx,dz = math.random(-200,200),math.random(-200,200)
        end
        Sleep(1000)
    end
end

function fireWorksSet(fireSet, maxDistance, speed)
    distanceX = math.random(maxDistance*0.75 ,maxDistance)*randSign()
    distanceZ = math.random(maxDistance*0.75 ,maxDistance)*randSign()
    distanceY = math.random(maxDistance*0.75 ,maxDistance)*randSign()
    assert(fireSet)
    for num, id in pairs(fireSet) do

        mP(id, distanceX, distanceY, distanceZ, speed)
        turnPieceRandDir(id, 0)    
        spinRand(id,-10, 10, 0.25)
        ShowReg(id)
    end
end

function fireWorks()
    local FireWorksCenter = piece("FireWorksCenter")
    FireWorksTableB = TableOfPiecesGroups["BlueSpark"]
    FireWorksTableR = TableOfPiecesGroups["RedSpark"]
    FireWorksTableY = TableOfPiecesGroups["YellowSpark"]
    upaxis = 2

    if maRa() == maRa() then
        StartThread(dragonDance) 
    end

    while true do
        while (hours > 20 or hours < 6) do
            ShowReg(FireWorksCenter)
            reset(FireWorksCenter)
            resetT(FireWorksTableB)
            resetT(FireWorksTableR)
            resetT(FireWorksTableY)
            updistance = 3000

            spreaddistance = 750 
            fOffsetX=math.random(1000,2500)*randSign()
            fOffsetZ=math.random(1000,2500)*randSign()
            Move(FireWorksCenter, 1, fOffsetX,0)
            Move(FireWorksCenter, 3, fOffsetZ,0)
            WMove(FireWorksCenter, upaxis, updistance, 1000.5)
            --Show and Expand

             speed = math.random(25,35)
            if maRa() then
               fireWorksSet(FireWorksTableB, spreaddistance, spreaddistance)
            end     

            if maRa() then
                fireWorksSet(FireWorksTableR, spreaddistance, spreaddistance)
            end
            
            if maRa() then
                fireWorksSet(FireWorksTableY, spreaddistance, spreaddistance)
            end
            HideReg( FireWorksCenter)          
            WMove(FireWorksCenter, upaxis, updistance - 200, 250.5)
            WMove(FireWorksCenter, upaxis, updistance - 1000, 500.5)
            Move(FireWorksCenter, upaxis, updistance - 2000, 750)
            Sleep(800) 
            Move(FireWorksCenter, upaxis, 0, 1000)
            for i=1, #FireWorksTableB do
                HideReg(FireWorksTableB[i])
                HideReg(FireWorksTableR[i])
                HideReg(FireWorksTableY[i])
                Sleep(200)
            end     
            WMove(FireWorksCenter, upaxis, 0, 1000)
            timeBetweenShots= math.random(4,10)*1000
            Sleep(1000)     

        end
    Sleep(5000)
    end
end

function shapeSymmetry(logo)
    for i=1, 10 do
        if not (maRa() == maRa()) or i < 4 then
            pieceName = "Symmetry0"..i
            symPieceName = "Symmetry0"..(i + 10)
            a = piece(pieceName)
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
    if not maRa() then
     ShowReg(logo)
    end
    if maRa() == maRa() then
        addHologramLetters(creditNeonSigns)
    else
        addHologramLetters(buisnessNeonSigns)
    end
end

function showOne(T)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    assert(T)
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

function hideResetAllPieces()
    letters = {"A","B","C","D","E","F","G","H","I","J","K","M","N","L","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
    for i=1, #letters do
        local letter = letters[i]
        if TableOfPiecesGroups[letter] then
            resetT(TableOfPiecesGroups[letter])
            hideTReg(TableOfPiecesGroups[letter])
        end
    end
end

function setupMessage(myMessages)
    assert(myMessages)
    hideResetAllPieces()
    spinner =  piece("text_spin")
    axis= 2
    startValue = 0
    myMessage = myMessages[math.random(1,#myMessages)]
    if boolIsCasino  then startValue = 2 end
    if boolIsBrothel  then startValue = 3 end
    boolUpRight = maRa()
    if boolUpRight and boolIsBrothel then
        if maRa() == maRa() then
            StartThread(LightChain, TableOfPiecesGroups["LightChain"], 4, math.random(700,1200))
        end
    end

    boolSpinning = maRa()

    downIndex = 1
    lettercounter={}
    stringlength = string.len(myMessage)
    rowIndex= 0
    columnIndex= 0

    if boolSpinning then

        reset(spinner)
        val = math.random(5,45)
        Spin(spinner, y_axis, math.rad(val),0)
    end

    if boolUpRight then
        if stringlength > 10 then        
            Move(spinner, y_axis,(stringlength-10) * sizeDownLetter, 0) --Move the text spinner upward so letters dont vannish into the ground
        end
    end

    allLetters = {} 
    posLetters = {}   
    for i=1, stringlength do
        columnIndex = columnIndex +1
        local letter = string.upper(string.sub(myMessage,i,i))
        if letter ~= " " and TableOfPiecesGroups[letter] then
            if not lettercounter[letter] then 
                lettercounter[letter] = startValue 
            end            
            lettercounter[letter] = lettercounter[letter] + 1 
            if lettercounter[letter] > 4 then lettercounter[letter] = 1 end

            if TableOfPiecesGroups[letter] and lettercounter[letter] and TableOfPiecesGroups[letter][lettercounter[letter]] then
               
                pieceName = TableOfPiecesGroups[letter][lettercounter[letter]] 
                if pieceName then     
                    table.insert(allLetters, pieceName)                
                    ShowReg(pieceName)
                    Move(pieceName, 3, -1*sizeDownLetter*rowIndex, 0)
                    Move(pieceName,axis, -sizeSpacingLetter*(columnIndex), 0)
                    posLetters[pieceName]= {0,-sizeSpacingLetter*(columnIndex),  -1*sizeDownLetter*rowIndex }
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
        else
            rowIndex= rowIndex +1
            columnIndex= 0
        end
    end
    return allLetters, posLetters, myMessage
end

function restoreMessageOriginalPosition(message, posLetters)
    foreach(message,
        function(id)
            Move(id, 1, posLetters[id][1], 0)
            Move(id, 2, posLetters[id][2], 0)
            Move(id, 3, posLetters[id][3], 0)
            end
        )
end

--myMessage = neonSigns[math.random(1,#neonSigns)]
function addHologramLetters( myMessages)  

    allLetters, posLetters = setupMessage(myMessages)

    if maRa() and maRa() or boolIsEverChanging then 
		allFunctions = {SinusLetter, CrossLetters, HideLetters,SpinLetters, SwarmLetters, SpiralUpwards, randomFLickerLetters, syncToFrontLetters, consoleLetters, dnaHelix, circleProject}
        --TextAnimation

        while true do
            restoreMessageOriginalPosition(allLetters, posLetters)
		    allFunctions[math.random(1,#allFunctions)](allLetters, posLetters) 
            WaitForMoves(allLetters)       
            restTime = math.max(5000, #allLetters*150)
            Sleep(restTime)
            if boolIsEverChanging == true then
                allLetters, posLetters, newMessage = setupMessage(myMessages)                
            end
        end
    end 
end

backdropAxis = x_axis
spindropAxis = y_axis
function randomFLickerLetters(allLetters, posLetters)
    errorDrift = math.random(2,7)
    flickerIntervall = math.ceil(1000/25)
	if (hours > 17 or hours < 7) then
		for i=1,(3000/flickerIntervall) do
			if i % 2 == 0 then      
			   showTReg(allLetters) 
			else
				hideTReg(allLetters) 
			end

            foreach(allLetters,
            function(id)
              for axis=1,3 do
                Move(id, axis, posLetters[id][axis] + math.random(-1*errorDrift,errorDrift), 100)
               end
            end)
            Sleep(flickerIntervall)
		end
		hideTReg(allLetters)  
        foreach(allLetters,
            function(id)
              for axis=1,3 do
                Move(id, axis, posLetters[id][axis], 15)
               end
               ShowReg(id)
            end)
	end		
end

function syncToFrontLetters(allLetters)
    direction =  randSign()
	hideTReg(allLetters)
    --Setup
    for j=1, #allLetters do
		WMove(allLetters[j],backdropAxis, -500 + math.sin((j/#allLetters)*(math.pi/2))*50, 0)			
    end    
	showTReg(allLetters)
	for j=1, #allLetters do
		WMove(allLetters[j],backdropAxis, 150 + math.cos((j/#allLetters)*(math.pi/2))*50, 250)			
    end
	for j=1, #allLetters do
		WMove(allLetters[j],backdropAxis,0, 150)			
    end

	WaitForMoves(allLetters)
    rest = math.random(4, 16)*500
    Sleep(rest)
end

function consoleLetters(allLetters, posLetters)
  
    foreach(allLetters,
    function(id)
      reset(id,0)
      HideReg(id)
    end)

    foreach(allLetters,
    function(id)
      for axis=1,3 do
        Move(id, axis, posLetters[id][axis], 150)
       end
       ShowReg(id)
    end)
    Sleep(100)
    WaitForMoves(allLetters)
    Sleep(5000)
end

function resetSpinDrop(allLetters)

         foreach(allLetters,
        function(id)   
                StopSpin(id, spindropAxis, math.rad(15), 15)     
                Turn(id, spindropAxis, math.rad(0), 15)    
        end)
end

function dnaHelix(allLetters)
	index = 1
    foreach(allLetters,
        function(id)
			val = (index/ #allLetters) * 2 * 2 * math.pi
			Turn(id, spindropAxis, math.rad(val), 0)    
			Spin(id, spindropAxis, math.rad(42), 15)   
			ShowReg(id)			
			index = index +1
        end)
		Sleep(9000)
	
	foreach(allLetters,
        function(id)
			StopSpin(id, spindropAxis)
			WTurn(id, spindropAxis, math.rad(0), 15) 
        end)
	Sleep(5000)
	
end

function circleProject(allLetters, posLetters)
    circumference = count(allLetters) * sizeSpacingLetter *2.0
    textCirumference = count(allLetters) * sizeSpacingLetter
    radius = circumference / (2 * math.pi)
    radiant = (math.pi *2)/(count(allLetters)*2.0)
    hideTReg(allLetters)

    i=0
    foreach(allLetters,
        function(pID)

        reset(pID, 0)
        radiantVal = radiant*i
        ShowReg(pID)
        local xr = radius * math.cos(radiantVal)
        local zr = radius * math.sin(radiantVal)

        Move(pID,x_axis, xr, math.abs(xr)/2.0)
        Move(pID,z_axis, zr, math.abs(zr)/2.0)
        Turn(pID,y_axis, math.pi + radiantVal, 0)
        i = i +1
        end)
    Sleep(15000)
    hideTReg(allLetters) 
end

function SpiralUpwards(allLetters, posLetters)

    hideTReg(allLetters)
    foreach(allLetters,
        function(id)
                Move(id, 3, posLetters[id][3] - 5000, 0)     
                Spin(id, spindropAxis, math.rad(42), 15)     
        end)
    Sleep(1000)

    foreach(allLetters,
        function(id)
            ShowReg(id)
            Move(id,3, posLetters[id][3], 2500)
            Sleep(250)
        end)
    WaitForMoves(allLetters)
    Sleep(2000)   

    resetSpinDrop(allLetters)
    WaitForTurns(allLetters)
end


function SwarmLetters(allLetters, posLetters)
    foreach(allLetters,
        function(id)
            for i=1,3 do
                Move(id, i, posLetters[id][i]+ math.random(0,1000)*randSign(), 0)
            end            
        end)
    Sleep(1000)

    foreach(allLetters,
        function(id)
            for i=1,3 do
                Move(id, i, posLetters[id][i], 350)            
            end
            ShowReg(id)
        end)
    WaitForMoves(allLetters)
    Sleep(2000)
end

function SpinLetters(allLetters)
    foreach(allLetters,
        function(id)
            rval = math.random(-360,360)
        Spin(id, spindropAxis, math.rad(rval), 15)
        ShowReg(id)
        end)
    Sleep(1000)
    resetSpinDrop(allLetters)    
    WaitForTurns(allLetters)
    hideTReg(allLetters)
    Sleep(2000)
end

function HideLetters(allLetters)
    direction =  randSign()
    --Setup
     for j=1, #allLetters do
    		HideReg(allLetters[j])
            WMove(allLetters[j],backdropAxis, 150, 300)
    		ShowReg(allLetters[j])
    		Move(allLetters[j],backdropAxis, 0, 600)				
     end

    rest = math.random(4, 16)*500
    Sleep(rest)
end

function SinusLetter(allLetters)
    direction =  randSign()
    for i=1, 10 do
        timeStep = i * math.pi/#allLetters
        for j=1, #allLetters do
            Move(allLetters[j],backdropAxis, 500 * math.sin(timeStep*j)*direction, 500)
        end
        Sleep(500)
    end
    rest = math.random(4, 16)*500
    Sleep(rest)
    for j=1, #allLetters do
        WMove(allLetters[j],backdropAxis, 0, 500)
    end
end

function CrossLetters(allLetters)
    direction =  randSign()
    -- Reset
    for i=1, #allLetters do
        id =allLetters[i]
        Move(id, backdropAxis, math.random(250,500)*direction, 0)
        HideReg(id)
    end
    for i=1, #allLetters do
        id =allLetters[i]
        Move(id, backdropAxis,0, 1600)
        ShowReg(id)
        WaitForMoves(id)
    end

    rest = math.random(4, 16)*500
    Sleep(rest)
end



function addJHologramLetters()
    if maRa() == maRa() then return end
    message = {}
    for i=1,6 do
        message[i] = math.random(1,41)
    end
    axis= 2
    boolUpRight = maRa()
    if boolUpRight then
        _,background = randDict(TableOfPiecesGroups["JUpright"])
    else
        _,background = randDict(TableOfPiecesGroups["JHorizontal"])
    end
     ShowReg(background)
    downIndex = 1
    --echo("Adding Grafiti with message:" ..myMessage)
    stringlength = 6
    rowIndex= 0
    columnIndex= 0

    val = math.random(5,45)
    for i=1, stringlength do
        if TableOfPiecesGroups["JLetter"][message[i]] then
            local pieceName = TableOfPiecesGroups["JLetter"][message[i]]                   
            ShowReg(pieceName)
            Move(pieceName, 3,  -sizeDownLetter*rowIndex, 0)
            Move(pieceName,axis, sizeSpacingLetter*(columnIndex), 0)
            if boolUpRight then
                columnIndex= 0
                rowIndex= rowIndex +1
            else           
                columnIndex = columnIndex +1
            end
        end
    end
end


-------------------------------------------TIGLILI COPIED CRAP --------------------------

function TigLilSetup()    
    --echo("dancing tilgil a1")
    HideReg(tlpole)
    HideReg(deathpivot)
    HideReg(tldrum)
    --HideReg(tlharp)
    HideReg(tlflute)
    HideReg(ball)
    HideReg(handr)
    --echo("dancing tilgil a2")
    HideReg(handl)
    ShowReg(tigLil)
    ShowReg(tlHead)
    ShowReg(tlhairup)
    ShowReg(tlhairdown)
    ShowReg(tlarm)
    ShowReg(tlarmr)
    --echo("dancing tilgil a3")
    ShowReg(tllegUp)
    ShowReg(tllegLow)
    ShowReg(tllegUpR)
    ShowReg(tllegLowR)
    --echo("dancing tilgil a4")

    Turn(tigLil, y_axis, math.rad(0), 4)
    Turn(tigLil, z_axis, math.rad(0), 4)
    Turn(tlHead, x_axis, math.rad(0), 4)
    Turn(tlHead, y_axis, math.rad(0), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)
    Turn(tlhairup, x_axis, math.rad(-74), 2)
    Turn(tlhairup, y_axis, math.rad(0), 2)
    Turn(tlhairup, z_axis, math.rad(0), 2)
    Turn(tlhairdown, x_axis, math.rad(-19), 3)
    Turn(tllegUp, x_axis, math.rad(0), 3)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 2)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 2)
    Turn(tllegLow, z_axis, math.rad(0), 2)
    Turn(tllegUpR, x_axis, math.rad(0), 3)
    Turn(tllegUpR, y_axis, math.rad(0), 2)
    Turn(tllegUpR, z_axis, math.rad(0), 4)
    Turn(tllegLowR, x_axis, math.rad(0), 2)
    Turn(tllegLowR, y_axis, math.rad(0), 2)
    Turn(tllegLowR, z_axis, math.rad(0), 2)
    Turn(tlarmr, y_axis, math.rad(0), 3)

    Turn(tlarmr, z_axis, math.rad(0), 3)
    --echo("dancing tilgil a5")

    Turn(tlarmr, x_axis, math.rad(0), 3)


    Turn(tlarm, y_axis, math.rad(0), 4)

    Turn(tlarm, z_axis, math.rad(0), 3)
    Turn(tlarm, x_axis, math.rad(0), 3)

    WaitForTurn(tigLil, y_axis)
    WaitForTurn(tigLil, z_axis)
    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlHead, y_axis)
    WaitForTurn(tlHead, z_axis)
    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlhairup, y_axis)
    WaitForTurn(tlhairup, z_axis)
    WaitForTurn(tlhairdown, x_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    WaitForTurn(tlarmr, y_axis)

    WaitForTurn(tlarmr, z_axis)


    WaitForTurn(tlarmr, x_axis)


    WaitForTurn(tlarm, y_axis)

    WaitForTurn(tlarm, z_axis)

    WaitForTurn(tlarm, x_axis)
    --echo("dancing tilgil a6")
    legs_down()
    --echo("dancing tilgil a7")
    --changebookmark 
    Sleep(285)
end

--------------------- IdleStance10-Fucntions-------
function drumClapOverhead()



    Turn(tigLil, x_axis, math.rad(-18), 4)
    Turn(tigLil, z_axis, math.rad(0), 4)


    Turn(tlHead, x_axis, math.rad(-13), 4)
    Turn(tlHead, y_axis, math.rad(0), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)

    tempRand = math.random(-12, 18)
    Turn(tlhairup, x_axis, math.rad(39), 4)
    Turn(tlhairup, y_axis, math.rad(tempRand), 4)
    tempRand = math.random(-7, 7)
    Turn(tlhairup, z_axis, math.rad(tempRand), 4)

    Turn(tlhairdown, x_axis, math.rad(-46), 4)

    Turn(tlarm, x_axis, math.rad(-17), 4)
    Turn(tlarm, y_axis, math.rad(-104), 7)
    Turn(tlarm, z_axis, math.rad(-117), 6)


    Turn(tlarmr, x_axis, math.rad(180), 6)
    Turn(tlarmr, y_axis, math.rad(-87), 6)
    Turn(tlarmr, z_axis, math.rad(-59), 5)

    Turn(tllegUp, x_axis, math.rad(21), 4)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 2)


    Turn(tllegLow, x_axis, math.rad(0), 4)
    Turn(tllegLow, y_axis, math.rad(0), 4)
    Turn(tllegLow, z_axis, math.rad(0), 4)


    Turn(tllegUpR, x_axis, math.rad(45), 4)
    Turn(tllegUpR, y_axis, math.rad(15), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 2)

    Turn(tllegLowR, x_axis, math.rad(89), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 4)
    Turn(tllegLowR, z_axis, math.rad(0), 4)


    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tigLil, z_axis)


    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlHead, y_axis)
    WaitForTurn(tlHead, z_axis)


    --WaitForTurn(tlhairup,x_axis)
    --WaitForTurn(tlhairup,y_axis)

    --WaitForTurn(tlhairup,z_axis)

    --WaitForTurn(tlhairdown,x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)


    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)


    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)


    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)

    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    --------------- Clap---------------



    Turn(tigLil, x_axis, math.rad(-12), 4)
    Turn(tigLil, z_axis, math.rad(0), 4)


    Turn(tlHead, x_axis, math.rad(5), 4)
    Turn(tlHead, y_axis, math.rad(15), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)


    tempRand = math.random(-55, -20)
    Turn(tlhairup, x_axis, math.rad(tempRand), 3)
    tempRand = math.random(-27, 5)
    Turn(tlhairup, y_axis, math.rad(tempRand), 4)
    tempRand = math.random(-7, 7)
    Turn(tlhairup, z_axis, math.rad(tempRand), 4)

    tempRand = math.random(-36, 26)
    Turn(tlhairdown, x_axis, math.rad(tempRand), 4)

    Turn(tlarm, x_axis, math.rad(-17), 4)
    Turn(tlarm, y_axis, math.rad(-96), 5)
    Turn(tlarm, z_axis, math.rad(-117), 5)


    Turn(tlarmr, x_axis, math.rad(182), 4)
    Turn(tlarmr, y_axis, math.rad(-101), 4)
    Turn(tlarmr, z_axis, math.rad(-67), 4)

    Turn(tllegUp, x_axis, math.rad(-47), 5)
    Turn(tllegUp, y_axis, math.rad(15), 4)
    Turn(tllegUp, z_axis, math.rad(0), 4)


    Turn(tllegLow, x_axis, math.rad(91), 7)
    Turn(tllegLow, y_axis, math.rad(0), 4)
    Turn(tllegLow, z_axis, math.rad(0), 4)


    Turn(tllegUpR, x_axis, math.rad(10), 5)
    Turn(tllegUpR, y_axis, math.rad(15), 4)
    Turn(tllegUpR, z_axis, math.rad(0), 4)

    Turn(tllegLowR, x_axis, math.rad(4), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 4)
    Turn(tllegLowR, z_axis, math.rad(0), 4)



    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tigLil, z_axis)


    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlHead, y_axis)
    WaitForTurn(tlHead, z_axis)

    --WaitForTurn(tlhairup,x_axis)

    --WaitForTurn(tlhairup,y_axis)

    --WaitForTurn(tlhairup,z_axis)


    --WaitForTurn(tlhairdown,x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)


    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)


    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)


    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)

    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)





    ---------------------------- Retour-----------------


    Turn(tigLil, x_axis, math.rad(-18), 4)
    Turn(tigLil, z_axis, math.rad(0), 4)


    Turn(tlHead, x_axis, math.rad(-13), 4)
    Turn(tlHead, y_axis, math.rad(0), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)

    tempRand = math.random(-12, 18)
    Turn(tlhairup, x_axis, math.rad(39), 4)
    Turn(tlhairup, y_axis, math.rad(tempRand), 4)
    tempRand = math.random(-7, 7)
    Turn(tlhairup, z_axis, math.rad(tempRand), 4)

    Turn(tlhairdown, x_axis, math.rad(-46), 4)

    Turn(tlarm, x_axis, math.rad(-17), 4)
    Turn(tlarm, y_axis, math.rad(-104), 6)
    Turn(tlarm, z_axis, math.rad(-117), 7)


    Turn(tlarmr, x_axis, math.rad(180), 8)
    Turn(tlarmr, y_axis, math.rad(-87), 6)
    Turn(tlarmr, z_axis, math.rad(-59), 5)

    Turn(tllegUp, x_axis, math.rad(21), 4)
    Turn(tllegUp, y_axis, math.rad(0), 4)
    Turn(tllegUp, z_axis, math.rad(0), 4)


    Turn(tllegLow, x_axis, math.rad(0), 5)
    Turn(tllegLow, y_axis, math.rad(0), 4)
    Turn(tllegLow, z_axis, math.rad(0), 4)


    Turn(tllegUpR, x_axis, math.rad(45), 7)
    Turn(tllegUpR, y_axis, math.rad(15), 5)
    Turn(tllegUpR, z_axis, math.rad(0), 4)

    Turn(tllegLowR, x_axis, math.rad(89), 7)
    Turn(tllegLowR, y_axis, math.rad(0), 4)
    Turn(tllegLowR, z_axis, math.rad(0), 4)

    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tigLil, z_axis)


    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlHead, y_axis)
    WaitForTurn(tlHead, z_axis)

    --WaitForTurn(tlhairup,x_axis)
    --WaitForTurn(tlhairup,y_axis)

    --WaitForTurn(tlhairup,z_axis)

    --WaitForTurn(tlhairdown,x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)


    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)


    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)


    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)

    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
end

function drumClapFront()
    Turn(tigLil, x_axis, math.rad(25), 3)
    Turn(tigLil, z_axis, math.rad(0), 4)

    Turn(tlHead, x_axis, math.rad(55), 4)
    Turn(tlHead, y_axis, math.rad(-6), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)

    tempRand = math.random(55, 80)
    Turn(tlhairup, x_axis, math.rad(tempRand), 7)
    tempRand = math.random(-27, 19)
    Turn(tlhairup, y_axis, math.rad(tempRand), 2)
    tempRand = math.random(-5, 45)
    Turn(tlhairup, z_axis, math.rad(tempRand), 5)

    tempRand = math.random(34, 52)

    Turn(tlhairdown, x_axis, math.rad(tempRand), 3)

    Turn(tlarm, x_axis, math.rad(0), 4)
    Turn(tlarm, y_axis, math.rad(-82), 4)
    Turn(tlarm, z_axis, math.rad(-206), 4)


    Turn(tlarmr, x_axis, math.rad(54), 4)
    Turn(tlarmr, y_axis, math.rad(-174), 4)
    Turn(tlarmr, z_axis, math.rad(-72), 4)

    tempRand = math.random(-30, 6)
    Turn(tllegUp, x_axis, math.rad(tempRand), 5)
    Turn(tllegUp, y_axis, math.rad(15), 4)
    Turn(tllegUp, z_axis, math.rad(0), 4)

    Turn(tllegLow, x_axis, math.rad(0), 4)
    Turn(tllegLow, y_axis, math.rad(0), 4)
    Turn(tllegLow, z_axis, math.rad(0), 4)

    tempRand = math.random(-101, -84)
    Turn(tllegUpR, x_axis, math.rad(tempRand), 5)
    Turn(tllegUpR, y_axis, math.rad(15), 4)
    Turn(tllegUpR, z_axis, math.rad(0), 4)

    tempRand = math.random(120, 148)
    Turn(tllegLowR, x_axis, math.rad(tempRand), 8)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)


    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tigLil, z_axis)


    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlHead, y_axis)
    WaitForTurn(tlHead, z_axis)


    --WaitForTurn(tlhairup,x_axis)

    --WaitForTurn(tlhairup,y_axis)
    --WaitForTurn(tlhairup,z_axis)


    --WaitForTurn(tlhairdown,x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)


    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)


    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)

    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)


    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)


    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    --------------- UnClap---------------

    Turn(tigLil, x_axis, math.rad(15), 4)
    Turn(tigLil, z_axis, math.rad(0), 4)


    Turn(tlHead, x_axis, math.rad(36), 4)
    Turn(tlHead, y_axis, math.rad(-6), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)

    tempdown = math.random(-105, -95)
    Turn(tlhairup, x_axis, math.rad(tempdown), 4) -- -15
    Turn(tlhairup, y_axis, math.rad(5), 4)
    Turn(tlhairup, z_axis, math.rad(0), 4)
    tempDownO = math.random(-75, -68)
    Turn(tlhairdown, x_axis, math.rad(tempDownO), 5) -- -58

    Turn(tlarm, x_axis, math.rad(0), 4)
    Turn(tlarm, y_axis, math.rad(-87), 4)
    Turn(tlarm, z_axis, math.rad(-190), 4)


    Turn(tlarmr, x_axis, math.rad(77), 6)
    Turn(tlarmr, y_axis, math.rad(-161), 6)
    Turn(tlarmr, z_axis, math.rad(-67), 6)

    Turn(tllegUp, x_axis, math.rad(-75), 5)
    Turn(tllegUp, y_axis, math.rad(15), 4)
    Turn(tllegUp, z_axis, math.rad(0), 4)


    Turn(tllegLow, x_axis, math.rad(91), 8)
    Turn(tllegLow, y_axis, math.rad(0), 4)
    Turn(tllegLow, z_axis, math.rad(0), 4)


    Turn(tllegUpR, x_axis, math.rad(-19), 2)
    Turn(tllegUpR, y_axis, math.rad(15), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 4)

    Turn(tllegLowR, x_axis, math.rad(4), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 4)
    Turn(tllegLowR, z_axis, math.rad(0), 4)


    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tigLil, z_axis)


    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlHead, y_axis)
    WaitForTurn(tlHead, z_axis)


    --WaitForTurn(tlhairup,x_axis)
    --WaitForTurn(tlhairup,y_axis)
    --WaitForTurn(tlhairup,z_axis)

    --WaitForTurn(tlhairdown,x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)


    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)


    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)


    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)

    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    ------------------------------------------




    Turn(tigLil, x_axis, math.rad(25), 4)
    Turn(tigLil, z_axis, math.rad(0), 4)


    Turn(tlHead, x_axis, math.rad(55), 4)
    Turn(tlHead, y_axis, math.rad(-6), 4)
    Turn(tlHead, z_axis, math.rad(0), 4)

    tempRand = math.random(-83, 73)
    Turn(tlhairup, x_axis, math.rad(tempRand), 4)
    tempRand = math.random(-27, 19)
    Turn(tlhairup, y_axis, math.rad(tempRand), 4)
    tempRand = math.random(-5, 45)
    Turn(tlhairup, z_axis, math.rad(tempRand), 4)

    tempRand = math.random(4, 52)

    Turn(tlhairdown, x_axis, math.rad(tempRand), 4)

    Turn(tlarm, x_axis, math.rad(0), 4)
    Turn(tlarm, y_axis, math.rad(-82), 4)
    Turn(tlarm, z_axis, math.rad(-206), 4)


    Turn(tlarmr, x_axis, math.rad(54), 4)
    Turn(tlarmr, y_axis, math.rad(-174), 4)
    Turn(tlarmr, z_axis, math.rad(-72), 4)

    tempRand = math.random(-30, 6)
    Turn(tllegUp, x_axis, math.rad(tempRand), 4)
    Turn(tllegUp, y_axis, math.rad(15), 4)
    Turn(tllegUp, z_axis, math.rad(0), 4)

    Turn(tllegLow, x_axis, math.rad(0), 4)
    Turn(tllegLow, y_axis, math.rad(0), 4)
    Turn(tllegLow, z_axis, math.rad(0), 4)

    tempRand = math.random(-101, -84)
    Turn(tllegUpR, x_axis, math.rad(tempRand), 4)
    Turn(tllegUpR, y_axis, math.rad(15), 4)
    Turn(tllegUpR, z_axis, math.rad(0), 4)

    tempRand = math.random(120, 148)
    Turn(tllegLowR, x_axis, math.rad(tempRand), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 4)
    Turn(tllegLowR, z_axis, math.rad(0), 4)

    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)

    Sleep(60)
end


function danceEnd()


    Turn(tigLil, x_axis, math.rad(0), 3)
    Turn(tigLil, y_axis, math.rad(0), 3)
    Turn(tigLil, z_axis, math.rad(0), 3)


    Turn(tlHead, x_axis, math.rad(0), 3)
    Turn(tlHead, y_axis, math.rad(35), 3)
    Turn(tlHead, z_axis, math.rad(0), 3)

    Turn(tlhairup, x_axis, math.rad(0), 3)
    Turn(tlhairup, y_axis, math.rad(-135), 3)
    Turn(tlhairup, z_axis, math.rad(-279), 3)

    Turn(tlhairdown, x_axis, math.rad(45), 3)

    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(30), 3)
    Turn(tlarm, z_axis, math.rad(39), 3)

    Turn(tlarmr, x_axis, math.rad(0), 3)
    Turn(tlarmr, y_axis, math.rad(37), 3)
    Turn(tlarmr, z_axis, math.rad(0), 3)


    Turn(tllegUp, x_axis, math.rad(-4), 3)
    Turn(tllegUp, y_axis, math.rad(-1), 3)
    Turn(tllegUp, z_axis, math.rad(12), 3)

    Turn(tllegLow, x_axis, math.rad(0), 3)


    Turn(tllegUpR, x_axis, math.rad(4), 3)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(-8), 3)

    Turn(tllegLowR, x_axis, math.rad(0), 3)

    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)




    Turn(tlHead, x_axis, math.rad(0), 3)
    Turn(tlHead, y_axis, math.rad(3), 3)
    Turn(tlHead, z_axis, math.rad(0), 3)

    Turn(tlhairup, x_axis, math.rad(0), 3)
    Turn(tlhairup, y_axis, math.rad(37), 3)
    Turn(tlhairup, z_axis, math.rad(279), 3)

    Turn(tlhairdown, x_axis, math.rad(-60), 3)

    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(0), 3)
    Turn(tlarm, z_axis, math.rad(23), 3)

    Turn(tlarmr, x_axis, math.rad(0), 3)
    Turn(tlarmr, y_axis, math.rad(0), 3)
    Turn(tlarmr, z_axis, math.rad(-30), 3)


    Turn(tllegUp, x_axis, math.rad(-45), 3)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(12), 3)

    Turn(tllegLow, x_axis, math.rad(0), 3)


    Turn(tllegUpR, x_axis, math.rad(90), 3)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(-8), 3)


    Turn(tllegLowR, x_axis, math.rad(0), 3)

    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)

    Move(tigLil, y_axis, -8, 19)

    Turn(tigLil, x_axis, math.rad(15), 3)
    Turn(tigLil, y_axis, math.rad(0), 3)
    Turn(tigLil, z_axis, math.rad(0), 3)


    Turn(tlHead, x_axis, math.rad(41), 3)
    Turn(tlHead, y_axis, math.rad(-15), 3)
    Turn(tlHead, z_axis, math.rad(0), 3)

    Turn(tlhairup, x_axis, math.rad(0), 3)
    Turn(tlhairup, y_axis, math.rad(37), 3)
    Turn(tlhairup, z_axis, math.rad(279), 3)

    Turn(tlhairdown, x_axis, math.rad(-60), 3)

    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(52), 3)
    Turn(tlarm, z_axis, math.rad(14), 3)

    Turn(tlarmr, x_axis, math.rad(0), 3)
    Turn(tlarmr, y_axis, math.rad(51), 3)
    Turn(tlarmr, z_axis, math.rad(-30), 3)


    Turn(tllegUp, x_axis, math.rad(-114), 3)
    Turn(tllegUp, y_axis, math.rad(1), 3)
    Turn(tllegUp, z_axis, math.rad(12), 3)

    Turn(tllegLow, x_axis, math.rad(98), 3)


    Turn(tllegUpR, x_axis, math.rad(47), 3)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)

    Turn(tllegLowR, x_axis, math.rad(20), 3)
    Sleep(128)


    Turn(tlHead, x_axis, math.rad(41), 3)
    Turn(tlHead, y_axis, math.rad(21), 3)
    Turn(tlHead, z_axis, math.rad(0), 3)

    Turn(tlhairup, x_axis, math.rad(-26), 3)
    Turn(tlhairup, y_axis, math.rad(109), 3)
    Turn(tlhairup, z_axis, math.rad(-286), 3)

    Turn(tlhairdown, x_axis, math.rad(-49), 3)
    WaitForMove(tigLil, y_axis)
    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)

    Move(tigLil, y_axis, 0, 12)

    WaitForMove(tigLil, y_axis)
end

function danceTurnLeft()
    Signal(SIG_INCIRCLE)
    SetSignalMask(SIG_INCIRCLE)
    while (true) do


        ---
        Turn(tigLil, x_axis, math.rad(-14), 3)

        Turn(tigLil, z_axis, math.rad(0), 3)

        Turn(tlHead, x_axis, math.rad(55), 1)
        Turn(tlHead, y_axis, math.rad(-28), 2)
        Turn(tlhairup, y_axis, math.rad(15), 6)

        Turn(tlhairup, x_axis, math.rad(180), 12)
        Turn(tlhairup, y_axis, math.rad(109), 8)
        Turn(tlhairup, z_axis, math.rad(-270), 14)

        tempHair = math.random(-28, 30)
        Turn(tlhairdown, x_axis, math.rad(tempHair), 3)
        Turn(tlarm, x_axis, math.rad(79), 6)
        Turn(tlarm, y_axis, math.rad(28), 3)
        Turn(tlarm, z_axis, math.rad(39), 4)

        Turn(tlarmr, x_axis, math.rad(61), 5)
        Turn(tlarmr, y_axis, math.rad(4), 3)
        Turn(tlarmr, z_axis, math.rad(-22), 3)


        Turn(tllegUp, x_axis, math.rad(-50), 4)
        Turn(tllegUp, y_axis, math.rad(0), 4)
        Turn(tllegUp, z_axis, math.rad(0), 2)

        Turn(tllegLow, x_axis, math.rad(90), 5)


        Turn(tllegUpR, x_axis, math.rad(14), 6)
        Turn(tllegUpR, y_axis, math.rad(-18), 2)
        Turn(tllegUpR, z_axis, math.rad(-7), 3)
        Turn(tllegLow, x_axis, math.rad(27), 4)

        Sleep(250)

        Turn(tigLil, x_axis, math.rad(-14), 3)

        Turn(tigLil, z_axis, math.rad(0), 3)
        Turn(tlHead, x_axis, math.rad(22), 1)
        Turn(tlHead, y_axis, math.rad(-47), 2)
        Turn(tlhairup, y_axis, math.rad(15), 6)
        Sleep(40)
        Turn(tlhairup, x_axis, math.rad(180), 12)
        Turn(tlhairup, y_axis, math.rad(109), 8)
        Turn(tlhairup, z_axis, math.rad(-270), 14)

        tempHair = math.random(-28, 30)
        Turn(tlhairdown, x_axis, math.rad(tempHair), 3)
        Turn(tlarm, x_axis, math.rad(217), 12)
        Turn(tlarm, y_axis, math.rad(28), 3)
        Turn(tlarm, z_axis, math.rad(39), 4)

        Turn(tlarmr, x_axis, math.rad(-34), 5)
        Turn(tlarmr, y_axis, math.rad(4), 3)
        Turn(tlarmr, z_axis, math.rad(-22), 3)


        Turn(tllegUp, x_axis, math.rad(15), 4)
        Turn(tllegUp, y_axis, math.rad(-11), 4)
        Turn(tllegUp, z_axis, math.rad(10), 2)

        Turn(tllegLow, x_axis, math.rad(-17), 5)


        Turn(tllegUpR, x_axis, math.rad(-56), 6)
        Turn(tllegUpR, y_axis, math.rad(-18), 2)
        Turn(tllegUpR, z_axis, math.rad(-7), 3)
        Turn(tllegLow, x_axis, math.rad(113), 4)
        Turn(tllegLow, y_axis, math.rad(18), 4)

        Sleep(260)

        Turn(tigLil, x_axis, math.rad(-53), 3)

        Turn(tigLil, z_axis, math.rad(0), 3)

        Turn(tlHead, x_axis, math.rad(31), 1)
        Turn(tlHead, y_axis, math.rad(-44), 2)
        Turn(tlhairup, y_axis, math.rad(15), 6)

        Turn(tlhairup, x_axis, math.rad(180), 12)
        Turn(tlhairup, y_axis, math.rad(109), 8)
        Turn(tlhairup, z_axis, math.rad(-270), 14)

        tempHair = math.random(-28, 30)
        Turn(tlhairdown, x_axis, math.rad(tempHair), 3)
        Turn(tlarm, x_axis, math.rad(3), 12)
        Turn(tlarm, y_axis, math.rad(-23), 3)
        Turn(tlarm, z_axis, math.rad(39), 4)

        Turn(tlarmr, x_axis, math.rad(-34), 5)
        Turn(tlarmr, y_axis, math.rad(17), 3)
        Turn(tlarmr, z_axis, math.rad(-22), 3)


        Turn(tllegUp, x_axis, math.rad(64), 4)
        Turn(tllegUp, y_axis, math.rad(0), 4)
        Turn(tllegUp, z_axis, math.rad(10), 2)

        Turn(tllegLow, x_axis, math.rad(97), 8)


        Turn(tllegUpR, x_axis, math.rad(39), 4)
        Turn(tllegUpR, y_axis, math.rad(0), 2)
        Turn(tllegUpR, z_axis, math.rad(-7), 3)
        Turn(tllegLow, x_axis, math.rad(15), 4)
        Turn(tllegLow, y_axis, math.rad(0), 4)
        Turn(tllegLow, z_axis, math.rad(7), 4)
        Sleep(250)
        Turn(tigLil, x_axis, math.rad(-14), 3)

        Turn(tigLil, z_axis, math.rad(0), 3)

        Turn(tlHead, x_axis, math.rad(55), 1)
        Turn(tlHead, y_axis, math.rad(-28), 2)
        Turn(tlhairup, y_axis, math.rad(15), 6)

        Turn(tlhairup, x_axis, math.rad(180), 12)
        Turn(tlhairup, y_axis, math.rad(109), 8)
        Turn(tlhairup, z_axis, math.rad(-270), 14)

        tempHair = math.random(-28, 30)
        Turn(tlhairdown, x_axis, math.rad(tempHair), 3)
        tempArm = math.random(55, 80)
        Turn(tlarm, x_axis, math.rad(tempArm), 6)
        Turn(tlarm, y_axis, math.rad(28), 3)
        Turn(tlarm, z_axis, math.rad(39), 4)

        tempArm = math.random(45, 70)
        Turn(tlarmr, x_axis, math.rad(tempArm), 5)
        Turn(tlarmr, y_axis, math.rad(4), 3)
        Turn(tlarmr, z_axis, math.rad(-22), 3)


        Turn(tllegUp, x_axis, math.rad(-50), 4)
        Turn(tllegUp, y_axis, math.rad(0), 4)
        Turn(tllegUp, z_axis, math.rad(0), 2)

        Turn(tllegLow, x_axis, math.rad(90), 5)

        tempLeg = math.random(-10, 34)
        Turn(tllegUpR, x_axis, math.rad(tempLeg), 6)
        Turn(tllegUpR, y_axis, math.rad(-18), 2)
        Turn(tllegUpR, z_axis, math.rad(-7), 3)
        Turn(tllegLow, x_axis, math.rad(27), 4)
        Sleep(250)
    end
end


function talkingHead()
    Signal(SIG_TALKHEAD)
    howlong = math.random(2,12)
    SetSignalMask(SIG_TALKHEAD)
    while (true) do
        for tlH = 0, howlong, 1 do
            rindRand = math.random(-5, 10)
            speedRand = math.random(4, 7)
            Turn(tlHead, x_axis, math.rad(rindRand), speedRand)
            rindRand = math.random(-4, 4)
            Turn(tlHead, z_axis, math.rad(rindRand), 4)
            wordLenght = math.random(40, 280)
            Sleep(wordLenght)
        end
        nonTalk = math.random(400, 2080)
        Sleep(nonTalk)
    end
end


function danceTurnRight()

    Signal(SIG_INCIRCLE)
    SetSignalMask(SIG_INCIRCLE)
    while (true) do


        ---
        Turn(tigLil, x_axis, math.rad(-19), 3)

        Turn(tigLil, z_axis, math.rad(-10), 3)


        Turn(tlHead, x_axis, math.rad(14), 2)
        Turn(tlHead, y_axis, math.rad(-12), 2) --i
        Turn(tlHead, z_axis, math.rad(10), 2)

        Turn(tlhairup, x_axis, math.rad(0), 3)
        Turn(tlhairup, y_axis, math.rad(108), 5) --i
        Turn(tlhairup, z_axis, math.rad(-265), 11)

        Turn(tlhairdown, x_axis, math.rad(22), 3)

        Turn(tlarm, x_axis, math.rad(58), 6)
        Turn(tlarm, y_axis, math.rad(70), 6) --i
        Turn(tlarm, z_axis, math.rad(39), 4)

        Turn(tlarmr, x_axis, math.rad(11), 3)
        Turn(tlarmr, y_axis, math.rad(-50), 5) --i
        Turn(tlarmr, z_axis, math.rad(-1), 3)


        Turn(tllegUp, x_axis, math.rad(31), 3)
        Turn(tllegUp, y_axis, math.rad(-39), 4) --i
        Turn(tllegUp, z_axis, math.rad(3), 3)

        Turn(tllegLow, x_axis, math.rad(12), 3)


        Turn(tllegUpR, x_axis, math.rad(-38), 4)
        Turn(tllegUpR, y_axis, math.rad(31), 3) --i
        Turn(tllegUpR, z_axis, math.rad(-7), 3)

        Turn(tllegLowR, x_axis, math.rad(2), 3)

        Sleep(250)

        Turn(tlHead, x_axis, math.rad(-10), 1)
        Turn(tlHead, y_axis, math.rad(21), 2)
        tempHair = math.random(67, 121)
        Turn(tlhairup, y_axis, math.rad(tempHair), 7)


        Turn(tlhairup, z_axis, math.rad(-270), 12)

        Turn(tlhairdown, x_axis, math.rad(22), 2)

        Turn(tlarm, y_axis, math.rad(26), 3)
        Turn(tlarm, z_axis, math.rad(28), 3)

        Turn(tlarmr, x_axis, math.rad(11), 3)
        Turn(tlarmr, y_axis, math.rad(-44), 4)
        Turn(tlarmr, z_axis, math.rad(50), 5)


        Turn(tllegUp, x_axis, math.rad(-50), 5)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)

        Turn(tllegLow, x_axis, math.rad(90), 8)


        Turn(tllegUpR, x_axis, math.rad(0), 3)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(-7), 1)

        Sleep(250)
        Turn(tlHead, x_axis, math.rad(-26), 3)
        Turn(tlHead, y_axis, math.rad(14), 3)
        Turn(tlHead, z_axis, math.rad(10), 3)

        Turn(tlhairup, x_axis, math.rad(19), 2)
        Turn(tlhairup, y_axis, math.rad(109), 9)
        Turn(tlhairup, z_axis, math.rad(230), 11)

        Turn(tlhairdown, x_axis, math.rad(-20), 2)
        Turn(tlarm, x_axis, math.rad(58), 4)
        Turn(tlarm, y_axis, math.rad(14), 2)
        Turn(tlarm, z_axis, math.rad(39), 3)

        Turn(tlarmr, x_axis, math.rad(11), 3)
        Turn(tlarmr, y_axis, math.rad(-25), 3)
        Turn(tlarmr, z_axis, math.rad(50), 4)


        Turn(tllegUp, x_axis, math.rad(-7), 5)
        Turn(tllegUp, y_axis, math.rad(0), 5)
        Turn(tllegUp, z_axis, math.rad(3), 5)

        Turn(tllegLow, x_axis, math.rad(12), 4)


        Turn(tllegUpR, x_axis, math.rad(-43), 5)
        Turn(tllegUpR, y_axis, math.rad(-24), 4)
        Turn(tllegUpR, z_axis, math.rad(-7), 3)

        Sleep(250)

        Turn(tlHead, x_axis, math.rad(-10), 1)
        Turn(tlHead, y_axis, math.rad(21), 2)
        Turn(tlhairup, y_axis, math.rad(109), 6)

        Turn(tlhairup, x_axis, math.rad(0), 4)
        Turn(tlhairup, z_axis, math.rad(-270), 5)

        Turn(tlhairdown, x_axis, math.rad(22), 3)

        Turn(tlarm, y_axis, math.rad(26), 3)
        Turn(tlarm, z_axis, math.rad(28), 3)

        Turn(tlarmr, x_axis, math.rad(11), 5)
        Turn(tlarmr, y_axis, math.rad(-114), 3)
        Turn(tlarmr, z_axis, math.rad(-22), 3)


        Turn(tllegUp, x_axis, math.rad(-50), 4)
        Turn(tllegUp, y_axis, math.rad(0), 4)
        Turn(tllegUp, z_axis, math.rad(0), 2)

        Turn(tllegLow, x_axis, math.rad(90), 5)


        Turn(tllegUpR, x_axis, math.rad(14), 6)
        Turn(tllegUpR, y_axis, math.rad(-18), 2)
        Turn(tllegUpR, z_axis, math.rad(-7), 3)
        Turn(tllegLow, x_axis, math.rad(27), 4)

    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)
    end
end


function gestiKulieren()

    SetSignalMask(SIG_GESTE)
    while (true) do

        --Hand back to default


        randSleep = math.random(400, 9001)
        if randSleep > 2049 then

            Turn(tlarmr, x_axis, math.rad(0), 5)
            Turn(tlarmr, y_axis, math.rad(0), 4)

            Turn(tlarmr, z_axis, math.rad(-74), 5)
            Turn(tlarm, x_axis, math.rad(0), 5)
            Turn(tlarm, y_axis, math.rad(0), 4)

            Turn(tlarm, z_axis, math.rad(87), 5)
        end

        Sleep(randSleep)
        decider = math.random(0, 1)
        if decider == 1 then
            --Geste weit offen
            rollDice = math.random(0, 1)
            if rollDice == 1 then
                --DualGeste
                randAlle = math.random(-139, 80)
                Turn(tlarmr, x_axis, math.rad(randAlle), 5)
                Turn(tlarmr, y_axis, math.rad(-90), 4)
                randAlle = math.random(-82, 40)
                Turn(tlarmr, z_axis, math.rad(randAlle), 5)


                Sleep(140)

                randAlle = math.random(-80, 139)
                Turn(tlarm, x_axis, math.rad(randAlle), 3)
                Turn(tlarm, y_axis, math.rad(90), 5)
                randAlle = math.random(-82, 40)
                Turn(tlarm, z_axis, math.rad(randAlle), 4)
            end
            if rollDice == 0 then

                randAlle = math.random(-139, 80)
                Turn(tlarmr, x_axis, math.rad(randAlle), 5)
                Turn(tlarmr, y_axis, math.rad(-90), 4)
                randAlle = math.random(-82, 40)
                Turn(tlarmr, z_axis, math.rad(randAlle), 5)


                Sleep(140)

                --monohanded gestures almost always are executed subconciessly with the prefered hand..
            end
        end

        if decider == 0 then

            x = math.random(12, 52)
            y = math.random(80, 124)

            Turn(tlarmr, x_axis, math.rad(0), 5)
            y = y * -1
            Turn(tlarmr, y_axis, math.rad(y), 5)
            Turn(tlarmr, z_axis, math.rad(x), 5)


            Turn(tlarmr, x_axis, math.rad(0), 5)
            yMax = 124 + y
            y = 80 + yMax - 3
            Turn(tlarmr, y_axis, math.rad(y), 5)
            x = x * -1
            Turn(tlarmr, z_axis, math.rad(x), 5)

            Sleep(180)



            -- Geste zusammen
        end
    end
end


function onTheMove()
    for k=1, 5 do

        if math.random(0, 1) ==1 then
            drumClapOverhead()
        else

            drumClapFront()
        end

        
    end
end


function spagat()

    Move(tigLil, y_axis, -10, 37)

    Turn(tigLil, x_axis, math.rad(0), 3)
    Turn(tigLil, y_axis, math.rad(0), 3)
    Turn(tigLil, z_axis, math.rad(0), 3)


    Turn(tlHead, x_axis, math.rad(0), 3)
    Turn(tlHead, y_axis, math.rad(3), 3)
    Turn(tlHead, z_axis, math.rad(0), 3)

    Turn(tlhairup, x_axis, math.rad(-52), 4)
    Turn(tlhairup, y_axis, math.rad(0), 3)
    Turn(tlhairup, z_axis, math.rad(0), 3)

    Turn(tlhairdown, x_axis, math.rad(-60), 4)

    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(0), 3)
    Turn(tlarm, z_axis, math.rad(-23), 3) --i
    Turn(tlarmr, x_axis, math.rad(0), 3)
    Turn(tlarmr, y_axis, math.rad(0), 3)
    Turn(tlarmr, z_axis, math.rad(30), 3) --i


    Turn(tllegUp, x_axis, math.rad(-90), 6)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(12), 4)

    Turn(tllegLow, x_axis, math.rad(0), 3)


    Turn(tllegUpR, x_axis, math.rad(90), 6)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(-8), 4)

    Turn(tllegLowR, x_axis, math.rad(0), 3)
    WaitForMove(tigLil, y_axis)
    WaitForTurns(tigLil,tlhairdown,tlhairup, tlHead,tlarm,tlarmr,tllegUp,tllegLow,tllegUpR,tllegLowR)

    Sleep(750)

    Turn(tlarm, z_axis, math.rad(23), 9) --i
    Turn(tlarmr, z_axis, math.rad(-23), 9) --i

    Turn(tllegUp, x_axis, math.rad(0), 8)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 4)

    Turn(tllegLow, x_axis, math.rad(0), 3)


    Turn(tllegUpR, x_axis, math.rad(0), 8)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 4)

    Move(tigLil, y_axis, 0, 38)
    WaitForMove(tigLil, y_axis)
    WaitForTurns(tigLil,tlhairdown,tlhairup, tlHead,tlarm,tlarmr,tllegUp,tllegLow,tllegUpR,tllegLowR)
end


function armswing()
    SetSignalMask(SIG_SWING)



    while (true) do
        --needs a redo
        --RightArmForwards,195 --i
        --ToFix: armright swings backward
        dice = math.random(1, 12)

        if dice == 1 then
            tP(tlarmr, 0, 0, 0, 6)
        end
        if dice == 2 then
            tP(tlarm, 0, 0, 0, 6)
        end

        if dice > 2 then
            xdice, ydice, zdice = -1 * math.random(25, 35), -1 * math.random(37, 47), math.random(35, 45)
            tP(tlarmr, xdice, ydice, zdice, 6)
            xdice, ydice, zdice = -1 * math.random(25, 35), math.random(37, 47), math.random(35, 45)
            tP(tlarm, xdice, ydice, zdice, 6)
        end
        Sleep(1350)
    end
end


function creaRandomValue(lowLimit, upLimit)
    randomvalue = math.random(lowLimit, upLimit)
    return randomvalue
end


function  legs_down()
    --printf(unitID, "legs_down")
    HideReg(tlpole)
    HideReg(tldrum)
        --printf(unitID, "legs_down")
    HideReg(tlflute)
    --HideReg(tldancedru)
        --printf(unitID, "legs_down")
    --Move(tldancedru, y_axis, 0, 60)
    --Move(tldancedru, x_axis, 0, 60)
    --Move(tldancedru, z_axis, 0, 60)
    Move(tlHead, y_axis, 0, 60)
    Move(tlHead, x_axis, 0, 60)
    Move(tlHead, z_axis, 0, 60)
    --printf(unitID, "legs_down")
    Move(tlarm, y_axis, 0, 60)
    Move(tlarm, x_axis, 0, 60)
    Move(tlarm, z_axis, 0, 60)
    Move(tlarmr, y_axis, 0, 60)
    Move(tlarmr, x_axis, 0, 60)
    Move(tlarmr, z_axis, 0, 60)
    --printf(unitID, "legs_down")
    Move(tldrum, y_axis, 0, 60)
    Move(tldrum, x_axis, 0, 60)
    Move(tldrum, z_axis, 0, 60)
    --printf(unitID, "legs_down")
    --Turn(tlharp, x_axis, math.rad(0), 45)
    --Turn(tlharp, y_axis, math.rad(0), 45)
    --Turn(tlharp, z_axis, math.rad(0), 45)
    Turn(tlflute, x_axis, math.rad(0), 45)
    Turn(tlflute, y_axis, math.rad(0), 45)
    Turn(tlflute, z_axis, math.rad(0), 45)
    reset(ball)
    reset(BallArcPoint)
    HideReg(ball)
    --printf(unitID, "legs_down")
    StopSpin(tigLil, y_axis)
    StopSpin(tigLil, z_axis)
    StopSpin(tigLil, x_axis)
    StopSpin(dancepivot, y_axis)
    Move(deathpivot, y_axis, 0, 60)
    Move(deathpivot, x_axis, 0, 60)
    Move(deathpivot, z_axis, 0, 60)
    --printf(unitID, "legs_down")
    Turn(dancepivot, x_axis, math.rad(0), 45)
    Turn(dancepivot, y_axis, math.rad(0), 45)
    Turn(dancepivot, z_axis, math.rad(0), 45)
    Move(tigLil, y_axis, 0, 60)
    Move(tigLil, x_axis, 0, 60)
    Move(tigLil, z_axis, 0, 60)
    Turn(deathpivot, x_axis, math.rad(0), 45)
    Turn(deathpivot, y_axis, math.rad(0), 45)
    Turn(deathpivot, z_axis, math.rad(0), 45)
    Turn(tigLil, x_axis, math.rad(0), 32)
    Turn(tigLil, y_axis, math.rad(0), 32)
    Turn(tigLil, z_axis, math.rad(0), 32)
    Turn(tlHead, x_axis, math.rad(0), 2)
    Turn(tlHead, y_axis, math.rad(0), 2)
    Turn(tlHead, z_axis, math.rad(0), 2)
    Turn(tlhairup, x_axis, math.rad(-74), 2)
    Turn(tlhairup, y_axis, math.rad(0), 2)
    --printf(unitID, "legs_down")
    Turn(tlhairup, z_axis, math.rad(0), 2)
    Turn(tlhairdown, x_axis, math.rad(-19), 3)
    Turn(tllegUp, x_axis, math.rad(0), 2)
    Turn(tllegUp, y_axis, math.rad(0), 2)
    Turn(tllegUp, z_axis, math.rad(0), 2)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 2)
    Turn(tllegLow, z_axis, math.rad(0), 2)
    Turn(tllegUpR, x_axis, math.rad(0), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 2)
    Turn(tllegUpR, z_axis, math.rad(0), 2)
    Turn(tllegLowR, x_axis, math.rad(0), 2)
    Turn(tllegLowR, y_axis, math.rad(0), 2)
    Turn(tllegLowR, z_axis, math.rad(0), 2)
    Sleep(75)
    --printf(unitID, "legs_down")
end


function idle_stance5()
    --echo("idle_stance5")
    Turn(tigLil, x_axis, math.rad(-37), 2)
    Turn(tlHead, x_axis, math.rad(-38), 2)
    Turn(tlhairup, x_axis, math.rad(-18), 4)

    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(-32), 3)
    Turn(tlarm, z_axis, math.rad(26), 3)

    Turn(tlarmr, x_axis, math.rad(0), 3)
    Turn(tlarmr, y_axis, math.rad(30), 3)
    Turn(tlarmr, z_axis, math.rad(-42), 3)

    Turn(tllegUp, x_axis, math.rad(22), 3)
    Turn(tllegLow, x_axis, math.rad(16), 3)
    Turn(tllegUpR, x_axis, math.rad(23), 3)
    Turn(tllegLowR, x_axis, math.rad(17), 3)
    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegLowR, x_axis)
    Sleep(1024)

    legs_down()
    Sleep(50)
    Turn(tigLil, x_axis, math.rad(-37), 4)
    Turn(tlHead, x_axis, math.rad(-38), 4)
    Turn(tlhairup, x_axis, math.rad(-18), 4)
    Turn(tlarm, x_axis, math.rad(-42), 3)
    Turn(tlarm, y_axis, math.rad(49), 5)
    Turn(tlarm, z_axis, math.rad(-9), 3)
    Turn(tlarmr, x_axis, math.rad(-42), 5)
    Turn(tlarmr, y_axis, math.rad(-49), 5)
    Turn(tlarmr, z_axis, math.rad(-9), 3)
    Turn(tllegUp, x_axis, math.rad(22), 3)
    Turn(tllegLow, x_axis, math.rad(16), 3)
    Turn(tllegUpR, x_axis, math.rad(23), 3)
    Turn(tllegLowR, x_axis, math.rad(17), 3)


    -- backflip

    Turn(tigLil, x_axis, math.rad(-88), 8)
    Turn(tlarm, x_axis, math.rad(-74), 4)
    Turn(tlarm, y_axis, math.rad(51), 4)
    Turn(tlarm, z_axis, math.rad(-5), 4)
    Turn(tlarmr, x_axis, math.rad(-74), 7)
    Turn(tlarmr, y_axis, math.rad(51), 4)
    Turn(tlarmr, z_axis, math.rad(-5), 4)
    Turn(tllegUp, x_axis, math.rad(42), 5)
    Turn(tllegUpR, x_axis, math.rad(41), 5)
    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUpR, x_axis)


    -- handstand

    Turn(tigLil, x_axis, math.rad(-180), 6)
    Turn(tlHead, x_axis, math.rad(-8), 3)
    Turn(tlhairup, x_axis, math.rad(101), 5)
    Turn(tlhairdown, x_axis, math.rad(21), 3)

    Turn(tlarm, x_axis, math.rad(7), 7)
    Turn(tlarm, y_axis, math.rad(0), 7)
    Turn(tlarm, z_axis, math.rad(-88), 5)

    Turn(tlarmr, x_axis, math.rad(7), 7)
    Turn(tlarmr, y_axis, math.rad(0), 7)
    Turn(tlarmr, z_axis, math.rad(92), 5)

    Turn(tllegUp, x_axis, math.rad(0), 3)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)
    Turn(tllegLow, x_axis, math.rad(0), 3)

    Turn(tllegUpR, x_axis, math.rad(0), 3)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 3)
    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlhairdown, x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)

    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    WaitForTurn(tllegLow, x_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    Sleep(3141)
    --reasumePosition

    Turn(tigLil, x_axis, math.rad(-290), 8)

    Turn(tlhairup, x_axis, math.rad(90), 4)

    Turn(tlarm, x_axis, math.rad(0), 5)
    Turn(tlarm, y_axis, math.rad(-53), 5)
    Turn(tlarm, z_axis, math.rad(0), 5)

    Turn(tlarmr, x_axis, math.rad(0), 5)
    Turn(tlarmr, y_axis, math.rad(53), 5)
    Turn(tlarmr, z_axis, math.rad(0), 5)

    Turn(tllegUp, x_axis, math.rad(-72), 7)
    Turn(tllegUp, y_axis, math.rad(0), 7)
    Turn(tllegUp, z_axis, math.rad(0), 7)
    Turn(tllegLow, y_axis, math.rad(0), 7)
    Turn(tllegLow, z_axis, math.rad(0), 7)
    Turn(tllegLow, x_axis, math.rad(0), 7)

    Turn(tllegUpR, x_axis, math.rad(-41), 8)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 3)

    WaitForTurn(tigLil, x_axis)

    WaitForTurn(tlhairup, x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)

    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    WaitForTurn(tllegLow, x_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    --Return

    Turn(tigLil, x_axis, math.rad(-360), 3)
    Turn(tlHead, x_axis, math.rad(0), 3)
    Turn(tlhairup, x_axis, math.rad(-43), 5)
    Turn(tlhairdown, x_axis, math.rad(-44), 6)

    Turn(tlarm, x_axis, math.rad(0), 5)
    Turn(tlarm, y_axis, math.rad(0), 5)
    Turn(tlarm, z_axis, math.rad(0), 5)

    Turn(tlarmr, x_axis, math.rad(0), 3)
    Turn(tlarmr, y_axis, math.rad(0), 3)
    Turn(tlarmr, z_axis, math.rad(0), 3)

    Turn(tllegUp, x_axis, math.rad(0), 3)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)
    Turn(tllegLow, x_axis, math.rad(0), 3)

    Turn(tllegUpR, x_axis, math.rad(0), 3)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 3)

    Turn(tigLil, x_axis, math.rad(360), 360)

    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlhairdown, x_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)

    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    WaitForTurn(tllegLow, x_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    WaitForTurn(tllegLowR, x_axis)





    legs_down()
end

--like a bitch over troubled water (expandable)
function idle_stance4()
--echo("idle_stance4")
    Turn(tlarm, z_axis, math.rad(-90), 3)
    Turn(tllegUp, x_axis, math.rad(-40), 2)
    Turn(tllegUp, y_axis, math.rad(-80), 2)
    Turn(tllegUp, z_axis, math.rad(-6), 2)
    Turn(tllegLow, x_axis, math.rad(125), 4)
    Turn(tllegUpR, z_axis, math.rad(-8), 2)
    WaitForTurn(tlarm, z_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegUpR, z_axis)
    Sleep(1675)
    dice = math.random(0, 1)
    if dice == 0 then
        --endless poseIbilitys
    end
    if dice == 1 then

        --Move(tigLil,z_axis,-7,5)--i-7
        --Move(tigLil,x_axis,-7,3)
        --WaitForMove(tigLil,x_axis)
        Turn(tigLil, x_axis, math.rad(-90), 12)

        Turn(tigLil, y_axis, math.rad(0), 12)
        Turn(tigLil, z_axis, math.rad(0), 12)

        Turn(tlHead, x_axis, math.rad(-24), 2)

        Turn(tlhairup, x_axis, math.rad(28), 3)

        Turn(tlhairup, y_axis, math.rad(0), 4)
        Turn(tlhairup, z_axis, math.rad(0), 4)

        Turn(tlhairdown, x_axis, math.rad(0), 4)

        Turn(tlarm, x_axis, math.rad(8), 8)
        Turn(tlarm, y_axis, math.rad(-83), 8)
        Turn(tlarm, z_axis, math.rad(-35), 5)

        Turn(tlarmr, x_axis, math.rad(8), 8)
        Turn(tlarmr, y_axis, math.rad(83), 8)
        Turn(tlarmr, z_axis, math.rad(41), 5)

        Turn(tllegUp, x_axis, math.rad(40), 4)
        Turn(tllegUp, y_axis, math.rad(2), 2)
        Turn(tllegUp, z_axis, math.rad(-3), 2)
        Turn(tllegLow, x_axis, math.rad(38), 4)

        Turn(tllegUpR, x_axis, math.rad(42), 3)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 2)

        Turn(tllegLowR, x_axis, math.rad(28), 3)
    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)
        Sleep(2024)

        Turn(tigLil, x_axis, math.rad(1), 12)

        Turn(tigLil, y_axis, math.rad(-90), 8)
        Turn(tigLil, z_axis, math.rad(90), 8)

        Turn(tlHead, x_axis, math.rad(-6), 2)
        Turn(tlHead, y_axis, math.rad(-5), 2)
        Turn(tlHead, z_axis, math.rad(-9), 2)

        Turn(tlhairup, x_axis, math.rad(15), 3)
        Turn(tlhairup, y_axis, math.rad(102), 8)
        Turn(tlhairup, z_axis, math.rad(-90), 7)

        Turn(tlhairdown, x_axis, math.rad(0), 4)

        Turn(tlarm, x_axis, math.rad(65), 8)
        Turn(tlarm, y_axis, math.rad(-83), 8)
        Turn(tlarm, z_axis, math.rad(-86), 6)

        Turn(tlarmr, x_axis, math.rad(8), 8)
        Turn(tlarmr, y_axis, math.rad(83), 8)
        Turn(tlarmr, z_axis, math.rad(41), 5)

        Turn(tllegUp, x_axis, math.rad(40), 5)
        Turn(tllegUp, y_axis, math.rad(90), 4)
        Turn(tllegUp, z_axis, math.rad(-3), 4)
        Turn(tllegLow, x_axis, math.rad(38), 8)

        Turn(tllegUpR, x_axis, math.rad(42), 5)
        Turn(tllegUpR, y_axis, math.rad(0), 4)
        Turn(tllegUpR, z_axis, math.rad(0), 3)

        Turn(tllegLowR, x_axis, math.rad(28), 3)
       WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)


        Turn(tigLil, x_axis, math.rad(90), 12)

        Turn(tigLil, y_axis, math.rad(-187), 12)
        Turn(tigLil, z_axis, math.rad(0), 12)

        Turn(tlHead, x_axis, math.rad(70), 5)
        Turn(tlHead, y_axis, math.rad(0), 2)
        Turn(tlHead, z_axis, math.rad(0), 2)

        Turn(tlhairup, x_axis, math.rad(95), 8)
        Turn(tlhairup, y_axis, math.rad(0), 4)
        Turn(tlhairup, z_axis, math.rad(0), 4)

        Turn(tlhairdown, x_axis, math.rad(0), 4)

        Turn(tlarm, x_axis, math.rad(144), 8)
        Turn(tlarm, y_axis, math.rad(3), 8)
        Turn(tlarm, z_axis, math.rad(-86), 5)

        Turn(tlarmr, x_axis, math.rad(190), 9)
        Turn(tlarmr, y_axis, math.rad(-65), 8)
        Turn(tlarmr, z_axis, math.rad(41), 5)

        Turn(tllegUp, x_axis, math.rad(-87), 8)
        Turn(tllegUp, y_axis, math.rad(-31), 4)
        Turn(tllegUp, z_axis, math.rad(-3), 4)
        Turn(tllegLow, x_axis, math.rad(-8), 6)

        Turn(tllegUpR, x_axis, math.rad(-87), 3)
        Turn(tllegUpR, y_axis, math.rad(31), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 2)

        Turn(tllegLowR, x_axis, math.rad(-8), 3)
     WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)

        legs_down()
    end
end

function idle_stance2()
    --echo("idle_stance2")
    rand = math.random(0, 2)
    if rand == 1 then
        Turn(tlarmr, y_axis, math.rad(-85), 3)
        Turn(tlHead, y_axis, math.rad(23), 2)
        WaitForTurn(tlHead, y_axis)
        WaitForTurn(tlarmr, y_axis)
        Turn(tlHead, y_axis, math.rad(-63), 2)
        Turn(tlarm, y_axis, math.rad(-90), 4)
        WaitForTurn(tlarm, y_axis)
        Sleep(50)
        Turn(tlarm, z_axis, math.rad(-120), 4)
        WaitForTurn(tlarm, z_axis)
        Sleep(550)
    end
    if rand == 0 then
        --snowAngel
        Move(deathpivot, y_axis, 2, 2)
        Turn(deathpivot, x_axis, math.rad(-94), 1)
        Turn(tlhairup, x_axis, math.rad(95), 7)
        angels = math.random(9, 12)
        for i = 0, angels, 1 do


            Turn(tlarmr, z_axis, math.rad(44), 1)
            Turn(tlarm, z_axis, math.rad(-44), 1)
            Turn(tllegUp, z_axis, math.rad(-44), 1)
            Turn(tllegUpR, z_axis, math.rad(44), 1)
            WaitForTurn(tllegUp, z_axis)
            WaitForTurn(tllegUpR, z_axis)
            WaitForTurn(tlarm, z_axis)
            WaitForTurn(tlarmr, z_axis)

            Sleep(50)
            Turn(tlarmr, z_axis, math.rad(0), 1)
            Turn(tllegUpR, z_axis, math.rad(0), 1)
            Turn(tllegUp, z_axis, math.rad(0), 1)
            Turn(tlarm, z_axis, math.rad(0), 1)

            WaitForTurn(tllegUp, z_axis)
            WaitForTurn(tllegUpR, z_axis)
            WaitForTurn(tlarm, z_axis)
            WaitForTurn(tlarmr, z_axis)
            Sleep(172)
        end
        Turn(deathpivot, x_axis, math.rad(0), 7)
        WaitForTurn(deathpivot, x_axis)
    end

    if rand == 2 then
        Turn(tllegUp, x_axis, math.rad(0), 6)
        Turn(tllegUpR, x_axis, math.rad(0), 4)
        Sleep(340)
        Move(deathpivot, y_axis, -1.5, 3)
        Turn(tlarmr, y_axis, math.rad(-90), 4)
        Turn(tlarm, y_axis, math.rad(90), 4)
        Turn(tigLil, x_axis, math.rad(55), 5)
        Turn(tllegUp, x_axis, math.rad(-65), 6)
        Turn(tllegUpR, x_axis, math.rad(55), 4)
        shakeThatTailFeather = math.random(3, 11)
        --bootyshake
        for i = 0, shakeThatTailFeather, 1 do
            Turn(tigLil, y_axis, math.rad(20), 1)
            Turn(tlarmr, y_axis, math.rad(-58), 2)
            Turn(tlarm, y_axis, math.rad(110), 3)
            Turn(tlhairup, y_axis, math.rad(40), 5)
            Turn(tllegUp, x_axis, math.rad(-57), 3)
            Turn(tllegUpR, x_axis, math.rad(-62), 3)
            Turn(tllegUpR, z_axis, math.rad(2), 1)
            WaitForTurn(tigLil, y_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarm, y_axis)

            WaitForTurn(tllegUp, x_axis)
            WaitForTurn(tllegUpR, x_axis)
            WaitForTurn(tllegUpR, z_axis)
            randSleep = math.random(34, 66)
            Sleep(randSleep)

            Turn(tigLil, y_axis, math.rad(-20), 2)
            Turn(tlarmr, y_axis, math.rad(-113), 5)
            Turn(tlarmr, z_axis, math.rad(9), 1)
            Turn(tlarm, y_axis, math.rad(67), 3)
            Turn(tlarm, z_axis, math.rad(4), 2)
            Turn(tlhairup, y_axis, math.rad(-40), 5)
            Turn(tllegUp, x_axis, math.rad(-64), 3)
            Turn(tllegUp, z_axis, math.rad(5), 1)
            Turn(tllegUpR, x_axis, math.rad(-55), 3)
            Turn(tllegUpR, z_axis, math.rad(1), 1)
            WaitForTurn(tigLil, y_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarm, y_axis)

            WaitForTurn(tllegUp, x_axis)
            WaitForTurn(tllegUpR, x_axis)
            WaitForTurn(tllegUpR, z_axis)
            HellsBells = math.random(66, 122)
            Sleep(HellsBells)
        end
        --BUTT - you cant do that PICASSO. OH INTERNET! I DONT EVEN STARTED!
        Turn(tigLil, x_axis, math.rad(3), 5)
        Turn(tigLil, y_axis, math.rad(0), 5)
        Turn(tlarmr, x_axis, math.rad(0), 4)
        Turn(tlarmr, y_axis, math.rad(0), 4)
        Turn(tlarmr, z_axis, math.rad(-77), 4)

        Turn(tlarm, x_axis, math.rad(0), 4)
        Turn(tlarm, y_axis, math.rad(0), 4)
        Turn(tlarm, z_axis, math.rad(86), 4)

        Turn(tllegUp, x_axis, math.rad(0), 6)
        Turn(tllegUp, y_axis, math.rad(0), 6)
        Turn(tllegUp, z_axis, math.rad(5), 6)

        Turn(tllegUpR, x_axis, math.rad(0), 4)
        Turn(tllegUpR, y_axis, math.rad(0), 4)
        Turn(tllegUpR, z_axis, math.rad(6), 4)
        Sleep(128)
        Turn(tlhairup, y_axis, math.rad(0), 5)
        Turn(tlhairdown, x_axis, math.rad(33), 5)
        Turn(tlHead, x_axis, math.rad(-32), 4)
        Turn(tlHead, y_axis, math.rad(-45), 4)
        WaitForTurn(tlHead, x_axis)
        WaitForTurn(tlHead, y_axis)
        Turn(tlarmr, x_axis, math.rad(15), 2)
        Turn(tlarmr, y_axis, math.rad(0), 2)
        Turn(tlarmr, z_axis, math.rad(-63), 3)
        Sleep(80)
        Turn(tlarmr, x_axis, math.rad(15), 2)
        Turn(tlarmr, y_axis, math.rad(0), 2)
        Turn(tlarmr, z_axis, math.rad(-83), 3)
        Sleep(256)
        Turn(tlarm, x_axis, math.rad(0), 8)
        Turn(tlarm, y_axis, math.rad(112), 14)
        Turn(tlarm, z_axis, math.rad(-37), 5)
        --laughing
        tease = math.random(2, 8)
        for i = 0, tease, 1 do
            Turn(tlHead, x_axis, math.rad(-32), 4)
            WaitForTurn(tlHead, x_axis)
            Sleep(66)

            Turn(tlHead, x_axis, math.rad(-15), 3)
            WaitForTurn(tlHead, x_axis)
        end
    end

    legs_down()
    truth = math.random(0, 1)
    if truth == 1 then

        Sleeper = 2

        Move(tigLil, z_axis, -21, 7)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        --Turn(tllegLow,x_axis,math.rad(12),2)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        --Turn(tllegLow,x_axis,math.rad(12),2)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        --Turn(tllegLow,x_axis,math.rad(12),2)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        WaitForMove(tigLil, z_axis)
        Move(tigLil, z_axis, -12, 5)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        --Turn(tllegLow,x_axis,math.rad(12),2)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        --Turn(tllegLow,x_axis,math.rad(12),2)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        WaitForMove(tigLil, z_axis)
        Move(tigLil, z_axis, 0, 7)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)

        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)

        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        --Turn(tllegLow,x_axis,math.rad(12),2)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        WaitForMove(tigLil, z_axis)
        Turn(tlarmr, z_axis, math.rad(-26), 3)
        Turn(tlarmr, x_axis, math.rad(0), 3)
        Turn(tlarmr, y_axis, math.rad(0), 3)

        Turn(tlarm, z_axis, math.rad(-53), 3)
        Turn(tlarm, x_axis, math.rad(0), 3)
        Turn(tlarm, y_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(90), 18)

        Turn(tllegUp, x_axis, math.rad(0), 2)
        Turn(tllegUp, y_axis, math.rad(0), 2)
        Turn(tllegUp, z_axis, math.rad(0), 2)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 2)
        Turn(tllegLow, z_axis, math.rad(0), 2)
        Turn(tllegUpR, x_axis, math.rad(0), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 2)
        Turn(tllegUpR, z_axis, math.rad(0), 2)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 2)
        Turn(tllegLowR, z_axis, math.rad(0), 2)

        Turn(tlhairup, y_axis, math.rad(-90), 18)
        Turn(tlhairup, z_axis, math.rad(-90), 18)

        Turn(tlarmr, z_axis, math.rad(52), 6)



        Spin(tigLil, z_axis, math.rad(70), 12)


        Spin(dancepivot, y_axis, math.rad(40), 9)


        Sleep(10275)
        StopSpin(tigLil, z_axis, 3)
        StopSpin(dancepivot, y_axis, 3)
        Turn(tlhairup, y_axis, math.rad(90), 18)
        Turn(tlhairup, z_axis, math.rad(-90), 18)
    end
end

function idle_stance3()
    --echo("idle_stance3")
    rand = math.random(0, 1)
    if rand == 1 then
        Turn(tlarm, z_axis, math.rad(-52), 4)

        Turn(tlarmr, z_axis, math.rad(49), 4)

        Turn(tllegUp, z_axis, math.rad(-60), 4)
        Turn(tllegUpR, z_axis, math.rad(61), 4)


        WaitForTurn(tlarm, z_axis)
        WaitForTurn(tlarmr, z_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegUpR, z_axis)
        Turn(tigLil, x_axis, math.rad(72), 4)
        Turn(tlHead, x_axis, math.rad(-34), 3)
        Move(tigLil, y_axis, -7, 12)
        WaitForMove(tigLil, y_axis)
        -- works

        Turn(tllegUp, z_axis, math.rad(0), 4)
        Turn(tllegUpR, z_axis, math.rad(0), 8)
        Turn(tllegUpR, x_axis, math.rad(70), 3)
        Turn(tllegLowR, x_axis, math.rad(90), 3)
        Turn(tlarm, z_axis, math.rad(14), 4)
        Turn(tlarm, y_axis, math.rad(88), 7)

        Turn(tllegUp, x_axis, math.rad(25), 2)
        Turn(tllegUp, z_axis, math.rad(-90), 5)
        Turn(tlhairup, x_axis, math.rad(-39), 3)

        WaitForTurn(tigLil, x_axis)
        WaitForTurn(tlHead, x_axis)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegUp, x_axis)

        Sleep(1475)

        Move(tigLil, y_axis, 3, 15)
        Turn(tlarm, x_axis, math.rad(0), 4)
        Turn(tlarm, z_axis, math.rad(0), 4)
        Turn(tlarm, y_axis, math.rad(0), 7)
        Turn(tlarmr, x_axis, math.rad(0), 4)
        Turn(tlarmr, z_axis, math.rad(0), 4)
        Turn(tlarmr, y_axis, math.rad(0), 7)
        Turn(tlHead, x_axis, math.rad(18), 3)
        Turn(tlhairup, x_axis, math.rad(-80), 3)
        Turn(tlhairdown, x_axis, math.rad(-60), 5)
        --reset arms

        Turn(tllegUpR, x_axis, math.rad(-38), 4)

        Turn(tllegUp, z_axis, math.rad(0), 4)
        Turn(tllegUp, x_axis, math.rad(32), 4)
        Turn(tllegUp, x_axis, math.rad(38), 4)
        Turn(tllegLowR, x_axis, math.rad(55), 3)
        Turn(tllegUp, x_axis, math.rad(0), 2)

        Turn(tigLil, x_axis, math.rad(-90), 18)
        WaitForTurn(tigLil, x_axis)
        Turn(tigLil, x_axis, math.rad(-180), 12)
        WaitForTurn(tigLil, x_axis)
        Turn(tigLil, x_axis, math.rad(-270), 8)
        WaitForTurn(tigLil, x_axis)
        Turn(tigLil, x_axis, math.rad(-360), 6)
        WaitForTurn(tigLil, x_axis)

        WaitForMove(tigLil, y_axis)
        WaitForTurn(tigLil, x_axis)
        WaitForTurn(tlHead, x_axis)
        WaitForTurn(tlhairup, x_axis)
        WaitForTurn(tlhairdown, x_axis)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegUp, x_axis)
        Turn(tigLil, x_axis, math.rad(0), 360)
        WaitForTurn(tigLil, x_axis)
        Move(tigLil, y_axis, 0, 35)
    end
    if rand == 0 then
        rand = math.random(0, 1)
        if rand == 0 then
            Turn(tllegUp, x_axis, math.rad(0), 4)
            Turn(tllegUp, y_axis, math.rad(0), 4)
            Turn(tllegUp, z_axis, math.rad(9), 4)
            Turn(tllegLow, x_axis, math.rad(0), 3)
            Turn(tllegUpR, x_axis, math.rad(8), 4)
            Turn(tllegUpR, y_axis, math.rad(0), 4)
            Turn(tllegUpR, z_axis, math.rad(-12), 4)
            Turn(tllegLowR, x_axis, math.rad(0), 3)
            Sleep(540)
            Turn(deathpivot, y_axis, math.rad(360), 4)
            Sleep(2048)
        end
        if rand == 1 then
            Turn(tllegUp, x_axis, math.rad(0), 4)
            Turn(tllegUp, y_axis, math.rad(0), 4)
            Turn(tllegUp, z_axis, math.rad(9), 4)
            Turn(tllegLow, x_axis, math.rad(0), 3)
            Turn(tllegUpR, x_axis, math.rad(8), 4)
            Turn(tllegUpR, y_axis, math.rad(0), 4)
            Turn(tllegUpR, z_axis, math.rad(-12), 4)
            Turn(tllegLowR, x_axis, math.rad(0), 3)



            for i = 0, 10, 1 do
                Turn(tlarm, x_axis, math.rad(9), 4)
                Turn(tlarm, y_axis, math.rad(01), 4)
                rand = math.random(80, 92)
                Turn(tlarm, z_axis, math.rad(rand), 1)
                Turn(tlarmr, x_axis, math.rad(0), 4)
                Turn(tlarmr, y_axis, math.rad(0), 4)
                rand = math.random(-85, -70)
                Turn(tlarmr, z_axis, math.rad(rand), 3)
                rand = math.random(-42, 44)
                Turn(tlHead, z_axis, math.rad(rand), 2)
                rand1 = math.random(0, 1)
                if rand1 == 1 then
                    rand = math.random(-16, 24)
                    Turn(tlHead, y_axis, math.rad(rand), 3)
                end
                --einfach nur rumstehen, einfach sich selbst sein...
                Sleep(4096)
            end
        end
        Turn(tlarm, x_axis, math.rad(0), 4)
        Turn(tlarm, y_axis, math.rad(-41), 4)
        Turn(tlarm, z_axis, math.rad(90), 2)
        Turn(tlarmr, x_axis, math.rad(0), 4)
        Turn(tlarmr, y_axis, math.rad(41), 4)
        Turn(tlarmr, z_axis, math.rad(-79), 3)
        itRandom = math.random(0, 12)

        for it = 0, itRandom, 1 do
            rand = math.random(59, 83)
            Turn(tlarm, z_axis, math.rad(rand), 1)
            rand = math.random(104, 126)
            Turn(tlarmr, z_axis, math.rad(rand), 1)

            Sleep(440)
            rand = math.random(104, 126)
            Turn(tlarm, z_axis, math.rad(rand), 1)
            rand = math.random(-83, -59)
            Turn(tlarmr, z_axis, math.rad(rand), 1)
            Sleep(280)
        end
    end
end

function idle_stance()
--echo("idle_stance")
    Turn(tlHead, y_axis, math.rad(-38), 3)
    WaitForTurn(tlHead, y_axis)
    Turn(tlHead, y_axis, math.rad(20), 2)
    WaitForTurn(tlHead, y_axis)
    Turn(tlarm, z_axis, math.rad(-38), 1)
    Turn(tlarmr, y_axis, math.rad(-22), 1)
    Turn(tlarmr, z_axis, math.rad(-28), 1)
    WaitForTurn(tlarm, z_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)
    Turn(tllegUp, x_axis, math.rad(-5), 1)
    Turn(tllegUp, y_axis, math.rad(-11), 1)
    Turn(tllegUp, z_axis, math.rad(8), 1)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 2)
    Turn(tllegLow, z_axis, math.rad(0), 2)

    Turn(tllegUpR, x_axis, math.rad(105), 6)
    Turn(tllegUpR, y_axis, math.rad(0), 1)
    Turn(tllegUpR, z_axis, math.rad(-12), 1)
    Turn(tllegLowR, x_axis, math.rad(98), 3)
    Turn(tllegLowR, y_axis, math.rad(0), 2)
    Turn(tllegLowR, z_axis, math.rad(0), 2)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    Sleep(325)
    Turn(tlarmr, z_axis, math.rad(38), 3)
    Turn(tlarm, y_axis, math.rad(22), 1)
    Turn(tlarm, z_axis, math.rad(38), 2)
    WaitForTurn(tlarmr, z_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)

    Turn(tlHead, y_axis, math.rad(0), 2)

    Turn(tlarm, z_axis, math.rad(0), 1)
    Turn(tlarmr, y_axis, math.rad(0), 1)
    Turn(tlarmr, z_axis, math.rad(0), 1)

    Turn(tllegUp, x_axis, math.rad(0), 1)
    Turn(tllegUp, y_axis, math.rad(0), 1)
    Turn(tllegUp, z_axis, math.rad(0), 1)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 2)
    Turn(tllegLow, z_axis, math.rad(0), 2)

    Turn(tllegUpR, x_axis, math.rad(0), 6)
    Turn(tllegUpR, y_axis, math.rad(0), 1)
    Turn(tllegUpR, z_axis, math.rad(0), 1)
    Turn(tllegLowR, x_axis, math.rad(0), 3)
    Turn(tllegLowR, y_axis, math.rad(0), 2)
    Turn(tllegLowR, z_axis, math.rad(0), 2)

    Turn(tlarmr, z_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(0), 1)
    Turn(tlarm, z_axis, math.rad(0), 2)
    Sleep(1575)

    rand = math.random(0, 1)
    if rand == 1 then


        temprand = math.random(7, 19)
        for i = 0, temprand, 1 do
            --chat lenght

            howOften = math.random(2, 6)
            rand = math.random(0, 1)
            if rand == 0 then
                --Headshake--disagree
                violently = math.random(5, 9)
                for at = 0, howOften, 1 do
                    if violently > 2 then

                        violently = violently - 1
                    end

                    Turn(tlHead, y_axis, math.rad(-35), violently)
                    Sleep(280)
                    Turn(tlHead, y_axis, math.rad(30), violently)
                    Sleep(180)
                    -------- Spring.Echo("Works1")
                end
            end

            if rand == 1 then
                --Nod (Not the Critizen Kane Nod from C&C) --always important to avoid missunderstandings in code
                -------- Spring.Echo("KillmeImBuggy!1")

                for at = 0, howOften, 1 do

                    Turn(tlHead, x_axis, math.rad(-4), 8)
                    Sleep(280)
                    Turn(tlHead, x_axis, math.rad(22), 9)
                    Sleep(180)
                end
            end


            gestRand = math.random(3, 12)
            for ot = 0, gestRand, 1 do
                howLong = math.random(2, 6)
                -------- Spring.Echo("KillmeImBuggy!2")
                StartThread(talkingHead)
            end
            Sleep(370)

            xif = howLong % 2
            if xif == 1 then
                -------- Spring.Echo("remember")
                Turn(tlarm, x_axis, math.rad(-17), 3)
                Turn(tlarm, y_axis, math.rad(137), 7)
                Turn(tlarm, z_axis, math.rad(-19), 3)
            end
            if xif == 0 then
                -- deute
                -------- Spring.Echo("KillmeImBuggy3!")
                Turn(tlarmr, x_axis, math.rad(1), 3)

                marlonRando = math.random(36, 129)
                marlonRando = marlonRando * -1
                --Turn(tlarmr,y_axis,math.rad((marlonRando)),7)
                Turn(tlarmr, y_axis, math.rad(marlonRando), 7)
                Turn(tlarmr, z_axis, math.rad(0), 3)
                Sleep(640)
                Turn(tlarmr, x_axis, math.rad(0), 3)

                Turn(tlarmr, y_axis, math.rad(marlonRando), 7)
                Turn(tlarmr, z_axis, math.rad(0), 3)
            end

            --Chatblock
            -------- Spring.Echo("KillmeImBuggy!4")
            Sleep(250)
            Signal(SIG_TALKHEAD)
            howLong = math.random(2, 6)
            StartThread(talkingHead)
            Signal(SIG_GESTE)
            StartThread(gestiKulieren)
            Sleep(2048)
            --EndChatblock
            --explain

            dicer = math.random(0, 1)
            if dicer == 1 then
                Signal(SIG_GESTE)
                -------- Spring.Echo("KillmeImBuggy!5")
                legs_down()

                Turn(tlarmr, x_axis, math.rad(0), 1)
                Turn(tlarmr, y_axis, math.rad(-64), 5)
                Turn(tlarmr, z_axis, math.rad(-17), 2)
                Sleep(80)
                Turn(tlarm, x_axis, math.rad(1), 1)
                Turn(tlarm, y_axis, math.rad(95), 5)
                Turn(tlarm, z_axis, math.rad(-8), 12)
                Sleep(200)
                target = math.random(1, 6)
                for ix = 0, target, 1 do
                    torg = math.random(8, 25)
                    ex = ix % 2
                    if ex == 1 then
                        torg = torg * -1
                    end
                    Turn(tlarm, z_axis, math.rad(torg), 12)
                    Sleep(140)
                end
            end
            --Chatblock
            -------- Spring.Echo("KillmeImBuggy!6")
            Signal(SIG_GESTE)
            StartThread(gestiKulieren)
            Signal(SIG_TALKHEAD)
            howLong = math.random(2, 6)
            StartThread(talkingHead)
            forQuiteALongTime = math.random(4096, 8048)
            Sleep(forQuiteALongTime)
            --EndChatblock
            if dicer == 0 then
                --argue&bitch
                Signal(SIG_GESTE)
                -------- Spring.Echo("KillmeImBuggy!7")
                -- FistShaking
                Turn(tigLil, x_axis, math.rad(0), 1)

                Turn(tlarmr, x_axis, math.rad(0), 1)
                Turn(tlarmr, y_axis, math.rad(0), 5)
                Turn(tlarmr, z_axis, math.rad(-71), 8)
                Turn(tlarm, x_axis, math.rad(0), 1)
                Turn(tlarm, y_axis, math.rad(0), 5)
                Turn(tlarm, z_axis, math.rad(71), 8)
                Sleep(120)
                Turn(tlarm, z_axis, math.rad(82), 4)
                Turn(tlarmr, z_axis, math.rad(-65), 4)
                Sleep(120)
                Turn(tlarm, z_axis, math.rad(71), 4)
                Turn(tlarmr, z_axis, math.rad(-71), 4)
                --- StompthatLegUP
                Turn(tllegUpR, x_axis, math.rad(-29), 6)
                Turn(tllegUpR, y_axis, math.rad(0), 1)
                Turn(tllegUpR, z_axis, math.rad(-8), 1)
                Turn(tllegLowR, x_axis, math.rad(57), 3)
                Turn(tllegLowR, y_axis, math.rad(9), 2)
                Turn(tllegLowR, z_axis, math.rad(0), 2)
                Sleep(360)
                --FistShaking
                Turn(tlarmr, x_axis, math.rad(0), 1)
                Turn(tlarmr, y_axis, math.rad(0), 5)
                Turn(tlarmr, z_axis, math.rad(-71), 8)
                Turn(tlarm, x_axis, math.rad(0), 1)
                Turn(tlarm, y_axis, math.rad(0), 5)
                Turn(tlarm, z_axis, math.rad(71), 8)
                Sleep(100)
                Turn(tlarm, z_axis, math.rad(82), 4)
                Turn(tlarmr, z_axis, math.rad(-65), 4)
                Sleep(60)
                Turn(tlarm, z_axis, math.rad(71), 4)
                Turn(tlarmr, z_axis, math.rad(-71), 4)
                Turn(tllegUp, x_axis, math.rad(0), 16)
                Turn(tllegUp, y_axis, math.rad(0), 1)
                Turn(tllegUp, z_axis, math.rad(0), 8)
                Turn(tllegLow, x_axis, math.rad(0), 25)
                Turn(tllegLow, y_axis, math.rad(0), 5)
                Turn(tllegLow, z_axis, math.rad(0), 2)
                Turn(tllegUpR, x_axis, math.rad(0), 16)
                Turn(tllegUpR, y_axis, math.rad(0), 1)
                Turn(tllegUpR, z_axis, math.rad(-8), 8)
                Turn(tllegLowR, x_axis, math.rad(0), 25)
                Turn(tllegLowR, y_axis, math.rad(0), 5)
                Turn(tllegLowR, z_axis, math.rad(0), 2)
                Sleep(180)

                --FistShaking
                Turn(tlarmr, x_axis, math.rad(0), 1)
                Turn(tlarmr, y_axis, math.rad(0), 5)
                Turn(tlarmr, z_axis, math.rad(-71), 8)
                Turn(tlarm, x_axis, math.rad(0), 1)
                Turn(tlarm, y_axis, math.rad(0), 5)
                Turn(tlarm, z_axis, math.rad(71), 8)
                Sleep(120)
                Turn(tlarm, z_axis, math.rad(82), 4)
                Turn(tlarmr, z_axis, math.rad(-65), 4)
                Sleep(120)
                Turn(tlarm, z_axis, math.rad(71), 4)
                Turn(tlarmr, z_axis, math.rad(-71), 4)
                Sleep(120)
            end
            --Chatblock
            -------- Spring.Echo("KillmeImBuggy!8")
            Signal(SIG_GESTE)
            StartThread(gestiKulieren)
            Signal(SIG_TALKHEAD)
            howLong = math.random(2, 6)
            StartThread(talkingHead)
            forQuiteALongTime = math.random(4096, 8048)
            Sleep(forQuiteALongTime)
            --EndChatblock


            -- sexy geste
            oneInSix = math.random(0, 18)
            if oneInSix == 6 then
                -------- Spring.Echo("KillmeImBuggy!9")
                itTerrator = math.random(0, 11)
                Signal(SIG_TALKHEAD)
                Signal(SIG_GESTE)
                speedincreaser = 0.1
                for grafZahl = 0, itTerrator, 1 do
                    --move back
                    if grafzahl == itTerrator - 2 then
                        speedincreaser = speedincreaser + 0.05
                    end

                    speed = 1 * speedincreaser
                    Turn(deathpivot, x_axis, math.rad(-8), speed)
                    speed = 5 * speedincreaser
                    Turn(deathpivot, y_axis, math.rad(0), speed)
                    speed = 8 * speedincreaser
                    Turn(deathpivot, z_axis, math.rad(0), speed)

                    speed = 3 * speedincreaser
                    Turn(tigLil, x_axis, math.rad(17), speed)
                    speed = 2 * speedincreaser
                    Turn(tigLil, y_axis, math.rad(4), speed)
                    speed = 2 * speedincreaser
                    Turn(tigLil, z_axis, math.rad(0), speed)
                    speed = 10 * speedincreaser
                    Turn(tlHead, x_axis, math.rad(26), speed)
                    speed = 5 * speedincreaser
                    Turn(tlHead, y_axis, math.rad(0), speed)
                    speed = 8 * speedincreaser
                    Turn(tlHead, z_axis, math.rad(0), speed)
                    speed = 11 * speedincreaser
                    Turn(tlhairup, x_axis, math.rad(-52), speed)
                    speed = 8 * speedincreaser
                    Turn(tlhairdown, x_axis, math.rad(-30), speed)
                    speed = 3 * speedincreaser
                    Turn(tlarm, x_axis, math.rad(8), speed)
                    speed = 8 * speedincreaser
                    Turn(tlarm, y_axis, math.rad(80), speed)
                    speed = 15 * speedincreaser
                    Turn(tlarm, z_axis, math.rad(55), speed)
                    speed = 1 * speedincreaser
                    Turn(tlarmr, x_axis, math.rad(-9), speed)
                    speed = 5 * speedincreaser
                    Turn(tlarmr, y_axis, math.rad(-80), speed)
                    speed = 15 * speedincreaser
                    Turn(tlarmr, z_axis, math.rad(-55), speed)
                    speed = 16 * speedincreaser
                    Turn(tllegUpR, x_axis, math.rad(-24), speed)
                    speed = 1 * speedincreaser
                    Turn(tllegUpR, y_axis, math.rad(0), speed)
                    speed = 8 * speedincreaser
                    Turn(tllegUpR, z_axis, math.rad(-8), speed)
                    speed = 22 * speedincreaser
                    Turn(tllegLowR, x_axis, math.rad(14), speed)
                    speed = 5 * speedincreaser
                    Turn(tllegLowR, y_axis, math.rad(0), speed)
                    speed = 2 * speedincreaser
                    Turn(tllegLowR, z_axis, math.rad(0), speed)
                    speed = 14 * speedincreaser
                    Turn(tllegUp, x_axis, math.rad(-24), speed)
                    speed = 8 * speedincreaser
                    Turn(tllegUp, y_axis, math.rad(-21), speed)
                    speed = 4 * speedincreaser
                    Turn(tllegUp, z_axis, math.rad(0), speed)
                    speed = 22 * speedincreaser
                    Turn(tllegLow, x_axis, math.rad(15), speed)
                    speed = 5 * speedincreaser
                    Turn(tllegLow, y_axis, math.rad(0), speed)
                    speed = 2 * speedincreaser
                    Turn(tllegLow, z_axis, math.rad(0), speed)
                    Sleep(240)

                    --move forth
                    speed = 6 * speedincreaser
                    Turn(deathpivot, x_axis, math.rad(6), speed)
                    speed = 5 * speedincreaser
                    Turn(deathpivot, y_axis, math.rad(0), speed)
                    speed = 8 * speedincreaser
                    Turn(deathpivot, z_axis, math.rad(0), speed)
                    speed = 3 * speedincreaser
                    Turn(tigLil, x_axis, math.rad(-25), speed)
                    speed = 2 * speedincreaser
                    Turn(tigLil, y_axis, math.rad(4), speed)
                    speed = 2 * speedincreaser
                    Turn(tigLil, z_axis, math.rad(0), speed)
                    speed = 5 * speedincreaser
                    Turn(tlHead, x_axis, math.rad(-18), speed)
                    speed = 5 * speedincreaser
                    Turn(tlHead, y_axis, math.rad(0), speed)
                    speed = 8 * speedincreaser
                    Turn(tlHead, z_axis, math.rad(0), speed)
                    speed = 11 * speedincreaser
                    Turn(tlhairup, x_axis, math.rad(-61), speed)
                    speed = 8 * speedincreaser
                    Turn(tlhairdown, x_axis, math.rad(30), speed)

                    speed = 3 * speedincreaser
                    Turn(tlarm, x_axis, math.rad(8), speed)
                    speed = 8 * speedincreaser
                    Turn(tlarm, y_axis, math.rad(80), speed)
                    speed = 15 * speedincreaser
                    Turn(tlarm, z_axis, math.rad(89), speed)
                    speed = 1 * speedincreaser
                    Turn(tlarmr, x_axis, math.rad(-9), speed)
                    speed = 5 * speedincreaser
                    Turn(tlarmr, y_axis, math.rad(14), speed)
                    speed = 15 * speedincreaser
                    Turn(tlarmr, z_axis, math.rad(-89), 15)
                    speed = 16 * speedincreaser
                    Turn(tllegUpR, x_axis, math.rad(19), speed)
                    speed = 1 * speedincreaser
                    Turn(tllegUpR, y_axis, math.rad(-10), speed)
                    speed = 8 * speedincreaser
                    Turn(tllegUpR, z_axis, math.rad(-8), speed)
                    speed = 22 * speedincreaser
                    Turn(tllegLowR, x_axis, math.rad(14), speed)
                    speed = 5 * speedincreaser
                    Turn(tllegLowR, y_axis, math.rad(0), speed)
                    speed = 2 * speedincreaser
                    Turn(tllegLowR, z_axis, math.rad(0), speed)
                    speed = 16 * speedincreaser
                    Turn(tllegUp, x_axis, math.rad(14), speed)
                    speed = 8 * speedincreaser
                    Turn(tllegUp, y_axis, math.rad(9), speed)
                    speed = 4 * speedincreaser
                    Turn(tllegUp, z_axis, math.rad(0), speed)
                    speed = 22 * speedincreaser
                    Turn(tllegLow, x_axis, math.rad(15), speed)
                    speed = 5 * speedincreaser
                    Turn(tllegLow, y_axis, math.rad(0), speed)
                    speed = 2 * speedincreaser
                    Turn(tllegLow, z_axis, math.rad(0), speed)
                    Sleep(180)

                    if speedincreaser < 1 then
                        speedincreaser = speedincreaser + 0.1
                    end
                end
            end

            Sleep(400)
            Signal(SIG_TALKHEAD)
            howLong = math.random(2, 6)
            StartThread(talkingHead)
            --laughing
            -------- Spring.Echo("KillmeImBuggy!10")
            coinUpYouLive = math.random(0, 6)
            if coinUpYouLive == 3 then
                Turn(deathpivot, x_axis, math.rad(0), 1)
                Turn(deathpivot, y_axis, math.rad(0), 5)
                Turn(deathpivot, z_axis, math.rad(0), 8)

                Turn(tigLil, x_axis, math.rad(19), 3)
                Turn(tigLil, y_axis, math.rad(4), 2)
                Turn(tigLil, z_axis, math.rad(0), 2)

                Turn(tlHead, x_axis, math.rad(0), 5)
                Turn(tlHead, y_axis, math.rad(0), 5)
                Turn(tlHead, z_axis, math.rad(0), 8)

                Turn(tlhairup, x_axis, math.rad(-77), 11)
                Turn(tlhairdown, x_axis, math.rad(-16), 8)


                Turn(tlarm, x_axis, math.rad(-18), 3)
                Turn(tlarm, y_axis, math.rad(-49), 8)
                Turn(tlarm, z_axis, math.rad(113), 15)

                Turn(tlarmr, x_axis, math.rad(0), 1)
                Turn(tlarmr, y_axis, math.rad(-154), 5)
                Turn(tlarmr, z_axis, math.rad(27), 15)

                Turn(tllegUpR, x_axis, math.rad(-47), 16)
                Turn(tllegUpR, y_axis, math.rad(0), 1)
                Turn(tllegUpR, z_axis, math.rad(0), 8)
                Turn(tllegLowR, x_axis, math.rad(47), 25)
                Turn(tllegLowR, y_axis, math.rad(0), 5)
                Turn(tllegLowR, z_axis, math.rad(0), 2)

                Turn(tllegUp, x_axis, math.rad(-44), 16)
                Turn(tllegUp, y_axis, math.rad(0), 8)
                Turn(tllegUp, z_axis, math.rad(0), 4)
                Turn(tllegLow, x_axis, math.rad(16), 25)
                Turn(tllegLow, y_axis, math.rad(0), 5)
                Turn(tllegLow, z_axis, math.rad(0), 2)

                Sleep(50)
                bitchslap = math.random(3, 11)

                for omgImTired = 0, bitchslap, 1 do
                    Turn(tlarm, x_axis, math.rad(-18), 3)
                    Turn(tlarm, y_axis, math.rad(-49), 8)
                    Turn(tlarm, z_axis, math.rad(113), 15)

                    Sleep(150)
                    Turn(tlarm, x_axis, math.rad(-17), 3)
                    Turn(tlarm, y_axis, math.rad(-23), 8)
                    Turn(tlarm, z_axis, math.rad(101), 15)
                    Sleep(230)
                end
            end
        end
    end
end

function idle_stance6()
    --echo("idle_stance6")
    Turn(tlHead, x_axis, math.rad(-29), 3)
    Turn(tlHead, x_axis, math.rad(29), 3)

    --wait &sleep
    Sleep(150)
    Move(tigLil, y_axis, -8, 12)


    Turn(tlHead, x_axis, math.rad(0), 3)
    Turn(tlhairup, x_axis, math.rad(-77), 4)
    Turn(tlarm, x_axis, math.rad(-27), 3)
    Turn(tlarm, y_axis, math.rad(-12), 3)
    Turn(tlarm, z_axis, math.rad(72), 3)

    Turn(tlarmr, x_axis, math.rad(-12), 3)
    Turn(tlarmr, y_axis, math.rad(104), 3)
    Turn(tlarmr, z_axis, math.rad(-107), 3)


    Turn(tllegUp, x_axis, math.rad(-63), 4)
    Turn(tllegUp, y_axis, math.rad(-14), 4)
    Turn(tllegLow, x_axis, math.rad(147), 6)

    Turn(tllegUpR, x_axis, math.rad(291), 4)
    Turn(tllegUpR, y_axis, math.rad(10), 4)
    Turn(tllegLowR, x_axis, math.rad(147), 6)

    WaitForTurn(tlHead, x_axis)

    Sleep(2048)
    --wait &sleep
    WaitForMove(tigLil, y_axis)



    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)


    Sleep(550)
    --jumpstage

    flipFlop = math.random(0, 1)
    if flipFlop == 1 then
        Spin(tigLil, y_axis, math.rad(360))


        Move(tigLil, y_axis, 7, 74)
        Move(tigLil, y_axis, 11, 64)
        Sleep(50)

        --Turn(deathpivot,y_axis,math.rad(179),8)
        Move(tigLil, y_axis, 17, 54)
        WaitForMove(tigLil, y_axis)

        Turn(tlHead, x_axis, math.rad(10), 3)

        --Turn(deathpivot,y_axis,math.rad(269),2)
        --Turn(deathpivot,y_axis,math.rad(360),4)

        Turn(tlarm, x_axis, math.rad(0), 6)
        Turn(tlarm, y_axis, math.rad(0), 6)
        Turn(tlarm, z_axis, math.rad(-98), 7)


        Turn(tlarmr, x_axis, math.rad(0), 6)
        Turn(tlarmr, y_axis, math.rad(0), 6)
        Turn(tlarmr, z_axis, math.rad(98), 7)


        Turn(tllegUp, x_axis, math.rad(-17), 7)
        Turn(tllegUp, y_axis, math.rad(-90), 7)
        Turn(tllegLow, x_axis, math.rad(41), 9)

        Turn(tllegUpR, x_axis, math.rad(-17), 7)
        Turn(tllegUpR, y_axis, math.rad(75), 7)
        Turn(tllegLowR, x_axis, math.rad(41), 9)

        --wait&sleep
    WaitForTurns(tigLil)
    WaitForTurns(tlHead)
    WaitForTurns(tlarm)
    WaitForTurns(tlarmr)
    WaitForTurns(tllegUp)
    WaitForTurns(tllegLow)
    WaitForTurns(tllegUpR)
    WaitForTurns(tllegLowR)
    WaitForTurns(tlhairup)
    WaitForTurns(tlhairdown)


        WaitForMove(tigLil, y_axis)


        Move(tigLil, y_axis, 11, 54)
        Move(tigLil, y_axis, 7, 64)
        Move(tigLil, y_axis, 0, 74)
        StopSpin(tigLil, y_axis)
        WaitForTurn(tigLil, y_axis)
        Turn(tlhairup, x_axis, math.rad(63), 28)
        WaitForMove(tigLil, y_axis)
        WaitForTurn(tlhairup, x_axis)
        Turn(tlHead, x_axis, math.rad(0), 3)
        Turn(tlhairup, x_axis, math.rad(0), 4)
        Turn(tlarm, x_axis, math.rad(0), 3)
        Turn(tlarm, y_axis, math.rad(0), 3)
        Turn(tlarm, z_axis, math.rad(0), 3)


        Turn(tlarmr, x_axis, math.rad(0), 3)
        Turn(tlarmr, y_axis, math.rad(0), 3)
        Turn(tlarmr, z_axis, math.rad(0), 3)


        Turn(tllegUp, x_axis, math.rad(0), 3)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(0), 3)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 3)



        WaitForTurn(tlHead, x_axis)

        WaitForTurn(tlarm, x_axis)
        WaitForTurn(tlarm, y_axis)
        WaitForTurn(tlarm, z_axis)

        WaitForTurn(tlarmr, x_axis)
        WaitForTurn(tlarmr, y_axis)
        WaitForTurn(tlarmr, z_axis)


        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegLow, x_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegLowR, x_axis)
        Turn(tigLil, y_axis, math.rad(0), 360)



        WaitForTurn(tlhairup, x_axis)

        WaitForMove(tigLil, y_axis)
        Sleep(350)
    end

    if flipFlop == 0 then
        Sleep(512)
        Move(tigLil, y_axis, -10, 12)
        Turn(tigLil, x_axis, math.rad(-4), 2)
        Turn(tigLil, y_axis, math.rad(0), 2)
        Turn(tigLil, z_axis, math.rad(0), 2)

        Turn(tlHead, x_axis, math.rad(0), 3)
        Turn(tlHead, y_axis, math.rad(0), 3)
        Turn(tlHead, z_axis, math.rad(0), 3)

        Turn(tlhairup, x_axis, math.rad(-74), 4)
        Turn(tlhairup, y_axis, math.rad(0), 4)
        Turn(tlhairup, z_axis, math.rad(0), 4)


        Turn(tlarm, x_axis, math.rad(-5), 3)
        Turn(tlarm, y_axis, math.rad(-39), 3)
        Turn(tlarm, z_axis, math.rad(-33), 3)

        Turn(tlarmr, x_axis, math.rad(0), 3)
        Turn(tlarmr, y_axis, math.rad(24), 3)
        Turn(tlarmr, z_axis, math.rad(-33), 3)


        Turn(tllegUp, x_axis, math.rad(0), 4)
        Turn(tllegUp, y_axis, math.rad(230), 22)
        Turn(tllegUp, z_axis, math.rad(90), 4)
        Turn(tllegLow, x_axis, math.rad(152), 6)

        Turn(tllegUpR, x_axis, math.rad(0), 4)
        Turn(tllegUpR, y_axis, math.rad(119), 4)
        Turn(tllegUpR, z_axis, math.rad(-90), 4)
        Turn(tllegLowR, x_axis, math.rad(148), 6)

        Sleep(440)

        Turn(tlarm, x_axis, math.rad(0), 3)
        Turn(tlarm, y_axis, math.rad(57), 3)
        Turn(tlarm, z_axis, math.rad(22), 3)

        Sleep(50)

        Turn(tlHead, x_axis, math.rad(16), 3)
        Turn(tlHead, y_axis, math.rad(54), 3)
        Turn(tlHead, z_axis, math.rad(0), 3)

        Turn(tlhairup, x_axis, math.rad(-38), 4)
        Turn(tlhairup, y_axis, math.rad(57), 4)
        Turn(tlhairup, z_axis, math.rad(90), 4)

        Sleep(150)

        Turn(tlHead, x_axis, math.rad(16), 3)
        Turn(tlHead, y_axis, math.rad(-54), 3)
        Turn(tlHead, z_axis, math.rad(6), 3)

        Turn(tlhairup, x_axis, math.rad(-21), 5)
        Turn(tlhairup, y_axis, math.rad(57), 5)
        Turn(tlhairup, z_axis, math.rad(-90), 5)

        Turn(tlhairdown, x_axis, math.rad(17), 8)
        Sleep(125)

        Turn(tlHead, x_axis, math.rad(16), 6)
        Turn(tlHead, y_axis, math.rad(54), 6)
        Turn(tlHead, z_axis, math.rad(0), 5)

        Turn(tlhairup, x_axis, math.rad(-38), 7)
        Turn(tlhairup, y_axis, math.rad(57), 7)
        Turn(tlhairup, z_axis, math.rad(90), 7)

        --ixxed
        --HairInFront
        Turn(tlHead, x_axis, math.rad(11), 6)
        Turn(tlHead, y_axis, math.rad(-32), 6)
        Turn(tlHead, z_axis, math.rad(0), 6)

        Turn(tlhairup, x_axis, math.rad(3), 8)
        Turn(tlhairup, y_axis, math.rad(-53), 8)
        Turn(tlhairup, z_axis, math.rad(79), 8)

        Turn(tlhairdown, x_axis, math.rad(24), 8)
        Sleep(60)

        Turn(tlhairup, x_axis, math.rad(-21), 4)
        Turn(tlhairup, y_axis, math.rad(-125), 4)
        Turn(tlhairup, z_axis, math.rad(151), 4)
        Turn(tlarmr, y_axis, math.rad(-55), 9)
        Turn(tlarmr, z_axis, math.rad(-29), 9)
        Turn(tlhairdown, x_axis, math.rad(24), 8)

        Sleep(256)
        Turn(tlarm, x_axis, math.rad(-84), 3)
        Turn(tlarm, y_axis, math.rad(57), 3)
        Turn(tlarm, z_axis, math.rad(22), 4)
        Sleep(256)
        Turn(tlarm, x_axis, math.rad(-125), 3)
        Turn(tlarm, y_axis, math.rad(122), 3)
        Turn(tlarm, z_axis, math.rad(10), 4)

        randItterator = math.random(6, 16)
        for i = 1, randItterator, 1 do
            Sleep(256)
            Turn(tlarm, x_axis, math.rad(-147), 0.5)
            Turn(tlarm, y_axis, math.rad(152), 0.5)
            Turn(tlarm, z_axis, math.rad(19), 0.5)

            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)
            Turn(tlarm, x_axis, math.rad(-147), 0.25)
            Turn(tlarm, y_axis, math.rad(155), 0.25)
            Turn(tlarm, z_axis, math.rad(5), 0.25)
            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)
            Turn(tlarm, x_axis, math.rad(-147), 0.125)
            Turn(tlarm, y_axis, math.rad(158), 0.125)
            Turn(tlarm, z_axis, math.rad(-8), 0.125)
            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)
        end
    end
    legs_down()
    Move(tigLil, y_axis, 0, 12)
    Sleep(2048)

    rand = math.random(0, 1)
    if rand == 1 then
        --levitate
        --FixMe : HairShouldFloat
        Move(tigLil, y_axis, -10, 12)
        Turn(tigLil, x_axis, math.rad(-4), 2)
        Turn(tigLil, y_axis, math.rad(0), 2)
        Turn(tigLil, z_axis, math.rad(0), 2)

        Turn(tlHead, x_axis, math.rad(0), 3)
        Turn(tlHead, y_axis, math.rad(0), 3)
        Turn(tlHead, z_axis, math.rad(0), 3)

        Turn(tlhairup, x_axis, math.rad(-74), 4)
        Turn(tlhairup, y_axis, math.rad(0), 4)
        Turn(tlhairup, z_axis, math.rad(0), 4)


        Turn(tlarm, x_axis, math.rad(0), 3)
        Turn(tlarm, y_axis, math.rad(43), 3)
        Turn(tlarm, z_axis, math.rad(22), 3)

        Turn(tlarmr, x_axis, math.rad(-4), 3)
        Turn(tlarmr, y_axis, math.rad(-44), 3)
        Turn(tlarmr, z_axis, math.rad(-15), 3)


        Turn(tllegUp, x_axis, math.rad(0), 4)
        Turn(tllegUp, y_axis, math.rad(230), 22)
        Turn(tllegUp, z_axis, math.rad(90), 4)
        Turn(tllegLow, x_axis, math.rad(152), 6)

        Turn(tllegUpR, x_axis, math.rad(0), 4)
        Turn(tllegUpR, y_axis, math.rad(119), 4)
        Turn(tllegUpR, z_axis, math.rad(-90), 4)
        Turn(tllegLowR, x_axis, math.rad(148), 6)


        for i = 0, 25, 1 do
            Turn(tlarm, x_axis, math.rad(24), 1)
            Turn(tlarmr, x_axis, math.rad(24), 1)
            Sleep(620)
            Turn(tlarm, x_axis, math.rad(-4), 1)
            Turn(tlarmr, x_axis, math.rad(-4), 1)
            Sleep(620)
        end
        Move(tigLil, y_axis, -9, 0.5)
        Sleep(150)
        Move(tigLil, y_axis, -10, 0.5)
        Sleep(320)
        Move(tigLil, y_axis, -5, 0.25)

        howLong = math.random(12, 24)
        for i = 0, howLong, 1 do
            Turn(tlarm, x_axis, math.rad(24), 1)
            Turn(tlarmr, x_axis, math.rad(24), 1)
            Sleep(420)
            Turn(tlarm, x_axis, math.rad(-4), 1)
            Turn(tlarmr, x_axis, math.rad(-4), 1)
            Sleep(420)
        end

        randSleep = math.random(512, 4096)
        rand = math.random(0, 1)
        WaitForMove(tigLil, y_axis)
        if rand == 0 then
            Move(tigLil, y_axis, 5, 0.5)
            Turn(tllegUp, x_axis, math.rad(0), 0.25)
            Turn(tllegUp, y_axis, math.rad(0), 0.25)
            Turn(tllegUp, z_axis, math.rad(0), 0.25)
            Turn(tllegLow, x_axis, math.rad(0), 0.25)

            Turn(tllegUpR, x_axis, math.rad(0), 0.25)
            Turn(tllegUpR, y_axis, math.rad(0), 0.25)
            Turn(tllegUpR, z_axis, math.rad(0), 0.25)
            Turn(tllegLowR, x_axis, math.rad(0), 0.25)
            Sleep(700)
            WaitForMove(tigLil, y_axis)
            -- random float in space

            tumbleWeed = math.random(7, 14)

            spinX = math.random(10, 60)
            spinY = math.random(10, 80)
            spinZ = math.random(30, 70)
            rondo = math.random(0, 2)




            if rondo == 0 then
                spinY = 0
                spinZ = spinZ / spinX
            end
            if rondo == 1 then
                spinX = spinX / spinY
                spinZ = 0
            end
            if rondo == 2 then
                spinY = spinY / spinZ
                spinX = 0
            end

            boolAllreadyActive = false
            temp = 12
            boolInPosition = false
            for at = 0, tumbleWeed, 1 do
                Move(tigLil, y_axis, temp, 0.5)
                --Team 4 Place Levitation SubScript here

                if boolAllreadyActive == false then
                    ------ Spring.Echo("Should work!0")
                    boolAllreadActive = true

                    if rondo == 0 then

                        Spin(tigLil, x_axis, math.rad(spinX), 0.25)

                        Spin(tigLil, z_axis, math.rad(spinZ), 0.45)
                    end
                    if rondo == 1 then
                        Spin(tigLil, x_axis, math.rad(spinX), 0.25)
                        Spin(tigLil, y_axis, math.rad(spinY), 0.35)
                    end
                    if rondo == 2 then
                        Spin(tigLil, y_axis, math.rad(spinY), 0.35)
                        Spin(tigLil, z_axis, math.rad(spinZ), 0.45)
                    end
                end



                if boolInPosition == false then
                    ------ Spring.Echo("HappyTrigger is Triggerhappy!")
                    Turn(tlHead, x_axis, math.rad(83), 4)


                    Turn(tlarm, y_axis, math.rad(79), 4)

                    Turn(tlarm, x_axis, math.rad(79), 1)
                    Turn(tlarm, z_axis, math.rad(-6), 1)


                    Turn(tlarmr, y_axis, math.rad(-102), 3)
                    Turn(tlarmr, x_axis, math.rad(-97), 3)
                    Turn(tlarmr, z_axis, math.rad(-12), 3)

                    Turn(tllegUp, x_axis, math.rad(-137), 3)
                    --i
                    Turn(tllegUp, z_axis, math.rad(5), 1)
                    Turn(tllegLow, x_axis, math.rad(155), 1)
                    --i
                    Turn(tllegLow, z_axis, math.rad(15), 2)

                    Turn(tllegUpR, x_axis, math.rad(-135), 4)
                    --i
                    Turn(tllegUpR, y_axis, math.rad(10), 2)
                    --i
                    Turn(tllegUpR, z_axis, math.rad(-13), 2)
                    Turn(tllegLowR, x_axis, math.rad(135), 1)
                    Turn(tllegLowR, y_axis, math.rad(0), 1)
                    Turn(tllegLowR, z_axis, math.rad(0), 1)
                    WaitForTurns(tigLil)
                    WaitForTurns(tlHead)
                    WaitForTurns(tlarm)
                    WaitForTurns(tlarmr)
                    WaitForTurns(tllegUp)
                    WaitForTurns(tllegLow)
                    WaitForTurns(tllegUpR)
                    WaitForTurns(tllegLowR)
                    WaitForTurns(tlhairup)
                    WaitForTurns(tlhairdown)
                    boolinPosition = true
                end

                WaitForMove(tigLil, y_axis)
                Sleep(1024)

                if temp < 32 then
                    temp = temp + 3
                end
                ------ Spring.Echo("Should work!2")
            end
            ------ Spring.Echo("Should work!3")
            if rondo == 0 then

                StopSpin(tigLil, x_axis)

                StopSpin(tigLil, z_axis)
            end
            if rondo == 1 then
                StopSpin(tigLil, x_axis)
                StopSpin(tigLil, y_axis)
            end
            if rondo == 2 then
                StopSpin(tigLil, y_axis)
                StopSpin(tigLil, z_axis)
            end
        end



        Sleep(randSleep)
        temp = 13
        --HeadShake
        if boolInPosition == true then
            Move(tigLil, y_axis, temp, 2)
            for i = 0, 4, 1 do

                Turn(tlHead, y_axis, math.rad(30), 13)
                Sleep(210)

                WaitForMove(tigLil, y_axis)
                Turn(tlHead, y_axis, math.rad(-30), 13)
                Sleep(210)
            end
            WaitForMove(tigLil, y_axis)
        end
        if boolInPosition == false then
            Move(tigLil, y_axis, 0, 18)


            --landing
            Turn(tlhairdown, x_axis, math.rad(0), 14)
            Turn(tigLil, x_axis, math.rad(40), 14)
            Turn(tigLil, y_axis, math.rad(0), 14)
            Turn(tigLil, z_axis, math.rad(0), 14)
            Turn(tlhairup, x_axis, math.rad(73), 14)
            Turn(tlHead, y_axis, math.rad(42), 14)
            Turn(tlHead, x_axis, math.rad(0), 14)
            Turn(tlHead, z_axis, math.rad(0), 14)
            Turn(tlarm, x_axis, math.rad(0), 7)
            Turn(tlarm, y_axis, math.rad(0), 7)
            Turn(tlarm, z_axis, math.rad(0), 7)
            Turn(tlarmr, x_axis, math.rad(0), 7)
            Turn(tlarmr, y_axis, math.rad(42), 7)
            Turn(tlarmr, z_axis, math.rad(0), 7)
            Turn(tllegLow, x_axis, math.rad(0), 9)
            Turn(tllegLow, z_axis, math.rad(0), 12)
            Turn(tllegLowR, x_axis, math.rad(0), 12)
            Turn(tlhairdown, x_axis, math.rad(18), 14)
            Turn(tllegUp, x_axis, math.rad(-37), 12)
            Turn(tllegUp, y_axis, math.rad(19), 12)
            Turn(tllegUp, z_axis, math.rad(0), 12)
            Turn(tllegUpR, x_axis, math.rad(-39), 12)
            Turn(tllegUpR, y_axis, math.rad(-14), 12)
            Turn(tllegUpR, z_axis, math.rad(0), 12)
            Turn(tlhairup, x_axis, math.rad(18), 14)
            WaitForMove(tigLil, y_axis)



            Turn(tllegUp, x_axis, math.rad(-6), 12)
            Turn(tllegUp, y_axis, math.rad(-37), 12)
            Turn(tllegUp, z_axis, math.rad(0), 12)
            Turn(tllegLow, x_axis, math.rad(24), 9)
            Turn(tllegLow, z_axis, math.rad(-5), 12)

            Turn(tllegUpR, x_axis, math.rad(-119), 12)
            Turn(tllegUpR, y_axis, math.rad(-11), 12)
            Turn(tllegUpR, z_axis, math.rad(0), 12)
            Turn(tllegLowR, x_axis, math.rad(78), 12)
            Move(tigLil, y_axis, -5, 12)
            WaitForMove(tigLil, y_axis)
            Sleep(160)
            Move(tigLil, y_axis, -7, 3)
            Turn(tigLil, x_axis, math.rad(50), 14)
            Turn(tigLil, y_axis, math.rad(5), 14)
            Turn(tigLil, z_axis, math.rad(0), 14)
            Turn(tlhairup, x_axis, math.rad(-90), 14)
            Turn(tlHead, y_axis, math.rad(6), 14)
            Turn(tlHead, x_axis, math.rad(0), 14)
            Turn(tlHead, z_axis, math.rad(0), 14)
            Turn(tlarm, x_axis, math.rad(0), 7)
            Turn(tlarm, y_axis, math.rad(27), 7)
            Turn(tlarm, z_axis, math.rad(0), 7)
            Turn(tlarmr, x_axis, math.rad(-40), 7)
            Turn(tlarmr, y_axis, math.rad(0), 7)
            Turn(tlarmr, z_axis, math.rad(-32), 7)
            Turn(tllegUp, x_axis, math.rad(6), 12)
            Turn(tllegUp, y_axis, math.rad(-37), 12)
            Turn(tllegUp, z_axis, math.rad(0), 12)
            Turn(tllegLow, x_axis, math.rad(16), 9)

            Turn(tllegUpR, x_axis, math.rad(-126), 12)
            Turn(tllegUpR, y_axis, math.rad(-11), 12)
            Turn(tllegUpR, z_axis, math.rad(0), 12)
            Turn(tllegLowR, x_axis, math.rad(109), 12)
            WaitForMove(tigLil, y_axis)
            Sleep(300)
            Move(tigLil, y_axis, -5, 12)
            Turn(tigLil, x_axis, math.rad(40), 14)
            Turn(tigLil, y_axis, math.rad(0), 14)
            Turn(tigLil, z_axis, math.rad(0), 14)
            Turn(tllegUp, x_axis, math.rad(-6), 12)
            Turn(tllegUp, y_axis, math.rad(-37), 12)
            Turn(tllegUp, z_axis, math.rad(0), 12)
            Turn(tllegLow, x_axis, math.rad(24), 9)
            Turn(tllegLow, z_axis, math.rad(-5), 12)

            Turn(tllegUpR, x_axis, math.rad(-119), 12)
            Turn(tllegUpR, y_axis, math.rad(-11), 12)
            Turn(tllegUpR, z_axis, math.rad(0), 12)
            Turn(tllegLowR, x_axis, math.rad(78), 12)
            Turn(tlHead, y_axis, math.rad(42), 14)
            Turn(tlHead, x_axis, math.rad(0), 14)
            Turn(tlHead, z_axis, math.rad(0), 14)
            Turn(tlarm, x_axis, math.rad(0), 7)
            Turn(tlarm, y_axis, math.rad(0), 7)
            Turn(tlarm, z_axis, math.rad(0), 7)
            Turn(tlarmr, x_axis, math.rad(0), 7)
            Turn(tlarmr, y_axis, math.rad(42), 7)
            Turn(tlarmr, z_axis, math.rad(0), 7)
            Sleep(2048)
            --abfedern
        end
        legs_down()
        Sleep(279)
    end
end

--rest&sleep
function idle_stance7()
    --echo("idle_stance7")


    --SitUp Position Legs Sidewayfold

    Move(tigLil, y_axis, -1, 4)
    WaitForMove(tigLil, y_axis)

    Turn(tlhairup, x_axis, math.rad(29), 3)
    Turn(tlarm, y_axis, math.rad(-12), 3)
    Turn(tlarmr, y_axis, math.rad(38), 3)
    Turn(tllegUp, x_axis, math.rad(-4), 3)
    Turn(tllegUp, y_axis, math.rad(-59), 3)
    Turn(tllegLow, x_axis, math.rad(35), 3)
    Turn(tllegUpR, x_axis, math.rad(-20), 3)
    Turn(tllegUpR, y_axis, math.rad(-44), 3)

    Turn(tllegLowR, x_axis, math.rad(31), 3)



    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)

    WaitForTurn(tllegLowR, x_axis)
    Sleep(256)

    --Watch over Knee
    randOMatic = math.random(0, 1)
    if randOMatic == 0 then
        --workOver
        --lean back & relex
        Move(tigLil, y_axis, -10, 13.5)
        Turn(tigLil, x_axis, math.rad(-34), 4)
        Turn(tlHead, x_axis, math.rad(-14), 3)

        Turn(tlarm, x_axis, math.rad(0), 6)
        Turn(tlarm, y_axis, math.rad(-58), 6)
        Turn(tlarm, z_axis, math.rad(31), 3)
        Turn(tlarmr, x_axis, math.rad(0), 6)
        Turn(tlarmr, y_axis, math.rad(77), 6)
        Turn(tlarmr, z_axis, math.rad(-23), 3)



        Turn(tlhairup, x_axis, math.rad(-38), 4)
        Turn(tlhairup, y_axis, math.rad(0), 3)
        Turn(tlhairup, z_axis, math.rad(0), 3)
        Turn(tlhairdown, x_axis, math.rad(26), 4)

        Turn(tllegUp, x_axis, math.rad(-90), 6)
        Turn(tllegUp, y_axis, math.rad(-15), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(90), 6)
        Turn(tllegLow, y_axis, math.rad(12), 3)

        Turn(tllegUpR, x_axis, math.rad(-90), 6)
        Turn(tllegUpR, y_axis, math.rad(15), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)

        Turn(tllegLowR, x_axis, math.rad(90), 6)
        Turn(tllegLowR, y_axis, math.rad(-8), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Sleep(12000)
    end
    legs_down()


    if randOMatic == 1 then
        Move(tigLil, y_axis, -6, 5)

        Turn(tigLil, x_axis, math.rad(8), 3)
        Turn(tigLil, y_axis, math.rad(-2), 3)
        Turn(tlhairup, x_axis, math.rad(-77), 3)

        Turn(tlarm, x_axis, math.rad(-151), 5)
        Turn(tlarm, y_axis, math.rad(92), 4)
        Turn(tlarm, z_axis, math.rad(-31), 3)

        Turn(tlarmr, x_axis, math.rad(188), 5)
        Turn(tlarmr, y_axis, math.rad(-83), 3)
        Turn(tlarmr, z_axis, math.rad(14), 3)

        Turn(tllegUp, x_axis, math.rad(-120), 5)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(60), 3)

        Turn(tllegUpR, x_axis, math.rad(-117), 3)
        Turn(tllegUpR, y_axis, math.rad(0), 3)

        Move(tigLil, y_axis, -10, 14)
        WaitForMove(tigLil, y_axis)
        WaitForTurn(tigLil, x_axis)
        WaitForTurn(tigLil, y_axis)
        Turn(tllegLowR, x_axis, math.rad(55), 4)
        WaitForTurn(tlhairup, x_axis)
        WaitForTurn(tlarm, x_axis)
        WaitForTurn(tlarm, y_axis)
        WaitForTurn(tlarm, z_axis)

        WaitForTurn(tlarmr, x_axis)
        WaitForTurn(tlarmr, y_axis)
        WaitForTurn(tlarmr, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegLow, x_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)

        WaitForTurn(tllegLowR, x_axis)


        Sleep(4096)

        flipFlop = math.random(0, 1)
        if flipFlop == 1 then

            Turn(tlarmr, x_axis, math.rad(-180), 3)
            Turn(tlarmr, y_axis, math.rad(-76), 3)
            Turn(tlarmr, z_axis, math.rad(102), 3)

            Turn(tlarm, x_axis, math.rad(0), 3)
            Turn(tlarm, y_axis, math.rad(-8), 3)
            Turn(tlarm, z_axis, math.rad(0), 3)

            Sleep(512)
            --LayDown


            Move(tigLil, y_axis, -11, 4)
            WaitForMove(tigLil, y_axis)
            Turn(tigLil, x_axis, math.rad(-98), 3)
            Turn(tigLil, y_axis, math.rad(0), 3)
            Turn(tigLil, z_axis, math.rad(0), 3)


            Turn(tlHead, x_axis, math.rad(40), 3)
            Turn(tlHead, y_axis, math.rad(30), 3)
            Turn(tlarmr, x_axis, math.rad(0), 3)
            Turn(tlarmr, y_axis, math.rad(0), 3)
            Turn(tlarmr, z_axis, math.rad(0), 3)
            Sleep(75)
            Turn(tlarmr, x_axis, math.rad(-2), 3)
            Turn(tlarmr, y_axis, math.rad(52), 3)
            Turn(tlarmr, z_axis, math.rad(90), 3)

            Turn(tlhairup, x_axis, math.rad(-8), 3)
            Turn(tlhairup, y_axis, math.rad(55), 3)
            Turn(tlhairup, z_axis, math.rad(-90), 3)

            Turn(tllegUp, x_axis, math.rad(-15), 3)
            Turn(tllegUp, y_axis, math.rad(0), 3)
            Turn(tllegUp, z_axis, math.rad(0), 3)
            Turn(tllegLow, x_axis, math.rad(60), 3)

            Turn(tllegUpR, x_axis, math.rad(9), 3)
            Turn(tllegUpR, y_axis, math.rad(0), 3)
            Turn(tllegUpR, z_axis, math.rad(0), 3)

            Turn(tllegLowR, x_axis, math.rad(0), 3)
            Turn(tllegLowR, x_axis, math.rad(0), 3)
            Turn(tllegLowR, x_axis, math.rad(0), 3)
            WaitForTurns(tigLil)
            WaitForTurns(tlHead)
            WaitForTurns(tlarm)
            WaitForTurns(tlarmr)
            WaitForTurns(tllegUp)
            WaitForTurns(tllegLow)
            WaitForTurns(tllegUpR)
            WaitForTurns(tllegLowR)
            WaitForTurns(tlhairup)
            WaitForTurns(tlhairdown)
            Sleep(50)
            Sleep(8096)

            Move(tigLil, y_axis, 0, 25)
            Turn(tigLil, x_axis, math.rad(0), 3)
            Turn(tigLil, y_axis, math.rad(0), 3)
            WaitForMove(tigLil, y_axis)
            WaitForTurn(tigLil, x_axis)
            WaitForTurn(tigLil, y_axis)
        end

        if flipFlop == 0 then


            Move(tlHead, z_axis, -0.826, 1)
            Move(tigLil, y_axis, -11, 5)
            Turn(tigLil, x_axis, math.rad(75), 6)
            Turn(tigLil, y_axis, math.rad(180), 8)
            Turn(tlHead, x_axis, math.rad(-50), 3)
            Turn(tlHead, y_axis, math.rad(0), 3)

            Turn(tlarm, x_axis, math.rad(-35), 3)
            Turn(tlarm, y_axis, math.rad(180), 8)
            Turn(tlarm, z_axis, math.rad(-43), 3)

            Turn(tlarmr, x_axis, math.rad(-1), 3)
            Turn(tlarmr, y_axis, math.rad(199), 7)
            Turn(tlarmr, z_axis, math.rad(32), 3)

            Turn(tlhairup, x_axis, math.rad(-40), 3)
            Turn(tlhairup, y_axis, math.rad(-7), 3)
            Turn(tlhairup, z_axis, math.rad(0), 3)
            Turn(tlhairdown, x_axis, math.rad(8), 3)
            Turn(tllegUp, x_axis, math.rad(0), 5)
            Turn(tllegUp, y_axis, math.rad(0), 5)
            Turn(tllegUp, z_axis, math.rad(0), 5)
            Turn(tllegUpR, x_axis, math.rad(0), 5)
            Turn(tllegUpR, y_axis, math.rad(0), 5)
            Turn(tllegUpR, z_axis, math.rad(0), 5)
            WaitForTurn(tigLil, x_axis)
            WaitForTurn(tigLil, y_axis)
            WaitForTurn(tlHead, x_axis)
            WaitForTurn(tlHead, y_axis)

            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)

            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)

            WaitForTurn(tlhairup, x_axis)
            WaitForTurn(tlhairup, y_axis)
            WaitForTurn(tlhairup, z_axis)




            tempItMax = math.random(7, 12)
            for it = 0, tempItMax, 1 do
                hipHop = math.random(0, 1)
                if hipHop == 1 then
                    Turn(tllegLowR, x_axis, math.rad(12), 3)
                    WaitForTurn(tllegLowR, x_axis)
                    sheGotLeg = math.random(15, 138)
                    Sleep(512)
                    Turn(tllegLow, x_axis, math.rad(sheGotLeg), 3)
                    WaitForTurn(tllegLow, x_axis)
                    randBreak = math.random(512, 1024)
                    Sleep(randBreak)
                end
                if hipHop == 0 then
                    Turn(tllegLow, x_axis, math.rad(12), 3)
                    WaitForTurn(tllegLow, x_axis)
                    sheGotLeg = math.random(15, 138)
                    Sleep(512)
                    Turn(tllegLowR, x_axis, math.rad(sheGotLeg), 3)
                    WaitForTurn(tllegLowR, x_axis)
                    randBreak = math.random(512, 1024)
                    Sleep(randBreak)
                end
            end
        end
        Move(tlHead, z_axis, 0, 1)
        Sleep(550)
    end

    BitchSleep = math.random(1024, 8000)
    Sleep(BitchSleep)
    BitchSleep = BitchSleep % 2
    if BitchSleep == 1 then
        randDuration = math.random(1, 3)
        for i = 0, randDuration, 1 do
            --swoard kata

            -- aufwaermuebungen


            --sowardkicks


            --spreadPose (Karatekid)





            --swoardspin in four directions, always going faster




            --fanal


            --standing
        end
        legs_down()
    end
end

function idle_stance8()
    --echo("idle_stance8")
    spagat()
    legs_down()
    tempThrower = math.random(1, 7)
    Turn(tlarm, x_axis, math.rad(-7), 3)
    Turn(tlarm, y_axis, math.rad(-138), 2)
    Turn(tlarm, z_axis, math.rad(52), 2)
    ShowReg(tldrum)
    Sleep(50)
    WaitForTurn(tlarm, z_axis)
    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(0), 3)
    Turn(tlarm, z_axis, math.rad(0), 4)
    WaitForTurn(tlarm, y_axis)

    for i = 1, tempThrower, 1 do
        Turn(tlarm, x_axis, math.rad(-180), 3)
        Turn(tlarm, y_axis, math.rad(90), 6)
        Turn(tlarm, z_axis, math.rad(0), 4)

        Turn(tlarmr, x_axis, math.rad(0), 3)
        Turn(tlarmr, y_axis, math.rad(103), 6)
        Turn(tlarmr, z_axis, math.rad(-44), 4)

        WaitForTurn(tlarm, x_axis)
        Turn(tlarm, z_axis, math.rad(-52), 5)
        WaitForTurn(tlarm, z_axis)
        Turn(tlarm, x_axis, math.rad(-180), 8)
        Turn(tlarm, y_axis, math.rad(90), 8)
        Turn(tlarm, z_axis, math.rad(0), 8)
        WaitForTurn(tlarm, z_axis)
        Turn(tlhairup, x_axis, math.rad(-17), 4)

        Turn(tlHead, x_axis, math.rad(-42), 1)
        Move(tldrum, y_axis, -26, 27)
        WaitForMove(tldrum, y_axis)
        Move(tldrum, y_axis, -30, 22)
        WaitForMove(tldrum, y_axis)
        Move(tldrum, y_axis, -36, 12)

        WaitForMove(tldrum, y_axis)
        Turn(tlHead, x_axis, math.rad(0), 2)
        Turn(tlhairup, x_axis, math.rad(-74), 5)
        Move(tldrum, y_axis, -30, 15)
        Move(tldrum, y_axis, -26, 27)
        WaitForMove(tldrum, y_axis)
        Move(tldrum, y_axis, -0.2, 37)
        WaitForMove(tldrum, y_axis)
        Turn(tlarm, z_axis, math.rad(-68), 5)
        WaitForTurn(tlarm, z_axis)
    end


    Sleep(150)
    Turn(tlarm, x_axis, math.rad(0), 3)
    Turn(tlarm, y_axis, math.rad(0), 2)
    Turn(tlarm, z_axis, math.rad(0), 3)
    WaitForTurn(tlarm, y_axis)
    Turn(tlarm, x_axis, math.rad(-187), 3)

    Turn(tlarm, y_axis, math.rad(-138), 2)
    Turn(tlarm, z_axis, math.rad(-52), 3)
    HideReg(tldrum)
end

--clapstance
function idle_stance9()
    --echo("idle_stance9")
    --Clap

    Turn(tigLil, x_axis, math.rad(-16), 3)
    Turn(tlHead, x_axis, math.rad(16), 3)
    Turn(tlhairup, x_axis, math.rad(-71), 3)
    Turn(tlhairdown, x_axis, math.rad(-27), 3)
    Turn(tlarm, x_axis, math.rad(-124), 3)
    Turn(tlarmr, x_axis, math.rad(-124), 3)
    Turn(tllegUp, x_axis, math.rad(26), 3)
    Turn(tllegLow, x_axis, math.rad(-10), 3)
    Turn(tllegUpR, x_axis, math.rad(14), 3)
    WaitForTurn(tigLil, x_axis)
    WaitForTurn(tlHead, x_axis)
    WaitForTurn(tlhairup, x_axis)
    WaitForTurn(tlhairdown, x_axis)
    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegUpR, x_axis)

    Sleep(150)
    tempclap = math.random(3, 12)
    --random number of handclaps
    decider = math.random(0, 1)
    if (decider == 0) then

        for itterator = 1, tempclap, 1 do

            --Hand Standyposition

            Turn(tlarmr, x_axis, math.rad(16), 3)
            Turn(tlarmr, y_axis, math.rad(-32), 3)
            Turn(tlarmr, z_axis, math.rad(88), 3)


            Turn(tlarm, x_axis, math.rad(188), 3)
            Turn(tlarm, y_axis, math.rad(63), 3)
            Turn(tlarm, z_axis, math.rad(58), 3)

            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)


            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)




            -- Hands together

            aynRandOM = math.random(28, 38)
            Turn(tlHead, x_axis, math.rad(aynRandOM), 3)
            Turn(tlhairdown, x_axis, math.rad(-98), 3)
            Turn(tlhairdown, x_axis, math.rad(-1), 3)

            Turn(tlarmr, x_axis, math.rad(16), 3)
            Turn(tlarmr, y_axis, math.rad(15), 3) --i
            Turn(tlarmr, z_axis, math.rad(114), 3) --i


            Turn(tlarm, x_axis, math.rad(154), 3)
            Turn(tlarm, y_axis, math.rad(180), 3)
            Turn(tlarm, z_axis, math.rad(75), 3) --i

            WaitForTurn(tlHead, x_axis)
            WaitForTurn(tlhairdown, x_axis)
            WaitForTurn(tlhairdown, x_axis)

            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)


            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)
            Sleep(40)

            --Hand Standyposition

            Turn(tlarmr, x_axis, math.rad(16), 3)
            Turn(tlarmr, y_axis, math.rad(-32), 3)
            Turn(tlarmr, z_axis, math.rad(88), 3)


            Turn(tlarm, x_axis, math.rad(188), 3)
            Turn(tlarm, y_axis, math.rad(63), 3)
            Turn(tlarm, z_axis, math.rad(58), 3)

            aynRandOM = math.random(12, 20)
            Turn(tlHead, x_axis, math.rad(aynRandOM), 3)
            Turn(tlhairup, x_axis, math.rad(-71), 3)
            Turn(tlhairdown, x_axis, math.rad(-27), 3)

            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)


            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)


            WaitForTurn(tlHead, x_axis)
            WaitForTurn(tlhairup, x_axis)
            WaitForTurn(tlhairdown, x_axis)
        end

        Sleep(50)
    end
    if (decider == 1) then
        for itterator = 1, tempclap, 1 do
            aynRandOM = math.random(28, 38)
            Turn(tlHead, x_axis, math.rad(aynRandOM), 3)
            Turn(tlhairdown, x_axis, math.rad(-98), 3)
            Turn(tlhairdown, x_axis, math.rad(-1), 3)

            --Hand Standyposition

            Turn(tlarmr, x_axis, math.rad(-124), 7)
            Turn(tlarmr, y_axis, math.rad(-148), 6) --i
            Turn(tlarmr, z_axis, math.rad(72), 3)


            Turn(tlarm, x_axis, math.rad(-124), 6)
            Turn(tlarm, y_axis, math.rad(135), 7) --i
            Turn(tlarm, z_axis, math.rad(-63), 3) --i
            WaitForTurn(tlHead, x_axis)
            WaitForTurn(tlhairdown, x_axis)
            WaitForTurn(tlhairdown, x_axis)



            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)


            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)
            -- Hands together
            Turn(tlarmr, x_axis, math.rad(-124), 7)
            Turn(tlarmr, y_axis, math.rad(-175), 7) --i
            Turn(tlarmr, z_axis, math.rad(72), 7)


            Turn(tlarm, x_axis, math.rad(-124), 7)
            Turn(tlarm, y_axis, math.rad(165), 7)
            Turn(tlarm, z_axis, math.rad(-63), 7) --i
            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)


            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)


            Sleep(40)
            --Hand Standyposition

            Turn(tlarmr, x_axis, math.rad(-124), 5)
            Turn(tlarmr, y_axis, math.rad(-148), 5) --i
            Turn(tlarmr, z_axis, math.rad(72), 3)

            aynRandOM = math.random(12, 20)
            Turn(tlHead, x_axis, math.rad(aynRandOM), 3)
            Turn(tlhairup, x_axis, math.rad(-71), 3)
            Turn(tlhairdown, x_axis, math.rad(-27), 3)


            Turn(tlarm, x_axis, math.rad(-124), 5)
            Turn(tlarm, y_axis, math.rad(135), 5)
            Turn(tlarm, z_axis, math.rad(-63), 3) --i

            WaitForTurn(tlarmr, x_axis)
            WaitForTurn(tlarmr, y_axis)
            WaitForTurn(tlarmr, z_axis)


            WaitForTurn(tlHead, x_axis)
            WaitForTurn(tlhairup, x_axis)
            WaitForTurn(tlhairdown, x_axis)


            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)
            WaitForTurn(tlarm, z_axis)


            aynRandOM = math.random(50, 175)
            Sleep(aynRandOM)
        end

        Sleep(50)
    end

    --HandWave

    Turn(tlarmr, x_axis, math.rad(23), 3)
    Turn(tlarmr, y_axis, math.rad(-17), 3)
    Turn(tlarmr, z_axis, math.rad(100), 3)


    Turn(tlarm, x_axis, math.rad(-123), 3)
    Turn(tlarm, y_axis, math.rad(-32), 3)
    Turn(tlarm, z_axis, math.rad(82), 3)
    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)


    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    Sleep(250)
    --Handwavethe Second

    Turn(tlarmr, x_axis, math.rad(23), 2)
    Turn(tlarmr, y_axis, math.rad(86), 2)
    Turn(tlarmr, z_axis, math.rad(114), 2)

    Turn(tlarm, x_axis, math.rad(-123), 2)
    Turn(tlarm, y_axis, math.rad(37), 2)
    Turn(tlarm, z_axis, math.rad(82), 2)

    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    Sleep(250)
    --HandWave

    Turn(tlarmr, x_axis, math.rad(23), 2)
    Turn(tlarmr, y_axis, math.rad(-17), 2)
    Turn(tlarmr, z_axis, math.rad(100), 2)


    Turn(tlarm, x_axis, math.rad(-122), 2)
    Turn(tlarm, y_axis, math.rad(-32), 2)
    Turn(tlarm, z_axis, math.rad(82), 2)

    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    Sleep(250)


    --Handwavethe Second

    Turn(tlarmr, x_axis, math.rad(22), 2)
    Turn(tlarmr, y_axis, math.rad(86), 2)
    Turn(tlarmr, z_axis, math.rad(114), 2)

    Turn(tlarm, x_axis, math.rad(-123), 2)
    Turn(tlarm, y_axis, math.rad(37), 2)
    Turn(tlarm, z_axis, math.rad(82), 2)


    WaitForTurn(tlarmr, x_axis)
    WaitForTurn(tlarmr, y_axis)
    WaitForTurn(tlarmr, z_axis)

    WaitForTurn(tlarm, x_axis)
    WaitForTurn(tlarm, y_axis)
    WaitForTurn(tlarm, z_axis)
    Sleep(250)
end

function danceInCircle()
        flopFlip = math.random(0, 1)
        Turn(tigLil, y_axis, math.rad(0), 0)

        if flopFlip == 1 then
            Turn(tigLil, y_axis, math.rad(-179), 7)
            StartThread(danceTurnRight)
            WaitForTurn(tigLil,y_axis)
             Turn(tigLil, y_axis, math.rad(-359), 7)
        else
            Turn(tigLil, y_axis, math.rad(179), 7)
            StartThread(danceTurnLeft)
            WaitForTurn(tigLil,y_axis)
            Turn(tigLil, y_axis, math.rad(359), 7)
        end
        WaitForTurn(tigLil, y_axis)
        Signal(SIG_INCIRCLE)

end
--dancestance
function idle_stance_10()
    --echo("idle_stance10")

        --------------------------------------- Preparations--------------------------
        Turn(tlarm, x_axis, math.rad(0), 4)
        Turn(tlarm, y_axis, math.rad(0), 4)
        Turn(tlarm, z_axis, math.rad(0), 4)
        WaitForTurn(tlarm, y_axis)
        Turn(tlarm, x_axis, math.rad(-7), 1)
        Turn(tlarm, y_axis, math.rad(-138), 11)
        Turn(tlarm, z_axis, math.rad(52), 4)
        WaitForTurn(tlarm, y_axis)
        ShowReg(tldrum)
        Sleep(150)
        Turn(tlarm, x_axis, math.rad(0), 4)
        Turn(tlarm, y_axis, math.rad(0), 4)
        Turn(tigLil, y_axis, math.rad(180), 18)
        WaitForTurn(tigLil, y_axis)
        --------------------------------------- Preparations--------------------------
    for i = 0, 4, 1 do     
     -- searchmebookmark
        -- do
        tempTurnRandA = math.random(75, 105)
        Turn(dancepivot, y_axis, math.rad(-tempTurnRandA), 0.35)       
        whileInTurn(dancepivot,y_axis,onTheMove)

        danceInCircle()
        

        tempTurnRandB = math.random(160, 190)
        Turn(dancepivot, y_axis, math.rad(-tempTurnRandB), 0.35)
        whileInTurn(dancepivot,y_axis,onTheMove)

        
   
        danceInCircle()

     

        tempTurnRandC = math.random(245, 290)
        Turn(dancepivot, y_axis, math.rad(-tempTurnRandC), 0.35)
        whileInTurn(dancepivot,y_axis,onTheMove)

 
 
        danceInCircle()

        
        Turn(dancepivot, y_axis, math.rad(-360), 0.35)      
        whileInTurn(dancepivot,y_axis,onTheMove)


       danceInCircle()
        Turn(dancepivot, y_axis, math.rad(0), 0)      
        Turn(tigLil, y_axis, math.rad(0), 0,true)
    end
    Signal(SIG_ONTHEMOVE)
    Signal(SIG_INCIRCLE)
    danceEnd()
    HideReg(tldrum)
    Sleep(250)
    legs_down()
end

--headshake
function idle_stance_12()
    --echo("idle_stance12")
    legs_down()
    sign = randSign()
    mP(tigLil, 0, -9.4, 1.3, 17)
    tP(tigLil, 17, 0, sign * 9, 17)
    tP(tlHead, -10, 0, 0, 17)
    tP(tlhairup, -58, 0, 0, 17)
    tP(tlhairdown, -13, 0, 0, 17)
    tP(tlarm, -34, -11, 54, 17)
    tP(tlarmr, -28, 0, -65, 17)
    tP(tllegUp, -95, -9 * sign, -16, 17)
    tP(tllegLow, 158, -22, 2, 17)
    tP(tllegUpR, -95, -24 * sign, 14, 17)
    tP(tllegLowR, 158, 0, 0, 17)
    Sleep(5000)
    for i = 1, math.random(3, 8), 1 do
        tP(tlHead, -10, -26, 0, math.random(4, 4 + i))
        tP(tlhairup, math.random(-20, -10), 0, 0, 11)
        tP(tlhairdown, math.random(-10, 10), 0, 0, 17)
        WaitForTurn(tlHead, y_axis)
        tP(tlHead, -10, 20, 0, math.random(4, 4 + i))
        tP(tlhairup, math.random(-20, -10), 0, 0, 11)
        tP(tlhairdown, math.random(-10, 10), 0, 0, 17)
        WaitForTurn(tlHead, y_axis)
    end

    sign = randSign()
    mP(tigLil, 0, -9.4, 1.3, 17)
    tP(tigLil, 17, 0, sign * 9, 17)
    tP(tlHead, -10, 0, 0, 17)
    tP(tlhairup, -58, 0, 0, 17)
    tP(tlhairdown, -13, 0, 0, 17)
    tP(tlarm, -34, -11, 54, 17)
    tP(tlarmr, -28, 0, -65, 17)
    tP(tllegUp, -95, -9 * sign, -16, 17)
    tP(tllegLow, 158, -22, 2, 17)
    tP(tllegUpR, -95, -24 * sign, 14, 17)
    tP(tllegLowR, 158, 0, 0, 17)
    Sleep(3000)
    legs_down()
end

--allmost like sex
function idle_stance13()
--echo("idle_stance13")
    ramming = math.random(9, 22)
    factor = 17 / 22
    for i = 1, ramming do
        mP(tigLil, 0, -7, -0.8, factor * i * 7)
        tP(tigLil, 74, 0, 0, factor * i)
        tP(tlHead, -35, 0, 0, factor * i)
        tP(tlhairup, -41, 0, 0, factor * i * 2)
        tP(tlhairdown, 0, 0, 0, factor * i * 2)
        tP(tlarm, 0, 40, 0, factor * i)
        tP(tlarmr, 0, -40, 0, factor * i)
        tP(tllegUp, -67, -13, 3, factor * i)
        tP(tllegLow, 88, 0, 0, factor * i)
        tP(tllegUpR, -68, 23, 0, factor * i)
        tP(tllegLowR, 84, 0, 0, factor * i)
        Sleep(1300 - (i * 50))
        mP(tigLil, 0, -7, 3.2, factor * i * 7)
        tP(tigLil, 88, 0, 0, factor * i)
        tP(tlHead, 19, 0, 0, factor * i)
        tP(tlhairup, 78, 0, 0, factor * i * 2)
        tP(tlhairdown, 74, 0, 0, factor * i * 2)
        tP(tlarm, 0, 59, 36, factor * i)
        tP(tlarmr, 0, -59, -36, factor * i)
        tP(tllegUp, -62, -13, 3, factor * i)
        tP(tllegLow, 54, 0, 0, factor * i)
        tP(tllegUpR, -64, 23, 0, factor * i)
        tP(tllegLowR, 59, 0, 0, factor * i)
        Sleep(1300 - (i * 50))
    end
     for i = 1, 6 do
    
        mP(tigLil, 0, -8, -0.8, factor * i * 7)
        poseshift=math.random(-i,i)
        tP(tigLil, 119+poseshift, 0, 0, factor * i)
        tP(tlHead, -25, -94, -26, factor * i)
        tP(tlhairup, 33,-15,-112, factor * i * 2)
        tP(tlhairdown, 0, 0, 0, factor * i * 2)
        tP(tlarm,-37, math.random(-13,0),105, factor * i)
        tP(tlarmr, -31,math.random(0,12),-106, factor * i)
        tP(tllegUp, -85+poseshift,math.random(3,5), math.random(3,5), factor * i)
        tP(tllegLow, 50, math.random(3,5), math.random(3,5), factor * i)
        tP(tllegUpR, -85+poseshift,math.random(3,5), math.random(3,5), factor * i)
        tP(tllegLowR, 50, math.random(3,5), math.random(3,5), factor * i)
        Sleep(1300 - (i * 50))
       
    end
    
    Sleep(3000)
    legs_down()
end
--strike a pose
function idle_stance16()
    --echo("idle_stance16")
    pose = 1
    if pose ==1 then
    
    end
    Sleep(3000)
    legs_down()
end

--giving it to here
function idle_stance15()
    --echo("idle_stance15")
    askingForARamjob = math.random(9, 22)
    factor = 17 / 22
     mP(tigLil, 0, -7, -0.8, 12)
        tP(tigLil, 0, 0, 0, 22)
          tP(tllegUp, -44,0,0, 22)
        tP(tllegLow, 129, 0, 0, 22)
        tP(tllegUpR, -44, 0, 0, 22)
        tP(tllegLowR, 129, 0, 0, 22)        
        WaitForMoves(tigLil)
    for i = 1, askingForARamjob do
        mP(tigLil, 0, -7, -0.8, factor * i * 7)
        tP(tigLil, 0, 0, 0, factor * i)
        tP(tlHead, 30, 0, 0, factor * i)
        tP(tlhairup, 16, 0, 0, factor * i * 2)
        tP(tlhairdown, 21, 0, 0, factor * i * 2)
        tP(tlarm, -50, 0, 90, factor * i)
        tP(tlarmr, -50, 0, -90, factor * i)
        tP(tllegUp, -44,0,0, 3*factor * i)
        tP(tllegLow, 129, 0, 0,2* factor * i)
        tP(tllegUpR, -44, 0, 0,3* factor * i)
        tP(tllegLowR, 129, 0, 0, 2*factor * i)
        WaitForTurns(tlhairup,tlhairdown)
         tP(tlhairup, -86, 0, 0, factor * i * 2)
        tP(tlhairdown, -30, 0, 0, factor * i * 2)
        Sleep(1300 - (i * 50))
        mP(tigLil, 0, -5, 4.8, factor * i * 7)
        tP(tigLil, -25, 0, 0, factor * i)
        tP(tlHead, 5, 0, 0, factor * i)
        tP(tlhairup, -76, 0, 0, factor * i * 2)
        tP(tlhairdown, 21, 0, 0, factor * i * 2)
         tP(tlarm, -10, 0, 90, factor * i)
        tP(tlarmr, -10, 0, -90, factor * i)
        tP(tllegUp, 35, 0, 0, 3*factor * i)
        tP(tllegLow, 79, 0, 0,2* factor * i)
        tP(tllegUpR, 35, 0, 0, 3*factor * i)
        tP(tllegLowR, 78, 0, 0,2* factor * i)
        Sleep(1300 - (i * 50))
    end
     for i = 1, 5 do
    
        mP(tigLil, 0, -5, 4.8, factor * i * 7)
        tP(tigLil, -25, 0, 0, factor * i)
        tP(tlHead, 5, 0, 0, factor * i)
        tP(tlhairup, -76, 0, 0, factor * i * 2)
        tP(tlhairdown, 21, 0, 0, factor * i * 2)
        tP(tlarm, -10+ math.random(-5,5), 0, 90+ math.random(-5,5), factor * i)
        tP(tlarmr, -10+ math.random(-5,5), 0, -90+ math.random(-5,5), factor * i)
        tP(tllegUp, 35 , math.random(-5,5), math.random(-5,5), 3*factor * i)
        tP(tllegLow, 79 , math.random(-5,5), math.random(-5,5), 2* factor * i)
        tP(tllegUpR, 35 , math.random(-5,5), math.random(-5,5), 3*factor * i)
        tP(tllegLowR, 78 , math.random(-5,5), math.random(-5,5),2* factor * i)
            WaitForTurns(tigLil,tigLil,tlHead,tlhairup,tlhairdow,tlarm, tlarmr, tllegUp,tllegLow,tllegUpR,tllegLowR)
    end
    
    Sleep(3000)
    legs_down()
end

--yoga
function idle_stance14()
    --echo("idle_stance14")
    yoga = math.random(1, 14)
    if yoga == 1 then
        mP(tigLil, 0, -5, 0, 9)
        syncTurn(unitID, tigLil, 0, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, -40, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, 0, 90, 0, 5)
        syncTurn(unitID, tlarmr, 0, -90, 0, 5)
        syncTurn(unitID, tllegUp, -46, 0, 0, 5)
        syncTurn(unitID, tllegLow, 95, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -46, 0, 0, 5 * 2)
        syncTurn(unitID, tllegLowR, 94, 0, 0, 5 * 2)
        Sleep(64000)
    end
    if yoga == 2 then
        mP(tigLil, 0, -5, -1, 9)
        syncTurn(unitID, tigLil, 29, 0, 0, 5)
        syncTurn(unitID, tlHead, -30, 0, 0, 5)
        syncTurn(unitID, tlhairup, -48, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, 11, 91, -45, 5)
        syncTurn(unitID, tlarmr, -175, -90, -51, 5)
        syncTurn(unitID, tllegUp, -77, -4, 15, 5)
        syncTurn(unitID, tllegLow, 95, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -46, 76, -76, 5)
        syncTurn(unitID, tllegLowR, 118, 0, 0, 5)
        Sleep(64000)
    end

    if yoga == 3 then
        mP(tigLil, 0, 0, -1, 9)
        syncTurn(unitID, tigLil, 70, 0, 0, 5)
        syncTurn(unitID, tlHead, -30, 0, 0, 5)
        syncTurn(unitID, tlhairup, -48, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, 0, 111, -30, 5)
        syncTurn(unitID, tlarmr, 5, -83, 38, 5)
        syncTurn(unitID, tllegUp, -74, 0, 0, 5)
        syncTurn(unitID, tllegLow, 0, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -146, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 0, 0, 0, 5)
        Sleep(64000)
    end

    if yoga == 4 then
        mP(tigLil, 0, 0, -1, 9)
        syncTurn(unitID, tigLil, 70, 0, 0, 5)
        syncTurn(unitID, tlHead, -30, 0, 0, 5)
        syncTurn(unitID, tlhairup, -48, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, -4, -109, 16, 5)
        syncTurn(unitID, tlarmr, 20, 80, 119, 5)
        syncTurn(unitID, tllegUp, -74, 0, 0, 5)
        syncTurn(unitID, tllegLow, 0, 0, 0, 5)
        syncTurn(unitID, tllegUpR, 86, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 84, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 5 then
        mP(tigLil, 0, 0, -1, 9)
        syncTurn(unitID, tigLil, 70, 0, 0, 5)
        syncTurn(unitID, tlHead, -30, 0, 0, 5)
        syncTurn(unitID, tlhairup, -48, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, 0, 0, -90, 5)
        syncTurn(unitID, tlarmr, 0, 0, 90, 5)
        syncTurn(unitID, tllegUp, -74, 0, 0, 5)
        syncTurn(unitID, tllegLow, 0, 0, 0, 5)
        syncTurn(unitID, tllegUpR, 24, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 0, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 6 then
        mP(tigLil, 0, -11, 3, 9)
        syncTurn(unitID, tigLil, 46, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, -50, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 29, 0, 0, 5 * 2)
        angle = math.random(180, 270) * -1
        syncTurn(unitID, tlarm, angle, -16, -86, 5)
        syncTurn(unitID, tlarmr, angle, -13, 94, 5)
        syncTurn(unitID, tllegUp, 43, 0, 0, 5)
        syncTurn(unitID, tllegLow, 0, 0, 0, 5)
        syncTurn(unitID, tllegUpR, 45, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 0, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 7 then
        mP(tigLil, 0, -10, 0, 9)
        syncTurn(unitID, tigLil, 66, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, -50, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 29, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, -116, -16, -86, 5)
        syncTurn(unitID, tlarmr, -116, -13, 94, 5)
        syncTurn(unitID, tllegUp, -138, 0, 0, 5)
        syncTurn(unitID, tllegLow, 150, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -138, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 150, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 8 then
        mP(tigLil, 0, -10, 0, 9)
        syncTurn(unitID, tigLil, 66, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, -50, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 29, 0, 0, 5 * 2)
        syncTurn(unitID, tlarmr, 50, 0, 94, 5)
        syncTurn(unitID, tlarm, 50, 0, -94, 5)

        syncTurn(unitID, tllegUp, -138, 0, 0, 5 * 3)
        syncTurn(unitID, tllegLow, 150, 0, 0, 5 * 3)
        syncTurn(unitID, tllegUpR, -138, 0, 0, 5 * 2)
        syncTurn(unitID, tllegLowR, 150, 0, 0, 5 * 2)
        Sleep(64000)
    end
    if yoga == 9 then
        mP(tigLil, 0, -10, 0, 9)
        syncTurn(unitID, tigLil, -96, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, -50, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 29, 0, 0, 5 * 2)
        syncTurn(unitID, tlarmr, -20, 0, 94, 5)
        syncTurn(unitID, tlarm, -10, -16, -86, 5)
        syncTurn(unitID, tllegUp, 26, 0, 0, 5)
        syncTurn(unitID, tllegLow, 150, 0, 0, 5)
        syncTurn(unitID, tllegUpR, 29, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 150, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 10 then
        mP(tigLil, 0, -5.5, 1, 9)
        syncTurn(unitID, tigLil, -57, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, 18, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, -16, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, -290, 0, 94, 5)
        syncTurn(unitID, tlarmr, -290, 0, -86, 5)
        syncTurn(unitID, tllegUp, 74, 0, 0, 5 * 3)
        syncTurn(unitID, tllegLow, 72, 0, 0, 5 * 3)
        syncTurn(unitID, tllegUpR, 74, 0, 0, 5 * 2)
        syncTurn(unitID, tllegLowR, 72, 0, 0, 5 * 2)
        Sleep(64000)
    end
    if yoga == 11 then
        mP(tigLil, 0, -8, 1, 9)
        syncTurn(unitID, tigLil, 127, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, 115, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, -16, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, -229, 0, 86, 5)
        syncTurn(unitID, tlarmr, -227, 13, 94, 5)
        syncTurn(unitID, tllegUp, -108, 0, 0, 5)
        syncTurn(unitID, tllegLow, 72, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -108, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 72, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 12 then
        mP(tigLil, 0, -9, 1, 9)
        syncTurn(unitID, tigLil, 0, 0, 0, 5)
        syncTurn(unitID, tlHead, -35, 0, 0, 5)
        syncTurn(unitID, tlhairup, -30, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, -16, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, -229, 0, 86, 5)
        syncTurn(unitID, tlarmr, -227, 13, 94, 5)
        syncTurn(unitID, tllegUp, -174, 36, -94, 5)
        syncTurn(unitID, tllegLow, 127, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -128, 0, -8, 5)
        syncTurn(unitID, tllegLowR, 129, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 13 then
        mP(tigLil, 0, -3, 1, 9)
        syncTurn(unitID, tigLil, 117, 0, 0, 15)
        syncTurn(unitID, tlHead, -70, 0, 0, 5)
        syncTurn(unitID, tlhairup, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, 0, 0, 0, 5)
        syncTurn(unitID, tlarmr, 0, 0, 0, 5)
        syncTurn(unitID, tllegUp, 20, 0, 0, 5)
        syncTurn(unitID, tllegLow, 0, 0, 0, 5)
        syncTurn(unitID, tllegUpR, -112, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 0, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 14 then
        mP(tigLil, 0, -10, 1, 9)
        syncTurn(unitID, tigLil, 13, 0, 0, 15)
        syncTurn(unitID, tlHead, -70, 0, 0, 5)
        syncTurn(unitID, tlhairup, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 0, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, -6, 71, 43, 5)
        syncTurn(unitID, tlarmr, 16, 80, -27, 5)
        syncTurn(unitID, tllegUp, -262, -191, 0, 5)
        syncTurn(unitID, tllegLow, 0, 3, -150, 5)
        syncTurn(unitID, tllegUpR, 73, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 138, 0, 0, 5)
        Sleep(64000)
    end
    if yoga == 15 then
        mP(tigLil, 0, -2, -2, 9)
        syncTurn(unitID, tigLil, 114, 0, 0, 15)
        syncTurn(unitID, tlHead, 0, 0, 0, 5)
        syncTurn(unitID, tlhairup, 102, 0, 0, 5 * 2)
        syncTurn(unitID, tlhairdown, 57, 0, 0, 5 * 2)
        syncTurn(unitID, tlarm, 5, 88, -24, 5)
        syncTurn(unitID, tlarmr, 5, -92, 27, 5)
        syncTurn(unitID, tllegUp, -144, -16, 0, 5)
        syncTurn(unitID, tllegUpR, -144, 16, 0, 5)
        syncTurn(unitID, tllegLow, 145, 0, 0, 5)
        syncTurn(unitID, tllegLowR, 150, 0, 0, 5)
        Sleep(64000)
    end
    legs_down()
end

function tangoStep(times,boolLeft, offset)
    threequarter,half,quarter= math.ceil(times*0.75), math.ceil(times/2), math.ceil(times*0.25)
    RLegUp,RLegDown,LLegUp,LLegDown = tllegUp,tllegLow,tllegUpR,tllegLowR
    if boolLeft==true then
        RLegUp,RLegDown,LLegUp,LLegDown=tllegUpR,tllegLowR,tllegUp,tllegLow
    end

    tSyncIn(LLegUp,-88,0,0,threequarter)
    tSyncIn(LLegDown,113,0,0,threequarter)

    tSyncIn(RLegUp, 57,0,0,threequarter)
    tSyncIn(RLegDown,0,0,0,threequarter)

    Sleep(threequarter)
    tSyncIn(LLegUp,-64,0,0,threequarter)
    tSyncIn(LLegDown,56,0,0,threequarter)

    tSyncIn(RLegUp, 42,0,0,quarter)
    tSyncIn(RLegDown,0,0,0,quarter)
    Sleep(quarter)
    end

    --Tango
    function idle_stance17()
        --echo("idle_stance17")
    orgDirection=0

    for t=1,6 do
        numberTangoSteps=3
        taktZeit=450
        dreiViertel=math.ceil(taktZeit*0.75)
        half=math.ceil(taktZeit/2)
        bLeft,bRight=true,false
        tSign=-1
        for i=1,numberTangoSteps,2 do
            lArm,rArm=tlarm,tlarmr
            if math.ceil(i/2)%2== 0 then 
            lArm,rArm=tlarmr,tlarm 
            end
            tSign=tSign*-1
            tSyncIn( lArm,9,71*tSign,35,taktZeit)
            tSyncIn( rArm,0,-87*tSign,5,taktZeit)
            
            mSyncIn(tigLil,0,-2,(i-0.5)*3, half)
            StartThread(tangoStep,taktZeit,bLeft,-6)
            Sleep(half)
            mSyncIn(tigLil,0,-4,(i)*3, half)
            Sleep(half)
                
            StartThread(tangoStep,taktZeit,bRight,-4)
            mSyncIn(tigLil,0,-2,(i+0.5)*3, half)
            Sleep(half)
            mSyncIn(tigLil,0,-5,(i+1)*3, half)
            Sleep(half)
            Sleep(150)
        end

        -- shaking
        for i=1,3 do
            tangoShakeMovement(half,taktZeit,qater,numberTangoSteps)
        end

            
        sideStep(half,taktZeit,numberTangoSteps)
        orgDirection=orgDirection+1
        Sleep(taktZeit*2)
        Turn(deathpivot,y_axis,math.rad(orgDirection*90),60)
        reset(tigLil,60)

    end

end

function tangoShakeMovement(half,taktZeit,qater,numberTangoSteps)
offset=math.random(-40,0)
    tSyncIn( lArm,9-offset,-71,35,taktZeit)
    tSyncIn( rArm,0-offset,87,5,taktZeit)
    mSyncIn(tigLil,0,-4,(numberTangoSteps+1)*3 +math.random(0,10)/10, taktZeit)
    tSyncIn(tigLil,21+offset,0,0,taktZeit)
    
    tSyncIn(tllegUp,0-offset,0,0,taktZeit)
    tSyncIn(tllegLow,44,0,0,taktZeit)
    tSyncIn(tllegUpR, -85-offset,0,0,taktZeit)
    tSyncIn(tllegLowR,61,0,0,taktZeit)
    Sleep(taktZeit)

    mSyncIn(tigLil,0, -2,(numberTangoSteps+1)*3 +math.random(0,10)/10, taktZeit)
    tSyncIn(tigLil,5+offset,0,0,taktZeit)
    
    tSyncIn(tllegUp,18-offset,0,0,taktZeit)
    tSyncIn(tllegLow,22,0,0,taktZeit)
    tSyncIn(tllegUpR, -50-offset,0,0,taktZeit)
    tSyncIn(tllegLowR,43 ,0,0,taktZeit)
    Sleep(taktZeit)
end
function sideStep(half,taktZeit,numberTangoSteps,orgDirection)


    tSyncIn(tllegUp, 15, -39, -30,half)
    tSyncIn(tllegLow,10,0,0,half)
    tSyncIn(tllegUpR, 57,0,0,half)
    tSyncIn(tllegLowR,0,0,0,half)

    
    mSyncIn(tigLil,0, 0,(numberTangoSteps)*3 +math.random(0,10)/10, taktZeit)
    tSyncIn(tigLil,0,90,0,taktZeit)
    
    Sleep(half)
    tSyncIn(tllegUpR, 0,0,42,half)
    tSyncIn(tllegLowR,0,0,0,half)
    tSyncIn(tllegUp,0,0,0,half)
    tSyncIn(tllegLow,0,0,0,half)
    Sleep(half)
    tSyncIn(tllegUpR, 0,0,0,half)
-- seitlich zurück
    engsign=randSign()
    tSyncIn( lArm,0,0,75*engsign,taktZeit)
    tSyncIn( rArm,0,0,-75*engsign,taktZeit)
end

--even numbers left foot up
function drumPose1(mspeed, tspeed)

    tSyncIn(tigLil, 0,0,0,250)
    tSyncIn(tlHead,20,0,0,250)
    tSyncIn(tlhairup,-69,0,0,250)
    tSyncIn(tlhairdown,-30,0,0,250)
    tSyncIn(tlarm, 10,0,-89.9,250)
    tSyncIn(tlarmr, 0,0,40.9,250)
    tSyncIn(tllegUp, 0,0,0,250)
    tSyncIn(tllegLow, 0,0,0,250)
    tSyncIn(tllegUpR, -60,-10,0,250)
    tSyncIn(tllegLowR, 81,0,-9,250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)

end

function drumPose2(mspeed, tspeed)

    tSyncIn(tigLil, -30,0,10,250)
    tSyncIn(tlHead,40,0,10,250)
    tSyncIn(tlhairup,-40,40,0,250)
    tSyncIn(tlhairdown,-50,10,0,250)
    tSyncIn(tlarm, 60,0,-89,250)
    tSyncIn(tlarmr, 69,0,20,250)
    tSyncIn(tllegUp, -29,0,0,250)
    tSyncIn(tllegLow,89,0,0,250)
    tSyncIn(tllegUpR, 40,-10,0,250)
    tSyncIn(tllegLowR, 1.5,0,-10,250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)

end

local function drumPose3(mspeed, tspeed)
    tSyncIn(tigLil, -1.7,0,-10,250)
    tSyncIn(tlHead,-34,0,17,250)
    tSyncIn(tlhairup,-20,2,0,250)
    tSyncIn(tlhairdown,20,10,0,250)
    tSyncIn(tlarm, 90,0,43,250)
    tSyncIn(tlarmr, -65,0,20,250)
    tSyncIn(tllegUp, 16,2,-4,250)
    tSyncIn(tllegLow,-2,-45,0,250)
    tSyncIn(tllegUpR, -77,20,0,250)
    tSyncIn(tllegLowR, 131,0,-10,250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)
    


end

local function drumPose4(mspeed, tspeed)
    tSyncIn(tigLil, 10,10,10,250)
    tSyncIn(tlHead,6,20,17,250)
    tSyncIn(tlhairup,-60,2,0,250)
    tSyncIn(tlhairdown,-49,10,0,250)
    tSyncIn(tlarm, 163,20,92,250)
    tSyncIn(tlarmr, 5,0,90,250)
    tSyncIn(tldrum, -2,0,0,250)
    tSyncIn(tllegUp, -134,32,-4,250)
    tSyncIn(tllegLow,120,0,0,250)
    tSyncIn(tllegUpR, 13,20,0,250)
    tSyncIn(tllegLowR, 11.5,-10,-12,250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)
    

end

local function drumPose5(mspeed, tspeed)
    tSyncIn(tigLil, -5.2,1.8,-1.6,250)
    tSyncIn(tlHead,-20,40,0,250)
    tSyncIn(tlhairup,-69,0,0,250)
    tSyncIn(tlhairdown,0,-59,89,250)
    
    tSyncIn(tlarm, -149,40,-89,250)
    tSyncIn(tlarmr, -120,0,-89.39,250)
    
    tSyncIn(tllegUp, 0,0,0,250)
    tSyncIn(tllegLow, 40,0,0,250)
    tSyncIn(tllegUpR, -99,20,10,250)
    tSyncIn(tllegLowR, 109,0,0,250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)


end

local function drumPose6(mspeed, tspeed, addUp)
    addUp = addUp - 5.5
    --drumjump
    mSyncIn(tigLil,0,addUp,6,250)
    tSyncIn(tigLil, -55,1.8,-1.6,250)
    
    tSyncIn(tlHead,40,-10,10,250)
    tSyncIn(tlhairup,-20,-40,20,250)
    tSyncIn(tlhairdown,30,0,0,250)
    
    tSyncIn(tlarm, -109, 168, -102,250)
    tSyncIn(tlarmr, -84,50,-89.39,250)
    
    tSyncIn(tllegUp, 20,-19,-20,250)
    tSyncIn(tllegLow, 109,-10,0,250)
    tSyncIn(tllegUpR, 12,30,30,250)
    tSyncIn(tllegLowR, 115,-10,0,250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)

    addUp = addUp + 2.5
    mSyncIn(tigLil,0,addUp,0,150)
    WaitForMoves(tigLil)

end

local function drumPose7(mspeed, tspeed, addUp)
  addUp = addUp - 5.5
    --drumjump
    mSyncIn(tigLil,0,addUp,6,250)
    tSyncIn(tigLil, 14.6,1.8,-1.6,250)
    
    tSyncIn(tlHead,10,-10,10,250)
    tSyncIn(tlhairup,-90,-2,20,250)
    tSyncIn(tlhairdown,30,0,0,250)
    
    tSyncIn(tlarm,-139.8,99,-101.8,250)
    tSyncIn(tlarmr,-54, 49, -89, 250)
    
    tSyncIn(tllegUp, -110,20,-20,250)
    tSyncIn(tllegLow, 1-10,-10,0,250)
    tSyncIn(tllegUpR, -107,-2,2,250)
    tSyncIn(tllegLowR, 135, -10,0, 250)
    WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    WaitForMoves(tigLil)

    addUp = addUp + 2.5
    mSyncIn(tigLil,0,addUp,0,150)
    WaitForMoves(tigLil)


end


local function drumPose8(mspeed, tspeed)
   
    --HipShake
    rand=math.random(1,8)
    for i = 0, rand, 1 do
        tSyncIn(tigLil,      0,0,-10,250)
        
        tSyncIn(tlHead,     10,0,-10,250)
        tSyncIn(tlhairup,   -72,20,0,250)
        tSyncIn(tlhairdown, -30,0,0,250)
        
        tSyncIn(tlarm,      5,-22,94,250)
        tSyncIn(tlarmr,     -10,80,-70,250)
        
        tSyncIn(tllegUp,    0,0,10,250)
        tSyncIn(tllegLow,   0,0,0,250)
        tSyncIn(tllegUpR,   2,-20,10,250)
        tSyncIn(tllegLowR,  0,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        Sleep(75)
        tSyncIn(tigLil,     0,0,0,250)
        
        tSyncIn(dancepivot, 0,0,0,250)  
        tSyncIn(tlHead,     11,0,3,250)
        tSyncIn(tlhairup,   -120,148,-150,250)
        tSyncIn(tlhairdown, -30,0,0,250)
        
        tSyncIn(tlarm,      3,-67,87,250)
        tSyncIn(tlarmr,     -4,97,-86,250)
        
        tSyncIn(tllegUp,    0,0,0,250)
        tSyncIn(tllegLow,   0,0,0,250)
        tSyncIn(tllegUpR,   2,-10,-10,250)
        tSyncIn(tllegLowR,  0,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
  
        Sleep(300)
    end
end

--Turnuebungen
local function drumPose(mspeed, tspeed, addUp)
    randyPro = math.random(2, 8)
     addUp1 = addUp - 10.5 --7
     mSyncIn(tigLil,    0, addUp1, 0, 250)
    for i = 0, randyPro, 1 do
        tSyncIn(tigLil, -104, 0 ,0, 250)    
        mSyncIn(tigLil, 0, addUp1, 0, 250)
        
        tSyncIn(dancepivot, 0,0,0,250)
        mSyncIn(tlHead,     0,0,0,250)
        tSyncIn(tlHead,     20,0,0,250)
        tSyncIn(tlhairup,   80, 2, 0, 250)
        tSyncIn(tlhairdown, 0,0,0,250)
        
        tSyncIn(tlarm,      0,0,-30,250)
        tSyncIn(tlarmr,     0,-2,40,250)
        
        tSyncIn(tllegUp,    -80,0,0,250)
        tSyncIn(tllegLow,   100,0,0,250)
        tSyncIn(tllegUpR,   -61,0,0,250)
        tSyncIn(tllegLowR,  80,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        WaitForMoves(tigLil)   

        addUp2 = addUp - 7.5000019073486 --6
        tSyncIn(tigLil,     -124, 0 ,0, 250)    
        mSyncIn(tigLil,     0, addUp2, 0, 250)
        
        tSyncIn(dancepivot, 0,0,0,250)
        mSyncIn(tlHead,     -1.5,-0.5,1.5,250)
        tSyncIn(tlHead,     68,-4,-2,250)
        tSyncIn(tlhairup,   60,2,10,250)
        tSyncIn(tlhairdown, 0,0,0,250)
        
        tSyncIn(tlarm,      -20,10,20,250)
        tSyncIn(tlarmr, -20,-2,-20,250)
        
        tSyncIn(tllegUp,    20,2,-20,250)
        tSyncIn(tllegLow,   100,0,0,250)
        tSyncIn(tllegUpR,   19,0,20,250)
        tSyncIn(tllegLowR,  90,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        WaitForMoves(tigLil)   
    end
        tSyncIn(tigLil,     0, 0 ,0, 250)   
        mSyncIn(tigLil, 0, addUp, 0, 100)
        tSyncIn(dancepivot, 0,0,0,250)
        tSyncIn(tlHead,     -20,20,0,250)
        mSyncIn(tlHead,      0,0,0,250)
        tSyncIn(tlHead,      0,0,0,250)
        tSyncIn(tlhairup,   -49,-12,0,250)
        tSyncIn(tlhairdown, -26,0,10,250)
        
        tSyncIn(tlarm,      -180,-10,90,250)
        tSyncIn(tlarmr,     -180,-20,-80,250)
        
        tSyncIn(tllegUp,    0,0,0,250)
        tSyncIn(tllegLow,   0,0,0,250)
        tSyncIn(tllegUpR,   0,0,0,250)
        tSyncIn(tllegLowR,  30,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        WaitForMoves(tigLil)
   
end

local function drumPoseNeutral(mspeed, tspeed, addUp)
        tSyncIn(tigLil,     0,0,0,250)
                            
        tSyncIn(dancepivot, 0,0,0,250)
        tSyncIn(tlHead,     -20,20,0,250)
        tSyncIn(tlhairup,   -50,-12,0,250)
        tSyncIn(tlhairdown, -26,0,10,250)
                            
        tSyncIn(tlarm,      -180,-10,89,250)
        tSyncIn(tlarmr,     -180,-20,-80,250)
                            
        tSyncIn(tllegUp,    0,0,0,250)
        tSyncIn(tllegLow,   10,0,0,250)
        tSyncIn(tllegUpR,   -10,0,0,250)
        tSyncIn(tllegLowR,  30,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)

end


local function drumPoseNeutral2(mspeed, tspeed, addUp)
    addUp = addUp - 7
    --- -Spring.Echo("Addup 5 to -7 neutral pose 2 ")
        mSyncIn(tigLil,     0,addUp,0,250)
        tSyncIn(tigLil,     0,0,0,250)
    
        tSyncIn(tlHead,     10,10,0,250)
        tSyncIn(tlhairup,   -49,-12,0,250)
        tSyncIn(tlhairdown, -26,0,10,250)
                            
        tSyncIn(tlarm,      0,0,0,250)
        tSyncIn(tlarmr,     -269,-20,-79,250)
                            
        tSyncIn(tllegUp,    -92,-89,20,250)
        tSyncIn(tllegLow,   149,0,0,250)
        tSyncIn(tllegUpR,   -70,0,80,250)
        tSyncIn(tllegLowR,  140,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)

        
end

local function drumPoseNeutral3(mspeed, tspeed, addUp)


    rand = math.random(0, 1)
    if rand == 1 then

        addUp = addUp - 8
        mSyncIn(tigLil,     0,addUp,0,250)
        tSyncIn(tigLil,     90,0,0,250)
    
        mSyncIn(tlHead,     0,-0.5,-0.5,250)
        tSyncIn(tlHead,     -100,-8,-8,250)
        tSyncIn(tlhairup,   21,8,10,250)
        tSyncIn(tlhairdown, -26,10,10,250)
                            
        tSyncIn(tlflute,    10,10,0,250)
        tSyncIn(tlarm,      -180,-20,40,250)
        tSyncIn(tlarmr,     -54,-109,97,250)
                            
        tSyncIn(tllegUp,    -90,-93,20,250) 
        tSyncIn(tllegLow,   8.5,0,0,250)
        tSyncIn(tllegUpR,   -70,0,79,250)
        tSyncIn(tllegLowR,  3,-10,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        Sleep(150)

    end
    if rand == 0 then
        addUp = addUp - 7.5
        mSyncIn(tigLil,     0,addUp,0,250)
        tSyncIn(tigLil,     0,0,0,250)
    
        tSyncIn(tlHead,     9,-7,0,250)
        tSyncIn(tlhairup,   -69,8,10,250)
        tSyncIn(tlhairdown, -26,10,10,250)
                            
        tSyncIn(tlflute,    10,10,0,250)
        tSyncIn(tlarm,      -180,-20,40,250)
        tSyncIn(tlarmr,     -54,-109,97,250)
                            
        tSyncIn(tllegUp,    -93,-90,20,250) 
        tSyncIn(tllegLow,   8.5,0,0,250)
        tSyncIn(tllegUpR,   -70,0,79,250)
        tSyncIn(tllegLowR,  3,-10,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)

    end
end

local function drumPoseMorphStage(mspeed, tspeed, addUp)

        mSyncIn(tigLil,     0,addUp,0,250)
        tSyncIn(tigLil,     0,20,0,250)
    
        tSyncIn(tlHead,     -10,-20,0,250)
        tSyncIn(tlhairup,   -70,30,0,250)
        tSyncIn(tlhairdown, 0,0,0,250)
                            
        tSyncIn(tlflute,    0,0,0,250)
        tSyncIn(tlarm,      0,-10,-40,250)
        tSyncIn(tlarmr,     -20,0,-54,250)
                            
        tSyncIn(tllegUp,    -20,-20,0,250)
        tSyncIn(tllegLow,   10,0,0,250)
        tSyncIn(tllegUpR,   -10,-20,0,250)
        tSyncIn(tllegLowR,  30,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        

 
end

local function drumPosePoledancin(mspeed, tspeed, addUp)
        addUp = addUp + 12
        mSyncIn(tigLil,     5,addUp,-3,250)
        tSyncIn(tigLil,     0,0,-90,250)
        ShowReg(tlpole)
        tSyncIn(tlHead,     6,0,-9,250)
        tSyncIn(tlhairup,   -57,90,17,250)
        tSyncIn(tlhairdown, 0,0,0,250)
                            
        tSyncIn(tlflute,    0,0,0,250)
        tSyncIn(tlarm,      0,0,-46,250)
        tSyncIn(tlarmr,     0,0,76,250)
                            
        tSyncIn(tllegUp,    -39,0,0,250)
        tSyncIn(tllegLow,   147,0,0,250)
        tSyncIn(tllegUpR,   -71,69,0,250)
        tSyncIn(tllegLowR,  142,0,0,250)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
        Spin(deathpivot, y_axis, math.rad(140), 90)
        --Spin(tldancedru, y_axis, math.rad(-140), 90)
        mSyncIn(tigLil,     0,addUp-21,0,8000)
        WaitForMoves(tigLil)
        StopSpin(deathpivot, y_axis)
        --StopSpin(tldancedru, y_axis)
        HideReg(tlpole)
    

end

local function idle_stance11()
    tspeed = 2
    mspeed = 3
    --music loud and pure
    rand = math.random(0, 2)

    if rand == 0 then
        --drum&base

        --plant drum
        ShowReg(tldrum)
        Turn(tlarm, x_axis, math.rad(-129.99998474121), tspeed)
        Turn(tlarm, y_axis, math.rad(60.000003814697), tspeed)
        Turn(tlarm, z_axis, math.rad(39.099998474121), tspeed)
        Sleep(270)
        Turn(tlarm, x_axis, math.rad(-90), tspeed)
        Turn(tlarm, y_axis, math.rad(60.000003814697), tspeed)
        Turn(tlarm, z_axis, math.rad(39.099998474121), tspeed)
        WaitForTurn(tlarm, x_axis)
        WaitForTurn(tlarm, y_axis)
        WaitForTurn(tlarm, z_axis)
        Turn(tlHead, x_axis, math.rad(39), tspeed)
        Turn(tlHead, y_axis, math.rad(0), tspeed)
        Turn(tlHead, z_axis, math.rad(-29.200000762939), tspeed)
        Turn(tlhairup, x_axis, math.rad(-119.99999237061), tspeed)
        Turn(tlhairup, y_axis, math.rad(10), tspeed)
        Turn(tlhairup, z_axis, math.rad(-30.000001907349), tspeed)
        Turn(tlflute, x_axis, math.rad(0), tspeed)
        Turn(tlflute, y_axis, math.rad(0), tspeed)
        Turn(tlflute, z_axis, math.rad(0), tspeed)
        Turn(tlarm, x_axis, math.rad(-90), tspeed)
        Turn(tlarm, y_axis, math.rad(60.000003814697), tspeed)
        Turn(tlarm, z_axis, math.rad(39.099998474121), tspeed)
        Move(tldrum, z_axis, -23, mspeed*3)
        Move(tlarmr, x_axis, 1.1920928955078e-007, mspeed)
        Turn(tlarmr, z_axis, math.rad(43.000003814697), tspeed)
        WaitForTurn(tlarmr, z_axis)
        WaitForMove(tldrum, z_axis)
        HideReg(tldrum)
        --ShowReg(tldancedru)
        ---------------------------------------------------
        mspeed = 1
        growBeatBox = math.random(-3, 18)
        --Move(tldancedru, y_axis, growBeatBox, math.abs(growBeatBox/3))
        growBeatBox = growBeatBox + 3
        addUp = growBeatBox
        Move(tigLil, y_axis, growBeatBox, math.abs(growBeatBox/3))
        WaitForMove(tigLil, y_axis)
        Sleep(360)
        discodancin = math.random(8, 18)
        twoAndTwo = 10
        two = math.random(-1, 0)

        twoAndTwo = twoAndTwo + (20 * two)
        Spin(tigLil, y_axis, math.rad(20))
        --FIXME
        mspeed = 4
        tspeed = 2

        for i = 0, discodancin, 1 do
            --8 drums
            for a = 0, 4, 1 do
                even = math.random(0, 2)
                --echo("Even discodancin" ..even)

                if even == 0 then
                    tspeed = 3
                    drumPose2(mspeed, tspeed)
                    Sleep(60)
                end
                if even == 1 then

                    tspeed = 3.5
                    drumPose4(mspeed, tspeed)
                    Sleep(60)
                end
                if even == 2 then
                    drumPose6(mspeed, tspeed, addUp)
                    Sleep(60)
                end
                ----- unevens
                uneven = math.random(0, 3)
                --echo("un Even discodancin" ..uneven)
                if uneven == 0 then
                    tspeed = 4
                    drumPose1(mspeed, tspeed)
                    Sleep(40)
                end
                if uneven == 1 then
                    tspeed = 5

                    drumPose3(mspeed, tspeed)
                    Sleep(45)
                end
                if uneven == 2 then
                    drumPose5(mspeed, tspeed)
                end
                if uneven == 3 then
                    drumPose7(mspeed, tspeed, addUp)
                end
            end
            --4 drum
            local oneInFour = math.random(0, 5)
            --echo("oneInFour discodancin" ..oneInFour)
            if oneInFour == 0 then

                drumPose8(mspeed, tspeed)
                Sleep(30)
                drumPoseMorphStage(mspeed, tspeed, addUp)
                Sleep(40)
            end
            if oneInFour == 1 then
                drumPose(mspeed, tspeed, addUp)
                Sleep(40)
                drumPoseMorphStage(mspeed, tspeed, addUp)
                Sleep(40)
            end
            if oneInFour == 2 then
                drumPoseNeutral(mspeed, tspeed, addUp)
                drumPoseMorphStage(mspeed, tspeed, addUp)
            end
            if oneInFour == 3 then
                drumPoseNeutral2(mspeed, tspeed, addUp)
                drumPoseMorphStage(mspeed, tspeed, addUp)
            end
            if oneInFour == 4 then
                drumPoseNeutral3(mspeed, tspeed, addUp)
                drumPoseMorphStage(mspeed, tspeed, addUp)
            end
            if oneInFour == 5 then
                drumPosePoledancin(mspeed, tspeed, addUp)
                drumPoseMorphStage(mspeed, tspeed, addUp)
            end
        end
    end
    if rand == 1 then
        --fluteloop
        local randOneZero = math.random(0, 1)
        if randOneZero == 1 then
            durRand = math.random(4, 18)
            for it = 0, durRand, 1 do
                --querfl򴥮
                tspeed = 1
                mspeed = 1
                Turn(tigLil, x_axis, math.rad(10), tspeed)
                Turn(tigLil, y_axis, math.rad(0), tspeed)
                Turn(tigLil, z_axis, math.rad(0), tspeed)
                Move(tlHead, x_axis, 0, mspeed)
                Move(tlHead, y_axis, 0, mspeed)
                Move(tlHead, z_axis, 0, mspeed)
                Turn(tlHead, x_axis, math.rad(0), tspeed)
                Turn(tlHead, y_axis, math.rad(0), tspeed)
                Turn(tlHead, z_axis, math.rad(0), tspeed)
                Move(tlhairup, x_axis, 0, mspeed)
                Move(tlhairup, y_axis, 0, mspeed)
                Move(tlhairup, z_axis, 0, mspeed)
                Turn(tlhairup, x_axis, math.rad(-59.600006103516), tspeed)
                Turn(tlhairup, y_axis, math.rad(0), tspeed)
                Turn(tlhairup, z_axis, math.rad(0), tspeed)
                Move(tlhairdown, x_axis, 0, mspeed)
                Move(tlhairdown, y_axis, 0, mspeed)
                Move(tlhairdown, z_axis, 0, mspeed)
                Turn(tlhairdown, x_axis, math.rad(-20), tspeed)
                Turn(tlhairdown, y_axis, math.rad(0), tspeed)
                Turn(tlhairdown, z_axis, math.rad(0), tspeed)
                Move(tlflute, x_axis, -0.099999986588955, mspeed)
                Move(tlflute, y_axis, 0.19999998807907, mspeed)
                Move(tlflute, z_axis, -0.099999964237213, mspeed)
                Turn(tlflute, x_axis, math.rad(5.0000009536743), tspeed)
                Turn(tlflute, y_axis, math.rad(-90), tspeed)
                Turn(tlflute, z_axis, math.rad(-607.00006103516), tspeed)
                Move(tlarm, x_axis, 0.49999988079071, mspeed)
                Move(tlarm, y_axis, 0, mspeed)
                Move(tlarm, z_axis, -0.39999997615814, mspeed)
                Turn(tlarm, x_axis, math.rad(69.999992370605), tspeed)
                Turn(tlarm, y_axis, math.rad(20), tspeed)
                Turn(tlarm, z_axis, math.rad(-11.000000953674), tspeed)

                Move(tldrum, x_axis, 0, mspeed)
                Move(tldrum, y_axis, 0, mspeed)
                Move(tldrum, z_axis, 0, mspeed)
                Turn(tldrum, x_axis, math.rad(0), tspeed)
                Turn(tldrum, y_axis, math.rad(0), tspeed)
                Turn(tldrum, z_axis, math.rad(0), tspeed)
                Move(tlarmr, x_axis, 1.0000001192093, mspeed)
                Move(tlarmr, y_axis, 0, mspeed)
                Move(tlarmr, z_axis, -1, mspeed)
                Turn(tlarmr, x_axis, math.rad(-208.99992370605), tspeed)
                Turn(tlarmr, y_axis, math.rad(52.000022888184), tspeed)
                Turn(tlarmr, z_axis, math.rad(202.90002441406), tspeed)
             --[[   Move(tlsparksemit, x_axis, 0, mspeed)
                Move(tlsparksemit, y_axis, 0, mspeed)
                Move(tlsparksemit, z_axis, 0, mspeed)
                Turn(tlsparksemit, x_axis, math.rad(0), tspeed)
                Turn(tlsparksemit, y_axis, math.rad(0), tspeed)
                Turn(tlsparksemit, z_axis, math.rad(0), tspeed)--]]
                --Move(tlharp, x_axis, 0, mspeed)
                --Move(tlharp, y_axis, 0, mspeed)
                --Move(tlharp, z_axis, 0, mspeed)
                --Turn(tlharp, x_axis, math.rad(0), tspeed)
                --Turn(tlharp, y_axis, math.rad(0), tspeed)
                --Turn(tlharp, z_axis, math.rad(0), tspeed)
                Move(tllegUp, x_axis, 0, mspeed)
                Move(tllegUp, y_axis, 0, mspeed)
                Move(tllegUp, z_axis, 0, mspeed)
                Turn(tllegUp, x_axis, math.rad(-15.000001907349), tspeed)
                Turn(tllegUp, y_axis, math.rad(0), tspeed)
                Turn(tllegUp, z_axis, math.rad(0), tspeed)
                Move(tllegLow, x_axis, 0, mspeed)
                Move(tllegLow, y_axis, 0, mspeed)
                Move(tllegLow, z_axis, 0, mspeed)
                Turn(tllegLow, x_axis, math.rad(0), tspeed)
                Turn(tllegLow, y_axis, math.rad(0), tspeed)
                Turn(tllegLow, z_axis, math.rad(0), tspeed)
                Move(tllegUpR, x_axis, 0, mspeed)
                Move(tllegUpR, y_axis, 0, mspeed)
                Move(tllegUpR, z_axis, 0, mspeed)
                Turn(tllegUpR, x_axis, math.rad(-11), tspeed)
                Turn(tllegUpR, y_axis, math.rad(0), tspeed)
                Turn(tllegUpR, z_axis, math.rad(0), tspeed)
                Move(tllegLowR, x_axis, 0, mspeed)
                Move(tllegLowR, y_axis, 0, mspeed)
                Move(tllegLowR, z_axis, 0, mspeed)
                Turn(tllegLowR, x_axis, math.rad(0), tspeed)
                Turn(tllegLowR, y_axis, math.rad(0), tspeed)
                Turn(tllegLowR, z_axis, math.rad(0), tspeed)

                ShowReg(tlflute)
                Sleep(950)

                Turn(tigLil, x_axis, math.rad(0), tspeed)
                Turn(tigLil, y_axis, math.rad(0), tspeed)
                Turn(tigLil, z_axis, math.rad(0), tspeed)
                Move(tlHead, x_axis, 0, mspeed)
                Move(tlHead, y_axis, 0, mspeed)
                Move(tlHead, z_axis, 0, mspeed)
                Turn(tlHead, x_axis, math.rad(1), tspeed)
                Turn(tlHead, y_axis, math.rad(6), tspeed)
                Turn(tlHead, z_axis, math.rad(0), tspeed)
                Move(tlhairup, x_axis, 0, mspeed)
                Move(tlhairup, y_axis, 0, mspeed)
                Move(tlhairup, z_axis, 0, mspeed)
                Turn(tlhairup, x_axis, math.rad(-79.599998474121), tspeed)
                Turn(tlhairup, y_axis, math.rad(0), tspeed)
                Turn(tlhairup, z_axis, math.rad(0), tspeed)
                Move(tlhairdown, x_axis, 0, mspeed)
                Move(tlhairdown, y_axis, 0, mspeed)
                Move(tlhairdown, z_axis, 0, mspeed)
                Turn(tlhairdown, x_axis, math.rad(1.9999989271164), tspeed)
                Turn(tlhairdown, y_axis, math.rad(-1), tspeed)
                Turn(tlhairdown, z_axis, math.rad(0), tspeed)
                Move(tlflute, x_axis, -0.099999986588955, mspeed)
                Move(tlflute, y_axis, 0.19999998807907, mspeed)
                Move(tlflute, z_axis, -0.099999964237213, mspeed)
                Turn(tlflute, x_axis, math.rad(4.0000009536743), tspeed)
                Turn(tlflute, y_axis, math.rad(-80.999984741211), tspeed)
                Turn(tlflute, z_axis, math.rad(-607.00006103516), tspeed)
                Move(tlarm, x_axis, 0.49999988079071, mspeed)
                Move(tlarm, y_axis, 0, mspeed)
                Move(tlarm, z_axis, -0.39999997615814, mspeed)
                Turn(tlarm, x_axis, math.rad(67.999992370605), tspeed)
                Turn(tlarm, y_axis, math.rad(20), tspeed)
                Turn(tlarm, z_axis, math.rad(-16.000001907349), tspeed)
           --[[     Move(tlsparksemit2, x_axis, 0, mspeed)
                Move(tlsparksemit2, y_axis, 0, mspeed)
                Move(tlsparksemit2, z_axis, 0, mspeed)
                Turn(tlsparksemit2, x_axis, math.rad(0), tspeed)
                Turn(tlsparksemit2, y_axis, math.rad(0), tspeed)
                Turn(tlsparksemit2, z_axis, math.rad(0), tspeed)--]]
                Move(tldrum, x_axis, 0, mspeed)
                Move(tldrum, y_axis, 0, mspeed)
                Move(tldrum, z_axis, 0, mspeed)
                Turn(tldrum, x_axis, math.rad(0), tspeed)
                Turn(tldrum, y_axis, math.rad(0), tspeed)
                Turn(tldrum, z_axis, math.rad(0), tspeed)
                Move(tlarmr, x_axis, 1.0000001192093, mspeed)
                Move(tlarmr, y_axis, 0, mspeed)
                Move(tlarmr, z_axis, -1, mspeed)
                Turn(tlarmr, x_axis, math.rad(-204.99995422363), tspeed)
                Turn(tlarmr, y_axis, math.rad(52.000022888184), tspeed)
                Turn(tlarmr, z_axis, math.rad(202.90002441406), tspeed)
--[[                Move(tlsparksemit, x_axis, 0, mspeed)
                Move(tlsparksemit, y_axis, 0, mspeed)
                Move(tlsparksemit, z_axis, 0, mspeed)
                Turn(tlsparksemit, x_axis, math.rad(0), tspeed)
                Turn(tlsparksemit, y_axis, math.rad(0), tspeed)
                Turn(tlsparksemit, z_axis, math.rad(0), tspeed)--]]
                --Move(tlharp, x_axis, 0, mspeed)
                --Move(tlharp, y_axis, 0, mspeed)
                --Move(tlharp, z_axis, 0, mspeed)
                --Turn(tlharp, x_axis, math.rad(0), tspeed)
                --Turn(tlharp, y_axis, math.rad(0), tspeed)
                --Turn(tlharp, z_axis, math.rad(0), tspeed)
                Move(tllegUp, x_axis, 0, mspeed)
                Move(tllegUp, y_axis, 0, mspeed)
                Move(tllegUp, z_axis, 0, mspeed)
                Turn(tllegUp, x_axis, math.rad(-5.0000023841858), tspeed)
                Turn(tllegUp, y_axis, math.rad(0), tspeed)
                Turn(tllegUp, z_axis, math.rad(0), tspeed)
                Move(tllegLow, x_axis, 0, mspeed)
                Move(tllegLow, y_axis, 0, mspeed)
                Move(tllegLow, z_axis, 0, mspeed)
                Turn(tllegLow, x_axis, math.rad(0), tspeed)
                Turn(tllegLow, y_axis, math.rad(0), tspeed)
                Turn(tllegLow, z_axis, math.rad(0), tspeed)
                Move(tllegUpR, x_axis, 0, mspeed)
                Move(tllegUpR, y_axis, 0, mspeed)
                Move(tllegUpR, z_axis, 0, mspeed)
                Turn(tllegUpR, x_axis, math.rad(-1.0000003576279), tspeed)
                Turn(tllegUpR, y_axis, math.rad(0), tspeed)
                Turn(tllegUpR, z_axis, math.rad(0), tspeed)
                Move(tllegLowR, x_axis, 0, mspeed)
                Move(tllegLowR, y_axis, 0, mspeed)
                Move(tllegLowR, z_axis, 0, mspeed)
                Turn(tllegLowR, x_axis, math.rad(0), tspeed)
                Turn(tllegLowR, y_axis, math.rad(0), tspeed)
                Turn(tllegLowR, z_axis, math.rad(0), tspeed)



                Sleep(460)
            end
            Move(tlarm, x_axis, 0, 4)
            Move(tlarm, y_axis, 0, 4)
            Move(tlarm, z_axis, 0, 4)
            HideReg(tlflute)
        end
        if randOneZero == 0 then
            --querTr򴥍
            ShowReg(tlflute)

            jamin = math.random(5, 19)
            for ot = 0, jamin, 1 do
                tspeed = 2


                Turn(tigLil, x_axis, math.rad(0), tspeed)
                Turn(tigLil, y_axis, math.rad(0), tspeed)
                Turn(tigLil, z_axis, math.rad(0), tspeed)
                Move(tlHead, x_axis, 0, mspeed)
                Move(tlHead, y_axis, 0, mspeed)
                Move(tlHead, z_axis, 0, mspeed)
                Turn(tlHead, x_axis, math.rad(0), tspeed)
                Turn(tlHead, y_axis, math.rad(0), tspeed)
                Turn(tlHead, z_axis, math.rad(0), tspeed)
                Move(tlhairup, x_axis, 0, mspeed)
                Move(tlhairup, y_axis, 0, mspeed)
                Move(tlhairup, z_axis, 0, mspeed)
                Turn(tlhairup, x_axis, math.rad(-59.999996185303), 7)
                Turn(tlhairup, y_axis, math.rad(0), tspeed)
                Turn(tlhairup, z_axis, math.rad(0), tspeed)
                Move(tlhairdown, x_axis, 0, mspeed)
                Move(tlhairdown, y_axis, 0, mspeed)
                Move(tlhairdown, z_axis, 0, mspeed)
                Turn(tlhairdown, x_axis, math.rad(0), tspeed)
                Turn(tlhairdown, y_axis, math.rad(0), tspeed)
                Turn(tlhairdown, z_axis, math.rad(0), tspeed)
                Move(tlflute, x_axis, -0.3999999165535, mspeed)
                Move(tlflute, y_axis, 0.099999994039536, mspeed)
                Move(tlflute, z_axis, -5.9604644775391e-008, mspeed)
                Turn(tlflute, x_axis, math.rad(30.000001907349), tspeed)
                Turn(tlflute, y_axis, math.rad(0), tspeed)
                Turn(tlflute, z_axis, math.rad(-199.99998474121), tspeed)
                Move(tlarm, x_axis, 0, mspeed)
                Move(tlarm, y_axis, 0, mspeed)
                Move(tlarm, z_axis, 0, mspeed)
                Turn(tlarm, x_axis, math.rad(-159.99998474121), 15)
                Turn(tlarm, y_axis, math.rad(109.99998474121), 10)
                Turn(tlarm, z_axis, math.rad(0), tspeed)
             --[[   Move(tlsparksemit2, x_axis, 0, mspeed)
                Move(tlsparksemit2, y_axis, 0, mspeed)
                Move(tlsparksemit2, z_axis, 0, mspeed)
                Turn(tlsparksemit2, x_axis, math.rad(0), tspeed)
                Turn(tlsparksemit2, y_axis, math.rad(0), tspeed)
                Turn(tlsparksemit2, z_axis, math.rad(0), tspeed)--]]
                Move(tldrum, x_axis, 0, mspeed)
                Move(tldrum, y_axis, 0, mspeed)
                Move(tldrum, z_axis, 0, mspeed)
                Turn(tldrum, x_axis, math.rad(0), tspeed)
                Turn(tldrum, y_axis, math.rad(0), tspeed)
                Turn(tldrum, z_axis, math.rad(0), tspeed)
                Move(tlarmr, x_axis, 0, mspeed)
                Move(tlarmr, y_axis, 0, mspeed)
                Move(tlarmr, z_axis, 0, mspeed)
                Turn(tlarmr, x_axis, math.rad(-167.69998168945), 16)
                Turn(tlarmr, y_axis, math.rad(-99.999984741211), 10)
                Turn(tlarmr, z_axis, math.rad(10.000001907349), tspeed)
--[[                Move(tlsparksemit, x_axis, 0, mspeed)
                Move(tlsparksemit, y_axis, 0, mspeed)
                Move(tlsparksemit, z_axis, 0, mspeed)
                Turn(tlsparksemit, x_axis, math.rad(0), tspeed)
                Turn(tlsparksemit, y_axis, math.rad(0), tspeed)
                Turn(tlsparksemit, z_axis, math.rad(0), tspeed)--]]
                --Move(tlharp, x_axis, 0, mspeed)
                --Move(tlharp, y_axis, 0, mspeed)
                --Move(tlharp, z_axis, 0, mspeed)
                --Turn(tlharp, x_axis, math.rad(0), tspeed)
                --Turn(tlharp, y_axis, math.rad(0), tspeed)
                --Turn(tlharp, z_axis, math.rad(0), tspeed)
                Move(tllegUp, x_axis, 0, mspeed)
                Move(tllegUp, y_axis, 0, mspeed)
                Move(tllegUp, z_axis, 0, mspeed)
                Turn(tllegUp, x_axis, math.rad(0), tspeed)
                Turn(tllegUp, y_axis, math.rad(0), tspeed)
                Turn(tllegUp, z_axis, math.rad(0), tspeed)
                Move(tllegLow, x_axis, 0, mspeed)
                Move(tllegLow, y_axis, 0, mspeed)
                Move(tllegLow, z_axis, 0, mspeed)
                Turn(tllegLow, x_axis, math.rad(0), tspeed)
                Turn(tllegLow, y_axis, math.rad(0), tspeed)
                Turn(tllegLow, z_axis, math.rad(0), tspeed)
                Move(tllegUpR, x_axis, 0, mspeed)
                Move(tllegUpR, y_axis, 0, mspeed)
                Move(tllegUpR, z_axis, 0, mspeed)
                Turn(tllegUpR, x_axis, math.rad(0), tspeed)
                Turn(tllegUpR, y_axis, math.rad(0), tspeed)
                Turn(tllegUpR, z_axis, math.rad(0), tspeed)
                Move(tllegLowR, x_axis, 0, mspeed)
                Move(tllegLowR, y_axis, 0, mspeed)
                Move(tllegLowR, z_axis, 0, mspeed)
                Turn(tllegLowR, x_axis, math.rad(0), tspeed)
                Turn(tllegLowR, y_axis, math.rad(0), tspeed)
                Turn(tllegLowR, z_axis, math.rad(0), tspeed)
                iWantRand = math.random(400, 1200)

                Sleep(iWantRand)
                ranZig = math.random(0, 1)
                if ranzig == 1 then
                    --down
                    Move(deathpivot, x_axis, 0, mspeed)

                    Move(tigLil, x_axis, 0, mspeed)
                    Move(tigLil, y_axis, 0, mspeed)
                    Move(tigLil, z_axis, 0, mspeed)
                    Turn(tigLil, x_axis, math.rad(20), tspeed)
                    Turn(tigLil, y_axis, math.rad(0), tspeed)
                    Turn(tigLil, z_axis, math.rad(0), tspeed)
                    Move(tlHead, x_axis, 0, mspeed)
                    Move(tlHead, y_axis, 0, mspeed)
                    Move(tlHead, z_axis, 0, mspeed)
                    Turn(tlHead, x_axis, math.rad(20.000001907349), tspeed)
                    Turn(tlHead, y_axis, math.rad(0), tspeed)
                    Turn(tlHead, z_axis, math.rad(0), tspeed)
                    Move(tlhairup, x_axis, 0, mspeed)
                    Move(tlhairup, y_axis, 0, mspeed)
                    Move(tlhairup, z_axis, 0, mspeed)
                    Turn(tlhairup, x_axis, math.rad(-89.999992370605), tspeed)
                    Turn(tlhairup, y_axis, math.rad(0), tspeed)
                    Turn(tlhairup, z_axis, math.rad(0), tspeed)
                    Move(tlhairdown, x_axis, 0, mspeed)
                    Move(tlhairdown, y_axis, 0, mspeed)
                    Move(tlhairdown, z_axis, 0, mspeed)
                    Turn(tlhairdown, x_axis, math.rad(-30.000001907349), tspeed)
                    Turn(tlhairdown, y_axis, math.rad(0), tspeed)
                    Turn(tlhairdown, z_axis, math.rad(0), tspeed)
                    Move(tlflute, x_axis, -0.3999999165535, mspeed)
                    Move(tlflute, y_axis, 0.099999994039536, mspeed)
                    Move(tlflute, z_axis, -5.9604644775391e-008, mspeed)
                    Turn(tlflute, x_axis, math.rad(30.000001907349), tspeed)
                    Turn(tlflute, y_axis, math.rad(0), tspeed)
                    Turn(tlflute, z_axis, math.rad(-199.99998474121), 20)
                    Move(tlarm, x_axis, 0, mspeed)
                    Move(tlarm, y_axis, 0, mspeed)
                    Move(tlarm, z_axis, 0, mspeed)
                    Turn(tlarm, x_axis, math.rad(-159.99998474121), 15)
                    Turn(tlarm, y_axis, math.rad(116.99997711182), 11)
                    Turn(tlarm, z_axis, math.rad(-9), tspeed)

                    Move(tldrum, x_axis, 0, mspeed)
                    Move(tldrum, y_axis, 0, mspeed)
                    Move(tldrum, z_axis, 0, mspeed)
                    Turn(tldrum, x_axis, math.rad(0), tspeed)
                    Turn(tldrum, y_axis, math.rad(0), tspeed)
                    Turn(tldrum, z_axis, math.rad(0), tspeed)
                    Move(tlarmr, x_axis, 0, mspeed)
                    Move(tlarmr, y_axis, 0, mspeed)
                    Move(tlarmr, z_axis, 0, mspeed)
                    Turn(tlarmr, x_axis, math.rad(-157.69998168945), 15)
                    Turn(tlarmr, y_axis, math.rad(-103.99999237061), 10)
                    Turn(tlarmr, z_axis, math.rad(18), tspeed)

                    --Move(tlharp, x_axis, 0, mspeed)
                    --Move(tlharp, y_axis, 0, mspeed)
                    --Move(tlharp, z_axis, 0, mspeed)
                    --Turn(tlharp, x_axis, math.rad(0), tspeed)
                    --Turn(tlharp, y_axis, math.rad(0), tspeed)
                    --Turn(tlharp, z_axis, math.rad(0), tspeed)
                    Move(tllegUp, x_axis, 0, mspeed)
                    Move(tllegUp, y_axis, 0, mspeed)
                    Move(tllegUp, z_axis, 0, mspeed)
                    Turn(tllegUp, x_axis, math.rad(-10), tspeed)
                    Turn(tllegUp, y_axis, math.rad(0), tspeed)
                    Turn(tllegUp, z_axis, math.rad(0), tspeed)
                    Move(tllegLow, x_axis, 0, mspeed)
                    Move(tllegLow, y_axis, 0, mspeed)
                    Move(tllegLow, z_axis, 0, mspeed)
                    Turn(tllegLow, x_axis, math.rad(0), tspeed)
                    Turn(tllegLow, y_axis, math.rad(0), tspeed)
                    Turn(tllegLow, z_axis, math.rad(0), tspeed)
                    Move(tllegUpR, x_axis, 0, mspeed)
                    Move(tllegUpR, y_axis, 0, mspeed)
                    Move(tllegUpR, z_axis, 0, mspeed)
                    Turn(tllegUpR, x_axis, math.rad(-20), tspeed)
                    Turn(tllegUpR, y_axis, math.rad(0), tspeed)
                    Turn(tllegUpR, z_axis, math.rad(0), tspeed)
                    Move(tllegLowR, x_axis, 0, mspeed)
                    Move(tllegLowR, y_axis, 0, mspeed)
                    Move(tllegLowR, z_axis, 0, mspeed)
                    Turn(tllegLowR, x_axis, math.rad(0), tspeed)
                    Turn(tllegLowR, y_axis, math.rad(0), tspeed)
                    Turn(tllegLowR, z_axis, math.rad(0), tspeed)
                end
                if ranzig == 0 then
                    --up


                    Turn(tigLil, x_axis, math.rad(10.000001907349), tspeed)
                    Turn(tigLil, y_axis, math.rad(0), tspeed)
                    Turn(tigLil, z_axis, math.rad(0), tspeed)
                    Move(tlHead, x_axis, 0, mspeed)
                    Move(tlHead, y_axis, 0, mspeed)
                    Move(tlHead, z_axis, 0, mspeed)
                    Turn(tlHead, x_axis, math.rad(-49.999996185303), tspeed)
                    Turn(tlHead, y_axis, math.rad(0), tspeed)
                    Turn(tlHead, z_axis, math.rad(0), tspeed)
                    Move(tlhairup, x_axis, 0, mspeed)
                    Move(tlhairup, y_axis, 0, mspeed)
                    Move(tlhairup, z_axis, 0, mspeed)
                    Turn(tlhairup, x_axis, math.rad(9.9999980926514), tspeed)
                    Turn(tlhairup, y_axis, math.rad(10), tspeed)
                    Turn(tlhairup, z_axis, math.rad(10), tspeed)
                    Move(tlhairdown, x_axis, 0, mspeed)
                    Move(tlhairdown, y_axis, 0, mspeed)
                    Move(tlhairdown, z_axis, 0, mspeed)
                    Turn(tlhairdown, x_axis, math.rad(-30.000001907349), tspeed)
                    Turn(tlhairdown, y_axis, math.rad(0), tspeed)
                    Turn(tlhairdown, z_axis, math.rad(0), tspeed)
                    Move(tlflute, x_axis, -0.3999999165535, mspeed)
                    Move(tlflute, y_axis, 0.099999994039536, mspeed)
                    Move(tlflute, z_axis, -5.9604644775391e-008, mspeed)
                    Turn(tlflute, x_axis, math.rad(30.000001907349), tspeed)
                    Turn(tlflute, y_axis, math.rad(0), tspeed)
                    Turn(tlflute, z_axis, math.rad(-199.99998474121), 20)
                    Move(tlarm, x_axis, 0, mspeed)
                    Move(tlarm, y_axis, 0, mspeed)
                    Move(tlarm, z_axis, 0, mspeed)
                    Turn(tlarm, x_axis, math.rad(-159.99998474121), 16) --159
                    Turn(tlarm, y_axis, math.rad(86.999984741211), tspeed)
                    Turn(tlarm, z_axis, math.rad(41), tspeed)
                   --[[ Move(tlsparksemit2, x_axis, 0, mspeed)
                    Move(tlsparksemit2, y_axis, 0, mspeed)
                    Move(tlsparksemit2, z_axis, 0, mspeed)
                    Turn(tlsparksemit2, x_axis, math.rad(0), tspeed)
                    Turn(tlsparksemit2, y_axis, math.rad(0), tspeed)
                    Turn(tlsparksemit2, z_axis, math.rad(0), tspeed)--]]
                    Move(tldrum, x_axis, 0, mspeed)
                    Move(tldrum, y_axis, 0, mspeed)
                    Move(tldrum, z_axis, 0, mspeed)
                    Turn(tldrum, x_axis, math.rad(0), tspeed)
                    Turn(tldrum, y_axis, math.rad(0), tspeed)
                    Turn(tldrum, z_axis, math.rad(0), tspeed)
                    Move(tlarmr, x_axis, 0, mspeed)
                    Move(tlarmr, y_axis, 0, mspeed)
                    Move(tlarmr, z_axis, 0, mspeed)
                    Turn(tlarmr, x_axis, math.rad(-167.69998168945), 16)
                    Turn(tlarmr, y_axis, math.rad(-93.999992370605), 10)
                    Turn(tlarmr, z_axis, math.rad(-41.999996185303), 4)
                   --[[ Move(tlsparksemit, x_axis, 0, mspeed)
                    Move(tlsparksemit, y_axis, 0, mspeed)
                    Move(tlsparksemit, z_axis, 0, mspeed)
                    Turn(tlsparksemit, x_axis, math.rad(0), tspeed)
                    Turn(tlsparksemit, y_axis, math.rad(0), tspeed)
                    Turn(tlsparksemit, z_axis, math.rad(0), tspeed)--]]
                    --Move(tlharp, x_axis, 0, mspeed)
                    --Move(tlharp, y_axis, 0, mspeed)
                    --Move(tlharp, z_axis, 0, mspeed)
                    --Turn(tlharp, x_axis, math.rad(0), tspeed)
                    --Turn(tlharp, y_axis, math.rad(0), tspeed)
                    --Turn(tlharp, z_axis, math.rad(0), tspeed)
                    Move(tllegUp, x_axis, 0, mspeed)
                    Move(tllegUp, y_axis, 0, mspeed)
                    Move(tllegUp, z_axis, 0, mspeed)
                    Turn(tllegUp, x_axis, math.rad(0), tspeed)
                    Turn(tllegUp, y_axis, math.rad(0), tspeed)
                    Turn(tllegUp, z_axis, math.rad(0), tspeed)
                    Move(tllegLow, x_axis, 0, mspeed)
                    Move(tllegLow, y_axis, 0, mspeed)
                    Move(tllegLow, z_axis, 0, mspeed)
                    Turn(tllegLow, x_axis, math.rad(0), tspeed)
                    Turn(tllegLow, y_axis, math.rad(0), tspeed)
                    Turn(tllegLow, z_axis, math.rad(0), tspeed)
                    Move(tllegUpR, x_axis, 0, mspeed)
                    Move(tllegUpR, y_axis, 0, mspeed)
                    Move(tllegUpR, z_axis, 0, mspeed)
                    Turn(tllegUpR, x_axis, math.rad(-10), tspeed)
                    Turn(tllegUpR, y_axis, math.rad(0), tspeed)
                    Turn(tllegUpR, z_axis, math.rad(0), tspeed)
                    Move(tllegLowR, x_axis, 0, mspeed)
                    Move(tllegLowR, y_axis, 0, mspeed)
                    Move(tllegLowR, z_axis, 0, mspeed)
                    Turn(tllegLowR, x_axis, math.rad(0), tspeed)
                    Turn(tllegLowR, y_axis, math.rad(0), tspeed)
                    Turn(tllegLowR, z_axis, math.rad(0), tspeed)
                    anotherRandomSleepVal = math.random(600, 1200)
                    Sleep(anotherRandomSleepVal)
                end
            end

            HideReg(tlflute)
        end
    end

    if rand == 2 then
        --harp a darp
--        ShowReg(tlharp)
        mspeed = 5
        tspeed = 0.5

        Move(tigLil, x_axis, 0, mspeed)
        Move(tigLil, y_axis, -7.2999997138977, mspeed)
        Move(tigLil, z_axis, 0, mspeed)
        Turn(tigLil, x_axis, math.rad(3.9999983310699), tspeed)
        Turn(tigLil, y_axis, math.rad(-20.999990463257), tspeed)
        Turn(tigLil, z_axis, math.rad(-4), tspeed)
        Move(tlHead, x_axis, 0, mspeed)
        Move(tlHead, y_axis, 0, mspeed)
        Move(tlHead, z_axis, 0, mspeed)
        Turn(tlHead, x_axis, math.rad(10), tspeed)
        Turn(tlHead, y_axis, math.rad(30.000001907349), tspeed)
        Turn(tlHead, z_axis, math.rad(0), tspeed)
        Move(tlhairup, x_axis, 0, mspeed)
        Move(tlhairup, y_axis, 0, mspeed)
        Move(tlhairup, z_axis, 0, mspeed)
        Turn(tlhairup, x_axis, math.rad(-87.999992370605), tspeed)
        Turn(tlhairup, y_axis, math.rad(0), tspeed)
        Turn(tlhairup, z_axis, math.rad(0), tspeed)
        Move(tlhairdown, x_axis, 0, mspeed)
        Move(tlhairdown, y_axis, 0, mspeed)
        Move(tlhairdown, z_axis, 0, mspeed)
        Turn(tlhairdown, x_axis, math.rad(0), tspeed)
        Turn(tlhairdown, y_axis, math.rad(0), tspeed)
        Turn(tlhairdown, z_axis, math.rad(0), tspeed)
        Move(tlflute, x_axis, 0, mspeed)
        Move(tlflute, y_axis, 0, mspeed)
        Move(tlflute, z_axis, 0, mspeed)
        Turn(tlflute, x_axis, math.rad(0), tspeed)
        Turn(tlflute, y_axis, math.rad(0), tspeed)
        Turn(tlflute, z_axis, math.rad(0), tspeed)

        Turn(tlarm, x_axis, math.rad(174.99989318848), tspeed)
        Turn(tlarm, y_axis, math.rad(110.99998474121), tspeed)
        Turn(tlarm, z_axis, math.rad(20), tspeed)
--[[        Move(tlsparksemit2, x_axis, 0, mspeed)
        Move(tlsparksemit2, y_axis, 0, mspeed)
        Move(tlsparksemit2, z_axis, 0, mspeed)
        Turn(tlsparksemit2, x_axis, math.rad(0), tspeed)
        Turn(tlsparksemit2, y_axis, math.rad(0), tspeed)
        Turn(tlsparksemit2, z_axis, math.rad(0), tspeed)--]]
        Move(tldrum, x_axis, 0, mspeed)
        Move(tldrum, y_axis, 0, mspeed)
        Move(tldrum, z_axis, 0, mspeed)
        Turn(tldrum, x_axis, math.rad(0), tspeed)
        Turn(tldrum, y_axis, math.rad(0), tspeed)
        Turn(tldrum, z_axis, math.rad(0), tspeed)
        Move(tlarmr, x_axis, 0, mspeed)
        Move(tlarmr, y_axis, 0, mspeed)
        Move(tlarmr, z_axis, 0, mspeed)
        Turn(tlarmr, x_axis, math.rad(-10.000008583069), tspeed)
        Turn(tlarmr, y_axis, math.rad(-99.999984741211), tspeed)
        Turn(tlarmr, z_axis, math.rad(-10), tspeed)

        --Move(tlharp, x_axis, 0, mspeed)
        --Move(, y_axis, 0, mspeed)
        --Move(tlharp, z_axis, 0, mspeed)
        --Turn(tlharp, x_axis, math.rad(0), tspeed)
        --Turn(tlharp, y_axis, math.rad(0), tspeed)
        --Turn(tlharp, z_axis, math.rad(0), tspeed)
        Move(tllegUp, x_axis, 0, mspeed)
        Move(tllegUp, y_axis, 0, mspeed)
        Move(tllegUp, z_axis, 0, mspeed)
        Turn(tllegUp, x_axis, math.rad(-49.999996185303), tspeed)
        Turn(tllegUp, y_axis, math.rad(-40), tspeed)
        Turn(tllegUp, z_axis, math.rad(0), tspeed)
        Move(tllegLow, x_axis, 0, mspeed)
        Move(tllegLow, y_axis, 0, mspeed)
        Move(tllegLow, z_axis, 0, mspeed)
        Turn(tllegLow, x_axis, math.rad(129.99998474121), 22)
        Turn(tllegLow, y_axis, math.rad(0), tspeed)
        Turn(tllegLow, z_axis, math.rad(0), tspeed)
        Move(tllegUpR, x_axis, -5.9604644775391e-008, mspeed)
        Move(tllegUpR, y_axis, 0, mspeed)
        Move(tllegUpR, z_axis, 0, mspeed)
        Turn(tllegUpR, x_axis, math.rad(-59.999996185303), tspeed)
        Turn(tllegUpR, y_axis, math.rad(20), tspeed)
        Turn(tllegUpR, z_axis, math.rad(0), tspeed)
        Move(tllegLowR, x_axis, 0, mspeed)
        Move(tllegLowR, y_axis, 0, mspeed)
        Move(tllegLowR, z_axis, 0, mspeed)
        Turn(tllegLowR, x_axis, math.rad(139.99998474121), 22)
        Turn(tllegLowR, y_axis, math.rad(0), tspeed)
        Turn(tllegLowR, z_axis, math.rad(0), tspeed)
        WaitForTurn(tigLil, x_axis)
        WaitForTurn(tigLil, y_axis)
        WaitForTurn(tigLil, z_axis)
        WaitForMove(tlHead, x_axis)
        WaitForMove(tlHead, y_axis)
        WaitForMove(tlHead, z_axis)
        WaitForTurn(tlHead, x_axis)
        WaitForTurn(tlHead, y_axis)
        WaitForTurn(tlHead, z_axis)
        WaitForMove(tlhairup, x_axis)
        WaitForMove(tlhairup, y_axis)
        WaitForMove(tlhairup, z_axis)
        WaitForTurn(tlhairup, x_axis)
        WaitForTurn(tlhairup, y_axis)
        WaitForTurn(tlhairup, z_axis)
        WaitForMove(tlhairdown, x_axis)
        WaitForMove(tlhairdown, y_axis)
        WaitForMove(tlhairdown, z_axis)
        WaitForTurn(tlhairdown, x_axis)
        WaitForTurn(tlhairdown, y_axis)
        WaitForTurn(tlhairdown, z_axis)
        WaitForMove(tlflute, x_axis)
        WaitForMove(tlflute, y_axis)
        WaitForMove(tlflute, z_axis)
        WaitForTurn(tlflute, x_axis)
        WaitForTurn(tlflute, y_axis)
        WaitForTurn(tlflute, z_axis)
        WaitForMove(tlarm, x_axis)
        WaitForMove(tlarm, y_axis)
        WaitForMove(tlarm, z_axis)
        WaitForTurn(tlarm, x_axis)
        WaitForTurn(tlarm, y_axis)
        WaitForTurn(tlarm, z_axis)
--[[        WaitForMove(tlsparksemit2, x_axis)
        WaitForMove(tlsparksemit2, y_axis)
        WaitForMove(tlsparksemit2, z_axis)
        WaitForTurn(tlsparksemit2, x_axis)
        WaitForTurn(tlsparksemit2, y_axis)
        WaitForTurn(tlsparksemit2, z_axis)--]]
        WaitForMove(tldrum, x_axis)
        WaitForMove(tldrum, y_axis)
        WaitForMove(tldrum, z_axis)
        WaitForTurn(tldrum, x_axis)
        WaitForTurn(tldrum, y_axis)
        WaitForTurn(tldrum, z_axis)
        WaitForMove(tlarmr, x_axis)
        WaitForMove(tlarmr, y_axis)
        WaitForMove(tlarmr, z_axis)
        WaitForTurn(tlarmr, x_axis)
        WaitForTurn(tlarmr, y_axis)
        WaitForTurn(tlarmr, z_axis)
--[[        WaitForMove(tlsparksemit, x_axis)
        WaitForMove(tlsparksemit, y_axis)
        WaitForMove(tlsparksemit, z_axis)
        WaitForTurn(tlsparksemit, x_axis)
        WaitForTurn(tlsparksemit, y_axis)
        WaitForTurn(tlsparksemit, z_axis)--]]
        --WaitForMove(tlharp, x_axis)
        --WaitForMove(tlharp, y_axis)
        --WaitForMove(tlharp, z_axis)
        --WaitForTurn(tlharp, x_axis)
        --WaitForTurn(tlharp, y_axis)
        --WaitForTurn(tlharp, z_axis)
        WaitForMove(tllegUp, x_axis)
        WaitForMove(tllegUp, y_axis)
        WaitForMove(tllegUp, z_axis)
        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForMove(tllegLow, x_axis)
        WaitForMove(tllegLow, y_axis)
        WaitForMove(tllegLow, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        WaitForMove(tllegUpR, x_axis)
        WaitForMove(tllegUpR, y_axis)
        WaitForMove(tllegUpR, z_axis)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForMove(tllegLowR, x_axis)
        WaitForMove(tllegLowR, y_axis)
        WaitForMove(tllegLowR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        hitIt = math.floor(math.random(12, 38))
        lastSwingBy = 20
        flipFlop1 = -1
        for play = 1, hitIt, 1 do
            flipFlop1 = flipFlop1 * -1

            tspeed = (play * hitIt) % 3

            swingBy = math.floor(math.random(-40, 40))

            if swingBy > -10 and swingBy < 10 then
                swingBy = swingBy * 2
            end
            if swingBy < -12 or swingBy > 12 then
                tspeed = 3
            end

            swingBy = swingBy * flipFlop1


            Turn(tlarm, x_axis, math.rad(174.29985046387), 17)
            Turn(tlarm, y_axis, math.rad(100.69999694824), 10)
            Turn(tlarm, z_axis, math.rad(swingBy), tspeed)
            WaitForTurn(tlarm, z_axis)
            WaitForTurn(tlarm, x_axis)
            WaitForTurn(tlarm, y_axis)

            sleepingBeau = math.random(500, 960)
            Sleep(sleepingBeau)
        end
    end
    --HideReg(tlharp)
end

--feeding the horse
function idle_stance18()

  for i=1,22 do
    tP(tlHead,0,0,0,12)
    mP(tigLil,0,-11,0,12)
    tP(tigLil,-102,0,0,12)
    tP(tlhairup,0,89,-111,12)
    tP(tlhairdown,-22,0,0,12)
    --legss
    tP(tllegUp,-24, math.random(-20,30) , -1* math.random(5,21), 5)
    tP(tllegLow,114 + math.random(-5,5),0,0, 5)
    tP(tllegUpR,-24, math.random(-20,30) , -1* math.random(-5,40), 5)
    tP(tllegLowR,114 + math.random(-5,5),0,0, 5)
    --arms
    tP(tlarm,44,72, 68, 15)
    tP(tlarmr,4 ,193,-1* math.random(70,75), 15)
    
    WaitForTurns(tigLil,tlarmr,tlarm, tllegUp, tllegLow, tllegUpR, tllegLow )
    
        --up she goes
    mP(tigLil,0,-9,0,12)
    tP(tlHead,32,0,0,12)
    tP(tigLil,-119,0,0,12)
    tP(tlhairup,0,89,-111,12)
    tP(tlhairdown,-22,0,0,12)
    --legss
    tP(tllegUp,-1, math.random(-20,3) , -1* math.random(64), 5)
    tP(tllegLow,114 + math.random(-5,5),0,0, 5)
    tP(tllegUpR,-1, math.random(-20,27) ,  -1* math.random(-55,-39), 5)
    tP(tllegLowR,114 + math.random(0,20),0,0, 5)
    --arms
    tP(tlarm,20 ,-28,0, 15)
    tP(tlarmr,4 ,193,-1* math.random(70,75), 15)
    WaitForTurns(tigLil,tlarmr,tlarm, tllegUp, tllegLow, tllegUpR, tllegLow )
  end
    Sleep(500)
      for i=1,12 do
           tP(tlHead,0,0,0,12)
          mP(tigLil,0,-11,0,12)
          tP(tigLil,-102,0,0,12)
          tP(tlhairup,0,89,-111,12)
          tP(tlhairdown,-22,0,0,12)
          --legss
          tP(tllegUp,-24, math.random(-20,30) , -1* math.random(5,21), 5)
          tP(tllegLow,114 + math.random(-5,5),0,0, 5)
          tP(tllegUpR,-24, math.random(-20,30) , -1* math.random(-5,40), 5)
          tP(tllegLowR,114 + math.random(-5,5),0,0, 5)
          --arms
          tP(tlarm,44,72, 68, 15)
          tP(tlarmr,4 ,193,-1* math.random(70,75), 15)

          WaitForTurns(tigLil,tlarmr,tlarm, tllegUp, tllegLow, tllegUpR, tllegLow )
  end
    --legss
  tP(tllegUp,-1, math.random(-20,3) , -1* math.random(64), 5)
  tP(tllegLow,114 + math.random(-5,5),0,0, 5)
  tP(tllegUpR,-1, math.random(-20,27) ,  -1* math.random(-55,-39), 5)
  tP(tllegLowR,114 + math.random(0,20),0,0, 5)
  Sleep(2500)  
end

local SIG_BALL =8192
boolBallAttached = false

function attachBallToPiece(hand)
    SetSignalMask(SIG_BALL)
    
    reset(ball)
    reset(BallArcPoint)
    reset(ball)
    boolBallAttached=true
    while boolBallAttached == true do
        movePieceToPiece(unitID, ball, hand, 10 )
        Sleep(10)
    end
end

function resetBall()
    reset(DirectionArcPoint)
    reset(BallArcPoint)
    reset(ball)

end

--> Moves the ball swingcenter away from the directionrotator
function setupBallArc(distanceToGo, directionInDeg, startArcInDeg, speed)
--default resets
    distanceToGo= distanceToGo or 0
    directionInDeg = directionInDeg or 0
    startArcInDeg =  startArcInDeg or 0
    speed= speed or 0
    Move(BallArcPoint,z_axis, distanceToGo,0)
    Move(ball,z_axis, -distanceToGo,0)
    Turn(DirectionArcPoint,y_axis, math.rad(directionInDeg),0)
    Turn(BallArcPoint,x_axis, math.rad(startArcInDeg),speed)
end



ballIdleFunctions = {
[1] = function()-- catch and hold
    resetBall()
    ShowReg(ball)
    ballIdleFunctions[5]()
    tP(tlarm,0,88,22,2)
    tP(tlarmr,0,-92,-22,2)
    WaitForTurns(tlarm,tlarmr)
    Sleep(3000)
    HideReg(ball)

    end,
[2] = function()-- keep up
--Einwurf
        ballIdleFunctions[5]()
    tP(tlarm,0,88,124,2)
    tP(tlarmr,0,-92,-124,2)
    for i=1, math.random(3,10) do
    
        if math.random(0,1)==1 then
            tP(tllegUp,-82, 0, 0, 11)
            tP(tllegLow,110, 0, 0, 11)
            tP(tllegUpR, 0, 0, -9, 9)
            tP(tllegLowR, 0, 0, -9, 9)
        else
            tP(tllegUpR,-82, 0, 0, 11)
            tP(tllegLowR,110, 0, 0, 11)
            tP(tllegUp, 0, 0, -9, 9)
            tP(tllegLow, 0, 0, -9, 9)

        end
        Turn(tlHead,x_axis,math.rad(-25),5)
        WaitForTurns(tllegUp,tllegLow,tllegUpR,tllegLowR)
        tP(tllegUpR,0, 0, 0, 11/4)
        tP(tllegLowR,0, 0, 0, 11/4)
        tP(tllegUp, 0, 0, -9, 9/4)
        tP(tllegLow, 0, 0, -9, 9/4)
        Turn(tlHead,x_axis,math.rad(0),0.05)
        ballIdleFunctions[7]()
    end

    WaitForTurns(tllegUp,tllegLow,tllegUpR,tllegLowR)
    Move(DirectionArcPoint,y_axis, -5,0)
    ballIdleFunctions[6]()
    end,
[3] = function()--recive and kick it
    resetBall()
    --Einwurf   
    Move(DirectionArcPoint,y_axis, -5,0)
    ballIdleFunctions[5]()
    --kick it
    ballIdleFunctions[6]()

    resetBall()
    HideReg(ball)
end,
[4] = function()--volley
    resetBall()

    value=math.random(10,90)
    arcLength=math.random(45,180)
    arcDir = math.random(-35,35)
    setupBallArc(value, arcDir, arcLength)
    ShowReg(ball)
    tP(tlarm,0,88,54,2)
    tP(tlarmr,0,-92,-52,2)
    WTurn(BallArcPoint,x_axis, math.rad(0),0.981)
    tP(tlarm,0,88,-54,8)
    tP(tlarmr,0,-92, 52,8)
    setupBallArc(value, arcDir *-1, 0)
    WTurn(BallArcPoint,x_axis, math.rad(arcLength),1.981)
    resetBall() 
    end,
    [5] = function () --Einwurf
        value=math.random(10,90)
        arcLength=math.random(45,180)
        arcDir = math.random(-35,35)
        setupBallArc(value, arcDir, arcLength)
        ShowReg(ball)
        WTurn(BallArcPoint,x_axis, math.rad(0),0.981)   
    end,
    [6] = function() -- kick ball
        tP(tllegUpR,-45,0,0,4)
        WaitForTurns(tllegUpR)  
        tP(tllegUpR,0,0,0,10)
        WaitForTurns(tllegUpR)
        tP(tlarm,0,0,54,8)
        tP(tlarmr,0,0, -52,8)
        tP(tllegUpR,15,0,0,17)
        WaitForTurns(tllegUpR)
        tP(tllegUpR,0,0,0,17)
        WMove(ball,z_axis, 80, 82)
        WMove(ball,z_axis, 90, 42)
        WMove(ball,z_axis, 100, 22)
    end,
    [7] = function() -- Move Ball Up
        heigth= math.random(50,75)
        for i=1, heigth do
            WMove(ball,y_axis, i, 15 + 82/math.sqrt(i/4))
        end
        for i=heigth, 15, -1 do
            WMove(ball,y_axis, i, math.max(0,math.min(81,i*6)))
        end
        Move(ball,y_axis, 0, 80)
    end
    
}


local function idle_playBall()
    ballDice = math.random(1,4)
    ballIdleFunctions[ballDice]()
    legs_down()
    resetBall()
    HideReg(ball)
end
--eggspawn --tigLil and SkinFantry


function Setup()
    HideReg(tlpole)
    HideReg(deathpivot)
    HideReg(tldrum)
    --HideReg(tlharp)
    HideReg(tlflute)
    HideReg(ball)
    HideReg(handr)
    HideReg(handl)
end

function tradWalk()

        -- Rightback

        Turn(tllegUpR, x_axis, math.rad(21), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(12), 4)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)

        Turn(tllegUp, x_axis, math.rad(-22), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(0), 2)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tigLil, y_axis, math.rad(-2), 1)
        Turn(tigLil, z_axis, math.rad(3), 1)
        WaitForTurn(tigLil, y_axis)
        Sleep(75)
        boolMove = true
        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)

        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)


        Turn(tllegUp, x_axis, math.rad(21), 2)
        Turn(tllegUp, y_axis, math.rad(0), 3)
        Turn(tllegUp, z_axis, math.rad(0), 3)
        Turn(tllegLow, x_axis, math.rad(12), 4)
        Turn(tllegLow, y_axis, math.rad(0), 3)
        Turn(tllegLow, z_axis, math.rad(0), 3)

        Turn(tllegUpR, x_axis, math.rad(-22), 2)
        Turn(tllegUpR, y_axis, math.rad(0), 3)
        Turn(tllegUpR, z_axis, math.rad(0), 3)
        Turn(tllegLowR, x_axis, math.rad(0), 2)
        Turn(tllegLowR, y_axis, math.rad(0), 3)
        Turn(tllegLowR, z_axis, math.rad(0), 3)
        Turn(tigLil, y_axis, math.rad(3), 1)
        Turn(tigLil, z_axis, math.rad(-4), 1)
        WaitForTurn(tigLil, y_axis)



        WaitForTurn(tigLil, z_axis)

        WaitForTurn(tllegUp, x_axis)
        WaitForTurn(tllegUp, y_axis)
        WaitForTurn(tllegUp, z_axis)
        WaitForTurn(tllegLow, x_axis)
        WaitForTurn(tllegLow, y_axis)
        WaitForTurn(tllegLow, z_axis)
        Sleep(65)
        WaitForTurn(tllegUpR, x_axis)
        WaitForTurn(tllegUpR, y_axis)
        WaitForTurn(tllegUpR, z_axis)
        WaitForTurn(tllegLowR, x_axis)
        WaitForTurn(tllegLowR, y_axis)
        WaitForTurn(tllegLowR, z_axis)
        Signal(SIG_WHIR)

end

function shakeWalk()

        -- Rightback

        tSyncIn(tlHead, 0,0,14,314)
        tSyncIn(tllegUpR, -23,0,8,314)
        tSyncIn(tllegLowR,6,0,0,314)
        tSyncIn(tllegUp,7,0, 27,314)       
        tSyncIn(tllegLow,12,0,0,314)
        tSyncIn(tigLil,0,0,-18,314)
        
        boolMove = true
        WaitForTurns(tigLil,tllegUp,tllegLow,tllegUpR,tllegLowR)
        
        tSyncIn(tlHead, 0,0,-16,314)
        tSyncIn(tllegUpR, 19,0,-29,314)
        tSyncIn(tllegLowR,6,0,0,314)
        tSyncIn(tllegUp,-28,0, -13,314)       
        tSyncIn(tllegLow,27,0,0,314)
        tSyncIn(tigLil,0,0,17,314)
        WaitForTurns(tigLil,tllegUp,tllegLow,tllegUpR,tllegLowR)

        Signal(SIG_WHIR)

end

--- WALKING -
function walk()
    HideReg(tldrum)
    HideReg(tlflute)
    --HideReg(tlharp)
    --HideReg(tldancedru)

    dice= math.random(0,40)

    legs_down()

    Signal(SIG_ONTHEMOVE)
    Signal(SIG_SWING)
    Signal(SIG_ONTHEMOVE)
    Signal(SIG_INCIRCLE)
    if (Sleeper == 1 or Sleeper == 8) then
        StartThread(armswing)
    end

    SetSignalMask(SIG_WALK)
    while (true) do
        if dice < 30 then
            tradWalk()
        else
            shakeWalk()
        end
    end
end


function hairInWind(offset)
    Signal(SIG_HAIR)
    SetSignalMask(SIG_HAIR)
    auslenkung= math.random(20,35)
    while true do
        TurnTowardsWind(tlhairup, math.pi, 50)
        sinA= (((spGetGameFrame())%60)/60)* 2*math.pi
    
        sinA,saint = math.sin(sinA)*auslenkung,math.sin(sinA+math.pi/8)*auslenkung
        Turn(tlhairup,x_axis,math.rad(sinA+offset), 50)
        Turn(tlhairdown,x_axis,math.rad(saint), 50)
        WaitForTurns(tlhairup,tlhairdown)
        Sleep(1)
    end
end

local poseFunction={
    function()
        mSyncIn(tigLil,0,-6,0,550)
        StartThread(hairInWind,-45)
        tSyncIn(tlHead,45,0,0,550)
        tSyncIn(tlarm,23,0,80,550)
        tSyncIn(tlarmr,-34,0,-84,550)
        tSyncIn(tllegUp,-79,0,0,550)
        tSyncIn(tllegLow,94,0,0,550)
        tSyncIn(tllegUpR,-21,0,0,550)
        tSyncIn(tllegLowR,104,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,    
    function()
        mSyncIn(tigLil,0,0,0,550)
        StartThread(hairInWind,0)
        tSyncIn(tlHead,0,0,0,550)
        tSyncIn(tlarm,28,0,101,550)
        tSyncIn(tlarmr,29,0,-98,550)
        tSyncIn(tllegUp,0,0,0,550)
        tSyncIn(tllegLow,0,0,0,550)
        tSyncIn(tllegUpR,-12,0,0,550)
        tSyncIn(tllegLowR,24,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,    
    function()
        mSyncIn(tigLil,0,-11,0,550)
        StartThread(hairInWind,28)
        tSyncIn(tigLil,40,0,0,550)
        tSyncIn(tlHead,-28,0,0,550)
        tSyncIn(tlarm,-128,0,101,550)
        tSyncIn(tlarmr,-127,0,-98,550)
        tSyncIn(tllegUp,49,0,0,550)
        tSyncIn(tllegLow,0,0,0,550)
        tSyncIn(tllegUpR,49,0,0,550)
        tSyncIn(tllegLowR,0,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,    
    function()
        mSyncIn(tigLil,0,-10.5,0,550)
        StartThread(hairInWind,-7)
        tSyncIn(tigLil,11,0,0,550)
        tSyncIn(tlHead,7,0,0,550)
        tSyncIn(tlarm,176,98,-19,550)
        tSyncIn(tlarmr,177,-96,21,550)
        tSyncIn(tllegUp,-138,0,6,550)
        tSyncIn(tllegLow,107,0,0,550)
        tSyncIn(tllegUpR,-138,0,-13,550)
        tSyncIn(tllegLowR,107,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,}

local technoPosesFunction={
    function()
        mSyncIn(tigLil,0,-6,0,550)
        StartThread(hairInWind,0)
        tSyncIn(tlHead,0,0,0,550)
        tSyncIn(tlarm,0,-60,90,550)
        tSyncIn(tlarmr,0,80,90,550)
        tSyncIn(tllegUp,0,0,0,550)
        tSyncIn(tllegLow,0,0,0,550)
        tSyncIn(tllegUpR,0,0,0,550)
        tSyncIn(tllegLowR,0,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,
    function()
        mSyncIn(tigLil,0,12,0,550)
        StartThread(hairInWind,0)
        tSyncIn(tlHead,0,0,0,550)
        tSyncIn(tlarm,0,60,90,550)
        tSyncIn(tlarmr,0,-80,90,550)
        tSyncIn(tllegUp,0,0,0,550)
        tSyncIn(tllegLow,0,0,0,550)
        tSyncIn(tllegUpR,0,0,0,550)
        tSyncIn(tllegLowR,0,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,
    function()
        mSyncIn(tigLil,0,-6,0,550)
        StartThread(hairInWind,0)
        tSyncIn(tlHead,0,0,0,550)
        tSyncIn(tlarm,0,-80,90,550)
        tSyncIn(tlarmr,0,80,90,550)
        tSyncIn(tllegUp,0,0,0,550)
        tSyncIn(tllegLow,0,0,0,550)
        tSyncIn(tllegUpR,0,0,0,550)
        tSyncIn(tllegLowR,0,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,
    function()
        mSyncIn(tigLil,0,12,0,550)
        StartThread(hairInWind,0)
        tSyncIn(tlHead,0,0,0,550)
        tSyncIn(tlarm,-90,0,15,550)
        tSyncIn(tlarmr,90,-180,-15,550)
        tSyncIn(tllegUp,0,0,0,550)
        tSyncIn(tllegLow,0,0,0,550)
        tSyncIn(tllegUpR,0,0,0,550)
        tSyncIn(tllegLowR,0,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,
    function()
        upDown= math.random(8,12)*randSign()
        mSyncIn(tigLil,0,12,0,550)
        lookDir = math.random(-45,45)
        StartThread(hairInWind,lookDir)
        tSyncIn(tlHead,0,lookDir,0,550)   
        lVal= math.random(0,10)    
        tSyncIn(tllegUp,-lVal,0,0,550)
        tSyncIn(tllegLow,lVal,0,0,550)
        rVal= math.random(0,10)   
        tSyncIn(tllegUpR,-rVal,0,0,550)
        tSyncIn(tllegLowR,rVal,0,0,550)
        WaitForMoves(tigLil)
        WaitForTurns(deathpivot,tigLil,tllegUp,tllegLow,tllegUpR,tllegLow,tlarm,tlarmr,tlHead,tlhairup,tlhairdown)
    end,
}

function strikeAPose(boolTechno)
    strikePosFunction = poseFunction
    if boolTechno then
        strikePosFunction = technoPosesFunction
    end
    poseSelector=math.random(1,#strikePosFunction)
    strikePosFunction[poseSelector]()
    time = math.random(15,40)*1000
    if boolTechno then
        time = 1000
    end
    Sleep(time)
    Signal(SIG_HAIR)
end


function waitPosition()
    Signal(SIG_IDLE)

    Move(tigLil, z_axis, -21, 7)
    Turn(tllegUpR, x_axis, math.rad(21), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(12), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)

    Turn(tllegUp, x_axis, math.rad(-22), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tigLil, y_axis, math.rad(-2), 1)
    Turn(tigLil, z_axis, math.rad(3), 1)
    WaitForTurn(tigLil, y_axis)
    Sleep(75)

    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)


    Turn(tllegUp, x_axis, math.rad(21), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    --Turn(tllegLow,x_axis,math.rad(12),2)
    Turn(tllegLow, x_axis, math.rad(12), 4)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tllegUpR, x_axis, math.rad(-22), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 2)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tigLil, y_axis, math.rad(3), 1)
    Turn(tigLil, z_axis, math.rad(-4), 1)
    WaitForTurn(tigLil, y_axis)



    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    Sleep(65)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    Turn(tllegUpR, x_axis, math.rad(21), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(12), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)

    Turn(tllegUp, x_axis, math.rad(-22), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tigLil, y_axis, math.rad(-2), 1)
    Turn(tigLil, z_axis, math.rad(3), 1)
    WaitForTurn(tigLil, y_axis)
    Sleep(75)

    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)


    Turn(tllegUp, x_axis, math.rad(21), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    --Turn(tllegLow,x_axis,math.rad(12),2)
    Turn(tllegLow, x_axis, math.rad(12), 4)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tllegUpR, x_axis, math.rad(-22), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 2)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tigLil, y_axis, math.rad(3), 1)
    Turn(tigLil, z_axis, math.rad(-4), 1)
    WaitForTurn(tigLil, y_axis)



    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    Sleep(65)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    Turn(tllegUpR, x_axis, math.rad(21), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(12), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)

    Turn(tllegUp, x_axis, math.rad(-22), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tigLil, y_axis, math.rad(-2), 1)
    Turn(tigLil, z_axis, math.rad(3), 1)
    WaitForTurn(tigLil, y_axis)
    Sleep(75)

    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)


    Turn(tllegUp, x_axis, math.rad(21), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    --Turn(tllegLow,x_axis,math.rad(12),2)
    Turn(tllegLow, x_axis, math.rad(12), 4)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tllegUpR, x_axis, math.rad(-22), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 2)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tigLil, y_axis, math.rad(3), 1)
    Turn(tigLil, z_axis, math.rad(-4), 1)
    WaitForTurn(tigLil, y_axis)



    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)
    Sleep(65)
    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)
    WaitForMove(tigLil, z_axis)
    Move(tigLil, z_axis, -12, 5)
    Turn(tllegUpR, x_axis, math.rad(21), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(12), 4)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)

    Turn(tllegUp, x_axis, math.rad(-22), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    Turn(tllegLow, x_axis, math.rad(0), 2)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tigLil, y_axis, math.rad(-2), 1)
    Turn(tigLil, z_axis, math.rad(3), 1)
    WaitForTurn(tigLil, y_axis)
    Sleep(75)

    WaitForTurn(tigLil, z_axis)

    WaitForTurn(tllegUp, x_axis)
    WaitForTurn(tllegUp, y_axis)
    WaitForTurn(tllegUp, z_axis)
    WaitForTurn(tllegLow, x_axis)
    WaitForTurn(tllegLow, y_axis)
    WaitForTurn(tllegLow, z_axis)

    WaitForTurn(tllegUpR, x_axis)
    WaitForTurn(tllegUpR, y_axis)
    WaitForTurn(tllegUpR, z_axis)
    WaitForTurn(tllegLowR, x_axis)
    WaitForTurn(tllegLowR, y_axis)
    WaitForTurn(tllegLowR, z_axis)


    Turn(tllegUp, x_axis, math.rad(21), 2)
    Turn(tllegUp, y_axis, math.rad(0), 3)
    Turn(tllegUp, z_axis, math.rad(0), 3)
    --Turn(tllegLow,x_axis,math.rad(12),2)
    Turn(tllegLow, x_axis, math.rad(12), 4)
    Turn(tllegLow, y_axis, math.rad(0), 3)
    Turn(tllegLow, z_axis, math.rad(0), 3)

    Turn(tllegUpR, x_axis, math.rad(-22), 2)
    Turn(tllegUpR, y_axis, math.rad(0), 3)
    Turn(tllegUpR, z_axis, math.rad(0), 3)
    Turn(tllegLowR, x_axis, math.rad(0), 2)
    Turn(tllegLowR, y_axis, math.rad(0), 3)
    Turn(tllegLowR, z_axis, math.rad(0), 3)
    Turn(tigLil, y_axis, math.rad(3), 1)
    Turn(tigLil, z_axis, math.rad(-4), 1)
    WaitForTurn(tigLil, y_axis)
end


idleAnimations[#idleAnimations +1] = idle_stance
idleAnimations[#idleAnimations +1] = idle_stance2
idleAnimations[#idleAnimations +1] = idle_stance3
idleAnimations[#idleAnimations +1] = idle_stance4
idleAnimations[#idleAnimations +1] = idle_stance5
idleAnimations[#idleAnimations +1] = idle_stance6
idleAnimations[#idleAnimations +1] = idle_stance7
idleAnimations[#idleAnimations +1] = idle_stance8
idleAnimations[#idleAnimations +1] = idle_stance9
idleAnimations[#idleAnimations +1] = idle_stance_10
idleAnimations[#idleAnimations +1] = idle_stance11
idleAnimations[#idleAnimations +1] = idle_stance_12
idleAnimations[#idleAnimations +1] = idle_stance13
idleAnimations[#idleAnimations +1] = idle_stance14
idleAnimations[#idleAnimations +1] = idle_stance15
idleAnimations[#idleAnimations +1] = idle_playBall
idleAnimations[#idleAnimations +1] = idle_stance18
idleAnimations[#idleAnimations +1] = idle_stance17
idleAnimations[#idleAnimations +1] = strikeAPose

technoAnimations[#technoAnimations +1] = strikeAPose
technoAnimations[#technoAnimations +1] = idle_stance_10
technoAnimations[#technoAnimations +1] = idle_stance
                


