include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"

attachpoint = piece "attachpoint"
Packed = piece "Packed"

local id
function attachSatellite()
	 Sleep(1)
	 x,y,z = Spring.GetUnitPosition(unitID)
	 teamID= Spring.GetUnitTeam(unitID)
	 id = Spring.CreateUnit("noone", x,y,z, 1, teamID)
	 -- Spring.SetUnitAlwaysVisible(id,true)
	 Spring.UnitAttach(unitID, id, attachpoint)
	 sendMessage(unitID, id)
	 Spring.SetUnitNoSelect(unitID,true)
	 hp,mp = Spring.GetUnitHealth(id)
	 while hp and hp > 0  do
		hp,mp = Spring.GetUnitHealth(id)
		Sleep(10)

	 end
	 Spring.DestroyUnit(unitID,true, false)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	-- echo("Satellite Anti Script here")

	StartThread(delayedShow)
end
function delayedShow()
	Turn(center,x_axis,math.rad(180),0)
	hideAll(unitID)
	Show(Packed)
	waitTillComplete(unitID)
	WTurn(center,x_axis,math.rad(0),math.pi)
	spindeg= math.random(10,42)*randSign()
	Spin(center,y_axis,math.rad(spindeg),0.01)
	Explode(Packed, SFX.SHATTER)
	showAll(unitID)
	Hide(Packed)
	StartThread(attachSatellite)


end




function script.Killed(recentDamage, _)
	if id and isUnitAlive(id)== true then Spring.UnitDetach (id,true); Spring.DestroyUnit(id, true, false) end
	explodeD(Spring.GetUnitPieceMap(unitID), SFX.SHATTER )
	-- explodeD(Spring.GetUnitPieceMap(unitID),  SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)

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


