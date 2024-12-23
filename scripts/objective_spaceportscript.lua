include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_debug.lua"
--include "lib_Build.lua"

TableOfPiecesGroups = {}

ReturningBooster1ThrusterPlumN = "ReturningBooster1ThrusterPlum"
ReturningBooster2ThrusterPlumN = "ReturningBooster2ThrusterPlum"
ReturningBooster3ThrusterPlumN = "ReturningBooster3ThrusterPlum"

CapsuleRocket = piece "CapsuleRocket"

BoosterN = "Booster"
RocketThrustPillarN = "RocketThrustPillar"
FusionLandingGearN = "FusionLandingGear"
LandedBoosterN = "LandedBooster"
RocketPlumeN = "RocketPlume"
RocketPlumeAN = "RocketPlumeA"
FireFlowerN = "FireFlower"
GroundRearDoorN = "GroundRearDoor"
GroundFrontDoorN = "GroundFrontDoor"
CraneHeadClawN = "CraneHeadClaw"
BoosterN = "Booster"
ReturningBoosterN = "ReturningBooster"
BoosterCrawlerN = "CrawlerBooster"
CrawlerBoosterN = "CrawlerBooster"
CrawlerBoosterGasRingN = "CrawlerBoosterGasRing"
BoosterRotatorN = "BoosterRotator"
MainStageRocket = piece("MainStageRocket")
RocketCrawler = piece("RocketCrawler")
Rocket = piece("Rocket")
RocketFusionPlume = piece("RocketFusionPlume")
GroundHeatedGasRing = piece("GroundHeatedGasRing")
turbine = piece("turbine")
turbineCold = piece("turbineCold")
turbineHot = piece("turbineHot")
fireCloud = piece("GroundGases")
LaunchCone = piece("LaunchCone")

SpaceHarbour = piece("SpaceHarbour")
CapsuleCrane = piece("CapsuleCrane")

CrawlerMain = piece("CrawlerMain")
LaunchCone = piece("LaunchCone")
Rocket = piece("Rocket")
MainStage = piece("MainStage")
CraneHead = piece("CraneHead")
RocketCraneBase = piece("RocketCrane")
CraneRocket = piece("CraneRocket")
CraneCapsule = piece("CraneCapsule")

myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage)
end
function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TableOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    initialSetup()
    StartThread(launchAnimation)
    StartThread(traffic)
    StartThread(foldFuelTowers)
end

function initialSetup()
    resetAll(unitID)
    showT(TableOfPiecesGroups[GroundRearDoorN])
    showT(TableOfPiecesGroups[GroundFrontDoorN])
    showT(TableOfPiecesGroups[CraneHeadClawN])
    Show(turbineCold)
    Show(CraneHead)
    showT(TableOfPiecesGroups[BoosterCrawlerN])
    Show(CrawlerMain)
    Show(CapsuleCrane)
    Show(RocketCraneBase)
    Show(SpaceHarbour)
    Move(CapsuleCrane, x_axis, -5000, 0)
    HideRocket()
end
doorSpeed = 70
function openDoor(name)
    foreach(
        TableOfPiecesGroups[name],
        function(id)
            if id then
                WMove(id, x_axis, -600, doorSpeed)
            end
        end
    )
    WaitForMoves(TableOfPiecesGroups[name])
end

function closeDoor(name)
     foreach(
        TableOfPiecesGroups[name],
        function(id)
            if id then
                WMove(id, x_axis, 0, doorSpeed)
            end
        end
    )  
end


boosterReturned = {}
function BoostersReturning()
    --Booster decoupling
    hideT(TableOfPiecesGroups[BoosterN])
    hideT(TableOfPiecesGroups[RocketThrustPillarN])


    for i=1, 3 do        
        boosterReturned[i] = false
       StartThread(landBooster, i, TableOfPiecesGroups["ReturningBooster"][i])
    end

    Sleep(1000)
    while (holdsForAllBool(boosterReturned, false)) do
        Sleep(1000)
    end
    closeDoor(GroundRearDoorN)
