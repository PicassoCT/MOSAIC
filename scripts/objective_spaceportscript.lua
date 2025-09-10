include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_debug.lua"
--include "lib_Build.lua"

local TableOfPiecesGroups = {}

local ReturningBooster1ThrusterPlumN = "ReturningBooster1ThrusterPlum"
local ReturningBooster2ThrusterPlumN = "ReturningBooster2ThrusterPlum"
local ReturningBooster3ThrusterPlumN = "ReturningBooster3ThrusterPlum"
local CapsuleRocket = piece "CapsuleRocket"

local BoosterN = "Booster"
local RocketThrustPillarN = "RocketThrustPillar"
local FusionLandingGearN = "FusionLandingGear"
local LandedBoosterN = "LandedBooster"
local RocketPlumeN = "RocketPlume"
local RocketPlumeAN = "RocketPlumeA"
local FireFlowerN = "FireFlower"
local GroundRearDoorN = "GroundRearDoor"
local GroundFrontDoorN = "GroundFrontDoor"
local CraneHeadClawN = "CraneHeadClaw"
local FireFlowerRotatorN = "FireFlowerRotator"
local BoosterN = "Booster"
local ReturningBoosterN = "ReturningBooster"
local BoosterCrawlerN = "CrawlerBooster"
local CrawlerBoosterN = "CrawlerBooster"
local CrawlerBoosterGasRingN = "CrawlerBoosterGasRing"
local CrawlerBoosterRingN = "CrawlerBoosterRing"
local CrawlerSmokeRingN = "CrawlerSmokeRing"
local BoosterRotatorN = "BoosterRotator"
local MainStageRocket = piece("MainStageRocket")
local RocketCrawler = piece("RocketCrawler")
local Rocket = piece("Rocket")
local RocketFusionPlume = piece("RocketFusionPlume")
local GroundHeatedGasRing1 = piece("GroundHeatedGasRing1")
local GroundHeatedGasRing2 = piece("GroundHeatedGasRing2")
local turbine = piece("turbine")
local turbineCold = piece("turbineCold")
local turbineHot = piece("turbineHot")
local fireCloud = piece("GroundGases")
local LaunchCone = piece("LaunchCone")

local SpaceHarbour = piece("SpaceHarbour")
local CapsuleCrane = piece("CapsuleCrane")
local CrawlerMain = piece("CrawlerMain")
local LaunchCone = piece("LaunchCone")
local Rocket = piece("Rocket")
local MainStage = piece("MainStage")
local CraneHead = piece("CraneHead")
local RocketCraneBase = piece("RocketCrane")
local CraneRocket = piece("CraneRocket")
local CraneCapsule = piece("CraneCapsule")
local FireTruckRotator = piece("FireTruckRotator")
local FireTruck = piece("FireTruck")


function script.HitByWeapon(x, z, weaponDefID, damage)
end
function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TableOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    Show(FireTruck)
    initialSetup()
    StartThread(launchAnimation)
    StartThread(traffic)
    StartThread(foldFuelTowers)
    StartThread(forkLiftOS)
    StartThread(fireTruckRoundOS)

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
    doorClosed[name] = false
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
     doorClosed[name] = true
end


boosterReturned = {}
function BoostersReturning()
    --Booster decoupling
    hideT(TableOfPiecesGroups[BoosterN])
    hideT(TableOfPiecesGroups[RocketThrustPillarN])


    for i=1, 3 do        
        boosterReturned[i] = false
       StartThread(landBooster, i)
    end

    Sleep(1000)
    while (holdsForAllBool(boosterReturned, false)) do
        Sleep(1000)
    end

end

crawlerSpeed = 750
function boosterArrivedTravelIntoHangar(boosterNr)


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
    StartThread(UnloadBooster)
    Hide(TableOfPiecesGroups[LandedBoosterN][boosterNr])
    Sleep(3000)

    WMove(TableOfPiecesGroups[CrawlerBoosterN][boosterNr], x_axis, 0, crawlerSpeed)
    WTurn(TableOfPiecesGroups[CrawlerBoosterN][boosterNr], y_axis, math.rad(0), 0.1)

    boosterReturned[boosterNr] = true
end

