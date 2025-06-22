include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}

gaiaTeamID = Spring.GetGaiaTeamID()
BrothelSpin= piece("BrothelSpin")
CasinoSpin= piece("CasinoSpin")
Joy = piece("Joy1")
JoyZoom = piece("Joy2")
JoyZoomArm = piece("Joy2Arm")
JoyRide = piece("JoyRide")
local boolDebugScript = false
local lastFrame = Spring.GetGameFrame()
local cachedCopy = {}
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
local BuisnessSpin = piece "BuisnessSpin"
local idleAnimations = {}
local spGetGameFrame = Spring.GetGameFrame
local buisnessLogo = nil
local brothelFlickerGroup = nil
local CasinoflickerGroup = nil
local JoyFlickerGroup = nil
SIG_TIGLIL = 2
SIG_GESTE = 4
SIG_TALKHEAD = 8

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
local hours  =0
local minutes=0
local seconds=0
local percent=0
hours, minutes, seconds, percent = getDayTime()

function clock()
    while true do
        hours, minutes, seconds, percent = getDayTime()
        Sleep(10000)
    end
end


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
    Show(pieceID)
    cachedCopy[pieceID] = pieceID
    updateCheckCache()
end

function HideReg(pieceID)
    assert(pieceID)
    Hide(pieceID)  
    cachedCopy[pieceID] = nil
    updateCheckCache()
end

-- > Hide all Pieces of a Unit
function hideAllReg(id)
    if not unitID then unitID = id end

    pieceMap = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(pieceMap) do 
        if v then
            HideReg(v) 
        end
    end
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

function showOne(T, bNotDelayd)
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


--VFS.Include("scripts/lib_textFx.lua")
include ("tigLilAnimation.lua")
include("lib_textFx.lua")

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
local function tiglLilLoop()

    while true do
        if (hours > 20 or hours < 6) then
        

            StartThread(dancingTiglil, idleAnimations)

            while  (hours > 20 or hours < 6) do
                Sleep(3000)               
            end

            Signal(SIG_TIGLIL)
            HideReg(skimpy)
            HideReg(tlpole)
            HideReg(tldrum)
            HideReg(tlflute)
            hideTReg(TablesOfPiecesGroups["GlowStick"])
            hideTReg(tigLilHoloPices)
            
        end
        while(hours < 20 ) do
                showLogo()
                Sleep(5000)
            end
        Sleep(3000)
    end
end

function dancingTiglil(animations, boolTechno)
    SetSignalMask(SIG_TIGLIL)
    if boolTechno then
        showOne(TablesOfPiecesGroups["GlowStick"])
        showOne(TablesOfPiecesGroups["GlowStick"])
    end
    if maRa() then
        skimpy = piece("skimpy")
        ShowReg(skimpy)
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

function joyStart()
    StartThread(flickerScript, JoyFlickerGroup, 5, 250, 4, true)
    StartThread(JoyAnimation)
end

