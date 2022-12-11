include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "anchor"
infantry = piece "Infantrz"
step = piece "step"

-- if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
-- if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end
testOffset = 300
stationaryDropRate = 2.0
travellingDropRate = 0.5
dropRate = travellingDropRate

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.MoveCtrl.Enable(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
    -- StartThread(AnimationTest)
    hideT(TablesOfPiecesGroups["Fract"])
    StartThread(fallingDown)
    StartThread(detectStationary)
    Show(center)
    assert(infantry)
    Hide(infantry)
    Hide(step)


    foreach(TablesOfPiecesGroups["Rotator"],
            function(id) 
                StartThread(randShow, id) 
            end
            )
end

upDownAxis= 1
function turnDownAndUp(id, rVal, downValue, downSpeed, upValue, upSpeed)
    Turn(id, upAxisRotation, math.rad(rVal),0)    
    Turn(id, upDownAxis, math.rad(downValue),downSpeed)
    WaitForTurns(id)
    Show(id)
    Turn(id, upDownAxis, math.rad(upValue),upSpeed)
end

SignAge= 1

function randShow(id)
    standardSpeed = math.pi / 10
    upAxisRotation = 3

    while true do
        rVal = math.random(1, 360)
        Show(id)
        if boolStationary == true then
            turnDownAndUp( id, rVal, math.random(-15, -10),0, math.random(0, 10), standardSpeed)
        else
           
            if true then 
                turnDownAndUp(id, rVal, math.random(-90, -45),0, math.random(-5, 0), standardSpeed)
            else
                timinRadMins = ((Spring.GetGameFrame()/30/60) % 1.0)*2 * math.pi
                axeVal = (45 + math.sin(timinRadMins)*45)*-1
                turnDownAndUp( id,rVal, axeVal, 0, math.random(-5, 0), standardSpeed)
            end
        end
        
        WaitForTurns(id)
        Hide(id)
        reset(id)
    end
end

x, y, z = Spring.GetUnitPosition(unitID)
boolStationary = false
function detectStationary()
    stationaryTreshold=4.0
    accumulatedNonMovementTime = 0
    oldx,  oldz = x,z

    while true do
        oldx,  oldz = x,z
        Sleep(100)
        dist = math.sqrt((oldx-x)^2 + (oldz-z)^2)
        if dist < stationaryTreshold then
            accumulatedNonMovementTime = accumulatedNonMovementTime + 100
            if accumulatedNonMovementTime > 5000 then
                dropRate = stationaryDropRate
                boolStationary = true
            else
                dropRate = travellingDropRate
                boolStationary = false
            end
        else
            accumulatedNonMovementTime = 0
            dropRate = travellingDropRate
            boolStationary = false
        end
    end
end

local passengerID = unitID
operativeTypeTable = getOperativeTypeTable(Unitdefs)

function fallingDown()
    waitTillComplete(unitID)
    Sleep(1)
    if not GG.ParachutPassengers then GG.ParachutPassengers = {} end 

    transporting = Spring.GetUnitIsTransporting(unitID)
    if not GG.ParachutPassengers[unitID] then
        if fatherID and operativeTypeTable[Spring.GetUnitDefID(fatherID)]  then
            tx, ty, tz = Spring.GetUnitPosition(fatherID)
            ty = ty + GG.GameConfig.parachuteHeight
            GG.ParachutPassengers[unitID] = {id = fatherID, x = tx, y = ty, z = tz}
        else
            if transporting and #transporting > 0 then
                x, y, z = Spring.GetUnitPosition(transporting[1])
                GG.ParachutPassengers[unitID] =
                    {id = transporting[1], x = x, y = y, z = z}
            end
        end
    end

    while not GG.ParachutPassengers[unitID] do Sleep(10) end
    -- debug code
    passengerID = GG.ParachutPassengers[unitID].id
    passengerDefID = Spring.GetUnitDefID(passengerID)
    if operativeTypeTable[passengerDefID] and Spring.GetUnitIsCloaked(passengerID) then Show(infantry) end

    x, y, z = GG.ParachutPassengers[unitID].x, GG.ParachutPassengers[unitID].y,
              GG.ParachutPassengers[unitID].z
    if not passengerID or isUnitAlive(passengerID) == false then
        Spring.DestroyUnit(unitID, false, true);
        return
    end

    Spring.UnitAttach(unitID, passengerID, step)
    Spring.MoveCtrl.SetPosition(unitID, x, y, z)

    while isPieceAboveGround(unitID, center, 15) == true do
        x, y, z = Spring.GetUnitPosition(unitID)
        xOff, zOff = getComandOffset(passengerID, x, z, 1.52)
        Spring.MoveCtrl.SetPosition(unitID, x + xOff, y - dropRate, z + zOff)
        Sleep(1)
    end

    Spring.UnitDetach(passengerID)
    Spring.DestroyUnit(unitID, false, true)
end

function pieceOrder(i)
    if i == 1 then return 1 end
    if i > 1 and i < 4 then return 2 end
    if i > 3 and i < 8 then return 3 end
    if i > 7 and i < 16 then return 4 end
    return 0
end

function sinusWaveThread(start, ends)
    local Fract = TablesOfPiecesGroups["Fract"]

    while true do
        -- one animation cycle
        sintime = ((Spring.GetGameFrame() % 300) / 300) * 2 * math.pi
        base = math.abs(math.sin(sintime) * 45)
        costime = ((Spring.GetGameFrame() % 600) / 600) * 2 * math.pi
        for i = start, ends do
            if Fract[i] then
                locTimeOffset = (math.pi) / 2 -- 5seconds  divided by 4 depth
                if i % 15 ~= 1 then base = 0 end

                pOrder = pieceOrder(i % 15)
                wavetime = costime + (locTimeOffset * pOrder)
                wave = math.cos(wavetime) * 42
                rVal = math.random(-6, 6)
                speed = math.abs(base + wave + rVal) / 100

                Turn(Fract[i], x_axis, math.rad(base + wave + rVal), speed)
            end
        end

        Sleep(100)
    end
end

function Fibonacci_tail_call(n)
    local function inner(m, a, b)
        if m == 0 then return a end
        return inner(m - 1, b, a + b)
    end
    return inner(n, 0, 1)
end

function AnimationTest()
    local Fract = TablesOfPiecesGroups["Fract"]
    for i = 1, #Fract, 15 do
        degToTurn = (360 / (#Fract / 15)) * (i - 1)
        ndegree = math.random(10, 80)
        Turn(Fract[i], y_axis, math.rad(degToTurn), 0)
    end

    for i = 1, #Fract do
        if i % 15 == 1 then StartThread(sinusWaveThread, i, i + 15) end
    end

    while true do
        -- resetAll(unitID)
        Sleep(3000)
        gameFrame = Spring.GetGameFrame()
        for i = 1, #Fract, 15 do
            degToTurn = (360 / (#Fract / 15)) * (i - 1)
            ndegree = math.random(10, 80)
            Turn(Fract[i], y_axis, math.rad(degToTurn), math.pi)
        end

        WaitForTurns(Fract)
        Sleep(10)
    end
end

function script.Killed(recentDamage, _)    
    return 1 
end


function getComandOffset(id, x, z, speed)

    CommandTable = Spring.GetUnitCommands(id, 3)
    boolFirst = true
    xVal, zVal = 0, 0
    for _, cmd in pairs(CommandTable) do
        if boolFirst == true and cmd.id == CMD.MOVE then
            boolFirst = false
            TurnVal = 0
            if math.abs(cmd.params[1] - x) > 10 then
                if cmd.params[1] < x then
                    TurnVal = 270
                    xVal = speed * -1
                elseif cmd.params[1] > x then
                    TurnVal = 90
                    xVal = speed
                end
            end

            if math.abs(cmd.params[3] - z) > 10 then
                if cmd.params[3] < z then
                    TurnVal = (TurnVal + 180) / 2
                    zVal = speed * -1
                elseif cmd.params[3] > z then
                    TurnVal = (TurnVal + 360) / 2
                    zVal = speed
                end
            end

            Turn(infantry, y_axis, math.rad(TurnVal), 15)

            return xVal, zVal
        end
    end
    return xVal, zVal
end
