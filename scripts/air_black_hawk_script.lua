include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

center = piece "center"
assert(center)
imgoingdown = piece "imgoingdown"
assert(imgoingdown)
bady = piece "bady"
assert(bady)
tailrotor = piece "tailrotor"
assert(tailrotor)
tailrotors = piece "tailrotors"
assert(tailrotors)

rotor = piece "rotor"
assert(rotor)

rotors = piece "rotors"
assert(rotors)

nightlight = piece "rotors"
turret = piece "turrret"
assert(turret)
gun = piece "gun001"
assert(gun)
aim1 = piece "aim1"
assert(aim1)

dirtemit1 = piece "dirtemit1"
assert(dirtemit1)
dirtemit2 = piece "dirtemit2"
assert(dirtemit2)

soundfolder = "sounds/air/copter/"
rotoscope = piece "rotoscope"
assert(rotoscope)

local boolOnlyOnce = true
local boolMoving = false
local SIG_LANDED = 1
local SIG_FLY = 2
local SIG_UP = 4
local SIG_Down = 8

function HideAssert(piece, name)
    --assert(piece, name)
    Hide(piece)
end

local buildProgress = 1
local boolShortStop = false
local boolLongStop = false

function rotorsUp()
    Sleep(200)
    Turn(center, x_axis, math.rad(0), 6.5)
    Move(center, y_axis, 0, 8.8)
    SetSignalMask(SIG_UP)
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
    if isNight() == true then 
        Show(nightlight)
    else
        HideAssert(nightlight, "nightlight")
    end

    Sleep(350)
    HideAssert(rotor, "rotor")
    HideAssert(tailrotor, "tailrotor")
end

function rotorsDown()
    SetSignalMask(SIG_Down)

    HideAssert(nightlight, "nightlight")
    Sleep(600)
    --Spring.Echo("Imlanding-Copterscript")
    Spin(tailrotor, x_axis, math.rad(-190), 0.001)
    Spin(rotor, y_axis, math.rad(-190), 0.001)
    Spin(nightlight, y_axis, math.rad(190), 0.001)
    Sleep(350)
    HideAssert(tailrotors, "tailrotors")

    HideAssert(rotors, "rotors")
    StopSpin(rotors, y_axis, 0)
    StopSpin(tailrotors, x_axis, 0.01)
    if boolAir == true then
        Show(rotor)
        Show(tailrotor)
    end
    Sleep(1000)
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
    StartThread(PlaySoundByUnitDefID, unitDefID, soundfolder .. "copterlanding.wav", 0.9, 3000, 1)
    Sleep(4000)

    while RepEated > 0 do
        RepEated = RepEated - 1
        w = lrand(0.5, 0.65)
        StartThread(PlaySoundByUnitDefID, unitDefID, soundfolder .. "copterlanded.wav", w, 3000, 1)
        rest = lceil(lrand(1900, 2400))

        for i = 1, rest, 100 do
            Sleep(100)
        end
    end
end

function flyBySound()
    if maRa() == true then
        PlaySoundByUnitDefID(unitDefID, soundfolder .. "copterflyby.wav", 0.7, 5000, 1)

    else
        PlaySoundByUnitDefID(unitDefID, soundfolder .. "copterflyby2.wav", 0.7, 5000, 1)
    end
end

function onTheFly()
    SetSignalMask(SIG_FLY)
    Sleep(300)
    local spPlaySound = Spring.PlaySoundFile
    local lsin = math.sin
    local lrand = math.random

    --StartThread(PlaySoundByUnitDefID, unitDefID, soundfolder .. "copterTakeOff.wav", 0.9, 3000, 1)
    Sleep(3000)
    SumSini = 0
    boolFlop = true
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

    HideAssert(rotoscope, "rotoscope")
    HideAssert(dirtemit1, "dirtemit1")
    HideAssert(dirtemit2, "dirtemit2")
    HideAssert(imgoingdown, "imgoingdown")

    if Game.windMax <= 1 then boolAir = false end
    --check boolAir
    HideAssert(aim1,"aim1")
    if boolAir == true then
        HideAssert(rotors, "rotors")
        HideAssert(tailrotors, "tailrotors")
    else
        HideAssert(tailrotor,"tailrotor")
        HideAssert(tailrotors,"tailrotors")
        HideAssert(rotor, "ROTOR")
        HideAssert(rotors, "ROTORs")

    end
    --HideAssert(aim2, "aim2")
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

