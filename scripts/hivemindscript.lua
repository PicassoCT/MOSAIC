include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
GameConfig = getGameConfig()

IntegrationRadius = GameConfig.integrationRadius
MAX_MEMBERS = GameConfig.maxTimeForSlowMotionRealTimeSeconds 
bodyMax = 128
innerLimit = 96
center = piece "center"
Icon = piece "Icon"
y_rotationAxis = y_axis

teamID = Spring.GetUnitTeam(unitID)


function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)

    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["body"])
    StartThread(integrateNewMembers)

    intI = 0
    if TablesOfPiecesGroups["cable"] then
        foreach(TablesOfPiecesGroups["cable"], function(id)
            randoVal = math.random(-10, 10) / 5
            val = intI * ((360 / 8) + math.pi * randoVal)
            Turn(id, y_rotationAxis, math.rad(val), 0)
            intI = intI + 1
        end)
    end
    StartThread(showState)
end

function script.Killed(recentDamage, _) return 1 end

membersIntegrated= 0

function integrateNewMembers()
    waitTillComplete(unitID)
    x, y, z = Spring.GetUnitPosition(unitID)
    local integrateAbleUnits = getMobileCivilianDefIDTypeTable(UnitDefs)
    px, py, pz = Spring.GetUnitPosition(unitID)
    members = {}
    while true do
        if  membersIntegrated < MAX_MEMBERS then
        foreach(getAllInCircle(x, z, IntegrationRadius), function(id)
            if GG.DisguiseCivilianFor[id] then
                return GG.DisguiseCivilianFor[id]
            end
            return id
        end, function(id)
            if integrateAbleUnits[Spring.GetUnitDefID(id)] then
           
                Spring.SetUnitPosition(id, px, py, pz)
                Spring.DestroyUnit(id, false, true)
                endmembersIntegrated = endmembersIntegrated  + 1

            end
        end)
        end
        Sleep(100)
    end
end

heigthPagode = 369
maxTurn = 6 * 90
function showState()
    bodyCount = count(TablesOfPiecesGroups["body"])
    for i = 1, innerLimit, 1 do
        degIndex = (i % 64) * (360 / 64)
        randOffset = (math.random(-4, 4) / 2) * math.pi
        Turn(TablesOfPiecesGroups["body"][i], y_rotationAxis,
             math.rad(10 * degIndex + randOffset), 0)
    end

    for i = innerLimit, #TablesOfPiecesGroups["body"], 1 do
        degIndex = ((i % 96) % 16) * (360 / 16)
        randOffset = (math.random(-4, 4) / 8) * math.pi
        Turn(TablesOfPiecesGroups["body"][i], y_rotationAxis,
             math.rad(10 * degIndex + randOffset), 0)
    end
    
    description = "Provides information warfare once assembled ("
    oldLevel = level
    while true do

        level = membersIntegrated / MAX_MEMBERS

        hideT(TablesOfPiecesGroups["body"])
        if level ~= oldLevel then
            Spring.SetUnitTooltip(unitID, description .. level.. " / "..MAX_MEMBERS..")")
            oldLevel = level
        end
        if level > 1 then showT(TablesOfPiecesGroups["body"], 1, level) end
        Sleep(100)
    end
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        if TablesOfPiecesGroups then hideT(TablesOfPiecesGroups["body"]) end
        Hide(Icon)
    end

end

