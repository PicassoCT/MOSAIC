include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
center = piece "center"
base = piece "base"
slider = piece "slider"
turret = piece "turret"
projectile = piece "projectile"

GameConfig = getGameConfig()
if not GG.UnitHeldByHouseMap then GG.UnitHeldByHouseMap = {} end

boolBuilding = false
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Hide(projectile)
	Move(projectile,z_axis, -210,0)
	T= process(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange*2),
				function(id)
					if isUnitInGroup(id, "house", GameConfig.instance.culture, UnitDefs)== true then
						return id
					end
				end
				)
				
	GG.UnitHeldByHouseMap[unitID] = T[1]
	StartThread(mortallyDependant, unitID, T[1], 15, false, true)
	StartThread(goToFireMode)
	StartThread(modeChangeOS)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
end

function modeChangeOS()
	oldBuildState= boolBuilding
	while true do
	buildID = Spring.GetUnitIsBuilding(unitID)
		if buildID then 
			boolBuilding = true	
			if oldBuildState ~= boolBuilding then
				oldBuildState = boolBuilding
				StartThread(goToSpaceMode)
			end			
		else
			boolBuilding = false
			if oldBuildState ~= boolBuilding then
				oldBuildState = boolBuilding
				StartThread(goToFireMode)
			end
		end
	Sleep(100)
	end

end

function goToSpaceMode()
	WTurn(turret,x_axis, math.rad(-90), math.pi)
	Move(slider,z_axis, -350, 50)

end

function goToFireMode()
	WMove(slider,z_axis, 0, 50)
	WTurn(turret,x_axis, math.rad(0), math.pi)
end

--- -aimining & fire weapon
function script.AimFromWeapon1()
    return projectile
end

function script.QueryWeapon1()
    return projectile
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy
	if boolBuilding == true then return false end
	
        WTurn(center, y_axis, Heading, 0.4)
        WTurn(turret, x_axis, -pitch, 0.7)
		
    return true
end


function script.FireWeapon1()

    return true
end



function script.StartBuilding()
end

function script.StopBuilding()
end
function script.Activate()
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end

function script.Deactivate()
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    return 0
end

function script.QueryBuildInfo()
    return projectile
end

Spring.SetUnitNanoPieces(unitID, { projectile })

function script.Killed(recentDamage, _)
	GG.UnitHeldByHouseMap[unitID] = nil
    --createCorpseCUnitGeneric(recentDamage)
    return 1
end



boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if  boolCloaked == true then
        hideAll(unitID)
		if TablesOfPiecesGroups then
			showT(TablesOfPiecesGroups["Icon"])
		end
    else
        showAll(unitID)
		if TablesOfPiecesGroups then
			hideT(TablesOfPiecesGroups["Icon"])
		end
    end
end