function getPlum(boosterNr)
    if boosterNr == 1 then
        return TableOfPiecesGroups[ReturningBooster1ThrusterPlumN]
    end  
    if boosterNr == 2 then
        return TableOfPiecesGroups[ReturningBooster2ThrusterPlumN]
    end
    if boosterNr == 3 then
        return TableOfPiecesGroups[ReturningBooster3ThrusterPlumN]
    end
    assert(nil, boosterNr .." not real")
end

forkLiftHasCargo = {}

function isAtEdge(z,x)
    if (z > 5500 or z < -5500) or ( x < -700 or x > 700 ) then
        return true    
    end
    return false
end

function dropCargo( goalZ, goalX, selectedForkLift )
    Hide(TableOfPiecesGroups["ForkLiftCargoUp"][selectedForkLift])
    Show(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift])
    Move(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift],y_axis, goalZ, 0)
    Move(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift],x_axis, goalX, 0)
    forkLiftHasCargo[selectedForkLift] = false
end

function pickUpCargo(selectedForkLift)
    Show(TableOfPiecesGroups["ForkLiftCargoUp"][selectedForkLift])
    Hide(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift])
    forkLiftHasCargo[selectedForkLift] = true
end

function fireTruckRoundOS()
    Show(FireTruck)
    while true do
        while (holdsForAllBool(boosterReturned, false)) do 
            while boolBackDoorOpen == false do Sleep(500) end           
            WMove(FireTruckRotator, y_axis, -3000, 500)
            WTurn(FireTruckRotator, y_axis, math.rad(-33), 0.25)
            restTime = math.random(1,15) * 1000
            Sleep(restTime)
            WTurn(FireTruckRotator, y_axis, math.rad(-133), 0.25)
            restTime = math.random(1,15) * 1000
            Sleep(restTime)
            WTurn(FireTruckRotator, y_axis, math.rad(-180), 0.25)
            WMove(FireTruckRotator, y_axis, 0, 500)
            WTurn(FireTruckRotator, y_axis, math.rad(-181), 0.25)
            while boolBackDoorOpen == false do Sleep(500) end
            WTurn(FireTruckRotator, y_axis, math.rad(-360), 0.25)
            Turn(FireTruckRotator, y_axis, math.rad(0), 0)
            restTime = math.random(1,15) * 1000
            Sleep(restTime)
        end
        Sleep(10000)
    end
end

function forkLiftDo(selectedForkLift)
        if launchState == "launching" then return end
        forkLift = TableOfPiecesGroups["Forklift"][selectedForkLift]
        Show(forkLift)
        goalZ= math.random(0, 6000)*randSign()
        goalX= math.random(0, 750)*randSign()

         if not forkLiftHasCargo[selectedForkLift] and randChance(10) then
            goalZ= math.random(5500, 6000)*randSign()
            goalX= math.random(650, 750)*randSign()
         end

        if not forkLiftHasCargo[selectedForkLift] and isAtEdge(goalZ, goalX) then   
            Hide(TableOfPiecesGroups["ForkLiftCargoUp"][selectedForkLift]) 
            Show(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift])
            Move(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift],y_axis, goalZ, 0)
            Move(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift],x_axis, goalX, 0)
            WMove(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift],z_axis, -100, 0)
            Move(TableOfPiecesGroups["ForkLiftCargoDown"][selectedForkLift],z_axis, 0, 50)
        end

        Turn(forkLift,y_axis, randSign()*math.pi*2, 5)
        WMove(forkLift,y_axis, goalZ, 750)

        if launchState == "launching" then return end
     
        Turn(forkLift,y_axis, randSign()*math.pi*0.5, 5)
       
        WMove(forkLift,x_axis, goalX, 750)

        if isAtEdge(goalZ, goalX) then
            if forkLiftHasCargo[selectedForkLift] then 
                dropCargo(goalZ, goalX, selectedForkLift)
            else
                pickUpCargo(selectedForkLift)
            end
        end
    end

function forkLiftOS()
    Sleep(500)
    hideT(TableOfPiecesGroups["ForkLiftCargoDown"])
    showT(TableOfPiecesGroups["ForkLiftCargoUp"])
    local forkLifts = TableOfPiecesGroups["Forklift"]
    for i=1,3 do         forkLiftHasCargo[i] = true; end

    while true do
        while launchState ~= "launching" do
            for i=1,3 do
                StartThread(forkLiftDo, i)
            end
            Sleep(100)
            for i=1,3 do
                WaitForTurns(forkLifts[i])
                WaitForMoves(forkLifts[i])
                WaitForTurns(forkLifts[i])
            end
            Sleep(3000)
        end
        Turn(forkLift,y_axis, randSign()*math.pi*2, 5)
        resetT(forkLifts, 750)
        Sleep(5000)
    end
