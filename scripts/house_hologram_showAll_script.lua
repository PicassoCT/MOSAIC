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
local cachedCopyDict ={}
local oldCachedCopyDict ={}
local lastFrame = Spring.GetGameFrame()
TableOfPiecesGroups = {}

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
    if not pieceID then return end
    Show(pieceID)
    cachedCopyDict[pieceID] = pieceID
    updateCheckCache()
end

function HideReg(pieceID)
    if not pieceID then return end
    --assert(pieceID_NameMap[pieceID], "Not a piece".. displayPieceTable(pieceID))
    Hide(pieceID)  
    --TODO make dictionary for efficiency
    cachedCopyDict[pieceID] = nil
    updateCheckCache()
end

-- > Hide all Pieces of a Unit
function showAllReg()
    local  pieceMap = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(pieceMap) do ShowReg(v) end
end

-- > Hide all Pieces of a Unit
function hideAllReg()
    local pieceMap = Spring.GetUnitPieceMap(unitID)
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
function script.Create()
    TablesOfPieceGroups = getPieceTableByNameGroups(false, true)
    showAllReg()
end