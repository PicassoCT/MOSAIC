include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
Rocket=""
BoosterT = {}
Flames = {}
Fusion = {}

myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end
function script.Create()
    echo(UnitDefs[myDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)

end
function landBooster( boosterNr, booster, rocket)
    boosterArrived[boosterNr] = false
    WMove(booster, upaxis, 9000, 0)
    WTurn(rocket, x_axis, math.rad(14), 0 )
    Show(booster)
    Turn (rocket, x_axis, math.rad(0), 0.0001 )
    x= 1
    for i=9000, 0, -100 do
        WMove(booster, upaxis, 9000, 1000/x)
        x  = x+1
    end
    boosterArrived[boosterNr] = true
end

function script.Killed(recentDamage, _)
    return 1
end

function plattFormFireBloom()
    Show(PlatFormCentralBloom)
    while boolLaunching do
        val = math.random(10, 77)*randSign()
        Spin(PlatFormCentralBloom,y_axis, math.rad(val),0)
        shift = 360/#TablesOfPiecesGroups["CyclesOfFire"]
        for i=1, #TablesOfPiecesGroups["CyclesOfFire"] do
            cycle = TablesOfPiecesGroups["CyclesOfFire"][i]
            Turn(cycle,y_axis, math.rad(rotation),0) 
            startVal = 90 + randSign()*90
            Turn(cycle,x_axis, math.rad(startVal),360) --reset
            Spin(cycle, x_axis, math.rad(val), fireBloomSpeed)
        end
        Sleep(9000)
    end
    StopSpins(TablesOfPiecesGroups["CyclesOfFire"])
    hideT(TablesOfPiecesGroups["CyclesOfFire"])
end

function liftRocketShowStage(distanceUp, timeUp, cloud, spinValue, startValue)
    Show(cloud)
    Spin(cloud,y_axis, math.rad(spinValue), startValue)
    moveInTime(Rocket, y_axis, distanceUp, timeUp)
    WaitForMoves(Rocket)
end

boolLaunching = false
function launchAnimation()
    boolLaunching = true
    --Inginition
    -- plattform firebloom
    StartThread(plattFormFireBloom)
    --Trusters
    showT(TablesOfPiecesGroups["Thrusters"])
    --Lift rocket (rocket is slow and becomes faster)
    liftRocketShowStage(300, 5000, TableOfPiecesGroups["cloud"][1], math.random(-10,10), 10)
        --Lift rocket
        -- Plattform smoke swirls
        -- Stage2 smoke Spin
            --Lift Rocket
            -- Stage2 smoke Spin
            --Lift Rocket
            -- Stage3 smoke Spin
            --Lift Rocket
            -- Stage4 smoke Spin
                -- Decoupling thrusters
                --Fireplum sinking back into Final Stage
                --Slight Slowdown
                --Fusion Engine kicks in
                -- Thrusters return to crawlers (copiesfrom decoupling)
                -- Landingplumes
                -- Glowing buckleup Crawler rooftop
                --Moving to reassembly
                --New Capsule



             