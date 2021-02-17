include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

local spiralCenter = piece "spiralCenter"
local fireSpiral1 = piece "fireSpiral1"
local fireSpiral2 = piece "fireSpiral2"
local fireSpiral3 = piece "fireSpiral3"
local shockwaveemit = piece "shockwaveEmit"
local shockwavecenter = piece "shockwavecenter"
local fireFx1 = piece "fireFx1"
local fireFx2 = piece "fireFx2"
local fireFx3 = piece "fireFx3"
local exploEmit = piece "exploEmit"
local centcolumnFxEmit1 = piece "centcolumnFxEmit1"
local centcolumnFxEmit2 = piece "centcolumnFxEmit2"
local centcolumnFxEmit3 = piece "centcolumnFxEmit3"

--local ffrotator=piece"ffrotator"
--local centerFireFx = piece "centerFireFx"
local center = piece "center"
local groupcenter = piece "groupcenter"
local ringRotator = piece "ringRotator"
local ringEmit1 = piece "ringEmit1"
local ringEmit2 = piece "ringEmit2"
local ringEmit3 = piece "ringEmit3"
local ringEmit4 = piece "ringEmit4"

ringCenter = piece "ringCenter"
suckINemit2 = piece "suckINemit2"
gdEmit = piece "gdEmit"
SIG_DIRT = 2
explosionTotalTime = 9000

function emitColumn()
    local lEmitSFX = EmitSfx
    local lookAtTheTime = 0
    local lexplosionTotalTime = explosionTotalTime

    while lookAtTheTime < explosionTotalTime do
        if lookAtTheTime > 0 then lEmitSFX(exploEmit, 1034) end
        if lookAtTheTime > lexplosionTotalTime * 0.25 then lEmitSFX(centcolumnFxEmit1, 1034) end
        if lookAtTheTime > lexplosionTotalTime * 0.5 then lEmitSFX(centcolumnFxEmit2, 1034) end
        if lookAtTheTime > lexplosionTotalTime * 0.75 then lEmitSFX(centcolumnFxEmit3, 1034) end

        --lEmitSFX(centcolumnFxEmit1,1027)
        if lookAtTheTime < explosionTotalTime - 1500 then lEmitSFX(exploEmit, 1028) end
        --lEmitSFX(centcolumnFxEmit3,1027)
        Sleep(350)
        lookAtTheTime = lookAtTheTime + 350
    end

    lookAtTheTime = 0
    while lookAtTheTime < explosionTotalTime or boolSmokeOnTheSlaughter == true do
        if lookAtTheTime > 0 and lookAtTheTime < lexplosionTotalTime * 0.25 then
            if math.random(0, 1) then lEmitSFX(exploEmit, 1030) else lEmitSFX(exploEmit, 1035) end
            lEmitSFX(centcolumnFxEmit1, 1034)
            lEmitSFX(centcolumnFxEmit2, 1034)
            lEmitSFX(centcolumnFxEmit3, 1034)
        elseif lookAtTheTime > lexplosionTotalTime * 0.25 and lookAtTheTime < lexplosionTotalTime * 0.5 then
            if math.random(0, 1) then lEmitSFX(exploEmit, 1030) else lEmitSFX(exploEmit, 1035) end
            if math.random(0, 1) then lEmitSFX(centcolumnFxEmit1, 1035) else lEmitSFX(centcolumnFxEmit1, 1030) end
            lEmitSFX(centcolumnFxEmit2, 1034)
            lEmitSFX(centcolumnFxEmit3, 1034)
        elseif lookAtTheTime > lexplosionTotalTime * 0.5 and lookAtTheTime < lexplosionTotalTime * 0.75 then
            if math.random(0, 1) then lEmitSFX(exploEmit, 1030) else lEmitSFX(exploEmit, 1035) end
            if math.random(0, 1) then lEmitSFX(centcolumnFxEmit1, 1035) else lEmitSFX(centcolumnFxEmit1, 1030) end
            if math.random(0, 1) then lEmitSFX(centcolumnFxEmit2, 1035) else lEmitSFX(centcolumnFxEmit2, 1030) end
            lEmitSFX(centcolumnFxEmit3, 1034)
        else
            if math.random(0, 1) then lEmitSFX(exploEmit, 1030) else lEmitSFX(exploEmit, 1035) end
            if math.random(0, 1) then lEmitSFX(centcolumnFxEmit1, 1035) else lEmitSFX(centcolumnFxEmit1, 1030) end
            if math.random(0, 1) then lEmitSFX(centcolumnFxEmit2, 1035) else lEmitSFX(centcolumnFxEmit2, 1030) end
            if math.random(0, 1) then lEmitSFX(centcolumnFxEmit3, 1035) else lEmitSFX(centcolumnFxEmit3, 1030) end
        end

        lEmitSFX(centcolumnFxEmit1, 1034)

        Sleep(350)
        lookAtTheTime = lookAtTheTime + 350
    end
