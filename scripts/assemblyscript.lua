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

TrayInPlaceStation={}
TrayInPickUpStation={}

LongDistance = 2050
ShortDistance = 1150

LINE_1_PlaceStation=1
LINE_2_PlaceStation=2
LINE_3_PlaceStation=3
LINE_4_PlaceStation=4

trayDecoMap{
	[piece("TrayLong1")]={start=1, ends=5	,counter=0},
	[piece("TrayLong2")]={start=6, ends=10	,counter=0},
	[piece("TrayShort1")]={start=11, ends=15,counter=0},
	[piece("TrayShort2")]={start=16, ends=20,counter=0},
	[piece("TrayShort3")]={start=21, ends=25,counter=0},
	[piece("TrayShort4")]={start=26, ends=30,counter=0},
	[piece("TrayLong3")]={start=31, ends=35	,counter=0},
	[piece("TrayLong4")]={start=36, ends=40	,counter=0}
}

trayPartInPlaceLine={

}



function hideTrayObjects(partName)
	hideT(TablesOfPiecesGroups["Object"],trayDecoMap[partName].start, trayDecoMap[partName].ends) 
	trayDecoMap[partName].counter = 0
end

function incShowTrayObjects(partName)
if not partName then return end
Show(TablesOfPiecesGroups["Object"][trayDecoMap[partName].start + trayDecoMap[partName].counter])
trayDecoMap[partName].counter = math.min(trayDecoMap[partName].counter+1, trayDecoMap[partName].ends)
end

function trayAnimation(partName, totalTravelDistance, delayInMs, travelDistanceStation, boolTravelDirection, inStationSignalID)
	reset(partName)
	Hide(partName)
	Sleep(delayInMs)
	Show(partName)
	maxis= x_axis
	raxis = y_axis
	
	sspeed = 250
	waitTimeStation = 5000

	while true do
		if boolTravelDirection == true then
			WTurn(partName,raxis,math.rad(0), math.pi)
			WMove(partName, maxis, travelDistanceStation, sspeed)
			TrayInPlaceStation[inStationSignalID]= true
			trayPartInPlaceLine[inStationSignalID] = partName
			Sleep(waitTimeStation)
			trayPartInPlaceLine[inStationSignalID] = nil
			TrayInPlaceStation[inStationSignalID]= false
			WMove(partName, maxis, totalTravelDistance, sspeed)
			WTurn(partName,raxis,math.rad(90), math.pi)
			TrayInPickUpStation[inStationSignalID] = true
			Sleep(waitTimeStation)
			hideTrayObjects(partName)
			TrayInPickUpStation[inStationSignalID] = false
			WTurn(partName,raxis,math.rad(179), math.pi)
			WMove(partName, maxis, 0, sspeed)
			WTurn(partName,raxis,math.rad(181), math.pi)
			WTurn(partName,raxis,math.rad(0), math.pi)
			Sleep(delayInMs)
		else
			WTurn(partName,raxis,math.rad(-179), math.pi)
			WMove(partName, maxis, travelDistanceStation, sspeed)
			TrayInPlaceStation[inStationSignalID]= true
			trayPartInPlaceLine[inStationSignalID] = partName
			Sleep(waitTimeStation)
			trayPartInPlaceLine[inStationSignalID] = nil
			TrayInPlaceStation[inStationSignalID]= false
			WMove(partName, maxis, totalTravelDistance, sspeed)
			WTurn(partName,raxis,math.rad(-270), math.pi)
			TrayInPickUpStation[inStationSignalID] = true
			Sleep(waitTimeStation)
			hideTrayObjects(partName)
			TrayInPickUpStation[inStationSignalID] = false
			WTurn(partName,raxis,math.rad(-360), math.pi)
			WMove(partName, maxis, 0, sspeed)
			WTurn(partName,raxis,math.rad(0), math.pi)
			Sleep(delayInMs)		
		end

	end

end

function WMoveScara(scaraNumber, jointPosA,jointPosB, jointPosC,jointPosD,   moveSpeed)

	Turn(TablesOfPiecesGroups["ASAxis"][scaraNumber],y_axis,math.rad(jointPosA), moveSpeed)
	Turn(TablesOfPiecesGroups["BSAxis"][scaraNumber],y_axis,math.rad(jointPosB), moveSpeed)
	Turn(TablesOfPiecesGroups["CSAxis"][scaraNumber],y_axis,math.rad(jointPosC), moveSpeed)
	WMove(TablesOfPiecesGroups["CSAxis"][scaraNumber],y_axis, jointPosD , moveSpeed * 10)
	WaitForTurns(TablesOfPiecesGroups["ASAxis"][scaraNumber],TablesOfPiecesGroups["BSAxis"][scaraNumber],TablesOfPiecesGroups["CSAxis"][scaraNumber])
