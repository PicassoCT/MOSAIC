include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"


center = piece "center"
imgoingdown = piece "imgoingdown"
bady = piece "bady"
tailrotor = piece "tailrotor"
tailrotors = piece "tailrotors"


wheel = piece "wheel"

rotor = piece "rotor"
rotors = piece "rotors"
turret = piece "turret"
gun = piece "gun001"
aim1 = piece "aim1"

dirtemit1 = piece "dirtemit1"
dirtemit2 = piece "dirtemit2"


soundfolder = "sounds/air/copter/"
rotoscope = piece "rotoscope"


local boolOnlyOnce = true
local boolMoving = false
local SIG_ONTHEFLY = 4
local SIG_BUILD = 2
local SIG_LANDED = 8
local SIG_HOVER = 16
local SIG_FLY = 32
local SIG_WAITING = 64
SIG_RESET = 128


local buildProgress = 1
local boolShortStop = false
local boolLongStop = false
boolIsNight = true

boolRedBlue = math.random(0, 1) == 1




function rotorsUp()
    Sleep(200)


    Turn(center, x_axis, math.rad(0), 6.5)
    Move(center, y_axis, 0, 8.8)
    SetSignalMask(SIG_UP)
    --Spring.Echo("Imflying-Copterscript")
    Spin(rotor, y_axis, math.rad(-105192), 35.4)
    Spin(nightlight, y_axis, math.rad(105192), 35.4)

    Spin(tailrotor, x_axis, math.rad(-105192), 35.4)

    Spin(rotors, y_axis, math.rad(272), 15.5)
    Spin(tailrotors, x_axis, math.rad(72), 15)
    Sleep(2000)
    if boolAir == true then
        Show(tailrotors)
        Show(rotors)
    end
    Sleep(350)
    Hide(rotor)
    Hide(tailrotor)

end

function rotorsDown()
    SetSignalMask(SIG_Down)

    Sleep(600)
    --Spring.Echo("Imlanding-Copterscript")
    Spin(tailrotor, x_axis, math.rad(-190), 0.001)
    Spin(rotor, y_axis, math.rad(-190), 0.001)
    Spin(nightlight, y_axis, math.rad(190), 0.001)
    Sleep(350)
    Hide(tailrotors)

    Hide(rotors)
    StopSpin(rotors, y_axis, 0)
    StopSpin(tailrotors, x_axis, 0.01)
    if boolAir == true then
        Show(rotor)
        Show(tailrotor)
    end
    Sleep(1000)
    Turn(center, x_axis, math.rad(-18), 0.25)
    Move(center, y_axis, -5.5, 2.8)

end

function script.Activate()
    --activates the secondary weapon
    Signal(SIG_Down)
    StartThread(rotorsUp)
    return 1
end

function script.Deactivate()
    --deactivates the secondary weapon
    Signal(SIG_UP)
    StartThread(rotorsDown)
    --return 0
    return 0
end

chopperdirt = 1024
choppermuzzle = 1025
flyinggrass = 1026
blackerthensmoke = 1027
rlexplode = 1028



RepEated = 2
function landed()
    SetSignalMask(SIG_LANDED)

    Sleep(350)
    local spPlaySound = Spring.PlaySoundFile
    local lrand = math.random
    local lceil = math.ceil
    StartThread(PlaySoundByUnitDefID, unitdef, soundfolder .. "copterlanding.wav", 0.9, 3000, 1)
    Sleep(4000)

    while RepEated > 0 do
        RepEated = RepEated - 1
        w = lrand(0.5, 0.65)
        StartThread(PlaySoundByUnitDefID, unitdef, soundfolder .. "copterlanded.wav", w, 3000, 1)
        rest = lceil(lrand(1900, 2400))

        for i = 1, rest, 100 do
            dx = lrand(1, 6)
            if boolAir == true then
                if dx == 3 then
                    EmitSfx(dirtemit1, chopperdirt)
                    EmitSfx(dirtemit2, chopperdirt)
                else
                    EmitSfx(dirtemit2, flyinggrass)
                    EmitSfx(dirtemit2, chopperdirt)
                end
            end
            Sleep(100)
        end
    end
end


function flyBySound()
    if maRa() == true then
        PlaySoundByUnitDefID(unitdef, soundfolder .. "copterflyby.wav", 0.7, 5000, 1)

    else
        PlaySoundByUnitDefID(unitdef, soundfolder .. "copterflyby2.wav", 0.7, 5000, 1)
    end
end