end

function dirtSuckedInwards()
    SetSignalMask(SIG_DIRT)
    local splEmitSfx = EmitSfx
    while (true) do
        randAdditive = math.random(0, 120)
        for i = 1, 6, 1 do
            randDegree = math.random(-15, 15)
            finalDegree = (randDegree + (i * 60)) + 120
            randElements = math.random(3, 11)
            for o = 1, randElements, 1 do
                Turn(shockwavecenter, y_axis, math.rad(finalDegree + (3 * o)), 0)

                splEmitSfx(shockwaveemit, 1028)
            end
            randSleep = math.random(100, 250)
            Sleep(randSleep)
        end
        grandSleep = math.random(600, 900)
        Sleep(grandSleep)
    end
end

function shockwave()
    x, y, z = Spring.GetUnitPosition(unitID)
    Spring.SpawnCEG("jsunwave", x, y + 10, z, 0, 1, 0, 60)
    local splEmitSfx = EmitSfx
    for i = 1, 12, 1 do
        splEmitSfx(spiralCenter, 1025)
        splEmitSfx(spiralCenter, 1025)
        splEmitSfx(spiralCenter, 1025)
        splEmitSfx(spiralCenter, 1025)
        Time = i * 10
        Sleep(Time)
    end
end

function alternativeFireLight()
    --we modell the light with a x� and then at the peak decrease with a
    --we have 150 ns to explosion - the while loop resting every 10 ns
    theTime = -150
    intensity = 150
    deci = 1
    local splEmitSfx = EmitSfx

    splEmitSfx(spiralCenter, 1024)
    while theTime < 7500 do
        if theTime < 0 then
            for i = 1, math.abs(-1 * (theTime ^ 2) + 22500) / 1000, 1 do
                if deci == 1 and boolLightMyFire == true then
                    deci = 0
                    splEmitSfx(spiralCenter, 1024)
                else
                    deci = 1
                    splEmitSfx(spiralCenter, 1033)
                end
            end

        else
            for i = 1, math.abs(22 - (math.log(theTime + 1) * 2.4)), 1 do
                if deci == 1 then
                    deci = 0
                    splEmitSfx(spiralCenter, 1024)
                else
                    deci = 1
                    splEmitSfx(spiralCenter, 1033)
                end
            end
        end

        Sleep(10)
        theTime = theTime + 10
    end

    while boolSmokeOnTheSlaughter == true do

        splEmitSfx(spiralCenter, 1033)
        Sleep(15)
    end
end

function downCloud()
    xor = 0

    local spGetUnitPiecePosition = Spring.GetUnitPiecePosition
    ox, oy, oz = spGetUnitPiecePosition(unitID, fireFx1)
    ax, ay, az = spGetUnitPiecePosition(unitID, fireFx2)
    bx, by, bz = spGetUnitPiecePosition(unitID, fireFx2)
    while xor < explosionTotalTime do
        EmitSfx(fireFx1, 1034)
        x, y, z = spGetUnitPiecePosition(unitID, fireFx1)
        y = math.min(y + math.random(-10, 10), oy)
        MovePieceToPos(fireFx1, x + math.random(-10, 10), y, z + math.random(-10, 10), 22)
        EmitSfx(fireFx2, 1034)
        EmitSfx(fireFx3, 1034)
        d = math.ceil(math.random(200, 400))
        Sleep(d)
        xor = xor + d
    end

    MovePieceToPos(fireFx1, ox, oy, oz, 0)
    WaitForMove(fireFx1, y_axis)

    while boolSmokeOnTheSlaughter == true do
        rot = math.random(0, 360)
        Turn(spiralCenter, y_axis, math.rad(rot), 0)

        x = math.random(-55, 55)
        z = math.random(-55, 55)
        Move(fireFx3, x_axis, x, 0)
        Move(fireFx3, z_axis, z, 0)



        MovePieceToPos(fireFx1, ox + math.random(-50, 50), oy + math.random(0, 10), oz + math.random(-50, 50), 0)
        if math.random(0, 1) == 1 then EmitSfx(fireFx1, 1035) else EmitSfx(fireFx1, 1035) end
        --
        MovePieceToPos(fireFx3, ax + math.random(-35, 35), ay + math.random(0, 10), oz + math.random(-35, 35), 0)

        if math.random(0, 1) == 1 then EmitSfx(fireFx3, 1035) else EmitSfx(fireFx3, 1027) end
        --
        MovePieceToPos(fireFx2, bx + math.random(-85, 85), by + math.random(0, 20), bz + math.random(-85, 85), 0)
        if math.random(0, 1) == 1 then EmitSfx(fireFx2, 1030) else EmitSfx(fireFx2, 1035) end
        d = math.ceil(math.random(5, 15))
        Sleep(d)
    end
