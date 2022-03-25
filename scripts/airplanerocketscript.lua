include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

local myDefID = Spring.GetUnitDefID(unitID)
TablesOfPiecesGroups = {}
SIG_RELOAD =1
SIG_FOLD =2

function script.HitByWeapon(x, z, weaponDefID, damage) end

Body = piece "Body"
Rotor = piece "Rotor"
FireEmit1 = piece "FireEmit1"
FireEmit2 = piece "FireEmit2"
RocketPod = piece "RocketPod"
TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

function unfold()
    SetSignalMask(SIG_FOLD)
    Signal(SIG_FOLD)
    Turn(TablesOfPiecesGroups["Wing"][3],3, math.rad(-120),1)
    Turn(TablesOfPiecesGroups["Wing"][4],3, math.rad(120),1)
    WaitForTurns(TablesOfPiecesGroups["Wing"][3],TablesOfPiecesGroups["Wing"][4])
    
    Turn(TablesOfPiecesGroups["Wing"][1],z_axis, math.rad(90),1)
    Turn(TablesOfPiecesGroups["Wing"][2],z_axis, math.rad(-90),1)
    WTurn(RocketPod,z_axis, math.rad(-90),1)
end

function fold()
    SetSignalMask(SIG_FOLD)
    Signal(SIG_FOLD)
    WTurn(TablesOfPiecesGroups["Wing"][1],z_axis, math.rad(0),1)
    WTurn(TablesOfPiecesGroups["Wing"][2],z_axis, math.rad(0),1)

    WTurn(TablesOfPiecesGroups["Wing"][3],3, math.rad(0),1)
    WTurn(TablesOfPiecesGroups["Wing"][4],3, math.rad(0),1)  
    WTurn(RocketPod,z_axis, math.rad(0),1)
end

function script.Create()
    Spin(Rotor, z_axis, math.rad(9122), 0)
    generatepiecesTableAndArrayCode(unitID)

    unfold()
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
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() 
    return FireEmit1 
end

function script.QueryWeapon1() 
    return FireEmit1 
end

counter =  #TablesOfPiecesGroups["Rocket"]
function script.AimWeapon1(Heading, pitch)
     if counter == 1 then StartThread(reloadRoutine) end
    return counter > 0 
end

function reloadRoutine()
    SetSignalMask(SIG_RELOAD)
    Signal(SIG_RELOAD)
    WTurn(RocketPod,z_axis, math.rad(0),1)
    Sleep(60000)
    counter = #TablesOfPiecesGroups["Rocket"]
    WTurn(RocketPod,z_axis, math.rad(-90),1)
    showT(TablesOfPiecesGroups["Rocket"])
end

function script.FireWeapon1()
    counter = math.max(0, counter-1)
    hideT(TablesOfPiecesGroups["Rocket"])
    showT(TablesOfPiecesGroups["Rocket"], 1, counter)     
    return true
end

--- -aimining & fire weapon
function script.StartMoving() 
end

function script.StopMoving() end

function script.Activate()
    Spin(Rotor, z_axis, math.rad(900), 100)
    StartThread(unfold)
    return 1
end

function script.Deactivate()
    StopSpin(Rotor, z_axis, 100)
    StartThread(fold)
    return 0
end
