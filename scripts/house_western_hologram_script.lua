include "lib_OS.lua"
include "lib_textFx.lua"
include "lib_mosaic.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"


myDefID = Spring.GetUnitDefID(unitID)
local boolIsCasino    = UnitDefNames["house_western_hologram_casino"].id == myDefID
local boolIsBrothel   = UnitDefNames["house_western_hologram_brothel"].id == myDefID
local boolIsBuisness  = UnitDefNames["house_western_hologram_buisness"].id == myDefID 

local creditNeonSigns =  include('creditNamesNeonLogos.lua')
local casinoNamesNeonSigns = include('casinoNamesNeonLogos.lua')
local buisnessNeonSigns =  include('buissnesNamesNeonLogos.lua')
local sloganNamesNeonSigns = include('SlogansNewsNeonLogos.lua')
local brothelsloganNamesNeonSigns = include('SloganBrothelNeonLogos.lua')
local restaurantNeonLogos = include('restaurantNeonLogos.lua')
civilianTypeTable = getCivilianTypeTable(UnitDefs)
local hours  =0
local minutes=0
local seconds=0
local percent=0
hours, minutes, seconds, percent = getDayTime()



function hashMaRa()
    return getLocationHash(unitID) % 2 == 0
end

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
boolIsRestaurant = false
textSpinner =  piece("text_spin")
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
local SIG_FLICKER= 256
local GameConfig = getGameConfig()
local pieceID_NameMap = Spring.GetUnitPieceList(unitID)
local cachedCopy ={}
local lastFrame = Spring.GetGameFrame()

function updateCheckCache()
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

function ShowReg(pieceID)
    if not pieceID then return end
    Show(pieceID)
    cachedCopy[pieceID] = pieceID
    updateCheckCache()
end

function HideReg(pieceID)
    if not pieceID then return end
    
    Hide(pieceID)  
    --TODO make dictionary for efficiency
    cachedCopy[pieceID] = nil
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
        for ik = l_upLimit, l_lowLimit, -1 do
            if l_tableName[ik] then
                HideReg(l_tableName[ik])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. l_lowLimit ..
                         " contains a empty entry")
            end

            if l_delay and l_delay > 0 then Sleep(l_delay) end
        end

    else
        for ik = 1, table.getn(l_tableName), 1 do
            if l_tableName[ik] then
                HideReg(l_tableName[ik])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. l_lowLimit .. " contains a empty entry")
            end
        end
    end
end

-- >ShowsStupid question.. i want to merge two script files before they are parsed : VFS.Include("scripts/tigLilAnimation.lua", nil, VFS.ZIP_FIRST) should do that?  As in the code within the file is available to functions below the line and can use functions above the line? a Pieces Table
function showTReg(l_tableName, l_lowLimit, l_upLimit, l_delay) 
    assert(l_tableName)
    if not l_tableName then
        Spring.Echo("No table given as argument for showT")
        assert(false)
        return
    end

    if l_lowLimit and l_upLimit then
        for ij = l_lowLimit, l_upLimit, 1 do
            if l_tableName[i] then ShowReg(l_tableName[ij]) end
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


include ("tigLilAnimation.lua")
include("lib_textFx.lua")
local function tiglLilLoop()
    if unitID % 5 ~= 0 then return end
    if not GG.TiglilHoloTable then GG.TiglilHoloTable = {} end
    if count(GG.TiglilHoloTable) > 3 and not GG.TiglilHoloTable[unitID]  then  return end

    GG.TiglilHoloTable[unitID] = unitID

    while true do
        if (hours > 20 or hours < 6) then
            assert(dancingTiglil)
            assert(technoAnimations)
            assert(idleAnimations)
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


--Direction = piece("Direction")

function showSubSpins(pieceID)
   local subspinName = getUnitPieceName(unitID, pieceID)
   subSpinPieceName = subspinName.."Spin"    
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
    local subPieceName = getUnitPieceName(unitID, pieceID)
    subSpinPieceName = subPieceName.."Spin"    
    if TableOfPiecesGroups[subSpinPieceName] then  
        hideTReg(TableOfPiecesGroups[subSpinPieceName]) 
    end
