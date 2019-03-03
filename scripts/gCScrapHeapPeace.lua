skyscrape = piece "skyscrape"
center = piece "center"
emitfire = piece "emitfire"
teamID = Spring.GetGaiaTeamID()
comb1 = piece "comb1"
comb2 = piece "comb2"
comb3 = piece "comb3"

comb = {}
for i = 1, 5, 1 do
    comb[i] = {}
    Emiters = "comb" .. i
    comb[i] = piece(Emiters)
end

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

corner = {}
for i = 1, 18, 1 do
    corner[i] = {}
    val = i + 10
    Emiters = "corn" .. val
    corner[i] = piece(Emiters)
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

function hideAllThePieces()
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

    --Spring.Echo("Test")
    for i = 1, 7, 1 do
        Hide(scrapH[i])
    end


    for i = 1, 36, 1 do
        Hide(windwall[i])
    end

    Hide(comb1)
    Hide(comb2)
    Hide(comb3)
    Hide(comb3)
    Hide(comb2)
end

function hideAndSeek()

    for i = 1, 5, 1 do
        Hide(comb[i])
    end
    if math.random(0, 3) == 1 then
        Show(skyscrape)
        if math.random(0, 1) == 1 then hideAllThePieces() end
        return
    else
        Hide(skyscrape)
    end

    mod = math.random(1, 5)
    --<template>
    --[[
    if       % mod ==0 then
    Show()
    else
    Hide()
    end]]
    --</template>

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
end


table.insert(scrapH, scrapMain)
--[[

groundEmitters={}
for i=1,8,1 do
groundEmitters[i]={}
Emiters="EmitG"..i
groundEmitters[i]=piece(Emiters)
end

skyEmitters={}
for i=1,21,1 do
skyEmitters[i]={}
Emiters="EmitS"..i
skyEmitters[i]=piece(Emiters)
end

lSpawner={}
for i=1,4,1 do
lSpawner[i]={}
lavaSpawneX="lavaSpawner"..i
lSpawner[i]=piece(lavaSpawneX)
end
lPyre={}
for i=1,3,1 do
lPyre[i]={}
lavaSpawneX="lavaPyre"..i
lPyre[i]=piece(lavaSpawneX)
end

lavaLingus={}
for i=1,4,1 do
lavaLingus[i]={}
lavaSpawneX="lavaTongue"..i
lavaLingus[i]=piece(lavaSpawneX)
end
]]


function script.Killed()
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




function script.Create()

    hideAndSeek()
		Spring.SetUnitNeutral(unitID,true)

    x = math.random(0, 360)
    EmitSfx(emitfire, 1024)
    Turn(center, y_axis, math.rad(x), 0)

    fireTime = math.random(40, 360)
    endTimes = math.random(0, 500)
    StartThread(onFire, fireTime, endTimes)
    StartThread(waitForAnEnd)
end


function waitForAnEnd()
    Time = math.ceil(math.random(12000, 48000))
    Sleep(Time)
    Move(center, y_axis, -67, 0.02)
    WaitForMove(center, y_axis)
    Spring.DestroyUnit(unitID, false,true)
end