function showLogo()
    Sleep(100)
        for i=1, math.random(3, 9) do            
            logo = buisnessLogo[math.random(1, #buisnessLogo)]
            val =math.random(5,22)*randSign()
            Spin(logo,y_axis, math.rad(val),0)
            ShowReg(logo)
            Sleep(1000)
        end
        Sleep(5000)
        hideTReg(buisnessLogo)
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

function theSlammer()
    Slammer = piece("Slammer")
    SlammPiece = piece("SlamPiece")
    ShowReg(SlammPiece)
    ShowReg(Slammer)
    while true do
        Turn(Slammer,z_axis, math.rad(-10), 5)
        WMove(SlammPiece,z_axis, -50, 150)
        Turn(Slammer,z_axis, math.rad(0), 15)
        WMove(SlammPiece,z_axis, 0, 50)
        Sleep(500)
    end
end

function dropCoinsOrMoney(boolIsMoney)
    if boolIsMoney then
       chipsDropping(TablesOfPiecesGroups["Money"], maRa())
    end

    if maRa()then
        chipsDropping(TablesOfPiecesGroups["CasinoChip"], maRa())
    else
        chipsDropping(TablesOfPiecesGroups["Money"], maRa())
    end
end


variousFunctions = {
    [1] = function ()
        echo("brothelFlicker function")
        StartThread(flickerScript, brothelFlickerGroup, 5, 250, 4, true)
        StartThread(theSlammer)
    end,
    [2] = function ()
        echo("showLogo function")
        StartThread(showLogo)
    end,    
    [3] = function () 
        echo("joyStart function")
        StartThread(joyStart)
    end,
    [4] = function () --tiglil
        echo("tiglLilLoop function")
        StartThread(tiglLilLoop)
        StartThread(dropCoinsOrMoney, true)
    end,
    [5] = function ()
        echo("casino function")
        StartThread(flickerScript, CasinoflickerGroup, 5, 250, 4, true)
        StartThread(dropCoinsOrMoney)
    end,
}


function script.Create()
    --echo(UnitDefs[unitDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
     TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
     StartThread(HoloGrams)
     HideReg(BrothelSpin)
     HideReg(CasinoSpin)
     HideReg(BuisnessSpin)

end

function hideAllReg()
    pieceMap = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(pieceMap) do HideReg(v) end
end

function HoloGrams()    
    StartThread(clock)
    buisnessLogo = TablesOfPiecesGroups["buisness_holo"]
    brothelFlickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    JoyFlickerGroup = {}

    JoyFlickerGroup[#JoyFlickerGroup+1] = Joy
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyZoom
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyZoomArm
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyRide
    hideAllReg()

    Sleep(15000)
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if maRa() then
        variousFunctions[math.random(1,#variousFunctions)]()
    else
       indexA = math.random(1,#variousFunctions)
       variousFunctions[indexA]()
       indexB =(indexA % #variousFunctions) +1
       variousFunctions[indexB]()
    end
    offset= 70
    val = math.random(5, 12)*randSign()
    Move(BrothelSpin, z_axis, -offset,0)
    Spin(BrothelSpin, z_axis, math.rad(val), 0.1)

    Move(CasinoSpin, z_axis, -offset,0)
    Spin(CasinoSpin, z_axis,  math.rad(val), 0.1)
    
    val = math.random(5, 12)*randSign()
    Spin(BuisnessSpin, z_axis,  math.rad(val), 0.1)
end

local GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(  GameConfig.instance.culture, "civilian", UnitDefs)

function joyToTheWorld()
    lowest = math.huge
    lowestID = nil
    mx,my,mz = Spring.GetUnitPosition(unitID)
    foreach(getAllOfTypeNearUnit(unitID, civilianWalkingTypeTable, 1024),
        function(id)
            candidateDistance = distancePosToUnit(mx,my,mz, id)
            if candidateDistance < lowest then
                lowest = candidateDistance
                lowestID = id
            end
        end)
    if lowestID then 
        turnUnitPieceToUnit(unitID, Joy, lowestID, 15)
    end
end



function JoyAnimation()
    offsetValue = -70
    turnVal= -17
    animStepTime = 1000
    JoySpinOrigin = TablesOfPiecesGroups["JoySpin"][1]

    while true do
        HideReg(JoyZoom)
        HideReg(JoyZoomArm)
        HideReg(Joy)
        if boolDebugScript or (hours > 17 or hours < 7) then
            if maRa() then ShowReg(JoyZoom); ShowReg(JoyZoomArm); else ShowReg(Joy) end
            joyToTheWorld()
            Spin(JoySpinOrigin, z_axis, math.rad(17*3), 0)
            ShowReg(JoySpinOrigin)
            Sleep(2000)

            scalar = 0.125*0.5*0.1
            for i=2, #TablesOfPiecesGroups["JoySpin"] do
                offset = i* offsetValue
                ShowReg(TablesOfPiecesGroups["JoySpin"][i])
                rootDistance = i* 70 * 2
                Move(JoySpinOrigin, z_axis, rootDistance,speed(rootDistance, animStepTime*scalar))
                Move(TablesOfPiecesGroups["JoySpin"][i],z_axis, offsetValue, speed(offsetValue, animStepTime*scalar))
                Turn(TablesOfPiecesGroups["JoySpin"][i],z_axis, math.rad(turnVal), speed(turnVal, animStepTime))

                WaitForTurns(TablesOfPiecesGroups["JoySpin"][i])
                WaitForMoves(TablesOfPiecesGroups["JoySpin"][i])
            end
            WaitForMoves(JoySpinOrigin)
        end

        hideTReg(TablesOfPiecesGroups["JoySpin"])
        for i=1, #TablesOfPiecesGroups["JoySpin"] do
            reset(TablesOfPiecesGroups["JoySpin"][i],0)
        end
        StopSpin(JoySpinOrigin,z_axis,0)
        WaitForTurns(TablesOfPiecesGroups["JoySpin"])
        WaitForMoves(TablesOfPiecesGroups["JoySpin"])   
        DownDist = -70* #TablesOfPiecesGroups["JoySpin"] * 2
        WMove(JoySpinOrigin,z_axis, DownDist, 0)
        Sleep(10)
    end
end

function flickerScript(flickerGroup,  errorDrift, timeoutMs, maxInterval, boolDayLightSavings)
    assert(flickerGroup)
    local fGroup = flickerGroup
    flickerIntervall = math.ceil(1000/25)
    
    while true do
        hideTReg(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        if boolDebugScript or (hours > 17 or hours < 7) then
            toShowTableT= {}
            for x=1,math.random(1,3) do
                toShowTableT[#toShowTableT+1] = fGroup[math.random(1,#fGroup)]
            end

            for i=1,(3000/flickerIntervall) do
                if i % 2 == 0 then  showTReg(toShowTableT) else hideTReg(toShowTableT) end
                if maRa()== maRa() then showTReg(toShowTableT) end 
                for ax=1,3 do
                    moveT(fGroup, ax, math.random(-1 * errorDrift, errorDrift),100)
                end
                Sleep(flickerIntervall)
            end
            hideTReg(toShowTableT)
        end
        breakTime = math.random(1,maxInterval)*timeoutMs
        Sleep(breakTime)
    end
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

