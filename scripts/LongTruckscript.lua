local queueEventThread = include "lib_event_threads.lua"
local newMotionSampler = include "lib_vehicle_motion.lua"

include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"
local TablesOfPiecesGroups = {}

SIG_ORDERTRANFER = 1
SIG_HONK = 2
SIG_INTERNAL = 4

local center = piece("center")
local attachPoint = piece("attachPoint")
local colDetectPiece = piece("Truck1")
local TruckCenter = center
local PayloadCenter = piece("PayloadCenter")

local myTeamID = Spring.GetUnitTeam(unitID)
local boolGaiaUnit = myTeamID == Spring.GetGaiaTeamID()
local DetectPiece = piece"DetectPiece"
local GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)

local truckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)


boolIsCivilianTruck = true

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then           
            Show(v)
            return v
        end
    end
end

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T, true)
    else
        return
    end
end

function showOneOrAll(T)
    if not T then return end
    if math.random(0,1) == 1 then
        return showOne(T)
    else
        for num, val in pairs(T) do Show(val) end
        return
    end
end

BusBack1 = piece("BusBack1")
BusBack2 = piece("BusBack2")
LimoTruck= piece("Truck5")
LimoCabin= piece("LimoCabin")

function showAndTell()
    Hide(attachPoint)
    Hide(center)
    Hide(TruckCenter)
    Hide(PayloadCenter)
    Hide(BusBack1)
    Hide(BusBack2)
    Hide(DetectPiece)
    Hide(LimoCabin)
    Hide(LimoTruck)

    hideT(TablesOfPiecesGroups["LimoWheel"])
    hideT(TablesOfPiecesGroups["Truck"])
    hideT(TablesOfPiecesGroups["Cabin"])
    hideT(TablesOfPiecesGroups["BusDeco"])
    hideT(TablesOfPiecesGroups["BusStationName"])

    if TablesOfPiecesGroups["Truck"] then
        myTruck =  showOne(TablesOfPiecesGroups["Truck"])

        if  myTruck == TablesOfPiecesGroups["Truck"][3] or 
            myTruck == TablesOfPiecesGroups["Truck"][4]
        then --Bus
            GG.BusesTable[unitID] = unitID
            if myTruck == TablesOfPiecesGroups["Truck"][3] then 
                Show(BusBack1)
            end

            if myTruck == TablesOfPiecesGroups["Truck"][4] then 
                Show(BusBack2)
            end
            Move(TablesOfPiecesGroups["Wheel"][4],y_axis, 70, 0)
            Move(TablesOfPiecesGroups["Wheel"][5],y_axis, 70, 0)
            Move(TablesOfPiecesGroups["Wheel"][3],y_axis, 190, 0)
            Move(TablesOfPiecesGroups["Wheel"][2],y_axis, 40, 0)
            Move(TablesOfPiecesGroups["Wheel"][1],y_axis, 40, 0)
            showOne(TablesOfPiecesGroups["BusDeco"])
            showOne(TablesOfPiecesGroups["BusDeco"])
            showOne(TablesOfPiecesGroups["BusStationName"])
            return
        end

        if myTruck == LimoTruck then
            Show(LimoCabin)
            hideT(TablesOfPiecesGroups["Wheel"])
            showT(TablesOfPiecesGroups["LimoWheel"])
            return
        end
    end

    if TablesOfPiecesGroups["Cabin"] then
        showOne(TablesOfPiecesGroups["Cabin"])
    end

end

boolTurnLeft = false
boolTurning = false

local function wrapTrailerAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

