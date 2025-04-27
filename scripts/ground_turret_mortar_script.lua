include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

local myTeamID = Spring.GetUnitTeam(unitID)
local GameConfig = getGameConfig()
local center = piece "center"
local Turret = piece "Turret"
local aimpiece = piece "aimpiece"
local aimingFrom = Turret
local firingFrom = aimpiece
local groundFeetSensors = {}
local SIG_GUARDMODE = 1
local boolDroneInterceptSaturated = false
local cruiseMissileProjectileType =  getCruiseMissileProjectileTypes(WeaponDefs)


function script.Create()
    resetAll(unitID)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(guardSwivelTurret)
end



boolAiming = false

function guardSwivelTurret()
    waitTillComplete(unitID)
    Signal(SIG_GUARDMODE)
    SetSignalMask(SIG_GUARDMODE)
    Sleep(5000)
    boolGroundAiming = false
    while true do
        if isTransported(unitID) == false  then
            target = math.random(1, 360)
            lastValueHeadingRad = math.rad(target)
            WTurn(center, y_axis, math.rad(target), math.pi)
            Sleep(500)
            WTurn(center, y_axis, math.rad(target), math.pi)
        end
        Sleep(500)
    end
end

function script.Killed(recentDamage, _)
    explodeTableOfPiecesGroupsExcludeTable(TablesOfPiecesGroups, {})
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return aimingFrom end

function script.QueryWeapon1() return firingFrom end

boolGroundAiming = false
lastValueHeadingRad = 0
function script.AimWeapon1(Heading, pitch)
    Signal(SIG_GUARDMODE)

    -- aiming animation: instantly turn the gun towards the enemy
    boolGroundAiming = true
    Turn(center, y_axis, Heading, math.pi)
    lastValueHeadingRad = Heading
    Turn(Turret, x_axis, -pitch +math.rad(90), math.pi)
    WaitForTurns(center, Turret)
    boolGroundAiming = false
    return true
end

function script.FireWeapon1()
    StartThread(fireFlowers, 15)
    WMove(aimpiece,y_axis, -10, 50)
    Move(aimpiece,y_axis, 0, 0.1)
    boolGroundAiming = false
    StartThread(guardSwivelTurret)
    return true
end


function fireFlowers(itterations)
    for i = 1, itterations do
        EmitSfx(firingFrom, 1025)
        Sleep(120)
    end
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

