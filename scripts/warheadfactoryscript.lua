include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
myTeamID = Spring.GetUnitTeam(unitID)
center = piece "center"
emitor = piece "center"
Icon = piece "Icon"
Rotor = piece "Rotor"
IconScull = piece "IconScull"
IconProj = piece "IconProj"

GameConfig = getGameConfig()
function script.HitByWeapon(x, z, weaponDefID, damage) end

local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    spinT(TablesOfPiecesGroups["SignalLight"], y_axis,
          math.random(42, 420) * randSign(), 42)
    Spring.SetUnitNanoPieces(unitID, TablesOfPiecesGroups["SignalLight"])
	StartThread(howToBuildTheBombWatcher)
    Spin(Rotor,y_axis, math.rad(720),0)
end

local buildID = nil
function howToBuildTheBombWatcher()
    while true do
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then
            waitTillComplete(builID)
			if doesUnitExistAlive(builID) == true then
			GG.PayloadParents[buildID] = unitID
			end
        end
    Sleep(50)
    end
end

function script.Killed(recentDamage, _) 
    explodeTableOfPiecesGroupsExcludeTable(TablesOfPiecesGroups, {[Icon] = Icon})
    return 1 
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return Icon end

function script.Activate()
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    Show(IconScull)
    val = math.random(1,4)*randSign()
    Spin(IconScull,y_axis,math.rad(val),0.1)
    Move(IconProj, x_axis, -15,0)    
    Show(IconProj)
    Move(IconProj, x_axis, 0,0.1)
    return 1
end

function delayedDeactivation()
    Sleep(1000)
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
end

function script.Deactivate()
    StartThread(delayedDeactivation)
    return 0
end

function script.StartBuilding() 
    SetUnitValue(COB.INBUILDSTANCE, 1) 
end

function script.StopBuilding() 
    SetUnitValue(COB.INBUILDSTANCE, 0) 
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then
        hideAll(unitID)
        Show(Icon)

    else
        showAll(unitID)
        Hide(Icon)
        Hide(IconProj)
        Hide(IconScull)
    end
end
