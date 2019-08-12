function gadget:GetInfo()
    return {
        name = "Relative Unit Scale:",
        desc = "Scales Units between a realistic scale and a tactical scale depending on camera heigth",
        author = "Picasso",
        date = "21st of March 2019",
        license = "GPLv3", 
        layer = 0,
        enabled = true
    }
end


if (gadgetHandler:IsSyncedCode()) then


	 VFS.Include("scripts/lib_UnitScript.lua")
	 VFS.Include("scripts/lib_mosaic.lua")

	scaleTable= getUnitScaleTable(UnitDefNames)
	
   local function tansferScaleTable()

        for typeDefID, scales in pairs(scaleTable) do
            SendToUnsynced("transferScaleTable", typeDefID, scales.realScale, scales.tacticalScale)
        end
    end
	
	function gadget:UnitCreated(unitID, unitDefID)
		SendToUnsynced("SetUnitLuaDraw", unitID, unitDefID)
	end

	StartFrame = Spring.GetGameFrame()
    function gadget:GameFrame(frame)
      if frame  ==  StartFrame + 1 then  
            tansferScaleTable()
	  end
    end

else -- unsynced

    local UnsyncedScaleTable = {} 
    local unitIDtypeDefIDMap = {}
	
	local limitOfTacticalScale = 2500
	local limitOfRealisticScale = 500
	local camPos={x=0, y=0, z=0}
	local groundHeigth = 0
	
    local function transferScaleTable(callname, typeDefID, realScale, tacticalScale)
        UnsyncedScaleTable[typeDefID] = {realScale=realScale, tacticalScale =tacticalScale}
    end

    local function setUnitLuaDraw(callname, unitID,typeDefID)
		unitIDtypeDefIDMap[unitID]=typeDefID
	    Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("transferScaleTable", transferScaleTable)
        gadgetHandler:AddSyncAction("SetUnitLuaDraw", setUnitLuaDraw)
    end
	

	function gadget:GameFrame(frame)
		camPos.x,camPos.y,camPos.z =	Spring.GetCameraPosition()
		groundHeigth = Spring.GetGroundHeight(camPos.x,camPos.z)
	end
	
	local function mix(vA, vB, fac)

		return (fac * vA +(1-fac) * vB)

	end

	
	
    function gadget:DrawUnit(unitID)
        if unitIDtypeDefIDMap[unitID] and UnsyncedScaleTable[unitIDtypeDefIDMap[unitID]] then
            local scale = UnsyncedScaleTable[unitIDtypeDefIDMap[unitID]]
			
			if scale then 
				camHeigth = math.abs(camPos.y - groundHeigth)
				
				factor = 0.0
				if camHeigth >= limitOfRealisticScale and camHeigth <= limitOfTacticalScale then
					factor = mix(scale.realScale, scale.tacticalScale, 1 - (math.abs(camHeigth - limitOfRealisticScale)/math.abs(limitOfTacticalScale - limitOfRealisticScale)))
				end
				
				if camHeigth > limitOfTacticalScale then 
					factor = scale.tacticalScale
				end
				if camHeigth < limitOfRealisticScale then 
					factor = scale.realScale
				end
			
            gl.Scale(factor, factor, factor)

            gl.UnitRaw(unitID, true)
			end
        end
    end
end