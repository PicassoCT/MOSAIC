
local versionNumber = "2.03"

function widget:GetInfo()
  return {
    name = "Snipe Mini Game",
    desc = "controlls the behaviour of raid icon minigame unitspawning",
    author = "dizekat",
    date = "Jan,2008",
    license = "GNU GPL, v2 or later",
    layer = 0,
    enabled = true
  }
end

function widget:Update(dt)

end

local raidIconDefID = nil

function widget:Initialize()

	WG['snipeminigame'] = {}
    WG['snipeminigame'].testfunc = function()
        return maxAlpha
    end

    return true
end

for k,v in pairs(UnitDefs) do
	if v.name == "raidicon" then
	raidIconDefID = k
	end
end

raidIcons ={}

function widget:UnitCreated(unitID, unitDefID)
	if raidIconDefID == unitDefID  then
		raidIcons[unitID] = unitID
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	if raidIcons[unitID] then 
		raidIcons[unitID] = nil
	end
end

local raidIcon = UnitDefNames["raidicon"].id

boolPlacementActive= false
function widget:MousePress(x,y,button)
	if (mButton ~= 1) then return false end

 local targType, targID = spTraceScreenRay(mx, my, false, inMinimap)
 Spring.Echo(targType.." - > "..targID)
        if targType == 'unit' and raidIcons[targID] then
			boolPlacementActive = true
			Spring.Echo("Clicked on raid icon")
			return true 
		end
end

 function widget:MouseMove(mx, my, dx, dy, mButton)
 
 end

function widget:MouseRelease(mx, my, mButton)

end