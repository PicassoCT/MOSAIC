include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

local myDefID = UnitDefNames["snipeicon"].id
local myTeam = Spring.GetUnitTeam(unitID)
local myParent = nil
TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "base"
-- Turret = piece "triangleTurret"
triangle =   {}
Turrets =   {}
turretTriangle = nil
function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	--setSpeedToZero, allow for rotation
	
	triangle = TablesOfPiecesGroups["Tris"]
	Turrets = TablesOfPiecesGroups["Turret"]
	hideT(Turrets)
	hideT(triangle)
	Show(Turrets[math.random(1,#Turrets)])
	
	turretTriangle  = triangle[1]
	setSpeedEnv(unitID, 0.0)
	-- x,y,z =Spring.GetUnitPosition(unitID)
	-- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
	StartThread(TriangleTest)
	StartThread(DelayedRegister)
	
end


function DelayedRegister()
	while not GG.SnipeIconCreator or not GG.SnipeIconCreator[unitID]  do
		Sleep(100)
	end

   GG.SniperIcon:Register( unitID, myTeam, GG.SnipeIconCreator[unitID] )
   myParent = GG.SnipeIconCreator[unitID]
   GG.SnipeIconCreator[unitID] = nil
end

function TriangleTest()
	while true do
	Sleep(1000)
	process(getUnitsInTriangle(),
		function (id)
			Spring.Echo("Unit "..id.. " is in triangle")
		end
	)
	end
end

function getUnitsInTriangle()
	maxRange = 85
	worldPos ={}
	x,y,z= Spring.GetUnitPosition(unitID)
	for i=1, #triangle do
	worldPos[#worldPos+1] ={}
		worldPos[#worldPos].x,_,worldPos[#worldPos].z = Spring.GetUnitPiecePosDir(unitID, triangle[i])
	end
	
	return process(getAllInCircle(x,z, maxRange,unitID), --all units in range
			function(id)  -- all units of defID
				if Spring.GetUnitDefID(id) == myDefID then
				return id
				end			
			end,
			function(id) -- all Units In Triangle
				px,py,pz =Spring.GetUnitPosition(id)
				if pointWithinTriangle(worldPos[1].x,worldPos[1].z, worldPos[2].x, worldPos[2].z, worldPos[3].x, worldPos[3].z, px,pz) then
					Spring.Echo("Unit in circle "..id)
					return id
				end
			end
			)


end


function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end


-- - -aimining & fire weapon
function script.AimFromWeapon1()
    
	
	return center
	
end



function script.QueryWeapon1()
    return center
end

function script.AimWeapon1(Heading, pitch)
	if center then
		WTurn(center, y_axis, -math.pi +  Heading, 0)
	end
    return true

end


function script.FireWeapon1()

    return true
end