unitdef = Spring.GetUnitDefID(unitID)
function onTheFly()
    SetSignalMask(SIG_FLY)
    Sleep(300)
    local spPlaySound = Spring.PlaySoundFile
    local lsin = math.sin
    local lrand = math.random

    StartThread(PlaySoundByUnitDefID, unitdef, soundfolder .. "copterTakeOff.wav", 0.9, 3000, 1)
    Sleep(3000)
    SumSini = 0
    boolFlop = true
    while true do
        if boolFlop == true then
            StartThread(PlaySoundByUnitDefID, unitdef, soundfolder .. "flying.wav", lsin(SumSini), 1050, 1)
            SumSini = SumSini + 0.05
            rest = lrand(950, 1050)
            Sleep(rest)
            if SumSini >= 1 then
                boolFlop = false
                SumSini = 0
            end
        else
            StartThread(PlaySoundByUnitDefID, unitdef, soundfolder .. "flying2.wav", lsin(SumSini), 1050, 1)
            SumSini = SumSini + 0.01
            rest = lrand(950, 1050)
            Sleep(rest)
            if SumSini >= 1 then
                boolFlop = true
                SumSini = 0
            end
        end
        --Chance for Flyby Sound
        oneInTen = math.random(1, 55)
        if oneInTen == 22 then flyBySound() end
        Sleep(10)
    end
end







boolLongStopStarted = false
boolLongFlightStarted = false

function moveStateCheck()
    while (true) do

        if boolMoving == true and boolLongFlightStarted == false then

            Signal(SIG_FLY)
            boolLongFlightStarted = true
            boolLongStopStarted = false
            StartThread(onTheFly)
            Sleep(500)
        end

        if boolMoving == false and boolShortStop == false then
            Sleep(512)

            if boolLongStop == false and boolShortStop == false then
                RepEated = 2
                boolLongStop = true
            end
        end
        if boolLongStop == true and boolLongStopStarted == false then
            Signal(SIG_LANDED)
            boolLongStopStarted = true
            boolLongFlightStarted = false
            if RepEated > 0 then
                StartThread(landed)
            end
        end


        Sleep(500)
    end
end



function script.StartMoving()

    --windGet()
    if boolOnlyOnce == true then
        boolOnlyOnce = false
        StartThread(moveStateCheck)
    end

    boolMoving = true
    boolShortStop = true
end

function script.StopMoving()


    boolMoving = false
    boolShortStop = false
end

boolYouOnlyDieOnce = false
function script.HitByWeapon(x, z, weaponDefID, damage)
    hp = Spring.GetUnitHealth(unitID)
    if hp and hp - damage < 0 and boolYouOnlyDieOnce == false then
        boolYouOnlyDieOnce = true
        StartThread(emitSmoke)
        EmitSfx(bady, rlexplode)


        EmitSfx(bady, rlexplode)
        Spin(imgoingdown, y_axis, math.rad(-250), 0.01)
        EmitSfx(bady, rlexplode)

        SetUnitValue(COB.CRASHING, 1)
        Spring.SetUnitNeutral(unitID, true)
        Spring.SetUnitNoSelect(unitID, true)
        return 0
    end
    return damage
end


boolAir = true
function script.Create()
    --test
    Turn(rotoscope, x_axis, math.rad(18), 0)
    Spin(rotoscope, y_axis, math.rad(640), 0)
    --/test
    Hide(dirtemit1)
    Hide(dirtemit2)
    if Game.windMax <= 1 then boolAir = false end
    --check boolAir
    Hide(aim1)
    if boolAir == true then
        Hide(rotors)
        Hide(tailrotors)
    else
        Hide(tailrotor)
        Hide(tailrotors)
        Hide(rotorhub)
        Hide(rotor)
        Hide(rotors)

    end
    Hide(aim2)
end

function emitSmoke()
    while (true) do
        EmitSfx(bady, smokeEmit)
        Sleep(15)
    end
end

function script.Killed()

    EmitSfx(bady, rlexplode)
    createCorpseCUnitGeneric()
    return 0
end


function script.AimFromWeapon1()
    return aim1
end

function script.QueryWeapon1()
    return aim1
end



function script.AimWeapon1(heading, pitch)
    if math.deg(pitch) < 0 then return false end
    Turn(turret, y_axis, heading, 5.2)
    Turn(gun, x_axis, pitch, 7.75)
    WaitForTurn(gun, x_axis)
    WaitForTurn(turret, y_axis)
    return true
end


function script.FireWeapon1()

    for i = 1, 11, 1 do
        EmitSfx(aim1, choppermuzzle)
        Sleep(142)
    end
end
