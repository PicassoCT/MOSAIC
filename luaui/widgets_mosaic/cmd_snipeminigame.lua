local versionNumber = "2.03"

function widget:GetInfo()
    return {
        name = "Snipe Mini Game",
        desc = "controlls the behaviour of raid icon minigame unitspawning",
        author = "picassoct",
        date = "Jan,2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
        hidden = true
    }
end

function widget:Update(dt)
end

local raidIconDefID = nil
local spTraceScreenRay = Spring.TraceScreenRay
local spIsAboveMiniMap = Spring.IsAboveMiniMap

function widget:Initialize()
    WG["snipeminigame"] = {}
    WG["snipeminigame"].testfunc = function()
        return maxAlpha
    end

    return true
end

for k, v in pairs(UnitDefs) do
    if v.name == "raidicon" then
        raidIconDefID = k
    end
end

raidIcons = {}

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
boolPlacementActive = false
function widget:MousePress(x, y, button)

    inMinimap = spIsAboveMiniMap(x, y)
    if (button ~= 1) then
        return false
    end

    local targType, unitID = spTraceScreenRay(x, y)
    -- Spring.Echo(targType, unitID)
    if targType == "unit" and Spring.GetUnitDefID(unitID) == raidIconDefID then
        local targType, targID = spTraceScreenRay(x, y, true, inMinimap, false, false, 50)
        -- Spring.Echo(targType.." - > ",targID[1],targID[2],targID[3])
        if targType and targType == "ground" then
            if boolPlacementActive == false then
                -- Spring.Echo("Placement started")
                lastPos = targID

                Spring.SendLuaRulesMsg(
                    "SPWN|snipeicon|" .. targID[1] .. "|" .. targID[2] .. "|" .. targID[3] .. "|" .. unitID
                )
            end
            boolPlacementActive = true

            --create Unit at Location
            --set

            return true
        end
    end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
end

function widget:MouseRelease(x, y, mButton)
    if (mButton ~= 1) then
        return false
    end

    if boolPlacementActive == true then
        -- Spring.Echo("Placement ended")
        inMinimap = spIsAboveMiniMap(x, y)
        local targType, targID = spTraceScreenRay(x, y, true, inMinimap, false, false, 50)
        Spring.SendLuaRulesMsg("POSROT|snipeicon|" .. targID[1] .. "|" .. targID[2] .. "|" .. targID[3])
        --Set Direction
        boolPlacementActive = false
        return true
    end
end
