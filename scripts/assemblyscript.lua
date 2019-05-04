include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
buildspot = piece "buildspot"
structure = piece "structure"
myTeamID = Spring.GetUnitTeam(unitID)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(buildWatcher)
end

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
end


function buildWatcher()
	
	while true do 
	buildID = Spring.GetUnitIsBuilding(unitID)
		if buildID then
		hp, mhp, pd, captProg, buildProgress = Spring.GetUnitHealth(buildID)
		laststep= 0
		while buildProgress and buildProgress + laststep  > 0.95		do
			Sleep(1)
			hp, mhp, pd, captProg, tbuildProgress = Spring.GetUnitHealth(buildID)
			laststep = buildProgress - tbuildProgress
			buildProgress = tbuildProgress
			
		end

		if buildProgress then 
			unitDefID = Spring.GetUnitDefID(buildID)
			createUnitAtUnit(myTeamID, unitDefID, unitID, 0,0, 0)
			local facCmds = Spring.GetFactoryCommands(unitID) 
			if facCmds then -- nil check
				local cmd = facCmds[1]
				Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {1,cmd.tag}, {"ctrl"})
			end
		
		end
		
		
		end
	
	Sleep(1)
	end


end



function script.Activate()
    SetUnitValue(COB.YARD_OPEN, 1)

    SetUnitValue(COB.BUGGER_OFF, 1)

    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end

function delayedDeactivation()
Sleep(1000)
    SetUnitValue(COB.YARD_OPEN, 0)

    SetUnitValue(COB.BUGGER_OFF, 0)

    SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.Deactivate()
	StartThread(delayedDeactivation)

    return 0
end

function script.QueryBuildInfo()
    return buildspot
end

Spring.SetUnitNanoPieces(unitID, { structure })

