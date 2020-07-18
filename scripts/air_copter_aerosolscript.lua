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
SIG_AEROSOL_DEPLOY = 1
emitor = piece "emitor"
center = piece "center"
aimpiece = center
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end
timeTank = 9999

typeTankMap= {
["depressol"] = 1,
["tollwutox"] = 2,
["orgyanyl"] = 3,
["wanderlost"] = 4
}
defIDTypeTankMap= {
[UnitDefNames["air_copter_aerosol_depressol"].id] = 1,
[UnitDefNames["air_copter_aerosol_tollwutox"].id] = 2,
[UnitDefNames["air_copter_aerosol_orgyanyl"].id] = 3,
[UnitDefNames["air_copter_aerosol_wanderlost"].id] = 4
}

AerosolUnitDefIDMap =getAerosolUnitDefIDs(UnitDefNames)

function colCode(searchstr)
	for name, num in pairs(typeTankMap) do
		if string.match(searchstr, name) then return num end
	end

return 1
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideT(TablesOfPiecesGroups["Tank"])
	Show(TablesOfPiecesGroups["Tank"][colCode(UnitDefs[myDefID].name)])
	timeTank = GG.GameConfig.Aerosols[AerosolUnitDefIDMap[myDefID]].sprayTimePerUnitInMs
	StartThread(aerosolDeployCegs)
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
	for i=1,#TablesOfPiecesGroups["lowrotor"] do
		if TablesOfPiecesGroups["lowrotor"][i] then
		Spin(TablesOfPiecesGroups["lowrotor"][i],y_axis, math.rad(1900),500)
		end
	end
end

function script.StopMoving()
	Turn(center,x_axis,math.rad(0),0)
	stopSpinT(TablesOfPiecesGroups["uprotor"],y_axis,math.pi)
	for i=1,#TablesOfPiecesGroups["lowrotor"] do
		if TablesOfPiecesGroups["lowrotor"][i] then
			StopSpin(TablesOfPiecesGroups["lowrotor"][i],y_axis, math.pi)
		end
	end
end

boolStopped= false
boolDeactivated= true

function aerosolDeployCegs()
Sleep(100)

local lisUnitFlying = isUnitFlying					 

	
	
	while true do 
		while lisUnitFlying(unitID)== true and timeTank > 0 do
			EmitSfx(emitor, 1023 + defIDTypeTankMap[myDefID])
			Sleep(100)
			spinRand(emitor, -90, 90, 0.5)
			timeTank= timeTank -100
			sprayTank()
		end
	if timeTank <= 0 then
		Spring.SetUnitNoSelect(unitID, false, true)
		Spring.DestroyUnit(unitID, false, true)
	end
	Sleep(100)
	end
end

local GameConfig = getGameConfig()
if not GG.AlreadyInfluenced then GG.AlreadyInfluenced ={} end
suspectableTypes =getChemTrailInfluencedTypes(UnitDefs)
alreadyChecked ={}

function sprayTank()
process(getAllNearUnit(unitID, GameConfig.Aerosols.sprayRange),
		function (id)
			if alreadyChecked[id] then return end
			
			if not GG.AlreadyInfluenced[id] and suspectableTypes[Spring.GetUnitDefID(id)] then
				return id
			else
				alreadyChecked[id]= id
			end
		end,
		function(id)
			GG.AlreadyInfluenced[id] = true
			 env = Spring.UnitScript.GetScriptEnv(id)
			if env and env.setBehaviourStateMachineExternal then

				Spring.UnitScript.CallAsUnit(unitID, env.setBehaviourStateMachineExternal, true, AerosolUnitDefIDMap[myDefID], true)
			end
		end
	)
end

function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end

