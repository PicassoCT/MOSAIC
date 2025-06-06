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
local boolIsSniper = (UnitDefs[unitDefID].name == "ground_turret_sniper")

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    resetAll(unitID)
    Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    groundFeetSensors = TablesOfPiecesGroups["GroundSensor"]
    hideT(TablesOfPiecesGroups["GroundSensor"])
    hideT(TablesOfPiecesGroups["TBase"])
    StartThread(foldControl)
    StartThread(guardSwivelTurret)
    StartThread(droneDefense)
end

function playProjectileInterceptAnimation(projectiles, timeTotal, maxIntercept)
    x, y, z = Spring.GetUnitPosition(unitID)
    intercepted = math.ceil(math.min(#projectiles, maxIntercept))
    timePerProjectile = timeTotal / intercepted
    StartThread(fireFlowers, intercepted)
    for projID, wdefID in pairs(projectiles) do
        if projID then
            if not cruiseMissileProjectileType[wDefID] or 
                cruiseMissileProjectileType[wDefID] and math.random(1,GameConfig.CruiseMissile.chanceOfInterceptOneIn) == 1  then
                px, py, pz = Spring.GetProjectilePosition (projID)
                if px then

                    goalRad = convPointsToRad(x, z, px, pz)
                    turnInTime(center, y_axis, math.deg(goalRad), timePerProjectile, 0, math.deg(lastValueHeadingRad), 0, false)
                    WaitForTurns(center)
                    lastValueHeadingRad = goalRad
                    EmitSfx(firingFrom, 256)
                    EmitSfx(firingFrom, 1025)
                    Spring.DeleteProjectile (projID)
                    Spring.SpawnCEG("missile_explosion", px, py, pz, 0, 1, 0, 50, 0)
                    if intercepted == 0 then return end
                end
                intercepted = intercepted - 1
            end
        end
    end
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

function droneDefense()
    local droneInterceptDistance = GameConfig.groundTurretDroneInterceptRate
    local spGetProjectileTeamID = Spring.GetProjectileTeamID
    local spGetUnitDefID = Spring.GetUnitDefID
    local myTeamID = Spring.GetUnitTeam(unitID)
    local InterceptedProjectileTypes = getGroundTurretMGInterceptableProjectileTypes(WeaponDefs)
    local interceptableDronesTypeTable = getInterceptableAirDroneTypes(UnitDefs)
    
    while true do
        if hasNoActiveAttackCommand(unitID) == true then
            projectilesToIntercept = {}
            foreach(getProjectilesAroundUnit(unitID, droneInterceptDistance),
                function(id)
                    teamID = spGetProjectileTeamID(id)
                    if teamID and teamID ~= myTeamID then
                        return id
                    end
                end,
                function (id)
                    weaponDef = Spring.GetProjectileDefID(id)
                    if weaponDef and InterceptedProjectileTypes[weaponDef] then
                        projectilesToIntercept[id] = weaponDef
                        return id
                    end
                end
            )
            boolPlayGunSound= false
            if projectilesToIntercept and count(projectilesToIntercept) > 0 then
                boolDroneInterceptSaturated = true
                StartThread(playProjectileInterceptAnimation, projectilesToIntercept, 500, GameConfig.groundTurretDroneMaxInterceptPerSecond / 2)
                boolPlayGunSound = true

                boolDroneInterceptSaturated = false
            else 
                dronesToIntercept = {}
                foreach(getAllNearUnitNotInTeam(unitID, droneInterceptDistance, myTeamID),
                        function(id)
                            defID = spGetUnitDefID(id)
                            if interceptableDronesTypeTable[defID] then
                                dronesToIntercept[id] = defID
                            end
                        end
                        )
                if count(dronesToIntercept) > 0 then
                   StartThread(playDroneInterceptAnimation, dronesToIntercept, 500, GameConfig.groundTurretDroneMaxInterceptPerSecond / 2)
                    boolPlayGunSound = true
                end
            end
            if boolPlayGunSound == true then
                StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/weapons/machinegun/salvo.ogg", 1.0, 5000, 2)
            end
            Sleep(250)
        end
        Sleep(250)
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
    [4] = {val = 50, dirUp = 1, lastDir = -1, countSwitches = 0}}

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
    if boolDroneInterceptSaturated == true then return false end
    -- aiming animation: instantly turn the gun towards the enemy
    boolGroundAiming = true
    Turn(center, y_axis, Heading, math.pi)
    lastValueHeadingRad = Heading
    Turn(Turret, x_axis, -pitch, math.pi)
    WaitForTurns(center, Turret)
    boolGroundAiming = false
    return not boolDroneInterceptSaturated
end

function script.FireWeapon1()
    StartThread(fireFlowers, 15)
    StartThread(PlaySoundByUnitDefID, unitDefID,
    "sounds/weapons/machinegun/salvo.ogg", 1.0, 5000, 2)
    boolGroundAiming = false
    StartThread(guardSwivelTurret)
    return true
end

function script.AimFromWeapon2() return aimingFrom end

function script.QueryWeapon2() return firingFrom end

function script.AimWeapon2(Heading, pitch)
    Signal(SIG_GUARDMODE)
    if boolDroneInterceptSaturated == true then return false end
    if boolGroundAiming == false then
        -- aiming animation: instantly turn the gun towards the enemy

        Turn(center, y_axis, Heading, math.pi)
        Turn(Turret, x_axis, -pitch, math.pi)
        WaitForTurns(center, Turret)
        return true
    end
end

function script.FireWeapon2()
    StartThread(fireFlowers, 15)
    StartThread(PlaySoundByUnitDefID, unitDefID,
    "sounds/weapons/machinegun/salvo2.ogg", 1.0, 5000, 1)
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

