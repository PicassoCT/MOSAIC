--
-- file: game_end.lua
-- brief: spawns start unit and sets storage levels
-- author: Andrea Piras
--
-- Copyright (C) 2010,2011.
-- Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
    return {
        name = "Debug Script",
        desc = "Gives Prometheus some units",
        author = "Picasso, first of his game",
        date = "August, 2010",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true -- loaded by default?
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
    return false
end

VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_UnitScript.lua")

startFrame = (Spring.GetGameFrame()+ 10 ) or 10

function gadget:GameFrame(frame)
    -- only do a check in slowupdate
    if (frame == startFrame)  then
		--get list of houses
		
		-- every third house -- add a safehouse for the ai-team
		
		
	
	
	end
end




function gadget:Initialize()
  startFrame = Spring.GetGameFrame()+ 10
end
