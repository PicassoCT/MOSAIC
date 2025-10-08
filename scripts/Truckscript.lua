include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"
local TablesOfPiecesGroups = {}

local LoadOutTypes = getTruckLoadOutTypeTable()
local NotTruckLoadableUnitType = getNotTruckLoadableTypeTable(UnitDefs)
local GameConfig = getGameConfig()
SIG_ORDERTRANFER = 1
SIG_HONK = 2
SIG_INTERNAL = 4
SIG_DEADGUY = 8

local center = piece "center"
local attachPoint = piece "attachPoint"
local myTeamID = Spring.GetUnitTeam(unitID)
local boolGaiaUnit = myTeamID == Spring.GetGaiaTeamID()

local truckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)
local boolIsCivilianTruck = (truckTypeTable[unitDefID] ~= nil)
local boolIsPoliceTruck = unitDefID == UnitDefNames["policetruck"].id
local myLoadOutType = LoadOutTypes[unitDefID]
local loadOutUnitID
local map = Spring.GetUnitPieceMap(unitID)


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


function showAndTell()
    showAll(unitID)
    Hide(center)
    if TablesOfPiecesGroups["TowGuys"] then
        hideT(TablesOfPiecesGroups["TowGuys"])
    end
    if map["DeadGuyTurningPoint"] then
        Hide(map["DeadGuyTurningPoint"] )
    end

    if UnitDefs[unitDefID].name == "truck_western2" then --WeyMo
        hideT(TablesOfPiecesGroups["Logo"])
        showOneOrAll(TablesOfPiecesGroups["Logo"])
    end

    if TablesOfPiecesGroups["EmitLight"] then
        hideT(TablesOfPiecesGroups["EmitLight"])
    end
    if TablesOfPiecesGroups["Body"] then
        hideT(TablesOfPiecesGroups["Body"])
        if #TablesOfPiecesGroups["Body"] <= 1 then
         Show(TablesOfPiecesGroups["Body"][1])
        else
            Show(TablesOfPiecesGroups["Body"][math.random(1, #TablesOfPiecesGroups["Body"])])
        end
    end
end

boolMoving = false
boolTurnLeft = false
boolTurning = false
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
            end    
        Sleep(125)    
    end
end

function hcdetector()
    TurnCount = 0
    local spGetUnitHeading = Spring.GetUnitHeading
    local headingOfOld = spGetUnitHeading(unitID)
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

function turnDeadGuyLoop(PayloadCenter)
    Signal(SIG_DEADGUY)
    SetSignalMask(SIG_DEADGUY)
    boolMoving = false
    boolTurnLeft = false
    boolTurning = false
    StartThread(monitorMoving)
    StartThread(hcdetector)
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
                local headRad
                if boolTurnLeft then
                    headRad = -math.pi + math.atan2(dz, dx)
                else
                    headRad = math.pi - math.atan2(dx, dz)
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

local deadGuyInTowTypeTable = getDeadGuyInTowTypeTable(UnitDefs)

function isTowTruck(defID)
    return deadGuyInTowTypeTable[defID]
end

local boolTowsGuyInAnarchy = isTowTruck(myDefId) and randChance(5)

function goingIntoAnarchy()
    local deadGuyTurningPoint = piece("DeadGuyTurningPoint")
    ShowOne(TablesOfPiecesGroups["TowGuys"])
    Show(deadGuyTurningPoint)
    StartThread(turnDeadGuyLoop, deadGuyTurningPoint)
end

function goingOutOfAnarchy()
    local deadGuyTurningPoint = piece("DeadGuyTurningPoint")
    hideT(TablesOfPiecesGroups["TowGuys"])
    Hide(deadGuyTurningPoint)
    Signal(SIG_DEADGUY)
end

function waitForAnarchy(intoAnarchyFunction, outOfAnarchyFunction)
    while true do
        waitTillDay()
        if GG.GlobalGameState == "anarchy" then
            intoAnarchyFunction()
            while GG.GlobalGameState == "anarchy"  do
                Sleep(9000)
            end
            outOfAnarchyFunction()
        end
        Sleep(1000)
    end
end

local loadOutUnitID
function script.Create()
    myName = UnitDefs[unitDefID].name
    if boolIsCivilianTruck == false then StartThread(loadLoadOutLoop) end
    if boolIsCivilianTruck == true then assingCivilianTruckRegistration(unitID, Game, GameConfig.instance.culture) end

    if myName == "policetruck" then StartThread(theySeeMeRollin) end 

    if myName == "truck_western1" then StartThread(showLamboWindow) end
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
    Hide(attachPoint)
    Hide(center)

    showAndTell()
    StartThread(observeTeamChange)
    if boolTowsGuyInAnarchy then
        StartThread(waitForAnarchy, goingIntoAnarchy, goingOutOfAnarchy )
    end
end

function showLamboWindow()
    Sleep(1)
    LamboWindow = piece"LamboWindow"
    Show(LamboWindow)
    Spoiler = piece"Spoiler"
    if maRa() == maRa() then 
        Show(Spoiler)
    else
        Hide(Spoiler)
    end
end

function observeTeamChange()
    myTeam = Spring.GetUnitTeam(unitID)
    while true do
        newTeam = Spring.GetUnitTeam(unitID)
        if newTeam ~= myTeam then -- Team changed
            if doesUnitExistAlive( loadOutUnitID) == true then
                transferUnitTeam(loadOutUnitID, newTeam)
            end
            myTeam = newTeam
        end
       delay = math.random(10,15)*50
       Sleep(delay)
    end
end

allOrderTypes = {}
function loadLoadOutLoop()
    waitTillComplete(unitID)
    Sleep(100)
    myTeam = Spring.GetUnitTeam(unitID)

    explosiveDefID = UnitDefNames["ground_turret_ssied"].id

    loadOutUnitID = createUnitAtUnit(myTeam, myLoadOutType, unitID, 0, 10, 0)
    if doesUnitExistAlive(loadOutUnitID) then
        if boolGaiaUnit then Spring.SetUnitAlwaysVisible(loadOutUnitID,true) end
        Spring.SetUnitNoSelect(loadOutUnitID, true)
        Spring.UnitAttach(unitID, loadOutUnitID, attachPoint)
    end

    while myLoadOutType ~= explosiveDefID do
        Sleep(100)

        if doesUnitExistAlive(loadOutUnitID) == false then
            myTeam = Spring.GetUnitTeam(unitID)
            loadOutUnitID = createUnitAtUnit(myTeam, myLoadOutType, unitID, 0,
                                             10, 0)
            if loadOutUnitID then
                if boolGaiaUnit then Spring.SetUnitAlwaysVisible(loadOutUnitID,true) end
                Spring.SetUnitNoSelect(loadOutUnitID, true)
                Spring.UnitAttach(unitID, loadOutUnitID, attachPoint)
            end
        else
            if allOrderTypes[myLoadOutType] then
                transferOrders(unitID, loadOutUnitID)
            else
                transferAttackOrder(unitID, loadOutUnitID)
            end
            transferStates(unitID, loadOutUnitID)
        end
    end
end

local passenger
function script.TransportPickup(passengerID)
    if passengerID then
        defID = Spring.GetUnitDefID(passengerID)
        if NotTruckLoadableUnitType[defID] then return end

        if  boolIsCivilianTruck then
            Spring.SetUnitNoSelect(passengerID, true)
            Spring.UnitAttach(unitID, passengerID, attachPoint)
            passenger = passengerID
            StartThread(tranferOrdersToLoadedUnit, passengerID)
        end
    end
end

function tranferOrdersToLoadedUnit(passengerID)
    Signal(SIG_ORDERTRANFER)
    SetSignalMask(SIG_ORDERTRANFER)

    while doesUnitExistAlive(passengerID) == true do
        transferAttackOrder(unitID, passengerID)
        transferStates(unitID, passengerID)
        Sleep(100)
    end
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
    setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_STARTED, "fleeing")
    if not enemyID then 
        setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_ENDED, "fleeing")
        return 
    end

    while doesUnitExistAlive(enemyID) and distanceUnitToUnit(unitID, enemyID) < GameConfig.civilian.PanicRadius do
        runAwayFrom(unitID, enemyID, GameConfig.civilian.FleeDistance)
        Sleep(500)
    end

    setCivilianUnitInternalStateMode(unitID, GameConfig.STATE_ENDED, "fleeings")
end

attackerID = 0
boolStartFleeing = false 
function startFleeing(attackerID)
    if not attackerID then return end
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

--- -aimining & fire weapon
function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return boolIsPoliceTruck end

function script.FireWeapon1() return true end

boolStopped = true
function script.StartMoving()
    boolStopped = false
    Signal(SIG_HONK)
    if boolIsPoliceTruck == true then
        spinT(TablesOfPiecesGroups["wheel"], x_axis, -260, 0.3)
    else
        spinT(TablesOfPiecesGroups["wheel"], x_axis, 260, 0.3)
    end
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
    boolStopped = true
    stopSpinT(TablesOfPiecesGroups["wheel"], x_axis, 3) 
    StartThread(honkIfHorny)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

