include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


buildspot = piece "buildspot"
Containers = piece "Containers"
myTeamID = Spring.GetUnitTeam(unitID)

GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
SIG_BUILD = 1

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

	StartThread(buildWatcher)
	T= process(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange*2),
				function(id)
					if houseTypeTable[Spring.GetUnitDefID(id)] then
						return id
					end
				end
				)
				
	GG.UnitHeldByHouseMap[unitID] = T[1]
	StartThread(mortallyDependant, unitID, T[1], 15, false, true)
	StartThread(buildAnimation)
end



function script.Killed(recentDamage, _)
    return 1
end

boolBuilding = false
function buildWatcher()
	
	while true do 
	buildID = Spring.GetUnitIsBuilding(unitID)
		if buildID then
		hp, mhp, pd, captProg, buildProgress = Spring.GetUnitHealth(buildID)
		laststep= 0
		boolBuilding = true
		while buildProgress and buildProgress + laststep  > 0.95		do
			Sleep(1)
			hp, mhp, pd, captProg, tbuildProgress = Spring.GetUnitHealth(buildID)
			laststep = buildProgress - tbuildProgress
			buildProgress = tbuildProgress
			
		end

		if buildProgress then 
			unitDefID = Spring.GetUnitDefID(buildID)
			createUnitAtUnit(myTeamID, unitDefID, unitID, 0,0, 0)
			if doesUnitExistAlive(unitID) == true then
				local facCmds = Spring.GetFactoryCommands(unitID) 
				if facCmds then -- nil check
					local cmd = facCmds[1]
					Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {1,cmd.tag}, {"ctrl"})
				end		
			end		
		end	
		boolBuilding = false		
		end
	
	Sleep(1)
	end
end

LongDistance = 2100
ShortDistance = 1150
function trayAnimation(partName, totalTravelDistance, delayInMs, travelDistanceStation)
	reset(partName)
	Hide(partName)
	Sleep(delayInMs)
	Show(partName)
	maxis= x_axis
	raxis = y_axis
	
	sspeed = 250
	waitTimeStation = 5000

	while true do
		WTurn(partName,raxis,math.rad(0), math.pi)
		WMove(partName, maxis, travelDistanceStation, sspeed)
		Sleep(waitTimeStation)

		WMove(partName, maxis, totalTravelDistance, sspeed)
		WTurn(partName,raxis,math.rad(179), math.pi)
		Sleep(waitTimeStation)
		WMove(partName, maxis, 0, sspeed)
		WTurn(partName,raxis,math.rad(181), math.pi)
		WTurn(partName,raxis,math.rad(0), math.pi)
		Sleep(delayInMs)

	end

end


function buildAnimation()
Signal(SIG_BUILD)
SetSignalMask(SIG_BUILD)
process(TablesOfPiecesGroups["TrayLong"],
		function(id)
			StartThread(trayAnimation,id, LongDistance, (id % 2)*7000, LongDistance*0.25)
		end)
process(TablesOfPiecesGroups["TrayShort"],
		function(id)
			StartThread(trayAnimation,id, ShortDistance, (id % 2)*7000, ShortDistance*0.25)
		end)
		
	while boolBuilding == true or true do
		process(TablesOfPiecesGroups["AAxis"],
				function(id)
					target= math.random(1,4)*90
					Turn(id,y_axis,math.rad(target),math.pi)
					end
				)		
		process(TablesOfPiecesGroups["BAxis"],
				function(id)
					target= math.random(1,35)*randSign()
					Turn(id,z_axis,math.rad(target),math.pi)
					end
				)	
		process(TablesOfPiecesGroups["CAxis"],
				function(id)
					target= math.random(1,35)*randSign()
					Turn(id,z_axis,math.rad(target),math.pi)
					end
				)	
		process(TablesOfPiecesGroups["DAxis"],
				function(id)
					target= math.random(1,4)*90
					Turn(id,x_axis,math.rad(target),math.pi)
					end
				)	
		process(TablesOfPiecesGroups["EAxis"],
				function(id)
					target= math.random(1,90)*randSign()
					Turn(id,z_axis,math.rad(target),math.pi)
					end
				)
		
		process(TablesOfPiecesGroups["_1SAxis"],
				function(id)
					target= math.random(-90,90)*randSign()
					Turn(id,y_axis,math.rad(target),math.pi)
					end
				)	
		process(TablesOfPiecesGroups["_2SAxis"],
				function(id)
					target= math.random(-90,90)*randSign()
					Turn(id,y_axis,math.rad(target),math.pi)
					end
				)


			WaitForTurns(TablesOfPiecesGroups["AAxis"])		
			WaitForTurns(TablesOfPiecesGroups["BAxis"])		
			WaitForTurns(TablesOfPiecesGroups["CAxis"])		
			WaitForTurns(TablesOfPiecesGroups["DAxis"])		
			WaitForTurns(TablesOfPiecesGroups["EAxis"])		
	
				
				
				
		Sleep(100)
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
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
end

function script.Deactivate()
	StartThread(delayedDeactivation)

    return 0
end

function script.QueryBuildInfo()
    return buildspot
end

Spring.SetUnitNanoPieces(unitID, { structure })

function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
    SetUnitValue(COB.INBUILDSTANCE, 0)
end

