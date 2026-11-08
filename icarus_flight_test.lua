-- Run from the repository root: lua5.1 tests/icarus_flight_test.lua
-- Exercise the real script and its native-movement/weapon API contract. This
-- fixture deliberately does not pretend to implement Recoil's aircraft AI.
-- Native command completion, firing and projectile destruction are explicit
-- engine events; native aerodynamic trajectory still needs an engine run.
local path = 'scripts/airplaneartilleryscript.lua'
local FPS = 30
local function copy(t)
    local result = {}; for k,v in pairs(t or {}) do result[k] = v end; return result
end
local function intersects(a,b)
    while a>0 and b>0 do
        if a%2==1 and b%2==1 then return true end
        a=math.floor(a/2);b=math.floor(b/2)
    end
    return false
end

local function fixture(options)
    options=options or {}
    local w = {frame=0, position={1000,0,1000}, velocity={0,0,0}, valid=true,
        build=options.build or 1, team=2, commands={}, nextTag=1, rules={}, events={},
        projectiles={}, projectileCount=0, manualSpawns=0, spawnAttempts=0,
        launches=0, reads=0, selfD=0, targetAlive=true, targetVisible=true,
        target={1600,0,1000}, animations={}, turns={}, moves={}, threads={},
        disabled=0, enabled=0, destroyed=0, heights={}, calls={}, goalWrites=0,
        steeringWrites=0, speedSettings={}, stunned=options.stunned or false}
    local e=setmetatable({}, {__index=_G})
    e.script={};e.unitID=7;e.unitDefID=9
    e.x_axis=1;e.y_axis=3;e.z_axis=2 -- actual gamedata/unit_script_header.lua
    e.Game={gameSpeed=FPS,gravity=130,mapSizeX=8192,mapSizeZ=8192}
    e.CMD={ATTACK=20,MOVE=10,PATROL=15,FIGHT=16,STOP=0,REMOVE=2,INSERT=1,
        SELFD=65,OPT_INTERNAL=8,OPT_SHIFT=32,IDLEMODE=145}
    e.COB={CRASHING=97}
    e.UnitDefs={[9]={speed=75,wantedHeight=1536,modCategories={air=true},
        customParams=copy(options.customParams)},[10]={modCategories={ground=true}}}
    e.WeaponDefNames={icarusglidebomb={id=4}}
    e.WeaponDefs={[4]={damageAreaOfEffect=64,explosionSpeed=3.23}}
    local ids={Cartdrige=13,Base=15,Eye=16,Tail=17,Wing1=101,Wing2=102,
        Wing1Sub1=111,Wing2Sub1=112}
    local groups={Wing={101,102},Sabot={121,122},TailRotor={131,132}}
    e.include=function() end
    e.piece=function(name) return assert(ids[name],name) end
    e.getPieceTableByNameGroups=function() return groups end
    e.hideAll=function() w.hidden=true end
    e.showT=function() end;e.hideT=function() end;e.Show=function() end;e.Hide=function() end
    e.moveT=function() end;e.spinT=function() end;e.spinRand=function() end
    e.CallAsTeam=function(access,fn,id)
        assert(access.read==w.team and id==88,'target position must respect owner information')
        w.scopedReads=(w.scopedReads or 0)+1
        local x,y,z=fn(id)
        if x then return x+(w.radarError or 0),y,z end
    end

    -- Match the project's LUS scheduler: StartThread runs immediately and
    -- inherits the caller's mask. Signal cancels suspended threads only.
    local function resume(thread,...)
        local previous=w.currentThread
        w.currentThread=thread;thread.wait=nil
        local ok,wait=coroutine.resume(thread.co,...)
        w.currentThread=previous
        assert(ok,wait)
        if coroutine.status(thread.co)~='dead' then
            assert(type(wait)=='table','a script thread yielded outside a supported wait')
            thread.wait=wait
        end
    end
    e.StartThread=function(fn,...)
        local thread={co=coroutine.create(fn),mask=w.currentThread and w.currentThread.mask or 0}
        w.threads[#w.threads+1]=thread
        resume(thread,...)
    end
    e.SetSignalMask=function(mask) assert(w.currentThread).mask=mask end
    e.Signal=function(mask)
        w.signals=(w.signals or 0)+1
        for _,thread in ipairs(w.threads) do
            if thread.wait and intersects(thread.mask,mask) then
                thread.cancelled=true;thread.wait=nil
            end
        end
    end
    e.Sleep=function(ms)
        coroutine.yield({kind='sleep',wake=w.frame+math.max(1,math.floor(ms/33))})
    end
    local function animate(kind,id,axis,target,speed)
        local key=kind..':'..id..':'..axis
        local previous=w.animations[key]
        local initial=0
        if previous then
            local duration=previous.finish-previous.begin
            local fraction=duration==0 and 1 or math.min(1,(w.frame-previous.begin)/duration)
            initial=previous.start+(previous.target-previous.start)*fraction
        end
        w.animations[key]={start=initial,target=target,begin=w.frame,
            finish=w.frame+(speed==0 and 0 or math.ceil(math.abs(target-initial)/speed*FPS))}
        local log=kind=='turn' and w.turns or w.moves
        log[#log+1]={id=id,axis=axis,target=target,frame=w.frame}
    end
    e.Turn=function(id,axis,target,speed) animate('turn',id,axis,target,speed) end
    e.Move=function(id,axis,target,speed) animate('move',id,axis,target,speed) end
    local function waitAnimation(kind,id,axis)
        local key=kind..':'..id..':'..axis
        local a=w.animations[key]
        if a and a.finish>w.frame then coroutine.yield({kind='animation',key=key}) end
    end
    e.WaitForTurn=function(id,axis) waitAnimation('turn',id,axis) end
    e.WaitForMove=function(id,axis) waitAnimation('move',id,axis) end
    e.setUnitNeverLand=function(_,flag)
        assert(flag==true,'never-land helper requires explicit true');w.neverLand=true
    end
    e.waitTillComplete=function()
        while w.valid and w.build<1 do e.Sleep(50) end
        return w.valid
    end
    e.GG={IcarusSkylineHeight=options.skyline or 0,IcarusSkylineReady=options.skylineReady~=false,
        NimrodLaunchFX={Departure=function(id,top)
        assert(id==7 and w.valid and w.build==1)
        w.launches=w.launches+1;w.launchTop=top
    end}}
    local function crash()
        w.crashed=true
        if e.BeginAircraftCrash then e.BeginAircraftCrash() end
        return true
    end
    e.GG.AircraftCrash=crash
    local function copyCommand(c)
        return {id=c.id,params=copy(c.params),tag=c.tag,options=copy(c.options)}
    end
    local function noSteeringAfterHandoff()
        assert(not w.handoffFrame,'scripted steering resumed after native handoff')
        w.steeringWrites=w.steeringWrites+1
    end
    function w:folded()
        for _,id in ipairs({101,102}) do
            local a=self.animations['turn:'..id..':1']
            if not a or a.target~=0 or a.finish>self.frame then return false end
        end
        for _,id in ipairs({111,112}) do
            local a=self.animations['move:'..id..':3']
            if not a or a.target~=326 or a.finish>self.frame then return false end
        end
        return true
    end
    function w:recordProjectile(params,manual)
        assert(self.valid,'projectile owner must still be alive')
        assert(self:folded(),'release must wait for both wings and telescoping panels')
        self.projectileCount=self.projectileCount+1
        local id=900+self.projectileCount
        self.projectiles[id]={params=params,weaponDef=4,position=copy(params.pos),
            releaseFrame=self.frame,manual=manual}
        self.releaseFrame=self.frame
        -- Native AddProjectile emits this synchronously, before SpawnProjectile
        -- returns. Exercise that re-entrant ordering for forced expiry too.
        if not self.suppressCreated and e.IcarusProjectileCreated then e.IcarusProjectileCreated(id) end
        return id
    end
    function w:projectileDestroyed(id)
        local p=self.projectiles[id]
        if not p then return end
        -- Recoil calls this before removing the projectile from its registry.
        if not self.suppressDestroyed then e.IcarusProjectileDestroyed(id) end
        self.projectiles[id]=nil
    end
    e.Spring={
        ValidUnitID=function(id) return id==7 and w.valid or id==88 and w.targetAlive end,
        GetUnitIsDead=function(id) return id==7 and not w.valid or id==88 and not w.targetAlive end,
        GetUnitPosition=function(id)
            if id==88 and not w.targetAlive then return end
            local p=id==7 and w.position or w.target;return p[1],p[2],p[3]
        end,
        GetUnitVelocity=function() return w.velocity[1],w.velocity[2],w.velocity[3],
            math.sqrt(w.velocity[1]^2+w.velocity[2]^2+w.velocity[3]^2) end,
        GetUnitDirection=function() return 0,0,1 end,
        GetUnitMoveTypeData=function()
            return {maxSpeed=options.nativeMaxSpeed or 75}
        end,
        GetUnitDefID=function(id) return id==7 and 9 or 10 end,
        GetUnitTeam=function() return w.team end,
        GetUnitAllyTeam=function(id) return id==7 and w.team or 3 end,
        GetUnitLosState=function() return {los=w.targetVisible,radar=w.targetVisible} end,
        GetUnitSelfDTime=function() return w.selfD end,
        GetUnitIsStunned=function() return w.stunned end,
        GetGameFrame=function() return w.frame end,
        GetGroundHeight=function() return w.groundHeight or 0 end,
        GetUnitHealth=function() return 100,100,0,0,w.build end,
        SetUnitRulesParam=function(_,key,value)
            w.rules[key]=value
            if key=='icarus_flight_phase' then w.events[#w.events+1]={phase=value,frame=w.frame} end
        end,
        GetUnitRulesParam=function(_,key) return w.rules[key] end,
        GetUnitCommands=function(_,limit)
            assert(limit==1,'event refresh needs only the active command')
            w.reads=w.reads+1
            local result={}
            for i=1,math.min(limit,#w.commands) do result[i]=copyCommand(w.commands[i]) end
            return result
        end,
        GetUnitWeaponTarget=function()
            if w.weaponTarget then return unpack(w.weaponTarget) end
            local c=w.commands[1]
            if c and c.id==e.CMD.ATTACK then
                local userTarget=not (c.options.internal or (c.options.coded or 0)%16>=8)
                if #c.params==1 then return 1,userTarget,c.params[1] end
                return 2,userTarget,copy(c.params)
            end
            return 0,false
        end,
        GiveOrderToUnit=function(_,id,params)
            if id==e.CMD.SELFD then w.selfD=0
            elseif id==e.CMD.IDLEMODE then w.neverLand=params[1]==0
            else error('Lua must leave native command execution alone: '..tostring(id)) end
        end,
        SetUnitMoveGoal=function(_,x,y,z)
            assert(not w.controlled,'native move goal while MoveCtrl is active')
            w.goalWrites=w.goalWrites+1;w.nativeGoal={x,y,z}
        end,
        SetUnitVelocity=function(_,x,y,z)
            noSteeringAfterHandoff();w.velocity={x,y,z}
        end,
        SpawnProjectile=function(id,params)
            w.spawnAttempts=w.spawnAttempts+1
            assert(id==4 and params.owner==7 and params.team==w.team and params.weapon==1)
            assert(params.gravity==-130/(FPS*FPS) and params.ttl>0)
            assert(w:folded(),'forced release before fold completion')
            if w.spawnFailure or (w.failFirstSpawn and w.spawnAttempts==1) then return nil end
            w.manualSpawns=w.manualSpawns+1
            return w:recordProjectile(params,true)
        end,
        GetProjectilePosition=function(id)
            local p=w.projectiles[id];if p then return unpack(p.position) end
        end,
        GetProjectileDefID=function(id)
            local p=w.projectiles[id];return p and p.weaponDef
        end,
        GetProjectileOwnerID=function(id)
            local p=w.projectiles[id];return p and p.params.owner
        end,
        DeleteProjectile=function(id) w.forcedProjectileCleanup=true;w:projectileDestroyed(id) end,
        DestroyUnit=function(id,selfd,reclaimed)
            assert(id==7 and not selfd and reclaimed,'owner cleanup must not create another explosion')
            assert(w.valid,'owner cleaned up twice')
            w.valid=false;w.destroyed=w.destroyed+1;e.script.Killed()
        end,
        SetUnitCrashing=crash,
        SetUnitCOBValue=function(_,key,value) assert(key==97 and value==1);crash() end,
        SetUnitNoDraw=function(_,v) w.noDraw=v end,
        SetUnitNoSelect=function(_,v) w.noSelect=v end,
        SetUnitNoMinimap=function(_,v) w.noMinimap=v end,
        SetUnitBlocking=function(_,a,b,c) assert(not a and not b and not c);w.nonblocking=true end,
        SetUnitNeutral=function(_,v) w.neutral=v end,
        SetUnitCloak=function(_,v) w.cloak=v end,
        SetUnitStealth=function(_,v) w.stealth=v end,
        SetUnitSonarStealth=function(_,v) w.sonarStealth=v end,
        SetUnitSensorRadius=function(_,_,v) assert(v==0);w.sensorsZero=true end,
        SetUnitWeaponState=function(_,slot,state) assert(slot==1);w.weaponState=state end,
        Echo=function() w.errors=(w.errors or 0)+1 end,
        MoveCtrl={
            Enable=function()
                noSteeringAfterHandoff();w.controlled=true;w.enabled=w.enabled+1
            end,
            Disable=function()
                assert(w.controlled,'MoveCtrl disabled twice')
                w.controlled=false;w.disabled=w.disabled+1;w.handoffFrame=w.frame
            end,
            GetTag=function() if w.controlled then return 0 end end,
            SetGravity=function(_,g) noSteeringAfterHandoff();assert(g==0) end,
            SetPosition=function(_,x,y,z) noSteeringAfterHandoff();w.position={x,y,z} end,
            SetVelocity=function(_,x,y,z) noSteeringAfterHandoff();w.velocity={x,y,z} end,
            SetRotation=function() noSteeringAfterHandoff() end,
            SetAirMoveTypeData=function(_,key,value)
                assert(not w.controlled,'native air settings require native movement')
                if type(key)=='table' then
                    for k,v in pairs(key) do w.nativeSettings=w.nativeSettings or {};w.nativeSettings[k]=v end
                    if key.wantedHeight then w.heights[#w.heights+1]={height=key.wantedHeight,frame=w.frame} end
                    if key.maxSpeed then w.speedSettings[#w.speedSettings+1]={speed=key.maxSpeed,frame=w.frame} end
                else
                    w.nativeSettings=w.nativeSettings or {};w.nativeSettings[key]=value
                    if key=='wantedHeight' then w.heights[#w.heights+1]={height=value,frame=w.frame} end
                    if key=='maxSpeed' then w.speedSettings[#w.speedSettings+1]={speed=value,frame=w.frame} end
                end
            end,
        },
    }
    -- Count direct production calls, excluding the fixture's engine events.
    local function countFunctions(t,prefix)
        for name,fn in pairs(t) do
            local key=(prefix or '')..name
            if type(fn)=='function' then
                t[name]=function(...)
                    w.calls[key]=(w.calls[key] or 0)+1
                    return fn(...)
                end
            elseif type(fn)=='table' then countFunctions(fn,key..'.') end
        end
    end
    countFunctions(e.Spring)
    function w:order(id,params,opts,append)
        -- Engine UnitCommand precedes the actual queue mutation.
        e.IcarusCommandChanged()
        local c={id=id,params=copy(params),options=copy(opts),tag=self.nextTag}
        self.nextTag=self.nextTag+1
        if append then self.commands[#self.commands+1]=c else self.commands={c} end
        return c
    end
    function w:finishCommand()
        table.remove(self.commands,1)
        e.IcarusCommandChanged() -- UnitCmdDone/UnitIdle relay
    end
    function w:step(count)
        for _=1,count or 1 do
            self.frame=self.frame+1
            -- Only launch MoveCtrl is simulated. Native flight is intentionally
            -- opaque; test scenarios supply positions/engine callbacks.
            if self.controlled then
                for i=1,3 do self.position[i]=self.position[i]+self.velocity[i] end
            end
            local countThreads=#self.threads
            for index=1,countThreads do
                local thread=self.threads[index]
                local wait=thread.wait
                if wait and not thread.cancelled then
                    local ready=wait.kind=='sleep' and wait.wake<=self.frame
                    if wait.kind=='animation' then
                        local animation=self.animations[wait.key]
                        ready=not animation or animation.finish<=self.frame
                    end
                    if ready then resume(thread) end
                end
            end
        end
    end
    function w:untilTrue(predicate,limit,message)
        for _=1,limit or 1200 do
            if predicate(self) then return end
            self:step()
        end
        error(message or 'condition not reached; phase '..tostring(self.rules.icarus_flight_phase))
    end
    function w:untilPhase(phase,limit)
        self:untilTrue(function(s) return s.rules.icarus_flight_phase==phase end,limit,
            'phase '..phase..' not reached')
    end
    function w:handoff()
        self:untilTrue(function(s) return s.goalWrites>0 end,300,'native handoff missing')
        -- Supply an explicit native flight sample for attack alignment. The
        -- fixture still does not integrate aircraft position or acceleration.
        self.velocity={2.5,0,0}
        self:step(2) -- allow the deferred initial command refresh
    end
    function w:nativeFire(targetID)
        assert(not e.script.BlockShot1(targetID,true),'native release gate unexpectedly blocked')
        local beforePosition=copy(self.position)
        local beforeVelocity=copy(self.velocity)
        e.script.FireWeapon1()
        assert(not self.noDraw,'FireWeapon hid the muzzle before native projectile creation')
        for i=1,3 do
            assert(self.position[i]==beforePosition[i] and self.velocity[i]==beforeVelocity[i],
                'FireWeapon changed native launch position/velocity')
        end
        local params={pos=copy(self.position),speed=copy(self.velocity),gravity=-130/(FPS*FPS),
            ttl=1000,owner=7,team=self.team,weapon=1}
        return self:recordProjectile(params,false)
    end
    function w:readyToDrop(targetID,limit)
        self:untilTrue(function(s)
            return s:folded() and not s.env.script.BlockShot1(targetID,true)
        end,limit or 150,'fold and native braking did not finish before release')
    end
    local chunk
    if setfenv then chunk=assert(loadfile(path));setfenv(chunk,e) else chunk=assert(loadfile(path,'t',e)) end
    chunk();w.env=e;e.script.Create()
    return w
end

local function deadline(w)
    return assert(w.rules.icarus_glide_end_frame,'glide deadline must be exposed for diagnostics')
end
local function advanceTo(w,frame) if frame>w.frame then w:step(frame-w.frame) end end
local function closeGroundAttack(w)
    w:order(w.env.CMD.ATTACK,{w.position[1]+300,0,w.position[3]})
    w:readyToDrop(nil)
end
local function assertCarrier(w)
    assert(w.valid and w.noDraw and w.noSelect and w.noMinimap and w.nonblocking)
    assert(w.neutral and w.sensorsZero and not w.controlled)
    assert(w.env.script.HitByWeapon(0,0,1,500)==0)
end

-- The shared map-wide roof height is computed once before Icarus launches.
-- Construction completion alone cannot launch while that initial snapshot is
-- incomplete, and waiting for it must not spend the airborne lifetime.
local w=fixture({skyline=100,skylineReady=false});w:step(3*FPS)
assert(w.launches==0 and w.enabled==0 and not w.controlled,
    'completed payload launched before the map-wide roof calculation finished')
assert(not w.rules.icarus_glide_start_frame and not w.rules.icarus_glide_end_frame,
    'waiting for the initial skyline spent the glide budget')
w.env.GG.IcarusSkylineHeight=900;w:step(2*FPS)
assert(w.launches==0 and w.enabled==0 and not w.rules.icarus_glide_start_frame,
    'a provisional skyline height started the launch before readiness')
local skylineReadyFrame=w.frame
w.env.GG.IcarusSkylineReady=true;w:handoff()
assert(w.launches==1 and w.enabled==1 and w.disabled==1)
assert(w.rules.icarus_glide_start_frame>skylineReadyFrame and deadline(w)-w.handoffFrame==787,
    'launch did not use the final map-wide roof height for its fresh airborne allowance')
w:step(FPS);assert(w.launches==1,'skyline readiness replayed the rail launch')

-- Completed construction and EMP gating precede the one finite launch, then
-- native movement owns the airframe for the entire remaining lifetime.
w=fixture({build=0.5});w:step(40)
assert(w.launches==0 and not w.controlled,'unfinished payload launched')
w.build=1;w.stunned=true;w:step(40)
assert(w.launches==0,'stunned payload launched')
w.stunned=false;w:handoff()
assert(w.launches==1 and w.launchTop==2048 and w.neverLand)
assert(w.enabled==1 and w.disabled==1 and not w.controlled and w.goalWrites==1)
assert(w.heights[1].height==1536)
local finish=deadline(w)
assert(finish-w.handoffFrame==4162,
    'default glide must reserve the full update, folding and native braking transition above terrain')
local initialCalls=copy(w.calls);local initialReads=w.reads;local initialHeights=#w.heights
w:step(300)
assert(w.projectileCount==0 and w.goalWrites==1 and not w.controlled)
assert(w.reads==initialReads,'idle glide must not poll the command queue')
local directCalls=0
for name,count in pairs(w.calls) do directCalls=directCalls+count-(initialCalls[name] or 0) end
assert(directCalls<=55,'idle clearance/sink exceeded its sparse engine-call budget')
for _,name in ipairs({'GetUnitPosition','GetUnitVelocity','GetGroundHeight'}) do
    local reads=(w.calls[name] or 0)-(initialCalls[name] or 0)
    assert(reads>=9 and reads<=11,'clearance sampling must stay near one Hz: '..name)
end
assert(#w.heights-initialHeights<=11,'altitude target is updated at most about 1 Hz')
for i=2,#w.heights do
    local a,b=w.heights[i-1],w.heights[i]
    local expected=8*(b.frame-a.frame)/FPS
    assert(math.abs((a.height-b.height)-expected)<0.00001,'sink target must follow absolute elapsed time')
end

-- Internal and automatic targets cannot release. Native MOVE/PATROL/FIGHT
-- execution is left untouched: no replacement waypoints or steering writes.
w:order(w.env.CMD.ATTACK,{1100,0,1000},{internal=true});w:step(40)
assert(w.env.script.BlockShot1(nil,false) and w.projectileCount==0)
w:order(w.env.CMD.ATTACK,{1100,0,1000},{coded=8});w:step(40)
assert(w.env.script.BlockShot1(nil,true) and w.projectileCount==0)
for _,cmd in ipairs({w.env.CMD.MOVE,w.env.CMD.PATROL,w.env.CMD.FIGHT}) do
    w:order(cmd,{1900,0,1900});w:step(40)
    assert(#w.commands==1 and w.commands[1].id==cmd and w.goalWrites==1)
    assert(w.env.script.BlockShot1(nil,false),'movement order allowed an automatic strike')
end
w:order(w.env.CMD.STOP,{});w:step(40)
assert(deadline(w)==finish and w.projectileCount==0,'orders renewed the glide budget')

-- Native weapon release is gated on full animation completion; ownership
-- handoff occurs only after the engine has sampled muzzle and velocity.
w=fixture();w:handoff();w.selfD=3;closeGroundAttack(w)
assert(not w.noDraw and w.projectileCount==0 and w.manualSpawns==0)
w.weaponTarget={2,true,{1300,0,1700}}
assert(w.env.script.BlockShot1(nil,true),'stale native ground target passed the current designation gate')
w.weaponTarget={2,false,{1300,0,1000}}
assert(w.env.script.BlockShot1(nil,true),'non-user native ground target passed the gate')
w.weaponTarget=nil
local projectile=w:nativeFire(nil)
assert(w.projectileCount==1 and w.manualSpawns==0 and w.selfD==0)
assertCarrier(w)
assert(w.env.script.BlockShot1(nil,true),'second native shot allowed')
w.env.IcarusProjectileCreated(projectile)
assert(w.projectileCount==1,'duplicate created callback spawned another bomb')
w:projectileDestroyed(projectile)
w:step(16);assert(w.valid,'owner removed before delayed outer splash')
w:step(20);assert(not w.valid and w.destroyed==1)
w:step(1200);assert(w.destroyed==1,'fallback cleanup ran a second time')

-- Event-before-queue ordering and shifted appends: an event coalesces one
-- deferred refresh; replacing the active designation cancels the old fold.
w=fixture();w:handoff()
local reads=w.reads
w:order(w.env.CMD.ATTACK,{1300,0,1000})
w.env.IcarusCommandChanged();w.env.IcarusCommandChanged()
assert(w.reads==reads,'UnitCommand synchronously read the old queue')
w:step(1);assert(w.reads==reads+1,'command events were not coalesced')
w:untilPhase(5,90)
w:order(w.env.CMD.MOVE,{1900,0,1900},{shift=true},true);w:step(50)
assert(w:folded() and #w.commands==2,'shift append interrupted the active strike')
assert(not w.env.script.BlockShot1(nil,true))
w:order(w.env.CMD.STOP,{});assert(w.env.script.BlockShot1(nil,true))
w:step(40)
assert(w.projectileCount==0 and not w:folded(),'STOP failed to reopen the wings')
assert(w.animations['turn:101:1'].target<0 and w.animations['turn:102:1'].target>0)

-- Nearby targets alone must not activate the slow folded flight profile.
-- Exercise only proactive preparation here: calling BlockShot would assert
-- that the real engine has already selected an aligned ballistic window.
for _,approach in ipairs({
    {name='behind',target={700,0,1000},velocity={2.5,0,0}},
    {name='abreast',target={1000,0,1300},velocity={2.5,0,0}},
    {name='stationary',target={1300,0,1000},velocity={0,0,0}},
    {name='oblique',target={1300,0,1000},velocity={2.25,0,2.5*math.sqrt(0.19)}},
}) do
    w=fixture();w:handoff();w.velocity=approach.velocity
    w:order(w.env.CMD.ATTACK,approach.target);w:step(2*FPS)
    assert(not w:folded() and #w.speedSettings==0 and w.projectileCount==0,
        approach.name..' target folded a glider before an aligned approach')
    assert(w.animations['turn:101:1'].target<0 and w.animations['turn:102:1'].target>0)
    local dx,dz=approach.target[1]-w.position[1],approach.target[3]-w.position[3]
    local length=math.sqrt(dx*dx+dz*dz)
    local ux,uz=dx/length,dz/length
    w.velocity={2.5*ux,0,2.5*uz}
    w:untilTrue(function(s) return s:folded() end,90)
    assert(#w.speedSettings==1 and w.speedSettings[1].speed==18.75,
        'an aligned '..approach.name..' approach did not prepare the native drop')
    -- The wider cancellation cone prevents a slight heading change from
    -- repeatedly restoring and reapplying the native speed limit.
    w.velocity={2.5*(0.9*ux-math.sqrt(0.19)*uz),0,
        2.5*(0.9*uz+math.sqrt(0.19)*ux)}
    w:step(2*FPS)
    assert(w:folded() and #w.speedSettings==1,'alignment hysteresis cancelled a viable folded approach')
    w.velocity={-2.5*ux,0,-2.5*uz};w:step(2*FPS)
    assert(not w:folded() and w.speedSettings[#w.speedSettings].speed==75,
        'a missed pass failed to reopen safely and restore native cruise speed')
end

w=fixture();w:handoff();w:order(w.env.CMD.ATTACK,{1300,0,1000})
w:untilTrue(function(s) return s:folded() end,90)
local alignedTurns=#w.turns
w.position[2]=400;w.velocity={-2.5,0,0};w:untilPhase(6,90)
assert(w.manualSpawns==1 and w:folded(),'lost alignment below clearance did not commit a local drop')
assert(#w.speedSettings==1 and w.speedSettings[1].speed==18.75,
    'lost alignment below clearance restored cruising speed')
for i=alignedTurns+1,#w.turns do
    local turn=w.turns[i]
    if turn.id==101 or turn.id==102 then
        assert(turn.target==0,'lost alignment reopened wings inside the roof zone')
    end
end

-- Folding reserves a native braking interval before the ballistic release.
-- This checks settings and timing, without pretending Lua simulates the
-- engine's aerodynamic response to a lower native maximum speed.
w=fixture();w:handoff()
assert(w.calls.GetUnitMoveTypeData==1,'native speed must be sampled once before launch')
w:order(w.env.CMD.ATTACK,{1300,0,1000})
w:untilTrue(function(s) return s:folded() end,90)
assert(#w.speedSettings==1 and w.speedSettings[1].speed==18.75,
    'fold completion must request one quarter of the original native speed')
local brakeFrame=w.speedSettings[1].frame
assert(w.env.script.BlockShot1(nil,true),'fully folded wings skipped the native braking interval')
advanceTo(w,brakeFrame+FPS-1)
assert(w.env.script.BlockShot1(nil,true),'release occurred before the full native braking interval')
w:step(1)
assert(not w.env.script.BlockShot1(nil,true))
w:order(w.env.CMD.STOP,{});w:step(40)
assert(#w.speedSettings==2 and w.speedSettings[2].speed==75,
    'safe cancellation failed to restore the original native maximum speed')
assert(w.calls.GetUnitMoveTypeData==1 and not w:folded())

w=fixture({nativeMaxSpeed=120,customParams={icarus_folded_speed_factor='0.5',icarus_brake_seconds='2'}})
w:handoff();w:order(w.env.CMD.ATTACK,{1300,0,1000})
w:untilTrue(function(s) return s:folded() end,90)
assert(w.speedSettings[1].speed==60,'folded speed must derive from the actual native movement speed')
brakeFrame=w.speedSettings[1].frame
advanceTo(w,brakeFrame+2*FPS-1);assert(w.env.script.BlockShot1(nil,true))
w:step(1);assert(not w.env.script.BlockShot1(nil,true))
w:order(w.env.CMD.STOP,{});w:step(40)
assert(w.speedSettings[#w.speedSettings].speed==120,'custom native speed was not restored')

w=fixture();w:handoff()
w:order(w.env.CMD.ATTACK,{1300,0,1000})
assert(w.env.script.BlockShot1(nil,true),'event/queue gap admitted a shot')
w:step(1)
assert(w.env.script.BlockShot1(nil,true),'native window admitted a shot before folding')
w:step(5)
assert(not w:folded() and w.env.script.BlockShot1(nil,true))
w:order(w.env.CMD.ATTACK,{7000,0,7000});w:step(40)
assert(not w:folded() and w.projectileCount==0,'replacement designation left a stale fold completion')

-- Unit designations use team-scoped perceived positions and final visibility
-- gating. A target dying, leaving contact, or an EMP cannot release a strike.
w=fixture();w:handoff();w.target={1250,0,1000};w.radarError=75
w:order(w.env.CMD.ATTACK,{88});w:readyToDrop(88)
assert(w.scopedReads and w.scopedReads>0)
assert(not w.env.script.BlockShot1(88,true))
assert(w.env.script.BlockShot1(99,true),'wrong native target passed the designation gate')
w.targetVisible=false;assert(w.env.script.BlockShot1(88,true))
w:step(40);assert(not w:folded() and w.projectileCount==0)
w.targetVisible=true;w:readyToDrop(88)
w.targetAlive=false;assert(w.env.script.BlockShot1(88,true))
w:step(40);assert(w.projectileCount==0)
w.targetAlive=true;w.env.UnitDefs[10].modCategories={air=true}
w:order(w.env.CMD.ATTACK,{88});w:step(40)
assert(w.env.script.BlockShot1(88,true),'non-GROUND target passed')
w:order(w.env.CMD.ATTACK,{7});w:step(40)
assert(w.env.script.BlockShot1(7,true),'self designation passed')

w=fixture();w:handoff();closeGroundAttack(w);local originalDeadline=deadline(w)
w.stunned=true;assert(w.env.script.BlockShot1(nil,true));w:step(40)
assert(w.projectileCount==0 and not w:folded(),'EMP did not abort prepared strike')
w.stunned=false;w:readyToDrop(nil)
assert(deadline(w)==originalDeadline and not w.env.script.BlockShot1(nil,true))

-- The shared skyline stays fixed at its map-wide absolute world altitude.
-- Moving onto higher terrain must not refill the airborne allowance even
-- though the required clearance above the local ground has become smaller.
w=fixture({skyline=600});w:handoff()
assert(deadline(w)-w.handoffFrame==1912,'city rooftop height did not shorten the native glide')
local cityDeadline=deadline(w)
w.groundHeight=500;w.position[2]=2500;w:step(FPS+1)
assert(deadline(w)==cityDeadline,'higher terrain beneath the fixed skyline renewed the glide budget')
w.groundHeight=1000;w:step(FPS+1)
assert(deadline(w)==cityDeadline and w.env.GG.IcarusSkylineHeight==600,
    'terrain above the fixed city roof height renewed the glide budget')

w=fixture({skyline=900});w:handoff();w.groundHeight=600;w.position[2]=1300
w:untilPhase(6,90)
assert(w.manualSpawns==1,'absolute rooftop clearance was mistaken for terrain-relative altitude')
w=fixture();w:handoff();w.groundHeight=1000;w.position[2]=1400
w:untilPhase(6,90)
assert(w.manualSpawns==1,'elevated terrain was omitted from the clearance floor')

-- Actual speed affects the reserved transition height independently of the
-- altitude allowance. Native velocity is supplied, never simulated here.
for _,motion in ipairs({{velocity={15,0,0},height=1000},{velocity={0,-10,0},height=1100}}) do
    w=fixture();w:handoff();w.position[2]=motion.height;w.velocity=motion.velocity
    w:untilPhase(6,90)
    assert(w.manualSpawns==1,'fast motion failed to reserve enough transition clearance')
end

-- A rail launch ending below the city's safe fold altitude must never show
-- the open-wing pose even briefly before committing its local native fall.
w=fixture({skyline=1900});w:handoff();w:untilPhase(6,90)
assert(w.manualSpawns==1 and w.enabled==1 and w.disabled==1)
for _,turn in ipairs(w.turns) do
    if turn.id==101 or turn.id==102 then
        assert(turn.target==0,'a launch below skyline clearance unfolded its wings')
    end
end
w=fixture({nativeMaxSpeed=900});w:handoff();w:untilPhase(6,90)
assert(w.manualSpawns==1 and w.calls.GetUnitMoveTypeData==1)
for _,turn in ipairs(w.turns) do
    if turn.id==101 or turn.id==102 then
        assert(turn.target==0,'launch clearance ignored the actual native speed before unfolding')
    end
end

-- A low aircraft is committed to the fall. STOP, a replacement target, lost
-- contact and the native shot callback must not reopen wings in the roof zone.
for _,reason in ipairs({'stop','retarget','contact','shot'}) do
    w=fixture();w:handoff();w.target={1300,0,1000};w:order(w.env.CMD.ATTACK,{88});w:readyToDrop(88)
    local speedWrites=#w.speedSettings
    w.position[2]=400
    if reason=='stop' then w:order(w.env.CMD.STOP,{})
    elseif reason=='retarget' then w:order(w.env.CMD.ATTACK,{7000,0,7000})
    elseif reason=='contact' then w.targetVisible=false
    else assert(w.env.script.BlockShot1(88,true),'unsafe native release bypassed forced-drop ownership') end
    w:untilPhase(6,90)
    assert(w.manualSpawns==1 and w:folded(),reason..' reopened a low glidebomb')
    for i=speedWrites+1,#w.speedSettings do
        assert(w.speedSettings[i].speed<75,reason..' restored cruise speed below the clearance floor')
    end
end

w=fixture();w:handoff();w:order(w.env.CMD.ATTACK,{1300,0,1000})
w:untilPhase(5,90);w:step(3)
assert(not w:folded(),'partial-fold regression requires an animation in progress')
local unsafeTurn=#w.turns
w.position[2]=400;w:order(w.env.CMD.STOP,{})
w:untilPhase(6,90)
assert(w.manualSpawns==1 and w.releaseFrame>=w.speedSettings[1].frame+FPS)
for i=unsafeTurn+1,#w.turns do
    local turn=w.turns[i]
    if turn.id==101 or turn.id==102 then
        assert(turn.target==0,'STOP reversed a partial fold below minimum clearance')
    end
end

-- An actual low/descending aircraft must commit early, including under EMP.
-- A distant attack target cannot redirect the local clearance-triggered drop.
for _,engaged in ipairs({false,true}) do
    w=fixture();w:handoff();local endFrame=deadline(w)
    if engaged then w:order(w.env.CMD.ATTACK,{7000,0,7000});w:step(1) end
    w.stunned=true
    w.position={2100,420,2200};w.velocity={1.5,-0.1,2}
    local unsafeFrame=w.frame
    w:untilPhase(6,90)
    assert(w.releaseFrame<endFrame and w.releaseFrame<=unsafeFrame+80,
        'unsafe clearance waited for the nominal lifetime or native stun gate')
    assert(w.manualSpawns==1 and w.projectileCount==1)
    local params=w.projectiles[901].params
    assert(params.pos[1]==2100 and params.pos[3]==2200,'expiry drop used the distant target')
    assert(params.speed[1]==1.5 and params.speed[3]==2,'expiry discarded native forward momentum')
    assert(params.owner==7 and params.team==2 and params.weapon==1)
    assertCarrier(w)
    w:projectileDestroyed(901);w:step(40)
    assert(w.destroyed==1)
end

-- Staying far above the sampled clearance never postpones absolute expiry.
-- Permanent EMP and an unreachable designation still produce the same local
-- drop, after only the bounded fold and native braking transition.
for _,engaged in ipairs({false,true}) do
    w=fixture();w:handoff();local endFrame=deadline(w)
    if engaged then w:order(w.env.CMD.ATTACK,{7000,0,7000});w:step(1) end
    w.position={2100,5000,2200};w.velocity={1.5,-0.1,2};w.stunned=true
    advanceTo(w,endFrame-1)
    assert(w.projectileCount==0 and deadline(w)==endFrame)
    w:untilPhase(6,50)
    assert(w.releaseFrame>=endFrame+45 and w.releaseFrame<=endFrame+46,
        'safe altitude or EMP extended the finite fold/braking deadline')
    local params=w.projectiles[901].params
    assert(w.manualSpawns==1 and params.pos[1]==2100 and params.pos[2]==5000 and params.pos[3]==2200,
        'absolute exhaustion was redirected toward the unreachable target')
    assert(params.speed[1]==1.5 and params.speed[3]==2)
    assertCarrier(w)
end

-- UnitDef tuning controls the finite budget, and the deadline remains an
-- upper bound even when native terrain avoidance has not reached that height.
w=fixture({customParams={icarus_sink_rate='16',icarus_terminal_height='700'}});w:handoff()
assert(deadline(w)-w.handoffFrame==1568)
w.groundHeight=1000;w.position[2]=5000
advanceTo(w,deadline(w));w:untilPhase(6,60)
assert(w.manualSpawns==1 and w.projectiles[901].params.pos[2]==5000)

-- Finite failure handling: a missing destruction callback or a failed forced
-- spawn must not create an immortal invisible/loitering unit.
w=fixture();w:handoff();closeGroundAttack(w);w:nativeFire(nil)
w.suppressDestroyed=true;w:step(1200)
assert(w.forcedProjectileCleanup and w.destroyed==1)
-- A missing destruction callback leaves a stale numerical ID in the script.
-- If Recoil reuses it, the fallback may reclaim its carrier but must never
-- delete another owner's bomb or a different weapon fired by this owner.
for _,replacement in ipairs({{weaponDef=4,owner=88},{weaponDef=5,owner=7}}) do
    w=fixture();w:handoff();closeGroundAttack(w);w:nativeFire(nil)
    w.suppressDestroyed=true;w:projectileDestroyed(901)
    local reused={weaponDef=replacement.weaponDef,params={owner=replacement.owner},position={10,20,30}}
    w.projectiles[901]=reused
    w:step(1200)
    assert(w.projectiles[901]==reused and not w.forcedProjectileCleanup,
        'timeout deleted an unrelated projectile after numerical ID reuse')
    assert(w.destroyed==1,'ID reuse left the original hidden carrier alive')
end
w=fixture({customParams={icarus_sink_rate=120}});w:handoff();w.failFirstSpawn=true
advanceTo(w,deadline(w));w:untilPhase(6,60)
assert(w.spawnAttempts==2 and w.manualSpawns==1 and not w.crashed)
w=fixture({customParams={icarus_sink_rate=120}});w:handoff();w.spawnFailure=true
advanceTo(w,deadline(w));w:step(60)
assert(w.spawnAttempts==2 and w.crashed and w.projectileCount==0)
w=fixture({customParams={icarus_sink_rate=120}});w:handoff();w.suppressCreated=true
advanceTo(w,deadline(w));w:untilPhase(6,60)
assert(w.manualSpawns==1,'forced expiry failed without its synchronous relay callback')
assertCarrier(w)

-- Pre-release crash/death cancels all scheduled work. No later sink update,
-- fold, MoveCtrl reacquisition or expiry projectile may appear.
w=fixture();w:handoff();closeGroundAttack(w)
w.env.BeginAircraftCrash();local updates=#w.heights
w:step(6000)
assert(w.rules.icarus_flight_phase==7 and w.projectileCount==0 and #w.heights==updates)
assert(w.enabled==1 and w.disabled==1 and not w.controlled)
w=fixture();assert(w.controlled,'launch test must begin during MoveCtrl ascent')
w.env.BeginAircraftCrash();w:step(6000)
assert(w.projectileCount==0 and #w.heights==0 and w.disabled==1 and not w.controlled)
w=fixture();w:handoff();w.env.script.Killed();w.valid=false;w:step(6000)
assert(w.projectileCount==0)
w=fixture();w:handoff();closeGroundAttack(w);w:nativeFire(nil)
w.env.script.Killed();w.valid=false;w:step(1200)
assert(w.projectiles[901] and not w.forcedProjectileCleanup,
    'exceptional owner removal deleted an already independent native projectile')
w:projectileDestroyed(901);w:step(40)
assert(w.destroyed==0 and w.projectileCount==1)

print('PASS: native Icarus handoff, sparse skyline clearance, finite sink, fold/brake gate, safe cancellation, irreversible low-altitude drop under EMP, live attribution, bounded cleanup and crashes')