end


function emitDustOutwards()
    done = 0
    local splEmitSfx = EmitSfx
    while (true) do
        randy = math.random(-22, 22)
        for i = 1, 360, 1 do

            x = math.random(0, 4)
            if x == 1 then
                target = randy + (i % 22)
                Move(fireEmitor, x_axis, target, 0)
                Turn(fireCenter, y_axis, math.rad(i), 0)
                splEmitSfx(fireEmitor, 1034)
            end
        end
        if done % 190 == 0 then
            for i = 1, table.getn(Astrotatoren), 1 do
                splEmitSfx(Astrotatoren[i], 1035)
            end
            done = 0
        end
        done = done + 5
        Sleep(125)
    end
end

function haveSoundArround()

    Spring.PlaySoundFile("sounds/weapons/godrod/nuke.ogg", 1)
    Sleep(3500)
    Spring.PlaySoundFile("sounds/weapons/godrod/nukular.wav", 1)
end

function shroom()

    for i = 1, 15 do
        EmitSfx(center, 1036)
        Sleep(350)
    end
end

function script.Killed(recentDamage, maxHealth)
    return 1
end

function spinRingRandom()
    x = math.random(-45, 45)
    Turn(ringRotator, x_axis, math.rad(x), 0)
end

boolSmokeOnTheSlaughter = true

function mushRoom()

    local ltime = explosionTotalTime
    local spPieceIsMoving = Spring.UnitScript.IsInMove
    local spEmitSfx = EmitSfx
    local lspinRingRandom = spinRingRandom
    Move(ringRotator, z_axis, 15, 0)
    Move(ringCenter, y_axis, 0, 0)
    Move(exploEmit, y_axis, 0, 0)

    --orangeclouds 1034
    --greycloud 1031
    --darkcloudnuke 1030


    Spin(ringCenter, y_axis, math.rad(690), 0)
    Move(ringCenter, y_axis, 35, 5.2)

    Move(ringRotator, z_axis, 20, 2.6)
    --Starting Low All Orange
    while (ltime > explosionTotalTime - 5000) do
        spEmitSfx(ringCenter, 1034)
        spEmitSfx(ringEmit1, 1034)
        spEmitSfx(ringEmit2, 1034)
        spEmitSfx(ringEmit3, 1034)
        spEmitSfx(ringEmit4, 1034)
        lspinRingRandom()
        spEmitSfx(exploEmit, 1027)
        spEmitSfx(exploEmit, 1034)
        spEmitSfx(ringCenter, 1027)
        spEmitSfx(ringCenter, 1034)
        ltime = ltime - 50
        Sleep(50)
    end
    --Spring.Echo("reached1")
    -- Turn Grey on the Outside
    Move(ringCenter, y_axis, 90, 3.2)


    Move(ringRotator, z_axis, 35, 2.6)
    while (ltime > explosionTotalTime - 7000) do
        spEmitSfx(ringCenter, 1034)
        spEmitSfx(ringEmit1, 1034)
        spEmitSfx(ringEmit2, 1034)
        spEmitSfx(ringEmit3, 1034)
        spEmitSfx(ringEmit4, 1034)
        lspinRingRandom()
        spEmitSfx(exploEmit, 1027)
        spEmitSfx(exploEmit, 1034)

        spEmitSfx(ringCenter, 1027)
        spEmitSfx(ringCenter, 1034)
        ltime = ltime - 50
        Sleep(50)
    end



    -- Only Grey on the Inside, Turning Slower

    Move(ringCenter, y_axis, 100, 15)

    Move(ringRotator, z_axis, 35, 3.9)
    while (ltime > explosionTotalTime - 12000) do
        spEmitSfx(ringCenter, 1034)
        spEmitSfx(ringEmit1, 1034)
        spEmitSfx(ringEmit2, 1034)
        spEmitSfx(ringEmit3, 1034)
        spEmitSfx(ringEmit4, 1034)


        lspinRingRandom()
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit1, 1030) else spEmitSfx(ringEmit1, 1034) end
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit2, 1030) else spEmitSfx(ringEmit2, 1034) end
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit3, 1030) else spEmitSfx(ringEmit3, 1034) end
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit4, 1030) else spEmitSfx(ringEmit4, 1034) end

        if math.random(0, 1) == 1 and math.random(0, 1) == 1 then
            spEmitSfx(exploEmit, 1027)
            spEmitSfx(exploEmit, 1034)

            ltime = ltime - 50
        end

        spEmitSfx(ringCenter, 1034)
        Sleep(10)
    end

    boolLightMyFire = false
    while (boolSmokeOnTheSlaughter == true) do
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit1, 1030) else spEmitSfx(ringEmit1, 1034) end
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit2, 1030) else spEmitSfx(ringEmit2, 1034) end
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit3, 1030) else spEmitSfx(ringEmit3, 1034) end
        if math.random(0, 1) == 1 then spEmitSfx(ringEmit4, 1030) else spEmitSfx(ringEmit4, 1034) end
        spEmitSfx(ringEmit1, 1035)
        spEmitSfx(ringEmit2, 1035)
        spEmitSfx(ringEmit3, 1035)
        spEmitSfx(ringEmit4, 1035)
        lspinRingRandom()
        Sleep(10)
    end


    --Spring.Echo("reached3")
    -- Stop Rising at all No longer Turning --LongTermClouds
    Move(ringCenter, y_axis, 0, 0)
