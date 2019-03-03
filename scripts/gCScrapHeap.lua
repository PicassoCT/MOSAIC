skyscrape = piece "skyscrape"
center = piece "center"
emitfire = piece "emitfire"
teamID = Spring.GetGaiaTeamID()
comb1 = piece "comb1"
comb2 = piece "comb2"
comb3 = piece "comb3"
triangles = {}
for i = 1, 6, 1 do
    triangles[i] = {}
    Emiters = "tris" .. i
    triangles[i] = piece(Emiters)
end

comDeb = {}
for i = 1, 7, 1 do
    comDeb[i] = {}
    Emiters = "comDeb" .. i
    comDeb[i] = piece(Emiters)
end

comb = {}
for i = 1, 5, 1 do
    comb[i] = {}
    Emiters = "comb" .. i
    comb[i] = piece(Emiters)
end

corner = {}
for i = 1, 18, 1 do
    corner[i] = {}
    val = i + 10
    Emiters = "corn" .. val
    corner[i] = piece(Emiters)
end

house = {}
for i = 1, 4, 1 do
    house[i] = {}
    Emiters = "house" .. i
    house[i] = piece(Emiters)
end


wallE = {}
for i = 1, 9, 1 do
    wallE[i] = {}
    Emiters = "wall0" .. i
    wallE[i] = piece(Emiters)
end

goldDebris = {}
for i = 1, 9, 1 do
    goldDebris[i] = {}
    Emiters = "goldDeb" .. i
    goldDebris[i] = piece(Emiters)
end

girderBender = {}
for i = 12, 36, 1 do
    girderBender[i] = {}
    Emiters = "girder" .. i
    girderBender[i] = piece(Emiters)
end


windwall = {}
for i = 1, 36, 1 do
    windwall[i] = {}
    Emiters = "winDebB" .. i
    windwall[i] = piece(Emiters)
end


scrapH = {}
for i = 1, 7, 1 do
    scrapH[i] = {}
    Emiters = "scrapHeap" .. i
    scrapH[i] = piece(Emiters)
end

scrapMain = piece "scrapMain"

function hideAndSeek()
    if math.random(0, 3) == 1 then
        Show(skyscrape)
        return
    else
        Hide(skyscrape)
    end
    dot = math.random(0, 2)
    if dot == 2 or dot == 1 then
        mod = math.random(1, 5)



        for i = 1, 6, 1 do
            if i % mod == 0 then
                Show(triangles[i])
            else
                Hide(triangles[i])
            end
        end

        for i = 1, 7, 1 do
            if i == 6 or i == 7 then
                x = math.random(-90, 90)
                y = math.random(-90, 90)
                z = math.random(-90, 90)
                Turn(comDeb[i], y_axis, math.rad(y), 0)
                Turn(comDeb[i], x_axis, math.rad(x), 0)
                Turn(comDeb[i], z_axis, math.rad(z), 0)
            end
            if i % mod == 0 then
                Show(comDeb[i])
            else
                Hide(comDeb[i])
            end
        end

        for i = 1, 18, 1 do
            if i % mod == 0 then
                Show(corner[i])
            else
                Hide(corner[i])
            end
        end


        for i = 1, 9, 1 do
            if i % mod == 0 then
                Show(wallE[i])
            else
                Hide(wallE[i])
            end
        end

        for i = 1, 9, 1 do
            if i % mod == 0 then
                Show(goldDebris[i])
            else
                Hide(goldDebris[i])
            end
        end

        for i = 24, 36, 1 do
            if i % mod == 0 then
                Show(girderBender[i])
            else
                Hide(girderBender[i])
            end
        end

        --Spring.Echo("Test")
        for i = 1, 7, 1 do
            if i % mod == 0 then
                Show(scrapH[i])
            else
                Hide(scrapH[i])
            end
        end


        for i = 1, 36, 1 do
            if i % mod == 0 then
                Show(windwall[i])
            else
                Hide(windwall[i])
            end
            if mod % 4 == 0 and i % 4 == 0 then
                Show(windwall[i])
            end
        end
        ranDosran = math.random(0, 4)
        if ranDosran == 1 then
            Hide(comb1)
        elseif ranDosran == 2 then
            Hide(comb2)
        elseif ranDosran == 3 then
            Hide(comb3)
        elseif ranDosran == 4 then
            Hide(comb3)
            Hide(comb2)
        end

    else
        --here begins a hide of all
        for i = 1, 6, 1 do

            Hide(triangles[i])
        end

        for i = 1, 7, 1 do

            Hide(comDeb[i])
        end

        for i = 1, 18, 1 do

            Hide(corner[i])
        end


        for i = 1, 9, 1 do

            Hide(wallE[i])
        end

        for i = 1, 9, 1 do

            Hide(goldDebris[i])
        end

        for i = 24, 36, 1 do

            Hide(girderBender[i])
        end

        for i = 1, 4, 1 do
            rondo = math.random(0, 1)
            if rondo == 1 then
                Hide(house[i])
            end
        end



        for i = 1, 36, 1 do

            Hide(windwall[i])
        end
        Hide(comb1)
        Hide(comb2)
        Hide(comb3)
    end
