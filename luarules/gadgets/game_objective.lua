function gadget:GetInfo()
	return {
		name = "Objectives",
		desc = "Spawns objectives - hands out rewards for protecting or destroying them",
		author = "Pircossa",
		date = "2.2.2009",
		license = "GPL2.1",
		layer = 50,
		enabled = true
	}
end

    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")


objectiveTypes = getObjectiveTypes(UnitDefs)
Objectives = {}
DeadObjectives = {}
--SYNCED
if (gadgetHandler:IsSyncedCode()) then
GameConfig = getGameConfig()

 function gadget:Initialize()
 	
 end

 function gadget:UnitCreated(UnitID, whatever)
 	local type=Spring.GetUnitDefID(UnitID);
	if objectiveTypes[type] then
		x,y,z=Spring.GetUnitPosition(UnitID)
		Objectives[UnitID] = {x= x, y=y, z=z}
	end
 end

 function gadget:UnitDestroyed(UnitID, whatever)
	if objectiveTypes[Spring.GetUnitDefID(UnitID)] then
		DeadObjectives[UnitID]=Objectives[UnitID]
		Objectives[UnitID]=nil
	end
 end

 function gadget:GameFrame(f)
	if f % GameConfig.Objectives.RewardCyle == 0 then
		antagonT= getAllTeamsOfType("antagon")
		protagonT= getAllTeamsOfType("protagon")

		for id,types in pairs(Objectives) do
			if doesUnitExistAlive(id)== true then
				for tid,_ in pairs(protagonT) do
				GG.Bank:TransferToTeam(  GameConfig.Objectives.Reward, tid, id)
				end
			end
		end

		for id,types in pairs(DeadObjectives) do
			--TODO Reward all antagon teams
				for tid,_ in pairs(antagonT) do
				GG.Bank:TransferToTeam(  GameConfig.Objectives.Reward, tid, id)
				end
		end
	end	
  end--fn
end--sync