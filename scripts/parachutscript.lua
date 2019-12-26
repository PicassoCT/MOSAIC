include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"

-- if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
-- if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end
testOffset = 300
dropRate= 0.25
function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Spring.MoveCtrl.Enable(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
	StartThread(AnimationTest)
	StartThread(fallingDown)
end

function fallingDown()
	while not GG.ParachutPassengers do
		Sleep(1)
	end
	
	while not GG.ParachutPassengers[unitID] do
		Sleep(1)
	end
	--debug code
	passengerID= GG.ParachutPassengers[unitID].id
	x,y,z =   GG.ParachutPassengers[unitID].x,  GG.ParachutPassengers[unitID].y,  GG.ParachutPassengers[unitID].z

	if not passengerID or isUnitAlive(passengerID)== false then Spring.DestroyUnit(unitID, false, true); return end
	GG.ParachutPassengers[unitID] = nil
	
	Spring.UnitAttach(unitID, passengerID, center)
	Spring.MoveCtrl.SetPosition(unitID, x,y,z)

	
	while isPieceAboveGround(unitID, center) == true do
		x,y,z =Spring.GetUnitPosition(unitID)
		Spring.MoveCtrl.SetPosition(unitID, x,y - dropRate,z)
		Sleep(1)
		
	end
	
	Spring.UnitDetach ( passengerID)
	Spring.DestroyUnit(unitID, false, true)

end

function sinusWaveThread(start,ends)
local Fract=TablesOfPiecesGroups["Fract"]
times = 0
	while true do
		for i=start,ends do
			if Fract[i] then
				rVal= math.random(-6,6)
				base = 0
				if i% 15 == 1 then base = 22 end
				wave = math.sin((i%15)*(times/8)*math.pi*2)*42
				speed = 0.15*((i%15)/15)
				Turn(Fract[i],x_axis,math.rad(base + wave +rVal ),speed)	
			end
		end
		WaitForTurns(Fract)
		times = times + 100
		Sleep(100)
	end
end

function Fibonacci_tail_call(n)
  local function inner(m, a, b)
    if m == 0 then
      return a
    end
    return inner(m-1, b, a+b)
  end
  return inner(n, 0, 1)
end

function AnimationTest()
local Fract=TablesOfPiecesGroups["Fract"]
	for i=1,#Fract do
		if i% 15 == 1 then 
			StartThread(sinusWaveThread,i ,i + 15 )
		end
	end

	while true do
		--resetAll(unitID)
		Sleep(3000)
		for i=1,#Fract do
			
			if i% 15 == 1 then 
			degToTurn= Fibonacci_tail_call(math.ceil(i/15))* 10
			WTurn(Fract[i],y_axis,math.rad(degToTurn),0)

			end
		end
		Sleep(3000)
	end
end

function script.Killed(recentDamage, _)

    return 1
end

