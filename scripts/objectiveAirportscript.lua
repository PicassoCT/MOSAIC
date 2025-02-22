include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
Airport = piece "Airport"
statusTable = {}
myDefID = Spring.GetUnitDefID(unitID)
JourneyPoint = piece "JourneyPoint"
PlanePositionTurnAxis = 3
PlanePositionMoveAxis = 2
directionToGo = math.random(0, 360)
SIG_PLANE = 1
boolCircling = false
boolCirclingDone = false
distanceUp = 80000
ferryFreeTable = {}
ferryTurnAxis = 3
gaiaTeamID = Spring.GetGaiaTeamID()
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    setup()
    StartThread(comingAndGoing)
    StartThread(advertisingBlimp)
end

function playDepartureGong(offset)
    hours, minutes, seconds, percent = getDayTime()     
    if percent % 0.25 < 0.1 and not isNight() then
        maphash = getMapHash(5) + 1
        name = "sounds/objective/airport_departure"..maphash..".ogg"
        StartThread(PlaySoundByUnitDefID, myDefID, name , 0.125, 500, 2)
    end
end

function playAircraftSounds()
    if not isNight() then
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/objective/airport_arrivaldeparture.ogg", 1.0, 120000, 1)
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
        if TablesOfPiecesGroups["Shuttle"][i] then
            if maRa() == true then
                statusTable[TablesOfPiecesGroups["Shuttle"][i]] = "landed"
                Show(TablesOfPiecesGroups["Shuttle"][i])
                Show(TablesOfPiecesGroups["Engine"][i])
            else
                statusTable[TablesOfPiecesGroups["Shuttle"][i]] = "docked"
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
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 180, 0)
        Sleep(2500)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 0, 0)
        Sleep(5000)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 180, 0)
        Sleep(5000)
    end
end


function comingAndGoing()
    while true do
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
        showT(TablesOfPiecesGroups["Transit"], 1, math.min(math.max(2,dockedShuttleCount),#TablesOfPiecesGroups["Transit"]))

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
    hideT(TablesOfPiecesGroups["Transit"])
    Hide(RightWing)
    Hide(LeftWing)
    Hide(TailStrike)
end

function showPlane()
    Show(RightWing)
    Show(LeftWing)
    Show(TailStrike)
    showOne(TablesOfPiecesGroups["MainBirdBody"])
    hideT(TablesOfPiecesGroups["Transit"])
end

function ferryGoUp(selectedFerryNr, times)
    if not ferryFreeTable[selectedFerryNr] then
        ferryFreeTable[selectedFerryNr] = false
    end
    if ferryFreeTable[selectedFerryNr] == true then
        return
    end
    ferryFreeTable[selectedFerryNr] = true

    local ferry = TablesOfPiecesGroups["Shuttle"][selectedFerryNr]
    local engine = TablesOfPiecesGroups["Engine"][selectedFerryNr]
    reset(ferry)
    Show(ferry)
    Show(engine)
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

ferryUpAxis = 3
function ferryGoDown(selectedFerryNr, times)
    if not ferryFreeTable[selectedFerryNr] then
        ferryFreeTable[selectedFerryNr] = false
    end
    if ferryFreeTable[selectedFerryNr] == true then
        return
    end
    ferryFreeTable[selectedFerryNr] = true
    Sleep(selectedFerryNr * 50)
    local ferry = TablesOfPiecesGroups["Shuttle"][selectedFerryNr]
    local engine = TablesOfPiecesGroups["Engine"][selectedFerryNr]
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
    Move(ferry, 2, rval, 0)

    Show(ferry)
    Show(engine)
    speed = distanceUp / (times / 1000)
    Turn(ferry, ferryTurnAxis, math.rad(0), 0.25)
    Move(ferry, 1, 0, speed)
    Move(ferry, 2, 0, speed)
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0.125)
    WMove(ferry, ferryUpAxis, distanceUp * 0.2, speed)
    Turn(ferry, ferryTurnAxis, math.rad(0), 0.5)
    val = math.random(-5, 5)
    Turn(engine, x_axis, math.rad(val), 0.125)
    WMove(ferry, ferryUpAxis, 0, speed * 0.25)
    WaitForMoves(ferry)
    Turn(engine, x_axis, math.rad(0), 0.125)
    ferryFreeTable[selectedFerryNr] = false
end

function ferryingGoods()
    StartThread(turnPlaneAround)
    ferryGoRound = math.random(3, 10)
    Sleep(60 * 3 * 1000)
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
    hideT(TablesOfPiecesGroups["Transit"])

    minutes = math.random(3, 6) * 60 * 1000
    Sleep(minutes)
end

function script.Killed(recentDamage, _)
    return 1
end
