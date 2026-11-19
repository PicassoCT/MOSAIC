-- Run through run.sh with Lua 5.1+. Authored-anchor animation and exact cleanup.
local compile = loadstring or load
local function read(path)
    local file = assert(io.open(path)); local text = file:read('*a'); file:close(); return text
end
local source = read('scripts/lib_human_shield_pose.lua')
local header = read('gamedata/unit_script_header.lua')
local actualAxes = {
    tonumber(assert(header:match('local x_axis = (%d+)'))),
    tonumber(assert(header:match('local y_axis = (%d+)'))),
    tonumber(assert(header:match('local z_axis = (%d+)'))),
}
local function run(axes)
    local moves, turns, originalMoves, originalTurns = {}, {}, {}, {}
    local moveTargets, turnTargets = {}, {}
    local writes = 0
    local pieces = {
        root=1, center=2, UpBody=3, Head1=4, UpArm1=5, UpArm2=6,
        LowArm1=7, LowArm2=8, UpLeg1=9, UpLeg2=10, LowLeg1=11,
        LowLeg2=12, Feet1=13, Feet2=14,
    }
    for id=1,14 do
        moves[id]={id/10,-3,id/20}; turns[id]={id/30,id/40,id/50}
        originalMoves[id]={unpack(moves[id])}; originalTurns[id]={unpack(turns[id])}
        -- An ordinary walking animation already has unfinished native targets.
        moveTargets[id]={9,8,7}; turnTargets[id]={6,5,4}
    end
    local moving = false
    local seated = false
    local env = setmetatable({x_axis=axes[1],y_axis=axes[2],z_axis=axes[3]}, {__index=_G})
    env.Spring = {
        UnitScript = {
            GetPieceTranslation=function(p) return unpack(moves[p]) end,
            GetPieceRotation=function(p) return unpack(turns[p]) end,
        },
        GetUnitPieceMap=function() error('native attachment owns the authored hostagePoint') end,
        GetUnitPiecePosition=function() error('animation must not cancel the authored hostagePoint offset') end,
        GetUnitCollisionVolumeData=function() error('authored anchor must not be replaced by guessed body spacing') end,
        GetUnitTransporter=function(id) assert(id==42); return seated and 99 or nil end,
        GetUnitVelocity=function(id)
            assert(id==42, 'the carrier drives the captive gait')
            if moving then return 2,0,1,math.sqrt(5) end
            return 0,0,0,0
        end,
    }
    env.Move=function(p,a,t,speed)
        writes=writes+1
        if speed==0 then moves[p][a]=t else moveTargets[p][a]=t end
    end
    env.Turn=function(p,a,t,speed)
        writes=writes+1
        if speed==0 then turns[p][a]=t else turnTargets[p][a]=t end
    end
    local function finishNativeAnimations()
        for id=1,14 do
            for axis=1,3 do
                moves[id][axis]=moveTargets[id][axis]
                turns[id][axis]=turnTargets[id][axis]
            end
        end
    end
    local makePose
    if setfenv then makePose=setfenv(assert(compile(source)),env)()
    else makePose=assert(load(source,'human shield pose','t',env))() end
    local pose=makePose(17,pieces)
    assert(writes==0, 'constructing a pose performs no engine mutations')
    pose:Capture(42)
    for axis=1,3 do
        assert(moves[1][axis]==0,
            'authored hostagePoint places neutral captive root on native axis '..axis)
    end
    assert(turns[5][axes[1]]<0 and turns[6][axes[1]]<0, 'both arms visibly held up')
    local capturedMoves, capturedTurns = {}, {}
    for id=1,14 do
        capturedMoves[id]={unpack(moves[id])}; capturedTurns[id]={unpack(turns[id])}
    end
    finishNativeAnimations()
    for id=1,14 do
        for axis=1,3 do
            assert(moves[id][axis]==capturedMoves[id][axis] and turns[id][axis]==capturedTurns[id][axis],
                'previous native animations must not drift the held pose')
        end
    end
    local capturedWrites=writes
    pose:Capture(42)
    assert(writes==capturedWrites, 'duplicate capture preserves original transform snapshot')

    pose:Animate(42, 10)
    finishNativeAnimations()
    local idleHead, idleArm = turns[4][axes[1]], turns[5][axes[1]]
    local idleLeg = turns[9][axes[1]]
    pose:Animate(42, 16)
    finishNativeAnimations()
    assert(turns[4][axes[1]]~=idleHead or turns[5][axes[1]]~=idleArm,
        'restrained idle has breathing or struggle motion, not only a static pose')
    moving=true
    pose:Animate(42, 10)
    finishNativeAnimations()
    local movingLeg=turns[9][axes[1]]
    assert(movingLeg~=idleLeg, 'moving carrier gives hostage a restrained shuffling gait')
    pose:Animate(42, 16)
    finishNativeAnimations()
    assert(turns[9][axes[1]]~=movingLeg, 'shuffling legs actually advance through their cycle')
    seated=true
    pose:Animate(42, 10); finishNativeAnimations()
    local seatedHip, seatedKnee = turns[9][axes[1]], turns[11][axes[1]]
    assert(seatedHip~=movingLeg and seatedKnee>0,
        'car transport gives the held civilian a bent seated pose')
    pose:Animate(42, 16); finishNativeAnimations()
    assert(turns[9][axes[1]]==seatedHip and turns[11][axes[1]]==seatedKnee,
        'a moving car does not make the seated hostage shuffle')
    for axis=1,3 do
        assert(moves[1][axis]==0, 'idle and shuffle do not displace the authored attachment origin')
    end
    pose:Release()
    finishNativeAnimations()
    for id=1,14 do
        for axis=1,3 do
            assert(moves[id][axis]==originalMoves[id][axis], 'all translations restored')
            assert(turns[id][axis]==originalTurns[id][axis], 'all rotations restored')
        end
    end
    local restoredWrites=writes
    pose:Animate(42, 20)
    assert(writes==restoredWrites, 'a stale animation update cannot mutate a released civilian')
    pose:Release()
    assert(writes==restoredWrites, 'duplicate release is inert')
    pose:Capture(42); pose:Release(); finishNativeAnimations()
    for id=1,14 do
        for axis=1,3 do
            assert(moves[id][axis]==originalMoves[id][axis] and turns[id][axis]==originalTurns[id][axis],
                'recapture must snapshot the restored pose')
        end
    end
