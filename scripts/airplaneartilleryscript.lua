include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

-- Native aircraft AI owns sustained flight. MoveCtrl is only the rail launch;
-- afterward a declining native altitude target consumes a finite glide budget.
local SIG_GLIDE, SIG_WINGS, SIG_ORDERS, SIG_CLEANUP = 16, 32, 64, 128
local FPS = Game.gameSpeed or 30
local FRAME_MS = 1000 / FPS
local FOLD_SPEED = math.rad(180)
local WING_SLIDE, WING_SLIDE_SPEED = 326, 652
local FOLD_SECONDS = math.max(WING_SLIDE/WING_SLIDE_SPEED, math.rad(80)/FOLD_SPEED)
local UPDATE_SECONDS = 1
local FOLD_ALIGNMENT, CANCEL_ALIGNMENT = 0.95, 0.8
local phaseNumber = {building=0, ascent=1, unfolding=2, loiter=3,
                     transit=4, folding=5, released=6, crashing=7}
local phase, stopped, released, committed = "building", false, false, false
local nativeReady, exhausted, orderDirty, refreshPending = false, false, true, false
local wings, currentOrder, impactProjectile = "closed", nil, nil
local pieces = {}
local definition = UnitDefs[unitDefID]
local custom = definition.customParams or {}
local cruiseHeight = math.max(2, definition.wantedHeight or definition.cruiseAlt or 1536)
local sinkRate = math.max(0.1, tonumber(custom.icarus_sink_rate) or 8)
local terminalHeight = math.max(1, math.min(cruiseHeight-1,
    tonumber(custom.icarus_terminal_height) or 128))
local glideFrames = math.ceil((cruiseHeight-terminalHeight) / sinkRate * FPS)
local flightSpeed = definition.speed or 75 -- elmos per second
local brakeSeconds = math.max(0.1, tonumber(custom.icarus_brake_seconds) or 1)
local foldedSpeedFactor = math.max(0.05, math.min(1,
    tonumber(custom.icarus_folded_speed_factor) or 0.25))
local nativeMaxSpeed, foldedSpeed = flightSpeed, flightSpeed*foldedSpeedFactor
local braking, brakeReadyFrame = false, nil
local glideStarted, glideDeadline, clearanceY
local expireGlide, checkClearance
local gravityPerSecond = math.abs(Game.gravity or 130)
local gravity = -gravityPerSecond / (FPS * FPS)
local weaponDefID = WeaponDefNames.icarusglidebomb.id
local weaponDefinition = WeaponDefs[weaponDefID]
local impactGraceFrames = math.ceil(weaponDefinition.damageAreaOfEffect /
    math.max(0.001, weaponDefinition.explosionSpeed)) + 1
-- CBombDropper::FireImpl gives native bombs a 1,000-frame TTL. Exhaustion
-- replaces this with a gravity-derived TTL before spawning its one projectile.
local projectileTimeoutFrames = 1000 + FPS

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

local function internalOrder(command)
    local options = command.options or {}
    if type(options) == "table" then
        if options.internal then return true end
        options = options.coded or 0
    end
    return math.floor(options / (CMD.OPT_INTERNAL or 8)) % 2 == 1
end

local function isDesignation(command)
    return command and command.id == CMD.ATTACK and not internalOrder(command)
end

local function sameOrder(a, b)
    if not a or not b then return a == b end
    if a.id ~= b.id or internalOrder(a) ~= internalOrder(b) then return false end
    if a.tag and b.tag and a.tag ~= b.tag then return false end
    local ap, bp = a.params or {}, b.params or {}
    if #ap ~= #bp then return false end
    for i=1,#ap do if ap[i] ~= bp[i] then return false end end
    return true
end

local function setFlightPhase()
    local id = currentOrder and currentOrder.id
    setPhase((id == CMD.ATTACK or id == CMD.MOVE or id == CMD.PATROL or id == CMD.FIGHT)
        and "transit" or "loiter")
end

