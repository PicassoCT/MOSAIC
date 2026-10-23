include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

-- The fighter AI must not descend or fire before folding. One controller owns
-- flight until a single native gravity bomb is released; MOVE/PATROL still work.
local SIG_FLIGHT = 16
local FPS = Game.gameSpeed or 30
local UPDATE_FRAMES = math.max(1, math.floor(FPS / 10))
local UPDATE_MS = UPDATE_FRAMES * 1000 / FPS
local LOITER_RADIUS, ARRIVAL_RADIUS = 180, 25
local FOLD_SPEED = math.rad(180)
local WING_SLIDE, WING_SLIDE_SPEED = 326, 652
local phaseNumber = {building=0, ascent=1, unfolding=2, loiter=3,
                     transit=4, folding=5, released=6, crashing=7}
local phase, stopped, released, impactProjectile = "building", false, false, nil
local releaseDeadline
local pieces, loiterX, loiterZ = {}, nil, nil
local forwardX, forwardZ = 0, 1
local definition = UnitDefs[unitDefID]
local cruiseHeight = definition.wantedHeight or definition.cruiseAlt or 1536
local flightSpeed = (definition.speed or 75) / FPS
local weaponDefID = WeaponDefNames.icarusglidebomb.id
local weaponDefinition = WeaponDefs[weaponDefID]
local impactGraceFrames = math.ceil(weaponDefinition.damageAreaOfEffect /
                                    math.max(0.001, weaponDefinition.explosionSpeed)) + 1
local gravity = -math.abs(Game.gravity or 130) / (FPS * FPS)

local Cartdrige = piece("Cartdrige")
local Base, Eye, Tail = piece("Base"), piece("Eye"), piece("Tail")
local Wing1, Wing2 = piece("Wing1"), piece("Wing2")
local Wing1Sub1, Wing2Sub1 = piece("Wing1Sub1"), piece("Wing2Sub1")

local function alive()
    return not stopped and Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID)
end

local function setPhase(nextPhase)
    if phase == nextPhase then return end
    phase = nextPhase
    Spring.SetUnitRulesParam(unitID, "icarus_flight_phase", phaseNumber[nextPhase], {inlos=true})
end

local function stopVelocity()
    Spring.MoveCtrl.SetVelocity(unitID, 0, 0, 0)
end

local function distance2(x, z, tx, tz)
    return (tx-x)*(tx-x) + (tz-z)*(tz-z)
end

local function internalOrder(command)
    local options = command.options or {}
    if type(options) == "table" then
        if options.internal then return true end
        options = options.coded or 0
    end
    local internal = CMD.OPT_INTERNAL or 8
    return math.floor(options / internal) % 2 == 1
end

local function currentOrder()
    local commands = Spring.GetUnitCommands(unitID, 2)
    return commands and commands[1], commands and #commands or 0
end

local function removeOrder(command)
    if command and command.tag then
        Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {command.tag}, 0)
    end
end

local function targetPosition(command)
    if not command or command.id ~= CMD.ATTACK or internalOrder(command) then return end
    local p = command.params or {}
    if #p == 1 then
        local target = p[1]
        if target == unitID or not Spring.ValidUnitID(target) or Spring.GetUnitIsDead(target) then return end
        local targetDef = UnitDefs[Spring.GetUnitDefID(target)]
        if not targetDef or not (targetDef.modCategories or {}).ground then return end
        local visibility = Spring.GetUnitLosState(target, Spring.GetUnitAllyTeam(unitID))
        if not visibility or not (visibility.los or visibility.radar) then return end
        -- A synced unit script otherwise sees exact positions through radar and
        -- fog. Match the owning team's information, including radar error.
        return CallAsTeam({read=Spring.GetUnitTeam(unitID)}, Spring.GetUnitPosition, target)
    elseif #p >= 3 then
        return p[1], p[2], p[3]
    end
end

