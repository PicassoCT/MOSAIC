include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
myTeamID = Spring.GetUnitTeam(unitID)
center = piece "center"
emitor = piece "center"
Icon = piece "Icon"

GameConfig = getGameConfig()
function script.HitByWeapon(x, z, weaponDefID, damage) end

if not center then
    echo("Unit of type" .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no center")
end
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    spinT(TablesOfPiecesGroups["SignalLight"], y_axis,
          math.random(42, 420) * randSign(), 42)
    Spring.SetUnitNanoPieces(unitID, TablesOfPiecesGroups["SignalLight"])
    T = foreach(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange * 2),
                function(id)
        if houseTypeTable[Spring.GetUnitDefID(id)] then return id end
    end)

    GG.UnitHeldByHouseMap[unitID] = T[1]
    StartThread(mortallyDependant, unitID, T[1], 15, false, true)
    hideAll(unitID)
    Show(Icon)
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

function script.StartBuilding() SetUnitValue(COB.INBUILDSTANCE, 1) end

function script.StopBuilding() SetUnitValue(COB.INBUILDSTANCE, 0) end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then
        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end
end
