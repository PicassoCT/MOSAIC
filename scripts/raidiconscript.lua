include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
whirl= 		{}
	ring= 	{}
	White= 	{}
	Black= 	{}
	step=	{}
	PlayPos=	{}
	
function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
Progresscenter = piece "Progresscenter"

protagon_talk ={
"SkyCastle Ready",
"Retro-Observation-Results",
"TAC Plan has go",
"(dart sounds)",
"away from the window",
"to the wall",
"drop it", 
"Defeat device removed",
"Subjects are dosed and stable",
"System subverted",
"Observation, Neutralization",
"Encapsulated Cloud Interrogation ",
"Individual Deprecation ",
"Sampling Artefacts",
"FragPellets in Sit, HiSpeedCam, Upload (BOOM)",
"Investigating Distribution",
}

antagon_talk ={
"-your guests torture people",
"kings things, puppets and strings",
"I m a old friend, i need the key for one day, to throw a suprise party..",
"Suprise, Motherfuckers",
"God is greater",
"This must hurt so much ?",
"Suffer like they did",
"Talk, talk - your live depends on it",
"Your side simply gave you up..",
"Though i walk through the valley of shadows",
"we, we are your own shadow, thats what you fight",
"you would never betray them, but they already betrayed you",
"You shouldnt have fucked her-",
"And though i walk in the valley of death"


}

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
	StartThread(raidAnimationLoop)
	-- StartThread(raidPercentage)	
	whirl= TablesOfPiecesGroups["Whirl"]
	ring= TablesOfPiecesGroups["Ring"]
	White= TablesOfPiecesGroups["White"]
	Black= TablesOfPiecesGroups["Black"]
	step= TablesOfPiecesGroups["Step"]
	PlayPos= TablesOfPiecesGroups["PlayPos"]
	hideT(White)
	hideT(Black)
end

figures={
empty = "empty", 
black = "black", 
white = "white", 
}

gameTable= makeTable({ figure= figures.empty}, 3,3, 3)

orderMap={
[1]=1,
[2]=2,
[3]=3,
[4]=6,
[5]=9,
[6]=8,
[7]=7,
[8]=4
}

reversePieceMap ={}
pieceMap = Spring.GetUnitPieceMap(unitID)
for k,v in pairs(pieceMap) do
reversePieceMap[v] = k
end

function mapPieceNumberToGridPos(nr)
	if nr >0 and nr < 4 then x = 1 end
	if nr == 4 or nr == 8 then x = 2 end
	if nr > 4  and nr < 8 then x = 3 end
	z = orderMap[nr]
end

teams={}
function mapTeamToSide(teamID)
	if teams[teamID] then return  teams[teamID] end

	if #teams == 1 then 
	teams[teamID] = figures.white
	end

	if #teams == 0 then 
	teams[teamID] = figures.black
	end

	return  teams[teamID]

end
lastChangedPiece= nil

function addPiece(playerID, clickedOnPiece, team)
	
	 indexGrid,indexPosX,indexPosZ = getField(clickedOnPiece)
	 setField(indexGrid,indexPosX,indexPosZ, mapTeamToSide(team))
	 lastChangedPiece = clickedOnPiece
end

function getField(clickedOnPiece)
	pieceNumber = string.tonumber(reversePieceMap[clickedOnPiece]:gsub("PlayPos",""))
	indexGrid = math.ceil(pieceNumber/8)
	indexPosX, indexPosZ = mapPieceNumberToGridPos((pieceNumber%8)+1)
	return indexGrid,indexPosX,indexPosZ, gameTable[indexGrid][indexPosX][indexPosZ]
end

function setField(indexGrid,indexPosX,indexPosZ, typeToSet)
	gameTable[indexGrid][indexPosX][indexPosZ] = {figure = typeToSet}
end

function selectPieceInteractPiece(playerID, firstPiece, targetPiece)
	--check if piece contains player piece
	x,y,z, field = getField(firstPiece)
	assert(field)

	if field.figure == mapTeamToSide(Spring.GetPlayerTeamID(playerID)) then
	--check if piece position is empty
	tx,ty,tz, tfield = getField(targetPiece)
	assert(tfield)

	if tfield.figure== figures.empty then
		setField(tx,ty,tz, field.figure)
		setField(x,y,z, field.empty)
		lastChangedPiece = targetPiece
	end

	end
end

function getOffset(index)
if index == 1 then
return -1, -1
end

if index == 2 then
return 0, -1
end

if index == 3 then
return 1, -1
end

if index == 4 then
return 1, 0
end

if index == 5 then
return 1, 1
end

if index == 6 then
return 0, 1
end

if index == 7 then
return -1, 1
end

if index == 8 then
return -1, 0
end

end


function roundEndCheck()
boolMillClosed = false
-- check around lastChangedPiece,
	if lastChangedPiece then
		x, y, z, field = getField(lastChangedPiece)
		for i=1, 8 do
		ox, oz = getOffset(i)
		-- if gameTable[][][]
		
		-- end
	
		
		end
	end
	return boolMillClosed
end

function showPercent(percent)
	percent=math.ceil(math.max(1,percent)/100*#step)

	hideT(step)
	showT(step,1, percent)
end



function raidAnimationLoop()
	Sleep(100)
	resetAll(unitID)
	
	index = 0
	process(ring,
		function(id)
			index= index + 1
			Spin(id, y_axis, math.rad(index* 4.2)*randSign(), 0.5)
			StartThread(waveSpin, id, math.random(4,24), math.random(4,40))
		end
	)
	Spin(Progresscenter, y_axis, math.rad(42),0.5)
	Spin(ring[8], y_axis, math.rad(42),0.5)
	process(whirl,
		function(id)
			Spin(id, y_axis, math.rad(42)*randSign(), 0.5)
			StartThread(waveSpin, id, math.random(4,24)*50, math.random(4,800), true)
		end
	)
	local counter = 1
	hideT(step)
	while true do
		counter =(counter +1) 
			showPercent( counter )
			if counter == 100 then counter = 0 end
		Sleep(100)
	end
end

function waveSpin(id, val, speed, randoHide)
	if val < 1 then val = 1 end
	
	while true do
	if randoHide and maRa() == true then Hide(id) else Show(id) end
	WMove(id, z_axis,val, speed)
	if randoHide and maRa() == true then Hide(id) else Show(id) end

	WMove(id, z_axis,val*-1, speed)
	end
end

function raidPercentage()
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

		Sleep(100)
	end
	Spring.DestroyUnit(unitID,false, true)
end
function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end




function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

