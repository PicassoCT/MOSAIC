include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
MeltingPot = piece"MeltingPot"
Lava = piece"Lava"
MeltSpin4 = piece"MeltSpin4"
Weld = piece"Weld"
ArcWeld = piece"ArcWeld"
MeltSpinnerT = {piece"MeltSpin3", piece"MeltSpin2", piece"MeltSpin1"}
TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    resetAll(unitID)
    StartThread(Melting)
    StartThread(robot)
end

function robot()
    SubPieceT = {}
        for i=1, #TablesOfPiecesGroups["Rob"] do
            Show( #TablesOfPiecesGroups["Rob"][i])
            SubPieceT[i] = piece("Rob"..i.."Sub1")
            Show(SubPieceT[i])
        end
    while true do
        aDir= randSign()
        bDir = randSign()
        for i=1, #TablesOfPiecesGroups["Rob"] do
            val = math.random(-180, 180)
            dal = math.random(-180, 180)
            Turn( TablesOfPiecesGroups["Rob"][i],y_axis, math.rad(val), 15)
            Turn( SubPieceT[i],y_axis, math.rad(dal), 15)
        end
        for d=1, 360, 36 do
            Turn(MeltSpinnerT[1], y_axis, math.rad(42*aDir), 36)
            Turn(MeltSpinnerT[2], y_axis, math.rad(42*bDir), 36)
            WaitForTurns(MeltSpinnerT[1])
            WaitForTurns(MeltSpinnerT[2])
        end
      
        for i=1, #TablesOfPiecesGroups["Rob"] do
            Turn( TablesOfPiecesGroups["Rob"][i],y_axis, math.rad(0), 15)
            Turn( SubPieceT[i],y_axis, math.rad(0), 15)
        end
        for i=1, #TablesOfPiecesGroups["Rob"] do
            WaitForTurns(TablesOfPiecesGroups["Rob"][i])
            WaitForTurns(SubPieceT[i])
        end
        Sleep(3000)
    end
end

SIG_WELD = 1
function flickerWeld()
    Signal(SIG_WELD)
    SetSignalMask(SIG_WELD)
    Show(Weld)
    weldPieces = {Weld, ArcWeld}
    while true do
        for k, p in pairs(weldPieces) do           
            rot= math.random(0,360)
            Turn(p, y_axis, math.rad(rot), 0)
            Spin(p, y_axis,math.rad(42*randSign()),0)
            val = 180 * math.random(0,1)
            Turn(p, x_axis, math.rad(val), 0)
        end
        Sleep(333)
    end
end

function Melting()
    Show(MeltingPot)
    Show(Lava)
    Show(MeltSpin4)
    showT(MeltSpinnerT)
 
    Spin(MeltSpinnerT[3], x_axis, math.rad(42))
    trainValue = 0
    while true do
        reset(Lava)
        WTurn(MeltingPot, y_axis, math.rad(60), 10)
        StartThread(flickerWeld)
        reset(MeltingPot)
        Sleep(300)
        WMove(Lava, y_axis, -500, 10)
        Sleep(5000)
        Signal(SIG_WELD)
        Sleep(1000)
        Hide(Weld)
        Hide(ArcWeld)
        trainValue = trainValue + 5
        Turn(MeltSpin4, y_axis, trainValue, 0.5)
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