end
LoadCrane = piece("LoadCrane")
LoadCraneNight = piece("LoadCraneNight")
LoadCraneDay = piece("LoadCraneDay")
PickUpBoosterDay = piece("PickUpBoosterDay")
PickUpBoosterNight = piece("PickUpBoosterNight")

travelAxis = y_axis
function PrepareUnloadBooster()
    Move(LoadCrane, travelAxis, 1000, 0)
    Hide(PickUpBoosterDay)
    Hide(PickUpBoosterNight)
    Hide(LoadCraneDay)
    Show(LoadCraneNight)
    WMove(LoadCrane,travelAxis, 500, 100)
    Hide(LoadCraneNight)
    Show(LoadCraneDay)
    WMove(LoadCrane,travelAxis, 0, 100)
end

function UnloadBooster()
    Show(PickUpBoosterDay)
    WMove(LoadCrane, travelAxis, 500, 100)
    Show(LoadCraneNight)
    Hide(LoadCraneDay)
    Hide(PickUpBoosterDay)
    Show(PickUpBoosterNight)
    WMove(LoadCrane,travelAxis, 1000, 100)
    Hide(PickUpBoosterDay)
    PrepareUnloadBooster()
end

function lightUpPad(cone, lengthOfTimeMs)
    for w = 1, lengthOfTimeMs, 300 do
        EmitSfx(cone,1024)
        Sleep(300)
    end
end

function showBoosterSmokeRing(nr)    
    reset(TableOfPiecesGroups[CrawlerSmokeRingN][nr])
    boosterSmokeRingHeight = 1500
    Move(TableOfPiecesGroups[CrawlerSmokeRingN][nr], downAxis, -boosterSmokeRingHeight, 0)
    Sleep(500)
    Show(LandCone)
    Sleep(350)
    Show(TableOfPiecesGroups[CrawlerBoosterGasRingN][boosterNr]) 
    Show(TableOfPiecesGroups[CrawlerBoosterRingN][boosterNr]) 
    Sleep(500)

    downAxis = 2
    val = math.random(42, 80) * randSign()
    Show(TableOfPiecesGroups[CrawlerSmokeRingN][nr])
    Spin(TableOfPiecesGroups[CrawlerSmokeRingN][nr],y_axis, math.rad(val), 0)
    Spin(TableOfPiecesGroups[CrawlerSmokeRingN][nr],x_axis, math.rad(0.5)*randSign(), 0)
    Spin(TableOfPiecesGroups[CrawlerSmokeRingN][nr],z_axis, math.rad(0.5)*randSign(), 0)
    mSyncIn(TableOfPiecesGroups[CrawlerSmokeRingN][nr], 0, 0, 0, 3500)
    Sleep(5000)   
    StopSpin(TableOfPiecesGroups[CrawlerSmokeRingN][nr],x_axis, 0)
    Turn(TableOfPiecesGroups[CrawlerSmokeRingN][nr],x_axis , math.rad(0), 0.5)
    Spin(TableOfPiecesGroups[CrawlerSmokeRingN][nr],z_axis, math.rad(0.5)*randSign(), 0)
    Turn(TableOfPiecesGroups[CrawlerSmokeRingN][nr],z_axis , math.rad(0), 0.5)
    mSyncIn(TableOfPiecesGroups[CrawlerSmokeRingN][nr], 0, -boosterSmokeRingHeight, 0, 11500)
    WaitForMoves(TableOfPiecesGroups[CrawlerSmokeRingN][nr])
    Hide(TableOfPiecesGroups[CrawlerSmokeRingN][nr])
    Hide(TableOfPiecesGroups[CrawlerBoosterGasRingN][boosterNr]) 
    Hide(LandCone)  
end

