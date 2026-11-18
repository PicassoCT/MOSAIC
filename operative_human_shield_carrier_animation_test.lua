-- Actual carrier helper and operative callbacks. Run through the external runner.
local compile=loadstring or load
local function read(path)
    local file=assert(io.open(path)); local text=file:read('*a'); file:close()
    return text:gsub('\r\n','\n')
end
local function execute(source,env)
    setmetatable(env,{__index=_G})
    if setfenv then return setfenv(assert(compile(source)),env)() end
    return assert(load(source,'human shield carrier regression','t',env))()
end
local function near(a,b,message) assert(math.abs(a-b)<1e-9,message) end
local helper=read('scripts/lib_human_shield_carrier_animation.lua')
local function helperTest(yawAxis,withHands)
    local state={frame=0,writes=0,threads={},aimChanges={},moving=false,seated=false}
    local pieces={center=1,Torso=2,Head=3,UpArm1=4,UpArm2=5,LowArm1=6,LowArm2=7,
        UpLeg1=8,UpLeg2=9,LowLeg1=10,LowLeg2=11,hostagePoint=99}
    if withHands then pieces.Hand1=12; pieces.Hand2=13 end
    local moves,turns,moveTargets,turnTargets,originalMoves,originalTurns={},{},{},{},{},{}
    for name,id in pairs(pieces) do
        if name~='hostagePoint' then
            moves[id]={id/10,-3,id/20}; turns[id]={id/30,id/40,id/50}
            originalMoves[id]={unpack(moves[id])}; originalTurns[id]={unpack(turns[id])}
            moveTargets[id]={9,8,7}; turnTargets[id]={6,5,4}
        end
    end
    local function finishNative()
        for id in pairs(moves) do
            for axis=1,3 do moves[id][axis]=moveTargets[id][axis]; turns[id][axis]=turnTargets[id][axis] end
        end
    end
    local env={}
    env.Spring={
        GetGameFrame=function() return state.frame end,
        GetUnitVelocity=function(id) assert(id==42); return state.moving and 2 or 0,0,0 end,
        GetUnitTransporter=function(id) assert(id==42); return state.seated and 88 or nil end,
        UnitScript={
            GetPieceTranslation=function(id) return unpack(moves[id]) end,
            GetPieceRotation=function(id) return unpack(turns[id]) end,
        },
    }
    env.Move=function(id,axis,target,speed)
        assert(id~=99,'carrier animation must leave the authored hostagePoint untouched')
        state.writes=state.writes+1
        if speed==0 then moves[id][axis]=target else moveTargets[id][axis]=target end
    end
    env.Turn=function(id,axis,target,speed)
        assert(id~=99,'carrier animation must not rotate the authored hostagePoint')
        state.writes=state.writes+1
        if speed==0 then turns[id][axis]=target else turnTargets[id][axis]=target end
    end
    local function resumeThread(thread,...)
        if thread.cancelled or coroutine.status(thread.co)=='dead' then return end
        state.current=thread
        local ok,err=coroutine.resume(thread.co,...)
        state.current=nil
        assert(ok,err)
    end
    env.StartThread=function(fn,...)
        local thread={co=coroutine.create(fn)}
        state.threads[#state.threads+1]=thread
        resumeThread(thread,...)
        return thread
    end
    env.Sleep=function() coroutine.yield() end
    env.SetSignalMask=function(mask) state.current.mask=mask end
    env.Signal=function(mask)
        for _,thread in ipairs(state.threads) do
            if thread.mask==mask then thread.cancelled=true end
        end
    end
    local animation=execute(helper,env)(42,pieces,{yawAxis=yawAxis,
        onAimChanged=function(aiming) state.aimChanges[#state.aimChanges+1]=aiming end})
    assert(state.writes==0 and not animation:IsActive(),'constructing carrier animation is inert')
    animation:Capture(); finishNative()
    assert(animation:IsActive() and #state.threads==1,'capture starts one restraint animation')
    local capturedWrites=state.writes
    animation:Capture()
    assert(state.writes==capturedWrites and #state.threads==1,'duplicate capture preserves original snapshot')
    animation:Step(10,false); finishNative()
    local idleTorso,idleHip=turns[2][1],turns[8][1]
    animation:Step(16,false); finishNative()
    assert(turns[2][1]~=idleTorso,'carrier restraint has living idle motion')
    animation:Step(10,true); finishNative()
    local strideHip=turns[8][1]
    assert(strideHip~=idleHip,'walking uses a restrained gait')
    animation:Step(16,true); finishNative()
    assert(turns[8][1]~=strideHip,'walking advances through the gait')
    animation:Step(10,true,true); finishNative()
    local seatedHip,seatedKnee=turns[8][1],turns[10][1]
    assert(seatedHip<0 and seatedKnee>0,'car transport uses a seated leg pose')
    animation:Step(16,true,true); finishNative()
    assert(turns[8][1]==seatedHip and turns[10][1]==seatedKnee,
        'a moving car does not trigger walking legs')
    state.frame=10; animation:Step(10,false); finishNative()
    local restrainedArm=turns[5][1]
    local relaxedArm=turns[4][1]
    animation:Aim(0.6,0.2); animation:Step(10,false); finishNative()
    assert(animation:IsActive() and animation:IsAiming(),'aim mode preserves active restraint')
    near(turns[2][yawAxis],0.6,'torso tracks aim on the authored model yaw axis')
    near(turns[5][1],restrainedArm,'the restraining arm keeps its grip while aiming')
    assert(turns[4][1]~=relaxedArm,'the free arm changes to an aim pose')
    assert(state.aimChanges[1]==true,'aim shows the held firearm through the supplied visibility callback')
    state.frame=44; animation:Step(44,false); finishNative()
    assert(animation:IsActive() and not animation:IsAiming(),'aim timeout returns to restraint without release')
    near(turns[2][yawAxis],0,'aim timeout removes torso aiming offset')
    assert(state.aimChanges[2]==false,'aim timeout restores non-aim weapon visibility')
    local oldThread=state.threads[1]
    animation:Release(); finishNative()
    assert(not animation:IsActive() and oldThread.cancelled,'release cancels the animation owner')
    for id in pairs(moves) do
        for axis=1,3 do
            assert(moves[id][axis]==originalMoves[id][axis] and turns[id][axis]==originalTurns[id][axis],
                'release restores all original transforms and replaces queued native targets')
        end
    end
    local restoredWrites=state.writes
    animation:Step(100,true); animation:Aim(1,1); animation:Release(); resumeThread(oldThread)
    assert(state.writes==restoredWrites,'released animation and cancelled loop cannot mutate the model')
    animation:Capture(); local count=state.writes
    -- Also exercise the generation guard independently of signal cancellation.
    oldThread.cancelled=false; resumeThread(oldThread)
    assert(state.writes==count and coroutine.status(oldThread.co)=='dead',
        'an old generation cannot interfere with recapture even if it wakes')
    animation:Release(); finishNative()
    for id in pairs(moves) do
        for axis=1,3 do
            assert(moves[id][axis]==originalMoves[id][axis] and turns[id][axis]==originalTurns[id][axis],
                'repeated capture restores the same original transforms')
        end
    end
end
helperTest(3,true)
helperTest(2,false)

local function functionSource(text,name)
    local first=assert(text:find('function '..name..'(',1,true),name)
    local last=assert(text:find('\nend',first,true),name..' end')
    return text:sub(first,last+3)
end
-- Read actual script declarations so omitted or colliding native masks cannot
-- be hidden by a fixture supplying its own SIG_UP/SIG_LOW/SIG_ANIM values.
local function declaredSignals(source)
    local signals={}
    for name,value in source:gmatch('\n%s*(SIG_[%w_]+)%s*=%s*(%d+)') do
        signals[name]=tonumber(value)
    end
    for name,value in source:gmatch('\n%s*local%s+(SIG_[%w_]+)%s*=%s*(%d+)') do
        signals[name]=tonumber(value)
    end
    return signals
end
local function animationOwnerLifecycle(source,path)
    local state={threads={},captures=0,releases=0,ambientStarts=0,resumes=0,writes=0}
    local env=declaredSignals(source)
    local ownerNames={'SIG_UP','SIG_LOW','SIG_ANIM','SIG_STOP','SIG_HUMAN_SHIELD_AMBIENT'}
    local masks={}
    for name,mask in pairs(env) do
        assert(mask>0 and mask==math.floor(mask),'native signal must be an integer: '..name)
        assert(not masks[mask],name..' shares a signal with '..tostring(masks[mask])..': '..path)
        masks[mask]=name
    end
    for _,name in ipairs(ownerNames) do
        assert(type(env[name])=='number','missing actual animation owner signal '..name..': '..path)
    end
    local function intersects(a,b)
        while a>0 and b>0 do
            if a%2==1 and b%2==1 then return true end
            a=math.floor(a/2); b=math.floor(b/2)
        end
        return false
    end
    local function resumeThread(thread,...)
        if thread.cancelled or coroutine.status(thread.co)=='dead' then return end
        state.current=thread
        local ok,err=coroutine.resume(thread.co,...)
        state.current=nil
        assert(ok,err)
    end
    env.Sleep=function() coroutine.yield() end
    env.SetSignalMask=function(mask)
        assert(type(mask)=='number','nil masks cannot own a native animation thread: '..path)
        state.current.mask=mask
    end
    env.Signal=function(mask)
        assert(type(mask)=='number','native Signal requires a declared numeric mask: '..path)
        for _,thread in ipairs(state.threads) do
            if thread.mask and intersects(thread.mask,mask) then thread.cancelled=true end
        end
    end
    env.StartThread=function(fn,...)
        local thread={co=coroutine.create(fn)}
        state.threads[#state.threads+1]=thread
        resumeThread(thread,...)
        return thread
    end
    local owners={}
    local function sleepingNativeOwner(mask)
        env.SetSignalMask(mask)
        env.Sleep(100)
        state.writes=state.writes+1
    end
    for _,name in ipairs(ownerNames) do
        owners[name]=env.StartThread(sleepingNativeOwner,env[name])
    end
    -- Visibility has its own real script signal and must not be accidentally
    -- killed because a newly assigned animation channel reused that bit.
    local unrelated=env.StartThread(sleepingNativeOwner,assert(env.SIG_FIRE_VISIBLITY))
    env.humanShieldActive=false
    env.currentCloakState='decloaked'
    env.eAnimState={slaved='slaved',standing='standing',walking='walking'}
    env.getWantCloak=function() return false end
    env.transitionToUncloaked=function() return 'decloaked' end
    env.Hide=function() end
    env.Show=function() end
    env.showFireArm=function() end
    env.breathing=function() state.ambientStarts=state.ambientStarts+1 end
    env.setOverrideAnimationState=function()
        assert(not env.humanShieldActive,'restraint must relinquish ownership before normal animation resumes')
        state.resumes=state.resumes+1
    end
    env.humanShieldAnimation={
        Capture=function()
            assert(env.humanShieldActive,'capture publishes restraint ownership before native pose changes')
            for name,thread in pairs(owners) do
                assert(thread.cancelled,'capture must retire '..name..' before touching the held pose: '..path)
            end
            state.captures=state.captures+1
        end,
        Release=function()
            assert(not env.humanShieldActive,'release clears restraint ownership before restoring transforms')
            state.releases=state.releases+1
        end,
    }
    execute(functionSource(source,'setHumanShieldActive'),env)
    env.setHumanShieldActive(true)
    assert(state.captures==1,'actual operative callback starts one restraint owner')
    for _,thread in pairs(owners) do resumeThread(thread) end
    assert(state.writes==0,'sleeping ordinary owners cannot mutate the captured body')
    assert(not unrelated.cancelled,'capture preserves the independent visibility channel')
    env.setHumanShieldActive(true)
    assert(state.captures==1,'duplicate capture leaves the current owner intact')
    env.setHumanShieldActive(false)
    assert(state.releases==1 and state.ambientStarts==1 and state.resumes==1,
        'live release restores native pose then restarts ordinary animation once')
    env.setHumanShieldActive(false)
    assert(state.releases==1 and state.ambientStarts==1,'duplicate release does not create extra ambient threads')
    env.setHumanShieldActive(true)
    env.humanShieldDying=true
    env.setHumanShieldActive(false)
    assert(state.releases==2 and state.ambientStarts==1 and state.resumes==1,
        'death restores transforms without resurrecting ordinary animation owners')
end

for _,path in ipairs({'scripts/operativePropagatorScript.lua','scripts/operativeassetscript.lua'}) do
    local source=read(path)
    animationOwnerLifecycle(source,path)
    local state={transport=nil,allowedTransport=true,airborne=false,aims=0,fires=0}
    local env={unitID=42,script={},humanShieldActive=true,
        Spring={GetUnitTransporter=function() return state.transport end,
            GetUnitPosition=function() return 0,0,0 end},
        GG={HumanShield={IsTransportAllowed=function(id) assert(id==42); return state.allowedTransport end}},
        isUnitFlying=function() return state.airborne end,
        hasHumanShield=function() return true end,
        humanShieldAnimation={Aim=function(_,yaw,pitch)
            state.aims=state.aims+1; state.yaw=yaw; state.pitch=pitch
        end},
        WeaponsTable={[1]={firefunc=function() state.fires=state.fires+1 end}},
    }
    execute(functionSource(source,'canUseHumanShield'),env)
    assert(env.canUseHumanShield(),'idle carrier may take a hostage: '..path)
    env.boolWalking=true; env.boolAiming=true
    assert(env.canUseHumanShield(),'walking and aim mode remain compatible: '..path)
    for _,flag in ipairs({'humanShieldDying','boolIsBuilding','boolInClosedCombat','boolFlying'}) do
        env[flag]=true; assert(not env.canUseHumanShield(),flag..' prevents capture: '..path); env[flag]=false
    end
    state.airborne=true; assert(not env.canUseHumanShield(),'live airborne check rejects parachuting'); state.airborne=false
    state.transport=88; env.boolFlying=true
    assert(env.canUseHumanShield(),'approved car transport permits the existing hostage despite height')
    state.allowedTransport=false; assert(not env.canUseHumanShield(),'unapproved transport rejects shielding')
    state.transport=nil; env.boolFlying=false
    if path:find('assetscript',1,true) then
        for _,flag in ipairs({'boolOnRoof','rooftopMotion'}) do
            env[flag]=true; assert(not env.canUseHumanShield(),'rooftop activity prevents shielding'); env[flag]=false
        end
    else
        env.boolInterrogated=true; assert(not env.canUseHumanShield(),'interrogation prevents shielding')
        env.boolInterrogated=false
    end
    execute(functionSource(source,'externalAimFunction'),env)
    env.externalAimFunction({x=100,y=20,z=0},0.6,true)
    assert(state.aims==1 and env.humanShieldActive,'external aim mode keeps and animates the hold')
    near(state.yaw,0.6,'external aim yaw preserved')
    near(state.pitch,math.atan2(20,100),'external aim computes target pitch')
    execute(functionSource(source,'script.AimWeapon'),env)
    execute(functionSource(source,'script.FireWeapon'),env)
    assert(env.script.AimWeapon(1,0.6,0.2)==false,'automatic weapon aim cannot authorize a shot from a hold')
    assert(env.script.FireWeapon(1)==false and state.fires==0,
        'weapon fire callback has no muzzle, recoil or ammunition side effect while shielding')
    local released=false
    env.releaseHumanShield=function(reason)
        assert(not env.boolIsBuilding and not env.boolInClosedCombat,
            'release happens before the incompatible activity takes animation ownership')
        released=true; state.releaseReason=reason; env.humanShieldActive=false
    end
    env.Signal=function() end
    env.COB={INBUILDSTANCE=1}
    env.SetUnitValue=function() assert(released,'building cannot start before captive release') end
    execute(functionSource(source,'script.StartBuilding'),env)
    env.script.StartBuilding(0,0)
    assert(released and env.boolIsBuilding and not state.releaseReason,
        'starting construction safely releases before changing stance')
    env.boolIsBuilding=false; released=false
    env.setViewRadius=function() assert(released,'melee cannot start before captive release') end
    execute(functionSource(source,'isNowInCloseCombat'),env)
    env.isNowInCloseCombat(88)
    assert(released and env.boolInClosedCombat and state.releaseReason=='melee',
        'actual close-combat callback releases immediately with the panic-escape reason')
end
print('PASS: Both operative carrier animations idle, shuffle, sit, aim without release, cancel and restore; actual signal declarations retire sleeping animation owners; real readiness and firing callbacks enforce activity exclusions')
