include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"
TablesOfPiecesGroups = {}

LoadOutTypes = getTruckLoadOutTypeTable()

SIG_ORDERTRANFER = 1
SIG_HONK = 2
SIG_INTERNAL = 4

center = piece("center")
attachPoint = piece("attachPoint")
colDetectPiece = piece("coldDetect")
TruckCenter = center
PayloadCenter = piece("PayloadCenter")
myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
boolGaiaUnit = myTeamID == Spring.GetGaiaTeamID()
DetectPiece = piece"DetectPiece"
GameConfig = getGameConfig()
civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)

local truckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)

STATE_STARTED = "STARTED"
STATE_ENDED = "ENDED"
function setCivilianUnitInternalStateMode(unitID, State)
     if not GG.CivilianUnitInternalLogicActive then GG.CivilianUnitInternalLogicActive = {} end
     
     GG.CivilianUnitInternalLogicActive[unitID] = State 
 end

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

function showAndTell()
    Hide(attachPoint)
    Hide(center)
    Hide(TruckCenter)
    Hide(PayloadCenter)
    Hide(BusBack1)
    Hide(BusBack2)
    Hide(DetectPiece)



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
    end

    if TablesOfPiecesGroups["Cabin"] then
        showOne(TablesOfPiecesGroups["Cabin"])
    end

end
 boolTurnLeft = false
 boolTurning = false

function turnTrailerLoop()
    local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
    local spGetGroundHeight = Spring.GetGroundHeight
    turnRatePerSecondDegree = (300*0.16)/4
    _,lastOrientation,_  = Spring.UnitScript.GetPieceRotation(PayloadCenter)
    px,py,pz = spGetUnitPiecePosDir(unitID, DetectPiece)
    val  = 0
    oldPitch, oldYaw, OldRoll = Spring.GetUnitRotation(unitID)
    while true do
        px,py,pz = Spring.GetUnitPiecePosDir(unitID, DetectPiece)
        pitch,yaw,roll = Spring.GetUnitRotation(unitID)
       -- echo("Unit  "..pitch.."/"..yaw.."/"..roll)
        if boolMoving == true  then          
            x, y, z = Spring.UnitScript.GetPieceRotation(PayloadCenter)
            goal = math.ceil(y * 0.95)
            Turn(PayloadCenter,y_axis, goal, 1.125)
            lastOrientation = goal
        else
            if boolTurning == true then                
                x,y,z = spGetUnitPiecePosDir(unitID, PayloadCenter)
                dx,  dz = px-x, pz-z
                if boolTurnLeft then
                    headRad = -math.pi + math.atan2(dz, dx)
                else
                    headRad = -math.atan2(dx, dz)
                end
                Turn(PayloadCenter,y_axis, headRad, 1)
                lastOrientation = headRad
            else    
                Turn(PayloadCenter,y_axis, lastOrientation, 0)   
            end
        end     

        groundHeigth =   spGetGroundHeight(px,pz)
        diff = math.max(math.abs((py - 7) -groundHeigth), 0.0125)
        if py - 7 > groundHeigth then
            val = val - (diff/10)
        else
            val = val + (diff/10)
        end
        radYaw = math.rad(clamp( val, -5, 5))
        Turn(PayloadCenter, x_axis, radYaw, 0.881)   

        if boolMoving == true then
            Sleep(125)
        else
            Sleep(50)
        end
        oldPitch, oldYaw, OldRoll = pitch, yaw, roll
    end
end

function hcdetector()
    TurnCount = 0
    local spGetUnitHeading = Spring.GetUnitHeading
    headingOfOld = spGetUnitHeading(unitID)
    while true do
        Sleep(50)
 
        tempHead = spGetUnitHeading(unitID)
        --if boolDebugPrintDiff then Spring.Echo("Current Heading"..tempHead) end
        if tempHead ~= headingOfOld then
            boolTurning = true
        else
            boolTurning = false
        end
        boolTurnLeft = headingOfOld > tempHead
        headingOfOld = tempHead
    end
end

local loadOutUnitID
function script.Create()
    if boolIsCivilianTruck == true then assingCivilianTruckRegistration(unitID, Game, GameConfig.instance.culture) end

    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)

    showAndTell()

    StartThread(hcdetector)
    StartThread(turnTrailerLoop)
    StartThread(monitorMoving)
end

function threadStateStarter()
    Sleep(100)
    while true do
        if boolStartFleeing == true then
            boolStartFleeing = false
            StartThread(fleeEnemy, attackerID)
        end
        Sleep(250)   
    end
end

function fleeEnemy(enemyID)
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    if not enemyID then 
        setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
        return 
    end

    while doesUnitExistAlive(enemyID) and distanceUnitToUnit(unitID, enemyID) < GameConfig.civilian.PanicRadius do
        runAwayFrom(unitID, enemyID, GameConfig.civilian.FleeDistance)
        Sleep(500)
    end

    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

attackerID = 0
boolStartFleeing = false 
function startFleeing(attackerID)
    if not attackerID then return end
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    boolStartFleeing = true
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


function collideWithPersonOnFoot()
    massOfTruck = UnitDefs[myDefID].mass or 90000
    maxSpeedOfTruck = UnitDefs[myDefID].maxVelocity or 2.81
    colDetectPiece = Spring.GetUnitPiecePosDir(unitID, colDetectPiece)
    foreach(colDetectPiece,
        function (id)
            personDefId = spGetUnitDefID(id)
            if  civilianWalkingTypeTable[personDefId] then 
                return id
            end 
        end,
        function (id)
            personDefId = spGetUnitDefID(id)
            massOfCivilian =  UnitDefs[personDefId].mass or 900
            px,py,pz = Spring.GetUnitPosition(person)
            v= normalizeVector{x= px-ox, y= py-oy, z = pz-oz}
            Impulsefaktor = (massOfTruck /maxSpeedOfTruck) * (1/massOfCivilian)
            Spring.AddUnitImpulse(person,Impulsefaktor*v.x,Impulsefaktor* v.y,Impulsefaktor* v.z)
        end)
end

ox,oy, oz = 0,0,0
function monitorMoving()
    local spGetUnitPosition = Spring.GetUnitPosition
    ox,oy,oz = spGetUnitPosition(unitID)
    nx,ny,nz = ox,oy,oz
    while true do
            ox,oy,oz = nx,ny,nz  
            nx,ny,nz = spGetUnitPosition(unitID)        
            diff= math.abs(ox - nx) + math.abs(oz-nz) 
            if diff >  5  then
                boolMoving = true
            else
                boolMoving = false
                collideWithPersonOnFoot()
            end    
        Sleep(125)    
    end
end

boolMoving = false
function script.StartMoving()    
    Signal(SIG_HONK)
    spinT(TablesOfPiecesGroups["Wheel"], x_axis, 260, 0.3)
end

function honkIfHorny()
    Signal(SIG_HONK)
    SetSignalMask(SIG_HONK)
    Sleep(250)
    if math.random(0,100) > 80 and boolIsCivilianTruck == true and isRushHour() == true then
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/car/honk"..math.random(1,7)..".ogg", GameConfig.truckHonkLoudness, 1000, 1)
    end
end

function script.StopMoving() 
    stopSpinT(TablesOfPiecesGroups["Wheel"], x_axis, 3) 
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
