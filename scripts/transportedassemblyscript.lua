-- Define the wheel pieces
include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
-- Define the pieces of the weapon

local SIG_RESET = 2
center = piece "center"
buildspot = piece "buildspot"
Object = piece "Object1"
teamID = Spring.GetUnitTeam(unitID)
TablesOfPiecesGroups = {}

function getDistance(cmd, x, z)
    val = ((cmd.params[1] - x) ^ 2 + (cmd.params[3] - z) ^ 2) ^ 0.5

    return val
end

function transferCommands()
    while true do
        Sleep(150)
        if GG.Factorys and GG.Factorys[unitID] and GG.Factorys[unitID][1] then

            CommandTable = Spring.GetUnitCommands(unitID, -1)
            first = false

            for _, cmd in pairs(CommandTable) do

                if Spring.ValidUnitID(GG.Factorys[unitID][1]) == true then
                    if #CommandTable ~= 0 then
                        if first == false then
                            first = true
                            x, y, z = Spring.GetUnitPosition(unitID)
                            if cmd.id == CMD.MOVE and getDistance(cmd, x, z) >
                                160 then
                                Spring.GiveOrderToUnit(GG.Factorys[unitID][1],
                                                       cmd.id, cmd.params, {})
                            elseif cmd.id == CMD.STOP then
                                Spring.GiveOrderToUnit(GG.Factorys[unitID][1],
                                                       CMD.STOP, {}, {})
                            end
                        else
                            Spring.GiveOrderToUnit(GG.Factorys[unitID][1],
                                                   cmd.id, cmd.params, {"shift"})
                        end
                    else
                        Spring.GiveOrderToUnit(GG.Factorys[unitID][1], CMD.STOP,
                                               {}, {})
                    end
                end
            end
        end
    end
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    Spring.SetUnitNanoPieces(unitID, TablesOfPiecesGroups["Deco"])
    Turn(center, y_axis, math.rad(90), 0)

    hideT(TablesOfPiecesGroups["Deco"])
    StartThread(transferCommands)
    StartThread(whileMyThreadGentlyWeeps)
    StartThread(workLoop)

    if GG.Factorys == nil then GG.Factorys = {} end
    GG.Factorys[unitID] = {}
end

function foldScara(speed)
    unfoldScara(speed)
    WMoveScara(1, 90, 0, 0, 10, speed)

end

function WMoveScara(scaraNumber, jointPosA, jointPosB, jointPosC, jointPosD,
                    moveSpeed)
    Turn(TablesOfPiecesGroups["ASAxis"][scaraNumber], y_axis,
         math.rad(jointPosA), moveSpeed)
    Turn(TablesOfPiecesGroups["BSAxis"][scaraNumber], y_axis,
         math.rad(jointPosB), moveSpeed)
    Turn(TablesOfPiecesGroups["CSAxis"][scaraNumber], y_axis,
         math.rad(jointPosC), moveSpeed)
    WMove(TablesOfPiecesGroups["CSAxis"][scaraNumber], y_axis, jointPosD,
          moveSpeed * 10)
    WaitForTurns(TablesOfPiecesGroups["ASAxis"][scaraNumber],
                 TablesOfPiecesGroups["BSAxis"][scaraNumber],
                 TablesOfPiecesGroups["CSAxis"][scaraNumber])
end

function unfoldScara(speed) WMoveScara(1, 0, 0, 0, 0, speed) end

function scaraCycle(speed)
    unfoldScara(speed)
    WMoveScara(1, -165, 0, 0, 0, speed)
    Show(Object)
    WMoveScara(1, math.random(0, 20), 115 + math.random(-20, 20), 0, 0, speed)
    Hide(Object)
end

function roboCycle(speed)
    WMoveRobotToPos(1, CannonPreWorkPos, speed)
    WMoveRobotToPos(1, PickUpPos, speed)
    hideT(TablesOfPiecesGroups["Deco"])
    WMoveRobotToPos(1, CannonPreWorkPos, speed)
    setWorkPos(1, speed)
    WMoveRobotToPos(1, CannonPreWorkPos, speed)

end

-- RobotFoldPos 		={90,	45,	-45, 	-90, 0}
-- CannonPreWorkPos 	={0,	 0,	  0,	-60, 0}
-- PickUpPos 			={-90, -15,	 75, 	 30, 0}
RobotFoldPos = {-90, -45, 45, 0, 90}
CannonPreWorkPos = {0, 0, 0, 0, 60}
PickUpPos = {90, -15, 75, 0, 30}

function setWorkPos(robotID, speed)
    JointPos = {
        math.random(-45, 45), -math.random(-20, -5), -math.random(-20, -5), 0,
        math.random(20, 40)
    }
    WMoveRobotToPos(robotID, JointPos, speed / 3)
end

function WMoveRobotToPos(robotID, JointPos, MSpeed)

    Turn(TablesOfPiecesGroups["AAxis"][robotID], y_axis, math.rad(JointPos[1]),
         MSpeed)
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

function foldPosition(speed)

    hideT(TablesOfPiecesGroups["Deco"])
    StartThread(foldScara, speed)
    StartThread(WMoveRobotToPos, 1, RobotFoldPos, speed)

    WMove(buildspot, z_axis, 0, 850 / (5 / speed))
    moveT(TablesOfPiecesGroups["stuetze"], y_axis, 0, 900 / (15 / speed), false)

end

function unfoldPosition(speed)
    WMove(buildspot, z_axis, 850, 850 / (5 / speed))
    moveT(TablesOfPiecesGroups["stuetze"], y_axis, -900, 900 / (15 / speed),
          false)

end

function scaraLoop(scaraCycles, speed)
    for i = 1, scaraCycles, 1 do
        scaraCycle(speed * scaraCycles)
        Show(randT(TablesOfPiecesGroups["Deco"]))
    end
end

function workAnimation(speed)
    scaraLoop(5, speed)
    StartThread(roboCycle, speed)

end

function workLoop()
    foldPosition(1.0)
    Sleep(10)
    while true do
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then
            oldID = buildID
            unfoldPosition(1.0)
            while buildID and buildID == oldID do
                buildID = Spring.GetUnitIsBuilding(unitID)
                workAnimation(1.0)
                Sleep(10)
            end
            scaraCycle(5)
            foldPosition(1.0)
        end
        Sleep(100)
    end
end

function script.QueryBuildInfo() return buildspot end

function script.Activate()
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    return 1
end

function script.Deactivate()
    Signal(SIG_UPGRADE)
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    return 0
end

function delayedBuildEnd()
    SetSignalMask(SIG_RESET)
    Sleep(1500)
    if GG.Factorys[unitID] then GG.Factorys[unitID][2] = false end
end

function script.StartBuilding()

    -- animation
    Signal(SIG_RESET)
    if GG.Factorys[unitID] then GG.Factorys[unitID][2] = true end
end

boolDoIt = false
function whileMyThreadGentlyWeeps()
    while true do
        Sleep(150)
        if boolDoIt == true then
            boolDoIt = false
            StartThread(delayedBuildEnd)
        end

    end
end

function script.StopBuilding() boolDoIt = true end

function script.Killed(endh, _)
    GG.Factorys[unitID] = nil -- check for correct syntax
    return 1
end
