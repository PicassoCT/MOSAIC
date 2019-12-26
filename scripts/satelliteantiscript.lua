include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


center = piece "center"
turret = piece "turret"

function script.Create()
	Spin(center,y_axis,math.rad(1),0.5)
	
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
	Explode(center, SFX.SHATTER)

    return 1
end



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


function script.AimFromWeapon1()

        return turret

end

function script.QueryWeapon1()
	return turret
end



function script.AimWeapon1( heading, pitch)
	 Turn(turret,y_axis, heading,10)
	 Turn(turret,y_axis, -pitch, 10)
    return true
end