boolBackDoorOpen = false
function landBooster(boostNr)
    axis = 2
    local boosterNr = boostNr
    local booster = TableOfPiecesGroups[ReturningBoosterN][boosterNr]
    local boosterRotator = TableOfPiecesGroups[BoosterRotatorN][boosterNr]
    local nextPos = 64000
    StartThread(openDoor, GroundRearDoorN)
    boolBackDoorOpen= true
    StartThread(PrepareUnloadBooster)
    WMove(booster, axis, upDistance , 0)
    WTurn(boosterRotator,1, math.rad(-15),0)
    Turn(boosterRotator, 1, math.rad(0),0.0125)
    Show(booster)
    for i=0, math.pi*0.5, 0.1 do
        val = math.sin(i)
        target  = upDistance + val * (64000-upDistance)
        WMove(booster, axis, target ,  math.max(1000,(1- val)*6000))
    end
 
    local LandCone = TableOfPiecesGroups["LandCone"][boosterNr]
    local plums = getPlum(boosterNr)
   
    for i = upDistance, 2000, -2000 do
        Move(booster, axis, i, 6000)
        Sleep(1)
        WaitForMoves(booster)
        if i <= 4000 then
            showT(plums)
        end
    end
    StartThread(lightUpPad, LandCone, 6000)
   
    val =math.random(300,500)
    Spin(TableOfPiecesGroups[CrawlerBoosterRingN][boosterNr], y_axis, math.rad(val)*randSign(), 0)
    Spin(TableOfPiecesGroups[CrawlerBoosterGasRingN][boosterNr], y_axis, math.rad(690), 0)

    Turn(booster, x_axis, math.rad(0), 0.5)
    Turn(booster, y_axis, math.rad(0), 3)
    Turn(boosterRotator, x_axis, math.rad(0),5)

    StartThread(showBoosterSmokeRing, boostNr)

    for i= 2000, 0, -10 do
        WMove(booster, axis, i, math.max(i*3, 1200))
        spinVal = math.random(40, 120)*randSign()
        Spin(LandCone, y_axis, math.rad(spinVal))
        for k=1, #plums do
            Move(plums[k], y_axis, math.random(-20,20), 0)
        end
        spinVal = math.random(40, 120)*randSign()
      
 
        if maRa() then
           rot = math.random(0,1)*180
           Turn(TableOfPiecesGroups[CrawlerBoosterRingN][boosterNr], x_axis, math.rad(rot),0)
        end
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
    Show(TableOfPiecesGroups[LandedBoosterN][boosterNr])

    Hide(TableOfPiecesGroups[CrawlerBoosterRingN][boosterNr])
    resttime = (boosterNr-1)*15000
    Sleep(resttime)
    assert(TableOfPiecesGroups[LandedBoosterN])
    boosterArrivedTravelIntoHangar(boosterNr)
end

function script.Killed(recentDamage, _)
    return 1
end

ArenaSmoke = piece("ArenaSmoke")
function plattFormFireBloom()
    Show(LaunchCone)
    Move(fireCloud, y_axis, -250, 0)
    Show(fireCloud)
    Move(fireCloud, y_axis, 3000, 1200)

    while launchState == "launching"  do
        
        rVal = math.random(300,950) *randSign()
        Spin(fireCloud, y_axis, math.rad(rVal), 0)
        rVal = math.random(50,150) *randSign()
        Spin(LaunchCone, y_axis, math.rad(rVal), 0)
        shift =  360 / 5
        for i = 1, 5 do
            rotator = TableOfPiecesGroups["FireFlowerRotator"][i]
            cycle = TableOfPiecesGroups["FireFlower"][i]
            randoVal= math.random(-15,15)
            turnVal = shift*i + randoVal
            Turn(rotator, z_axis, math.rad(turnVal), 9000)
            Spin(cycle,z_axis, math.rad(1800), 1200)
            Show(cycle)       
        end       
        Sleep(800)
        stopSpinT(TableOfPiecesGroups["FireFlower"], z_axis)
        resetT(TableOfPiecesGroups["FireFlower"])
    end
    hideT(TableOfPiecesGroups["FireFlower"])
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
    Hide(GroundHeatedGasRing1)
    Hide(GroundHeatedGasRing2)
    hideT(TableOfPiecesGroups["FireFlower"])
    hideT(TableOfPiecesGroups["FireFlowerRotator"])
end


function liftRocketShowStage(distanceUp, timeUp, cloud, spinValue, startValue)
    Show(cloud)
    Spin(cloud, y_axis, math.rad(spinValue), startValue)
    mSyncIn(Rocket, 0, distanceUp, 0, timeUp)
    WaitForMoves(Rocket)
end


