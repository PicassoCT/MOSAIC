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
activeWheels = {}
local passenger = nil
local bikeType = nil
SteerParts = {}
local Signum = 1
local LeanFactor = 1.0
bikeWheelMap = {}
local boolIsCivilianTruck = (truckTypeTable[unitDefID] ~= nil)
local boolIsPoliceTruck = unitDefID == UnitDefNames["policetruck"].id


 
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
   StartThread(buildBike)
end

function buildBike()

    hideAll(unitID)
    Sleep(1)
    bikeType = math.random(1, #TablesOfPiecesGroups["Bike"])
    myDeliverySymbolIndex = math.random(1,#TablesOfPiecesGroups["Delivery"])
    boolDeliveryOnGuy = myDeliverySymbolIndex % 2 == 1
    myDeliverySymbol = TablesOfPiecesGroups["Delivery"][myDeliverySymbolIndex]

    Show(TablesOfPiecesGroups["Bike"][bikeType])
    if TablesOfPiecesGroups["Steering"][bikeType] then
        Show(TablesOfPiecesGroups["Steering"][bikeType] )
    end

    if bikeType == 7 then
        Show(TablesOfPiecesGroups["Steering"][5] )
    end

    if boolIsDelivery and not boolDeliveryOnGuy then
        Show(myDeliverySymbol)
    end
    defaultTable = { LeanFactor = 0.0, SteerParts = {}, wheels = {}} 
    bikeWheelMap = makeTable(defaultTable, 7)
    bikeWheelMap[1].LeanFactor = 0.1

    for i= 1, 4 do
        assert(TablesOfPiecesGroups["Wheel"][i], i)
        bikeWheelMap[1].wheels[#bikeWheelMap[1].wheels + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    for i= 5, 6 do
        assert(TablesOfPiecesGroups["Wheel"][i], i)
        bikeWheelMap[2].wheels[#bikeWheelMap[2].wheels + 1] = TablesOfPiecesGroups["Wheel"][i]
    end


    for i= 7, 8 do
        assert(TablesOfPiecesGroups["Wheel"][i], i)
        bikeWheelMap[3].wheels[#bikeWheelMap[3].wheels + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    bikeWheelMap[3].SteerParts[#bikeWheelMap[3].SteerParts + 1 ] = piece("SteeringAddition3")

    for i= 9, 10 do
        assert(TablesOfPiecesGroups["Wheel"][i], i)
        bikeWheelMap[4].wheels[#bikeWheelMap[4].wheels + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    for i= 11, 12 do
        assert(TablesOfPiecesGroups["Wheel"][i], i)
        bikeWheelMap[5].wheels[#bikeWheelMap[5].wheels + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    for i= 13, 18 do
        assert(TablesOfPiecesGroups["Wheel"][i], i)
        bikeWheelMap[6].wheels[#bikeWheelMap[6].wheels + 1] = TablesOfPiecesGroups["Wheel"][i]
    end

    local wheelCopy = bikeWheelMap[5].wheels
    bikeWheelMap[7].wheels = wheelCopy

    if boolGaiaUnit then Show(Civilian) end

    LeanFactor = bikeWheelMap[bikeType].LeanFactor
    activeWheels = bikeWheelMap[bikeType].wheels

    showT(activeWheels)
    SteerParts = bikeWheelMap[bikeType].SteerParts 
    if SteerParts and count(SteerParts) > 0 then
        showT(SteerParts)
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
	Hide(Civilian)
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
    if boolGaiaUnit then Show(Civilian) end
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
                Show(Civilian)
                Show(myDeliverySymbol)
            end
        end

        assert(SteerParts)
        if boolMoving == true and boolTurning == true then
           if boolGaiaUnit then
                Show(myDeliverySymbol)
                Show(Civilian)
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
    Hide(Civilian)

end

function script.StopMoving() 
    StartThread(delayedStop)
    stopSpinT(activeWheels, x_axis, 3) 
    if boolGaiaUnit then Show(Civilian) end
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
