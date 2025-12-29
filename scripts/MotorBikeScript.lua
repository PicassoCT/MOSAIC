include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()
local SIG_ORDERTRANFER = 1
local SIG_HONK = 2
local SIG_INTERNAL = 4
local SIG_STOP = 8
local SIG_Kill = 16

local center = piece "center"
local attachPoint = piece"attachPoint"
local Civilian = piece"Civilian"
local motorBikeLoadableTypeTable = getMotorBikeLoadableTypes(UnitDefs)
local truckTypeTable = getTruckTypeTable(UnitDefs)
local Seat = piece "Seat"

local myTeamID = Spring.GetUnitTeam(unitID)
local boolGaiaUnit = myTeamID == Spring.GetGaiaTeamID()
local boolIsDelivery = randChance(66)
local myDeliverySymbolIndex = nil
local boolDeliveryOnGuy = false
local myDeliverySymbol = nil
local activeWheels = {}
local passenger = nil
local bikeType = nil
SteerParts = {}
local Signum = -1
local LeanFactor = 1.0
bikeWheelMap = {}
local boolIsCivilianTruck = (truckTypeTable[unitDefID] ~= nil)
local boolIsPoliceTruck = unitDefID == UnitDefNames["policetruck"].id


 
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
   StartThread(buildBike)
end

