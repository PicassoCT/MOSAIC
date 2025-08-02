include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()
SIG_ORDERTRANFER = 1
SIG_HONK = 2
SIG_INTERNAL = 4
SIG_STOP = 8
SIG_Kill = 16

local center = piece "center"
local attachPoint = piece"attachPoint"
local Civilian = piece"Civilian"
local motorBikeLoadableTypeTable = getMotorBikeLoadableTypes(UnitDefs)
local truckTypeTable = getTruckTypeTable(UnitDefs)
local Seat = piece "Seat"

myTeamID = Spring.GetUnitTeam(unitID)
local boolGaiaUnit = myTeamID == Spring.GetGaiaTeamID()
local boolIsDelivery = randChance(66)
local myDeliverySymbolIndex = nil
local boolDeliveryOnGuy = false
local myDeliverySymbol = nil
local activeWheels = {}
local passenger = nil
local bikeType = math.random(1,3)
local SteerParts = {}
local Signum = -1
local LeanFactor = 1.0


boolIsCivilianTruck = (truckTypeTable[unitDefID] ~= nil)
boolIsPoliceTruck = unitDefID == UnitDefNames["policetruck"].id
 
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
    myDeliverySymbolIndex = math.random(1,#TablesOfPiecesGroups["Delivery"])
    boolDeliveryOnGuy = myDeliverySymbolIndex % 2 == 1
    myDeliverySymbol = TablesOfPiecesGroups["Delivery"][myDeliverySymbolIndex]
    hideAll(unitID)
    Show(TablesOfPiecesGroups["Bike"][bikeType])
    Show(TablesOfPiecesGroups["Steering"][bikeType])
    if boolIsDelivery and not boolDeliveryOnGuy then
        Show(myDeliverySymbol)
    end
    assert(TablesOfPiecesGroups["Steering"][bikeType])
    if boolGaiaUnit then   Show(Civilian)   end

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
    if not boolGaiaUnit then
        setSpeedEnv(unitID, 0.0)  
    end
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
    if boolGaiaUnit then   Show(Civilian)   end
    if doesUnitExistAlive(passengerID) then
        passenger= nil
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
	Spring.AddUnitImpulse(unitID, vx*factor, vy*factor, vz*factor)
	Sleep(2000)
	WTurn(center, z_axis,math.rad(90*randSign()), math.pi)
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
boolGaiaUnit = (Spring.GetUnitTeam(unitID) == Spring.GetGaiaTeamID())
boolMoving = false
function updateSteering()
    StartThread(headChangeDetector, 3)   
    Sleep(100)

    while true do
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
