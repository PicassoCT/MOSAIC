include "lib_UnitScript.lua"

local TablesOfPiecesGroups = {}
local pieceID_NameMap = Spring.GetUnitPieceList(unitID)
local cachedCopy ={}
local Frame = piece("Frame")

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAllReg(unitID)
    ShowReg(Frame)
    StartThread(flickerAnimation)
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

function displayPieceTable(T)
    if type(T) == "number" then  return  pieceID_NameMap[T] end

    concatString = ""
    for i=1, #T do
       concatString= concatString.."|".. pieceID_NameMap[T[i]]
    end
    return concatString

end


function HideReg(pieceID)
    if not pieceID then return end
    assert(pieceID_NameMap[pieceID], "Not a piece".. displayPieceTable(pieceID))
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

local snippetStarts= 
{
    [1] = { endsat= 70,  jumpsto = {35, 400}},
    [70] = { endsat= 140,  jumpsto = {105, 125, 1}},
    [140] = { endsat= 175,  jumpsto = {140, 155, 70}},
    [175] = { endsat= 175 + 35,  jumpsto = {175, 140}},
    [210] = { endsat= 210 + 35,  jumpsto = {210, 175}},
    [245] = { endsat= 245 + 35,  jumpsto = {245, 210, 175}},
    [280] = { endsat= 280 + 35,  jumpsto = {245, 210, 175}},
    [315] = { endsat= 315 + 35,  jumpsto = {245, 280, 315}},
    [350] = { endsat= 350 + 35,  jumpsto = {245, 280, 315, 1}},
    [385] = { endsat= 385 + 5,  jumpsto = {385, 1}},
    [390] = { endsat= 390 + 5,  jumpsto = {390, 1}},
    [395] = { endsat= 395 + 5,  jumpsto = {395, 1}},
    [400] = { endsat= 400 + 5,  jumpsto = {400, 1}},
    [405] = { endsat= 405 + 409,  jumpsto = {405, 1}},
}
local endIndex= snippetStarts[1].endsat
local jumpsto = snippetStarts[1].jumpsto

function flickerAnimation()
    local index = 1
    local lastPiece = TablesOfPiecesGroups["Flicker"][index]
    local currentPiece = TablesOfPiecesGroups["Flicker"][index]
    Show(currentPiece)
    Sleep(125)
    while true do
        currentPiece = TablesOfPiecesGroups["Flicker"][index]
        HideReg(currentPiece)
        index = loopsReptitionsJumps(index)
        currentPiece = TablesOfPiecesGroups["Flicker"][index]
        ShowReg(currentPiece)
        varSpeed= math.random(40, 160)
        Sleep(varSpeed)
    end
end

function loopsReptitionsJumps(index)
    newIndex = (index % #TablesOfPiecesGroups["Flicker"]) +1
    if index == endIndex then
        if maRa() then
           if maRa() then Sleep(3000) end
           newIndex = getSafeRandom(jumpsto, jumpsto[1])
           if snippetStarts[newIndex] then 
                jumpsto = snippetStarts[newIndex].jumpsto
                endIndex = snippetStarts[newIndex].endsat
                return newIndex
           end          
        end
    end

    if snippetStarts[newIndex] then 
        jumpsto = snippetStarts[newIndex].jumpsto
        endIndex = snippetStarts[newIndex].endsat
    end
    return newIndex
end

function script.Killed(recentDamage, _)
    return 1
end

