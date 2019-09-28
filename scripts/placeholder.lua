include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	-- StartThread(AnimationTest)
end

-- function AnimationTest()
-- while true do
	-- resetAll(unitID)
	-- Sleep(3000)
		-- WTurn(right,z_axis,math.rad(-89),math.pi)
		-- WTurn(left,z_axis,math.rad(89),math.pi)
	-- Sleep(3000)
	-- Turn(left,y_axis,math.rad(-89),math.pi)
	-- WTurn(right,y_axis,math.rad(89),math.pi)
	
	-- Turn(left,y_axis,math.rad(89),math.pi)	
	-- WTurn(right,y_axis,math.rad(-89),math.pi)
	-- end
-- end

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
-- function script.AimFromWeapon1()
    -- return aimpiece
-- end



-- function script.QueryWeapon1()
    -- return aimpiece
-- end

-- function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    -- return true
-- end


-- function script.FireWeapon1()

    -- return true
-- end



function script.StartMoving()
end

function script.StopMoving()
end

function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

-- function script.QueryBuildInfo()
    -- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

