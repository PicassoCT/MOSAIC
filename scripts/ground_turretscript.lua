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

local function interceptionTargets(targets)
    local ids = {}
    for id in pairs(targets) do ids[#ids+1] = id end
    table.sort(ids)
    return ids
end

local function aimAndFireIntercept(position, duration)
    local px, py, pz = position()
    if not px then return false end
    local x, y, z = Spring.GetUnitPiecePosDir(unitID, firingFrom)
    local front, up, right = Spring.GetUnitVectors(unitID)
    local dx, dy, dz = px-x, py-y, pz-z
    local forward = dx*front[1]+dy*front[2]+dz*front[3]
    local side = -(dx*right[1]+dy*right[2]+dz*right[3])
    local vertical = dx*up[1]+dy*up[2]+dz*up[3]
    local heading = math.atan2(side, forward)
    local pitch = math.atan2(vertical, math.sqrt(side*side+forward*forward))
    local _, oldHeading = Spring.UnitScript.GetPieceRotation(center)
    local oldPitch = Spring.UnitScript.GetPieceRotation(Turret)
    local turnTime = math.max(0.001, duration / 2000)
    local yaw = oldHeading + (heading-oldHeading+math.pi)%(2*math.pi)-math.pi
    Signal(SIG_GUARDMODE)
    Turn(center, y_axis, yaw, math.max(math.pi, math.abs(yaw-oldHeading)/turnTime))
    Turn(Turret, x_axis, -pitch, math.max(math.pi, math.abs(-pitch-oldPitch)/turnTime))
    WaitForTurns(center, Turret)
    lastValueHeadingRad = heading
    -- The same muzzle routine as normal shooting, plus visible travelling
    -- rounds. Sample moving targets again for each shot; disappeared targets
    -- end the burst without an explosion at stale coordinates.
    fireFlowers(3, position, duration / 6)
    return position() ~= nil
end

function playProjectileInterceptAnimation(projectiles, timeTotal, maxIntercept)
    local ids = interceptionTargets(projectiles)
    local limit = math.ceil(math.min(#ids, maxIntercept))
    local intercepted = 0
    boolDroneInterceptSaturated = true
    for _, projID in ipairs(ids) do
        if intercepted >= limit then break end
        local wdefID = projectiles[projID]
        if not cruiseMissileProjectileType[wdefID] or
            math.random(1,GameConfig.military.cruiseMissiles.interceptOneIn) == 1 then
            local function position()
                if Spring.GetProjectileDefID(projID) == wdefID then
                    return Spring.GetProjectilePosition(projID)
                end
            end
            if aimAndFireIntercept(position, timeTotal/limit) then
                local px, py, pz = position()
                Spring.DeleteProjectile(projID)
                Spring.SpawnCEG("missile_explosion", px, py, pz, 0, 1, 0, 50, 0)
                intercepted = intercepted + 1
            end
        end
    end
    boolDroneInterceptSaturated = false
    StartThread(guardSwivelTurret)
end

function playDroneInterceptAnimation(drones, timeTotal, maxIntercept)
    local ids = interceptionTargets(drones)
    local limit = math.ceil(math.min(#ids, maxIntercept))
    local intercepted = 0
    boolDroneInterceptSaturated = true
    for _, droneID in ipairs(ids) do
        if intercepted >= limit then break end
        local function position() return Spring.GetUnitPosition(droneID) end
        if aimAndFireIntercept(position, timeTotal/limit) then
            Spring.AddUnitDamage(droneID, 50)
            intercepted = intercepted + 1
        end
    end
    boolDroneInterceptSaturated = false
    StartThread(guardSwivelTurret)
end

function droneDefense()
    local droneInterceptDistance = GameConfig.military.droneInterception.range
    local spGetProjectileTeamID = Spring.GetProjectileTeamID
    local spGetUnitDefID = Spring.GetUnitDefID
    local myTeamID = Spring.GetUnitTeam(unitID)
    local InterceptedProjectileTypes = getGroundTurretMGInterceptableProjectileTypes(WeaponDefs)
    local interceptableDronesTypeTable = getInterceptableAirDroneTypes(UnitDefs)
    
    while true do
        if not boolDroneInterceptSaturated and hasNoActiveAttackCommand(unitID) == true then
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
                StartThread(playProjectileInterceptAnimation, projectilesToIntercept, 500, GameConfig.military.droneInterception.maxPerSecond / 2)
                boolPlayGunSound = true
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
                   StartThread(playDroneInterceptAnimation, dronesToIntercept, 500, GameConfig.military.droneInterception.maxPerSecond / 2)
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

function fireFlowers(itterations, targetPosition, shotInterval)
    if targetPosition then
        StartThread(PlaySoundByUnitDefID, unitDefID,
            "sounds/weapons/machinegun/salvo.ogg", 1.0, 5000, 2)
    end
    for i = 1, itterations do
        if targetPosition then
            local tx, ty, tz = targetPosition()
            if not tx then return end
            local x, y, z = Spring.GetUnitPiecePosDir(unitID, firingFrom)
            local dx, dy, dz = tx-x, ty-y, tz-z
            local distance = math.sqrt(dx*dx+dy*dy+dz*dz)
            if distance > 0 then
                local speed = 850 / (Game.gameSpeed or 30)
                Spring.SpawnProjectile(WeaponDefNames.interceptiontracer.id, {
                    pos = {x,y,z}, speed = {dx/distance*speed,dy/distance*speed,dz/distance*speed},
                    owner = unitID, ttl = math.max(1,math.ceil(distance/speed)), gravity = 0,
                })
            end
        end
        EmitSfx(firingFrom, 1025)
        Sleep(shotInterval or 120)
    end
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