local function sameDesignation(first, second)
    if not first or not second or second.id ~= CMD.ATTACK or internalOrder(second) then return false end
    if first.tag and second.tag then return first.tag == second.tag end
    local a, b = first.params or {}, second.params or {}
    if #a ~= #b then return false end
    for i=1,#a do if a[i] ~= b[i] then return false end end
    return true
end

local function beginLoiter(x, z)
    -- Offset the centre beside the flight path, avoiding a jump to the rim.
    loiterX, loiterZ = x-forwardZ*LOITER_RADIUS, z+forwardX*LOITER_RADIUS
    if Game.mapSizeX and Game.mapSizeX > 2*LOITER_RADIUS then
        loiterX = math.max(LOITER_RADIUS,math.min(Game.mapSizeX-LOITER_RADIUS,loiterX))
    end
    if Game.mapSizeZ and Game.mapSizeZ > 2*LOITER_RADIUS then
        loiterZ = math.max(LOITER_RADIUS,math.min(Game.mapSizeZ-LOITER_RADIUS,loiterZ))
    end
    setPhase("loiter")
end

local function flyToward(x, y, z, tx, tz, bank)
    local dx, dz = tx-x, tz-z
    local distance = math.sqrt(dx*dx + dz*dz)
    local speed = math.min(flightSpeed, distance / UPDATE_FRAMES)
    local vx, vz = 0, 0
    if distance > 0.001 then
        forwardX, forwardZ = dx/distance, dz/distance
        vx, vz = forwardX*speed, forwardZ*speed
    end
    local desiredY = math.max(0, Spring.GetGroundHeight(x,z), Spring.GetGroundHeight(tx,tz)) + cruiseHeight
    local vy = math.max(-flightSpeed, math.min(flightSpeed, (desiredY-y)/UPDATE_FRAMES))
    Spring.MoveCtrl.SetVelocity(unitID, vx, vy, vz)
    -- MoveCtrl's front vector is (-sin(yaw), 0, cos(yaw)).
    Spring.MoveCtrl.SetRotation(unitID, 0, -math.atan2(forwardX, forwardZ), bank or 0)
end

local function unfoldWings()
    Turn(Wing1, x_axis, math.rad(-80), FOLD_SPEED)
    Turn(Wing2, x_axis, math.rad(80), FOLD_SPEED)
    Move(Wing1Sub1, y_axis, 0, WING_SLIDE_SPEED)
    Move(Wing2Sub1, y_axis, 0, WING_SLIDE_SPEED)
    WaitForTurn(Wing1, x_axis)
    WaitForTurn(Wing2, x_axis)
    WaitForMove(Wing1Sub1, y_axis)
    WaitForMove(Wing2Sub1, y_axis)
end

local function foldWings()
    -- Use real piece IDs and wait for both folding and telescoping to finish.
    Move(Wing1Sub1, y_axis, WING_SLIDE, WING_SLIDE_SPEED)
    Move(Wing2Sub1, y_axis, WING_SLIDE, WING_SLIDE_SPEED)
    Turn(Wing1, x_axis, 0, FOLD_SPEED)
    Turn(Wing2, x_axis, 0, FOLD_SPEED)
    WaitForMove(Wing1Sub1, y_axis)
    WaitForMove(Wing2Sub1, y_axis)
    WaitForTurn(Wing1, x_axis)
    WaitForTurn(Wing2, x_axis)
end

