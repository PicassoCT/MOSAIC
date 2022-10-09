include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

--include "lib_Build.lua"

function cegFunction(x,y,z) 
	cegname, sleeptime = getCegName()
	--Spring.SpawnCEG(getCegName(), x,  y + 50, z, math.random(-1,1),  math.random(-1,0),  math.random(-1,1), 60)
	--spawnCegAtPiece(unitID, Quader04, cegname, -50, 0, 0, 0)
	Sleep(sleeptime)
	name = getCegName()
	spawnCegNearUnitGround(unitID, name)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
end

function getCegName()
	echo("Cegspawn")
	return "tankfireshockwave", 1000
end
center = piece "center"
Quader04 = piece "Quader04"
Quader08 = piece "Quader08"
Quader01 = piece "Quader01"

function script.Create()
	hideAll(unitID)
	Spring.MoveCtrl.Enable(unitID,true)
	x,y,z=Spring.GetUnitPosition(unitID)
	Spring.MoveCtrl.SetPosition(unitID,x,y+150,z)
	--generatepiecesTableAndArrayCode(unitID)
	StartThread(saySay)
	StartThread(emitSFX)
	StartThread(hovertest)
	StartThread(switchMove)
	-- StartThread(testTurnInTime)
	echo(minimalAbsoluteDistance(15,-15))
	echo(minimalAbsoluteDistance(-15,-15))
	echo(minimalAbsoluteDistance(-15,15))
	echo(minimalAbsoluteDistance(360,-270))
	x,y,z = Spring.GetUnitPosition(unitID)
	echo("Unit Position: "..x.."/"..y.."/"..z)
end
Body= piece"dronetest"
InnerWing= piece"power"
HoverPoint = piece"HoverPoint"
boolMoving=false
function switchMove()
	while true do

	Sleep(100000)
	boolMoving = true
	end

end

function hovertest()
	while true do
		Turn(Body,x_axis,math.rad(math.random(-100,100)),0,true)
		Sleep(1000)
		hoverSegway(      center,
						  Body,
						 InnerWing, 
						 HoverPoint,
						 50, 
						 -90,
						 90,
						 x_axis, 
						 function(axis, p) return select(axis,Spring.UnitScript.GetPieceRotation(p)) end,
						 function() return boolMoving end, 
						 math.pi/10,
						 math.pi
						 )

	Sleep(1000)
	end
end
Kugel02 = piece"Kugel02"
function script.Killed(recentDamage, _)
	
	createCorpseCUnitGeneric(recentDamage)
	return 1
end
Quader02 = piece"Quader02"
function testTurnInTime()
	
	while true do
		reset(Quader02)
		Sleep(1000)
		turnInTime(Quader02, y_axis, 360, 5000, 0,0,0, false)
		WaitForTurns(Quader02)	
		turnInTime(Quader02, y_axis, -360, 5000, 0,360,0, false)
		WaitForTurns(Quader02)	
	end
end

function saySay()
	while true do
		Sleep(10000)
		T = prepSpeach("Test 1 2 3 ", "Honk", 64, 0.5, 500)
		
		say(T, 5000, NameColour, { r = 1.0, g = 1.0, b = 1.0 }, OptionString, unitID)
	end
end

function emitSFX()
	--StartThread(constDistanceDrag)
	StartThread(testTurnInTime)
	x, y, z = Spring.GetUnitPosition(unitID)
	i = 0
	while true do
	cegFunction(x,Spring.GetGroundHeight(x,z),z)
		
	end
end

dragInRange = 1200
liftUpRange = 900



--- -aimining & fire weapon
function script.AimFromWeapon1()
	return Kugel02
end



function script.QueryWeapon1()
	return Kugel02
end

function script.AimWeapon1(Heading, pitch)
	--aiming animation: instantly turn the gun towards the enemy
	WTurn(Kugel02,y_axis,Heading,0)
	WTurn(Kugel02,x_axis,-pitch,0)
	return true
end