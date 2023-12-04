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

local sniperIconDefID = nil
UnitDefNames = getUnitDefNames(UnitDefs)
for i=1,#UnitDefs do
	if UnitDefs[i].name == "sniperrifleicon" then
		sniperIconDefID = UnitDefs[i].id
	end
end

function setEnvironmentRooftop(assetID)
	
    env = Spring.UnitScript.GetScriptEnv(assetID)

    if env and env.onRooftop then
       result= Spring.UnitScript.CallAsUnit(assetID, 
                                     env.onRooftop
                                     )
       echo("Called unit on rooftop")
    end
end


function gadget:Initialize()
	if  GG.myParent == nil then 
		GG.myParent = {}
	end
end

function gadget:UnitFinished(unitID, unitDefID)
	if unitDefID == sniperIconDefID then
		Spring.SetUnitNoSelect(unitID, true)
		moveUnitToUnit(GG.myParent[unitID], unitID)
		setEnvironmentRooftop(GG.myParent[unitID])
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if unitDefID == sniperIconDefID then
 		GG.myParent[unitID] = builderID
 		Spring.Echo("Setting my parent for ".. builderID)
 	end
end