local function targetPosition()
    if not isDesignation(currentOrder) then return end
    local p = currentOrder.params or {}
    if #p == 1 then
        local target = p[1]
        if target == unitID or not Spring.ValidUnitID(target) or Spring.GetUnitIsDead(target) then return end
        local targetDef = UnitDefs[Spring.GetUnitDefID(target)]
        if not targetDef or not (targetDef.modCategories or {}).ground then return end
        local visibility = Spring.GetUnitLosState(target, Spring.GetUnitAllyTeam(unitID))
        if not visibility or not (visibility.los or visibility.radar) then return end
        -- Prepare animation with the owner's information, including radar error.
        -- Native aircraft AI does all actual target tracking and steering.
        return CallAsTeam({read=Spring.GetUnitTeam(unitID)}, Spring.GetUnitPosition, target)
    elseif #p >= 3 then
        return p[1], p[2], p[3]
    end
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
    Move(Wing1Sub1, y_axis, WING_SLIDE, WING_SLIDE_SPEED)
    Move(Wing2Sub1, y_axis, WING_SLIDE, WING_SLIDE_SPEED)
    Turn(Wing1, x_axis, 0, FOLD_SPEED)
    Turn(Wing2, x_axis, 0, FOLD_SPEED)
    WaitForMove(Wing1Sub1, y_axis)
    WaitForMove(Wing2Sub1, y_axis)
    WaitForTurn(Wing1, x_axis)
    WaitForTurn(Wing2, x_axis)
end

local function brakeForDrop()
    if braking then return end
    braking = true
    brakeReadyFrame = Spring.GetGameFrame()+math.ceil(brakeSeconds*FPS)
    -- CStrafeAirMoveType::SetMaxSpeed recalculates native aerodynamic drag.
    -- The engine sheds forward speed; Lua never writes the unit's velocity.
    Spring.MoveCtrl.SetAirMoveTypeData(unitID,"maxSpeed",foldedSpeed)
end

local function cancelFold()
    if wings == "open" or wings == "unfolding" or exhausted or released or stopped then return end
    if checkClearance and not checkClearance() then return end
    Signal(SIG_WINGS)
    if braking then
        Spring.MoveCtrl.SetAirMoveTypeData(unitID,"maxSpeed",nativeMaxSpeed)
        braking, brakeReadyFrame = false, nil
    end
    wings = "unfolding"
    setPhase("unfolding")
    StartThread(function()
        SetSignalMask(SIG_WINGS)
        unfoldWings()
        if stopped or released or exhausted then return end
        wings = "open"
        setFlightPhase()
    end)
end

local function beginFold()
    if wings ~= "open" or stopped or released or exhausted or committed then return end
    if checkClearance and not checkClearance() then return end
    Signal(SIG_WINGS)
    wings = "folding"
    setPhase("folding")
    StartThread(function()
        SetSignalMask(SIG_WINGS)
        foldWings()
        if stopped or released or exhausted then return end
        wings = "folded"
        brakeForDrop()
    end)
end

local function refreshOrder()
    -- Command events, not a polling flight controller, refresh this one entry.
    local commands = Spring.GetUnitCommands(unitID, 1)
    local nextOrder = commands and commands[1]
    local changed = not sameOrder(currentOrder, nextOrder)
    currentOrder, orderDirty = nextOrder, false
    if changed then cancelFold() end
    if wings == "open" then setFlightPhase() end
end

function IcarusCommandChanged()
    if stopped or released or exhausted or committed then return end
    orderDirty = true -- close the shot gate during the event/queue gap
    if not nativeReady or refreshPending then return end
    refreshPending = true
    StartThread(function()
        SetSignalMask(SIG_ORDERS)
        -- UnitCommand is emitted BEFORE the engine mutates its command queue.
        Sleep(FRAME_MS)
        refreshPending = false
        if stopped or released or exhausted or not nativeReady then return end
        refreshOrder()
    end)
end

local function prepareAttack()
    if orderDirty or committed or not isDesignation(currentOrder) then return end
    local tx,ty,tz = targetPosition()
    if not tx or Spring.GetUnitIsStunned(unitID) then cancelFold(); return end
    local x,y,z = Spring.GetUnitPosition(unitID)
    local vx,_,vz = Spring.GetUnitVelocity(unitID)
    local dx,dz = tx-x,tz-z
    local distanceSquared, speedSquared = dx*dx+dz*dz, vx*vx+vz*vz
    local approach = dx*vx+dz*vz
    local alignment = wings == "open" and FOLD_ALIGNMENT or CANCEL_ALIGNMENT
    -- Fold only on an aligned approach: the slow native profile deliberately
    -- sheds lift and has weaker turning authority. Reopen after a missed pass,
    -- with hysteresis, unless the clearance guard commits a local terminal drop.
    if approach <= 0 or approach*approach < alignment*alignment*distanceSquared*speedSquared then
        cancelFold()
        return
    end
    local speed = math.max(nativeMaxSpeed, math.sqrt(speedSquared)*FPS)
    local fallSeconds = math.sqrt(2*math.max(0,y-ty) / gravityPerSecond)
    -- Prepare before the native bomber's narrow ballistic firing window, only
    -- during an explicit attack, at the same 1 Hz as the glide allowance.
    local lead = foldedSpeed*fallSeconds + speed*(FOLD_SECONDS+brakeSeconds+1.5) + 24
    if distanceSquared <= lead*lead then
        beginFold()
    elseif distanceSquared > (lead*1.25)^2 then
        cancelFold() -- reopen if a missed pass or moving target takes us away
    end
