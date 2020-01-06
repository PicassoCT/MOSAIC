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
myDefID = Spring.GetUnitDefID(unitID)
center = piece "center"
aimpiece = center
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

typeTankMap= {
["depressol"] = 1,
["tollwutox"] = 2,
["orgyanyl"] = 3,
["wanderlost"] = 4
}

function colCode(searchstr)
	for name, num in pairs(typeTankMap) do
		if string.match(searchstr, name) then return num end
	end

return 1
end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideT(TablesOfPiecesGroups["Tank"])
	Show(TablesOfPiecesGroups["Tank"][colCode(UnitDefs[myDefID].name)])
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
	Turn(center,x_axis,math.rad(10),0)
	spinT(TablesOfPiecesGroups["uprotor"],y_axis, 350, 9500)
	for i=1,#TablesOfPiecesGroups["downrotor"] do
		if TablesOfPiecesGroups["downrotor"][i] then
		Spin(TablesOfPiecesGroups["downrotor"][i],y_axis, math.rad(350),0)
		end
	end
end

function script.StopMoving()
	Turn(center,x_axis,math.rad(0),0)
	stopSpinT(TablesOfPiecesGroups["uprotor"],y_axis,math.pi)
	for i=1,#TablesOfPiecesGroups["downrotor"] do
		if TablesOfPiecesGroups["downrotor"][i] then
			StopSpin(TablesOfPiecesGroups["downrotor"][i],y_axis, math.pi)
		end
	end
end
function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

