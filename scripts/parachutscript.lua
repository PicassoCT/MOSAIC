include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
local GrapheneChute = VFS.Include("scripts/lib_graphene_chute.lua")

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "anchor"
infantry = piece "Infantrz"
step = piece "step"
testOffset = 300
stationaryDropRate = 2.0
travellingDropRate = 0.5
dropRate = travellingDropRate
local canopySlots = {}

local function clearCanopy()
    if GG.SmokeRibbon then
        for _, slot in ipairs(canopySlots) do GG.SmokeRibbon.Remove(unitID, slot) end
    end
    canopySlots = {}
end

local function deployCanopy()
    if not GG.SmokeRibbon then return end
    local layout = GrapheneChute.Layout(unitID, step)
    if not layout then return end
    for i = 1, 4 do
        local slot = "graphene_chute_" .. i
        if GG.SmokeRibbon.Set(unitID, slot, step, GrapheneChute.RibbonOptions(layout, i)) then
            canopySlots[#canopySlots+1] = slot
        end
        slot = "graphene_arc_" .. i
        local ok, reason = GG.SmokeRibbon.Set(unitID, slot, step, GrapheneChute.ArcOptions(layout, i))
        if ok then canopySlots[#canopySlots+1] = slot
        else Spring.Echo("[GrapheneArc] registration failed: " .. tostring(reason)) end
    end
end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.MoveCtrl.Enable(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    --Spring.SetUnitAlwaysVisible(unitID, true)
    hideT(TablesOfPiecesGroups["Rotator"])
    hideT(TablesOfPiecesGroups["DownWardSpiral"])
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
            ty = ty + GG.GameConfig.military.parachute.height
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
    deployCanopy()

    passengerID = GG.ParachutPassengers[unitID].id
    passengerDefID = Spring.GetUnitDefID(passengerID)
    if operativeTypeTable[passengerDefID] and Spring.GetUnitIsCloaked(passengerID) then Show(infantry) end

    x, y, z = GG.ParachutPassengers[unitID].x, GG.ParachutPassengers[unitID].y,
              GG.ParachutPassengers[unitID].z
    if not passengerID or isUnitAlive(passengerID) == false then
        clearCanopy()
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

    clearCanopy()
    Spring.UnitDetach(passengerID)
    Spring.DestroyUnit(unitID, false, true)
end

function script.Killed(recentDamage, _)    
    clearCanopy()
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
