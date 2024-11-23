include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
local myDefID = Spring.GetUnitDefID(unitID)
local myTeamID = Spring.GetUnitTeam(unitID)
local GameConfig = getGameConfig()
local center = piece "center"
local Turret = piece "Turret"
local aimpiece = piece "aimpiece"
local Shell = piece "Shell"
local aimingFrom = Turret
local firingFrom = aimpiece
local groundFeetSensors = {}
local SIG_GUARDMODE = 1
local boolDroneInterceptSaturated = false
local cruiseMissileProjectileType =  getCruiseMissileProjectileTypes(WeaponDefs)

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    resetAll(unitID)
    Hide(aimpiece)
    Hide(Shell)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    groundFeetSensors = TablesOfPiecesGroups["GroundSensor"]
    hideT(TablesOfPiecesGroups["GroundSensor"])
    hideT(TablesOfPiecesGroups["TBase"])
    StartThread(foldControl)
    StartThread(guardSwivelTurret)
end


function playDroneInterceptAnimation(drones, timeTotal, maxIntercept)
    x, y, z = Spring.GetUnitPosition(unitID)
    intercepted = math.ceil(math.min(count(drones), maxIntercept))
    timePerProjectile = timeTotal / intercepted
    StartThread(fireFlowers, intercepted)
    for droneID, wdefID in pairs(drones) do
        if droneID then
            px, py, pz = Spring.GetUnitPosition(droneID)
                if px then
                    goalRad = convPointsToRad(x, z, px, pz)
                    turnInTime(center, y_axis, math.deg(goalRad), timePerProjectile, 0, math.deg(lastValueHeadingRad), 0, false)
                    WaitForTurns(center)
                    lastValueHeadingRad = goalRad
                    EmitSfx(firingFrom, 256)
                    EmitSfx(firingFrom, 1025)
                    Spring.AddUnitDamage(droneID, 50)
                    if intercepted == 0 then return end
                end
            intercepted = intercepted - 1
        end
    end
end

function printOutWeapon(weaponName)
    for i = 1, #WeaponDefs do
        element = WeaponDefs[i]

        if weaponName == element.name then
            echo(element.name .. "->", element)
        end
    end
end

boolAiming = false

function guardSwivelTurret()
    waitTillComplete(unitID)
    Signal(SIG_GUARDMODE)
    SetSignalMask(SIG_GUARDMODE)
    Sleep(5000)
    boolGroundAiming = false
    while true do
        if isTransported(unitID) == false and boolDroneInterceptSaturated == false then
            target = math.random(1, 360)
            lastValueHeadingRad = math.rad(target)
            WTurn(center, y_axis, math.rad(target), math.pi)
            Sleep(500)
            WTurn(center, y_axis, math.rad(target), math.pi)
        end
        Sleep(500)
    end
end

function foldControl()
    Sleep(10)
    foldUnfoldTurnAxis = z_axis
    Turn(Turret, x_axis, math.rad(90), 0)
    Turn(TablesOfPiecesGroups["TBase"][1], foldUnfoldTurnAxis, math.rad(-30), 0)
    Turn(TablesOfPiecesGroups["TBase"][2], foldUnfoldTurnAxis, math.rad(30), 0)
    Turn(TablesOfPiecesGroups["TBase"][3], foldUnfoldTurnAxis, math.rad(-30), 0)
    Turn(TablesOfPiecesGroups["TBase"][4], foldUnfoldTurnAxis, math.rad(30), 0)
    WTurn(Turret, x_axis, math.rad(0), math.pi)
    waitTillComplete(unitID)
    while true do
        if isTransported(unitID) == false then
            unfold()
        else
            fold()
        end
        Sleep(1000)
    end
end

currentDeg = {
    [1] = {val = -50, dirUp = -1, lastDir = 1, countSwitches = 0},
    [2] = {val = -50, dirUp = -1, lastDir = 1, countSwitches = 0},
    [3] = {val = 50, dirUp = 1, lastDir = -1, countSwitches = 0},
    [4] = {val = 50, dirUp = 1, lastDir = -1, countSwitches = 0}
    }

function turnFeedToGround(nr)
    axis = y_axis

    local direction = currentDeg[nr].dirUp

    x, y, z = Spring.GetUnitPiecePosDir(unitID, groundFeetSensors[nr])
    gh = Spring.GetGroundHeight(x, z)
    if y > gh then -- we are underground
        currentDeg[nr].val = currentDeg[nr].val + direction
    else -- aboveground
        direction = direction * -1
        currentDeg[nr].val = currentDeg[nr].val + direction
    end
    Turn(TablesOfPiecesGroups["UpLeg"][nr], axis,
    math.rad(currentDeg[nr].val), math.pi)

    -- check for directional change
    if direction ~= currentDeg[nr].lastDir then
        currentDeg[nr].countSwitches = currentDeg[nr].countSwitches + 1
        currentDeg[nr].lastDir = direction
    end

    return boolDone
end

function isDone()
    boolDone = true
    for i = 1, 4 do boolDone = boolDone and currentDeg[i].countSwitches > 2 end
return boolDone
end

function setNotDone()
    boolDone = true
    for i = 1, 4 do currentDeg[i].countSwitches = 0 end
end

function unfold()
    boolDone = isDone()
    Sleep(10)
    while boolDone == false do
        Sleep(10)
        WaitForTurns(TablesOfPiecesGroups["UpLeg"])

        for i = 1, 2 do
            turnFeedToGround(i)
            Turn(TablesOfPiecesGroups["LowLeg"][i], x_axis, math.rad(-90),
            math.pi)
        end
        for i = 3, 4 do
            turnFeedToGround(i)
            Turn(TablesOfPiecesGroups["LowLeg"][i], x_axis, math.rad(90),
            math.pi)
        end
        WaitForTurns(TablesOfPiecesGroups["LowLeg"])
        WaitForTurns(TablesOfPiecesGroups["UpLeg"])
        boolDone = isDone()
    end
end

function fold()
    WaitForTurns(TablesOfPiecesGroups["UpLeg"])
    for i = 1, 4 do
        reset(TablesOfPiecesGroups["UpLeg"][i], 2 * math.pi)
        reset(TablesOfPiecesGroups["LowLeg"][i], 2 * math.pi)
    end

    WaitForTurns(TablesOfPiecesGroups["LowLeg"])
    WaitForTurns(TablesOfPiecesGroups["UpLeg"])
    setNotDone()
end

function script.Killed(recentDamage, _)
    EmitSfx(center, 1024)
    EmitSfx(Turret, 1024)
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
    Turn(center, y_axis, Heading, math.pi)
    lastValueHeadingRad = Heading
    Turn(Turret, x_axis, -pitch, math.pi)
    WaitForTurns(center, Turret)
    return true
end

function script.FireWeapon1()
    EmitSfx(firingFrom, 1025)
    Explode(Shell, SFX.FALL + SFX.NO_HEATCLOUD)
    StartThread(guardSwivelTurret)
    return true
end


function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

