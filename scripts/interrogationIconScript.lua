include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

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

function interrogatePercentage()
	timer = 0
	
	while not GG.raidIconPercentage or not GG.raidIconPercentage[unitID] and timer < 5000 do
		Sleep(100)
	end
	
	if timer >= 5000 then 	
		Spring.DestroyUnit(unitID,false, true)
	end
	SetUnitValue(COB.WANT_CLOAK, 0)
	showAll(unitID)
	
	while   GG.raidIconPercentage[unitID] do --GG.raidPercentageToIcon and GG.raidPercentageToIcon[unitID] do
	
		lastIndex= math.random(1,16)
		alreadyVisitedTable=makeTable(false, 16)	
		hideT(TablesOfPiecesGroups["puzzle"])
		Show(TablesOfPiecesGroups["puzzle"][lastIndex])
		alreadyVisitedTable[lastIndex] = true
		factor = math.min(20,math.max(1, GG.raidIconPercentage[unitID] * 20))
		
		while factor < 17 do
			factor = factor +1

			pieceWithNeighbour = getPieceWithNeigbhours(alreadyVisitedTable)
				if pieceWithNeighbour and (TablesOfPiecesGroups["puzzle"][pieceWithNeighbour]) then
					Show(TablesOfPiecesGroups["puzzle"][pieceWithNeighbour])
					alreadyVisitedTable[pieceWithNeighbour] = true
				end

			Sleep(1000)
			end
		Sleep(1000)
	end
	
	Spring.DestroyUnit(unitID,false, true)
end

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
end




function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