end


table.insert(scrapH, scrapMain)


function script.Killed()
end

function playRadomBattleSound(Nr, chanceIt)
    local spPlaySoundFile = Spring.PlaySoundFile
    FourString = "sounds/gCrubbleHeap/city_battle"
    SecondString = ".wav"
    y = 1
    if chanceIt == true then
        y = math.random(0, 1)
    end

    if y == 1 then
        for i = 1, Nr, 1 do
            rand = math.random(1, 19)
            resultString = FourString .. rand
            resultString = resultString .. SecondString
            spPlaySoundFile(resultString)
            napTime = math.random(1700, 3500)
            Sleep(napTime)
        end
    end
end

function playBattleLoop()
    local spPlaySoundFile = Spring.PlaySoundFile
    dice = math.random(0, 1)
    if dice == 1 then
        decDicer = math.random(0, 1)
        if decDicer == 1 then
            spPlaySoundFile("sounds/gCrubbleHeap/battle_loop1.wav")
        else
            spPlaySoundFile("sounds/gCrubbleHeap/battle_loop2.wav")
        end
    else
    end
    Sleep(30000)
end

function soundEmit()
    for i = 0, 4, 1 do
        --firstMinute
        if i == 1 then
            StartThread(playRadomBattleSound, 12, false)
            playBattleLoop()
            StartThread(playRadomBattleSound, 8, false)
            playBattleLoop()

        elseif i == 2 then
            --secondMinute
            StartThread(playRadomBattleSound, 5, false)
            playBattleLoop()
            StartThread(playRadomBattleSound, 12, true)
            playBattleLoop()
        else
            StartThread(playRadomBattleSound, 9, true)
            Sleep(60000)
        end
    end
end

function smokeEmit()
end

function onFire(times, endtimes)
    for i = 1, times, 1 do
        if i < endtimes then
            EmitSfx(emitfire, 1025)
            EmitSfx(emitfire, 1028)
            EmitSfx(emitfire, 1026)
            EmitSfx(emitfire, 1027)
        else
            EmitSfx(emitfire, 1027)
        end
        Sleep(200)
    end
end

function combineShatter()

    for i = 1, 5, 1 do
        if math.random(0, 1) == 1 then
            d = math.random(-45, 45)
            Turn(comb[i], x_axis, math.rad(d), 0)
            d = math.random(-45, 45)
            Turn(comb[i], z_axis, math.rad(d), 0)
            d = math.random(-360, 360)
            Turn(comb[i], y_axis, math.rad(d), 0)
            Show(comb[i])
        end
    end
end


function script.Create()
    for i = 1, 5, 1 do
        Hide(comb[i])
    end
    hideAndSeek()
    if math.random(0, 22) == 1 then combineShatter() end


    x = math.random(0, 360)
    EmitSfx(emitfire, 1024)
    Turn(center, y_axis, math.rad(x), 0)
    StartThread(soundEmit)
    fireTime = math.random(40, 360)
    endTimes = math.random(0, 500)
    StartThread(onFire, fireTime, endTimes)
    StartThread(waitForAnEnd)
end

function waitForAnEnd()
    Time = math.ceil(math.random(12000, 48000))
    Sleep(Time)
    Move(center, y_axis, -67, 0.04)
    WaitForMove(center, y_axis)
    Spring.DestroyUnit(unitID, true, false)
end