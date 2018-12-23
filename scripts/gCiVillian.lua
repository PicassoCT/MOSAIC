include "lib_UnitScript.lua"
include "lib_Animation.lua"

--Define the wheel pieces
local over = piece "over"
--Define the pieces of the weapon
local ensignKim = piece "ensignKim"
local forrestGum = piece "forrestGum" --p

local civBody = piece "civBody"
local emit1 = piece "emit1"
local emit2 = piece "emit2"
local civLeg11 = piece "civLeg11"
local civLeg12 = piece "civLeg12"
local civLeg21 = piece "civLeg21"
local civLeg22 = piece "civLeg22"
runDist = 500
--second
local lifeTime = 45
--define other pieces

local SIG_WALK = 1 --signal for the walk animation thread
local SIG_AIM = 2 --signal for the weapon aiming thread
local SIG_IDLE = 4
local SIG_AIM2 = 8

timeSinceLastChatter = 0
function reduceTimeSinceLastChatter()
    Sleep(timeSinceLastChatter)
    timeSinceLastChatter = 0
end

unitdef = Spring.GetUnitDefID(unitID)

function throwYourHandsUpInTheAir()
    health = Spring.GetUnitHealth(unitID)
    healthOfOld = health
    while (true) do
        health = Spring.GetUnitHealth(unitID)
        if health >= healthOfOld then
            Sleep(500)
        else
            if timeSinceLastChatter < 5 then
                AleaActaEst = math.random(0, 14)

                if AleaActaEst == 0 then
                    StartThread(PlaySoundByUnitDefID, unitdef, "sounds/gCiv/screamWaah.wav", 0.3, 700, 1, 50)

                elseif AleaActaEst == 2 then
                    StartThread(PlaySoundByUnitDefID, unitdef, "sounds/gCiv/woah.wav", 0.3, 700, 1, 50)
                elseif AleaActaEst == 3 then
                    StartThread(PlaySoundByUnitDefID, unitdef, "sounds/gCiv/woohw.wav", 0.3, 700, 1, 50)
                end
            end
            EmitSfx(emit1, 1024)
            EmitSfx(emit1, 1024)
            --handsUp
            Turn(ensignKim, y_axis, math.rad(92), 5)
            Turn(ensignKim, x_axis, math.rad(-28), 5)
            Turn(ensignKim, z_axis, math.rad(-150), 5)

            Turn(forrestGum, y_axis, math.rad(-95), 5)
            Turn(forrestGum, x_axis, math.rad(-40), 5)
            Turn(forrestGum, z_axis, math.rad(174), 5)
            Sleep(600)
        end
        healthOfOld = health
    end
end


function runForrestRunOutrunMyGun()
    while (true) do
        --Get the Position
        px, py, pz = Spring.GetUnitPosition(unitID)
        --Get nearest enemy
        ex, ey, ez = Spring.GetUnitNearestEnemy(unitID)
        --computate steigung..
        --y=m*x+t
        x = 0
        z = 0
        if ez == nil then
            ex = 1000
            ey = 0
            ez = 1000
        end
        divNil = (pz - ez + 0.0001)
        if divNil == nil then
            divNil = 0.00001
        end

        steigung = (px - ex + 0.000001) / divNil
        --assert(steigung)
        runDist = math.random(400, 900)
        if ex < px then
            x = steigung * (runDist) + px
        else
            x = steigung * (runDist * -1) + px
        end

        z = (x - px) / steigung

        --set in alternative x into term with

        --Spring. SetUnitToMove.
        Spring.SetUnitMoveGoal(unitID, x, py, z)
        Sleep(3000)
    end
end

function delayedUnSetNeutral()
    Sleep(5000)
    Spring.SetUnitNeutral(unitID, false)
end

function script.Create()
    StartThread(killMeSoftly)
    px, py, pz = Spring.GetUnitPosition(unitID)
    Spring.SetUnitMoveGoal(unitID, px + 10, py, pz + 10)
end

local function idle()

    sleeper = math.random(1024, 8192)

    SetSignalMask(SIG_IDLE)
    while (true) do
        sleeper = math.random(5000, 60000)
        Sleep(sleeper)
        decid = math.random(0, 3)
        if decid == 1 then
            --Raucherpause
        elseif decid == 2 then
            Move(over, y_axis, -5.6, 3)
            Turn(civLeg21, x_axis, math.rad(-48), 6)
            Turn(civLeg21, y_axis, math.rad(-180), 12)
            Turn(civLeg21, z_axis, math.rad(180), 18)

            Turn(civLeg22, x_axis, math.rad(68), 6)
            Turn(civLeg22, y_axis, math.rad(180), 12)
            Turn(civLeg22, z_axis, math.rad(180), 18)


            Turn(civLeg12, x_axis, math.rad(40), 6)
            Turn(civLeg12, y_axis, math.rad(180), 12)
            Turn(civLeg12, z_axis, math.rad(180), 18)

            Turn(civLeg11, x_axis, math.rad(-48), 6)
            Turn(civLeg11, y_axis, math.rad(-180), 12)
            Turn(civLeg11, z_axis, math.rad(-180), 18)

            Turn(forrestGum, x_axis, math.rad(27), 6)
            Turn(forrestGum, y_axis, math.rad(-89), 12)
            Turn(forrestGum, z_axis, math.rad(33), 18)

            Turn(ensignKim, x_axis, math.rad(11), 6)
            Turn(ensignKim, y_axis, math.rad(63), 12)
            Turn(ensignKim, z_axis, math.rad(31), 18)
            --sitdown
        end
    end
end


--knorke in every file.. paranoia.. he is here.. right here... if you click on new file.. he is in there allready
--chuck norris of spring
--http://answers.springlobby.info/questions/427/howto-spinning-wheels-on-moving-units

