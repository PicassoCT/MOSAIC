include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
center=piece"center"
tether = piece "Umbilical"
blimp = piece "Blimp"

function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(blinkLights)
    StartThread(turnWindSlow)
      heightOfsset= getObjectiveAboveGroundOffset(unitID)
    Move(center,y_axis, heightOfsset + 30, 0)
    for i=1,#TablesOfPiecesGroups["Plane"] do
        StartThread(vtolStartLanding,TablesOfPiecesGroups["Plane"][i], TablesOfPiecesGroups["Plane"..i.."Spin"][1], TablesOfPiecesGroups["Plane"..i.."Spin"][2] )
    end
end

function showHidePlane(boolShow, plane, rotor1, rotor2 )
        if boolShow == true then
            Show(plane)
            Show(rotor1)
            Show(rotor2)
        else
            Hide(plane)
            Hide(rotor1)
            Hide(rotor2)
        end
    end

function movePlaneRandomLocationInTime(plane, rotor1, rotor2, time)
    rx,ry, rz = randSign()* math.random(3000,7000), 19000, randSign() * math.random(3000,7000)
    mSyncIn(plane, rx,ry,rz, time)
end


function vtolStartLanding(plane, rotor1, rotor2)
    boolInAir = maRa()
    if boolInAir == true then 
        showHidePlane(false, plane, rotor1, rotor2)
    end
    lastValue = 0

    while true do
        if boolInAir == true then
            randSleep= math.random(1,12)
            Sleep(randSleep*1000)
            movePlaneRandomLocationInTime(plane, rotor1, rotor2, 100)
            WaitForMoves(plane)
            Spin(rotor1, y_axis, math.rad(666),0)
            Spin(rotor2, y_axis, math.rad(666),0)
            showHidePlane(true, plane, rotor1, rotor2)
            lastValue =math.random(-180,180)
            StartThread(turnInTime, plane, y_axis, math.random(0,180)*randSign(), 7000, 0,lastValue,0 )
            syncMoveInTime(plane, 0, 0, 0, 7000)
             Sleep(7000)
            WaitForMoves(plane)
            StopSpin(rotor1, y_axis, 0.1)
            StopSpin(rotor2, y_axis, 0.1)
         
            boolInAir = false
             randSleep= math.random(20,40)
            Sleep(randSleep*1000)
        else
            Spin(rotor1, y_axis, math.rad(666),0.1)
            Spin(rotor2, y_axis, math.rad(666),0.1)
            Sleep(3000)
            movePlaneRandomLocationInTime(plane, rotor1, rotor2, 5000)
            Sleep(200)
            lastValue =math.random(-180,180)
            Turn(plane, y_axis, math.rad(lastValue),0.5)
            WaitForMoves(plane)
            rx,rz = math.random(1,Game.mapSizeX)*randSign(), math.random(1,Game.mapSizeZ)*randSign()
            syncMoveInTime(plane, rx, 19000, rz, 10000)
            WaitForMoves(plane)
            showHidePlane(false, plane, rotor1, rotor2)
            boolInAir = true
            randSleep= math.random(1,12)
            Sleep(randSleep*1000)
        end
    end
end

function turnWindSlow()
    --StartThread(emitSulfur)
    while true do
        dx, dy, dz = Spring.GetWind()
        headRad = math.atan2(dx, dz)
        Turn(tether, y_axis, headRad + math.pi, 0.01)
        Turn(blimp, y_axis, -(headRad + math.pi), 0.01)
        Turn(blimp, x_axis, math.rad(-2 * randSign()), 0.01)
        Turn(blimp, z_axis, math.rad(-2 * randSign()), 0.01)
        WaitForTurns(tether, blimp)
        Sleep(100)
    end
end

function emitSulfur()
    while true do
        spawnCegAtPiece(unitID, blimp, "sulfurinjection", 0, 1, 0, 0, true)
        Sleep(3000)
    end
end

function blinkLights()
    n = 1
    while true do
        n = n + 1 % 2
        for i = 1, #TablesOfPiecesGroups["BlinkyLight"], 1 do
            if i % 2 == 0 then
                Turn(TablesOfPiecesGroups["BlinkyLight"][i], z_axis,
                     math.rad(180 * n), 0)
            else
                Turn(TablesOfPiecesGroups["BlinkyLight"][i], z_axis,
                     math.rad(180 * (n + 1)), 0)
            end
        end
        Sleep(2500)
    end
end

function script.Killed(recentDamage, _) return 1 end

