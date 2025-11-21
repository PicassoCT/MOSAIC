include "lib_OS.lua"
include "lib_Animation.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"

local hours   = 0
local minutes = 0
local seconds = 0
local percent = 0
local TablesOfPiecesGroups = {}
local cachedCopyDict = {}
local spGetGameFrame = Spring.GetGameFrame
local GameConfig = getGameConfig()

hours, minutes, seconds, percent = getDayTime()

function clock()
    while true do
        hours, minutes, seconds, percent = getDayTime()
        Sleep(10000)
    end
end

local gaiaTeamID = Spring.GetGaiaTeamID()
local boolDebugHologram = true
local PornoRamaFlickerGroup = {}

local oldFrame = spGetGameFrame()
local newFrame = nil
--This is a externally pulled function- meaning its called after all unitscripts have run by a gadget to deliver the show and hidden pieces
function updateCheckCache()     
    GG.VisibleUnitPieces[unitID] =  dictToTable(cachedCopyDict)     
    newFrame = spGetGameFrame()
end

function setUpdateRequest()
    if newFrame ~= oldFrame then
        oldFrame = newFrame
        GG.VisibleUnitPieceUpateStates[unitID] = true
    end
end

function ShowReg(pieceID)
    if  pieceID == nil then return end
    --Spring.Echo("Avertiseblimp registering ShowReg "..pieceID)
    Show(pieceID)
    cachedCopyDict[pieceID] = pieceID
    setUpdateRequest()
end

function HideReg(pieceID)
    if  pieceID == nil then return end
    Hide(pieceID)  
    cachedCopyDict[pieceID] = nil
    setUpdateRequest()
end
local pieceMap = Spring.GetUnitPieceMap(unitID)
function showAllReg(id)
    if not unitID then unitID = id end
    for k, v in pairs(pieceMap) do 
        if v then
            HideReg(v) 
        end
    end
end
-- > Hide all Pieces of a Unit
function hideAllReg(id)
    if not unitID then unitID = id end
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

function pornoRamaStart()
    StartThread(flickerScript, PornoRamaFlickerGroup, 5, 250, 4, true)
    StartThread(showLogo)
end

function showLogo()
    Sleep(100)
    for i=1, math.random(3, 9) do            
        logo = TablesOfPiecesGroups["PornoRama"][math.random(1, #TablesOfPiecesGroups["PornoRama"])]
        val =math.random(5,22)*randSign()
        Spin(logo,y_axis, math.rad(val),0)
        ShowReg(logo)
        Sleep(1000)
    end
    Sleep(5000)
    hideTReg(TablesOfPiecesGroups["PornoRama"])
end

function delayedAlwaysVisble()
    Sleep(9000)
    Spring.SetUnitAlwaysVisible(unitID, true)
end

function script.Create()
    --echo(UnitDefs[unitDefID].name.."has placeholder script called")
    StartThread(delayedAlwaysVisble)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    PornoRamaFlickerGroup = TablesOfPiecesGroups["PornoRama"]
     --showAllReg()
    StartThread(HoloGrams)

    HideReg(BrothelSpin)
    HideReg(CasinoSpin)
    HideReg(BuisnessSpin)
end

function HoloGrams()    
    StartThread(clock)
    hideAllReg()

    Sleep(15000)    
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
--    echo("Start blimp Holograms advertisement")
    StartThread(pornoRamaStart)
end

function flickerScript(flickerGroup,  errorDrift, timeoutMs, maxInterval, boolDayLightSavings)
    local fGroup = flickerGroup
    flickerIntervall = math.ceil(1000/25)
    
    while true do
        hideTReg(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        if boolDebugHologram or (hours > 17 or hours < 7) then
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