local function releaseBomb()
    if released or not alive() or Spring.GetUnitIsStunned(unitID) then return false end
    local x,y,z = Spring.GetUnitPosition(unitID)
    local height = math.max(0, y-math.max(0,Spring.GetGroundHeight(x,z)))
    local ttl = math.ceil(math.sqrt(2*height / -gravity)) + 10*FPS
    if (Spring.GetUnitSelfDTime(unitID) or 0) > 0 then
        Spring.GiveOrderToUnit(unitID, CMD.SELFD, {}, 0)
    end
    local projectile = Spring.SpawnProjectile(weaponDefID, {
        pos={x,y,z}, speed={0,-0.01,0}, gravity=gravity, ttl=ttl,
        owner=unitID, team=Spring.GetUnitTeam(unitID), weapon=1,
    })
    if not projectile then return false end
    impactProjectile, released = projectile, true
    releaseDeadline = Spring.GetGameFrame()+ttl+FPS
    setPhase("released")
    -- The engine resolves ownerID at impact. Keep its attribution carrier alive
    -- until collision, then reclaim it without a second death explosion.
    Spring.SetUnitRulesParam(unitID, "icarus_released", 1, {private=true})
    hideAll(unitID)
    Spring.SetUnitNoDraw(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitNoMinimap(unitID, true)
    Spring.SetUnitBlocking(unitID, false, false, false)
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitStealth(unitID, true)
    Spring.SetUnitSonarStealth(unitID, true)
    for _, sensor in ipairs({"los", "airLos", "radar", "sonar"}) do
        Spring.SetUnitSensorRadius(unitID, sensor, 0)
    end
    stopVelocity()
    return true
end

local function flightController()
    local x,y,z = Spring.GetUnitPosition(unitID)
    beginLoiter(x,z)
    while alive() and not released do
        x,y,z = Spring.GetUnitPosition(unitID)
        if Spring.GetUnitIsStunned(unitID) then
            stopVelocity()
        else
        local command, queuedOrders = currentOrder()
        local tx,ty,tz = targetPosition(command)
        if tx then
            setPhase("transit")
            if distance2(x,z,tx,tz) < ARRIVAL_RADIUS*ARRIVAL_RADIUS then
                -- Lock the release point when folding begins. A moving target
                -- can evade after commitment; the gravity bomb never homes.
                Spring.MoveCtrl.SetPosition(unitID, tx,y,tz)
                stopVelocity()
                setPhase("folding")
                foldWings()
                if not alive() then return end
                local latest = currentOrder()
                if sameDesignation(command,latest) and targetPosition(latest) and not Spring.GetUnitIsStunned(unitID) then
                    if releaseBomb() then break end
                    Spring.Echo("[Icarus] Could not create gravity bomb; retaining aircraft",unitID)
                    removeOrder(latest)
                end
                setPhase("unfolding")
                unfoldWings()
                if not alive() then return end
                beginLoiter(tx,tz)
            else
                flyToward(x,y,z,tx,tz)
            end
        elseif command and (command.id == CMD.MOVE or command.id == CMD.PATROL or command.id == CMD.FIGHT) then
            local p = command.params or {}
            if #p >= 3 then
                if command.id == CMD.PATROL and queuedOrders < 2 then
                    -- A single newly issued/replaced patrol needs a return leg.
                    Spring.GiveOrderToUnit(unitID, CMD.PATROL, {x,y,z}, {"shift"})
                end
                setPhase("transit")
                if distance2(x,z,p[1],p[3]) < ARRIVAL_RADIUS*ARRIVAL_RADIUS then
                    if command.id == CMD.PATROL then
                        Spring.GiveOrderToUnit(unitID,CMD.PATROL,{p[1],p[2],p[3]},{"shift"})
                    end
                    removeOrder(command)
                    beginLoiter(x,z)
                else
                    flyToward(x,y,z,p[1],p[3])
                end
            else
                removeOrder(command)
            end
        else
            -- STOP, a dead target, or an internal auto-target resumes loiter.
            if command and command.id == CMD.ATTACK then removeOrder(command) end
            if phase ~= "loiter" then beginLoiter(x,z) end
            local angle = math.atan2(z-loiterZ,x-loiterX) + flightSpeed*UPDATE_FRAMES/LOITER_RADIUS
            flyToward(x,y,z,loiterX+math.cos(angle)*LOITER_RADIUS,
                             loiterZ+math.sin(angle)*LOITER_RADIUS,-0.22)
        end
        end
        Sleep(UPDATE_MS)
    end
    -- This loop is bounded by the projectile's TTL and runs only during its fall.
    while alive() and impactProjectile and Spring.GetProjectilePosition(impactProjectile) do
        if Spring.GetGameFrame() >= releaseDeadline then
            Spring.DeleteProjectile(impactProjectile)
            break
        end
        Sleep(UPDATE_MS)
    end
    if alive() and released then
        -- Blast damage propagates over subsequent frames; its outer hits still
        -- resolve attackerID. Retain attribution until that finite wave ends.
        Sleep(impactGraceFrames*1000/FPS)
        if not alive() then return end
        stopped = true
        Spring.DestroyUnit(unitID, false, true)
    end
end

local function revealUnfold()
    SetSignalMask(SIG_FLIGHT)
    hideAll(unitID)
    setUnitNeverLand(unitID, true)
    showT(pieces.Sabot)
    Show(Cartdrige)
    if not waitTillComplete(unitID) or not alive() then return end
    while alive() and Spring.GetUnitIsStunned(unitID) do Sleep(UPDATE_MS) end
    if not alive() then return end

    local x,y,z = Spring.GetUnitPosition(unitID)
    local launchTop = y+2048
    if GG.NimrodLaunchFX and GG.NimrodLaunchFX.Departure then
        GG.NimrodLaunchFX.Departure(unitID, launchTop)
    end
    Spring.MoveCtrl.Enable(unitID)
    Spring.MoveCtrl.SetGravity(unitID, 0)
    stopVelocity()
    setPhase("ascent")
    moveT(pieces.Sabot,y_axis,-1000,200)
    for _, sabot in pairs(pieces.Sabot or {}) do spinRand(sabot,15,50) end
    local climbed, step = 0, 250
    while climbed < 2048 and alive() do
        if Spring.GetUnitIsStunned(unitID) then
            Sleep(UPDATE_MS)
        else
        climbed = math.min(2048, climbed+step)
        Spring.MoveCtrl.SetPosition(unitID,x,y+climbed,z)
        if climbed > 1700 then step = math.max(50,step*0.97) end
        Sleep(1000/FPS)
        end
    end
    if not alive() then return end
    hideT(pieces.Sabot)
    Sleep(500)
    if not alive() then return end
    Hide(Cartdrige)
    showT(pieces.TailRotor)
    Show(Base); Show(Eye); Show(Tail)
    Turn(Tail,y_axis,math.rad(90),15)
    showT(pieces.Wing)
    Show(Wing1Sub1); Show(Wing2Sub1)
    Move(Wing1Sub1,y_axis,WING_SLIDE,0)
    Move(Wing2Sub1,y_axis,WING_SLIDE,0)
    -- Preserve the established model orientation: the nose then faces +Z.
    Turn(Base,x_axis,math.rad(90),15)
    Turn(Base,z_axis,math.rad(90),15)
    spinT(pieces.TailRotor,y_axis,math.rad(42))
    setPhase("unfolding")
    unfoldWings()
    if alive() then flightController() end
end

function script.Create()
    pieces = getPieceTableByNameGroups(false,true)
    Spring.SetUnitRulesParam(unitID,"icarus_flight_phase",phaseNumber.building,{inlos=true})
    StartThread(revealUnfold)
end

function BeginAircraftCrash()
    if released then return end
    stopped = true
    setPhase("crashing")
    Signal(SIG_FLIGHT)
    if Spring.MoveCtrl.GetTag(unitID) then Spring.MoveCtrl.Disable(unitID) end
end

function script.HitByWeapon(_,_,_,damage)
    if released then return 0 end
    return damage
end

function script.Killed()
    stopped = true
    Signal(SIG_FLIGHT)
    -- Already released projectiles retain native ballistic/TTL behavior even
    -- after exceptional external removal of their protected owner.
    impactProjectile = nil
    return 1
end

function script.StartMoving() end
function script.StopMoving() end
function script.Activate() return 1 end
function script.Deactivate() return 0 end
function script.AimFromWeapon1() return Base end
function script.QueryWeapon1() return Base end
function script.AimWeapon1() return false end
function script.BlockShot1() return true end
function script.FireWeapon1() return false end
