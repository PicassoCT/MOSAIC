include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"
TablesOfPiecesGroups = {}

SIG_ORDERTRANFER = 1
SIG_HONK = 2
SIG_INTERNAL = 4
SIG_STOP = 8

center = piece "center"
attachPoint = piece"attachPoint"
motorBikeLoadableTypeTable = getMotorBikeLoadableTypes(UnitDefs)
Seat = piece "Seat"
myDefID = Spring.GetUnitDefID(unitID)
activeWheels = {}
passenger = nil
bikeType = math.random(1,3)
 SteerParts = {}
 Signum = -1
LeanFactor = 1.0

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
    hideAll(unitID)
    Show(TablesOfPiecesGroups["Bike"][bikeType])
    Show(TablesOfPiecesGroups["Steering"][bikeType])
    assert(TablesOfPiecesGroups["Steering"][bikeType])
    SteerParts[#SteerParts +1 ]= TablesOfPiecesGroups["Steering"][bikeType]

    if bikeType == 1 then 
        Signum = -1
        LeanFactor = 0.1
        for i=1, 4 do
            Show(TablesOfPiecesGroups["Wheel"][i])
            activeWheels[#activeWheels+1] = TablesOfPiecesGroups["Wheel"][i]
        end
    elseif bikeType == 2 then
        Signum = 1
        for i=5, 6 do
            Show(TablesOfPiecesGroups["Wheel"][i])
            activeWheels[#activeWheels+1] = TablesOfPiecesGroups["Wheel"][i]
        end
    elseif bikeType == 3 then 
        Signum = -1
        for i=7, 8 do
            Show(TablesOfPiecesGroups["Wheel"][i])
            activeWheels[#activeWheels+1] = TablesOfPiecesGroups["Wheel"][i]
        end
        SteerParts[#SteerParts +1 ]= piece("SteeringAddition3")
        assert(piece("SteeringAddition3"))
        Show(piece("SteeringAddition3"))
    end
    StartThread(updateSteering)
end


function script.TransportPickup(passengerID)
    if motorBikeLoadableTypeTable[Spring.GetUnitDefID(passengerID)] then
        Spring.SetUnitNoSelect(passengerID, true)
        Spring.UnitAttach(unitID, passengerID, attachPoint)
        passenger = passengerID
    end
end

function script.TransportDrop(passengerID, x, y, z)
    if doesUnitExistAlive(passengerID) then
        passenger= nil
        Spring.UnitDetach(passengerID)
        Spring.SetUnitNoSelect(passengerID, false)
    end
end

boolTurning = false
boolTurnLeft = false

function headChangeDetector( moveTreshold)
    TurnCount = 0
    headingOfOld = Spring.GetUnitHeading(unitID)
    oldx, _, oldz = Spring.GetUnitPosition(unitID)
    while true do
        Sleep(500)
 
        tempHead = Spring.GetUnitHeading(unitID)
        if boolDebugPrintDiff then Spring.Echo("Current Heading"..tempHead) end
        if tempHead ~= headingOfOld then
            TurnCount = TurnCount + 1
            if TurnCount > 3 then
                boolTurning = true
            end
        else
            TurnCount = 0
            boolTurning = false
        end
        boolTurnLeft = headingOfOld > tempHead
        headingOfOld = tempHead
    end
end

boolMoving = false
function updateSteering()
    StartThread(headChangeDetector, 3)   
    Sleep(100)

    while true do
        if boolMoving == true and boolTurning == true then
           if boolTurnLeft == true then
                turnT(SteerParts, y_axis, -10, 1)
                Turn(center,x_axis ,math.rad(-15*LeanFactor),1)
                WaitForTurns(SteerParts)
            else
                turnT(SteerParts, y_axis, 10, 1)
                Turn(center,x_axis,math.rad(15*LeanFactor),1)
                WaitForTurns(SteerParts)
            end
        else
            turnT(SteerParts, y_axis, 0, 1)
            Turn(center, x_axis, math.rad(0),1)
            WaitForTurns(SteerParts)
        end

        Sleep(250)
    end
end

function script.Killed(recentDamage, _)
    if doesUnitExistAlive(passenger) then
        Spring.DestroyUnit(passenger, true, true)
    end

    createCorpseCUnitGeneric(recentDamage)
    return 1
end

function delayedRiseAndFall()
    if boolTurning == false then
    WTurn(center,y_axis, math.rad(-10*LeanFactor),0.1 )
    WTurn(center,y_axis, math.rad(0),0.2)
    end
end
--- -aimining & fire weapon
function script.StartMoving()
        boolMoving = true
        Signal(SIG_HONK)
        spinT(activeWheels, x_axis, 260 * Signum, 0.3)
        StartThread(delayedRiseAndFall)
end

function honkIfHorny()
    Signal(SIG_HONK)
    SetSignalMask(SIG_HONK)
    Sleep(250)
    if math.random(0,100) > 80 and boolIsCivilianTruck == true and isRushHour() == true then
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/car/honk"..math.random(1,7)..".ogg", 1.0, 1000, 1)
    end
end

function delayedStop()
    Signal(SIG_STOP)
    SetSignalMask(SIG_STOP)
    Sleep(250)
    boolMoving = false
    StartThread(honkIfHorny)
end

function script.StopMoving() 
    StartThread(delayedStop)
    stopSpinT(activeWheels, x_axis, 3) 
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
