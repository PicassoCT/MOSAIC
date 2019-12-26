include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(attachLaser)
end

function attachLaser()
 Sleep(1)
 id = createUnitAtUnit(Spring.GetUnitTeam(unitID), "noone", unitID) 
 Spring.UnitAttach(unitID, id, center)
end


function script.Killed(recentDamage, _)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1()
    return aimpiece
end



function script.QueryWeapon1()
    return emitpiece
end




function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy
	

	WTurn(base, y_axis, Heading, math.pi)
	WTurn(aimpiece, x_axis, -pitch, math.pi)
	EmitSfx(aimpiece, 2048)
    return true
end


function script.FireWeapon1()

    return true
end



function script.StartMoving()
end

function script.StopMoving()
end

function script.Activate()
    return 1
end

function script.Deactivate()

/cheat
    return 0
end