end

function chipsDropping(chips, boolReverse)
   
    while true do
        if (hours > 20 or hours < 6)  then
            for i=1, #chips do
                local chip= chips[i]
                reset(chip)
                val= math.random(15, 55)*randSign()
                Spin(chip, x_axis, math.rad(val),0)
                val= math.random(15, 55)*randSign()
                Spin(chip, z_axis, math.rad(val),0)
                ShowReg(chip)
                randX = math.random(0, 1500)*randSign()
                randY = math.random(0, 1500)*randSign()
                randZ = math.random(0, 1500)*randSign()
                downDirection = math.random(15000, 29000) * randSign()
                mP(chip, randX, randY, randZ, 100)
            end
            Sleep(2000)
            for i=1, #chips do
                local chip= chips[i]
                Move(chip, math.random(1,3), downDirection, 300)
            end
            Sleep(15000)
            if boolReverse then
                for i=1, #chips do
                    local chip= chips[i]
                    reset(chip, 300)
                end
                Sleep(15000)
            end
            for i=1, #chips do
                HideReg(chips[i])
            end
        end
        Sleep(1000)
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

function mergePersonalizeMessages()
  location_region, location_country, location_province, location_cityname, location_citypart = getLocation()
  
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
end

boolJustOnce= true
function restartHologram()
    Signal(SIG_CORE)
    SetSignalMask(SIG_CORE)

    Sleep(500)
    resetAll(unitID)
    hideAllReg(unitID)

    if boolIsEverChanging and boolJustOnce then
        mergePersonalizeMessages()
        boolJustOnce = false
    end
   
    StartThread(clock)
    deployHologram()    
    hideTReg(spins)
    StartThread(checkForBlackOut)    
    StartThread(tiglLilLoop)
end

function GetPieceTableGroups()
    return getPieceTableByNameGroups(false, true)
end

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TableOfPiecesGroups = GetSetSharedOneTimeResult("house_western_hologram_script_PiecesTable", GetPieceTableGroups)
    restartHologram()
    StartThread(grid)
    StartThread(emergencyWatcher)
end

function ShowEmergencyElements () 
    EmergencyIcon = piece("EmergencyIcon")
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


    if (randChance(25)) then
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