end

crawlerSpeed = 750
function boosterArrivedTravelIntoHangar(boosterNr)

    openDoor(GroundRearDoorN)
    rest =7000*boosterNr^2 or 10000
    Sleep(rest)
    if boosterNr == 1 or boosterNr == 3 then
        turnSign = -1 
        if boosterNr == 3 then turnSign = 1 end
        WTurn(TableOfPiecesGroups[CrawlerBoosterN][boosterNr], y_axis, math.rad(90 * turnSign), 0.1)
    else
        WMove(TableOfPiecesGroups[CrawlerBoosterN][boosterNr], x_axis, -19000, crawlerSpeed)
    end
    Sleep(2000)
    Hide(TableOfPiecesGroups[LandedBoosterN][boosterNr])
    Sleep(3000)

    WMove(TableOfPiecesGroups[CrawlerBoosterN][boosterNr], x_axis, 0, crawlerSpeed)
    WTurn(TableOfPiecesGroups[CrawlerBoosterN][boosterNr], y_axis, math.rad(0), 0.1)

    boosterReturned[boosterNr] = true
end

function getPlum(boosterNr)
    if boosterNr == 1 then
        assertTable( TableOfPiecesGroups[ReturningBooster1ThrusterPlumN])
        return TableOfPiecesGroups[ReturningBooster1ThrusterPlumN]
    end  
    if boosterNr == 2 then
        assertTable(TableOfPiecesGroups[ReturningBooster2ThrusterPlumN])
        return TableOfPiecesGroups[ReturningBooster2ThrusterPlumN]
    end
    if boosterNr == 3 then
        assertTable(TableOfPiecesGroups[ReturningBooster3ThrusterPlumN])
        return TableOfPiecesGroups[ReturningBooster3ThrusterPlumN]
    end
    assert(nil, boosterNr .." not real")
end


function landBooster(boosterNr, booster)
    resttime = boosterNr*15000
    LandCone = TableOfPiecesGroups["LandCone"][boosterNr]
    axis = 2
    Sleep(resttime)
    plums = getPlum(boosterNr)
    assert(plums)
    booster = TableOfPiecesGroups[ReturningBoosterN][boosterNr]
    assert(booster)
    nextPos = 64000
    boosterRotator = TableOfPiecesGroups[BoosterRotatorN][boosterNr]
    assert(boosterRotator)
    WMove(booster, axis, nextPos, 0)
    --Turn(boosterRotator, x_axis, math.rad(-5), 0)
    Show(booster)
    --Turn(boosterRotator, x_axis, math.rad(0), 0.001)
   
    for i = nextPos, 2000, -2000 do
        Move(booster, axis, i, 4000)
        Sleep(1)
        WaitForMoves(booster)
    end
    Show(LandCone)
    Show(TableOfPiecesGroups[CrawlerBoosterGasRingN][boosterNr])
    Spin(TableOfPiecesGroups[CrawlerBoosterGasRingN][boosterNr], y_axis, math.rad(690), 0)
    showT(plums)
    Show(LandCone)
    Turn(booster, x_axis, math.rad(0), 0.5)
    Turn(booster, y_axis, math.rad(0), 3)
    for i= 2000, 0, -10 do
       WMove(booster, axis, i, 500)

       spinVal = math.random(40, 120)*randSign()
       Spin(LandCone, y_axis, math.rad(spinVal))

       spinVal = math.random(40, 120)*randSign()
       turnT(plums, y_axis, math.rad(spinVal))
       spinT(plums, y_axis, math.rad(spinVal))
       spinVal = math.random(40, 120)*randSign()
       Spin(LandCone, y_axis, math.rad(spinVal))
    end  

    Hide(TableOfPiecesGroups[CrawlerBoosterGasRingN][boosterNr])
    assert(plums)
    hideT(plums)
    Hide(LandCone)
    Hide(booster)
    assert(TableOfPiecesGroups[LandedBoosterN])
    Show(TableOfPiecesGroups[LandedBoosterN][boosterNr])
    boosterArrivedTravelIntoHangar(boosterNr)
