include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TableOfPiecesGroups = {}

ReturningBooster1ThrusterPlumN = "ReturningBooster1ThrusterPlum"
ReturningBooster2ThrusterPlumN = "ReturningBooster2ThrusterPlum"
ReturningBooster3ThrusterPlumN = "ReturningBooster3ThrusterPlum"

CapsuleRocket = piece "CapsuleRocket"

BoosterN = "Booster"
RocketThrustPillarN = "RocketThrustPillar"
FusionLandingGearN = "FusionLandingGear"
landedBoosterN = "LandedBooster"
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
GroundGases = piece("GroundGases")
CraneHead = piece("CraneHead")
RocketCraneBase = piece("RocketCrane")
CraneRocket = piece("CraneRocket")
CraneCapsule = piece("CraneCapsule")

myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage)
end
function script.Create()
    echo(UnitDefs[myDefID].name .. "has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TableOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    initialSetup()
    StartThread(launchAnimation)
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
            WMove(id, x_axis, -600, doorSpeed)
        end
    )
    WaitForMoves(TableOfPiecesGroups[name])
end

function closeDoor(name)
    resetT(TableOfPiecesGroups[name], doorSpeed)
    WaitForMoves(TableOfPiecesGroups[name])
end

index = 1
boosterReturned = {}
function BoostersReturning()
    --Booster decoupling
    hideT(TableOfPiecesGroups["CoupledBoosters"])
    hideT(TableOfPiecesGroups["ThrusterPlum"])

    foreach(
        BoosterT,
        function(booster)
            boosterReturned[index] = false
            StartThread(landBooster, index, booster)
            index = inc(index)
        end
    )
    Sleep(1000)
    while (holdsForAllBool(boosterReturned, false)) do
        Sleep(1000)
    end
end

crawlerSpeed = 1500
function boosterArrivedTravelIntoHangar(bosterNr)
    openDoor(GroundRearDoorN)
    if bosterNr == 1 or bosterNr == 2 then
        turnSign = -1 ^ boosterNr
        WTurn(TableOfPiecesGroups[CrawlerBoosterN][bosterNr], y_axis, math.rad(90 * turnSign), 5)
    else
        WMove(TableOfPiecesGroups[CrawlerBoosterN][bosterNr], x_axis, -15000, crawlerSpeed)
    end
    Sleep(2000)
    Hide(TableOfPiecesGroups[landedBoosterN][bosterNr])
    Sleep(3000)
    closeDoor(GroundRearDoorN)
    WMove(TableOfPiecesGroups[CrawlerBoosterN][bosterNr], x_axis, 0, crawlerSpeed)
    WTurn(TableOfPiecesGroups[CrawlerBoosterN][bosterNr], y_axis, math.rad(0), 5)

    boosterReturned[boosterNr] = true
end

function landBooster(boosterNr, booster)
    Sleep(boosterNr*10000)
    plums = TableOfPiecesGroups["ReturningBooster" .. bosterNr .. "ThrusterPlum"]
    booster = TableOfPiecesGroups[ReturningBoosterN][boosterNr]
    WMove(booster, y_axis, 9000, 0)
    yVal = math.random(0, 180) * randSign()
    Turn(booster, y_axis, math.rad(yVal), 0)
    xVal = math.random(-5, 5)
    Turn(booster, x_axis, math.rad(xVal), 0)
    Show(booster)
    Turn(booster, x_axis, math.rad(0), 0.001)
    Show(TableOfPiecesGroups[CrawlerBoosterGasRingN][bosterNr])
    Spin(TableOfPiecesGroups[CrawlerBoosterGasRingN][bosterNr], y_axis, math.rad(690), 0)
    x = 1
    for i = 9000, 0, -100 do
        WMove(booster, y_axis, 9000, 1000 / x)
        if i < 1000 then
            showT(plums)
            spinVal = math.random(40, 120)
            spinT(plums, y_axis, math.rad(spinVal))
            Turn(booster, x_axis, math.rad(0), 0.5)
            Turn(booster, y_axis, math.rad(0), 3)
        end
        x = x + 1
    end
    Hide(TableOfPiecesGroups[CrawlerBoosterGasRingN][bosterNr])
    hideT(plums)
    Hide(booster)
    showT(TableOfPiecesGroups[LandedBoosterN])
    boosterArrivedTravelIntoHangar(boosterNr)
end

function script.Killed(recentDamage, _)
    return 1
end