function turnTrailerLoop()
    local sampleMotion = newMotionSampler(unitID)
    local previousHeading = Spring.GetUnitHeading(unitID)
    local previousFrame = Spring.GetGameFrame()
    local val = 0
    while true do
        boolMoving, boolTurning, boolTurnLeft = sampleMotion()
        local frame = Spring.GetGameFrame()
        local heading = Spring.GetUnitHeading(unitID)
        local delta = ((heading - previousHeading + 32768) % 65536 - 32768) * math.pi / 32768
        local dt = (frame - previousFrame) / 30
        previousHeading, previousFrame = heading, frame

        local _, yaw = Spring.UnitScript.GetPieceRotation(PayloadCenter)
        -- Preserve world orientation when the tractor rotates beneath the hitch.
        -- Both directions and the signed-heading boundary use the same rule.
        yaw = wrapTrailerAngle(yaw - delta)
        if boolMoving then
            -- Continuous relaxation toward the tractor; never round radians.
            yaw = yaw * math.exp(-dt / 6)
        end
        Turn(PayloadCenter, y_axis, yaw, 0)

        local px, py, pz = Spring.GetUnitPiecePosDir(unitID, DetectPiece)
        local groundHeight = Spring.GetGroundHeight(px, pz)
        local diff = math.max(math.abs((py - 7) - groundHeight), 0.0125)
        if py - 7 > groundHeight then
            val = val - diff / 10
        else
            val = val + diff / 10
        end
        val = clamp(val, -5, 5)
        Turn(PayloadCenter, x_axis, math.rad(val), 0.881)
        Sleep(boolMoving and 125 or 50)
    end
end


local loadOutUnitID
function script.Create()
    if boolIsCivilianTruck == true then assingCivilianTruckRegistration(unitID, Game, GameConfig.instance.culture) end

    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)

    showAndTell()

    StartThread(turnTrailerLoop)
end


function fleeEnemy(enemyID)
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_STARTED, "fleeing")
    if not enemyID then 
        setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_ENDED, "fleeing")
        return 
    end


    while doesUnitExistAlive(enemyID) and distanceUnitToUnit(unitID, enemyID) < GameConfig.civilian.PanicRadius do
        runAwayFrom(unitID, enemyID, GameConfig.civilian.FleeDistance)
        Sleep(500)
    end

    setCivilianUnitInternalStateMode(unitID,  GameConfig.STATE_ENDED, "fleeing")
end

attackerID = 0

function startFleeing(enemyID)
    if not enemyID then return end
    queueEventThread("flee", fleeEnemy, 250, enemyID)
end

function script.TransportDrop(passengerID, x, y, z)
    Signal(SIG_ORDERTRANFER)
    if boolIsCivilianTruck == true then
        Spring.UnitDetach(passengerID)
        Spring.SetUnitNoSelect(passengerID, false)
    end
end

function script.Killed(recentDamage, _)
    if doesUnitExistAlive(loadOutUnitID) then
        Spring.DestroyUnit(loadOutUnitID, true, true)
    end

    createCorpseCUnitGeneric(recentDamage)
    return 1
end

 function normalizeVector(vec)
        local length = math.sqrt(vec.x^2 + vec.y^2 + vec.z^2)
        vec.x = vec.x/length
        vec.y = vec.y/length
        vec.z = vec.z/length
        return vec
    end


ox,oy, oz = 0,0,0


boolMoving = false
function script.StartMoving()    
    Signal(SIG_HONK)
    spinT(TablesOfPiecesGroups["Wheel"], x_axis, 260, 0.3)
    spinT(TablesOfPiecesGroups["LimoWheel"], x_axis, 260, 0.3)
end

function honkIfHorny()
    Signal(SIG_HONK)
    SetSignalMask(SIG_HONK)
    Sleep(250)
    if math.random(0,100) > 80 and boolIsCivilianTruck == true and isRushHour() == true then
        StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/car/honk"..math.random(1,7)..".ogg", GameConfig.truckHonkLoudness, 1000, 1)
    end
end

function script.StopMoving() 
    stopSpinT(TablesOfPiecesGroups["Wheel"], x_axis, 3) 
    stopSpinT(TablesOfPiecesGroups["LimoWheel"], x_axis, 3) 
    StartThread(honkIfHorny)

end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

--- -aimining & fire weapon
function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return false end

function script.FireWeapon1() return true end