local function walk()
    Signal(SIG_WALK)
    SetSignalMask(SIG_WALK)
    Turn(civBody, x_axis, math.rad(22), 14)
    WaitForTurn(civBody, x_axis)
    leg_movespeed = 6
    while (true) do
        if leg_movespeed < 14 then
            leg_movespeed = leg_movespeed + 4
        end
        Turn(ensignKim, x_axis, math.rad(25), leg_movespeed) --x and z axis are switched
        Turn(forrestGum, x_axis, math.rad(-25), leg_movespeed)

        Turn(civLeg21, x_axis, math.rad(35), leg_movespeed)
        Turn(civLeg22, x_axis, math.rad(0), leg_movespeed)
        Turn(civLeg11, x_axis, math.rad(-25), leg_movespeed)
        Turn(civLeg12, x_axis, math.rad(28), leg_movespeed)
        Sleep(250)
        Turn(ensignKim, x_axis, math.rad(-25), leg_movespeed)
        Turn(forrestGum, x_axis, math.rad(25), leg_movespeed)

        Turn(civLeg21, x_axis, math.rad(-25), leg_movespeed)
        Turn(civLeg22, x_axis, math.rad(18), leg_movespeed)
        Turn(civLeg11, x_axis, math.rad(34), leg_movespeed)
        Turn(civLeg12, x_axis, math.rad(8), leg_movespeed)
        Sleep(250)
    end
end

local function legs_down()

    Move(civBody, x_axis, 0, 12)
    Move(civBody, y_axis, 0, 12)
    Move(civBody, z_axis, 0, 12)
    Move(over, x_axis, 0, 12)
    Move(over, y_axis, 0, 12)
    Move(over, z_axis, 0, 12)
    Turn(civBody, x_axis, math.rad(0), 15)
    Turn(civBody, y_axis, math.rad(0), 15)
    Turn(civBody, z_axis, math.rad(0), 15)
    Turn(over, x_axis, math.rad(0), 15)
    Turn(over, y_axis, math.rad(0), 15)
    Turn(over, z_axis, math.rad(0), 15)
    Turn(civLeg21, x_axis, math.rad(0), 15)
    Turn(civLeg22, x_axis, math.rad(0), 15)
    Turn(civLeg11, x_axis, math.rad(0), 15)
    Turn(civLeg12, x_axis, math.rad(0), 15)

    Turn(civLeg21, y_axis, math.rad(0), 15)
    Turn(civLeg22, y_axis, math.rad(0), 15)
    Turn(civLeg11, y_axis, math.rad(0), 15)
    Turn(civLeg12, y_axis, math.rad(0), 15)


    Turn(civLeg21, z_axis, math.rad(0), 15)
    Turn(civLeg22, z_axis, math.rad(0), 15)
    Turn(civLeg11, z_axis, math.rad(0), 15)
    Turn(civLeg12, z_axis, math.rad(0), 15)
end

boolVirginia = true

function script.StartMoving()
    if boolVirginia == true then
        boolVirginia = false
        StartThread(runForrestRunOutrunMyGun)
        StartThread(throwYourHandsUpInTheAir)
    end
    --    ----Spring.Echo ("starting to walk!")
    Signal(SIG_IDLE)
    legs_down()
    StartThread(walk)
end

function script.StopMoving()

    --    ----Spring.Echo ("stopped walking!")
    Signal(SIG_IDLE)
    Signal(SIG_WALK)
    legs_down()
    StartThread(idle)
end

function killMeSoftly()

    Sleep(1000 * lifeTime)

    Spring.DestroyUnit(unitID, false, true)
end


function script.Killed(recentDamage, maxHealth)
    if math.random(0, 2) == 1 then

        StartThread(PlaySoundByUnitDefID, unitdef, "sounds/gCiv/screamWaah.wav", 0.3, 700, 1, 50)
    end
    EmitSfx(emit1, 1024)
    EmitSfx(emit2, 1024)


    bitRand = math.random(0, 1)
    if bitRand == 1 then
        Move(civBody, y_axis, 2, 0.6)

        Turn(over, x_axis, math.rad(25), 3)
        WaitForTurn(over, x_axis)
        EmitSfx(emit2, 1024)
        EmitSfx(emit1, 1024)
        Sleep(10)
        EmitSfx(emit2, 1024)
        EmitSfx(emit1, 1024)
        Turn(over, x_axis, math.rad(45), 9)
        WaitForTurn(over, x_axis)
        EmitSfx(emit1, 1024)
        EmitSfx(emit2, 1024)
        EmitSfx(emit1, 1024)
        EmitSfx(emit2, 1024)
        Turn(over, x_axis, math.rad(90), 3)
        WaitForTurn(over, x_axis)
        EmitSfx(emit1, 1024)
        EmitSfx(emit2, 1024)
        EmitSfx(emit1, 1024)
        EmitSfx(emit2, 1024)

        --- -Spring.Echo ("He is dead, Jim!")


    else
        Move(civBody, y_axis, 2, 0.6)

        Turn(civBody, x_axis, math.rad(-25), 3)
        WaitForTurn(civBody, x_axis)
        EmitSfx(emit1, 1024)
        EmitSfx(emit2, 1024)
        Turn(civBody, x_axis, math.rad(-45), 9)
        WaitForTurn(civBody, x_axis)
        EmitSfx(emit2, 1024)
        EmitSfx(emit1, 1024)
        Turn(civBody, x_axis, math.rad(-90), 3)
        WaitForTurn(civBody, x_axis)
        EmitSfx(emit2, 1024)
        EmitSfx(emit1, 1024)

        --- -Spring.Echo ("He is dead, Jim!")
    end

    return 1
end