end
run(actualAxes)
run({1,2,3})

-- Execute the real civilian ownership callbacks with intentionally uncancelled
-- coroutines. Even if a stale callback wakes, its generation cannot touch the
-- next capture's pose or restart ambient activity while the civilian is dying.
local civilianSource=read('scripts/civilianscript.lua')
local first=assert(civilianSource:find('function canBeHumanShield()',1,true))
local following=assert(civilianSource:find('function civilianPhoneCall(',first,true))
local callbacks=civilianSource:sub(first,following-1)
local function lifecycle()
    local state={threads={},frames=0,animated=0,captured=0,released=0,resumed=0,
        fled=0,signals=0,position={120,0,30},carrierPosition={100,0,30}}
    local env=setmetatable({unitID=17,humanShieldGeneration=0,humanShieldEscapeSprint=false,
        bodyConfig={},GG={},Game={mapSizeX=200,mapSizeZ=200},
        GameConfig={civilians={panic={fleeDistance=120}}},TablesOfPiecesGroups={},
        eAnimState={standing='standing'},SPRINT_SPEED=1,NORMAL_WALK_SPEED=0.5,
        SIG_ANIM=1,SIG_UP=2,SIG_LOW=4,SIG_BEHAVIOUR_STATE_MACHINE=8,
        SIG_PISTOL=16,SIG_MOLOTOW=32,SIG_RPG=64,SIG_STOP=128,SIG_HUMAN_SHIELD=2048},
        {__index=_G})
    env.Spring={
        GetUnitTransporter=function() return nil end,
        GetGameFrame=function() return state.frames end,
        GetUnitPosition=function(id)
            if id==17 then return unpack(state.position) end
            assert(id==42,'only the previous carrier supplies the escape origin')
            return unpack(state.carrierPosition)
        end,
        SetUnitMoveGoal=function(id,x,y,z)
            assert(id==17,'the liberated civilian owns the escape goal')
            state.goal={x,y,z}
        end,
    }
    env.humanShieldPose={
        Capture=function(_,id) assert(id==42); state.captured=state.captured+1 end,
        Release=function() state.released=state.released+1 end,
        Animate=function(_,id) assert(id==42); state.animated=state.animated+1 end,
    }
    env.externalInterruptCivilian=function() env.humanShieldEscapeSprint=false end
    env.setOverrideAnimationState=function() state.resumed=state.resumed+1 end
    env.getWalkingState=function() return 'walking' end
    env.startFleeing=function(id) assert(id==42); state.fled=state.fled+1 end
    env.setSpeedEnv=function(id,speed) assert(id==17); state.speed=speed end
    env.Signal=function() state.signals=state.signals+1 end
    env.SetSignalMask=function(mask) assert(mask==env.SIG_HUMAN_SHIELD) end
    env.Sleep=function() coroutine.yield() end
    env.StartThread=function(fn,...)
        local thread=coroutine.create(fn)
        state.threads[#state.threads+1]=thread
        assert(coroutine.resume(thread,...))
        return thread
    end
    env.queueEventThread=function() state.queued=true end
    if setfenv then setfenv(assert(compile(callbacks)),env)()
    else assert(load(callbacks,'civilian shield callbacks','t',env))() end
    return state,env
end
local state,env=lifecycle()
assert(env.canBeHumanShield(),'ordinary civilian is initially eligible')
env.bodyConfig.boolArmed=true
assert(not env.setHumanShieldCarrier(42),'armed civilian callback vetoes capture')
env.bodyConfig.boolArmed=false
assert(env.setHumanShieldCarrier(42),'civilian capture callback succeeds')
assert(state.captured==1 and state.animated==1 and #state.threads==1,
    'capture starts one live animation immediately')
env.setHumanShieldCarrier(42)
assert(state.captured==1 and #state.threads==1,'duplicate callback does not replace original ownership')
local stale=state.threads[1]
env.setHumanShieldCarrier(nil)
assert(state.released==1 and state.resumed==1 and state.fled==0,
    'ordinary release restores animation without forcing a panic escape')
env.setHumanShieldCarrier(42)
local count=state.animated
assert(coroutine.resume(stale))
assert(coroutine.status(stale)=='dead' and state.animated==count,
    'old capture coroutine cannot overwrite a new capture from the same carrier')
env.setHumanShieldCarrier(nil,'melee')
assert(state.fled==1 and env.humanShieldEscapeSprint and state.speed==env.SPRINT_SPEED,
    'melee liberation orders the civilian to flee the former carrier at sprint speed')
assert(state.goal[1]==200 and state.goal[3]==30,'escape vector is normalized and clamped to map bounds')

state,env=lifecycle()
state.position={100,0,100}; state.carrierPosition={100,0,100}
env.setHumanShieldCarrier(42); env.setHumanShieldCarrier(nil,'melee')
for _,axis in ipairs({1,3}) do
    local coordinate=state.goal[axis]
    assert(coordinate==coordinate and coordinate>=0 and coordinate<=200,
        'coincident origins still produce a finite in-map escape goal')
end
state,env=lifecycle()
state.position={100,0,100}; state.carrierPosition={100,0,150}
env.setHumanShieldCarrier(42); env.setHumanShieldCarrier(nil,'melee')
assert(state.goal[3]==0,'escape direction remains away from a carrier to the south')
state,env=lifecycle()
env.setHumanShieldCarrier(42); env.boolDying=true; env.setHumanShieldCarrier(nil,'melee')
assert(state.released==1 and state.resumed==0 and state.fled==0,
    'death restores the model without starting ambient or flee activity')
print('PASS: Human Shield captive animation preserves authored hostagePoint, idles and shuffles, restores transforms, rejects stale loops and safely flees on melee liberation')
