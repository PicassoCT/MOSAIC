local versionNumber = "2.03"

function widget:GetInfo()
    return 
{        name = "operatorRotate",
        desc = "rotates operators towards the mouse curser when selected for attack",
        author = "picassoct",
        date = "Jan,2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
        hidden = true,
        handler = true
    }
end

local operatorTypeTable = {}
local spTraceScreenRay = Spring.TraceScreenRay
local spIsAboveMiniMap = Spring.IsAboveMiniMap
local spGetSelectedUnits = Spring.GetSelectedUnits
local raidIcons = {}
local oldValues = {x= 0, z = 0}
local operativeAssetDefID = 0
local operativeInvestigatorDefID = 0
local operativePropagatorDefID = 0
local CMD_ATTACK = CMD.ATTACK
local CMD_FIGHT = CMD.FIGHT
local OPTIONS = {   -- these will be loaded when switching style, but the style will overwrite the those values

    teamcolorOpacity                = 0.55,     -- how much teamcolor used for the base platter

    -- opacity
    spotterOpacity                  = 0.95,
    baseOpacity                     = 0.15,     -- setting to 0: wont be rendered

    -- animation
    selectionStartAnimation         = true,
    selectionStartAnimationTime     = 0.05,
    selectionStartAnimationScale    = 0.82,
    -- selectionStartAnimationScale = 1.17,
    selectionEndAnimation           = true,
    selectionEndAnimationTime       = 0.07,
    selectionEndAnimationScale      = 0.9,
    --selectionEndAnimationScale    = 1.17,
}

function widget:Initialize()
    for k, v in pairs(UnitDefs) do
        if string.find(v.name,"operative") then
            operatorTypeTable[k] = v
        end
        if v.name == "operativepropagator" then
            operativePropagatorDefID = k
        end
       if v.name == "operativeinvestigator" then
            operativeInvestigatorDefID = k
        end 
        if v.name == "operativeasset" then
            operativeAssetDefID = k
        end         
    end

return true
end


local selChangedSec = 0
local selectedUnitsSorted = Spring.GetSelectedUnitsSorted()
local selectedUnitsCount = Spring.GetSelectedUnitsCount()
local operatorID

function widget:SelectionChanged(sel)
    checkSelectionChanges = true
   -- Spring.Echo("Selection changed")
end

local   function serializeUnitIDTable(unitIDT)
            local retString =""
            local seperator="|"
            if unitIDT then
                for i=1,#unitIDT do
                    retString = retString.. unitIDT[i]..seperator
                end
            end
            return retString
        end

function widget:Update(dt)
    currentClock = os.clock()
    maxSelectTime = currentClock - OPTIONS.selectionStartAnimationTime
    maxDeselectedTime = currentClock - OPTIONS.selectionEndAnimationTime

    selChangedSec = selChangedSec + dt
    if checkSelectionChanges and selChangedSec >= 0.05 then
        selChangedSec = 0
        selectedUnitsSorted = Spring.GetSelectedUnitsSorted()
        selectedUnitsCount = Spring.GetSelectedUnitsCount()
        checkSelectionChanges = false
    end

    local boolContainsOperators = selectedUnitsSorted[operativeAssetDefID] or selectedUnitsSorted[operativePropagatorDefID]  or selectedUnitsSorted[operativeInvestigatorDefID] 
    --check if selectedUnitsContainOperatives
     local index, cmdID = Spring.GetActiveCommand() 
        boolAttackOrFightCmdActive = index ~= nil and (cmdID == CMD_ATTACK or cmdID == CMD_FIGHT)

    if boolContainsOperators and selectedUnitsCount == 1 and boolAttackOrFightCmdActive then
       -- Spring.Echo("Selection contains Operators")
        -- Trace screen ray
        -- rotate them towards target
        local mouseX, mouseY = Spring.GetMouseState()
        local inMinimap = spIsAboveMiniMap(mouseX, mouseY)
        local targType, targID = spTraceScreenRay(mouseX, mouseY, true, inMinimap, false, false, 50)

        if targID then
            operatorID = targID[1]
         Spring.SendLuaRulesMsg("OPROTPOS|" .. targID[1] .. "|" .. targID[2] .. "|" .. targID[3].."|"..
            serializeUnitIDTable(selectedUnitsSorted[operativeAssetDefID]).. "|" ..
            serializeUnitIDTable(selectedUnitsSorted[operativePropagatorDefID]).. "|" ..
            serializeUnitIDTable(selectedUnitsSorted[operativeInvestigatorDefID]).. "|" )
        end
    else
        operatorID = nil
    end
end

local function onRightClickOnBuilding(operatorID, houseID,x,y,z)
    local cx, cy, cz = Spring.GetCameraPosition ( ) 
    Spring.Echo("Rightclick-> SET_SNIPER_POS_")
    Spring.SendLuaRulesMsg("SET_SNIPER_POS_|"..operatorID.."|"..houseID.."|"..x.."|"..y.."|"..z.."|"..cx.."|"..cy.."|"..cz)
end

function widget:MousePress(x, y, button)
    if button == 2 then --right
        Spring.Echo("Rightclick")
        if operatorID then
            Spring.Echo("Rightclick-> Operator defined")
        --Spring.TraceScreenRay ( number mouseX, number mouseY, [, bool onlyCoords [, bool useMinimap [, bool includeSky [, bool ignoreWater [, number D ]]]]] ) 
        local targType, targID = spTraceScreenRay(x, y, true, false, false, false, 50)
            if targetType == "unit" then
                local houseID = targID[1]
                   local desc, args = spTraceScreenRay(mouseX, mouseY, true)
                   local x = args[1]
                   local y = args[2]
                   local z = args[3]

                onRightClickOnBuilding(operatorID, targID[1], x, y, z, cx,cy,cz)
            end
        end
    end
end

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.spotterOpacity                   = OPTIONS.spotterOpacity
    savedTable.baseOpacity                      = OPTIONS.baseOpacity
    savedTable.teamcolorOpacity                 = OPTIONS.teamcolorOpacity

    return savedTable
end

function widget:SetConfigData(data)
    OPTIONS.spotterOpacity     = data.spotterOpacity    or OPTIONS.spotterOpacity
    OPTIONS.baseOpacity        = data.baseOpacity       or OPTIONS.baseOpacity
    OPTIONS.teamcolorOpacity   = data.teamcolorOpacity  or OPTIONS.teamcolorOpacity
end

