include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
gameConfig = getGameConfig()

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(launchMotion)
    StartThread(launchCloud)
end

function launchMotion()
    maxTotalInterceptPossibleTime = gameConfig.LauncherInterceptTimeSeconds * 30
    totalInterceptPossibleTime = maxTotalInterceptPossibleTime
    StageInterval = maxTotalInterceptPossibleTime/ #TablesOfPiecesGroups["Stage"]
    StageTable = {}
    for i=1, #TablesOfPiecesGroups["Stage"] do
        StageTable[ i*StageInterval] = TablesOfPiecesGroups["Stage"][i]
    end

    maxHeigth = 2048
    x, y, z = Spring.GetUnitPosition(unitID)
    Spring.MoveCtrl.Enable(unitID, true)
    offset = 0

    while totalInterceptPossibleTime > 0 do
        offset = math.sin((math.pi / 2) *
                              (1 -
                                  (totalInterceptPossibleTime /
                                      maxTotalInterceptPossibleTime))) *
                     maxHeigth
        Spring.MoveCtrl.SetPosition(unitID, x, y + offset, z)

        totalInterceptPossibleTime = totalInterceptPossibleTime - 1
        Sleep(1)
        timeSinceLaunch = maxTotalInterceptPossibleTime - totalInterceptPossibleTime
        for time, stage in pairs(StageTable) do
            if stage then
                if time < timeSinceLaunch then
                    Hide(stage)
                    Explode(stage, SFX.SHATTER )
                    StageTable[time] = nil
                end
            end
        end
    end
    hideT(TablesOfPiecesGroups["Stage"])

    while true do
        Spring.MoveCtrl.SetPosition(unitID, x, y + maxHeigth, z)
        Sleep(1)
    end
end

function launchCloud()
    while true do
        EmitSfx(TablesOfPiecesGroups["RearEmit"][math.random(1,#TablesOfPiecesGroups["RearEmit"])], 1024)
        Sleep(50)
    end
end

function script.Killed(recentDamage, _) return 1 end

