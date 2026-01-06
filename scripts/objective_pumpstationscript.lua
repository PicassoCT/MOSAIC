include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

restTime = (60*1000)/20
LightOn = piece("LightOn")
LightOff = piece("LightOff")

y_axis = 2
randf = math.random
function unfoldPiece(pID)
    val = math.random(50, 500)
    Sleep(val)
    StopSpin(pID, 1, 5)
    StopSpin(pID, 2, 5)
    StopSpin(pID, 3, 5)
    reset(pID, 2.5)
    val = math.random(-360, 360)
    Turn(pID, y_axis, math.rad(val), 5)
end

local function animateGasCloud(pieces, radius)
    for i = 1, #pieces do
        local p = pieces[i]

        local angle = randf(0, 2*math.pi)
        local dist  = randf(radius * 0.2, radius)

        local x = math.cos(angle) * dist
        local z = math.sin(angle) * dist
        local y = randf(150, 450)

        Show(p)

        -- fast outward bloom
        WMove(p, x_axis, x, randf(120, 260))
        WMove(p, z_axis, z, randf(120, 260))
        WMove(p, y_axis, y, randf(160, 320))

        -- turbulent rotation
        spinRand(p, -60, 60, randf(18, 32))
    end
end

local function driftCloud(stem, dirX, dirZ, timeMs)
    local steps = math.floor(timeMs / 250)
    local speed = 18

    for i = 1, steps do
        WMove(stem, x_axis, dirX * speed, 80)
        WMove(stem, z_axis, dirZ * speed, 80)
        Sleep(250)
    end
end

local function collapseAndFade(pieces)
    for i = 1, #pieces do
        local p = pieces[i]

        -- stop spinning
        StopSpin(p, x_axis)
        StopSpin(p, y_axis)
        StopSpin(p, z_axis)

        -- pull inward & downward
        Move(p, x_axis, 0, randf(60,120))
        Move(p, z_axis, 0, randf(60,120))
        Move(p, y_axis, randf(-120, -60), randf(80,140))
    end

    Sleep(800)

    hideT(pieces)
end

SIG_FLAME = 2
Flame = piece("Flame")

function flameSpin()
    Signal(SIG_FLAME)
    SetSignalMask(SIG_FLAME)

    while true do
        Show(Flame)
        spinRand(Flame, -60, 60, randf(18, 32))
                Spin(Flame, 2, math.rad(42)*randSign(), math.pi)
        rVal = math.random(150,500)
        Sleep(rVal)
        Hide(Flame)
        reset(Flame)

    end
end

function explosionLoop()
    Sleep(100)
    explosionTable = {unpack(TablesOfPiecesGroups["Explosion"], 2, #TablesOfPiecesGroups["Explosion"])} 
    explosionStem  = TablesOfPiecesGroups["Explosion"][1]
    cloudRadius = 2500
    driftTimeInMs = 3000
    Hide(Flame)
    while true do 
        hideT(explosionTable)
        Hide(explosionStem)
        StartThread(flameSpin)
        resetT(explosionTable, 0)
        reset(explosionStem, 0)

        local dirX, _, dirZ = Spring.GetWind()

        Show(explosionStem)

        -- vertical ignition plume
        WMove(explosionStem, y_axis, 1250, 250)

        -- gas cloud bloom
        animateGasCloud(explosionTable, cloudRadius)

        -- drift phase
        driftCloud(explosionStem, dirX, dirZ, driftTimeInMs)
        Signal(SIG_FLAME)
        Hide(Flame)
        -- collapse + fade
        collapseAndFade(explosionTable)

        Hide(explosionStem)

        Sleep(2000)
    end
end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(blinkLoop,LigthOn, LightOff, restTime)
    StartThread(explosionLoop)
    Spring.SetUnitBlocking(unitID, false)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
