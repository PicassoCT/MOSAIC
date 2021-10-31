include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

local myDefID = Spring.GetUnitDefID(unitID)
TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

Body = piece "Body"
Rotor = piece "Rotor"
FireEmit1 = piece "FireEmit1"
FireEmit2 = piece "FireEmit2"

function script.Create()
    Spin(Rotor, z_axis, math.rad(9000), 0)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["FireEmit"])
    StartThread(headingSoundSurveilance)
    StartThread(initialMove)
    Spring.MoveCtrl.SetAirMoveTypeData(unitID, "attackSafetyDistance", 2048 )
    Spring.MoveCtrl.Disable(unitID, true)
    setUnitNeverLand(unitID, true)
end

function initialMove()
    waitTillComplete(unitID)
    x,y,z =Spring.GetUnitPosition(unitID)
    x,z = x+ math.random(1,50)*randSign(), z + math.random(1,50)*randSign()
    Command(unitID, "move", {x=x,y=y, z=z})
    Command(unitID, "move", {x=x,y=y, z=z}, {"shift"})
end

function headingSoundSurveilance()
    local oldHeading = 0
    accumulator = 0
    while true do
        heading = Spring.GetUnitHeading(unitID)

        Sleep(100)
        if absDistance(heading,oldHeading) > 160 then
            accumulator = accumulator+1
        else
            accumulator = math.max(0,accumulator -1)
        end

        if accumulator > 4 then
            StartThread(PlaySoundByUnitDefID, myDefID, "sounds/plane/drone.ogg", 1.0, 5000, 1)
        end
        oldHeading = heading
    end
  end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return FireEmit1 end

function script.QueryWeapon1() return FireEmit1 end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon1() return true end

--- -aimining & fire weapon
function script.AimFromWeapon2() return FireEmit2 end

function script.QueryWeapon2() return FireEmit2 end

function script.AimWeapon2(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon2() return true end

function script.StartMoving() 
     

end

function script.StopMoving() end

function script.Activate()
    Spin(Rotor, z_axis, math.rad(900), 100)
    return 1
end

function script.Deactivate()
    StopSpin(Rotor, z_axis, 100)
    return 0
end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

