include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
BrothelSpin= piece("BrothelSpin")
CasinoSpin= piece("CasinoSpin")
Joy = piece("Joy")
JoyRide = piece("JoyRide")
local boolDebugScript = false
local lastFrame = Spring.GetGameFrame()
local cachedCopy = {}

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
    Hide(pieceID)  
    cachedCopy[pieceID] = nil
    updateCheckCache()
end

-- > Hide all Pieces of a Unit
function hideAllReg(id)
    if not unitID then unitID = id end

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



function script.Create()
    --echo(UnitDefs[myDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
     TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
     StartThread(HoloGrams)
     HideReg(BrothelSpin)
     HideReg(CasinoSpin)

end

function HoloGrams()    
    local brothelFlickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    local JoyFlickerGroup = {}

    JoyFlickerGroup[#JoyFlickerGroup+1] = Joy
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyRide
    hideTReg(brothelFlickerGroup)
    hideTReg(CasinoflickerGroup)
    hideTReg(JoyFlickerGroup)
    hideTReg(TablesOfPiecesGroups["JoySpin"])

    Sleep(15000)
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if maRa() then
        StartThread(flickerScript, brothelFlickerGroup, 5, 250, 4, true)
    else
        StartThread(flickerScript, JoyFlickerGroup, 5, 250, 4, true)
        StartThread(JoyAnimation)
    end
    val = math.random(5, 12)*randSign()
    Move(BrothelSpin, z_axis, -offset,0)
    Spin(BrothelSpin, z_axis, math.rad(val), 0.1)
    StartThread(flickerScript, CasinoflickerGroup, 5, 250, 4, true)
    val = math.random(5, 12)*randSign()
    Move(CasinoSpin, z_axis, -offset,0)
    Spin(CasinoSpin, z_axis,  math.rad(val), 0.1)
end



function JoyAnimation()
    offsetValue = -70
    turnVal= -17
    animStepTime = 1000
    JoySpinOrigin = TablesOfPiecesGroups["JoySpin"][1]

    while true do

        hours, minutes, seconds, percent = getDayTime()
        if boolDebugScript or (hours > 17 or hours < 7) then
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
        hours, minutes, seconds, percent = getDayTime()
        if boolDebugScript or (hours > 17 or hours < 7) then
            toShowTableT= {}
            for x=1,math.random(1,3) do
                toShowTableT[#toShowTableT+1] = fGroup[math.random(1,#fGroup)]
            end

            for i=1,(3000/flickerIntervall) do
                if i % 2 == 0 then  showTReg(toShowTableT) else hideTReg(toShowTableT) end
                if maRa()==maRa() then showTReg(toShowTableT) end 
                for ax=1,3 do
                    moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
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

