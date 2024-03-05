include "createCorpse.lua"
include "lib_OS.lua"
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
    Show(pieceID)
    table.insert(cachedCopy, pieceID)
    updateCheckCache()
end

function HideReg(pieceID)
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



function restartHologram()
    Signal(SIG_CORE)
    SetSignalMask(SIG_CORE)
    resetAll(unitID)
    hideAllReg(unitID)
    deployHologram()
    StartThread(checkForBlackOut)
    StartThread(clock)
end

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TableOfPiecesGroups = getPieceTableByNameGroups(false, true)
    restartHologram()
end

local hours, minutes, seconds, percent = getDayTime()
function clock()
    while true do
        hours, minutes, seconds, percent = getDayTime()
        Sleep(1000)
    end
end


function deployHologram()
    StartThread(HoloGrams)
end

logoPiece = nil
spinPieces = {}
jumpScarePieces = {}
function deterministiceSetup()
 
     
        logoPiece = deterministicElement( getDeterministicRandom(unitID, #TableOfPiecesGroups["HoloLogo"]), TableOfPiecesGroups["HoloLogo"])
        ShowReg(logoPiece)

        nrSpins = unitID % 10
        for i=1, nrSpins, 1 do
            spinPiece = deterministicElement( getDeterministicRandom(unitID, #TableOfPiecesGroups["HoloSpin"]), TableOfPiecesGroups["HoloSpin"])
            table.insert(spinPieces, spinPiece)
        end

        jumpScareNr = unitID % 5
        for i=1, jumpScareNr, 1 do
            jumpScare = deterministicElement( getDeterministicRandom(unitID, #TableOfPiecesGroups["JumpScare"]), TableOfPiecesGroups["JumpScare"])
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
        Hide(piecesTable[i])
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