end


function takeMeToTheCloudAbove()

    x = 22000


    while x > 0 do
        if x > 9000 then
            for i = 1, 7, 1 do
                EmitSfx(exploEmit, 1027)
                Sleep(2)
            end
            EmitSfx(exploEmit, 1034)
        else
            for i = 1, math.random(1, 3), 1 do
                EmitSfx(exploEmit, 1027)
                if x > 4000 then EmitSfx(exploEmit, 1034) end
            end
        end
        Sleep(150)
        x = x - 150
    end

    while boolLightMyFire == true do

        EmitSfx(exploEmit, 1027)
        Sleep(90)
    end
end



function actualExplosion()
    Spin(spiralCenter, y_axis, math.rad(-182), 0)
    boolLightMyFire = true
    local spSpawnCeg = Spring.SpawnCEG
    local spEmitSfx = EmitSfx
    x, y, z = Spring.GetUnitPosition(unitID)

    --Impact + DustCloud

    for i = 1, 5, 1 do
        spSpawnCeg("dirt", x, y + (i * 2), z, 0, 1, 0, 50, 0)
        Sleep(70)
    end
    Sleep(150)
    --Shockwave+ShockwaveDust
    shockwave()
    Sleep(500)
    --StartGroundLight
    StartThread(alternativeFireLight)
   -- StartThread(damageFunction)
    Sleep(75)
    --Bright White Light+First ExplosionCloud
    spEmitSfx(shockwavecenter, 1026)
    Sleep(75)
    spEmitSfx(shockwavecenter, 1026)
    haveSoundArround()
    StartThread(emitColumn)
    StartThread(downCloud)
    Sleep(350)
    StartThread(mushRoom)
    --StartThread(takeMeToTheCloudAbove)

    Sleep(10000)

    --Rising ExplosionCloud - Outward Moving Pyroclastics

    --MushroomCloudForming --Starting ExplosionCloud ColourDecay

    --Pillarcloud rising
    --Decay Groundlight

    Sleep(13000)
    boolSmokeOnTheSlaughter = false
    Sleep(1500)
    Spring.DestroyUnit(unitID, false, true)
end

function threadMill()
        StartThread(actualExplosion)
        StartThread(shroom)
end

function script.Create()
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)

    Hide(spiralCenter)
    Hide(fireSpiral1)
    Hide(fireSpiral2)
    Hide(shockwaveemit)
    Hide(shockwavecenter)
    Hide(fireFx1)
    Hide(fireFx2)
    Hide(fireFx3)

    Hide(center)
    Hide(groupcenter)
    Hide(ringRotator)
    Hide(ringEmit1)
    Hide(ringEmit2)
    Hide(ringEmit3)
    Hide(ringEmit4)
    StartThread(threadMill)
end