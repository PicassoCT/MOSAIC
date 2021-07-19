include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

firepiece = piece "firepiece"
center = piece "MosaicJavelin"
gun = piece "MosaicJavelin"
local SIG_SCOUTLET = 2

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- Hide(firepiece)
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return firepiece end

function script.QueryWeapon1() return firepiece end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon1()
    destroyUnitConditional(unitID, false, true)
    return true
end

function script.StartMoving()
    Signal(SIG_SCOUTLET)
    spinT(TablesOfPiecesGroups["uprotor"], y_axis, 9500, 350)
    spinT(TablesOfPiecesGroups["lowrotor"], y_axis, -9500, 350)
    for i=1,4 do
        reset(TablesOfPiecesGroups["Scoutlett"][i], 44000)
    end
     Spring.SetUnitCloak(unitID, false)
end

boolRestart = true
function detachScouletts()
    x,y,z = Spring.GetUnitPosition(unitID)
    gh = Spring.GetGroundHeight(x,z)
    if y - gh < 5 then
        for i=1,4 do
            if math.random(0,4) == 2 then
                StartThread(deployScoutletts,TablesOfPiecesGroups["Scoutlett"][i],i)
            end
        end
    end
end

function deployScoutletts(pname, nr)
    SetSignalMask(SIG_SCOUTLET)
    Sleep(1000)
    Spin(TablesOfPiecesGroups["uprotor"][nr], y_axis, 9500, 350)
    Spin(TablesOfPiecesGroups["lowrotor"][nr], y_axis, -9500, 350)
          rx,rz = math.random(1000,5000) * randSign(), math.random(1000,5000) * randSign()
    while true do
        rx,rz = rx + math.random(1000,5000) * randSign(), rz+ math.random(1000,5000) * randSign()
        mSyncIn(pname,rz, rx, Spring.GetGroundHeight(rx,rz)+ 250 + math.random(0,100), 500)
        Sleep(500)
    end
end

function script.StopMoving()
    stopSpinT(TablesOfPiecesGroups["uprotor"], y_axis, 1)
    stopSpinT(TablesOfPiecesGroups["lowrotor"], y_axis, 1)
    StartThread(detachScouletts)

end

function script.Activate() return 1 end

function script.Deactivate() 
 Spring.SetUnitCloak(unitID, true, true , 25)
    return 0 
end

