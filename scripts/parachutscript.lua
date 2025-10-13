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
testOffset = 300
stationaryDropRate = 2.0
travellingDropRate = 0.5
dropRate = travellingDropRate

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.MoveCtrl.Enable(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    --Spring.SetUnitAlwaysVisible(unitID, true)
    hideT(TablesOfPiecesGroups["Rotator"])
    StartThread(fallingDown)
    StartThread(detectStationary)
    Show(center)
    assert(infantry)
    Hide(infantry)
    Hide(step) 
end

upDownAxis= 1
SignAge= 1



x, y, z = Spring.GetUnitPosition(unitID)
boolStationary = false
function detectStationary()
    stationaryTreshold=4.0
    accumulatedNonMovementTime = 0
    oldx,  oldz = x,z

    while true do
        oldx,  oldz = x,z
        Sleep(100)
        if Spring.GetGroundHeight(x,z) < 0 then
            dropRate = 0.00000001
        else
            dist = math.sqrt((oldx-x)^2 + (oldz-z)^2)
            if dist < stationaryTreshold then
                accumulatedNonMovementTime = accumulatedNonMovementTime + 100
                if accumulatedNonMovementTime > 5000 then
                    dropRate = stationaryDropRate
                    boolStationary = true
                    foreach(TablesOfPiecesGroups["DownWardSpiral"],
                        function(id)
                            val = math.random(1,360)
                            Turn(id, y_axis, math.rad(val),0)
                            Show(id)
                            directions = math.random(15, 35)
                            Spin(id,y_axis,math.rad(directions), 0.1)
                        end)
                else
                    dropRate = travellingDropRate
                    boolStationary = false
                    foreach(TablesOfPiecesGroups["DownWardSpiral"],
                        function(id)
                            Hide(id)                            
                            StopSpin(id,y_axis)
                        end)
                end
            else
                accumulatedNonMovementTime = 0
                dropRate = travellingDropRate
                boolStationary = false
                foreach(TablesOfPiecesGroups["DownWardSpiral"],
                        function(id)
                            Hide(id)                            
                            StopSpin(id,y_axis)
                        end)
            end
        end
    end
end

local passengerID = unitID
operativeTypeTable = getOperativeTypeTable(Unitdefs)

function fallingDown()
    waitTillComplete(unitID)
    Sleep(1)
    showT(TablesOfPiecesGroups["Cord"])
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
    StartThread(Strandanimation)

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
    for i=2,#TablesOfPiecesGroups["Cord"] do
        WMove(TablesOfPiecesGroups["Cord"][i], 2 , i*-15, 900)
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

local semaphore = {}
function strandMotion(index,strand, yValue, xStart, xEndValue, speed)
    semaphore[index] = true  
    Turn(strand, x_axis, math.rad(xStart), 0)
    Turn(strand, y_axis, math.rad(yValue), 0)
    Show(strand)
    WTurn(strand, x_axis, math.rad(xEndValue), speed)
    Hide(strand)
    semaphore[index] = nil
end

function sinusWaveThread(start, ends)
    local Fract = TablesOfPiecesGroups["Rotator"]

    while true do
        -- one animation cycle
        sintime = ((Spring.GetGameFrame() % 300) / 300)
        
        for i = start, ends do
            local strand = Fract[i]
            circleVal = ((i - start)+1) * (360/(ends- start)) + math.random(-5,5)

            if not semaphore[i] then
                startValue =  math.random(15,30)
                endValue = -15
                StartThread(strandMotion, i, strand, circleVal, startValue,endValue, 1 )               
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

function Strandanimation()
    local Fract = TablesOfPiecesGroups["Rotator"]
    for i = 1, #Fract do
        if i % 15 == 1 and Fract[i] and Fract[i+15] then
            StartThread(sinusWaveThread, i, i + 15) 
        end
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