function spinUpTurbine()
    Move(ArenaSmoke, y_axis, -900, 0)
    Show(ArenaSmoke)
    Move(ArenaSmoke, y_axis, 0, 25)
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

doorClosed = {}
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
rocketCraneBaseSpeed= 200
function craneLoadToPlatform()
--    echoEnter("craneLoadToPlatform")
    openClaw()
    WTurn(CraneHead, y_axis, math.rad(crawlerRocketPosY), 0.1)
    closeClaw()
    Hide(RocketCrawler)
    Show(CraneRocket)


    StartThread(driveBackCrawler)
    WTurn(CraneHead, y_axis, math.rad(RocketOnPlatformPos), 0.1)

    Hide(CraneRocket)   
    ShowRocket()
    unfoldFuelTowers()
    openClaw()
    deployCapsule()
    WMove(RocketCraneBase, z_axis, -4500, rocketCraneBaseSpeed)
    WTurn(CraneHead, y_axis, math.rad(crawlerRocketPosY), 0.1)
    WMove(RocketCraneBase, z_axis, -4500, rocketCraneBaseSpeed)
    StartThread(closeDoor, GroundFrontDoorN)
    foldFuelTowers()
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

function RandomRocketPlumage()
    if maRa() then
        return RocketPlumeN
    else
        return RocketPlumeAN
    end
end

function getRandomizedPlumageTable()
    Plumage = {}
    for i=1, 5 do
        Plumage[i] = TableOfPiecesGroups[RandomRocketPlumage()][i]
    end
    return Plumage
end

--thrusterCloud
launchState = "prepareForLaunch"
rocketPlumage = RocketPlumeN
local GameConfig = getGameConfig()
upDistance = 58000
function launchAnimation()
    StartThread(vtolLoop)
    while true do
        while GG.GlobalGameState == GameConfig.GameState.normal do
            local plumageTable = getRandomizedPlumageTable()
            --echo("driveOutMainStage")
            driveOutMainStage()
            craneLoadToPlatform()
            --echoEnter("showHotColdTurbine")
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

            Show(GroundHeatedGasRing1)
            Spin(GroundHeatedGasRing1,y_axis,math.rad(66),0)
            Show(GroundHeatedGasRing2)
            Spin(GroundHeatedGasRing2,y_axis,math.rad(66)*randSign(),0)
            destroyUnitsNearby()

            --Lift rocket (rocket is slow and becomes faster)
            liftRocketShowStage(3000, 1500, plumageTable[1], math.random(35, 45)*randSign(), 13)
            --Lift rocket
            liftRocketShowStage(12000, 2000, plumageTable[2], math.random(20, 30)*randSign(), 11)
            -- Stage2 smoke Spin
            --Lift Rocket
            -- Stage2 smoke Spin
            --Lift Rocket
            liftRocketShowStage(18000, 2000, plumageTable[3], math.random(10, 20)*randSign(), 5)
            -- Stage3 smoke Spin
            --Lift Rocket
            plattformFireBloomCleanup()
            liftRocketShowStage(32000, 2000, plumageTable[4], math.random(5, 15)*randSign(), 3)
            liftRocketShowStage(upDistance, 2000, plumageTable[5], math.random(3, 8)*randSign(), 1)
            -- Stage4 smoke Spin
            -- Decoupling thrusters
            destroyUnitsNearby()

            StartThread(BoostersReturning)
            --Launchplum sinking back into Final Stage
            StartThread(cloudFallingDown, 
                TableOfPiecesGroups["RocketScience"], 
                plumageTable, 
                TableOfPiecesGroups["RocketPlumeB"] )
            --Slight Slowdown
            Show(RocketFusionPlume)
            Sleep(500)
            --Fusion Engine kicks in 
            
            launchState = "recovery"
            WMove(MainStage, y_axis, 92000, 16000)
            Sleep(9000)
            Hide(RocketFusionPlume)
            HideRocket()
--            echo("launch complete waiting for return")
            --Moving CrawlerMain back to reassembly
      
            WMove(RocketCraneBase, z_axis, 0, rocketCraneBaseSpeed)
            WTurn(CraneHead, y_axis, math.rad(crawlerRocketPosY), 0.1)
            watchDog = 90000

            while (holdsForAllBool(boosterReturned, false) or watchDog > 0) do
                Sleep(1000)
                watchDog = watchDog-1000
            end
            closeDoor(GroundRearDoorN)
            boolBackDoorOpen= false
            launchState = "prepareForLaunch"

            initialSetup()
        end
        Sleep(1000)
    end