end

function script.Killed(recentDamage, _)
    return 1
end

function plattFormFireBloom()
    Show(LaunchCone)
    Move(fireCloud, y_axis, -250, 0)
    Show(fireCloud)
    Move(fireCloud, y_axis, 3000, 1200)

    while launchState == "launching" do
        rVal = math.random(300,950) *randSign()
        Spin(fireCloud, y_axis, math.rad(rVal), 0)
        rVal = math.random(50,150) *randSign()
        Spin(LaunchCone, y_axis, math.rad(rVal), 0)
        shift = 360 / #TableOfPiecesGroups["FireFlower"]
        for i = 1, #TableOfPiecesGroups["FireFlower"] do
            cycle = TableOfPiecesGroups["FireFlower"][i]
            Show(cycle)
            rotation = math.random(-360,360)
            Turn(cycle, y_axis, math.rad(rotation), 0)
            startVal = 90 + randSign() * 90
            Turn(cycle, x_axis, math.rad(startVal), 360) --reset
            val =math.random(50,250)*randSign()
            Spin(cycle, y_axis, val, fireBloomSpeed)
        end
        hideT(TableOfPiecesGroups["FireFlower"])
        Sleep(3000)
    end

end

function plattformFireBloomCleanup()
    foreach(
        TableOfPiecesGroups["FireFlower"],
        function(id)
            Hide(id)
            StopSpin(id, x_axis, 0)
        end
    )
    Hide(LaunchCone)
    Hide(fireCloud)
    Hide(GroundHeatedGasRing)
    hideT(TableOfPiecesGroups["FireFlower"])
end


function liftRocketShowStage(distanceUp, timeUp, cloud, spinValue, startValue)
    Show(cloud)
    Spin(cloud, y_axis, math.rad(spinValue), startValue)
    mSyncIn(Rocket, 0, distanceUp, 0, timeUp)
    WaitForMoves(Rocket)
end


function spinUpTurbine()
    Spin(turbine, y_axis, math.rad(42), 0.1)
    Show(turbineCold)
    Sleep(4000)
    Show(turbineHot)
    Hide(turbineCold)
    

end

function driveOutMainStage()
    Show(CrawlerMain)
    Show(RocketCrawler)
    openDoor(GroundFrontDoorN)
    WMove(CrawlerMain, x_axis, -6825, 6825 / 30.0)
end

function driveBackCrawler()
    WMove(CrawlerMain, x_axis, 0, 6825 / 30.0)
    closeDoor(GroundFrontDoorN)
end

function ShowRocket()
    Show(MainStage)
    Show(MainStageRocket)
    showT(TableOfPiecesGroups[BoosterN])
end
crawlerRocketPosY = -63.17
RocketOnPlatformPos = 0
CraneOutOfTheWayPos = 25
function openClaw()
    Turn(TableOfPiecesGroups[CraneHeadClawN][1], y_axis, math.rad(65), 5)
    Turn(TableOfPiecesGroups[CraneHeadClawN][2], y_axis, math.rad(-65), 5)
    Turn(TableOfPiecesGroups[CraneHeadClawN][3], y_axis, math.rad(65), 5)
    Turn(TableOfPiecesGroups[CraneHeadClawN][4], y_axis, math.rad(-65), 5)
    WaitForTurnT(TableOfPiecesGroups[CraneHeadClawN])
end

function closeClaw()
    Turn(TableOfPiecesGroups[CraneHeadClawN][1], y_axis, math.rad(0), 1)
    Turn(TableOfPiecesGroups[CraneHeadClawN][2], y_axis, math.rad(0), 1)
    Turn(TableOfPiecesGroups[CraneHeadClawN][3], y_axis, math.rad(0), 1)
    Turn(TableOfPiecesGroups[CraneHeadClawN][4], y_axis, math.rad(0), 1)
    WaitForTurnT(TableOfPiecesGroups[CraneHeadClawN])
end