end

function scaraAnimationLoop(scaraNumber, objectToPick, targetIDTable, jointPosTable)
	Hide(objectToPick)
	boolObjectPicked = false
	moveSpeed= math.pi
	while true do		
		--Move to CenterPos
		WMoveScara(scaraNumber, jointPosTable.HomePos.a, jointPosTable.HomePos.b, 0, jointPosTable.HomePos.d,  moveSpeed)
		--check if one of the trays is in station
		local targetID 
		if maRa == true then
			for i=1, #targetIDTable, 1 do
				if TrayInPlaceStation[targetIDTable[i]] and  TrayInPlaceStation[targetIDTable[i]] == true then
					targetID = targetIDTable[i]
					break
				end
			end
		else
			for i=#targetIDTable, 1, -1 do
				if TrayInPlaceStation[targetIDTable[i]] and  TrayInPlaceStation[targetIDTable[i]] == true then
					targetID = targetIDTable[i]
					break
				end
			end
		end
		
		if targetID and boolObjectPicked == false then
		--Move to PickUpPos
			WMoveScara(scaraNumber, jointPosTable.PickUp.a, jointPosTable.PickUp.b, 0, 0,  moveSpeed)
			WMoveScara(scaraNumber, jointPosTable.PickUp.a, jointPosTable.PickUp.b, 0, jointPosTable.PickUp.d,  moveSpeed)
			--Pick up ObjectToPick
			Show(objectToPick)
			boolObjectPicked = true
			WMoveScara(scaraNumber, jointPosTable.PickUp.a, jointPosTable.PickUp.b, 0, 0,  moveSpeed)
		end
		
		if boolObjectPicked == true and targetID then
			Pos = jointPosTable.PlaceTable[targetID]
			WMoveScara(scaraNumber, Pos.a, Pos.b, 0, 0,  moveSpeed)
			WMoveScara(scaraNumber, Pos.a, Pos.b, 0, Pos.d,  moveSpeed)
			incShowTrayObjects(trayPartInPlaceLine[targetID])
			Hide(objectToPick)
			WMoveScara(scaraNumber, Pos.a, Pos.b, 0,  0,  moveSpeed)
		
		end	
	Sleep(100)
	end
end

function WMoveRobotToPos(robotID, JointPos, MSpeed)
	Turn(TablesOfPiecesGroups["AAxis"][robotID], y_axis, JoinPos.a, MSpeed)
	Turn(TablesOfPiecesGroups["BAxis"][robotID], z_axis, JoinPos.b, MSpeed)
	Turn(TablesOfPiecesGroups["CAxis"][robotID], z_axis, JoinPos.c, MSpeed)
	Turn(TablesOfPiecesGroups["DAxis"][robotID], x_axis, JoinPos.d, MSpeed)
	Turn(TablesOfPiecesGroups["EAxis"][robotID], z_axis, JoinPos.e, MSpeed)

	WaitForTurns(TablesOfPiecesGroups["AAxis"][robotID],		
				 TablesOfPiecesGroups["BAxis"][robotID],		
				 TablesOfPiecesGroups["CAxis"][robotID],		
				 TablesOfPiecesGroups["DAxis"][robotID],		
				 TablesOfPiecesGroups["EAxis"][robotID])	

end

function robotArmAnimationLoop(robotID, posTable, speed, lineIDTable, targetIDTable, objectPickedSet)
	
	

	--move into HomePos
	WMoveRobotToPos(robotID, posTable.homepos, speed)
	boolObjectPicked = false
	while true do
	

	
	--Check if there is stuff to be picked up
		local targetID 
		if maRa == true then
			for i=1, #targetIDTable, 1 do
				if TrayInPickUpStation[targetIDTable[i]] and  TrayInPickUpStation[targetIDTable[i]] == true then
					targetID = targetIDTable[i]
					break
				end
			end
		else
			for i=#targetIDTable, 1, -1 do
				if TrayInPickUpStation[targetIDTable[i]] and  TrayInPickUpStation[targetIDTable[i]] == true then
					targetID = targetIDTable[i]
					break
				end
			end
		end
	
		if targetID and boolObjectPicked == false then
		--Move to PickUpPos
			WMoveRobotToPos(scaraNumber, posTable.hubposT[targetID],  speed)
			WMoveRobotToPos(scaraNumber, posTable.pickUpPosT[targetID],  speed)
			showT(objectPickedSet)
			boolObjectPicked = true
			WMoveRobotToPos(scaraNumber, posTable.hubposT[targetID],  speed)
			WMoveRobotToPos(scaraNumber, posTable.deskHub,  speed)

		end
		
		if boolObjectPicked == true and targetID then
			WMoveRobotToPos(scaraNumber, posTable.deskHub,  speed)
			-- place it on the table
			tablePos = calcTablePos(posTable.TableRange)
			WMoveRobotToPos(robotID, tablePos, speed)
			WMoveRobotToPos(scaraNumber, posTable.deskHub,  speed)
		end	
		
		Sleep(100)	
	end
