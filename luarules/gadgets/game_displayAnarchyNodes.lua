function gadget:GetInfo()
	return {
		name = "display Data Tool",
		desc = " ",
		author = "Picasso",
		date = "3rd of May 2010",
		license = "GPL3",
		layer = 3,
		version = 1,
		enabled = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
    return false
end

	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")	

	local GameConfig = getGameConfig()

function gadget:GameFrame(frame)
	
	-- if frame > 0 and frame % 30 == 0 then
		-- local orgMidPointTable = sharedComputationResult( "orgHousePosTable", computeOrgHouseTable, UnitDefs, 500, GameConfig )
		-- if #orgMidPointTable > 0 then
		-- local currentPositionClusters = sharedComputationResult( "civilianAnarchyPositionClusters", computateClusterNodes, orgMidPointTable, 15 , GameConfig)
		
		-- Spring.Echo("OrgPoints:"..#orgMidPointTable.."  Remaining Points:"..count(currentPositionClusters))
		-- process(currentPositionClusters,
			-- function(pos)
				-- markPosOnMap(pos.x,pos.y+15,pos.z, "redmarker", true)
			-- end
			-- )
		-- end
	-- end
end