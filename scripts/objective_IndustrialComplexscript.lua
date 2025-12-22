include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

IndustrialComplex = piece"IndustrialComplex"
MeltingPot = piece"MeltingPot"
Lava = piece"Lava"
MeltSpin4 = piece"MeltSpin4"
Weld = piece"Weld"

Claw1 = piece("Claw1")
Claw2 = piece("Claw2")
MeltSpinnerT = {piece"MeltSpin1", piece"MeltSpin2", piece"MeltSpin3" }
TablesOfPiecesGroups = {}
TOPG = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end
groundOffset = 0
x_axis = 1
y_axis = 2
z_axis = 3
rotationAxis= 3
truckAxis = 2
horizontalAxis = 1
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    TOPG =TablesOfPiecesGroups
    isAboveGround, x,y,z, gh =  isPieceAboveGround(unitID, TruckMove)
    groundOffset = gh -y
    hideAll(unitID)
    resetAll(unitID)
    showT(TablesOfPiecesGroups["Claw"])

    StartThread(truckComingAndGoing)
    StartThread(Melting)
    StartThread(Cranes)
    StartThread(robot)
end

function turnCraneTowardsPos(index, angle, turret, maxAngle, omega,  pot, hook)
    t= 0
    factor = 1.0
    Turn(turret, rotationAxis, math.rad(angle), 0.25)
    while factor > 0.0 do 
        local angle = maxAngle * math.sin(omega * t)*factor           
        Turn(pot, x_axis, -angle, math.rad(10)) -- fast response, smooth motion
        WTurn(hook, x_axis, angle, math.rad(10)) -- fast response, smooth motion            
        t = t + 250
        factor = factor - (250/maxtime)
    end
    WTurn(hook, x_axis, 0, math.rad(90)) 
end

function Cranes()
    showT(TablesOfPiecesGroups["Crane"])
    showT(TablesOfPiecesGroups["Turret"])
    showT(TablesOfPiecesGroups["Pot"])

    -- pendulum parameters
    local ropeLength = 20.0
    local g = 9.81
    local omega = math.sqrt(g / ropeLength) -- angular frequency
    local maxAngle = math.rad(18)            -- visual amplitude
    local timeStep = 0.05                    -- seconds
    local t = 0
    maxtime = 25000
    while true do
        -- random turret movement
        local index = math.random(1,3)
        local pot = TablesOfPiecesGroups["Pot"][index]
        local hook = TablesOfPiecesGroups["Crane"][index]
        local turret = TablesOfPiecesGroups["Turret"][index]
        local val = math.random(-360,360)
        local sign = Signum(val)
        if index == 1 then
            local val = 0
        end

        Turn(turret, rotationAxis, math.rad(val), 0.25)
        maxAngle = sign * maxAngle * -1
        -- pendulum swing loop (~5 seconds)
        t= 0
        factor = 1.0
        while factor > 0.0 do 
            local angle = maxAngle * math.sin(omega * t)*factor           
            Turn(pot, x_axis, -angle, math.rad(10)) -- fast response, smooth motion
            WTurn(hook, x_axis, angle, math.rad(10)) -- fast response, smooth motion            
            t = t + 250
            factor = factor - (250/maxtime)
        end
        WTurn(hook, x_axis, 0, math.rad(90)) 
        if index == 1 then 
            while boolTruckPresent == false do
                Sleep(1000)
            end
            showT(TablesOfPiecesGroups["Metal"])
            Hide(TruckMetall)
            for i=1, #TablesOfPiecesGroups["Metal"] do
                reset(TablesOfPiecesGroups["Metal"][i]) 
                Move(TablesOfPiecesGroups["Metal"][i], y_axis, 1026, 150)
                Move(TablesOfPiecesGroups["Metal"][i], x_axis, -337,150)
                Sleep(750)
            end
            for i=1, #TablesOfPiecesGroups["Metal"] do
                WaitForMoves(TablesOfPiecesGroups["Metal"][i])
            end
            boolTruckLoaded= false
            turnCraneTowardsPos(index, 180, turret, maxAngle, omega, pot, hook)
            for i=1, #TablesOfPiecesGroups["Metal"] do
                WMove(TablesOfPiecesGroups["Metal"][i], y_axis, 0, 800)  
                Hide(TablesOfPiecesGroups["Metal"][i])         
                reset(TablesOfPiecesGroups["Metal"][i])   
                Sleep(750)
            end
        end
    end
end


function robot()
    SubPieceT = {}
        for i=1, #TablesOfPiecesGroups["Rob"] do
            Show(TablesOfPiecesGroups["Rob"][i])
            SubPieceT[i] = piece("Rob"..i.."Sub1")
            Show(SubPieceT[i])
        end
    
    aDir = randSign()
    bDir = randSign()
    while true do


        for d=1, 360, 18 do
            for i=1, #TablesOfPiecesGroups["Rob"] do
                val = math.random(-180, 180)
                dal = math.random(-180, 180)
                Turn( TablesOfPiecesGroups["Rob"][i],rotationAxis, math.rad(val), 15)
                Turn( SubPieceT[i],rotationAxis, math.rad(dal), 15)
            end
            Turn(MeltSpinnerT[1], rotationAxis, math.rad(d*aDir), 1.5)
            Turn(MeltSpinnerT[2], rotationAxis, math.rad(d*bDir), 1.5)
            WaitForTurns(MeltSpinnerT[1])
            WaitForTurns(MeltSpinnerT[2])
             for i=1, #TablesOfPiecesGroups["Rob"] do
                Turn( TablesOfPiecesGroups["Rob"][i],rotationAxis, math.rad(0), 15)
                Turn( SubPieceT[i],rotationAxis, math.rad(0), 15)
            end

            for i=1, #TablesOfPiecesGroups["Rob"] do
             WaitForTurns(TablesOfPiecesGroups["Rob"][i])
             WaitForTurns(SubPieceT[i])
            end
        end
         Turn(MeltSpinnerT[1], rotationAxis, math.rad(0), 0)
        Turn(MeltSpinnerT[2], rotationAxis, math.rad(0), 0)
      
       
        Sleep(3000)
    end