function plattFormFireBloom()
    Show(LaunchCone)
    Move(fireCloud, y_axis, -250, 0)
    Show(fireCloud)
    Spin(fireCloud, y_axis, math.rad(42), 0)
    Spin(LaunchCone, y_axis, math.rad(42), 0)
    Move(fireCloud, y_axis, 0, math.pi)

    while boolLaunching do
        val = math.random(10, 77) * randSign()
        Spin(fireCloud, y_axis, math.rad(val), 0)
        shift = 360 / #TableOfPiecesGroups["FireFlower"]
        for i = 1, #TableOfPiecesGroups["FireFlower"] do
            cycle = TableOfPiecesGroups["FireFlower"][i]
            Turn(cycle, y_axis, math.rad(rotation), 0)
            startVal = 90 + randSign() * 90
            Turn(cycle, x_axis, math.rad(startVal), 360) --reset
            Spin(cycle, x_axis, math.rad(val), fireBloomSpeed)
        end
        Sleep(9000)
    end
    foreach(
        TableOfPiecesGroups["FireFlower"],
        function(id)
            StopSpin(id, x_axis, 0)
        end
    )
    hideT(TableOfPiecesGroups["FireFlower"])
end

function liftRocketShowStage(distanceUp, timeUp, cloud, spinValue, startValue)
    Show(cloud)
    Spin(cloud, y_axis, math.rad(spinValue), startValue)
    mSyncIn(Rocket, 0, distanceUp, 0, timeUp)
    WaitForMoves(Rocket)
end

function cloudFallingDown()
    for i = #TableOfPiecesGroups[rocketPlumage], 1, -1 do
        WMove(TableOfPiecesGroups[rocketPlumage][i], y_axis, -3000, 300)
        Hide(TableOfPiecesGroups[rocketPlumage][i])
    end
end

function showHotColdTurbine()
    Sleep(4000)
    Show(turbineHot)
    Hide(turbineCold)
    while (launchState == "launching") do
        Sleep(1000)
    end
    Hide(turbineHot)
    Show(turbineCold)
    StopSpin(turbine, y_axis, 0.1)
    Sleep(9000)
    Turn(turbine, y_axis, 0, 3)
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
    StartThread(driveBackCrawler)
    WTurn(CraneHead, y_axis, math.rad(RocketOnPlatformPos), 0.1)
    Hide(CraneRocket)
    ShowRocket()
    openClaw()
    Move(RocketCraneBase, z_axis, -1000, 50)
    deployCapsule()
    Turn(CraneHead, y_axis, math.rad(CraneOutOfTheWayPos), 0.1)
    WMove(RocketCraneBase, z_axis, -1000, 50)
    Move(RocketCraneBase, z_axis, -4500, 15)
    WTurn(CraneHead, y_axis, math.rad(CraneOutOfTheWayPos), 0.1)

    Move(RocketCraneBase, z_axis, -4500, 15)
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
        echo("driveOutMainStage")
        driveOutMainStage()
        craneLoadToPlatform()
        echoEnter("showHotColdTurbine")
        Spin(turbine, y_axis, math.rad(42), 0.001)
        Show(turbineCold)
        launchState = "launching"

        --Inginition
        -- plattform firebloom

        StartThread(plattFormFireBloom)
        --Trusters
        showT(TableOfPiecesGroups["RocketThrustPillarN"])
        foreach(
            TableOfPiecesGroups["RocketThrustPillarN"],
            function(id)
                val = math.random(-50, 50)
                Spin(id, y_axis, math.rad(val), 50)
            end
        )

        if maRa() then
            rocketPlumage = RocketPlumeN
        else
            rocketPlumage = RocketPlumeAN
        end
        StartThread(showHotColdTurbine)

        --Lift rocket (rocket is slow and becomes faster)
        liftRocketShowStage(3000, 5000, TableOfPiecesGroups[rocketPlumage][1], math.random(-10, 10), 10)
        --Lift rocket
        liftRocketShowStage(12000, 8000, TableOfPiecesGroups[rocketPlumage][2], math.random(-10, 10), 10)
        -- Stage2 smoke Spin
        --Lift Rocket
        -- Stage2 smoke Spin
        --Lift Rocket
        liftRocketShowStage(18000, 8000, TableOfPiecesGroups[rocketPlumage][3], math.random(-10, 10), 10)
        -- Stage3 smoke Spin
        --Lift Rocket
        liftRocketShowStage(32000, 12000, TableOfPiecesGroups[rocketPlumage][4], math.random(-10, 10), 10)
        -- Stage4 smoke Spin
        -- Decoupling thrusters
        StartThread(BoostersReturning)
        --Launchplum sinking back into Final Stage
        StartThread(cloudFallingDown)
        --Slight Slowdown
        Show(RocketFusionPlume)
        Sleep(500)
        --Fusion Engine kicks in
        WMove(Rocket, y_axis, 64000, 100)
        Sleep(9000)
        Hide(RocketFusionPlume)
        HideRocket()
        echo("launch complete waiting for return")
        --Moving CrawlerMain back to reassembly
        launchState = "prepareForLaunch"
        WMove(RocketCraneBase, z_axis, 0, 15)
        while (holdsForAllBool(boosterReturned, false)) do
            Sleep(1000)
        end

        initialSetup()
    end
end

function HideRocket()
    Hide(MainStage)
    Hide(RocketPod)
    Hide(MainStageRocket)
end