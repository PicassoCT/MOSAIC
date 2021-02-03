include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "TumbleConfig"
aimpiece = center
Deployed1 = piece "Deployed1"
Deployed2 = piece "Deployed2"
boolDeployed = true

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Hide(center)
end


function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end

Salvos1 = 12
Salvos2 = 12


function script.AimFromWeapon1()
    return Deployed1
end

function script.QueryWeapon1()
    return Deployed1
end

function script.AimWeapon1(Heading, pitch)
    return boolDeployed and Salvos1 >= 0
end

function script.FireWeapon1()
	Salvos1 = Salvos1 -1
	if Salvos2 < 0 and Salvos1 < 0 then Spring.DestroyUnit(unitID,true,false) end
    return boolDeployed
end

function script.AimFromWeapon2()
    return Deployed2
end

function script.QueryWeapon2()
    return Deployed2
end

function script.AimWeapon2(Heading, pitch)
    return boolDeployed and Salvos2 >= 0 
end

function script.FireWeapon2()
	Salvos2 = Salvos2 -1
	if Salvos2 < 0 and Salvos1 < 0 then Spring.DestroyUnit(unitID,true,false) end
    return boolDeployed
end