function craneLoadToPlatform()
    echoEnter("craneLoadToPlatform")
    openClaw()
    WTurn(CraneHead, y_axis, math.rad(crawlerRocketPosY), 0.1)
    closeClaw()
    Hide(RocketCrawler)
    Show(CraneRocket)

    StartThread(unfoldFuelTowers)
    StartThread(driveBackCrawler)
    WTurn(CraneHead, y_axis, math.rad(RocketOnPlatformPos), 0.1)
    Hide(CraneRocket)   
    ShowRocket()
    openClaw()
    Move(RocketCraneBase, z_axis, -4500, 100)
    deployCapsule()
    Turn(CraneHead, y_axis, math.rad(CraneOutOfTheWayPos), 0.1)
    WTurn(CraneHead, y_axis, math.rad(CraneOutOfTheWayPos), 0.1)
    WMove(RocketCraneBase, z_axis, -4500, 15)
    StartThread(foldFuelTowers)
    closeDoor(GroundFrontDoorN)

end

function unfoldFuelTowers()
    resetT(TableOfPiecesGroups["FuelCrane"], 5.0)
    resetT(TableOfPiecesGroups["FuelCraneHead"], 5.0)
    WaitForTurns(TableOfPiecesGroups["FuelCrane"])
    WaitForTurns(TableOfPiecesGroups["FuelCraneHead"])
end

function foldFuelTowers()
    showT(TableOfPiecesGroups["FuelCrane"])
    showT(TableOfPiecesGroups["FuelCraneHead"])
    Turn(TableOfPiecesGroups["FuelCrane"][1],z_axis, math.rad(-80), 5.0)
    Turn(TableOfPiecesGroups["FuelCraneHead"][1],z_axis, math.rad(80), 5.0)
Turn(TableOfPiecesGroups["FuelCrane"][2],x_axis, math.rad(80), 5.0)
    Turn(TableOfPiecesGroups["FuelCraneHead"][2],x_axis, math.rad(-80), 5.0)
end

function deployCapsule()
    WMove(CapsuleCrane, x_axis, -5000, 0)
    Show(CraneCapsule)
    WMove(CapsuleCrane, x_axis, 0, 5000 / 30)
    Hide(CraneCapsule)
    Show(CapsuleRocket)
    WMove(CapsuleCrane, x_axis, -5000, 5000 / 10)

end

--thrusterCloud
launchState = "prepareForLaunch"
rocketPlumage = RocketPlumeN

function launchAnimation()
    while true do
             if maRa() then
            rocketPlumage = RocketPlumeN
        else
            rocketPlumage = RocketPlumeAN
        end
        echo("driveOutMainStage")
        driveOutMainStage()
        craneLoadToPlatform()
        echoEnter("showHotColdTurbine")
        launchState = "launching"
        StartThread(spinUpTurbine)
        --Inginition
        -- plattform firebloom
        Spring.PlaySoundFile("sounds/launcher/start"..math.random(1,2)..".ogg", 1.0)
        StartThread(plattFormFireBloom)
        --Trusters
        --assert(TableOfPiecesGroups[RocketThrustPillarN])
        showT(TableOfPiecesGroups[RocketThrustPillarN])
        foreach(
            TableOfPiecesGroups[RocketThrustPillarN],
            function(id)
                val = math.random(-50, 50)
                Spin(id, y_axis, math.rad(val), 50)
            end
        )
        
        destroyUnitsNearby()

        if maRa() then
            rocketPlumage = RocketPlumeN
        else
            rocketPlumage = RocketPlumeAN
        end

        Show(GroundHeatedGasRing)
        Spin(GroundHeatedGasRing,y_axis,math.rad(66),0)

        --Lift rocket (rocket is slow and becomes faster)
        liftRocketShowStage(3000, 1500, TableOfPiecesGroups[rocketPlumage][1], math.random(35, 45)*randSign()/10, 13)
        --Lift rocket
        liftRocketShowStage(12000, 2000, TableOfPiecesGroups[rocketPlumage][2], math.random(20, 30)*randSign()/10, 11)
        -- Stage2 smoke Spin
        --Lift Rocket
        -- Stage2 smoke Spin
        --Lift Rocket
        liftRocketShowStage(18000, 2000, TableOfPiecesGroups[rocketPlumage][3], math.random(10, 20)*randSign()/10, 5)
        -- Stage3 smoke Spin
        --Lift Rocket
        plattformFireBloomCleanup()
        liftRocketShowStage(32000, 2000, TableOfPiecesGroups[rocketPlumage][4], math.random(5, 15)*randSign()/10, 3)
        liftRocketShowStage(58000, 2000, TableOfPiecesGroups[rocketPlumage][5], math.random(3, 8)*randSign()/10, 1)
        -- Stage4 smoke Spin
        -- Decoupling thrusters
        StartThread(BoostersReturning)
        --Launchplum sinking back into Final Stage
        StartThread(cloudFallingDown)
        --Slight Slowdown
        Show(RocketFusionPlume)
        Sleep(500)
        --Fusion Engine kicks in 

        WMove(MainStage, y_axis, 92000, 16000)
        Sleep(9000)
        Hide(RocketFusionPlume)
        HideRocket()
        echo("launch complete waiting for return")
        --Moving CrawlerMain back to reassembly
        launchState = "recovery"
        WMove(RocketCraneBase, z_axis, 0, 15)
        watchDog = 90000
        while (holdsForAllBool(boosterReturned, false) or watchDog > 0) do
            Sleep(1000)
            watchDog = watchDog-1000
        end
        launchState = "prepareForLaunch"

        initialSetup()
    end
