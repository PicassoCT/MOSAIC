include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

Base = piece "Base"
center = piece "Rotor"
Turret = piece "Eyes"
aimpiece = piece "Eyes"
SIG_GUARDMODE = 1
rocketIndex = 1
function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    resetAll(unitID)
    StartThread(guardSwivelTurret)
end

boolAiming = false

function guardSwivelTurret()
    Signal(SIG_GUARDMODE)
    SetSignalMask(SIG_GUARDMODE)
    Sleep(5000)

    while true do
        if isTransported(unitID) == false then
            target = math.random(1, 360)
            WTurn(center, y_axis, math.rad(target), math.pi)
            Sleep(500)
            WTurn(center, y_axis, math.rad(target), math.pi)
        else
            Move(Base,z_axis, 200, 0)
        end
        Sleep(500)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return Turret end

function script.QueryWeapon1() return Turret end

function script.AimWeapon1(Heading, pitch)

    Signal(SIG_GUARDMODE)

    Turn(center, y_axis, Heading, math.pi)
    Turn(Turret, y_axis, -pitch, math.pi)
    WaitForTurns(center, Turret)

    return true
end

function script.FireWeapon1()
    hideT(TablesOfPiecesGroups["Projectile"], 1, rocketIndex)
    rocketIndex = rocketIndex + 1
    if rocketIndex > #TablesOfPiecesGroups["Projectile"] then
        rocketIndex = 1
        showT(TablesOfPiecesGroups["Projectile"])
    end
    StartThread(guardSwivelTurret)
    return true
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

