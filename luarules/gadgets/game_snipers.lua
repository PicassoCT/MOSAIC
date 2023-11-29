function gadget:GetInfo()
    return {
        name = "Sniper Gadget",
        desc = "Handles Sniper behaviour",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")


local UnitDefNames = getUnitDefNames(UnitDefs)

local sniperIconDefID = UnitDefNames["sniperrifleicon"].id
local sniperIcons = {}

function SetUnitPosition(iconID, operativeID)
 	env = Spring.UnitScript.GetScriptEnv(iconID)
        if env and env.TransportPickup then
            Spring.UnitScript.CallAsUnit(iconID, env.TransportPickup, operativeID)
        end
end

function gadget:UnitFinished(unitID, unitDefID)
	if unitDefID == sniperIconDefID then
		sniperIcons[unitID] = parentID
		SetUnitPosition(unitID, parentID)
	end
end


