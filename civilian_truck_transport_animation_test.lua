-- Exercise the real passenger pose and civilian lifecycle under native-style
-- queued movement semantics. Run with the external MOSAIC test runner.
local compile = loadstring or load
local function read(path)
    local f = assert(io.open(path)); local text = f:read('*a'); f:close()
    return text:gsub('\r\n', '\n')
end
local function execute(source, env)
    setmetatable(env, {__index = _G})
    if setfenv then return setfenv(assert(compile(source)), env)() end
    return assert(load(source, 'civilian passenger regression', 't', env))()
end
local function functionSource(source, name)
    local first = assert(source:find('function '..name..'(', 1, true), name)
    local last = assert(source:find('\nend', first, true), name..' end')
    return source:sub(first, last + 3)
end
local function copyVector(v) return {v[1], v[2], v[3]} end
local function near(a, b, message) assert(math.abs(a - b) < 1e-8, message) end

local helperSource = read('scripts/lib_civilian_transport.lua')
local scriptSource = read('scripts/civilianscript.lua')
local function fixture()
    local w = {frame = 0, carriers = {}, defs = {[101]=10, [102]=11, [103]=12,
        [104]=13, [105]=14}, velocity = {}, writes = 0, begins = 0,
        finishes = {}, reclaims = 0, threads = {}, queued = {}}
    local pieces = {root=1, center=2, UpBody=3, Head1=4, UpArm1=5, UpArm2=6,
        LowArm1=7, LowArm2=8, UpLeg1=9, UpLeg2=10, LowLeg1=11,
        LowLeg2=12, Feet1=13, Feet2=14}
    w.moves, w.turns, w.moveTargets, w.turnTargets = {}, {}, {}, {}
    w.savedMoves, w.savedTurns = {}, {}
    for _, id in pairs(pieces) do
        w.moves[id] = {id / 10, -3, id / 20}
        w.turns[id] = {id / 50, id / 60, id / 70}
        w.savedMoves[id], w.savedTurns[id] = copyVector(w.moves[id]), copyVector(w.turns[id])
        -- These are already-running native targets when boarding occurs.
        w.moveTargets[id], w.turnTargets[id] = {9, 8, 7}, {6, 5, 4}
    end
    function w.flush()
        for _, id in pairs(pieces) do
            w.moves[id], w.turns[id] = copyVector(w.moveTargets[id]), copyVector(w.turnTargets[id])
        end
    end
    function w.assertRestored()
        for _, id in pairs(pieces) do
            for axis=1,3 do
                near(w.moves[id][axis], w.savedMoves[id][axis], 'unload restores translation')
                near(w.turns[id][axis], w.savedTurns[id][axis], 'unload restores rotation')
            end
        end
    end
    local env = {unitID=42, x_axis=1, y_axis=2, z_axis=3,
        UnitDefs = {[10]={customParams={baseclass='Truck'}},
            [11]={customParams={baseclass='truck'}},
            [12]={customParams={}}, [13]={customParams={}}, [14]={customParams={baseclass='Aircraft'}}},
        UnitDefNames = {truckpayloadrefugee={id=12}, air_parachut={id=13}},
        Spring = {
            GetUnitTransporter = function(id) return w.carriers[id] end,
            GetUnitDefID = function(id) return w.defs[id] end,
            GetGameFrame = function() return w.frame end,
            GetUnitVelocity = function(id)
                w.motionSample = id
                return unpack(w.velocity[id] or {0, 0, 0})
            end,
            GetUnitVectors = function() return {0, 0, 1}, {0, 1, 0}, {1, 0, 0} end,
            UnitScript = {
                GetPieceTranslation = function(id) return unpack(w.moves[id]) end,
                GetPieceRotation = function(id) return unpack(w.turns[id]) end,
            },
        },
    }
    env.Move = function(id, axis, target, speed)
        w.writes = w.writes + 1
        if speed == 0 then w.moves[id][axis] = target else w.moveTargets[id][axis] = target end
    end
    env.Turn = function(id, axis, target, speed)
        w.writes = w.writes + 1
        if speed == 0 then w.turns[id][axis] = target else w.turnTargets[id][axis] = target end
    end
    local function overlaps(a, b)
        while a > 0 and b > 0 do
            if a % 2 == 1 and b % 2 == 1 then return true end
            a, b = math.floor(a / 2), math.floor(b / 2)
        end
        return false
    end
    function w.resume(thread, ...)
        if thread.cancelled or coroutine.status(thread.co) == 'dead' then return end
        w.current = thread
        local ok, err = coroutine.resume(thread.co, ...)
        w.current = nil
        assert(ok, err)
    end
    env.StartThread = function(fn, ...)
        local thread = {co=coroutine.create(fn), mask=0}
        w.threads[#w.threads+1] = thread; w.resume(thread, ...); return thread
    end
    env.Sleep = function(ms) return coroutine.yield(ms) end
    env.SetSignalMask = function(mask) if w.current then w.current.mask = mask end end
    env.Signal = function(mask)
        for _, thread in ipairs(w.threads) do
            if overlaps(thread.mask, mask) then thread.cancelled = true end
        end
    end
    local context = {
        blocked=function() return w.blocked end,
        upperBodyFree=function() return w.armed == true end,
        begin=function() w.begins=w.begins+1 end,
        reclaimUpper=function() w.reclaims=w.reclaims+1 end,
        finish=function(resume) w.finishes[#w.finishes+1]=resume end,
    }
    w.helper = execute(helperSource, env)(42, pieces, context)
    function w.step(frame)
        w.frame=frame
        return w.helper:Update(frame)
    end
    return w, env, pieces
end

do
    local w, env, p = fixture()
    assert(not w.step(0) and w.writes == 0 and w.begins == 0, 'walking pedestrians are unchanged')
    w.carriers[42]=101
    assert(w.step(3) and w.begins == 1 and w.helper:IsActive(), 'boarding starts passenger ownership')
    w.flush()
    assert(w.turns[p.UpLeg1][1] < -0.8 and w.turns[p.LowLeg1][1] > 1.3,
        'truck passengers fold thighs and knees into a seated pose')
    assert(math.abs(w.turns[p.UpArm1][1]) < 1, 'truck hands brace below the shoulders, not parachute overhead')
    local idleTorso = w.turns[p.UpBody][1]
    w.step(9); w.flush()
    assert(w.begins == 1 and w.turns[p.UpBody][1] ~= idleTorso, 'idle breathing does not recapture the snapshot')
    w.velocity[101]={2, 0, 3}; w.step(12); w.flush()
    assert(w.motionSample == 101, 'movement is sampled from the vehicle')
    local drivingTorso, drivingKnee = w.turns[p.UpBody][1], w.turns[p.LowLeg1][1]
    w.step(15); w.flush()
    assert(w.turns[p.LowLeg1][1] ~= drivingKnee, 'driving adds mild road movement')
    w.velocity[101]={0, 0, 0}; w.step(18); w.flush()
    assert(w.turns[p.UpBody][1] ~= drivingTorso, 'stopping changes the passenger brace')
    near(w.turns[p.UpLeg1][1], math.rad(-65), 'driving never starts a walking gait')
    w.carriers[42]=nil; assert(not w.step(21)); w.flush(); w.assertRestored()
    assert(not w.helper:IsActive() and w.finishes[1] == true, 'unload resumes normal activity once')
    local writes = w.writes
    w.step(24); w.helper:Stop(); assert(w.writes == writes and #w.finishes == 1, 'idle cleanup is inert')

    -- Another truck variant, a nested refugee seat and a direct transport swap.
    w.carriers[42]=102; w.step(30); w.flush()
    w.carriers[42]=103; w.carriers[103]=101; w.velocity[101]={1, 0, 2}
    w.step(33); w.flush()
    assert(w.motionSample == 101 and w.finishes[2] == false, 'nested refugee payload samples its truck and swaps without ambient restart')
    w.carriers[42]=104; w.step(36); w.flush()
    assert(w.turns[p.UpArm1][1] < -2 and w.turns[p.LowLeg1][1] < 0.6,
        'real parachutes use raised hands and suspended legs')
    w.carriers[42]=105; assert(not w.step(39)); w.flush(); w.assertRestored()
    assert(w.finishes[#w.finishes] == true, 'unrecognized transport releases the dedicated passenger pose')
    w.carriers[42]=101; w.step(42); w.flush()
    w.blocked=true; assert(not w.step(45)); w.flush(); w.assertRestored()
    assert(w.finishes[#w.finishes] == false, 'hostage, stun and death owners take priority without restarting ambient animation')
    writes=w.writes; w.step(48); assert(w.writes == writes, 'blocked passenger controller cannot overwrite the higher-priority pose')
    w.blocked=false; w.step(51); w.flush()
    w.carriers[42]=nil; w.step(54); w.flush(); w.assertRestored()
end

do
    local w, env, p = fixture()
    w.armed=true; w.carriers[42]=101; w.step(0)
    assert(w.helper:IsActive() and not w.helper:OwnsUpperBody(), 'armed passengers retain firing/aiming torso ownership')
    assert(w.helper:OwnsPiece(p.UpLeg1) and not w.helper:OwnsPiece(p.UpArm1), 'seat still owns armed passenger legs')
    -- Simulate a weapon taking a fresh aiming pose while the truck drives.
    for _, id in ipairs({p.center,p.UpBody,p.Head1,p.UpArm1,p.UpArm2,p.LowArm1,p.LowArm2}) do
        env.Turn(id, 1, 0.87, 1); env.Move(id, 2, 0.63, 1)
    end
    w.flush(); w.carriers[42]=nil; w.step(3); w.flush()
    near(w.turns[p.UpArm1][1], 0.87, 'unloading does not rewind an independently aimed arm')
    near(w.moves[p.UpBody][2], 0.63, 'unloading does not restore unowned torso transforms')
    w.carriers[42]=101; w.step(6); w.flush()
    w.armed=false; w.step(9); w.flush()
    assert(w.helper:OwnsUpperBody() and w.reclaims==1, 'disarming returns the torso to the seated brace')
    assert(w.turns[p.UpArm1][1] ~= 0.87, 'newly owned arms enter the brace')
    w.armed=true; w.step(12); w.flush()
    near(w.turns[p.UpArm1][1], 0.87, 'releasing the upper body replaces old bracing targets')
    near(w.moves[p.UpBody][2], 0.63, 'released upper body restores the pose at its latest acquisition')
end

-- Actual civilian callbacks, including a deferred pre-boarding animation request.
do
    local w, env, p = fixture()
    for name, id in pairs(p) do env[name]=id end
    for name, value in pairs({SIG_ANIM=1,SIG_UP=2,SIG_LOW=4,SIG_COVER_WALK=8,
        SIG_BEHAVIOUR_STATE_MACHINE=16,SIG_PISTOL=32,SIG_MOLOTOW=64,
        SIG_INTERNAL=128,SIG_RPG=256,SIG_STOP=512,SIG_PARADE=1024,
        SIG_HUMAN_SHIELD=2048,SIG_TRANSPORT=4096}) do env[name]=value end
    env.script={}; env.bodyConfig={}; env.TablesOfPiecesGroups={}
    env.GG={CivilianUnitInternalLogicActive={}}
    env.eAnimState={standing='standing',walking='walking',aiming='aiming'}
    env.boolWalking=false; env.humanShieldGeneration=0
    env.NORMAL_WALK_SPEED=1; env.cellphone1=88
    env.Hide=function() end; env.hideT=function() end
    env.paradeParticipation={Stop=function() end}
    env.setSpeedEnv=function() end
    env.getWalkingState=function() return 'walking' end
    env.spGetGameFrame=env.Spring.GetGameFrame
    env.queueEventThread=function(kind, fn, delay, ...)
        w.queued[#w.queued+1]={kind=kind, fn=fn, args={...}}
    end
    env.animationStateMachineUpper=function() w.upperStarts=(w.upperStarts or 0)+1 end
    env.animationStateMachineLower=function() w.lowerStarts=(w.lowerStarts or 0)+1 end
    for _,name in ipairs({'setOverrideAnimationState','deferedOverrideAnimationState',
        'setAnimationState','externalInterruptCivilian','civilianTransportLoop',
        'script.StartMoving','script.StopMoving'}) do
        execute(functionSource(scriptSource,name),env)
    end
    env.include=function(name)
        assert(name=='lib_civilian_transport.lua'); return execute(helperSource,env)
    end
    local first=assert(scriptSource:find('passengerTransport = include("lib_civilian_transport.lua")',1,true))
    local last=assert(scriptSource:find('\nfunction civilianTransportLoop()',first,true))
    execute(scriptSource:sub(first,last-1),env)
    w.helper=env.passengerTransport
    env.setOverrideAnimationState('walking','walking',true,nil,true)
    local deferred=w.queued[#w.queued]
    w.queued={}; w.carriers[42]=101
    local loop=env.StartThread(env.civilianTransportLoop); w.flush()
    assert(w.helper:IsActive() and loop.mask==env.SIG_TRANSPORT, 'real script loop takes ownership on boarding')
    deferred.fn(unpack(deferred.args))
    assert(not w.upperStarts and not w.lowerStarts, 'pre-boarding deferred walk cannot steal the passenger pose')
    env.script.StartMoving(); env.script.StopMoving()
    assert(#w.queued==0, 'transport start/stop callbacks cannot schedule walking or delayed standing')
    env.boolStartChatting=true
    execute(functionSource(scriptSource,'threadStateStarter'),env)
    env.threadStateStarter()
    assert(env.boolStartChatting==true, 'ambient dispatcher does not start a pose while seated')
    for _, name in ipairs({'startPhoneCall','startPraying','startChatting','startFleeing','startAnarchyBehaviour'}) do
        execute(functionSource(scriptSource,name),env)
        assert(env[name](100)==false, 'new '..name..' request is rejected while a passenger')
    end

    -- Per-piece filtering also protects against any unsignalled old clip.
    env.animCmd={turn=env.Turn,move=env.Move}; env.axisSign={1,1,1}
    env.upperBodyPieces={[p.UpArm1]=true}; env.isPrayerGestureActive=function() return false end
    env.bagAlignment={owns=function() return false end,poseCommand=function() end}
    env.addBagsSwingImpulse=function() end
    env.Animations={probe={{time=0,commands={
        {c='turn',p=p.UpLeg1,a=1,t=0.9,s=1},{c='turn',p=p.UpArm1,a=1,t=0.9,s=1}}}}}
    execute(functionSource(scriptSource,'PlayAnimation'),env)
    local writes=w.writes
    env.PlayAnimation('probe'); assert(w.writes==writes, 'a stale clip cannot overwrite owned legs or arms')
    env.bodyConfig.boolArmed=true; w.frame=3; w.resume(loop); w.flush()
    env.PlayAnimation('probe'); w.flush()
    near(w.turns[p.UpArm1][1],0.9,'armed passenger animations can still aim the free torso')
    assert(w.turns[p.UpLeg1][1]~=0.9,'aiming animation cannot overwrite seated legs')
    env.setOverrideAnimationState('aiming','walking',true,nil,true)
    assert(w.queued[#w.queued].args[1]=='aiming' and w.queued[#w.queued].args[2]==nil,
        'armed passenger requests retain upper aiming and remove lower walking')

    -- Death restores the native model before death choreography begins and
    -- cancels the polling owner; it cannot wake and reseat the corpse.
    env.setHumanShieldCarrier=function() end
    env.dropLoot=function() end
    env.bagAlignment.remove=function() end
    env.deathAnimation=function()
        assert(not w.helper:IsActive(),'death takes ownership after passenger cleanup')
        w.deathWrites=w.writes
    end
    execute(functionSource(scriptSource,'script.Killed'),env)
    assert(env.script.Killed(1,100)==1 and loop.cancelled,'death cancels the passenger owner')
    w.resume(loop); assert(w.writes==w.deathWrites,'cancelled passenger loop cannot overwrite the death pose')
end

-- A newly unloaded passenger can be captured before the 100 ms poll runs.
do
    local w, env, p=fixture()
    w.carriers[42]=101; w.step(0); w.flush()
    env.passengerTransport=w.helper; env.humanShieldGeneration=0
    env.canBeHumanShield=function() return true end
    env.externalInterruptCivilian=function() end
    env.TablesOfPiecesGroups={}
    env.SIG_ANIM=1;env.SIG_UP=2;env.SIG_LOW=4;env.SIG_BEHAVIOUR_STATE_MACHINE=16
    env.SIG_PISTOL=32;env.SIG_MOLOTOW=64;env.SIG_RPG=256;env.SIG_STOP=512;env.SIG_HUMAN_SHIELD=2048
    env.animateHumanShield=function() end
    env.humanShieldPose={Capture=function()
        assert(not w.helper:IsActive(),'seat is released before the hostage snapshot')
        w.flush();w.assertRestored()
    end}
    execute(functionSource(scriptSource,'setHumanShieldCarrier'),env)
    w.carriers[42]=nil
    assert(env.setHumanShieldCarrier(99),'same-frame unload and capture succeeds')
    assert(env.humanShieldCarrier==99 and w.finishes[1]==false,
        'capture transfers pose ownership without briefly restarting ambient animation')
end

print('PASS: Civilian passengers sit and brace in trucks, preserve parachutes and armed aiming, restore native transforms, respect hostage/death ownership, and reject stale ambient animation')
