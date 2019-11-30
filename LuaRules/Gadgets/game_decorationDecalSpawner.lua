function gadget:GetInfo()
	return {
		name = "Decal spawner",
		desc = "Coordinates Traffic ",
		author = "Picasso",
		date = "3rd of May 2010",
		license = "GPL3",
		layer = 3,
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
	gameConfig = getGameConfig()
	
	defIDDecalNameMap = getDecalMap(gameConfig.instance.culture)	
	gaiaTeamID = Spring.GetGaiaTeamID()
	houseDefID = UnitDefNames["house"].id
	function gadget:GameFrame(n)
		frameDelayedAction(n)
	end
	
	SpawnedUnits={}
	
	function frameDelayedAction(frame)
		if SpawnedUnits[frame] then
		
			for i=1, #SpawnedUnits[frame] do
				local unitID = SpawnedUnits[frame][i].id
				local unitDefID = SpawnedUnits[frame][i].defID
				local teamID = SpawnedUnits[frame][i].teamID
				
				if defIDDecalNameMap[UnitDefs[unitDefID].name] and teamID == gaiaTeamID then
					x,y,z= Spring.GetUnitPosition(unitID)
					
					T= getAllNearUnit(unitID, 725)
					T = process(T,
								function(id)
									if Spring.GetUnitTeam(id) == gaiaTeamID and Spring.GetUnitDefID(id)== houseDefID then
										return id
									end
								end
								)
					
					
					ID = 0
					if T and count(T) > 2 then
						nrElement= math.random(1,#defIDDecalNameMap[UnitDefs[unitDefID].name].urban)
						ID =defIDDecalNameMap[UnitDefs[unitDefID].name].urban[nrElement]
					else
						nrElement= math.random(1,#defIDDecalNameMap[UnitDefs[unitDefID].name].rural)
						ID =defIDDecalNameMap[UnitDefs[unitDefID].name].rural[nrElement]
					end
					
					GG.UnitsToSpawn:PushCreateUnit(ID, x,y,z, 1 , gaiaTeamID)				
				end
			end
		end
		
	SpawnedUnits[frame]= nil
	end
	
	function gadget:UnitCreated(unitID, unitDefID, teamID)
		frame = Spring.GetGameFrame() +1
		if not SpawnedUnits [frame] then SpawnedUnits [frame] = {} end
			set = {id= unitID, defID= unitDefID, teamID= teamID}
			table.insert(SpawnedUnits[frame], set)				
		end
			
end