end

SIG_WELD = 1

function flickerWeld()
    Signal(SIG_WELD)
    SetSignalMask(SIG_WELD)
    Show(Weld)
    showT(TablesOfPiecesGroups["ArcWeld"])
    weldPieces = {Weld, TablesOfPiecesGroups["ArcWeld"][1], TablesOfPiecesGroups["ArcWeld"][2]}
    while true do
        for k, p in pairs(weldPieces) do           
            rot= math.random(0,360)
            Turn(p, rotationAxis, math.rad(rot), 0)
            Spin(p, rotationAxis,math.rad(42*randSign()),0)
            val = 180 * math.random(0,1)
            Turn(p, horizontalAxis, math.rad(val), 0)
        end
        Sleep(333)
    end
end

function Melting()
    Show(IndustrialComplex)
    Show(MeltingPot)
    Show(Lava)
    Show(MeltSpin4)
    showT(MeltSpinnerT)
    lavaStream = TablesOfPiecesGroups["Lavastream"]
    Spin(MeltSpinnerT[3], horizontalAxis , math.rad(-42))
    trainValue = 0
    while true do
        reset(Lava)
        WTurn(MeltingPot, rotationAxis, math.rad(-60), 5)
        StartThread(flickerWeld)
        reset(MeltingPot)
        Sleep(300)
        showT(lavaStream)
        Spin(lavaStream[2], rotationAxis, math.rad(42)*randSign(),0)
        Spin(lavaStream[1], rotationAxis, math.rad(42)*randSign(),0)
        WMove(Lava, rotationAxis, -5000, 500)
        hideT(lavaStream)
        Sleep(5000)
        Signal(SIG_WELD)
        Sleep(1000)
        Hide(Weld)
        hideT(TOPG["ArcWeld"])
        trainValue = trainValue + 5
        Turn(MeltSpin4, rotationAxis, trainValue, 0.125)
    end
end

boolTruckPresent = false
boolTruckLoaded = false
Truck = piece("Truck")
TruckMove = piece("TruckMove")
TruckRotate1 = piece("TruckRotate1")
TruckRotate2 = piece("TruckRotate2")
TruckRotate3 = piece("TruckRotate3")
TruckMetall = piece("TruckMetall")



--TODO: This is wrong pica and you know it- shame
rotationAxis= 3
truckAxis = 2
horizontalAxis = 1

rotSign = -1
truckDepartingSequence = {
    {WTurn, TruckRotate2,truckAxis, math.rad(60 *rotSign), 0.3 },
    {Move,  TruckMove,truckAxis, 2000, 20 },
    --{Move,  TruckMove,rotationAxis, groundOffset, 200 },
    {WTurn, TruckRotate1,truckAxis, math.rad(-60*rotSign), 0.3 },   
    {Turn,  Truck,rotationAxis, math.rad(-90), 10},
    {WTurn, TruckRotate3,rotationAxis, math.rad(180), 0.1 },  
    {Hide, Truck}
}

truckArrivingSequence = 
{
    --Preparation
    --{Move, TruckMove, rotationAxis, groundOffset, 0 },
    {Turn,  TruckRotate2,truckAxis, math.rad(60*rotSign), 0 },
    {Turn,  TruckRotate1,truckAxis, math.rad(-60*rotSign),0 },
    {Turn,  TruckRotate3,rotationAxis, math.rad(180),0 },
    {Move,  TruckMove,truckAxis, 2000, 0 },
    {Turn,  Truck,rotationAxis, math.rad(90), 0},   
    {WTurn, TruckRotate3,rotationAxis, math.rad(0), 0.1 },

    {Turn,  Truck,rotationAxis, math.rad(180), 0},
    {Move,  TruckMove,rotationAxis, 0, 0.5 },
    {WMove, TruckMove,truckAxis, 0, 0.5 },
    {WTurn, Truck,rotationAxis, math.rad(0), 10},
    {WTurn, TruckRotate2,truckAxis, math.rad(0), 0.1 }, 
    {WTurn, TruckRotate1,truckAxis, math.rad(0), 0.1 }
}


function truckComingAndGoing()
    showT(TablesOfPiecesGroups["TruckRotate"])
    Show(TruckMove)
    offset = 0


    while true do
        if boolTruckPresent then
            if boolTruckLoaded then
                --do nothing
            else --drive off
                boolTruckPresent = false
                Hide(TruckMetall)
                Show(Truck)
                animateSequence(truckDepartingSequence)   
                Hide(Truck)             
            end

        else --new Truck arrives
            Show(TruckMetall)
            Show(Truck)    
            animateSequence(truckArrivingSequence)
            boolTruckPresent = true
            boolTruckLoaded = true
        end
        Sleep(5000)
    end
end


function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
