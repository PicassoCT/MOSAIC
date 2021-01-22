include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
GameConfig = getGameConfig()
boolLaunchReady = false

RocketAttach = piece "RocketAttach"
Crane = piece "Crane"
Craddle = piece "Craddle"
Elevator = piece "Elevator"
center = piece "Elevator"
Icon = piece "Icon"
upaxis = y_axis
teamID = Spring.GetUnitTeam(unitID)
stepIndex = 0
rocketHeigth = 3400
stepHeight = rocketHeigth / GameConfig.LaunchReadySteps

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    if not GG.Launchers then GG.Launchers = {} end
    if not GG.Launchers[teamID] then GG.Launchers[teamID] = {} end
    GG.Launchers[teamID][unitID] = 0
    Move(RocketAttach, upaxis, -rocketHeigth, 0)
    Move(Elevator, upaxis, -rocketHeigth, 0)
    Hide(RocketAttach)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    hideT(TablesOfPiecesGroups["Step"])
    hideT(TablesOfPiecesGroups["WIP"])
    hideT(TablesOfPiecesGroups["Gantry"])
    StartThread(accountForBuiltLauncherSteps)
    StartThread(workCycle)
    Spin(Craddle, y_axis, math.rad(1), 0.1)
    Spin(RocketAttach, y_axis, math.rad(1), 0.1)
end

launcherStepDefID = UnitDefNames["launcherstep"].id
function accountForBuiltLauncherSteps()
    while boolLaunchReady == false do
        -- Spring.Echo("Detect Upgrade")
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then
            if boolLaunchReady == false then
                buildDefID = Spring.GetUnitDefID(buildID)
                if buildDefID == launcherStepDefID then
                    waitTillComplete(buildID)
                    stepIndex = stepIndex + 1
                    Move(RocketAttach, upaxis,
                         math.min(-rocketHeigth + stepIndex * stepHeight, 0), 10)
                    Move(Elevator, upaxis,
                         math.min(-rocketHeigth + stepIndex * stepHeight, 0), 10)
                    showT(TablesOfPiecesGroups["Step"], 0, stepIndex)
                    Hide(TablesOfPiecesGroups["WIP"][stepIndex])
                    Show(TablesOfPiecesGroups["WIP"][math.min(
                             #TablesOfPiecesGroups["WIP"], stepIndex + 1)])
                    showT(TablesOfPiecesGroups["Gantry"], 0, math.min(
                              #TablesOfPiecesGroups["Gantry"], stepIndex * 2))

                    GG.Launchers[teamID][unitID] =
                        GG.Launchers[teamID][unitID] + 1
                    Spring.Echo("Launcherstep Complete")
                    Spring.DestroyUnit(buildID, false, true)
                end
            elseif boolLaunchReady == true then
                Spring.DestroyUnit(buildID, false, true)
            end
        end

        if stepIndex >= GameConfig.LaunchReadySteps and boolLaunchReady == false then
            prePareForLaunch()
            boolLaunchReady = true
        end
        Sleep(500)
    end
end
boolWorkCycle = true
function prePareForLaunch()
    boolWorkCycle = false
    hideT(TablesOfPiecesGroups["WIP"])
    showT(TablesOfPiecesGroups["Step"])

    StopSpin(Craddle, y_axis, 0.1)
    StopSpin(RocketAttach, y_axis, 0.1)
    Move(RocketAttach, upaxis, 0, 25)
    Move(Elevator, upaxis, 0, 25)
    Sleep(2500)
    WTurn(Crane, y_axis, math.rad(95), 5)

end

function WMoveRobotToPos(robotID, JointPos, MSpeed)
    Turn(TablesOfPiecesGroups["AAxis"][robotID], y_axis, math.rad(JointPos[1]),
         MSpeed)
    Turn(TablesOfPiecesGroups["BAxis"][robotID], z_axis, math.rad(JointPos[2]),
         MSpeed)
    Turn(TablesOfPiecesGroups["CAxis"][robotID], z_axis, math.rad(JointPos[3]),
         MSpeed)
    Turn(TablesOfPiecesGroups["DAxis"][robotID], x_axis, math.rad(JointPos[4]),
         MSpeed)
    Turn(TablesOfPiecesGroups["EAxis"][robotID], z_axis, math.rad(JointPos[5]),
         MSpeed)

    WaitForTurns(TablesOfPiecesGroups["AAxis"][robotID],
                 TablesOfPiecesGroups["BAxis"][robotID],
                 TablesOfPiecesGroups["CAxis"][robotID],
                 TablesOfPiecesGroups["DAxis"][robotID],
                 TablesOfPiecesGroups["EAxis"][robotID])
end

function moveToWorkBasePos(i)
    WMoveRobotToPos(i, WorkPos[i], math.rad(4, 12))
    WMoveRobotToPos(i, BasePos[i], math.rad(4, 12))
end

WorkPos = {
    [1] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
    [2] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
    [3] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
    [4] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
}

BasePos = {
    [1] = {[1] = 0, [2] = -45, [3] = 45, [4] = 0, [5] = 0},
    [2] = {[1] = 0, [2] = -45, [3] = 45, [4] = 0, [5] = 0},
    [3] = {[1] = 0, [2] = 45, [3] = -45, [4] = 0, [5] = 0},
    [4] = {[1] = 0, [2] = 45, [3] = -45, [4] = 0, [5] = 0}
}

function workCycle()
    while boolWorkCycle == true do

        if boolBuilding == true then
            for i = 1, 4 do StartThread(moveToWorkBasePos, i) end
        end

        startFrame = Spring.GetGameFrame()
        endFrame = Spring.GetGameFrame() + 1

        while startFrame ~= endFrame do
            startFrame = Spring.GetGameFrame()
            for i = 1, 4 do
                robotID = i
                WaitForTurns(TablesOfPiecesGroups["AAxis"][robotID],
                             TablesOfPiecesGroups["BAxis"][robotID],
                             TablesOfPiecesGroups["CAxis"][robotID],
                             TablesOfPiecesGroups["DAxis"][robotID],
                             TablesOfPiecesGroups["EAxis"][robotID])
            end
            endFrame = Spring.GetGameFrame()
            Sleep(5)
        end
        Sleep(100)
    end
end

function script.Killed(recentDamage, _)
    if GG.Launchers[teamID][unitID] then GG.Launchers[teamID][unitID] = nil end
    return 1
end
boolBuilding = false
function script.Activate()
    boolBuilding = true
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end

function script.Deactivate()
    boolBuilding = false
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    return 0
end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})
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

