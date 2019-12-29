include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

base = piece "base"
aimpiece = piece "aimpiece"
emitpiece = piece "emitPiece"

local id
function attachSatellite()
	 Sleep(1)
	 x,y,z = Spring.GetUnitPosition(unitID)
	 teamID= Spring.GetUnitTeam(unitID)
	 id = Spring.CreateUnit("noone", x,y,z, 1, teamID)
	  echo("Spawning noone of id : "..id)
	 Spring.SetUnitAlwaysVisible(id,true)
	 Spring.UnitAttach(unitID, id, base)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	-- echo("Satellite Anti Script here")
	StartThread(attachSatellite)
end




function script.Killed(recentDamage, _)
	if id and isUnitAlive(id)== true then Spring.DetachUnit(id,true); Spring.DestroyUnit(id, false, true) end
	explodeD(Spring.GetUnitPieceMap(unitID), SFX.FALL + SFX.FIRE)

  return 1
end

--- -aimining & fire weapon
--- -aimining & fire weapon
function script.AimFromWeapon1()
    return emitpiece
end



function script.QueryWeapon1()
    return aimpiece
end



function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy
	

	-- WTurn(base, z_axis, Heading, math.pi)
	-- WTurn(aimpiece, x_axis, -pitch, math.pi)
    return true
end

function script.FireWeapon1()


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


