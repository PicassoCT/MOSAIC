include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
whirl= 		{}
	ring= 	{}
	Blue= 	{}
	Red= 	{}
	step=	{}
	PlayPos=	{}
	
function script.HitByWeapon(x, z, weaponDefID, damage)
end


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
	Blue= TablesOfPiecesGroups["Blue"]
	Red= TablesOfPiecesGroups["Red"]
	step= TablesOfPiecesGroups["Step"]
	

	showT(Blue)
	showT(Red)
end

figures={
	Red = "red", 
	Blue = "blue", 
}
function newRoundTable()
 return {
[figure.Red] = { 
PlacedFigures = {},
},
[figure.Blue] = {
PlacedFigures = {},
},


}

end
roundTable=  newRoundTable()

function revealAndEliminate()
	for team, PlacedFigures in pairs (roundtable) do
		for nr, figureTable in pairs(PlacedFigures) do
			
		end
	end
end

teams={}
pieceIndex={
[figures.Blue]= 3, --defender
[figures.Red]= 3, --agressor
}


function showPercent(percent)
	percent=math.ceil(math.max(1,percent)/100*#step)

	hideT(step)
	showT(step,1, percent)
end


function registerSnipeIcon(team, id, position)
	teamType= "empty"
	if team == myTeamID then teamType = figures.Red else teamType =  figures.Blue  end
	roundTable[teamType].PlacedFigures[#roundTable[teamType].PlacedFigures + 1 ]=    {id = id, position = position}
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
	roundStep = math.ceil(GameConfig.raid.maxRoundLength/100)
	hideT(step)
	while counter < 100 or totalTime > GameConfig.raid.maxTimeToWait do
		counter =(counter +1) 
		showPercent( counter )
		
		-- roundHasEnded
		if (counter == 100) or allStonesPlaced(teams) == true and  then
			revealAndEliminate()
			winningTeam =onePartIsOutOfStones(teams)
			if winningTeam then
				winnerBehaviour(winningTeam)
			
			end
		end
		
		totalTime= totalTime + roundStep
		Sleep(roundStep)
	end
end



function winnerBehaviour(winningTeam)
if winningTeam == myTeamID then
 GG.raidIconPercentage[unitID]  = 100
 else
 	roundTable = newRoundTable()
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

