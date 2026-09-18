local parachuteSway = include "lib_parachute_sway.lua"
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

local windX, windZ = 0, 0
local steeringX, steeringZ = 0, 0
local WIND_DRIFT = 0.12 -- per existing movement tick; steering is 1.52

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
        steeringX, steeringZ = xOff, zOff
        local driftX, driftZ = 0, 0
        if xOff == 0 and zOff == 0 then
            driftX, driftZ = windX*WIND_DRIFT, windZ*WIND_DRIFT
        end
        Spring.MoveCtrl.SetPosition(unitID, x + xOff + driftX, y - dropRate, z + zOff + driftZ)
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

-- One worker for all strands; no per-strand threads, hide/show cycles or RNG.
function Strandanimation()
    local strands = TablesOfPiecesGroups["Rotator"] or {}
    local ids = {}
    for index, strand in pairs(strands) do
        if type(index) == "number" then ids[#ids+1] = index end
    end
    table.sort(ids)
    local flowX, flowZ = 0, 0
    local previousFrame = Spring.GetGameFrame()
    local phase = (unitID % 31)*0.19
    for _, index in ipairs(ids) do Show(strands[index]) end
    while true do
        local frame = Spring.GetGameFrame()
        local dt = math.max(0, (frame-previousFrame)/30)
        previousFrame = frame
        local wx, _, wz = Spring.GetWind()
        windX, windZ = parachuteSway.wind(wx or 0, wz or 0, Game.windMax or 0)
        -- Relative airflow: wind bends downwind, commanded travel trails backward.
        local heading = Spring.GetUnitHeading(unitID)*math.pi/32768
        local dx, dz = windX*0.45-steeringX/1.52, windZ*0.45-steeringZ/1.52
        local c, s = math.cos(heading), math.sin(heading)
        local blend = 1-math.exp(-dt/0.65)
        flowX = flowX + (c*dx-s*dz-flowX)*blend
        flowZ = flowZ + (s*dx+c*dz-flowZ)*blend
        for ordinal, index in ipairs(ids) do
            local pitch, yaw, roll = parachuteSway.pose(frame/30+phase, ordinal, #ids, flowX, flowZ)
            Turn(strands[index], x_axis, pitch, 1.8)
            Turn(strands[index], y_axis, yaw, 1.8)
            Turn(strands[index], z_axis, roll, 1.8)
        end
        Sleep(100)
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
