-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name = "Nine Mens Morris",
    desc = " Controll the raids icons nine men morris",
    author = "dizekat",
    date = "Jan,2008",
    license = "GNU GPL, v2 or later",
    layer = 5,
    enabled = true,
	hidden = true
  }
end



function widget:GameStart()

end

local raidIconDefID = nil

function widget:Initialize()
 
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

function widget:MousePress(x,y,button)
 local targType, targID = spTraceScreenRay(mx, my, false, inMinimap)
 Spring.Echo(targType.." - > "..targID)
        if targType == 'unit' then
            defID = Spring.GetUnitDefID(targID)
			if defID == raidIcon then
			Spring.Echo("Clicked on raid icon")
			
			end
		end
end