include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "Elevator"
Icon = piece "Icon"

teamID = Spring.GetUnitTeam(unitID)
stepIndex = 0
rocketHeigth= 4200
stepHeight = rocketHeigth/GameConfig.LaunchReadySteps

function script.Create()
	if not GG.Launchers then GG.Launchers = {} end
	if not GG.Launchers[teamID] then GG.Launchers[teamID] = {} end
	GG.Launchers[teamID][unitID]= 0
	
	
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Move(center,y_axis,-1* rocketHeigth, 0)
	hideT(TablesOfPiecesGroups["Step"])
	StartThread(accountForBuiltLauncherSteps)
end

launcherStepDefID = UnitDefNames["launcherstep"].id
function accountForBuiltLauncherSteps()
	while true do 
		-- Spring.Echo("Detect Upgrade")
		buildID = Spring.GetUnitIsBuilding(unitID)
		if buildID then
		
			buildDefID = Spring.GetUnitDefID(buildID)
			if buildDefID == launcherStepDefID  then
				waitTillComplete(buildID)
				stepIndex = stepIndex +1
				Move(center,y_axis,math.min( -rocketHeigth + stepIndex*stepHeight, 0), 10)
				showT(TablesOfPiecesGroups["Step"],0,stepIndex)
				GG.Launchers[teamID][unitID] = GG.Launchers[teamID][unitID] + 1
				Spring.Echo("Launcherstep Complete")
				Spring.DestroyUnit(buildID,false,true)
			end
		end
		Sleep(500)
	end
end

function script.Killed(recentDamage, _)
	if GG.Launchers[teamID][unitID] then
	GG.Launchers[teamID][unitID] = nil
	end
    return 1
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
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if  boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end


end

