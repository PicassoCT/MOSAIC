local versionNumber = "2.03"

function widget:GetInfo()
    return {
        name = "snipeMiniGame",
        desc = "controlls the behaviour of raid icon minigame unitspawning",
        author = "picassoct",
        date = "Jan,2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
        hidden = true,
        handler = true
    }
end


local raidIconDefID = nil
local houseRaidIconMap = {}
local houseTypeTable = {}
local spTraceScreenRay = Spring.TraceScreenRay
local spIsAboveMiniMap = Spring.IsAboveMiniMap
local raidIcons = {}
local oldValues = {x= 0, z = 0}

function widget:Initialize()

    for k, v in pairs(UnitDefs) do
        if v.name == "raidicon" then
            raidIconDefID = k
        end

        if string.find(v.name,"house_arab0") or string.find(v.name, "house_europe0") then
            houseTypeTable[k] = k
        end
    end

    for k, v in pairs(UnitDefs) do
        if v.name == "raidicon" then
            raidIconDefID = k
        end
    end

    return true
end

function widget:Shutdown()

end

function widget:UnitCreated(unitID, unitDefID)
    if raidIconDefID == unitDefID then
        raidIcons[unitID] = unitID
    end
end

function widget:UnitDestroyed(unitID, unitDefID)
    if raidIcons[unitID] then
        raidIcons[unitID] = nil
    end
end

local raidIcon

for id, def in pairs(UnitDefs) do
    if def.name == "raidicon" then
        raidIcon = id
    end
end

lastPos = {}
local boolPlacementActive = false
function widget:MousePress(x, y, button)
    local inMinimap = spIsAboveMiniMap(x, y)
    Spring.Echo("MousePress ".. button)
    if (button ~= 1) then
        return false
    end

    local targType, unitID = spTraceScreenRay(x, y)
     --Spring.Echo("cmd_snipeminigame:", targType, unitID)

    if targType == "unit" then
        --does not trace down to raidicon - selects house instead.. even with house set to unselect
        local defID = Spring.GetUnitDefID(unitID) 

		if houseTypeTable[defID] or  defID == raidIconDefID then
		--make houses transparent
		if houseTypeTable[defID]  then
		
		
    		--Spring.Echo("Mouse Press on MiniGameBoard of type".. UnitDefs[defID].name)
            local targType, targID = spTraceScreenRay(x, y, true, inMinimap, false, false, 50)
            --Spring.Echo(targType.." - > ",targID[1],targID[2],targID[3])
            
            if targType and targType == "ground" then
                if boolPlacementActive == false then
                    --Spring.Echo("Placement started")
                    lastPos = targID
                    Spring.SendLuaRulesMsg(
                        "SPWN|snipeicon|" .. targID[1] .. "|" .. targID[2] .. "|" .. targID[3] .. "|" .. unitID
                    )
                end
                boolPlacementActive = true
    			return true
            end
        end
        end
    end
end

function widget:Update(dt)
    if boolPlacementActive == true then
        local x,y = Spring.GetMouseState()
        inMinimap = spIsAboveMiniMap(x, y)
        local targType, targID = spTraceScreenRay(x, y, true, inMinimap, false, false, 50)
        if targID then
         Spring.SendLuaRulesMsg("ROTPOS|snipeicon|" .. targID[1] .. "|" .. targID[2] .. "|" .. targID[3])
        end
    end
end

function widget:MouseRelease(x, y, mButton)
    if (mButton ~= 1) then
        return false
    end

    if boolPlacementActive == true then
        --Spring.Echo("Placement ended")
        inMinimap = spIsAboveMiniMap(x, y)
        local targType, targID = spTraceScreenRay(x, y, true, inMinimap, false, false, 50)
        if targID then
         Spring.SendLuaRulesMsg("POSROT|snipeicon|" .. targID[1] .. "|" .. targID[2] .. "|" .. targID[3])
        end
        --Set Direction
        boolPlacementActive = false
        return true
    end
end
