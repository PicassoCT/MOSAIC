include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
center = piece "Center"
Rotator = piece "Rotator"
GameConfig = getGameConfig()

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.MoveCtrl.Enable(unitID)
    ox, oy, oz = Spring.GetUnitPosition(unitID)
    Spring.SetUnitPosition(unitID, ox, oy + 125, oz)
    showAll(unitID)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    StartThread(interrogatePercentage)
end

function showTime()
    StartThread(pulseLoad)
    showAll()
    hideT(TablesOfPiecesGroups["Load"])
    Spin(Rotator, y_axis, math.rad(42), 15)
    while true do
        showT(TablesOfPiecesGroups["Load"], 1,
              math.max(1, #TablesOfPiecesGroups["Load"] * getCurrentPercent()))
        Sleep(OnePercent)
        for i = 1, #TablesOfPiecesGroups["Ring"] do
            val = math.random(2, 15) * randSign()
            speed = math.random(5, 25)
            Spin(TablesOfPiecesGroups["Ring"][i], y_axis, math.rad(val), speed)
        end
        Sleep(1)
    end
end

function getCurrentPercent()
    return ((startCountDown - countDown) / startCountDown)
end

countDown = (GameConfig.InterrogationTimeInFrames / 30) * 1000
startCountDown = countDown
OnePercent = math.ceil(countDown / 100)

function pulseLoad()
    counter = 0
    while true do
        frame = ((Spring.GetGameFrame() % 300) / 300) * math.pi
        counter = counter + 1
        for i = 1, #TablesOfPiecesGroups["Load"] do
            value = math.sin(frame + (i + counter) * (math.pi) /
                                 #TablesOfPiecesGroups["Load"]) * 50
            if TablesOfPiecesGroups["Load"][i] then
                Move(TablesOfPiecesGroups["Load"][i], y_axis, value, 0)
            end
        end
        Sleep(30)
    end
end

function interrogatePercentage()
    for i = 1, #TablesOfPiecesGroups["Ring"] do
        value = 32 ^ i
        WMove(TablesOfPiecesGroups["Ring"][i], z_axis, value, 0)
    end

    for i = 1, #TablesOfPiecesGroups["Ring"] do
        syncMoveInTime(TablesOfPiecesGroups["Ring"][i], 0, 0, 0, 750)
    end

    timer = 0
    StartThread(showTime)
    while not GG.raidStatus or not GG.raidStatus[unitID] do --test
        Sleep(100)
        timer = timer + 100
        if timer > 15000 then 
            echo("Timeout interrogationIcon")
            Spring.DestroyUnit(unitID, false, true) end
    end

    SetUnitValue(COB.WANT_CLOAK, 0)

    while countDown > 0 do -- GG.raidPercentageToIcon and GG.raidPercentageToIcon[unitID] do
        Sleep(OnePercent)
        countDown = math.max(0, countDown - OnePercent)
        Sleep(1)
    end
    for i = 1, #TablesOfPiecesGroups["Ring"] do
        value = 32 ^ i
        syncMoveInTime(TablesOfPiecesGroups["Ring"][i], 0, value, 0, 750)
    end
    WaitForMoves(TablesOfPiecesGroups["Ring"])

    if GG.raidStatus and GG.raidStatus[unitID] then
         GG.raidStatus[unitID].boolInterogationComplete = true
    end
    echo("RaidIcon LifeTime ended")
    Spring.DestroyUnit(unitID, false, true)
end

function visualizeProgress()
    hideT(TablesOfPiecesGroups["Puzzle"])
    showT(TablesOfPiecesGroups["Puzzle"], 1,
          #TablesOfPiecesGroups["Puzzle"] * getCurrentPercent())
end

function script.Killed(recentDamage, _) 
    echo("Interrogation Icon died")
    return 1 
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

