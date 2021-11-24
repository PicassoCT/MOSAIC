include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
groundFeetSensors = {}
center = piece"Pod"

function script.HitByWeapon(x, z, weaponDefID, damage) end

Pod = piece "Pod"
assert(Pod)
PodTop = piece "PodTop"
aimpiece = piece "aimpiece"
if not aimpiece then
    echo("Unit of type " .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no aimpiece")
end
if not Pod then
    echo("Unit of type" .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no Pod")
end
rocketPiece = aimpiece
myDefID = Spring.GetUnitDefID(unitID)
boolIsTransportPod = UnitDefs[myDefID].name == "ground_turret_cm_transport"
DefIDPieceMap = {
    [UnitDefNames["ground_turret_cm_airstrike"].id] = "cm_airstrike_fold",
    [UnitDefNames["ground_turret_cm_transport"].id] = "cm_walker_fold",
    [UnitDefNames["ground_turret_cm_antiarmor"].id] = "cm_AntiArmour_fold"
}


function showDependantOnType()
    myDefID = Spring.GetUnitDefID(unitID)
    assert(DefIDPieceMap[myDefID])
    name = DefIDPieceMap[myDefID]
    rocketPiece = piece(name)
    Show(rocketPiece)
end

function script.Create()

    if not GG.CruiseMissileTransport then GG.CruiseMissileTransport  = {} end
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
        groundFeetSensors = TablesOfPiecesGroups["GroundSensor"]
    hideT(GroundSensor)
    resetAll(unitID)
    hideAll(unitID)
    Show(Pod)
    Show(PodTop)
    showDependantOnType()
    showT(TablesOfPiecesGroups["UpLeg"])
    showT(TablesOfPiecesGroups["LowLeg"])
    Hide(aimpiece)
    Turn(aimpiece, x_axis, math.rad(180), 0)

    StartThread(foldControl)
 --   StartThread(debugCEGScript)
end

function foldControl()

    while true do
        if isTransported(unitID) == false then
            unfoldWalkLoop()
        else
            fold()
        end
        Sleep(50)
    end
end


function turnFeedToGround(nr)

    local direction = currentDeg[nr].dirUp

    x, y, z = Spring.GetUnitPiecePosDir(unitID, groundFeetSensors[nr])
    gh = Spring.GetGroundHeight(x, z)
    if y  > gh then -- we are underground
        currentDeg[nr].val = currentDeg[nr].val + direction
    else -- aboveground
        direction = direction * -1
        currentDeg[nr].val = currentDeg[nr].val + direction
    end
    Turn(TablesOfPiecesGroups["UpLeg"][nr], currentDeg[nr].axis,
         math.rad(currentDeg[nr].val), math.pi*speed)

    -- check for directional change
    if direction ~= currentDeg[nr].lastDir then
        currentDeg[nr].countSwitches = currentDeg[nr].countSwitches + 1
        currentDeg[nr].lastDir = direction
    end

    return boolDone
end

function isDone()
    boolDone = true
    for i = iStart, iEnd do boolDone = boolDone and currentDeg[i].countSwitches > 1 end
    return boolDone
end

function setNotDone()
    boolDone = true
    for i = iStart, iEnd do currentDeg[i].countSwitches = 0 end
end

currentDeg = {
    [1] = {val = -50, dirUp = -1, lastDir = -1, countSwitches = 0, axis =z_axis, sign= 1},    
    [3] = {val = 50, dirUp = 1, lastDir = 1, countSwitches = 0, axis =z_axis, sign= -1},

    [2] = {val = 50, dirUp = 1, lastDir = -1, countSwitches = 0, axis =x_axis, sign= -1},
    [4] = {val =  -50, dirUp = -1, lastDir = 1, countSwitches = 0, axis =x_axis, sign= 1},
}

iterator =1
speed= math.pi
maxSwingHeigth = 250
baseSwing = 80
iStart= 1
iEnd = 4
function unfoldWalkLoop()
    if boolMoving == true then
        Spin(center, y_axis, math.rad(12.0), 0)
        iterator = (iterator % 4)+ 1
        aterator = ((iterator + 1 ) % 4) + 1

        currentDeg[iterator].val = 80 * currentDeg[iterator].dirUp
        currentDeg[iterator].lastDir = currentDeg[iterator].dirUp
        currentDeg[iterator].countSwitches = 0

        currentDeg[aterator].val = 60 * currentDeg[aterator].dirUp
        currentDeg[aterator].lastDir= currentDeg[aterator].dirUp
        currentDeg[aterator].countSwitches = 0

        travelHeigth = baseSwing + (iterator % 2 )* 125
        Move(center,y_axis, travelHeigth, 250)
    else
        StopSpin(center,y_axis, 0)
        Turn(center,y_axis,math.rad(0),math.pi*speed)
        Move(center,y_axis, baseSwing, 50)
        WaitForTurns(center)
        WMove(center,y_axis, baseSwing, 50)
    end

    boolDone = isDone()
    Sleep(10)
    while boolDone == false do
        Sleep(10)
        WaitForTurns(TablesOfPiecesGroups["UpLeg"])

        for i = iStart, iEnd do
            turnFeedToGround(i)
            Turn(TablesOfPiecesGroups["LowLeg"][i], currentDeg[i].axis, math.rad( currentDeg[i].sign *90), math.pi*speed)
        end
        WaitForTurns(TablesOfPiecesGroups["LowLeg"])
        WaitForTurns(TablesOfPiecesGroups["UpLeg"])
        boolDone = isDone()
    end

    Move(center,y_axis, 0, math.pi)
end

function fold()
    WaitForTurns(TablesOfPiecesGroups["UpLeg"])
 

    for i = iStart, iEnd do
        Turn(TablesOfPiecesGroups["UpLeg"][i], currentDeg[i].axis, math.rad(0), math.pi*speed)
        Turn(TablesOfPiecesGroups["LowLeg"][i], currentDeg[i].axis, math.rad(0), math.pi*speed)
    end
    WaitForTurns(TablesOfPiecesGroups["LowLeg"])
    WaitForTurns(TablesOfPiecesGroups["UpLeg"])
    setNotDone()
end

function script.Killed(recentDamage, _) return 1 end

-- aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return rocketPiece end

function script.AimWeapon1(Heading, pitch)
    WTurn(PodTop, z_axis, math.rad(180), math.pi * 3)
    StartThread(launchCloud)
    WMove(rocketPiece, y_axis, 1000, 1000)
    WMove(rocketPiece, y_axis, 4000, 2000)
    return boolFired == false
end
function launchCloud()
    while boolFired==false do
        EmitSfx(rocketPiece, 1024)
        Sleep(125)
    end
end

boolFired = false
function script.FireWeapon1()
    boolFired= true
    StartThread(delayedDestruct)
    return true
end

function delayedDestruct()
  Hide(rocketPiece)
  Sleep(5000)
  Spring.DestroyUnit(unitID, true, false)

end

boolMoving = false

function script.StartMoving() boolMoving = true end

function script.StopMoving() boolMoving = false end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function debugCEGScript()
   StartThread(launchCloud)
    while true do
    WTurn(PodTop, z_axis, math.rad(180), math.pi * 3)
    WMove(rocketPiece, y_axis, 1000, 1000)
    WMove(rocketPiece, y_axis, 4000, 2000)
    Sleep(3000)
    WTurn(PodTop, z_axis, math.rad(0), 0)
    WMove(rocketPiece, y_axis, 0, 0)

    end


end


TODO
boolIsTransportPod