function buildBike()

    bikeType = math.random(1, #TablesOfPiecesGroups["Bike"])
    myDeliverySymbolIndex = math.random(1,#TablesOfPiecesGroups["Delivery"])
    boolDeliveryOnGuy = myDeliverySymbolIndex % 2 == 1
    myDeliverySymbol = TablesOfPiecesGroups["Delivery"][myDeliverySymbolIndex]
    hideAll(unitID)
    Sleep(1)
    ShowAssert(TablesOfPiecesGroups["Bike"][bikeType])
    if TablesOfPiecesGroups["Steering"][bikeType] then
        ShowAssert(TablesOfPiecesGroups["Steering"][bikeType] )
    end

    if bikeType == 7 then
        ShowAssert(TablesOfPiecesGroups["Steering"][5] )
    end

    if boolIsDelivery and not boolDeliveryOnGuy then
        ShowAssert(myDeliverySymbol)
    end
    defaultTable = {Signum = 1, LeanFactor = 0.0, SteerParts = {}}    
    bikeWheelMap = makeTable(defaultTable, 7)
    bikeWheelMap[1] = {Signum = -1, LeanFactor = 0.1}    
    SteerPartsCollection = {}
    for i= 1, 4 do
        bikeWheelMap[1][#bikeWheelMap[1] + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    bikeWheelMap[2] = defaultTable  
    for i= 5, 6 do
        bikeWheelMap[2][#bikeWheelMap[2] + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    bikeWheelMap[3].Signum = -1
    for i= 7, 8 do
        bikeWheelMap[3][#bikeWheelMap[3] + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    bikeWheelMap[3].SteerParts[#bikeWheelMap[3].SteerParts + 1 ] = {piece("SteeringAddition3")}

    for i= 9, 10 do
        bikeWheelMap[4][#bikeWheelMap[4] + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    for i= 11, 12 do
        bikeWheelMap[5][#bikeWheelMap[5] + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    for i= 13, 18 do
        bikeWheelMap[6][#bikeWheelMap[6] + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    bikeWheelMap[7]= bikeWheelMap[5]




    if boolGaiaUnit then   ShowAssert(Civilian)   end

    Signum = bikeWheelMap[bikeType].Signum
    LeanFactor = bikeWheelMap[bikeType].LeanFactor
    showTAssert(bikeWheelMap[bikeType])
    activeWheels = bikeWheelMap[bikeType]
    SteerParts = bikeWheelMap[bikeType].SteerParts 
    if SteerParts then
        showTAssert(SteerParts)
    end
    
    StartThread(updateSteering)
    if not boolGaiaUnit then
        setSpeedEnv(unitID, 0.0)  
    end
end

function assertType(name, types)
    assert(type(name) == types, "value of type " .. type(name) .. " is not a "..types)  
end

function script.TransportPickup(passengerID)
	HideAssert(Civilian)
    if motorBikeLoadableTypeTable[Spring.GetUnitDefID(passengerID)] then
		reset(center, math.pi)
        Signal(SIG_KILL)
        setUnitValueExternal(passengerID, 'WANT_CLOAK', false)
        Spring.SetUnitNoSelect(passengerID, true)
        Spring.UnitAttach(unitID, passengerID, attachPoint)
        if not boolGaiaUnit then
            setSpeedEnv(unitID, 1.0)
        end
        passenger = passengerID
    end
end

function script.TransportDrop(passengerID, x, y, z)
    if boolGaiaUnit then ShowAssert(Civilian) end
    if doesUnitExistAlive(passengerID) then
        passenger = nil
        Spring.UnitDetach(passengerID)
        px,py,pz = Spring.GetUnitPosition(unitID)
        Spring.SetUnitNoSelect(passengerID, false)
        Command(unitID, "go", {x = px,y= py, z=pz}, {})

        if not boolGaiaUnit then
            setSpeedEnv(unitID, 0.0)
            StartThread(killAfterTime)
        end
    end
end

function killAfterTime()
    Signal(SIG_KILL)
    SetSignalMask(SIG_KILL)
	factor = 2.0
	vx,vy,vz = Spring.GetUnitDirection(unitID) 
	Spring.AddUnitImpulse(unitID, vx * factor, vy * factor, vz * factor)
	Sleep(2000)
	WTurn(center, z_axis,math.rad(90 * randSign()), math.pi)
    Sleep(GameConfig.motorBikeSurvivalStandaloneMS)
    Spring.DestroyUnit(unitID, false, true)
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
        --if boolDebugPrintDiff then Spring.Echo("Current Heading"..tempHead) end
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

boolGaiaUnit = (Spring.GetUnitTeam(unitID) == Spring.GetGaiaTeamID())
boolMoving = false
boolPreviouslyMoving = boolMoving
function updateSteering()
    StartThread(headChangeDetector, 3)   
    Sleep(100)

    while true do
        if boolPreviouslyMoving == false and boolMoving == true then
            if not (passenger and Spring.GetUnitTransporter(passenger) == unitID) then
                ShowAssert(Civilian)
                ShowAssert(myDeliverySymbol)
            end
        end
        if boolMoving == true and boolTurning == true then
           if boolGaiaUnit then
                ShowAssert(myDeliverySymbol)
                ShowAssert(Civilian)
           end
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
        boolPreviouslyMoving = boolMoving
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
        WTurn(center,y_axis, math.rad(-10 * LeanFactor),0.1 )
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
        StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/car/honk"..math.random(1,7)..".ogg", GameConfig.truckHonkLoudness, 1000, 1)
    end
end

function delayedStop()
    Signal(SIG_STOP)
    SetSignalMask(SIG_STOP)
    Sleep(250)
    boolMoving = false
    StartThread(honkIfHorny)
    Sleep(3000)
    HideAssert(Civilian)

end

function script.StopMoving() 
    StartThread(delayedStop)
    stopSpinT(activeWheels, x_axis, 3) 
    if boolGaiaUnit then ShowAssert(Civilian) end
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function threadStateStarter()
    Sleep(100)
    while true do
        if boolStartFleeing == true then
            boolStartFleeing = false
            StartThread(fleeEnemy, attackerID)
        end
        Sleep(250)   
    end
end

function fleeEnemy(enemyID)
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_STARTED, "fleeing")
    if not enemyID then 
        setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_ENDED, "fleeing")
        return 
    end

    while doesUnitExistAlive(enemyID) and distanceUnitToUnit(unitID, enemyID) < GameConfig.civilian.PanicRadius do
        runAwayFrom(unitID, enemyID, GG.GameConfig.civilian.FleeDistance)
        Sleep(500)
    end

    setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_ENDED, "fleeing")
end

attackerID = 0
boolStartFleeing = false 
function startFleeing(attackerID)
    if not attackerID then return end
    boolStartFleeing = true
end