function holoGramNightTimes( name, axisToRotateAround, elementsMax)

    elementsMax = elementsMax or 5
    elementsMax = math.max(math.min(elementsMax, #TableOfPiecesGroups[name]),4)
    interval = math.random(1,3)*60*1000
    alreadyShowing = {}
    
    while true do
        if ( (hours > 17 or hours < 7) or boolDebugHologram) and isANormalDay() then
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/advertising/hologramnoise.ogg", 0.25, 25000, 1)
            showTellDict= {}
            hcounter = math.random(3, elementsMax)
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

function lineTicker()
    Spring.Echo("Starting lineTicker at "..getCoordinateString(unitID))
    while true do
        totalDeg = 0
        absoluteRange = 180
        for i=1,10 do
            relativeRange = (absoluteRange - 90) - totalDeg
            relativeDeg  = sanitizeRandom(math.min(relativeRange, 0), math.max(relativeRange, 0))
            Turn(TableOfPiecesGroups["BuisnessWall35Sub"][i], z_axis, math.rad(relativeDeg  - totalDeg),0)
            totalDeg = totalDeg - relativeDeg
            ShowReg(TableOfPiecesGroups["BuisnessWall35Sub"][i])
        end
        if maRa() then
            Turn(TableOfPiecesGroups["BuisnessWall35Sub"][21], z_axis, math.rad(-totalDeg),0)
            ShowReg(TableOfPiecesGroups["BuisnessWall35Sub"][21])
        end

        totalDeg = 0
        absoluteRange = 180
        for i=11,20 do
            relativeRange = (absoluteRange - 90) - totalDeg
            relativeDeg  = sanitizeRandom(math.min(relativeRange, 0), math.max(relativeRange, 0))

            Turn(TableOfPiecesGroups["BuisnessWall35Sub"][i],z_axis, math.rad(relativeDeg - totalDeg),0)
            totalDeg = totalDeg - relativeDeg
            ShowReg(TableOfPiecesGroups["BuisnessWall35Sub"][i])
        end
        if maRa() then
            Turn(TableOfPiecesGroups["BuisnessWall35Sub"][22],z_axis, math.rad(-totalDeg),0)
            ShowReg(TableOfPiecesGroups["BuisnessWall35Sub"][22])
        end
        Sleep(15000)
        hideTReg(TableOfPiecesGroups["BuisnessWall35Sub"])
        Sleep(3000)
    end
end


function showWallDayTime(name)
    local BuisnessWall35 = piece("BuisnessWall35")
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
                    if element ~= BuisnessWall35 then
                        encounter = encounter - 1
                        ShowReg(element)
                        showSubSpins(element)
                    else
                        StartThread(lineTicker)
                    end
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
   -- echo("begin western hologram initialisation")
    SetSignalMask(SIG_HOLO)
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
    --echo("Starting hologram GeneralDeco")
    StartThread(holoGramNightTimes, "GeneralDeco", nil, 3)
    --echo("Starting hologram type specific initilisation")
    if boolIsCasino then 
        if randChance(25) then StartThread(chipsDropping, TableOfPiecesGroups["CasinoChip"], maRa) end
        if randChance(25) then StartThread(chipsDropping, TableOfPiecesGroups["Money"]) end
        StartThread(localflickerScript, CasinoflickerGroup, function() return randChance(25); end, 5, 250, 4,  3, math.random(4,7))
    
        if maRa() or isNearCityCenter(x,z, GameConfig)  then
          StartThread(showWallDayTime, "CasinoWall")
          StartThread(addJHologramLetters)
          if maRa() then
            StartThread(fireWorks)
          end
        end           
        if randChance(75) then
            StartThread(addHologramLetters, casinoNamesNeonSigns)         
            return 
        end
    end
    

    if boolIsBuisness then 
        if maRa() or isNearCityCenter(x,z, GameConfig) then
            StartThread(showWallDayTime, "BuisnessWall")
        end

        logo = nil
        boolDone = false
        if not GG.HoloLogoRegister  then 
            GG.HoloLogoRegister = {}
            GG.HoloLogoRegister.western = {}
            GG.HoloLogoRegister.eastern = {}
          end   

        lowestIndex= nil
        lowestCounter = math.huge

        start = (getLocationHash(unitID) % #TableOfPiecesGroups["buisness_holo"]) + 1
        for i=start, #TableOfPiecesGroups["buisness_holo"] do
            element = TableOfPiecesGroups["buisness_holo"][i]

            if not GG.HoloLogoRegister.western[element] then
                GG.HoloLogoRegister.western[element] = 1
                logo = element
                showSubSpins(element)
                boolDone = true
                break
            elseif GG.HoloLogoRegister.western[element] < lowestCounter then
                lowestIndex = element
                lowestCounter = GG.HoloLogoRegister.western[element]
            end
        end

        if not boolDone then
            for i=1, start do
                element = TableOfPiecesGroups["buisness_holo"][i] 
                if not GG.HoloLogoRegister.western[element] then
                    GG.HoloLogoRegister.western[element] = 1
                    logo = element
                    showSubSpins(element)
                    boolDone = true
                    break
                elseif GG.HoloLogoRegister.western[element] < lowestCounter then
                    lowestIndex = element
                    lowestCounter = GG.HoloLogoRegister.western[element]
                end
            end
        end

        if not boolDone then
            --echo("Found no index for logo, selecting lowest")
            logo = lowestIndex
            GG.HoloLogoRegister.western[logo] = GG.HoloLogoRegister.western[logo] +1      
        end
        
        if not GG.RestaurantCounter then GG.RestaurantCounter = 0 end
        if GG.RestaurantCounter < 4 and randChance(25) then    
            logo = piece("buisness_holo18")
            boolIsRestaurant = true
     
            GG.RestaurantCounter = GG.RestaurantCounter + 1
            symbol = math.random(8,11)
            ShowReg(TableOfPiecesGroups["buisness_holo18Spin"][symbol])
            StartThread(holoGramNightTimes, "GeneralDeco", nil, 5)
            StartThread(addJHologramLetters)
        end

        if logo == symmetryPiece then 
            symmetryOrigin = piece("SymmetryOrigin")
            if maRa() then ShowReg(symmetryOrigin) end
            StartThread(shapeSymmetry, symmetryPiece)
            --return            
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
        echo("buisness_holo logo is: "..getUnitPieceName(unitID, logo))

        if randChance(5) then StartThread(flickerBuisnessLogo, logo, getSafeRandom(TableOfPiecesGroups["buisness_holo"], TableOfPiecesGroups["buisness_holo"][1])) end
        if randChance(1) then StartThread(flickerBuisnessAllLogos, logo, TableOfPiecesGroups["buisness_holo"]) end

        if maRa() then
           local logoName = getUnitPieceName(unitID, logo)
           logoTableName = logoName.."Spin"
           if TableOfPiecesGroups[logoTableName] then   
                for i=1, #TableOfPiecesGroups[logoTableName] do
                    _, element = randDict(TableOfPiecesGroups[logoTableName])             
                    if maRa() then
                        spinLogoPiece = element
                        ShowReg(spinLogoPiece)
                        Spin(spinLogoPiece,y_axis, math.rad(-42),0)
                    end
                end
              conditionalBuisnessLogo()
           end
        else
            if randChance(25) then
                addHologramLetters(creditNeonSigns)
                if maRa() then
                    StartThread(LightChain, TableOfPiecesGroups["Techno"], 4, 110)
                end
            else
                conditionalBuisnessLogo()
            end
        end
        return 
    end 
end

function conditionalBuisnessLogo()
    if boolIsRestaurant then 
        addHologramLetters(restaurantNeonLogos)
    else
        if unitID % 5 == 0 then
            mapHash = getDetermenisticMapHash(Game)
            limit =  2048
            hash = getDeterministicRandom(mapHash, limit)
            addHologramLetters({ shamusYoungCompanyName(hash, limit), shamusYoungCompanyName(reHash(hash, limit))})
        else
            addHologramLetters(buisnessNeonSigns)
        end
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

    if maRa() then
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
    Sleep(500)
    resetT(TableOfPiecesGroups["Symmetry"], 0)
    hideTReg(TableOfPiecesGroups["Symmetry"])
    local symmetryLimit =11
    for ix=1, symmetryLimit do
        if  (randChance(65.0)) or ix < 2 then
            local smyPieceOrgName = "Symmetry0"..ix
            local symPieceName = "Symmetry0"..(ix + symmetryLimit)
            local ap = piece(smyPieceOrgName)
            local symRoationVal = 0
            if ap then         
                symRoationVal = math.random(1,8)*randSign()*45
                WTurn(ap, x_axis, math.rad(symRoationVal), 5000)
                ShowReg(ap)
            end

            local orgVal = 0 
            if ix == 1 then orgVal = 180 end
            local symValue =  orgVal - symRoationVal
            local bp = piece(symPieceName)
            if bp then          
                WTurn(bp, x_axis, math.rad(symValue), 5000)
                ShowReg(bp)
            end
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

function hideResetAllLetters()
    letters = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
    for i=1, #letters do
        local letter = letters[i] 
        if TableOfPiecesGroups[letter] then
            resetT(TableOfPiecesGroups[letter])
            hideTReg(TableOfPiecesGroups[letter])
        else
            echo("hideResetAllLetters failed for:"..letter)
        end
    end
end

function delayedFlickerSingleLetter(letterPiece)
    Signal(SIG_FLICKER)
    SetSignalMask(SIG_FLICKER)
    while true do

        --buildUpIntervall ever shorter
        for i= math.random(5,10), 1, -1 do
            HideReg(letterPiece)
            intervallLength = math.ceil(5000/i)
            Sleep(intervallLength)
            ShowReg(letterPiece)
            showIntervall = math.max((i/10),0.1) * 2000
            Sleep(showIntervall)
        end
        Sleep(6000)
    end
end

function setupMessage(myMessages)
    boolHighlightFirstLetter = math.random(1,100) < 10
    hideResetAllLetters()
    Move(textSpinner, 2 ,0, 0) --Move the text spinner upward so letters dont vannish into the ground
    axis= 2
    startValue = 0
    myMessage = myMessages[math.random(1,#myMessages)]
    if boolIsCasino  then startValue = 2 end
    if boolIsBrothel  then startValue = 3 end
    boolUpright = maRa()


    if boolUpright and boolIsBrothel then
        if maRa() == maRa() then
            StartThread(LightChain, TableOfPiecesGroups["LightChain"], 4, math.random(700,1200))
        end
    end

    boolSpinning = maRa()
    boolFirstHighlight= true

    downIndex = 1
    local lettercounter={}
    stringlength = string.len(myMessage)
    rowIndex= 0
    columnIndex= 0
      
    if boolSpinning then
        reset(textSpinner)
        val = math.random(5,45)
        Spin(textSpinner, y_axis, math.rad(val),0)
    end

    if boolUpright then
        if stringlength > 10 then        
            Move(textSpinner, 2 ,math.abs(stringlength-10) * sizeDownLetter, 0) --Move the text spinner upward so letters dont vannish into the ground
        end
    end

    allLetters = {} 
    posLetters = {}   
    posLetters.myMessage = myMessage
    if stringlength < 12 and maRa() then
        posLetters.IsThreeLetter= {}
    end 
    posLetters.spacing = {}
    posLetters.boolUpright = boolUpright

    for i=1, stringlength do
        --increment letter index
        local letter = string.upper(string.sub(myMessage,i,i))

        if TableOfPiecesGroups[letter] then
            if not lettercounter[letter] then 
                lettercounter[letter] = 0
            end            

            lettercounter[letter] = lettercounter[letter] + 1 
            boolContinue = not(lettercounter[letter] > #TableOfPiecesGroups[letter])

            if boolContinue == true and TableOfPiecesGroups[letter] and lettercounter[letter] and TableOfPiecesGroups[letter][lettercounter[letter]] then
                local letterName = TableOfPiecesGroups[letter][(lettercounter[letter] % #TableOfPiecesGroups[letter]) + 1 ] 
                if posLetters.IsThreeLetter then
                    posLetters.IsThreeLetter[letterName] = TableOfPiecesGroups[letter]
                end

                --Highlight first
                if boolHighlightFirstLetter and boolFirstHighlight then
                    boolFirstHighlight =false
                    StartThread(delayedFlickerSingleLetter, letterName)
                end
                if letterName then     
                    table.insert(allLetters, letterName)
                    table.insert(posLetters.spacing, letterName)          
                    ShowReg(letterName)                    
                    posLetters[letterName]= {0,  -1*sizeSpacingLetter * columnIndex,  -1 * sizeDownLetter * rowIndex }
                    for ax=1,3 do
                        Move(letterName, ax, posLetters[letterName][ax], 0)
                    end
                end
            end
            --increment
            if boolUpright == true then
                rowIndex = rowIndex + 1
            else
                columnIndex = columnIndex + 1
            end

        else -- non letter letter - space etc
            table.insert(posLetters.spacing, " ")
            boolFirstHighlight = true   
            if boolUpright == true then --spacing
                rowIndex = rowIndex +1
            else --horizontal
                if columnIndex > 12 then -- linebreak
                    columnIndex = 0
                    rowIndex = rowIndex +1
                else
                    columnIndex = columnIndex + 1
                end
            end
        end  
    end
    return allLetters, posLetters, myMessage
end

function restoreMessageOriginalPosition(message, posLetters)
    hideResetAllLetters()
    letterIndex= 0
    foreach(message,
        function(letter)
            letterIndex= letterIndex +1
                if letter then                                 
                    for ax=1,3 do
                        Move(letter, ax, posLetters[letter][ax], 0)
                    end
                        
                    if boolSpinning and posLetters.boolUpright then
                        val = letterIndex * 5
                        Turn(letter, 2, math.rad(val), 0)
                    end
                end    
            end
        )
end


backdropAxis = x_axis
spindropAxis = y_axis


function resetSpinDrop(allLetters)

         foreach(allLetters,
        function(id)   
                StopSpin(id, spindropAxis, math.rad(0), 0)      
                Turn(id, 1, math.rad(0), 0)    
                Turn(id, 2, math.rad(0), 0)    
                Turn(id, 3, math.rad(0), 0)    
        end)
end


function addJHologramLetters()
    if maRa() == maRa()  then return end
    message = {}
    for i=1,6 do
        message[i] = math.random(1,41)
    end
    axis= 2
    boolJUpright = maRa()
    if boolJUpright then
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
            local jPieceName = TableOfPiecesGroups["JLetter"][message[i]]                   
            ShowReg(jPieceName)
            Move(jPieceName, 3,  -sizeDownLetter*rowIndex, 0)
            Move(jPieceName,axis, sizeSpacingLetter*(columnIndex), 0)
            if boolJUpright then
                columnIndex= 0
                rowIndex= rowIndex +1
            else           
                columnIndex = columnIndex +1
            end
        end
    end
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
                

function waterFallProject(allLetters, posLetters)
    foreach(allLetters, 
        function (id)
            randomHeight = math.random(8,20)*1000
            Move(id, spindropAxis, randomHeight, 0)
            ShowReg(id)
        end)
    speed= 0
    waitTime = 21000
    while waitTime > 0 do
        speed = speed + 9.81
        foreach(allLetters, 
        function (id)
            for ax=1,3 do
                Move(id, spindropAxis, posLetters[id][ax], speed)
            end
        end)
        waitTime = waitTime - 100
        Sleep(100)
    end
    Sleep(60000)
    hideTReg(allLetters)
end


--myMessage = neonSigns[math.random(1,#neonSigns)]
function addHologramLetters( myMessages)  
    allFunctions = getAllTextFx()
    allLetters, posLetters, newMessage = setupMessage(myMessages)

    if maRa() and maRa() or boolIsEverChanging  then 

        while true do
            restoreMessageOriginalPosition(allLetters, posLetters)
            if not posLetters.boolUpright then
                name, textFX = randDict(allFunctions)
               -- name, textFx = "circleProject", circleProject
                if name then
                    Spring.Log('house_western_hologram_script.lua', 'info',"Hologram "..newMessage.." with textFX "..name)
                    textFX(allLetters, posLetters)
                    Signal(SIG_FLICKER)
                    HideLetters(allLetters,posLetters)
                end
                WaitForMoves(allLetters)       
            end
            restTime = math.max(5000, #allLetters*150)
            Sleep(restTime)
            restoreMessageOriginalPosition(allLetters, posLetters)
            resetSpinDrop(allLetters)
            WaitForTurns(allLetters)
            Sleep(restTime)
            if boolIsEverChanging == true then
                allLetters, posLetters, newMessage = setupMessage(myMessages)                
            end
        end
    end 
end

function flickerBuisnessLogo(logoA, logoB)
    while true do
        ShowReg(logoA)
        Sleep(10000)
        for i=1, 10 do
            HideReg(logoA)
            ShowReg(logoB)
            Sleep(333)
            HideReg(logoB)
            ShowReg(logoA)
            Sleep(333)
            
        end
        Sleep(1000)
    end
end

function flickerBuisnessAllLogos(logoA, allLogos)
    while true do
        ShowReg(logoA)
        Sleep(10000)
        for i=math.random(1,#allLogos-10), 10 do
            HideReg(logoA)
            ShowReg(allLogos[i])
            Sleep(333)
            HideReg(allLogos[i])
            ShowReg(logoA)
            Sleep(333)          
        end
        Sleep(1000)
    end
end