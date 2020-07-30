include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
triangleTurret = piece "triangleTurret"
triangle =   {}

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	--setSpeedToZero, allow for rotation
	triangle = TablesOfPiecesGroups["triangle"]
	-- Spring.MoveCtrl.Enable(unitID,true)
	-- x,y,z =Spring.GetUnitPosition(unitID)
	-- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
	-- StartThread(AnimationTest)
end

function getAimTriangleWorldCoords()


end


function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end


-- - -aimining & fire weapon
function script.AimFromWeapon1()
    return aimpiece
end



function script.QueryWeapon1()
    return aimpiece
end

function script.AimWeapon1(Heading, pitch)
	Turn(triangleTurret, y_axis, Heading, 0)
    return true
end


function script.FireWeapon1()

    return true
end

