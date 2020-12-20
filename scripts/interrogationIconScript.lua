include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
center = piece"Center"
Rotator = piece"Rotator"
GameConfig = getGameConfig()
function script.HitByWeapon(x, z, weaponDefID, damage)
end


function script.Create()
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
	Spring.MoveCtrl.Enable(unitID)
	ox,oy,oz = Spring.GetUnitPosition(unitID)
	Spring.SetUnitPosition(unitID, ox,oy + 125, oz)
	showAll(unitID)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

	StartThread(interrogatePercentage)	

end

function getPieceWithNeigbhours(mapTable)

randStart = math.random(#mapTable) 

	for i= randStart, #mapTable do
	curCursor = i
		if mapTable[curCursor] == false then
			dirDice = math.random(1,4)
			
			if dirDice == 1 and  mapTable[i -1] and mapTable[i -1] == true then return curCursor end
			if dirDice == 2 and  mapTable[i +1] and mapTable[i +1] == true then return curCursor end
			if dirDice == 3 and  mapTable[i -4] and mapTable[i -4 ] == true then return curCursor end
			if dirDice == 4 and  mapTable[i + 4] and mapTable[i  +4 ] == true then return curCursor end
		end
	end
	
	for i= 1, randStart do
	curCursor = i
		if mapTable[curCursor] == false then
			dirDice = math.random(1,4)
			
			if dirDice == 1 and  mapTable[i -1] and mapTable[i -1] == true then return curCursor end
			if dirDice == 2 and  mapTable[i +1] and mapTable[i +1] == true then return curCursor end
			if dirDice == 3 and  mapTable[i -4] and mapTable[i -4 ] == true then return curCursor end
			if dirDice == 4 and  mapTable[i + 4] and mapTable[i  +4 ] == true then return curCursor end
		end
	end

	for i= 1, #mapTable do
	curCursor = i
		if mapTable[curCursor] and mapTable[curCursor] == false then return curCursor end
	end
end

function showTime()
	showAll()
	hideT(TablesOfPiecesGroups["Load"])	
	Spin(Rotator,y_axis,math.rad(42),15)
		while true do
			StartThread(visualizeProgress)
			showT(TablesOfPiecesGroups["Load"], 1, 	math.max(1, #TablesOfPiecesGroups["Load"] * getCurrentPercent()))
			Sleep(startCountDown)
			for i=1,#TablesOfPiecesGroups["Ring"] do
				val = math.random(2,15)*randSign()
				speed= math.random(5,25)
				Spin(TablesOfPiecesGroups["Ring"][i],y_axis, math.rad(val),speed)
			end
			Sleep(1)
		end
end

function getCurrentPercent()
	return ( startCountDown / (startCountDown-countDown))
end

countDown = (GameConfig.InterrogationTimeInFrames/30)*1000
startCountDown = countDown
OnePercent = math.ceil(countDown /100)

function interrogatePercentage()
	timer = 0
	StartThread(showTime)	
--[[	while not GG.raidIconDone or not GG.raidIconDone[unitID]  do
		Sleep(100)
		timer = timer + 100
		if timer > 5000 then 
			Spring.DestroyUnit(unitID,false, true)
		end
	end--]]

	SetUnitValue(COB.WANT_CLOAK, 0)

	while  countDown > 0 do --GG.raidPercentageToIcon and GG.raidPercentageToIcon[unitID] do
		Sleep(OnePercent)
		countDown = math.max(0, countDown - OnePercent)
		Spring.Echo( "Interrogation running :" ..countDown)
	end

	--GG.raidIconDone[unitID].boolInterogationComplete = true
	--Spring.DestroyUnit(unitID,false, true)
end

function visualizeProgress()
		lastIndex= math.random(1,16)
		alreadyVisitedTable=makeTable(false, 16)	
		hideT(TablesOfPiecesGroups["puzzle"])
		Show(TablesOfPiecesGroups["puzzle"][lastIndex])
		alreadyVisitedTable[lastIndex] = true
		factor = math.min(20,math.max(1, getCurrentPercent()* 20))
		
		while factor < 17 do
			factor = factor +1

			pieceWithNeighbour = getPieceWithNeigbhours(alreadyVisitedTable)
				if pieceWithNeighbour and (TablesOfPiecesGroups["puzzle"][pieceWithNeighbour]) then
					Show(TablesOfPiecesGroups["puzzle"][pieceWithNeighbour])
					alreadyVisitedTable[pieceWithNeighbour] = true
				end

			Sleep(1000)
		end
end

function script.Killed(recentDamage, _)
    return 1
end




function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

