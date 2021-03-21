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
    spinT(TablesOfPiecesGroups["uprotor"], y_axis, 9500, 350)
    spinT(TablesOfPiecesGroups["lowrotor"], y_axis, -9500, 350)
    boolRestart = true
end

boolRestart = true
function detachScouletts()
    x,y,z = Spring.GetUnitPosition(unitID)
    gh = Spring.GetGroundHeight(x,z)
    if y - gh < 5 then
        boolRestart = false
        for i=1,4 do
            if math.random(0,4) == 2 then
                StartThread(deployScoutletts,TablesOfPiecesGroups["Scoutlett"][i],i)
            end
        end
    end
end

function deployScoutletts(pieces, nr)
    Signal(SIG_SCOUTLET)
    SetSignalMask(SIG_SCOUTLET)
    spinT(TablesOfPiecesGroups["uprotor"][nr], y_axis, 9500, 350)
    spinT(TablesOfPiecesGroups["lowrotor"][nr], y_axis, -9500, 350)
    while boolRestart == false do
        ry= math.random(30, 100)
        rx,rz = math.random(50,250) * randSign(), math.random(50,250) * randSign()
        mSyncIn(piecename, rx,ry,rz, 3000)
        Sleep(500)
        while boolRestart == false and true == Spring.UnitScript.IsInMove(pname, x_axis) do
            Sleep(33)
        end

    end
    mSyncIn(piecename, 0,0,0, 1000)
end

function script.StopMoving()
    stopSpinT(TablesOfPiecesGroups["uprotor"], y_axis, 1)
    stopSpinT(TablesOfPiecesGroups["lowrotor"], y_axis, 1)
    StartThread(detachScouletts)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

