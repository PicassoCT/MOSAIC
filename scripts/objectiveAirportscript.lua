include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
Airport = piece "Airport"
statusTable = {}

JourneyPoint = piece "JourneyPoint"
PlanePositionTurnAxis = 3
PlanePositionMoveAxis = 2
directionToGo = math.random(0, 360)
SIG_PLANE = 1
boolCircling = false
boolCirclingDone = false
distanceUp = 45000
ferryFreeTable = {}
ferryTurnAxis = 3
gaiaTeamID = Spring.GetGaiaTeamID()
local ferryScramJet = {}
function resetFerrysScramJet()
    for i=1, #TablesOfPiecesGroups["Shuttle"] do
        ferryScramJet[i] = randChance(25)
    end
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    resetFerrysScramJet()
    setup()
    StartThread(comingAndGoing)
    StartThread(advertisingBlimp)
end

function playDepartureGong(offset)
    hours, minutes, seconds, percent = getDayTime()     
    if percent % 0.25 < 0.1 and not isNight() then
        maphash = getMapHash(6) + 1
        name = "sounds/objective/airport_departure"..maphash..".ogg"
        StartThread(PlaySoundByUnitDefID, unitDefID, name , 0.1, maphash*1000, 1)
    end
end

function playAircraftSounds()
    if not isNight() then
        StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/objective/airport_arrivaldeparture.ogg", 0.1, 120000, 1)
    end
end

function advertisingBlimp()
    ax,az = math.ceil(Game.mapSizeX/2) , math.ceil(Game.mapSizeZ/2)
    ay = Spring.GetGroundHeight(ax,az)
    Sleep(100)
    blimpID = createUnitAtUnit(gaiaTeamID, "advertising_blimp", unitID, 0, 50, 0, 0)
    Spring.AddUnitImpulse(blimpID, math.random(5,15)*-3.0, 10, math.random(5,15)*-3.0)
    Sleep(100)

    while true do
        if  doesUnitExistAlive(blimpID) == false then
            blimpID = createUnitAtUnit(gaiaTeamID, "advertising_blimp", unitID, 0, 50, 0, 0)
            Spring.AddUnitImpulse(blimpID, math.random(5,15)*-3, 10, math.random(5,15)*-3)
            Spring.GiveOrderToUnit(blimpID, CMD.PATROL, { ax , ay, az }, {})                 
        end
        Sleep(1000)
    end
end

function setup()
    hideAll(unitID)
    Show(Airport)
    showT(TablesOfPiecesGroups["Gateway"])
    PlanePosition = TablesOfPiecesGroups["SwingCenter"][2]
    StartThread(blink)
    for i = 1, #TablesOfPiecesGroups["Shuttle"] do
        if ferryScramJet[i] == false then
            if TablesOfPiecesGroups["Shuttle"][i]  then
                if maRa() == true then
                    statusTable[TablesOfPiecesGroups["Shuttle"][i]] = "landed"
                    Show(TablesOfPiecesGroups["Shuttle"][i])
                    Show(TablesOfPiecesGroups["Engine"][i])
                else
                    statusTable[TablesOfPiecesGroups["Shuttle"][i]] = "docked"
                end
            end
        end
    end

    for i = 1, #TablesOfPiecesGroups["AirCar"] do
        StartThread(
            vtolLoop,
            unitID,
            TablesOfPiecesGroups["AirCar"][i],
            math.random(5, 10) * 15 * 1000,
            math.random(10, 30) * 15 * 10000
            )
    end
end

function cturnT(t, axis, degs, speed, boolInstantUpdate, boolWait)
    if boolInstantUpdate then
        for i = 1, #t, 1 do
            if t[i] then
                Turn(t[i], axis, math.rad(degs), 0, true)
            end
        end
        return
    end

    if not speed or speed == 0 then
        for i = 1, #t, 1 do
            if t[i] then
                Turn(t[i], axis, math.rad(degs), 0)
            end
        end
    else
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(degs), speed)
        end
        if boolWait then
            for i = 1, #t, 1 do
                if t[i] then
                    WaitForTurn(t[i], axis)
                end
            end
        end
    end
    return