end

local function reclaimAfterImpact()
    SetSignalMask(SIG_CLEANUP)
    Sleep(impactGraceFrames*FRAME_MS)
    if not alive() then return end
    stopped = true
    Spring.DestroyUnit(unitID, false, true)
end

function IcarusProjectileDestroyed(projectileID)
    if stopped or not released or impactProjectile ~= projectileID then return end
    impactProjectile = nil
    Signal(SIG_CLEANUP)
    -- Outward blast propagation resolves the owner again on later frames.
    StartThread(reclaimAfterImpact)
end

function IcarusProjectileCreated(projectileID)
    if stopped or released then return end
    impactProjectile, released, committed, nativeReady = projectileID, true, true, false
    Signal(SIG_GLIDE)
    Signal(SIG_WINGS)
    Signal(SIG_ORDERS)
    setPhase("released")
    if (Spring.GetUnitSelfDTime(unitID) or 0) > 0 then
        -- Cancel before the private marker makes the crash gadget reject orders.
        Spring.GiveOrderToUnit(unitID, CMD.SELFD, {}, 0)
    end
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
    -- The hidden owner retains native movement until impact. No MoveCtrl
    -- freeze or projectile-position polling is needed.
    StartThread(function()
        SetSignalMask(SIG_CLEANUP)
        Sleep(projectileTimeoutFrames*FRAME_MS)
        if not alive() or impactProjectile ~= projectileID then return end
        -- A lost destruction event can outlive the projectile's numeric ID:
        -- do not delete an unrelated shot which has since reused that ID.
        if Spring.GetProjectileDefID(projectileID) == weaponDefID
            and Spring.GetProjectileOwnerID(projectileID) == unitID then
            Spring.DeleteProjectile(projectileID)
        end
        IcarusProjectileDestroyed(projectileID) -- relay-reload fallback
    end)
end

local function releaseExpiredBomb()
    if released or not alive() then return true end
    local x,y,z = Spring.GetUnitPosition(unitID)
    local vx,vy,vz = Spring.GetUnitVelocity(unitID)
    local height = math.max(0,y-math.max(0,Spring.GetGroundHeight(x,z)))
    vy = math.min(-0.01,vy)
    local fallFrames = (vy+math.sqrt(vy*vy-2*gravity*height)) / -gravity
    local ttl = math.ceil(fallFrames) + 10*FPS
    projectileTimeoutFrames = ttl+FPS
    -- Passive exhaustion cannot be postponed by EMP or a distant target.
    -- Inherit the momentum left after native braking. Native gravity and
    -- collision own the terminal fall; AircraftBomb itself has no air drag.
    local projectileID = Spring.SpawnProjectile(weaponDefID, {
        pos={x,y,z}, speed={vx,vy,vz}, gravity=gravity, ttl=ttl,
        owner=unitID, team=Spring.GetUnitTeam(unitID), weapon=1,
    })
    if not projectileID then return false end
    -- ProjectileCreated normally runs synchronously inside SpawnProjectile.
    if not released then IcarusProjectileCreated(projectileID) end
    return true
end

expireGlide = function()
    if exhausted or stopped or released then return end
    exhausted = true
    Signal(SIG_GLIDE)
    Signal(SIG_WINGS)
    Signal(SIG_ORDERS)
    wings = "folding"
    setPhase("folding")
    StartThread(function()
        SetSignalMask(SIG_WINGS)
        foldWings()
        if stopped or released then return end
        wings = "folded"
        brakeForDrop()
        -- Bounded native braking, independent of EMP or commands. Always yield
        -- before spawning, including if a BlockShot callback triggered expiry.
        Sleep(math.max(1,brakeReadyFrame-Spring.GetGameFrame())*FRAME_MS)
        if stopped or released then return end
        if releaseExpiredBomb() then return end
        Sleep(FRAME_MS)
        if stopped or released or releaseExpiredBomb() then return end
        -- A failed spawn must not turn an exhausted glider immortal.
        Spring.Echo("[Icarus] Exhaustion bomb creation failed; starting native crash",unitID)
        if GG.AircraftCrash and GG.AircraftCrash(unitID) then return end
        BeginAircraftCrash()
        Spring.SetUnitCrashing(unitID, true)
    end)
