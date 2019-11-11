include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

-- center = piece "center"

-- if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
-- if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Spring.MoveCtrl.Enable(unitID,true)
	x,y,z =Spring.GetUnitPosition(unitID)
	Spring.MoveCtrl.SetPosition(unitID, x,y+200,z)
	StartThread(AnimationTest)
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

				WTurn(Fract[i],y_axis,math.rad((i/15)*22),0)
				--spi= math.random(-2,2)
				--Spin(Fract[i],y_axis, math.rad(spi),0.01)
			end
		end
		Sleep(3000)
	end
end

function script.Killed(recentDamage, _)

    return 1
end