end

function cloudFallingDown()
    hideT(TableOfPiecesGroups["FireFlower"])
    Move(Rocket,y_axis, 0, 100)
    for i =  1, #TableOfPiecesGroups[rocketPlumage] do
        if TableOfPiecesGroups[rocketPlumage][i+1] then
            Move(TableOfPiecesGroups[rocketPlumage][i+1], y_axis, i*4500, 4500)
        end
        WMove(TableOfPiecesGroups[rocketPlumage][i], y_axis, -i*4500, 4500)
        Hide(TableOfPiecesGroups[rocketPlumage][i])
    end
    Sleep(4000)
    Hide(turbineHot)
    Show(turbineCold)
    StopSpin(turbine, y_axis, 0.0001)
    Sleep(9000)
    Turn(turbine, y_axis, 0, 3)
end


function HideRocket()
    Hide(MainStage)
    Hide(CapsuleRocket)
    Hide(MainStageRocket)
end


trafficCounter = 0

function trafficRun(index)
    if maRa() then return end
    trafficCounter = trafficCounter +1
    runner = nil
    turnSign= -1
    if maRa() then
        runner = TableOfPiecesGroups["ClockWise"][index]
    else
        turnSign= 1
        runner = TableOfPiecesGroups["CounterClockWise"][index]
    end
    Show(runner)
    speed= 1/index

    firstPart = math.random(140, 179)*turnSign
    WTurn(runner, y_axis, math.rad(firstPart), speed)
    if maRa() then Sleep(3000) end
    secondPart = math.random(180, 290)*turnSign
    WTurn(runner, y_axis, math.rad(secondPart), speed)
    if maRa() then Sleep(3000) end
    target = 360*turnSign
    WTurn(runner, y_axis, math.rad(target), speed)
    Hide(runner)
    reset(runner)
    trafficCounter = trafficCounter-1
end

function traffic()
    while true do
        while launchState ~= "launching" do
            for i=1,4 do
                StartThread(trafficRun, i)
            end
            Sleep(100)
            while trafficCounter > 0  do
                Sleep(1000)
            end

        Sleep(1000)
        end
        Sleep(1000)
    end
end

wreckageTypeTable = getScrapheapTypeTable(UnitDefs)

function destroyUnitsNearby()
    foreach(getAllNearUnit(unitID, 350),
            function(id)
                defID = Spring.GetUnitDefID(id)
                if not wreckageTypeTable[defID] then
                    destroyUnitConditional(id, false, true)
                end
            end
            )
end