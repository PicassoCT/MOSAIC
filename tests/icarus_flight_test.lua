-- Run from the repository root: lua5.1 tests/icarus_flight_test.lua
-- The real unit script runs with a frame scheduler, native animation waits and
-- continuous MoveCtrl velocity. The projectile fixture supplies only ballistic
-- movement/collision; engine ownership/weapon semantics are checked separately.
local path = 'scripts/airplaneartilleryscript.lua'
local function fixture()
    local w = {frame=0, position={1000,0,1000}, velocity={0,0,0}, valid=true,
        build=1, team=2, commands={}, nextTag=1, rules={}, events={}, projectiles={},
        projectileCount=0, impacts=0, launches=0, reads=0, selfD=0, targetAlive=true,
        target={1600,0,1000}, targetVisible=true, targetGround=true,
        animations={}, turns={}, moves={}, disabled=0, destroyed=0}
    local e = setmetatable({}, {__index=_G})
    e.script={};e.unitID=7;e.unitDefID=9
    e.x_axis=1;e.y_axis=3;e.z_axis=2 -- actual gamedata/unit_script_header.lua
    e.Game={gameSpeed=30,gravity=130}
    e.CMD={ATTACK=20,MOVE=10,PATROL=15,FIGHT=16,STOP=0,REMOVE=2,SELFD=65,OPT_INTERNAL=8,IDLEMODE=145}
    e.UnitDefs={[9]={speed=75,wantedHeight=1536,modCategories={air=true}},
                [10]={modCategories={ground=true}}}
    e.WeaponDefNames={icarusglidebomb={id=4}}
    e.WeaponDefs={[4]={damageAreaOfEffect=64,explosionSpeed=3.23}}
    local ids={Cartdrige=13,Base=15,Eye=16,Tail=17,Wing1=101,Wing2=102,
               Wing1Sub1=111,Wing2Sub1=112}
    local groups={Wing={101,102},Sabot={121,122},TailRotor={131,132}}
    e.include=function() end
    e.CallAsTeam=function(access,fn,id)
        assert(access.read==w.team and id==88,'target position must respect owner information')
        w.scopedReads=(w.scopedReads or 0)+1
        local x,y,z=fn(id)
        return x+(w.radarError or 0),y,z
    end
    e.piece=function(name) return assert(ids[name],name) end
    e.getPieceTableByNameGroups=function() return groups end
    e.hideAll=function() w.hidden=true end
    e.showT=function() end;e.hideT=function() end;e.Show=function() end;e.Hide=function() end
    e.moveT=function() end;e.spinT=function() end;e.spinRand=function() end
    e.SetSignalMask=function() end
    e.Signal=function() w.cancelled=true end
    e.Sleep=function(ms) coroutine.yield(math.max(1,math.ceil(ms*30/1000-0.00001))) end
    e.StartThread=function(fn)
        assert(not w.thread,'only one flight controller')
        w.thread=coroutine.create(fn);w.wake=w.frame
    end
    local function animate(kind,id,axis,target,speed)
        local key=kind..':'..id..':'..axis
        local before=w.animations[key] or {target=0}
        w.animations[key]={target=target,finish=w.frame+(speed==0 and 0 or math.ceil(math.abs(target-before.target)/speed*30))}
        local log=kind=='turn' and w.turns or w.moves
        log[#log+1]={id=id,axis=axis,target=target,frame=w.frame}
    end
    e.Turn=function(id,axis,target,speed) animate('turn',id,axis,target,speed) end
    e.Move=function(id,axis,target,speed) animate('move',id,axis,target,speed) end
    local function waitAnimation(kind,id,axis)
        local a=w.animations[kind..':'..id..':'..axis]
        if a and a.finish>w.frame then e.Sleep((a.finish-w.frame)*1000/30) end
    end
    e.WaitForTurn=function(id,axis) waitAnimation('turn',id,axis) end
    e.WaitForMove=function(id,axis) waitAnimation('move',id,axis) end
    e.setUnitNeverLand=function(_,flag) assert(flag==true,'never-land helper needs explicit true');w.neverLand=true end
    e.waitTillComplete=function()
        while w.valid and w.build<1 do e.Sleep(50) end
        return w.valid
    end
    e.GG={NimrodLaunchFX={Departure=function(id,top)
        assert(id==7 and w.valid and w.build==1)
        w.launches=w.launches+1;w.launchTop=top
    end}}
    local function copyCommand(c)
        local p={};for i,v in ipairs(c.params or {}) do p[i]=v end
        return {id=c.id,params=p,tag=c.tag,options=c.options}
    end
    e.Spring={
        ValidUnitID=function(id) return id==7 and w.valid or id==88 and w.targetAlive end,
        GetUnitIsDead=function(id) return id==7 and not w.valid or id==88 and not w.targetAlive end,
        GetUnitPosition=function(id) local p=id==7 and w.position or w.target;return p[1],p[2],p[3] end,
        GetUnitDefID=function(id) return id==7 and 9 or 10 end,
        GetUnitTeam=function() return w.team end,
        GetUnitAllyTeam=function(id) return id==7 and w.team or 3 end,
        GetUnitLosState=function() return {los=w.targetVisible,radar=w.targetVisible} end,
        GetUnitSelfDTime=function() return w.selfD end,
        GetUnitIsStunned=function() return w.stunned or false end,
        GetGameFrame=function() return w.frame end,
        GetGroundHeight=function() return 0 end,
        SetUnitRulesParam=function(_,key,value)
            w.rules[key]=value
            if key=='icarus_flight_phase' then w.events[#w.events+1]={phase=value,frame=w.frame} end
        end,
        GetUnitCommands=function(_,limit)
            w.reads=w.reads+1
            local result={}
            for i=1,math.min(limit,#w.commands) do result[i]=copyCommand(w.commands[i]) end
            return result
        end,
        GiveOrderToUnit=function(_,id,params,options)
            if id==e.CMD.REMOVE then
                for i,c in ipairs(w.commands) do if c.tag==params[1] then table.remove(w.commands,i);break end end
            elseif id==e.CMD.SELFD then w.selfD=0
            elseif id==e.CMD.PATROL then
                assert(options[1]=='shift');w:order(id,params,{},true)
            else error('unexpected emitted order '..tostring(id)) end
        end,
        SpawnProjectile=function(id,params)
            assert(w.valid,'owner must live at release')
            assert(id==4 and params.owner==7 and params.team==w.team and params.weapon==1)
            assert(params.gravity==-130/900 and params.speed[1]==0 and params.speed[3]==0 and params.speed[2]<0)
            for _,pieceID in ipairs({101,102}) do
                local a=assert(w.animations['turn:'..pieceID..':1'])
                assert(a.target==0 and a.finish<=w.frame,'release before actual wing fold completes')
            end
            for _,pieceID in ipairs({111,112}) do
                local a=assert(w.animations['move:'..pieceID..':3'])
                assert(a.target==326 and a.finish<=w.frame,'release before telescoping panels retract')
            end
            if w.spawnFailure then return nil end
            w.projectileCount=w.projectileCount+1
            local number=900+w.projectileCount
            w.projectiles[number]={position={params.pos[1],params.pos[2],params.pos[3]},vy=params.speed[2],gravity=params.gravity,
                ttl=params.ttl,params=params,releaseFrame=w.frame}
            w.releaseFrame=w.frame
            return number
        end,
        GetProjectilePosition=function(id)
            local p=w.projectiles[id];if p then return p.position[1],p.position[2],p.position[3] end
        end,
        DeleteProjectile=function(id) w.projectiles[id]=nil;w.forcedProjectileCleanup=true end,
        DestroyUnit=function(id,selfd,reclaimed)
            assert(id==7 and not selfd and reclaimed,'cleanup must not create a second explosion')
            w.valid=false;w.destroyed=w.destroyed+1;e.script.Killed()
        end,
        SetUnitNoDraw=function(_,v) w.noDraw=v end,
        SetUnitNoSelect=function(_,v) w.noSelect=v end,
        SetUnitNoMinimap=function(_,v) w.noMinimap=v end,
        SetUnitBlocking=function(_,a,b,c) assert(not a and not b and not c);w.nonblocking=true end,
        SetUnitNeutral=function(_,v) w.neutral=v end,
        SetUnitStealth=function(_,v) w.stealth=v end,
        SetUnitSonarStealth=function(_,v) w.sonarStealth=v end,
        SetUnitSensorRadius=function(_,_,v) assert(v==0);w.sensorsZero=true end,
        Echo=function() w.errors=(w.errors or 0)+1 end,
        MoveCtrl={
            Enable=function() w.controlled=true end,
            Disable=function() w.controlled=false;w.disabled=w.disabled+1 end,
            GetTag=function() if w.controlled then return 0 end end,
            SetGravity=function(_,g) assert(g==0) end,
            SetPosition=function(_,x,y,z) w.position={x,y,z} end,
            SetVelocity=function(_,x,y,z) w.velocity={x,y,z} end,
            SetRotation=function(_,pitch,yaw,roll) w.rotation={pitch,yaw,roll} end,
        },
    }
    function w:order(id,params,options,append)
        local c={id=id,params=params or {},options=options or {},tag=self.nextTag}
        self.nextTag=self.nextTag+1
        if append then self.commands[#self.commands+1]=c else self.commands={c} end
        return c
    end
    function w:step(count)
        for _=1,count or 1 do
            self.frame=self.frame+1
            if self.controlled then
                for i=1,3 do self.position[i]=self.position[i]+self.velocity[i] end
            end
            for id,p in pairs(self.projectiles) do
                if not self.freezeProjectile then
                    p.vy=p.vy+p.gravity;p.position[2]=p.position[2]+p.vy;p.ttl=p.ttl-1
                    if p.position[2]<=(self.hitHeight or 0) then
                        assert(self.valid or self.allowDeadOwner,'live owner required at impact for attacker credit')
                        self.impacts=self.impacts+1;self.projectiles[id]=nil
                        self.delayedSplash=self.frame+16
                    elseif p.ttl<=0 then self.projectiles[id]=nil end
                end
            end
            if self.delayedSplash and self.frame==self.delayedSplash then
                assert(self.valid or self.allowDeadOwner,'outer delayed splash also needs its living owner')
                self.splashHit=true
            end
            if self.thread and not self.cancelled and coroutine.status(self.thread)~='dead' and self.wake<=self.frame then
                local ok,delay=coroutine.resume(self.thread)
                assert(ok,delay)
                self.wake=self.frame+(delay or 1)
            end
        end
    end
    function w:untilPhase(phase,limit)
        for _=1,limit or 1200 do
            if self.rules.icarus_flight_phase==phase then return end
            self:step()
        end
        error('phase '..phase..' not reached; last '..tostring(self.rules.icarus_flight_phase))
    end
    local chunk
    if setfenv then chunk=assert(loadfile(path));setfenv(chunk,e) else chunk=assert(loadfile(path,'t',e)) end
    chunk();w.env=e;e.script.Create()
    return w
end

local w=fixture();w.build=0.5;w:step(40)
assert(w.launches==0 and not w.controlled,'unfinished construction cannot launch')
w.build=1;w:untilPhase(3)
assert(w.launches==1 and w.launchTop==2048 and w.neverLand)
local x,z=w.position[1],w.position[3]
local initialReads=w.reads
w:step(300)
assert(w.rules.icarus_flight_phase==3 and w.projectileCount==0)
assert(w.position[2]>=1536-0.001 and (w.position[1]-x)^2+(w.position[3]-z)^2>100,'loiter must move around its circle')
assert(w.reads-initialReads<=102,'state decisions are bounded to 10 Hz')
assert(not w.env.script.AimWeapon1() and w.env.script.BlockShot1() and not w.env.script.FireWeapon1())
w:order(w.env.CMD.ATTACK,{w.position[1],0,w.position[3]},{internal=true});w:step(15)
assert(w.projectileCount==0,'internal/autonomous attack must not designate a strike')
w:order(w.env.CMD.ATTACK,{w.position[1],0,w.position[3]},{coded=8});w:step(15)
assert(w.projectileCount==0,'coded internal options also rejected')

-- Explicit ground attack, full fold before native release, live credit carrier,
-- an elevated target contact, then exactly one impact and one silent cleanup.
w=fixture();w:untilPhase(3);w.selfD=3
w:order(w.env.CMD.ATTACK,{1450,0,1000})
w:untilPhase(4);assert(w.projectileCount==0)
w:untilPhase(5);assert(w.projectileCount==0)
w:untilPhase(6)
assert(w.projectileCount==1 and w.valid and w.selfD==0)
assert(w.noDraw and w.noSelect and w.noMinimap and w.nonblocking and w.neutral and w.sensorsZero)
assert(w.env.script.HitByWeapon(0,0,1,500)==0)
w.hitHeight=120;w:step(300)
assert(w.impacts==1 and w.splashHit and w.destroyed==1 and not w.valid)
w:step(300);assert(w.projectileCount==1 and w.impacts==1 and w.destroyed==1)

-- Unit targets follow their position before commitment; changing or cancelling
-- the order during folding restores the wings instead of launching late.
w=fixture();w:untilPhase(3);w:order(w.env.CMD.ATTACK,{88});w:step(30)
w.target={1800,0,1200};w:untilPhase(5)
assert(w.position[1]==1800 and w.position[3]==1200)
w.commands={};w:step(45)
assert(w.projectileCount==0 and w.valid and w.rules.icarus_flight_phase==3)
assert(w.animations['turn:101:1'].target<0 and w.animations['turn:102:1'].target>0)
w:order(w.env.CMD.ATTACK,{88});w:untilPhase(5);w.targetAlive=false;w:step(45)
assert(w.projectileCount==0,'target dying during folding aborts release')

w=fixture();w:untilPhase(3);w:order(w.env.CMD.ATTACK,{88});w:step(15);w.targetAlive=false;w:step(6)
assert(w.rules.icarus_flight_phase==3 and w.projectileCount==0,'dead target cancels transit')

w=fixture();w:untilPhase(3);w:order(w.env.CMD.ATTACK,{88});w:step(9)
assert(w.scopedReads and w.scopedReads>0)
w.targetVisible=false;w:step(6)
assert(w.rules.icarus_flight_phase==3 and w.projectileCount==0,'lost contact cannot be followed through fog')
w.targetVisible=true;w.env.UnitDefs[10].modCategories={air=true}
w:order(w.env.CMD.ATTACK,{88});w:step(6)
assert(w.rules.icarus_flight_phase==3,'unit targeting preserves the GROUND-only restriction')
w:order(w.env.CMD.ATTACK,{7});w:step(6)
assert(w.projectileCount==0,'self targeting is rejected')
w=fixture();w:untilPhase(3);w.target={w.position[1]+200,0,w.position[3]};w.radarError=75
w:order(w.env.CMD.ATTACK,{88});w:untilPhase(5)
assert(w.position[1]==w.target[1]+75,'radar designation uses team-scoped perceived coordinates')

-- Manual release must retain the engine's EMP/stun gate, including a stun that
-- starts after the folding animation has already begun.
w=fixture();w.stunned=true;w:step(60)
assert(w.launches==0,'a stunned completed payload waits before actual departure')
w.stunned=false;w:untilPhase(3)
w.stunned=true;w:order(w.env.CMD.ATTACK,{w.position[1],0,w.position[3]});w:step(40)
assert(w.projectileCount==0,'stunned aircraft cannot start a strike')
w.stunned=false;w:untilPhase(5);w.stunned=true;w:step(50)
assert(w.projectileCount==0 and w.valid,'EMP during folding aborts the release')
w.stunned=false;w:untilPhase(6)
assert(w.projectileCount==1,'a still-current designation can resume after EMP')

-- Existing movement and patrol remain usable; STOP aborts a designated run.
w=fixture();w:untilPhase(3);w:order(w.env.CMD.MOVE,{1300,0,1000});w:untilPhase(4)
w:untilPhase(3);assert(w.projectileCount==0 and #w.commands==0)
w:order(w.env.CMD.PATROL,{1600,0,1000});w:step(10)
assert(#w.commands==2,'single patrol also keeps its start waypoint')
w:step(240);assert(#w.commands==2 and w.projectileCount==0,'patrol keeps cycling')
w:order(w.env.CMD.PATROL,{1900,0,900});w:step(6)
assert(#w.commands==2,'replacing a patrol keeps a return leg')
w:order(w.env.CMD.MOVE,{1800,0,1000});w:step(6)
w:order(w.env.CMD.PATROL,{1700,0,1000});w:step(6)
assert(#w.commands==2,'patrol/move/patrol replacement must not strand a one-point patrol')
w:order(w.env.CMD.ATTACK,{2500,0,1000});w:step(9)
w:order(w.env.CMD.STOP,{});w:step(6)
assert(w.rules.icarus_flight_phase==3 and w.projectileCount==0)

-- A failed native spawn retains the aircraft; a stuck projectile cannot retain
-- an invisible owner indefinitely, even if the engine never clears its ID.
w=fixture();w:untilPhase(3);w.spawnFailure=true
w:order(w.env.CMD.ATTACK,{w.position[1],0,w.position[3]});w:step(80)
assert(w.valid and not w.noDraw and w.projectileCount==0 and w.errors==1)
w=fixture();w:untilPhase(3);w.freezeProjectile=true
w:order(w.env.CMD.ATTACK,{w.position[1],0,w.position[3]});w:untilPhase(6);w:step(1000)
assert(not w.valid and w.destroyed==1 and w.forcedProjectileCleanup)
w=fixture();w:untilPhase(3);w:order(w.env.CMD.ATTACK,{88});w:untilPhase(5)
local lockedX,lockedZ=w.position[1],w.position[3]
w.target={w.target[1]+300,0,w.target[3]+300};w:untilPhase(6)
local bomb=w.projectiles[901]
assert(bomb.position[1]==lockedX and bomb.position[3]==lockedZ,'moving targets cannot steer a committed drop')
assert(w.projectileCount==1,'an explicit unit designation also releases once')
w.env.script.Killed();w.valid=false;w.allowDeadOwner=true;w:step(300)
assert(w.cancelled and next(w.projectiles)==nil and w.impacts==1,'forced owner removal does not restart controller or cancel an already released native bomb')

-- Lethal pre-release damage hands movement to the existing crash system and
-- cannot leave a coroutine that later reacquires MoveCtrl or releases a bomb.
w=fixture();w:untilPhase(3);w:order(w.env.CMD.ATTACK,{88});w:step(6)
w.env.BeginAircraftCrash();local p=w.position[1];w:step(300)
assert(w.rules.icarus_flight_phase==7 and not w.controlled and w.disabled==1 and w.projectileCount==0)
assert(w.position[1]==p)
w=fixture();w:untilPhase(3);w.env.script.Killed();w.valid=false;w:step(300)
assert(w.projectileCount==0 and w.cancelled)

print('PASS: Icarus construction/ascent, circling, explicit/visible targets, move/patrol/stop, fold waits/EMP, gravity release, attribution carrier, one impact, failures and crashes')
