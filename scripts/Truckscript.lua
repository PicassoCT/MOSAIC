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

center = piece "center"
attachPoint = piece "attachPoint"

myDefID = Spring.GetUnitDefID(unitID)

local truckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)

STATE_STARTED = "STARTED"
STATE_ENDED = "ENDED"
function setCivilianUnitInternalStateMode(unitID, State)
     if not GG.CivilianUnitInternalLogicActive then GG.CivilianUnitInternalLogicActive = {} end
     
     GG.CivilianUnitInternalLogicActive[unitID] = State 
 end

boolIsCivilianTruck = (truckTypeTable[myDefID] ~= nil)
boolIsPoliceTruck = myDefID == UnitDefNames["policetruck"].id
myLoadOutType = LoadOutTypes[myDefID]
local loadOutUnitID

function showAndTell()
    showAll(unitID)

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

local loadOutUnitID
function script.Create()

    if boolIsCivilianTruck == false then StartThread(loadLoadOutLoop) end

    if UnitDefs[myDefID].name == "polictruck" then
        StartThread(theySeeMeRollin)
    end 

    if UnitDefs[myDefID].name == "truck_western1" then
        StartThread(showLamboWindow)
    end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
    Hide(attachPoint)
    Hide(center)
    showAndTell()
    StartThread(observeTeamChange)
end

function showLamboWindow()
    LamboWindow = piece"LamboWindow"
    Show(LamboWindow)
    Spoiler = piece"Spoiler"
    if maRa() == maRa() then 
        Show(Spoiler)
    else
        Hide(Spoiler)
    end



    interval = math.ceil(1000/30)
    local spGetUnitRotation = Spring.GetUnitRotation
    local quarterRad = (math.pi*2)/4
    local lookInsideRatio = quarterRad/10


    while true do
        _,yaw,_ = spGetUnitRotation(unitID)
        remainder = yaw % quarterRad
        randDistance = math.huge
        if remainder < lookInsideRatio then
             randDistance = remainder
        elseif  remainder + lookInsideRatio > quarterRad  then
            randDistance = math.abs(remainder - quarterRad)
        end

        if randDistance < lookInsideRatio then
            factor = (randDistance/lookInsideRatio)*100
             if math.random(1,100) < factor then  Hide(LamboWindow)  end
            else
                    Show(LamboWindow)
            end
        Sleep(interval)
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
    Spring.SetUnitNoSelect(loadOutUnitID, true)
    Spring.UnitAttach(unitID, loadOutUnitID, attachPoint)

    while myLoadOutType ~= explosiveDefID do
        Sleep(100)

        if doesUnitExistAlive(loadOutUnitID) == false then
            myTeam = Spring.GetUnitTeam(unitID)
            loadOutUnitID = createUnitAtUnit(myTeam, myLoadOutType, unitID, 0,
                                             10, 0)
            if loadOutUnitID then
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
    if boolIsCivilianTruck then
        Spring.SetUnitNoSelect(passengerID, true)
        Spring.UnitAttach(unitID, passengerID, attachPoint)
        passenger = passengerID
        StartThread(tranferOrdersToLoadedUnit, passengerID)
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
    if not enemyID then 
        setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
        return 
    end

    while doesUnitExistAlive(enemyID) and distanceUnitToUnit(unitID, enemyID) < GameConfig.civilianPanicRadius do
        runAwayFrom(unitID, enemyID, GG.GameConfig.civilianFleeDistance)
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

--- -aimining & fire weapon
function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return boolIsPoliceTruck end

function script.FireWeapon1() return true end

function script.StartMoving()
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
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/car/honk"..math.random(1,7)..".ogg", 1.0, 1000, 1)
    end
end

function script.StopMoving() 
    stopSpinT(TablesOfPiecesGroups["wheel"], x_axis, 3) 
    StartThread(honkIfHorny)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

