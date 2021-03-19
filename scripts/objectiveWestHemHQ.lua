include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitBlocking(unitID,false)
    resetAll(unitID)
    val = math.random(-360, 360)
    rSign = randSign()*math.random(1,9)
    for i=1,#TablesOfPiecesGroups.HyperLoop do
        Turn(TablesOfPiecesGroups.HyperLoop[i],y_axis, math.rad(rSign),0)
    end
    StartThread(sensorTurn, TablesOfPiecesGroups["HyperLoop"][1], 1, 5)
    StartThread(sensorTurn, TablesOfPiecesGroups["HyperLoop"][6], 6,
                #TablesOfPiecesGroups["HyperLoop"])

    StartThread(forInterval, 1, 6)
    StartThread(forInterval, 7, #TablesOfPiecesGroups["HyperLoop"])
    StartThread(delayShowAllElements)
    StartThread(blinkLights)
    for i=1,#TablesOfPiecesGroups["Plane"] do
        StartThread(vtolStartLanding,TablesOfPiecesGroups["Plane"][i], TablesOfPiecesGroups["Plane"..i.."Sub"][1], TablesOfPiecesGroups["Plane"..i.."Sub"][2] )
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
        rx,ry, rz = randSign()* math.random(3000,7000), 9000, randSign()* math.random(3000,7000)
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
            StartThread(turnInTime, plane, y_axis,7000, 0,lastValue,0 )
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
            showHidePlane(false, plane, rotor1, rotor2)
            boolInAir = true
            randSleep= math.random(1,12)
            Sleep(randSleep*1000)
        end
    end
end

function blinkLights()
    for i=1, #TablesOfPiecesGroups["LightOn"] do
        StartThread(howToBlinky, TablesOfPiecesGroups["LightOn"][i],TablesOfPiecesGroups["LightOff"][i] )
    end
end

function howToBlinky(showOn, showOff)
    while true do
            Show(showOn)
            Hide(showOff)
            Sleeptime = math.random(500,2000)
            Sleep(Sleeptime)
            Show(showOff)
            Hide(showOn)
            Sleeptime = math.random(500,2000)
            Sleep(Sleeptime)
    end
end

function delayShowAllElements()

    hideT(TablesOfPiecesGroups["HyperLoop"])
    Sleep(10000)


    nrsShown={}
    for nr, piecenr in pairs(TablesOfPiecesGroups["HyperLoop"]) do
        x, y, z = Spring.GetUnitPiecePosDir(unitID, piecenr)
        nrsShown[nr] = false
        if not (x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ) then
            Show(piecenr)
            nrsShown[nr] = true
        end
    end

    for i=1, #nrsShown do
        if nrsShown[i]  ~= nil and nrsShown[i + 1] ~= nil  then
            if nrsShown[i] == true and nrsShown[i + 1] == false then
                Show(TablesOfPiecesGroups["HyperLoop"][i+1])
            end
        end 
    end
end

function script.Killed(recentDamage, _) return 1 end

function sensorTurn(tower, starts, ends)
    for k = starts, ends do
        radStart = math.random(2, 359)
        for i = radStart, 360, 10 do
            WTurn(tower, y_axis, math.rad(i), 0)
            x, y, z = Spring.GetUnitPiecePosDir(unitID,
                                                TablesOfPiecesGroups["HyperLoop"][k])

            if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
                return
            end
        end

        for i = 1, radStart, 10 do
            WTurn(tower, y_axis, math.rad(i), 0)
            x, y, z = Spring.GetUnitPiecePosDir(unitID,
                                                TablesOfPiecesGroups["HyperLoop"][k])

            if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
                return
            end
        end
    end
end

function forInterval(start, stop)

    elementsToShow = {}
    for i = start, stop do
        if i ~= stop then
            nextElement = TablesOfPiecesGroups["HyperLoop"][i + 1]
            thisElement = TablesOfPiecesGroups["HyperLoop"][i]
            boolIsAboveGround = false
            val = 0
            counter = 0
            while boolIsAboveGround == false and counter < 10 do
                x, y, z = Spring.GetUnitPiecePosDir(unitID, nextElement)
                gh = Spring.GetGroundHeight(x, z)
                counter = counter + 1

                if y > gh + 50 then
                    val = val - 1
                elseif y < gh + 50 then
                    val = val + 1
                else
                    break
                end
                if (x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ) ==
                    false then
                    elementsToShow[#elementsToShow + 1] = thisElement
                end
                WTurn(thisElement, x_axis, math.rad(val), 0)
                Sleep(1)
            end
        end
    end

end
