include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

-- base = piece "base"
-- aimpiece = piece "aimpiece"
-- emitpiece = piece "emitPiece"

local id
function attachSatellite()
	 Sleep(1)
	 x,y,z = Spring.GetUnitPosition(unitID)
	 teamID= Spring.GetUnitTeam(unitID)
	 id = Spring.CreateUnit("noone", x,y,z, 1, teamID)
	 -- Spring.SetUnitAlwaysVisible(id,true)
	 Spring.UnitAttach(unitID, id, base)
	 Spring.SetUnitNoSelect(id,true)
	 
	 while isUnitAlive(id) == true do
		Sleep(10)
		transferOrders(unitID, id)
	 end
	 Spring.DestroyUnit(unitID,true, false)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	-- echo("Satellite Anti Script here")
	StartThread(attachSatellite)
	StartThread(delayedShow)
end
function delayedShow()
	Packed = piece "Packed"	
	hideAll(unitID)
	Show(Packed)
	waitTillComplete(unitID)
	Explode(Packed, SFX.SHATTER)
	showAll(unitID)
	Hide(Packed)

end




function script.Killed(recentDamage, _)
	if id and isUnitAlive(id)== true then Spring.DetachUnit(id,true); Spring.DestroyUnit(id, false, true) end
	explodeD(Spring.GetUnitPieceMap(unitID), SFX.SHATTER + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)

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


