include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
Airport = piece"Airport"
statusTable = {}


function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    setup()
    StartThread(comingAndGoing)
end

function setup()
    hideAll(unitID)
    Show(Airport)
    showT(TablesOfPiecesGroups["Gateway"])
    PlanePosition = TablesOfPiecesGroups["SwingCenter"][2]
    StartThread(blink)
    for i=1, #TablesOfPiecesGroups["Shuttle"] do
        if TablesOfPiecesGroups["Shuttle"][i] then
        if maRa() == true then
            statusTable[TablesOfPiecesGroups["Shuttle"][i]] ="landed"
            Show(TablesOfPiecesGroups["Shuttle"][i])
            Show(TablesOfPiecesGroups["Engine"][i])
        else
            statusTable[TablesOfPiecesGroups["Shuttle"][i]] ="docked"
        end
        end
    end

    for i=1, #TablesOfPiecesGroups["AirCar"] do
        StartThread(vtolLoop, TablesOfPiecesGroups["AirCar"][i], math.random(5,10)*15*1000, math.random(10,30)*15*10000)
    end
end

function cturnT(t, axis, degs, speed, boolInstantUpdate, boolWait)
    if boolInstantUpdate then
        for i = 1, #t, 1 do 
            if t[i] then Turn(t[i], axis, math.rad(degs), 0, true) end
        end
        return
    end

    if not speed or speed == 0 then
        for i = 1, #t, 1 do 
            if t[i] then Turn(t[i], axis, math.rad(degs), 0) end
        end
    else
        for i = 1, #t, 1 do Turn(t[i], axis, math.rad(degs), speed) end
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
    upaxis=1
    while true do
         upaxis= (upaxis  % 3 + 1)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 180,0)
        Sleep(2500)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 0,0)
        Sleep(2500)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 180,0)
        Sleep(2500)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 0,0)
        Sleep(5000)
        cturnT(TablesOfPiecesGroups["SwitchLight"], upaxis, 180,0)
        Sleep(5000)
    end
end

function comingAndGoing()
    while true do
        Sleep(10000)
        arrival()
        ferryingGoods()
        departure()
    end
end

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
            Show(v) 
            return v
        end
    end
end
JourneyPoint = piece"JourneyPoint"
PlanePositionTurnAxis = 3
PlanePositionMoveAxis= 3
directionToGo = math.random(0,360)
function arrival()

    directionToGo = math.random(0,360)
    Turn(JourneyPoint,PlanePositionTurnAxis, math.rad(directionToGo ), 0)
    Move(PlanePosition, PlanePositionMoveAxis, -150000,0)
    showOne(TablesOfPiecesGroups["MainBirdBody"])
    WMove(PlanePosition, PlanePositionMoveAxis, 0, 15000)
end
SIG_PLANE = 1
boolCircling = false
boolCirclingDone= false
function turnPlaneAround()
    Signal(SIG_PLANE)
    SetSignalMask(SIG_PLANE)
    boolCircling = true
    boolCirclingDone= false
    while boolCircling == true do
        resetT(TablesOfPiecesGroups["SwingCenter"],0)
        if maRa() == true then
            WTurn(TablesOfPiecesGroups["SwingCenter"][1],PlanePositionTurnAxis, math.rad(-179), 0.11)
            WTurn(TablesOfPiecesGroups["SwingCenter"][1],PlanePositionTurnAxis, math.rad(-181), 0.11)
            WTurn(TablesOfPiecesGroups["SwingCenter"][1],PlanePositionTurnAxis, math.rad(-360), 0.11)
        else
            WTurn(TablesOfPiecesGroups["SwingCenter"][2],PlanePositionTurnAxis, math.rad(179), 0.1)
            WTurn(TablesOfPiecesGroups["SwingCenter"][2],PlanePositionTurnAxis, math.rad(181), 0.1)
            WTurn(TablesOfPiecesGroups["SwingCenter"][2],PlanePositionTurnAxis, math.rad(360), 0.1)
        end
        Sleep(1)

    end
    boolCirclingDone= true
end

function ferryingGoods()
    StartThread(turnPlaneAround)
    ferryGoRound = math.random(3,10)
    for i=1, ferryGoRound do
        Sleep(15000)
    end
end

function departure()
    boolCircling = false
    while boolCirclingDone == false do Sleep(10) end
    WMove(PlanePosition, PlanePositionMoveAxis, 150000,15000)
    hideT(TablesOfPiecesGroups["MainBirdBody"])
end

function script.Killed(recentDamage, _)
    return 1
end


