--statue spawn gadget

function gadget:GetInfo()
	return {
		name = "Satellites Movement Gadget",
		desc = "Collects Engagment Data and Displays it at exit of person",
		author = "pica",
		date = "Anno Domini 2018",
		license = "Comrade Stallmans License",
		layer = 109,
		version = 1,
		enabled = true,
		hidden = true
	}
end

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear
if (gadgetHandler:IsSyncedCode()) then

	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	
	SatelliteTypes = getSatteliteTypes(UnitDefs)
	SatelliteTypesSpeedTable = getSatelliteTypesSpeedTable(UnitDefs)
	SatelliteAltitudeTable = getSatelliteAltitudeTable(UnitDefs)
	SatelliteTimeOutTable = getSatelliteTimeOutTable(UnitDefs)
	
	Satellites ={}
	function gadget:UnitDestroyed(unitID, unitDefID)
		if Satellites[unitID] then
			Satellites[unitID] = nil
		end
	
	end

	
	function gadget:UnitCreated(unitID, unitDefID)
		if SatelliteTypes[unitDefID] then
			satteliteStateTable[unitID] = "flying"
			Spring.MoveCtrl.Enable(unitID,true)
			Satellites[unitID] = unitDefID
		end		
	end
	
	local mapSizeX = Game.mapSizeX
	local mapSizeZ = Game.mapSizeZ
	
	function circularClamp(x,y,z)
		if (x >= mapSizeX) then x = 2 end
		if (x <= 1) then x = mapSizeX-1 end
		
		return x,y,z
	end
	
	function getComandOffset(id, x, speed)
  
	 CommandTable = Spring.GetUnitCommands(id, 3)
	 boolFirst=true
	 
		 for _, cmd in pairs(CommandTable) do
				if boolFirst == true and cmd.id == CMD.MOVE then 
					boolFirst = false 
					if math.abs(cmd.params[1] - x)> 10 then
						if cmd.params[1] < x then
							return speed *-1
						elseif cmd.params[1]  > x then
							return speed 
						end
					end
				end	 
		 end		 
	return 0
	end
	timeOutTable={}
	satteliteStateTable={}
	
local	satelliteStates={
	["flying"] = function(id, x, y, z, utype)	
					-- Spring.Echo("State flying")
					if  (z >= mapSizeZ) then
						return "timeout", x, y, 1
					end
					
					return "flying", x,y,z
				  end,
	["timeout"] =  function(id, x,y,z, utype)
						-- Spring.Echo("State timeout")
						if not timeOutTable[id] then timeOutTable[id] = SatelliteTimeOutTable[utype] end
						timeOutTable[id]= timeOutTable[id] -1
						
						if timeOutTable[id] <= 0 then 
							 timeOutTable[id] = nil
							return "flying", x,y,1
						end
	
					return "timeout", x,y,1
					end	
	}
	
	function gadget:GameFrame(n)
		for id, utype in pairs(Satellites) do
			x,y,z = Spring.GetUnitPosition(id)
			x,y,z = circularClamp(x + getComandOffset(id, x, SatelliteTypesSpeedTable[utype]), y , z + SatelliteTypesSpeedTable[utype])
			
			satteliteStateTable[id],x,y,z = satelliteStates[satteliteStateTable[id]](id, x, y, z, utype)
			
			Spring.MoveCtrl.SetPosition(id, x, SatelliteAltitudeTable[utype], z )
		end
	end
end
