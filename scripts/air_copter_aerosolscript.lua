include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end
chemTrails = getChemTrailTypes()
aerosoltype = chemTrails.wanderlost

center = piece "center"

aimpiece = piece "aimpiece"
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	GG.SelectedAerosol[unitID] = "wanderlost"
	-- StartThread(AnimationTest)
end

function script.Killed(recentDamage, _)

    return 1
end


--aimining & fire weapon
function script.AimFromWeapon1()
    return aimpiece
end

function script.QueryWeapon1()
    return aimpiece
end

function script.AimWeapon1(Heading, pitch)
return true
end



function script.FireWeapon1()
	Command(unitID, "setactive", 1)
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

    return 0
end

