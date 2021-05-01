include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

buildspot = piece "buildspot"
Containers = piece "Containers"
myTeamID = Spring.GetUnitTeam(unitID)
MaxPlattformHeigth = 750

GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)
SIG_BUILD = 1
Tool_FoilGlue = 1
Tool_FoilWeld = 2
Tool_FoilCamo = 3
Tool_FoilWeld = 4
Tool_ModuleGripper = 5
ToolTable = {} -- [robot][toolnumber]
DeskTable = {}

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Deco"])
    hideT(TablesOfPiecesGroups["Object"])

    for k = 1, 3 do
        ToolTable[k] = {}
        DeskTable[k] = {}

        for i = 1, 5 do
            ToolName = string.upper(string.char(96 + i)) .. "Tool"
            assert(ToolName)
            assert(TablesOfPiecesGroups[ToolName])
            assert(TablesOfPiecesGroups[ToolName])
            ToolTable[k][#ToolTable[k] + 1] = TablesOfPiecesGroups[ToolName][k]
            DeskTable[k][#DeskTable[k] + 1] =
                TablesOfPiecesGroups["D_" .. ToolName][k]
        end
    end

    StartThread(buildWatcher)
    T = process(getAllNearUnit(unitID, GameConfig.buildSafeHouseRange * 2),
                function(id)
        if houseTypeTable[Spring.GetUnitDefID(id)] then return id end
    end)

    GG.UnitHeldByHouseMap[unitID] = T[1]
    StartThread(mortallyDependant, unitID, T[1], 15, false, true)

end

function script.Killed(recentDamage, _) return 1 end

boolBuilding = false
local buildID = nil
function buildWatcher()

    while true do
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then
            StartThread(buildAnimation)
            producedUnits[#producedUnits + 1]=  buildID
            hp, mhp, pd, captProg, buildProgress = Spring.GetUnitHealth(buildID)
            laststep = 0
            boolBuilding = true
            while buildProgress and buildProgress + laststep < 0.95 do
                Sleep(10)
                hp, mhp, pd, captProg, tbuildProgress =    Spring.GetUnitHealth(buildID)
                laststep = buildProgress - tbuildProgress
                buildProgress = tbuildProgress
            end
        end

        boolBuilding = false
        Sleep(1)
    end
end

TrayInPlaceStation = {}
TrayInPickUpStation = {}

LongDistance = 2050
ShortDistance = 1150

LINE_1 = 1
LINE_2 = 2
LINE_3 = 3
LINE_4 = 4
TrayLong1 = piece("TrayLong1")
TrayLong2 = piece("TrayLong2")
TrayShort1 = piece("TrayShort1")
TrayShort2 = piece("TrayShort2")
TrayShort3 = piece("TrayShort3")
TrayShort4 = piece("TrayShort4")
TrayLong3 = piece("TrayLong3")
TrayLong4 = piece("TrayLong4")
trayDecoMap = {
    [TrayLong1] = {start = 1, ends = 5, counter = 0, line = LINE_1},
    [TrayLong2] = {start = 6, ends = 10, counter = 0, line = LINE_1},
    [TrayShort1] = {start = 11, ends = 15, counter = 0, line = LINE_2},
    [TrayShort2] = {start = 16, ends = 20, counter = 0, line = LINE_2},
    [TrayShort3] = {start = 21, ends = 25, counter = 0, line = LINE_3},
    [TrayShort4] = {start = 26, ends = 30, counter = 0, line = LINE_3},
    [TrayLong3] = {start = 31, ends = 35, counter = 0, line = LINE_4},
    [TrayLong4] = {start = 36, ends = 40, counter = 0, line = LINE_4}
}

trayPartInPlaceLine = {}

function hideTrayObjects(partName)
    hideT(TablesOfPiecesGroups["Deco"], trayDecoMap[partName].start,
          trayDecoMap[partName].ends)
    trayDecoMap[partName].counter = 0
end

function incShowTrayObjects(partName)
    if not partName then return end
    if TablesOfPiecesGroups["Deco"][trayDecoMap[partName].start +
        trayDecoMap[partName].counter] then
        Show(TablesOfPiecesGroups["Deco"][trayDecoMap[partName].start +
                 trayDecoMap[partName].counter])
    end
    trayDecoMap[partName].counter = math.min(trayDecoMap[partName].counter + 1,
                                             trayDecoMap[partName].ends)
end

function trayAnimation(partName, totalTravelDistance, delayInMs,
                       travelDistanceStation, boolTravelDirection,
                       inStationSignalID, sspeed)
    reset(partName)
    Hide(partName)
    Sleep(delayInMs)
    Show(partName)
    maxis = x_axis
    raxis = y_axis

    waitTimeStation = 2000

    if not TrayInPlaceStation[inStationSignalID] then
        TrayInPlaceStation[inStationSignalID] = false
    end
    if not TrayInPickUpStation[inStationSignalID] then
        TrayInPickUpStation[inStationSignalID] = false
    end

    while true do
        if boolTravelDirection == true then
            WTurn(partName, raxis, math.rad(0), math.pi)
            while TrayInPlaceStation[inStationSignalID] == true do
                Sleep(100)
            end
            WMove(partName, maxis, travelDistanceStation, sspeed)
            TrayInPlaceStation[inStationSignalID] = true
            trayPartInPlaceLine[inStationSignalID] = partName
            Sleep(waitTimeStation * 2)
            trayPartInPlaceLine[inStationSignalID] = nil
            TrayInPlaceStation[inStationSignalID] = false
            WMove(partName, maxis, totalTravelDistance, sspeed)
            while TrayInPickUpStation[inStationSignalID] == true do
                Sleep(100)
            end
            WTurn(partName, raxis, math.rad(90), math.pi)
            TrayInPickUpStation[inStationSignalID] = true
            Sleep(waitTimeStation)
            hideTrayObjects(partName)
            TrayInPickUpStation[inStationSignalID] = false
            WTurn(partName, raxis, math.rad(179), math.pi)
            WMove(partName, maxis, 0, sspeed)
            WTurn(partName, raxis, math.rad(181), math.pi)
            WTurn(partName, raxis, math.rad(0), math.pi)

        else
            WTurn(partName, raxis, math.rad(-179), math.pi)
            while TrayInPlaceStation[inStationSignalID] == true do
                Sleep(100)
            end
            WMove(partName, maxis, travelDistanceStation, sspeed)
            TrayInPlaceStation[inStationSignalID] = true
            trayPartInPlaceLine[inStationSignalID] = partName
            Sleep(waitTimeStation * 2)
            trayPartInPlaceLine[inStationSignalID] = nil
            TrayInPlaceStation[inStationSignalID] = false
            WMove(partName, maxis, totalTravelDistance, sspeed)
            while TrayInPickUpStation[inStationSignalID] == true do
                Sleep(100)
            end
            WTurn(partName, raxis, math.rad(-270), math.pi)
            TrayInPickUpStation[inStationSignalID] = true
            Sleep(waitTimeStation)
            hideTrayObjects(partName)
            TrayInPickUpStation[inStationSignalID] = false
            WTurn(partName, raxis, math.rad(-360), math.pi)
            WMove(partName, maxis, 0, sspeed)
            WTurn(partName, raxis, math.rad(0), math.pi)
        end

    end

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

function scaraAnimationLoop(scaraNumber, objectToPick, targetIDTable,
                            jointPosTable, moveSpeed)
    Hide(objectToPick)
    boolObjectPicked = false
    WMoveScara(scaraNumber, jointPosTable.HomePos.a, jointPosTable.HomePos.b, 0,
               jointPosTable.HomePos.d, moveSpeed)

    while true do
        -- Move to CenterPos
        -- check if one of the trays is in station
        local targetID

        for i = 1, #targetIDTable, 1 do
            if TrayInPlaceStation[targetIDTable[i]] and
                TrayInPlaceStation[targetIDTable[i]] == true then
                targetID = targetIDTable[i]
                break
            end
        end

        if targetID and boolObjectPicked == false then
            -- Move to PickUpPos
            WMoveScara(scaraNumber, jointPosTable.PickUp.a,
                       jointPosTable.PickUp.b, 0, 0, moveSpeed)
            WMoveScara(scaraNumber, jointPosTable.PickUp.a,
                       jointPosTable.PickUp.b, 0, jointPosTable.PickUp.d,
                       moveSpeed)
            -- Pick up ObjectToPick
            Show(objectToPick)
            boolObjectPicked = true
            WMoveScara(scaraNumber, jointPosTable.PickUp.a,
                       jointPosTable.PickUp.b, 0, 0, moveSpeed)
            WMoveScara(scaraNumber, jointPosTable.HomePos.a,
                       jointPosTable.HomePos.b, 0, jointPosTable.HomePos.d,
                       moveSpeed)
        end

        if boolObjectPicked == true and targetID then
            Pos = jointPosTable.PlaceTable[targetID]
            WMoveScara(scaraNumber, Pos.a, Pos.b, 0, 0, moveSpeed)
            WMoveScara(scaraNumber, Pos.a, Pos.b, 0, Pos.d, moveSpeed)
            if trayPartInPlaceLine[targetID] then
                incShowTrayObjects(trayPartInPlaceLine[targetID])
            end
            boolObjectPicked = false
            Hide(objectToPick)
            WMoveScara(scaraNumber, Pos.a, Pos.b, 0, 0, moveSpeed)
            WMoveScara(scaraNumber, jointPosTable.HomePos.a,
                       jointPosTable.HomePos.b, 0, jointPosTable.HomePos.d,
                       moveSpeed)
        end
        Sleep(100)
    end
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
    -- echo("Robot: Move Completed")

end

function changeToolTo(robotID, ToolType, posTable, speed, currentTool)
    -- Drive to tooltables
    offset = ((robotID - 1) * 3)
    hideT(TablesOfPiecesGroups["Modul"], offset, offset + 3)
    WMoveRobotToPos(robotID, posTable.toolPos, speed)
    hideT(ToolTable[robotID], 1, 5)
    if DeskTable[robotID][currentTool] then
        Show(DeskTable[robotID][currentTool])
    end
    Show(ToolTable[robotID][ToolType])
    Hide(DeskTable[robotID][ToolType])
    Sleep(500)
    -- return to homepos
end

function robotArmAnimation(robotID, posTable, speed, targetIDTable,
                           objectPickedSet)
    Sleep(100)
    -- assert(ToolTable[robotID])

    -- move into HomePos
    -- echo("Robot:Driving Home")
    offset = ((robotID - 1) * 3)
    showT(TablesOfPiecesGroups["Modul"], offset + 1, offset + 3)
    WMoveRobotToPos(robotID, posTable.homepos, speed)
    boolObjectPicked = false
    changeToolTo(robotID, Tool_ModuleGripper, posTable, speed, Tool_FoilWeld)
    currentTool = Tool_ModuleGripper
    WMoveRobotToPos(robotID, posTable.homepos, speed)

    while true do

        -- Check if there is stuff to be picked up
        local targetID
        if maRa() == true then
            for i = 1, #targetIDTable, 1 do
                if TrayInPickUpStation[targetIDTable[i]] and
                    TrayInPickUpStation[targetIDTable[i]] == true then
                    targetID = targetIDTable[i]
                    break
                end
            end
        else
            for i = #targetIDTable, 1, -1 do
                if TrayInPickUpStation[targetIDTable[i]] and
                    TrayInPickUpStation[targetIDTable[i]] == true then
                    targetID = targetIDTable[i]
                    break
                end
            end
        end

        -- switch Tool
        if not targetID and boolObjectPicked == false and currentTool ==
            Tool_ModuleGripper and robotID ~= 2 then
            currentTool = math.random(1, 4)
            changeToolTo(robotID, currentTool, posTable, speed,
                         Tool_ModuleGripper)
        end

        if not targetID and currentTool ~= Tool_ModuleGripper then
            WMoveRobotToPos(robotID, posTable.deskHub, speed)
            WMoveRobotToPos(robotID, calcTablePos(posTable.TableRange), speed)
            WMoveRobotToPos(robotID, posTable.deskHub, speed)
        end

        if targetID and boolObjectPicked == false then
            if currentTool ~= Tool_ModuleGripper then
                changeToolTo(robotID, Tool_ModuleGripper, posTable, speed,
                             currentTool)
                currentTool = Tool_ModuleGripper
            end

            -- Move to PickUpPos
            WMoveRobotToPos(robotID, posTable.hubposT[targetID], speed)
            -- echo("Robot:Driving to Hub Position")
            WMoveRobotToPos(robotID, posTable.pickUpPosT[targetID], speed)

            if #objectPickedSet > 0 then showT(objectPickedSet) end
            -- while (TrayInPickUpStation[inStationSignalID] and TrayInPickUpStation[inStationSignalID] == true) do Sleep(100) end
            boolObjectPicked = true
            showT(TablesOfPiecesGroups["Modul"], offset + 1, offset + 3)
            -- echo("Robot:Driving to desk Hub Position")

            WMoveRobotToPos(robotID, posTable.deskHub, speed)
        end

        if targetID and boolObjectPicked == true then
            WMoveRobotToPos(robotID, posTable.deskHub, speed)
            -- place it on the table

            WMoveRobotToPos(robotID, calcTablePos(posTable.TableRange), speed)
            if #objectPickedSet > 0 then hideT(objectPickedSet) end
            boolObjectPicked = false
            offset = ((robotID - 1) * 3)
            hideT(TablesOfPiecesGroups["Modul"], offset + 1, offset + 3)
            WMoveRobotToPos(robotID, posTable.deskHub, speed)
            WMoveRobotToPos(robotID, posTable.homepos, speed)
        end

        Sleep(100)
    end
end

function calcTablePos(TableRange)
    return {
        [1] = math.random(TableRange.min[1], TableRange.max[1]),
        [2] = math.random(TableRange.min[2], TableRange.max[2]),
        [3] = math.random(TableRange.min[3], TableRange.max[3]),
        [4] = math.random(TableRange.min[4], TableRange.max[4]),
        [5] = math.random(TableRange.min[5], TableRange.max[5]),
        [6] = math.random(TableRange.min[6], TableRange.max[6])
    }
end

robotArmHomePos = {
    [1] = {90, -50, 50, 0, 90, 0},
    [2] = {0, -50, 50, 0, 90, 0},
    [3] = {-90, -50, 50, 0, 90, 0}
}

function driveHome()
    for i = 1, 3 do
        StartThread(WMoveScara, i, 0, 0, 0, 0, math.pi)
        StartThread(WMoveRobotToPos, i, robotArmHomePos[i], math.pi)
    end
end


function buildAnimation()
    Signal(SIG_BUILD)
    SetSignalMask(SIG_BUILD)

    StartThread(driveHome)
    Sleep(500)

    animationSpeed = math.pi * 3

    randoVal = (math.random() % 4)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayLong"][1],
                LongDistance, randoVal * 7000, LongDistance * 0.2, false,
                LINE_1, 2000)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayLong"][2],
                LongDistance, (randoVal + 1) * 7000, LongDistance * 0.2, false,
                LINE_1, 2000)

    randoVal = (math.random() % 4)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayShort"][1],
                ShortDistance, randoVal * 7000, ShortDistance * 0.2, false,
                LINE_2, 1000)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayShort"][2],
                ShortDistance, (randoVal + 1) * 7000, ShortDistance * 0.2,
                false, LINE_2, 1000)

    randoVal = (math.random() % 4)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayShort"][3],
                ShortDistance, randoVal * 7000, ShortDistance * 0.2, true,
                LINE_3, 1000)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayShort"][4],
                ShortDistance, (randoVal + 1) * 7000, ShortDistance * 0.2, true,
                LINE_3, 1000)
    randoVal = (math.random() % 4)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayLong"][3],
                LongDistance, randoVal * 7000, LongDistance * 0.2, true, LINE_4,
                2000)
    StartThread(trayAnimation, TablesOfPiecesGroups["TrayLong"][4],
                LongDistance, (randoVal + 1) * 7000, LongDistance * 0.2, true,
                LINE_4, 2000)

    local targetIDTable1 = {LINE_1, LINE_2}

    local jointPosTable1 = {
        HomePos = {a = -35, b = 35, c = 0, d = 0},
        PickUp = {a = 10, b = 10, c = 0, d = 0},
        PlaceTable = {
            [LINE_1] = {a = 35, b = 110, c = 0, d = 0},
            [LINE_2] = {a = -45, b = -45, c = 0, d = 0}

        }
    }
    StartThread(scaraAnimationLoop, 1, TablesOfPiecesGroups["Object"][1],
                targetIDTable1, jointPosTable1, animationSpeed)

    local targetIDTable2 = {LINE_2, LINE_3}
    local jointPosTable2 = {
        HomePos = {a = 0, b = 0, c = 0, d = 0},
        PickUp = {a = -25, b = -90, c = 0, d = -7},
        PlaceTable = {
            [LINE_3] = {a = 15, b = 90, c = 0, d = -7},
            [LINE_2] = {a = -15, b = -90, c = 0, d = -7}
        }
    }
    StartThread(scaraAnimationLoop, 2, TablesOfPiecesGroups["Object"][2],
                targetIDTable2, jointPosTable2, animationSpeed)

    local targetIDTable3 = {LINE_4, LINE_3}
    local jointPosTable3 = {
        HomePos = {a = 25, b = -50, c = 0, d = 0},
        PickUp = {a = -55, b = 0, c = 0, d = -7},
        PlaceTable = {
            [LINE_3] = {a = 60, b = 30, c = 0, d = -7},
            [LINE_4] = {a = -55, b = -90, c = 0, d = -7}

        }
    }
    StartThread(scaraAnimationLoop, 3, TablesOfPiecesGroups["Object"][3],
                targetIDTable3, jointPosTable3, animationSpeed)

    -- Robot1
    posTable = {
        homepos = robotArmHomePos[1],
        TableRange = {
            ["min"] = {70, 20, 10, 0, 45, 0},
            ["max"] = {115, 40, 20, 3, 55, 3}
        },
        toolPos = {195, -15, 25, 0, 50, 0},
        hubposT = {[LINE_4] = {210, -35, 75, 0, 50, 0}},
        pickUpPosT = {[LINE_4] = {210, -30, 60, 0, 50, 0}},
        deskHub = {90, 25, 15, 0, 45, 0}
    }
    targetIDTable = {LINE_4}

    StartThread(robotArmAnimation, 1, posTable, math.pi, targetIDTable, {})

    -- Robot3
    posTable = {
        homepos = robotArmHomePos[3],
        TableRange = {
            ["min"] = {-35, 20, 10, 0, 45, 0},
            ["max"] = {35, 40, 20, 3, 55, 3}
        },
        toolPos = {105, -35, 65, 0, 60, 0},
        hubposT = {
            [LINE_2] = {65, -35, 75, 0, 50, 0},
            [LINE_3] = {-70, -35, 75, 0, 50, 0}
        },

        pickUpPosT = {
            [LINE_2] = {65, -30, 60, 0, 50, 0},
            [LINE_3] = {-70, -30, 60, 0, 50, 0}
        },
        deskHub = {0, -25, 15, 0, 45, 0}
    }
    targetIDTable = {LINE_2, LINE_3}
    StartThread(robotArmAnimation, 3, posTable, math.pi, targetIDTable, {})

    -- Robot2
    posTable = {
        homepos = robotArmHomePos[2],
        TableRange = {
            ["min"] = {-135, 20, 10, 0, 45, 0},
            ["max"] = {-65, 40, 20, 3, 55, 3}
        },
        toolPos = {-190, -15, 25, 0, 50, 0},

        hubposT = {[LINE_1] = {-180, -35, 60, 0, 65, 0}},
        pickUpPosT = {[LINE_1] = {-200, -15, 70, 0, 50, 0}},
        deskHub = {-90, -25, 15, 0, 45, 0}
    }
    targetIDTable = {LINE_1}

    StartThread(robotArmAnimation, 2, posTable, math.pi, targetIDTable, {})

    while boolBuilding == true do

        if buildID then
            hp, mHp, pD, cP, buildProgress = Spring.GetUnitHealth(buildID)
            buildProgress = buildProgress or 0
            if buildProgress then
                Plattformheight = MaxPlattformHeigth * (1 - buildProgress)
                Move(buildspot, z_axis, Plattformheight, math.pi * 15)
            end
        end
        Sleep(10)
    end

    driveHome()
end

producedUnits={}
function TurnProducedUnitsOverToTeam(teamID)
process(producedUnits,
        function(id)
            if doesUnitExistAlive(id) == true then
                transferUnitTeam(id,teamID)
            end
        end)
end

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

function script.QueryBuildInfo() return buildspot end

Spring.SetUnitNanoPieces(unitID, {structure})

function script.StartBuilding() SetUnitValue(COB.INBUILDSTANCE, 1) end

function script.StopBuilding() SetUnitValue(COB.INBUILDSTANCE, 0) end