end

function vtolLoop()
    local landed = {}
    while true do
        while launchState == "prepareForLaunch" or launchState == "recovery" do
            local _, rando = randDict(TableOfPiecesGroups["VTOL"])
            if rando then
                if landed[rando] then -- start and hide
                    Show(rando)
                    Move(rando, y_axis, 4500, 1500)
                    xval = math.random(0,800) *randSign()
                    zval = math.random(0,800) *randSign()
                    Move(rando, x_axis, xval, 250)
                    Move(rando, z_axis, zval, 250)
                    WaitForMoves(rando)
                    Hide(rando)
                    landed[rando] = nil
                else
                    xval = math.random(0,800) *randSign()
                    zval = math.random(0,800) *randSign()
                    Move(rando, x_axis, xval, 0)
                    Move(rando, z_axis, zval, 0)
                    WMove(rando, y_axis, 4500, 0)
                    WaitForMoves(rando)
                    rVal = math.random(0,360)
                    Turn(rando, y_axis, math.rad(rVal),0)
                    Show(rando)
                    Move(rando, x_axis, xval, 250)
                    Move(rando, z_axis, zval, 250)
                    WaitForMoves(rando)
                    Turn(rando, y_axis, math.rad(0),10)
                    WMove(rando, y_axis, 0, 800)         
                    landed[rando] = true -- 
                end
        end
            Sleep(100)
        end
        Sleep(1000)
    end

end

function showBubbleSmoke()
    for i =  1, #TableOfPiecesGroups["SmokeBubble"] do
        smokeRotator = TableOfPiecesGroups["SmokeBubbleRotator"][i]
        smokeBubble = TableOfPiecesGroups["SmokeBubble"][i]
        spinRand(smokeBubble, -90, 90, 12)
        spinRand(smokeRotator, -90, 90, 12)
        Show (smokeBubble)
    end
end

function resetSmokeBubbles()
    hideT(TableOfPiecesGroups["SmokeBubble"])
    resetT(TableOfPiecesGroups["SmokeBubble"])
    resetT(TableOfPiecesGroups["SmokeBubbleRotator"])
end

function cloudFallingDown(cloudMovers, cloudGoingUp, cloudCoolingDown)
    --showBubbleSmoke()
    showT(cloudGoingUp)
    hideT(TableOfPiecesGroups["FireFlower"])
    Move(Rocket,y_axis, 0, 100)
    for i =  1, #cloudMovers do
        Hide(cloudGoingUp[i])
        Show(cloudCoolingDown[i])
        if cloudMovers[i+1] then
            Move(cloudMovers[i+1], y_axis, i*4500, 4500)
        end
        WMove(cloudMovers[i], y_axis, -i*4500, 5500)
        Hide(cloudCoolingDown[i])
    end
    hideT(cloudCoolingDown)
    --resetSmokeBubbles()
    Move(ArenaSmoke, y_axis, -2900, 290)
    Sleep(4000)
    Hide(turbineHot)
    Show(turbineCold)
    StopSpin(turbine, y_axis, 0.0001)
    Sleep(9000)
    Hide(ArenaSmoke)
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

    firstPart = math.random(140, 179) * turnSign
    WTurn(runner, y_axis, math.rad(firstPart), speed)
    if maRa() then Sleep(3000) end
    secondPart = math.random(180, 290) * turnSign
    WTurn(runner, y_axis, math.rad(secondPart), speed)
    if maRa() then Sleep(3000) end
    target = 360 * turnSign
    WTurn(runner, y_axis, math.rad(target), speed)
    Hide(runner)
    reset(runner)
    trafficCounter = trafficCounter-1
end

function traffic()
    while true do
        while launchState ~= "launching" do
            for i=1,4 do
                trafficRun(i)
                if launchState == "launching" then break end
            end
            Sleep(100)
        end

        Sleep(1000)
    end
end


wreckageTypeTable = getScrapheapTypeTable(UnitDefs)

function destroyUnitsNearby()
    foreach(getAllNearUnit(unitID, 350),
            function(id)
                if id ~= unitID then
                    defID = Spring.GetUnitDefID(id)
                    if not wreckageTypeTable[defID]  then
                        destroyUnitConditional(id, false, true)
                    end
                end
            end
            )
end