end

local function foldClearance(ground,vx,vy,vz)
    local speed = math.max(nativeMaxSpeed, math.sqrt(vx*vx+vz*vz)*FPS)
    local downward = math.max(sinkRate, -vy*FPS)
    -- Reserve the entire next sampling interval, wing animation and native
    -- braking dwell. Full bomb gravity is conservative while still an aircraft.
    -- The horizontal travel allowance also keeps fast gliders out of roof gaps.
    local seconds = UPDATE_SECONDS+FOLD_SECONDS+brakeSeconds
    local reserve = math.max(terminalHeight, speed*seconds,
        downward*seconds+0.5*gravityPerSecond*seconds*seconds)
    return math.max(ground,GG.IcarusSkylineHeight or 0)+reserve
end

checkClearance = function(frame)
    if exhausted or stopped or released then return false end
    if not glideStarted then return true end
    frame = frame or Spring.GetGameFrame()
    local x,y,z = Spring.GetUnitPosition(unitID)
    local vx,vy,vz = Spring.GetUnitVelocity(unitID)
    local ground = math.max(0,Spring.GetGroundHeight(x,z))
    local floorY = foldClearance(ground,vx,vy,vz)
    local requiredAGL = math.max(terminalHeight,floorY-ground)
    local deadline = glideStarted+math.max(0,
        math.ceil((cruiseHeight-requiredAGL)/sinkRate*FPS))
    -- The shared city roof is fixed. Faster descent or movement over lower
    -- terrain can spend the allowance; climbing or orders cannot refill it.
    if deadline < glideDeadline then
        glideDeadline = deadline
        Spring.SetUnitRulesParam(unitID,"icarus_glide_end_frame",deadline,{inlos=true})
    end
    if not clearanceY or math.ceil(floorY) ~= math.ceil(clearanceY) then
        Spring.SetUnitRulesParam(unitID,"icarus_fold_height",floorY,{inlos=true})
    end
    clearanceY = floorY
    if frame >= glideDeadline or y <= floorY then
        expireGlide()
        return false,requiredAGL
    end
    return true,requiredAGL
end

local function glideLifetime()
    glideStarted = Spring.GetGameFrame()
    glideDeadline = glideStarted+glideFrames
    Spring.SetUnitRulesParam(unitID,"icarus_glide_start_frame",glideStarted,{inlos=true})
    Spring.SetUnitRulesParam(unitID,"icarus_glide_end_frame",glideDeadline,{inlos=true})
    Spring.SetUnitRulesParam(unitID,"icarus_sink_rate",sinkRate,{inlos=true})
    if not checkClearance(glideStarted) then return end
    refreshOrder()
    -- Stagger same-frame spawns instead of waking a whole swarm together.
    local sleepFrames = math.min(glideDeadline-glideStarted,FPS-(glideStarted+unitID)%FPS)
    prepareAttack()
    while not stopped and not released do
        Sleep(sleepFrames*FRAME_MS)
        if stopped or released then return end
        local frame = Spring.GetGameFrame()
        local safe,requiredAGL = checkClearance(frame)
        if not safe then return end
        -- This namespace also exposes NATIVE movement configuration. The setter
        -- does not enable MoveCtrl or write position, velocity or steering.
        Spring.MoveCtrl.SetAirMoveTypeData(unitID,"wantedHeight",
            math.max(requiredAGL,cruiseHeight-sinkRate*(frame-glideStarted)/FPS))
        prepareAttack()
        sleepFrames = math.min(FPS,glideDeadline-frame)
    end
end

