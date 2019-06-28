include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "Frame"
door = 1
spys={}
function script.Create()
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
	Spring.MoveCtrl.Enable(unitID)
	ox,oy,oz = Spring.GetUnitPosition(unitID)
	Spring.SetUnitPosition(unitID, ox,oy + 50, oz)
	showAll(unitID)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(raidAnimationLoop)
	StartThread(raidPercentage)	
	door= TablesOfPiecesGroups["door"][1]
	spys= TablesOfPiecesGroups["spy"]
end
	agentActiveCounter= 0
function agentOneThread()
agentActiveCounter = agentActiveCounter+1

	Move(spys[1], y_axis, -100*4, 768)
	randVal= math.random(-120,-70)
	Turn(spys[1], y_axis, math.rad(randVal), 5)	

	Sleep(900)
	randVal= math.random(-15,25)
	Turn(spys[1], y_axis, math.rad(randVal	), 8)
	WMove(spys[1], y_axis, -100*4, 512)
	randVal= math.random(60,100)
	Turn(spys[1], y_axis, math.rad(randVal), 3)
	WMove(spys[1], y_axis, -130*4, 512)
	randVal= math.random(0,30)
	Turn(spys[1], y_axis, math.rad(randVal), 3)
	WMove(spys[1], x_axis, -50*4, 512)
		randVal= math.random(0,30)
	WTurn(spys[1], y_axis, math.rad(150), 3)
	Hide(spys[1])

agentActiveCounter = agentActiveCounter-1
end

function agentTwoThread()
agentActiveCounter = agentActiveCounter+1

	WMove(spys[2], x_axis, 50*4, 512
	)
	randVal= math.random(0,30)  + 90
	Turn(spys[2], y_axis, math.rad(randVal), 12)
	randVal= math.random(-80,-40)
	WMove(spys[2], y_axis, randVal*4, 512)
	randVal= math.random(45,140) 
	WTurn(spys[2], y_axis, math.rad(randVal), 8)
	randVal= math.random(60,90) 
	WMove(spys[2], x_axis, randVal*4, 512)
	randVal= math.random(70, 120) 
	WTurn(spys[2], y_axis, math.rad(randVal), 8)
	randVal= math.random(60,90) 
	randVal= math.random(0,30)  + 90
	Turn(spys[2], y_axis, math.rad(randVal), 12)
	Move(spys[2], x_axis, 70*4, 512)
	WMove(spys[2], y_axis, -160*4, 512)
	WTurn(spys[2], y_axis, math.rad(60), 3)
	WTurn(spys[2], y_axis, math.rad(120), 2)
	Sleep(500)
	Hide(spys[2])

agentActiveCounter = agentActiveCounter-1
end

function agentThreeThread()
agentActiveCounter = agentActiveCounter+1
spy = spys[3]

	WMove(spy, x_axis, -50*4, 256
	)
	randVal= math.random(0,30)  - 90
	Turn(spy, y_axis, math.rad(randVal), 12)

	WMove(spy, y_axis, -120, 256)
	randVal= math.random(-150,-120) 
	WTurn(spy, y_axis, math.rad(randVal), 8)
	randVal= math.random(60,90) 
	WMove(spy, x_axis, randVal*4, 512)
	randVal= math.random(160, 180) 
	WTurn(spy, y_axis, math.rad(randVal), 8)

	randVal= math.random(60,80) *-1
	Turn(spy, y_axis, math.rad(randVal), 12)
	Move(spy, x_axis, 70*4, 512)
	WMove(spy, y_axis, -160*4, 512)
	WTurn(spy, y_axis, math.rad(180), 3)
	Sleep(500)
	Hide(spy)

agentActiveCounter = agentActiveCounter-1
end

function raidAnimationLoop()
	Sleep(100)
	agentActiveCounter= 0
	while true do
	resetAll(unitID)
	Sleep(100)
	showT(spys)
	Sleep(1000)	
	WTurn(door,y_axis,math.rad(115), 90)
	Turn(door,y_axis,math.rad(110), 50)
	StartThread(agentOneThread)
	StartThread(agentTwoThread)
	StartThread(agentThreeThread)
	Sleep(100)
	
	while agentActiveCounter ~= 0 do
		Sleep(100)
	end
	WTurn(door,y_axis,math.rad(0), 15)
	
	Sleep(4000)
	end
end
function raidPercentage()

	while not GG.raidIconPercentage or not GG.raidIconPercentage[unitID] do
		Sleep(100)
	end

	while   GG.raidIconPercentage[unitID] do --GG.raidPercentageToIcon and GG.raidPercentageToIcon[unitID] do
		hideT(TablesOfPiecesGroups["door"])
		hideT(TablesOfPiecesGroups["bdoor"])
		factor =  math.min(20,math.max(1, GG.raidIconPercentage[unitID] * 20))
		
		showT(TablesOfPiecesGroups["door"], 1, math.floor(factor))
		showT(TablesOfPiecesGroups["bdoor"], 1, math.floor(factor))
		showT(TablesOfPiecesGroups["bdoor"], 21, 21+ math.floor(factor))
		showT(TablesOfPiecesGroups["bdoor"], 41, 41+ math.floor(factor))
		Sleep(100)
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

