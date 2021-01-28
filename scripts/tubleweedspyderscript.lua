include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "TumbleConfig"
-- left = piece "left"
-- right = piece "right"
aimpiece = center
Deployed1 = piece "Deployed1"
Deployed2 = piece "Deployed2"

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Deployed"])
    Turn(center,y_axis,math.rad(90),0)

end


function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end

Salvos1 = 12
Salvos2 = 12

function script.AimFromWeapon1()
    return aimpiece
end

function script.QueryWeapon1()
    return aimpiece
end

function script.AimWeapon1(Heading, pitch)
    return boolDeployed == false
end

function script.FireWeapon1()
	Spring.DestroyUnit(unitID,true,false)
    return boolDeployed == false
end

function script.AimFromWeapon2()
    return Deployed1
end

function script.QueryWeapon2()
    return Deployed1
end

function script.AimWeapon2(Heading, pitch)
    return boolDeployed and Salvos1 >= 0
end

function script.FireWeapon2()
	Salvos1 = Salvos1 -1
	if Salvos2 < 0 and Salvos1 < 0 then Spring.DestroyUnit(unitID,true,false) end
    return boolDeployed
end

function script.AimFromWeapon3()
    return Deployed2
end

function script.QueryWeapon3()
    return Deployed2
end

function script.AimWeapon3(Heading, pitch)
    return boolDeployed and Salvos2 >= 0 
end

function script.FireWeapon3()
	Salvos2 = Salvos2 -1
	if Salvos2 < 0 and Salvos1 < 0 then Spring.DestroyUnit(unitID,true,false) end
    return boolDeployed
end

function script.StartMoving()
	if not boolDeployed then
		Spin(center, x_axis,math.rad(180), 0.7)
	end
end

function script.StopMoving()
	if not boolDeployed then
	StopSpin(center, x_axis, 0.1)
	end
end

function script.Activate()
	StartThread(deploy)
    return 1
end

boolDeployed= false
function deploy()
	boolDeployed = true
	setSpeedEnv(unitID, 0.0)

	Hide(center)
    showT(TablesOfPiecesGroups["Deployed"])
end

function script.Deactivate()
    return 0
end