end


function buildAnimation()
Signal(SIG_BUILD)
SetSignalMask(SIG_BUILD)

	StartThread(trayAnimation,TablesOfPiecesGroups["TrayLong"][1], LongDistance, (math.random() % 4)* 7000, LongDistance*0.25, true, LINE_1_PlaceStation)
	StartThread(trayAnimation,TablesOfPiecesGroups["TrayLong"][2], LongDistance, (math.random() % 4)* 7000, LongDistance*0.25, true, LINE_1_PlaceStation)

	StartThread(trayAnimation,TablesOfPiecesGroups["TrayShort"][1], ShortDistance, (math.random() % 4)* 7000, ShortDistance*0.25, true, LINE_2_PlaceStation)
	StartThread(trayAnimation,TablesOfPiecesGroups["TrayShort"][2], ShortDistance, (math.random() % 4)* 7000, ShortDistance*0.25, true, LINE_2_PlaceStation)
	
	StartThread(trayAnimation,TablesOfPiecesGroups["TrayShort"][3], ShortDistance, (math.random() % 4)* 7000, ShortDistance*0.25, true, LINE_3_PlaceStation)
	StartThread(trayAnimation,TablesOfPiecesGroups["TrayShort"][4], ShortDistance, (math.random() % 4)* 7000, ShortDistance*0.25, true, LINE_3_PlaceStation)

	StartThread(trayAnimation,TablesOfPiecesGroups["TrayLong"][3], LongDistance, (math.random() % 4)* 7000 , LongDistance*0.25, true, LINE_4_PlaceStation)
	StartThread(trayAnimation,TablesOfPiecesGroups["TrayLong"][4], LongDistance, (math.random() % 4)* 7000, LongDistance*0.25, true, LINE_4_PlaceStation)
		
		targetIDTable ={LINE_1_PlaceStation, LINE_2_PlaceStation }
		jointPosTable={HomePos={a=0,b=0,c=0,d=0}, PickUp={a=0,b=12,c=0,d=-7}, 
		PlaceTable ={
			[LINE_1_PlaceStation] ={a=80,b=0,c=0,d=-7}, 
			[LINE_2_PlaceStation] ={a=-55,b=-20,c=0,d=-7}, 		
			}		
		}
		StartThread(scaraAnimationLoop,1, TablesOfPiecesGroups["Object"][1], targetIDTable, jointPosTable)
		
		targetIDTable ={LINE_2_PlaceStation, LINE_3_PlaceStation}
		jointPosTable={HomePos={a=0,b=0,c=0,d=0}, PickUp={a=-45,b=-50,c=0,d=-7}, 
			PlaceTable ={
				[LINE_2_PlaceStation] ={a=65,b=45,c=0,d=-7}, 
				[LINE_3_PlaceStation] ={a=-65,b=-35,c=0,d=-7}, 		
				}		
			}
		StartThread(scaraAnimationLoop,2,  TablesOfPiecesGroups["Object"][2], targetIDTable, jointPosTable)
		
		targetIDTable ={LINE_3_PlaceStation, LINE_4_PlaceStation}
		jointPosTable={HomePos={a=0,b=0,c=0,d=0}, PickUp={a=12,b=22,c=0,d=-7}, 
			PlaceTable ={
				[LINE_3_PlaceStation] ={a=45,b=70,c=0,d=-7}, 
				[LINE_4_PlaceStation] ={a=-22,b=0,c=0,d=-7}, 		
				}		
			}
		StartThread(scaraAnimationLoop,3,  TablesOfPiecesGroups["Object"][3], targetIDTable, jointPosTable)
		
		
		
	while boolBuilding == true or true do	
		robotArmAnimationLoop()	
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

