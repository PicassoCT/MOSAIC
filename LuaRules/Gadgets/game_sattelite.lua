--statue spawn gadget

function gadget:GetInfo()
	return {
		name = "Satellites Movement Gadget",
		desc = "Collects Engagment Data and Displays it at exit of person",
		author = "pica",
		date = "Anno Domini 2018",
		license = "Comrade Stallmans License, disregard the starving wretches and bastards, rise above - strive for freedom",
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
	local directionalSwitchValue = 50
	
	Satellites ={} --utype --direction
	function gadget:UnitDestroyed(unitID, unitDefID)
		if Satellites[unitID] then
			Satellites[unitID] = nil
		end
	
	end

	
	function gadget:UnitCreated(unitID, unitDefID)
		if SatelliteTypes[unitDefID] then
			satteliteStateTable[unitID] = "flying"
			Spring.MoveCtrl.Enable(unitID,true)
			Satellites[unitID] = {utype =unitDefID, direction = "orthogonal"}
		end		
	end
	
	local mapSizeX = Game.mapSizeX
	local mapSizeZ = Game.mapSizeZ
	
	function circularClamp(x,y,z)
		if (x >= mapSizeX) then x = 2 end
		if (x <= 1) then x = mapSizeX-1 end
		
		return x,y,z
	end
	
	function getComandOffset(id, x, z, direction, speed)

		 CommandTable = Spring.GetUnitCommands(id, 3)
		 boolFirst=true
	 
		 for _, cmd in pairs(CommandTable) do
			if boolFirst == true and cmd.id == CMD.MOVE then 
				boolFirst = false 
				if direction == "orthogonal" then
					if math.abs(cmd.params[1] - x)> 10 then
						if cmd.params[1] < x then
							return speed *-1, 0
						elseif cmd.params[1]  > x then
							return speed, 0
						end
					end
				else
					if math.abs(cmd.params[3] - z)> 10 then
						if cmd.params[3] < z then
							return 0, speed *-1
						elseif cmd.params[3]  > z then
							return 0, speed 
						end
					end				
				end			
				break
			end		 
		 end		 
	return 0, 0
	end
	timeOutTable={}
	directionalChangeTable={}
	satteliteStateTable={}

function directionalArrestTimeOut(x,y,z, direction)
	if direction == "orthogonal" then
		if x > directionalSwitchValue then z = 1 end
		return x,y, z
	end
	
	if direction == "horizontal" then
		if z > directionalSwitchValue then x = 1 end

		return x , y, z
	end
	
	echo("directionalArrest Error")
	return x,y,z
end	

	
function directionalArrest(x,y,z, direction)
	if direction == "orthogonal" then
		return x,y, 1
	end
	
	if direction == "horizontal" then
		return 1, y, z
	end
	
	echo("directionalArrest Error")
	return x,y,z
end	
	
directionalChangeTable ={}
function dectectDirectionalChange(id, direction)
	-- only one directional change per waiting period -- prevents pendulum behaviour
	if directionalChangeTable[id] then return direction end
	--data preparation
	CommandTable = Spring.GetUnitCommands(id, 3)
	boolFirst=true
	tx, tz = 0, 0
	for _, cmd in pairs(CommandTable) do
		if boolFirst == true and cmd.id == CMD.MOVE then 
			tx, tz = cmd.params[1] , cmd.params[3]
			boolFirst = false 
		end
	end

	 mx,my,mz = Spring.GetUnitPosition(id)
	 
	-- directional change 
	if tx < directionalSwitchValue and tz < directionalSwitchValue then return direction end
	
	if tx < directionalSwitchValue and direction == "orthogonal" then 
		return  "horizontal"
	end
	
	if tz < directionalSwitchValue and direction == "horizontal" then
		return "orthogonal"
	end
	
	return direction
end

function deactivateSatellite(id)
	Spring.SetUnitNeutral(id, true)	
	Spring.SetUnitBlocking(id , false, false, false)
	-- setUnitValueExternal(id, VIEWRADIUS, 0)
end

function reactivateSatellite(id)
	if directionalChangeTable[id] then directionalChangeTable[id] = nil end
 Spring.SetUnitNeutral(id, false)
end
	
local	satelliteStates={
	["flying"] = function(id, x, y, z, utype, direction)	

					if  (direction == "orthogonal" and z >= mapSizeZ) or (direction == "horizontal" and x >= mapSizeX) then
						deactivateSatellite(id)				
						x,y,z = directionalArrestTimeOut(x,y,z, direction)
						return "timeout", x, y, z
					end
					
					return "flying", x,y,z
				  end,
	["timeout"] =  function(id, x,y,z, utype, direction)
					direction = dectectDirectionalChange(id, direction)
					Satellites[id].direction = direction
	
						if not timeOutTable[id] then timeOutTable[id] = SatelliteTimeOutTable[utype] end
						timeOutTable[id]= timeOutTable[id] -1
						
						if timeOutTable[id] <= 0 then 
							 timeOutTable[id] = nil							
							 x,y,z = directionalArrest(x,y,z, direction)
							 reactivateSatellite(id)
							return "flying", x,y,z
						end
					x,y,z = directionalArrestTimeOut(x,y,z, direction)
					return "timeout", x,y,z
					end	
	}
	
	function getDirectionalTypeTravelSpeed(utype, direction)
	ox, oz = 0,0
		if direction == "orthogonal" then
			 oz =  SatelliteTypesSpeedTable[utype]
		else
			 ox =  SatelliteTypesSpeedTable[utype]
		end
	return ox, oz
	end
	
	function gadget:GameFrame(n)
		for id, tables in pairs(Satellites) do
			utype = tables.utype
			sx,sy,sz = Spring.GetUnitPosition(id)
			ox, oz = getDirectionalTypeTravelSpeed(utype, tables.direction)
			speedx, speedz= getComandOffset(id, sx, sz, tables.direction, SatelliteTypesSpeedTable[utype])
			x,y,z = circularClamp(sx + ox+ speedx , sy , sz+oz +speedz)
			
			satteliteStateTable[id],x,y,z = satelliteStates[satteliteStateTable[id]](id, x, y, z, utype, tables.direction)
			
			Spring.MoveCtrl.SetPosition(id, x, SatelliteAltitudeTable[utype], z )
			vx,vy,vz = absDistance(sx,x),0,absDistance(sz,z)
			if satelliteStates[id] ~= "timeout" then
				Spring.MoveCtrl.SetVelocity(id, vx, vy, vz)
			end
			-- Spring.MoveCtrl.SetRotation(id, 0, 0, 0)
		end
	end
end
