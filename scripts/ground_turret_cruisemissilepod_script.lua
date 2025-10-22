include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

SIG_LAUNCHCLOUD=1

local TablesOfPiecesGroups = {}
groundFeetSensors = {}
center = piece"Pod"
rocketTransportableType = getRocketTransportableTypes(UnitDefs)
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
rocketPiece = piece("rocketPiece")

boolIsTransportPod = UnitDefs[unitDefID].name == "ground_turret_cm_transport"
DefIDPieceMapFold = {
    [UnitDefNames["ground_turret_cm_airstrike"].id] = piece("cm_airstrike_fold"),
    [UnitDefNames["ground_turret_cm_transport"].id] = piece("cm_turret_ssied_fold"),
    [UnitDefNames["ground_turret_cm_antiarmor"].id] = piece("cm_AntiArmour_fold"),
}

DefIDPieceMap = {
    [UnitDefNames["ground_turret_cm_airstrike"].id] = piece("cm_airstrike_proj"),
    [UnitDefNames["ground_turret_cm_transport"].id] = piece("cm_turret_ssied_proj"),
    [UnitDefNames["ground_turret_cm_antiarmor"].id] = piece("cm_AntiArmour_proj"),
}


function showHideDependantOnType(boolFolded)
    assert(DefIDPieceMap[unitDefID])
    assert(DefIDPieceMapFold[unitDefID])
    Hide(DefIDPieceMap[unitDefID])
    Hide(DefIDPieceMapFold[unitDefID])
    if boolFolded then
        Show(DefIDPieceMapFold[unitDefID])
    else
        Show(DefIDPieceMap[unitDefID])
    end
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
    showT(TablesOfPiecesGroups["UpLeg"])
    showT(TablesOfPiecesGroups["LowLeg"])
    Hide(rocketPiece)
    Hide(aimpiece)
    showHideDependantOnType(true)
    Turn(aimpiece, x_axis, math.rad(180), 0)
    Show(Door1)
    Show(Door2)

    StartThread(foldControl)
    StartThread(launchCloud)
    StartThread(launchStateMachineThread)
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
boolLaunchAnimationStarted = false
boolLaunchAnimationCompleted = false
Door1 = piece("Door1")
Door2 = piece("Door2")
function launchAnimation()
    factor = 2.0
    Signal(SIG_LAUNCHCLOUD)
    SetSignalMask(SIG_LAUNCHCLOUD)
    boolLaunchAnimationStarted = true
    boolLaunchAnimationCompleted= false
    showHideDependantOnType(true)
    WTurn(Door1, x_axis, math.rad(140), 30)
    WTurn(Door2, x_axis, math.rad(-140), 30)
    WTurn(PodTop, z_axis, math.rad(0), math.pi * 3)
    WTurn(PodTop, z_axis, math.rad(179), math.pi * 3)
    WMove(rocketPiece, y_axis, 500*factor, 250*factor)
    showHideDependantOnType(false)
    WMove(rocketPiece, y_axis, 1000*factor, 1000*factor)    
    boolLaunchAnimationCompleted = true
end

currentLaunchState = "ready"
function launchStateMachineThread()
    launchStateMachine = {}
    launchStateMachine["ready"] =   function (frame, oldState, persPack)
        persPack.launchingCounter = 0
        Sleep(10)
        showHideDependantOnType(true)
        WMove(rocketPiece, y_axis, 0, 0)
        WTurn(PodTop, z_axis, math.rad(0), math.pi * 3)
        if boolFireRequest then
            return "launching"
        end
        boolFireRequest = false
        return "ready"
    end

   launchStateMachine["launching"] = function(frame, oldState, persPack)
        if oldState == "ready" then
            StartThread(launchAnimation)
        end
        if boolFireRequest == false then
            persPack.launchingCounter = persPack.launchingCounter + 1
        end

        if boolFireRequest == true and boolLaunchAnimationCompleted == true then
            return "fire"
        end

        if  persPack.launchingCounter > 50 and boolLaunchAnimationCompleted == true then
            Signal(SIG_LAUNCHCLOUD)
            return "ready"
        end

        boolFireRequest = false
        return "launching"
    end

    launchStateMachine["fire"] = function (frame, oldState, persPack)
        Hide(rocketPiece)
        return "fire"
    end

    launchStateMachine["reloading"] = function(frame, oldState, persPack)
        boolFireRequest =false
        if oldState == "fire" then persPack.startFrame = frame end
        if persPack.startFrame + ((25*1000)/30) < frame then return "ready" end
        Move(rocketPiece, y_axis, 0, 0)
        showHideDependantOnType(true)
        return "reloading"
    end

    oldState = "ready"
    persPack = {}
    while true do
        newState = launchStateMachine[currentLaunchState](Spring.GetGameFrame(), oldState, persPack)
       -- echo("Launchstatemachine:"..currentLaunchState.."/"..oldState)
        oldState = currentLaunchState
        currentLaunchState = newState
        Sleep(100)
    end
end



function launchCloud()   
    while true do
        while currentLaunchState == "launching" do
            EmitSfx(rocketPiece, 1024)
            if maRa()== maRa()  and maRa()== maRa()  then   EmitSfx(rocketPiece, 1025)  end
            if maRa()== maRa() then   EmitSfx(rocketPiece, 1026)  end
            Sleep(125)
        end
        Sleep(150)
    end    
end

function script.AimWeapon1(Heading, pitch)
    boolFireRequest= true
    return currentLaunchState == "fire"
end

function script.FireWeapon1()   
    currentLaunchState = "reloading"
    return true
end

boolMoving = false

function script.StartMoving() boolMoving = true end

function script.StopMoving() boolMoving = false end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

local boolFilled = false
function script.TransportPickup(passengerID)
    defID = Spring.GetUnitDefID(passengerID)
    if not boolFilled and boolIsTransportPod and rocketTransportableType[defID] then
        if not GG.CruiseMissileTransport then GG.CruiseMissileTransport = {} end
        GG.CruiseMissileTransport[unitID] = serializeUnitToTable(passengerID)
        boolFilled = true
    end
end

function script.TransportDrop(passengerID, x, y, z)
    transporting = Spring.GetUnitIsTransporting (unitID)
    if boolFilled and boolIsTransportPod  then
        id = reconstituteUnitFromTable(GG.CruiseMissileTransport[unitID])
        GG.CruiseMissileTransport[unitID] = nil
        moveUnitToUnit(id, unitID, 10, 0, 0)
        boolFilled = false
    end
end