local function revealUnfold()
    SetSignalMask(SIG_GLIDE)
    hideAll(unitID)
    setUnitNeverLand(unitID, true)
    showT(pieces.Sabot)
    Show(Cartdrige)
    if not waitTillComplete(unitID) or not alive() then return end
    -- The generated city's one map-wide roof calculation must finish before
    -- any payload unfolds. This wait is outside the finite airborne budget.
    while alive() and (Spring.GetUnitIsStunned(unitID) or GG.IcarusSkylineReady == false) do
        Sleep(100)
    end
    if not alive() then return end

    local x,y,z = Spring.GetUnitPosition(unitID)
    local launchTop = y+2048
    -- Read the native profile before launch MoveCtrl temporarily replaces it.
    -- Its actual (possibly modified) speed also sizes the launch clearance test.
    local moveData = Spring.GetUnitMoveTypeData(unitID)
    nativeMaxSpeed = math.max(1,(moveData and moveData.maxSpeed) or flightSpeed)
    foldedSpeed = nativeMaxSpeed*foldedSpeedFactor
    if GG.NimrodLaunchFX and GG.NimrodLaunchFX.Departure then
        GG.NimrodLaunchFX.Departure(unitID, launchTop)
    end
    Spring.MoveCtrl.Enable(unitID)
    Spring.MoveCtrl.SetGravity(unitID, 0)
    Spring.MoveCtrl.SetVelocity(unitID, 0, 0, 0)
    setPhase("ascent")
    moveT(pieces.Sabot,y_axis,-1000,200)
    for _, sabot in pairs(pieces.Sabot or {}) do spinRand(sabot,15,50) end
    local climbed, step = 0, 250
    while climbed < 2048 and alive() do
        if Spring.GetUnitIsStunned(unitID) then
            Sleep(100)
        else
            climbed = math.min(2048,climbed+step)
            Spring.MoveCtrl.SetPosition(unitID,x,y+climbed,z)
            if climbed > 1700 then step = math.max(50,step*0.97) end
            Sleep(FRAME_MS)
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
    Turn(Base,x_axis,math.rad(90),15)
    Turn(Base,z_axis,math.rad(90),15)
    spinT(pieces.TailRotor,y_axis,math.rad(42))
    -- A launch underneath an unusually high skyline must stay folded too.
    if launchTop > foldClearance(math.max(0,Spring.GetGroundHeight(x,z)),0,0,0) then
        setPhase("unfolding")
        unfoldWings()
        wings = "open"
    else
        wings = "folded"
    end
    if not alive() then return end
    Spring.MoveCtrl.Disable(unitID)
    Spring.MoveCtrl.SetAirMoveTypeData(unitID,"wantedHeight",cruiseHeight)
    -- StartMoving enters native takeoff/flying even without a player order.
    -- This one goal seeds idle circling; later commands belong to AirCAI.
    Spring.SetUnitMoveGoal(unitID,x,launchTop,z)
    nativeReady = true
    glideLifetime()
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
    Signal(SIG_GLIDE+SIG_WINGS+SIG_ORDERS+SIG_CLEANUP)
    if Spring.MoveCtrl.GetTag(unitID) then Spring.MoveCtrl.Disable(unitID) end
end

function script.HitByWeapon(_,_,_,damage)
    if released then return 0 end
    return damage
end

function script.Killed()
    stopped = true
    Signal(SIG_GLIDE+SIG_WINGS+SIG_ORDERS+SIG_CLEANUP)
    impactProjectile = nil
    return 1
end

function script.StartMoving() end
function script.StopMoving() end
function script.Activate() return 1 end
function script.Deactivate() return 0 end
function script.AimFromWeapon1() return Base end
function script.QueryWeapon1() return Base end
function script.AimWeapon1() return nativeReady and wings == "folded" end

function script.BlockShot1(targetID,userTarget)
    if not nativeReady or stopped or released or committed or exhausted or orderDirty
        or not userTarget or not isDesignation(currentOrder) or Spring.GetUnitIsStunned(unitID) then
        return true
    end
    if not checkClearance() then return true end
    local tx,ty,tz = targetPosition()
    if not tx then return true end
    local p = currentOrder.params
    if #p == 1 then
        if targetID ~= p[1] then return true end
    else
        local targetType,explicit,position = Spring.GetUnitWeaponTarget(unitID,1)
        if targetType ~= 2 or not explicit or type(position) ~= "table"
            or math.abs(position[1]-tx) > 1 or math.abs(position[3]-tz) > 1 then return true end
    end
    if wings ~= "folded" then beginFold(); return true end
    if not brakeReadyFrame or Spring.GetGameFrame() < brakeReadyFrame then return true end
    return false
end

function script.FireWeapon1()
    -- Native release still needs to sample its muzzle and motion. The projectile
    -- creation event, rather than this callback, hides the spent aircraft.
    committed = true
end
