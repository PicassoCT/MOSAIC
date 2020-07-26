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



function widget:Initialize()
 
end

local raidIconDefID = UnitDefNames["raidicon"].id
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

function widget:MousePress(x,y,button)

end