end

function blink()
    showT(TablesOfPiecesGroups["SwitchLight"])
    upaxis = 1
    while true do
        upaxis = (upaxis % 3 + 1)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 180, 0)
        Sleep(2500)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 0, 0)
        Sleep(2500)
    end
end


function comingAndGoing()
    while true do
        while GG.GlobalGameState == GameConfig.GameState.normal do
        repeat 
            if not GG.AirPortSemaphore then GG.AirPortSemaphore = unitID end
            Sleep(3000)
        until (GG.AirPortSemaphore == unitID)

        arrival()
        for i = 1, 2 do
            touchDownTime = math.random(8, 18)
            StartThread(ferryGoDown, math.random(1, #TablesOfPiecesGroups["Shuttle"]), touchDownTime * 1000)
        end
        ferryingGoods()
        departure()
        GG.AirPortSemaphore = nil
        end
        Sleep(5000)
    end
end

function showOne(T, bNotDelayd)
    if not T then
        return
    end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then
            c = c + 1
        end
        if c == dice then
            Show(v)
            return v
        end
    end
end


function arrival()
    resetT(TablesOfPiecesGroups["SwingCenter"], 0)
    directionToGo = math.random(0, 360)
    Turn(JourneyPoint, PlanePositionTurnAxis, math.rad(directionToGo), 0)
    Move(PlanePosition, PlanePositionMoveAxis, -150000, 0)
    showPlane()
    WMove(PlanePosition, PlanePositionMoveAxis, 0, 15000)
end
    dockedShuttleCount = 6
function turnPlaneAround()
    Signal(SIG_PLANE)
    SetSignalMask(SIG_PLANE)
    boolCircling = true
    StartThread(PlaneLights)
    boolCirclingDone = false
    dockedShuttleCount = 6
    while boolCircling == true do
         ferryGoRound = math.random(3, 5)
         ferryGoDownCount = math.random(3, 5)
         dockedShuttleCount = dockedShuttleCount + ferryGoRound - ferryGoDownCount
        if maRa() == true then
            Turn(TailStrike, 3, math.rad(15), 1)
            Turn(RightWing, 3, math.rad(15), 1)
            Turn(LeftWing, 3, math.rad(15), 1)
            WTurn(TablesOfPiecesGroups["SwingCenter"][1], PlanePositionTurnAxis, math.rad(-179), 0.11)
            WTurn(TablesOfPiecesGroups["SwingCenter"][1], PlanePositionTurnAxis, math.rad(-181), 0.11)
            playDepartureGong()
            WTurn(TablesOfPiecesGroups["SwingCenter"][1], PlanePositionTurnAxis, math.rad(-300), 0.11)
            playDepartureGong(1)
            playAircraftSounds()
           
            degShare = 50 / ferryGoRound
            for i = 1, ferryGoRound do
                timeToArrivalMS = (((ferryGoRound - i) * degShare) / (0.1 * 30)) * 1000
                StartThread(ferryGoUp, math.random(1, #TablesOfPiecesGroups["Shuttle"]), timeToArrivalMS)
                WTurn(TablesOfPiecesGroups["SwingCenter"][1], PlanePositionTurnAxis, math.rad(-300 - i * degShare), 0.1)
            end
            WTurn(TablesOfPiecesGroups["SwingCenter"][1], PlanePositionTurnAxis, math.rad(-360), 0.11)
           
            for i = 1, ferryGoDownCount do
                touchDownTime = math.random(8, 18)
                StartThread(ferryGoDown, math.random(1, #TablesOfPiecesGroups["Shuttle"]), touchDownTime * 1000)
            end
            Turn(TablesOfPiecesGroups["SwingCenter"][1], PlanePositionTurnAxis, math.rad(0), 0)
        else
            Turn(TailStrike, 3, math.rad(-15), 1)
            Turn(RightWing, 3, math.rad(-15), 1)
            Turn(LeftWing, 3, math.rad(-15), 1)
            WTurn(TablesOfPiecesGroups["SwingCenter"][2], PlanePositionTurnAxis, math.rad(179), 0.1)
            WTurn(TablesOfPiecesGroups["SwingCenter"][2], PlanePositionTurnAxis, math.rad(181), 0.1)
            playDepartureGong()
            WTurn(TablesOfPiecesGroups["SwingCenter"][2], PlanePositionTurnAxis, math.rad(300), 0.1)
            playDepartureGong(1)
            playAircraftSounds()
            degShare = 50 / ferryGoRound
            for i = 1, ferryGoRound do
                timeToArrivalMS = (((ferryGoRound - i) * degShare) / (0.1 * 30)) * 1000
                StartThread(ferryGoUp, math.random(1, #TablesOfPiecesGroups["Shuttle"]), timeToArrivalMS)
                WTurn(TablesOfPiecesGroups["SwingCenter"][2], PlanePositionTurnAxis, math.rad(310 + i * degShare), 0.1)
            end

            WTurn(TablesOfPiecesGroups["SwingCenter"][2], PlanePositionTurnAxis, math.rad(360), 0.1)
            for i = 1, ferryGoDownCount do
                touchDownTime = math.random(8, 18)
                StartThread(ferryGoDown, math.random(1, #TablesOfPiecesGroups["Shuttle"]), touchDownTime * 1000)
            end
            Turn(TablesOfPiecesGroups["SwingCenter"][2], PlanePositionTurnAxis, math.rad(0), 0)
        end
        Sleep(1)
    end
    WMove(PlanePosition, PlanePositionMoveAxis, 150000, 15000)
    WMove(PlanePosition, PlanePositionMoveAxis, 450000, 25000)
    hidePlane()
    boolCirclingDone = true
end
RightWing = piece ("RightWing")
LeftWing = piece("LeftWing")
TailStrike = piece("TailStrike")

function hidePlane()
    hideT(TablesOfPiecesGroups["MainBirdBody"])
    Hide(RightWing)
    Hide(LeftWing)
    Hide(TailStrike)
end

function showPlane()
    Show(RightWing)
    Show(LeftWing)
    Show(TailStrike)
    showOne(TablesOfPiecesGroups["MainBirdBody"])
end

function ferryGoUp(selectedFerryNr, times)
    local ferry = TablesOfPiecesGroups["Shuttle"][selectedFerryNr]
    local engine = TablesOfPiecesGroups["Engine"][selectedFerryNr]
    if ferryScramJet[selectedFerryNr] then
        Hide(ferry)
        Hide(engine)
        ScramJetGoUp(selectedFerryNr)
        return
    end   

    if not ferryFreeTable[selectedFerryNr] then
        ferryFreeTable[selectedFerryNr] = false
    end
    if ferryFreeTable[selectedFerryNr] == true then
        return
    end
    ferryFreeTable[selectedFerryNr] = true
    awayValue = math.random(15,45)*randSign()

    local ferry = TablesOfPiecesGroups["Shuttle"][selectedFerryNr]
    local engine = TablesOfPiecesGroups["Engine"][selectedFerryNr]
    reset(ferry)
    Show(ferry)
    Show(engine)
    WTurn(TablesOfPiecesGroups["Gateway"][selectedFerryNr],y_axis, math.rad(awayValue), 5)
    speed = distanceUp / (times / 1000)
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0.125)
    WMove(ferry, ferryUpAxis, distanceUp * 0.05, speed * 0.5)
    if selectedFerryNr < 6 then
        Turn(ferry, ferryTurnAxis, math.rad(180), 0.5)
    else
        Turn(ferry, ferryTurnAxis, math.rad(0), 0.5)
    end
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0.125)
    WMove(ferry, ferryUpAxis, distanceUp, speed * 1.05)

    Hide(ferry)
    Hide(engine)
    ferryFreeTable[selectedFerryNr] = false
end


ferryUpAxis = 2


function ferryGoDown(selectedFerryNr, times)
    local ferry = TablesOfPiecesGroups["Shuttle"][selectedFerryNr]
    local engine = TablesOfPiecesGroups["Engine"][selectedFerryNr]
    if ferryScramJet[selectedFerryNr] then
        Hide(ferry)
        Hide(engine)
        ScramJetGoDown(selectedFerryNr)
        return
    end   

    if not ferryFreeTable[selectedFerryNr] then
        ferryFreeTable[selectedFerryNr] = false
    end
    if ferryFreeTable[selectedFerryNr] == true then
        return
    end
    ferryFreeTable[selectedFerryNr] = true
    Sleep(selectedFerryNr * 50)

    rVal = math.random(-45, 45)
    if selectedFerryNr < 6 then
        Turn(ferry, ferryTurnAxis, math.rad(180 + rVal), 0)
    else
        Turn(ferry, ferryTurnAxis, math.rad(rVal), 0)
    end
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0)

    Move(ferry, ferryUpAxis, distanceUp, 0)
    rval = math.random(250, 750) * randSign()
    Move(ferry, 1, rval, 0)
    rval = math.random(250, 750) * randSign()
    Move(ferry, 3, rval, 0)

    Show(ferry)
    Show(engine)
    speed = distanceUp / (times / 1000)
    Turn(ferry, ferryTurnAxis, math.rad(0), 0.25)
    Move(ferry, 1, 0, speed)
    Move(ferry, 3, 0, speed)
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0.125)
    WMove(ferry, ferryUpAxis, distanceUp * 0.2, speed)
    Turn(ferry, ferryTurnAxis, math.rad(0), 0.5)
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0.125)
    WMove(ferry, ferryUpAxis, 0, speed * 0.25)
    WaitForMoves(ferry)
    Turn(engine, x_axis, math.rad(0), 0.125)
    WTurn(TablesOfPiecesGroups["Gateway"][selectedFerryNr], y_axis, math.rad(0), 5)

    ferryFreeTable[selectedFerryNr] = false
end

function ferryingGoods()
    StartThread(turnPlaneAround)
    ferryGoRound = math.random(3, 10)
    Sleep(60 * 3 * 1000)
end


local travelForwardAxis = 2
local travelUpwardAxis = 3
local rotatorAxis= 3

local travelSpeed = 60.0
local vtolSpeed  = 3.0
local vtolFactor = 2.0
local distFactor = 1.0
local slowTurnVTol = 0.125

travelAltitude = math.random(8, 12) * 3000
function ScramJetGoDown(nr)
    local Jet = TablesOfPiecesGroups["ScramJet"][nr]
    local Gear = TablesOfPiecesGroups["ScramJetGear"][nr]
    local Rotator = TablesOfPiecesGroups["ScramJetRotator"][nr]
    reset(Rotator)
    reset(Jet)
    assert(Jet)
    Hide(Jet)
    Hide(Gear)
    dist = math.random(8, 12) * 10000 * -1 * distFactor
    Move(Jet, travelForwardAxis,dist, 0)
    Move(Jet, travelUpwardAxis, travelAltitude *vtolFactor, 0)
    arrivalVector = math.random(-180, 180)
    Turn(Rotator, rotatorAxis, math.rad(arrivalVector), 0)
    Show(Jet)
    StartThread(showThruster, nr, time)
    Turn(Rotator, rotatorAxis, math.rad(0), slowTurnVTol)
    WMove(Jet, travelForwardAxis, -7000 * distFactor, 1000 * travelSpeed)
    WMove(Jet, travelForwardAxis, -6000 * distFactor, 750 * travelSpeed)
    WMove(Jet, travelForwardAxis, -5000 * distFactor, 500 * travelSpeed)
    WMove(Jet, travelForwardAxis, -3000 * distFactor, 250 * travelSpeed)
    Show(Gear)
    WMove(Jet, travelForwardAxis, 0, 125 * travelSpeed)    
    Turn(Rotator, rotatorAxis, math.rad(0), slowTurnVTol)

    WMove(Jet, travelUpwardAxis, 3000, vtolSpeed * 900)   
    WTurn(Rotator, rotatorAxis, math.rad(0), slowTurnVTol) 
    WMove(Jet, travelUpwardAxis, 0, vtolSpeed * 350)    
end

function showThruster(nr, time)
    thrusterNr = piece("ScramJet"..nr.."Thrust")
    
    Spin(thrusterNr, z_axis, math.rad(960))
    for k=1, 20 do
        Show(thrusterNr)
        startValue = math.random(0, 5)
        Move(thrusterNr, z_axis, startValue, 0)
        value = math.random(2,8)*-1
        WMove(thrusterNr, z_axis, value, value*2)
        Hide(thrusterNr)
        Sleep(25)
    end
     Hide(thrusterNr)
end


function ScramJetGoUp(nr)
    local Jet = TablesOfPiecesGroups["ScramJet"][nr]
    assert(Jet)
    local Gear = TablesOfPiecesGroups["ScramJetGear"][nr]
    local Rotator = TablesOfPiecesGroups["ScramJetRotator"][nr]
    reset(Rotator)
    reset(Jet)
    Show(Jet)
    Show(Gear)
    departureVector = math.random(-180, 180)
   
    Turn(Rotator, rotatorAxis, math.rad(departureVector), slowTurnVTol)
    WMove(Jet, travelUpwardAxis, travelAltitude* 0.5 * vtolFactor, vtolSpeed * 350)  
    WMove(Jet, travelUpwardAxis, travelAltitude * vtolFactor, vtolSpeed * 700)  
    Hide(Gear)

    WTurn(Rotator, rotatorAxis, math.rad(departureVector), slowTurnVTol)
    StartThread(showThruster, nr, 5000)
    dist = math.random(8, 15) * 10000 
    WMove(Jet, travelForwardAxis,1000*distFactor, 250 * travelSpeed)
    WMove(Jet, travelForwardAxis,2000*distFactor, 500 * travelSpeed)
    WMove(Jet, travelForwardAxis,4000*distFactor, 1000 * travelSpeed)
    WMove(Jet, travelForwardAxis,dist*distFactor, 1000 * travelSpeed)
    Hide(Jet)
    reset(Jet)  
    reset(Rotator)  
end

function PlaneLights()
    boolLightFlipFlop = false
    while boolCircling == true do
        boolLightFlipFlop = not boolLightFlipFlop
        if boolLightFlipFlop == true then
            Show(TablesOfPiecesGroups["SignalLightOn"][1])
            Show(TablesOfPiecesGroups["SignalLightOff"][2])
        else
            Show(TablesOfPiecesGroups["SignalLightOff"][1])
            Show(TablesOfPiecesGroups["SignalLightOn"][2])
        end
        Sleep(1000)
        hideT(TablesOfPiecesGroups["SignalLightOn"])
        hideT(TablesOfPiecesGroups["SignalLightOff"])
    end
end

function departure()
    boolCircling = false
    while boolCirclingDone == false do
        Sleep(10)
    end
   for i = 1, dockedShuttleCount do
        touchDownTime = math.random(8, 18)
        StartThread(ferryGoDown, math.random(1, #TablesOfPiecesGroups["Shuttle"]), touchDownTime * 1000)
    end

    minutes = math.random(3, 6) * 60 * 1000
    Sleep(minutes)
end

function script.Killed(recentDamage, _)
    return 1
end
