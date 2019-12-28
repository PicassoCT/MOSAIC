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

function pieceOrder(i)
if i== 1 then return 1 end
if i> 1 and i < 4 then return 2 end
if i> 3 and i < 8 then return 3 end
if i> 7 and i < 16 then return 4 end
return 0
end

function sinusWaveThread(start,ends)
local Fract=TablesOfPiecesGroups["Fract"]

	while true do
		--one animation cycle
		sintime = ((Spring.GetGameFrame()%300)/300)*2*math.pi
		base = math.abs(math.sin(sintime)*45)
		costime = ((Spring.GetGameFrame()%600)/600)*2*math.pi
		for i=start,ends do
			if Fract[i] then	
				locTimeOffset = ( math.pi)/2 -- 5seconds  divided by 4 depth
				if i% 15 ~= 1 then 
					base = 0
				end
				
				pOrder = pieceOrder(i%15)
				wavetime = costime + (locTimeOffset* pOrder)			
				wave =  math.cos(wavetime)*42            
				rVal= math.random(-6,6)
				speed= math.abs(base + wave +rVal)/100
				
				Turn(Fract[i],x_axis,math.rad(base + wave +rVal ),speed)	
			end
		end
	
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
		gameFrame = Spring.GetGameFrame()
		for i=1, #Fract, 15 do
			
			degToTurn = (360 / (#Fract/15))*(i-1)
			ndegree= math.random(10,80)
			Turn(Fract[i],y_axis,math.rad(degToTurn),math.pi)

		
		end
		WaitForTurns(Fract)
		Sleep(10)
	end
end

function script.Killed(recentDamage, _)

    return 1
end

