function gadget:GetInfo()
	return {
		name = "Raidicon Rendering Settings ",
		desc = " ",
		author = "Picasso",
		date = "3rd of May 2010",
		license = "GPL3",
		layer = 4,
		version = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	iconTypeTable = getIconTypes(UnitDefs)
	local GameConfig = getGameConfig()
	
	iconUnit={}
	
	function gadget:UnitCreated(unitID, unitDefID)
		if iconTypeTable[unitDefID] then
				Spring.Echo("Icon Type "..UnitDefs[unitDefID].name.. " created")
				iconUnit[unitID] = unitDefID
				SendToUnsynced("SetUnitLuaDraw", unitID, unitDefID)
		end
	end

else -- unsynced
    local iconTables = {}
	
    local function setUnitLuaDraw(callname, unitID,typeDefID)
		iconTables[unitID]=typeDefID
	    Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
    end

    function gadget:Initialize()
		Spring.Echo(GetInfo().name.." Initialization started")
		gadgetHandler:AddSyncAction("SetUnitLuaDraw", setUnitLuaDraw)
		Spring.Echo(GetInfo().name.." Initialization ended")
    end
	
	local glScale = gl.Scale
	local glUnitRaw = gl.UnitRaw
	
    function gadget:DrawUnit(unitID, drawMode)
        if iconTables[unitID] and drawMode == 2 then
			
			glUnitRaw(unitID, true)	
			
			return true
        end
    end
end
