include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

padDistance = 450
x,y,z = Spring.GetUnitPosition(unitID)
isSeaUnit = 0 > Spring.GetGroundHeight(x,z)
Ground = piece("Ground")
Water = piece("Water")
function script.Create()
    echo(UnitDefs[myDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    Show(Water)

    showT(TablesOfPiecesGroups["DroneShip"])
    showT(TablesOfPiecesGroups["Capsule"])
    showT(TablesOfPiecesGroups["Gauntry"])
    if isSeaUnit then
    else
        Show(Ground)
        showT(TablesOfPiecesGroups["Chains"])
    end
    StartThread(behaviourLoop)
end
--Booster1
--Booster2
--Booster2
--SpaceX_Falcon_Heavy001
FalconX = piece("SpaceX_Falcon_Heavy001")
upaxis = y_axis
boosterArrived = {}
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

function behaviourLoop()
    while true do
        boosterArrived = {}
        for i=1, 3 do
            StartThread(landBooster, i, piece("Booster"..i), piece("RocketRotator00"..i))
        end
        Sleep(500)

        while not boosterArrived[1] or 
              not boosterArrived[2] or 
              not boosterArrived[3] do
              Sleep(100)
        end 
        Move(TablesOfPiecesGroups["DroneShip"][1],z_axis, -padDistance, 25)
        Move(TablesOfPiecesGroups["DroneShip"][2],z_axis, padDistance, 25)
        Move(TablesOfPiecesGroups["DroneShip"][3],x_axis, padDistance, 25)
        WaitForMoves(TablesOfPiecesGroups["DroneShip"])
        Show(FalconX)
        hideT(TablesOfPiecesGroups["Booster"])
        Move(TablesOfPiecesGroups["DroneShip"][1],z_axis, 0, 25)
        Move(TablesOfPiecesGroups["DroneShip"][2],z_axis, 0, 25)
        WMove(TablesOfPiecesGroups["DroneShip"][3],x_axis, padDistance*2, 25)
        Sleep(10000)
        for i=1,9000, 100 do
            WMove(FalconX, upaxis, i, 100*((i+1)/100))
        end
        Hide(FalconX)
        reset(FalconX)
        WMove(TablesOfPiecesGroups["DroneShip"][3],x_axis, 0, 25)
        Sleep(5000)
    end
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

--Inginition
    --Lift rocket (rocket is slow and becomes faster)
    --Trusters
    -- plattform firebloom
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
                


             