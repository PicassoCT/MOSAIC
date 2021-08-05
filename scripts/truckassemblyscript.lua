include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

center = piece "center"
attachPoint = piece "attachPoint"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
    createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- Signals for moving
SIG_RESET = 1
SIG_FOLD = 2
SIG_MOVE = 4
SIG_RESET = 8
SIG_UNFOLD = 16
SIG_BREATH = 32
SIG_UPGRADE = 64
SIG_STOP = 128

local boolAllreadyDead = false
local boolAllreadyStarted = false
local boolMurdered = true
local mexID = -666

function UpdateUnitPosition(ParentID, UnitID, attach)
    local px, py, pz, _, _, _ = Spring.GetUnitPiecePosDir(ParentID, attach)
    local rx, ry, rz = Spring.GetUnitPieceRotation(ParentID, attach)
    Spring.MoveCtrl.SetPhysics(UnitID, px, py, pz + 4, 0, 0, 0, rx, ry, rz)
end

function GetUnitPieceRotation(unitID, piece)
    local rx, ry, rz = Spring.UnitScript.CallAsUnit(unitID, spGetPieceRotation,
                                                    piece)
    local Heading = Spring.GetUnitHeading(unitID) -- COB format
    local dy = rad(Heading / 182)
    return rx, dy + ry, rz
end

factoryID = nil
----aimining & fire weapon
function newFactory()
    if GG.Factorys == nil then GG.Factorys = {} end

    local x, y, z = Spring.GetUnitPosition(unitID)
    teamID = Spring.GetUnitTeam(unitID)

    factoryID = Spring.CreateUnit("transportedassembly", x, y + 40, z + 20, 0,
                                  teamID)
    GG.Factorys[factoryID] = {}
    GG.Factorys[factoryID][1] = unitID
    GG.Factorys[factoryID][2] = false
    Spring.SetUnitNoSelect(unitID, true)
    Spring.MoveCtrl.Enable(factoryID, true)
    Spring.SetUnitNeutral(factoryID, true)
    Spring.SetUnitBlocking(factoryID, false, false)
end

boolBuilding = false
function updateBoolisBuilding()
    while GG.Factorys == nil or GG.Factorys[factoryID] == nil do Sleep(150) end

    while true do
        Sleep(500)
        if GG.Factorys[factoryID][2] == true then
            boolBuilding = true
        else
            boolBuilding = false
        end
    end
end

function workInProgress()
    while factoryID == nil do Sleep(250) end

    buildID = nil
    buildIDofOld = nil
    counter = 0

    while (true) do
        Sleep(120)
        if factoryID and Spring.ValidUnitID(factoryID) == true then

            buildID = Spring.GetUnitIsBuilding(factoryID)
            if buildID and buildID ~= buildIDofOld and type(buildID) == "number" then

                boolBuilding = true

                buildProgress = 0

                while buildProgress and buildProgress < 1 do
                    health, maxHealth, paralyzeDamage, captureProgress, buildProgress =
                        Spring.GetUnitHealth(buildID)
                    Sleep(150)
                    if not doesUnitExistAlive(buildID) then
                        break
                    end
                end

                if buildID ~= nil then
                    buildIDofOld = buildID
                    buildID = nil
                end

                if buildID == nil and buildIDofOld ~= nil and
                    doesUnitExistAlive(buildIDofOld) == true then
                    buildIDofOld = nil
                end
            end
        end

    end
    boolBuilding = false
end

function moveFactory()
    Sleep(100)
    local spGetUnitPiecePosition = Spring.GetUnitPiecePosDir
    local spMovCtrlSetPos = Spring.MoveCtrl.SetPosition
    local spValidUnitID = Spring.ValidUnitID
    local LGetUnitPieceRotation = GetUnitPieceRotation
    local LUpdateUnitPosition = UpdateUnitPosition
    local spMoveCtrlSetRotation = Spring.MoveCtrl.SetRotation
    Hide(attachPoint)
    waitTillComplete(unitID)
    while (true) do
        if (not spValidUnitID(factoryID)) then newFactory() end

        local x, y, z = spGetUnitPiecePosition(unitID, attachPoint)
        spMovCtrlSetPos(factoryID, x, y - 10, z + 1)
        dx, dy, dz = Spring.GetUnitRotation(unitID)

        spMoveCtrlSetRotation(factoryID, dx, dy, dz)
        buildID = Spring.GetUnitIsBuilding(factoryID)
        if buildID then
            setSpeedEnv(unitID, 0.0)
        else
            reSetSpeed(unitID)
        end
        Sleep(30)
    end
end

boolMoving = false
function delayedStop()
    Signal(SIG_STOP)
    SetSignalMask(SIG_STOP)
    Sleep(400)
    boolMoving = false
end

function script.StartMoving() boolMoving = true end

function script.StopMoving() StartThread(delayedStop) end

function script.StartMoving()
    if TablesOfPiecesGroups and TablesOfPiecesGroups["wheel"] then
        spinT(TablesOfPiecesGroups["wheel"], x_axis, 260, 0.3)
    end
end

function script.StopMoving()
    if TablesOfPiecesGroups and TablesOfPiecesGroups["wheel"] then
        stopSpinT(TablesOfPiecesGroups["wheel"], x_axis, 3)
    end
end

function script.Killed(recentDamage, maxHealth)
    if Spring.ValidUnitID(factoryID) == true then
        GG.UnitsToKill:PushKillUnit(factoryID, true, true)
    end

    return 0
end
-- Buildi

function script.Activate() return 1 end

function script.Deactivate() return 0 end

boolLaunch = false
function launchBuilding(delayTime) boolLaunch = true end

-- Laun

function script.Create()

    Spring.SetUnitNoSelect(unitID, true)
    x, y, z = Spring.GetUnitPosition(unitID)
    Spring.SetUnitMoveGoal(unitID, x - 20, y, z)

    StartThread(workInProgress)
    StartThread(moveFactory)
    StartThread(updateBoolisBuilding)

end
