include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


function script.Create()
	Spring.MoveCtrl.Enable(unitID)
	ox,oy,oz = Spring.GetUnitPosition(unitID)
	Spring.SetUnitPosition(unitID, ox,oy + 50, oz)
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
	-- while not GG.raidPercentageToIcon or not GG.raidPercentageToIcon[unitID] do
		-- Sleep(100)
	-- end
	Sleep(100)
	while  true do --GG.raidPercentageToIcon and GG.raidPercentageToIcon[unitID] do
		lastIndex= math.random(1,16)
		alreadyVisitedTable=makeTable(false, 16)	
		hideT(TablesOfPiecesGroups["puzzle"])
		Show(TablesOfPiecesGroups["puzzle"][lastIndex])
		alreadyVisitedTable[lastIndex] = true
		factor = 1
		
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

