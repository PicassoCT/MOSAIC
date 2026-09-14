-- Run from the game root: lua tests/event_thread_optimizations_test.lua
-- Real helpers and changed entry points with a deterministic unit-thread mock.
local unpackArgs = unpack or table.unpack
local function read(path)
    local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s
end
local function run(source, env)
    if setfenv then return setfenv(assert(loadstring(source)), env)() end
    return assert(load(source, 'test', 't', env))()
end
local function fn(path, name)
    local escaped = name:gsub('([%.])', '%%%1')
    return assert(read(path):match('(function '..escaped..'%(.-\nend)'), name)
end
local function overlaps(a, b)
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then return true end
        a, b = math.floor(a / 2), math.floor(b / 2)
    end
    return false
end
local function runtime()
    local frame, active, current = 0, nil, nil
    local threads, envs = {}, {}
    local function resume(t, ...)
        local oldActive, oldCurrent = active, current
        active, current = t.unit, t
        local ok, delay = coroutine.resume(t.co, ...)
        active, current = oldActive, oldCurrent
        assert(ok, delay)
        if coroutine.status(t.co) == 'dead' then t.dead = true
        else t.wake = frame + math.max(1, math.floor(delay / 33)) end
    end
    local r = {}
    function r.unit(id)
        local e = setmetatable({unitID=id, script={}}, {__index=_G})
        envs[id] = e
        function e.StartThread(action, ...)
            assert(active == id, 'missing/wrong CallAsUnit context')
            local t = {unit=id, mask=current and current.mask or 0,
                       co=coroutine.create(action)}
            threads[#threads+1] = t
            resume(t, ...)
        end
        function e.SetSignalMask(mask) assert(current); current.mask=mask end
        function e.Sleep(ms) assert(current, 'yield outside thread'); return coroutine.yield(ms) end
        function e.Signal(mask)
            for _,t in ipairs(threads) do
                if t.unit == id and overlaps(t.mask, mask) then t.dead=true end
            end
        end
        e.Spring = {GetGameFrame=function() return frame end, UnitScript={}}
        function e.Spring.UnitScript.CallAsUnit(unit, action, ...)
            local old = active; active=unit
            local results = {pcall(action, ...)}; active=old
            assert(results[1], results[2]); return unpackArgs(results, 2)
        end
        e.queueEventThread = run(read('scripts/lib_event_threads.lua'), e)
        return e
    end
    function r.call(e, action, ...) return e.Spring.UnitScript.CallAsUnit(e.unitID,action,...) end
    function r.tick(n)
        for _=1,n do
            frame=frame+1
            local count=#threads
            for i=1,count do
                local t=threads[i]
                if not t.dead and t.wake <= frame then resume(t) end
            end
        end
    end
    function r.pending()
        local n=0; for _,t in ipairs(threads) do if not t.dead then n=n+1 end end; return n
    end
    function r.destroy(id)
        for _,t in ipairs(threads) do if t.unit==id then t.dead=true end end
        envs[id]=nil
    end
    return r
end

-- External calls, latest request, nil arguments, inherited cancellation,
-- handler yielding, reentrant requests, and automatic unit death cleanup.
do
    local r=runtime(); local e=r.unit(1); local calls={}
    local function handler(...)
        calls[#calls+1]={n=select('#',...), ...}
        e.Sleep(33)
    end
    r.call(e,e.queueEventThread,'test',handler,33,'old')
    r.call(e,e.queueEventThread,'test',handler,33,'new',nil,9,nil)
    assert(#calls==0 and r.pending()==1)
    r.tick(1)
    assert(#calls==1 and calls[1][1]=='new' and calls[1][3]==9 and calls[1].n==4)
    r.tick(1); assert(r.pending()==0)
    r.call(e,e.StartThread,function()
        e.SetSignalMask(4)
        e.queueEventThread('test',handler,33,'survives')
        e.Sleep(500)
    end)
    r.call(e,e.Signal,4)
    r.tick(2); assert(calls[2][1]=='survives' and r.pending()==0)
    r.call(e,e.queueEventThread,'again',function()
        e.queueEventThread('again',handler,33,'follow-up')
    end,33)
    r.tick(3); assert(calls[3][1]=='follow-up' and r.pending()==0)
    local e2=r.unit(2)
    r.call(e2,e2.queueEventThread,'death',function() error('dead unit ran') end,33)
    r.destroy(2); r.tick(2); assert(r.pending()==0)
end

for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
    local r=runtime(); local e=r.unit(1); local animations, behaviours={},{}
    e.setCivilianUnitInternalStateMode=function() end
    e.GameConfig={STATE_STARTED=1}
    e.x_axis, e.y_axis, e.z_axis = 1, 2, 3
    e.PrayerAnimations = run(read('scripts/animations_civilian_prayers.lua'), e)
    e.conditionalEcho=function() end; e.locationstring=function() return 'test' end
    e.deferedOverrideAnimationState=function(...)
        animations[#animations+1]={...}; e.Sleep(33)
    end
    run(fn(path,'setOverrideAnimationState'),e)
    local condition=function() return true end
    r.call(e,e.setOverrideAnimationState,'old','old',true,nil,false)
    r.call(e,e.setOverrideAnimationState,'upper','lower',false,condition,true)
    r.tick(2)
    assert(#animations==1 and animations[1][1]=='upper' and animations[1][4]==condition)
    assert(e.boolDecoupled==true and r.pending()==0)
    for _,name in ipairs({'wailing','fleeEnemy','pray','aeroSolStateBehaviour'}) do
        e[name]=function(arg) behaviours[#behaviours+1]={name,arg}; e.Sleep(33) end
    end
    run('local behaviourDispatcherClosed=false\n'..fn(path,'threadStateStarter')..'\n'..
        fn(path,'startWailing')..'\n'..fn(path,'startFleeing')..'\n'..
        fn(path,'startPraying')..'\n'..fn(path,'startAerosolBehaviour'),e)
    r.call(e,e.startPraying,3)
    assert(e.prayerAnimationName == 'UPBODY_PRAYER_3')
    r.call(e,e.startFleeing,123)
    r.call(e,e.startWailing,500)
    assert(r.pending()==1)
    r.tick(8)
    assert(#behaviours==3 and behaviours[1][1]=='wailing' and behaviours[2][1]=='fleeEnemy')
    assert(behaviours[2][2]==123 and behaviours[3][1]=='pray' and r.pending()==0)
    r.call(e,e.startAerosolBehaviour,'wanderlost'); r.tick(8)
    r.call(e,e.startPraying); r.tick(8)
    assert(#behaviours==4 and behaviours[4][1]=='aeroSolStateBehaviour' and r.pending()==0)
end

for _,culture in ipairs({'arab','asian','western'}) do
    local path='scripts/house_'..culture..'_script.lua'
    local r=runtime(); local e=r.unit(1); local arcs=0
    e.getSafeRandom=function() return 1 end
    e.spawnCegAtPiece=function() arcs=arcs+1 end
    run('local accumulatedStun=0; local stunAnimationRunning=false; local SIG_STUN=2; '..
        'local RoofTopPieces={1}; stunInterval=1000; stunInteval=1000\n'..
        fn(path,'stunAnimation')..'\n'..fn(path,'stunHouse'),e)
    r.call(e,e.stunHouse,200,100)
    r.call(e,e.stunHouse,100,100)
    assert(r.pending()==1)
    r.tick(30); assert(arcs==3 and r.pending()==0,culture..' stun did not finish')
    r.call(e,e.stunHouse,100,100); r.tick(10)
    assert(arcs==4 and r.pending()==0,culture..' stun did not restart')
end

for _,path in ipairs({'scripts/Truckscript.lua','scripts/LongTruckscript.lua'}) do
    local r=runtime(); local e=r.unit(1); local enemy
    e.fleeEnemy=function(id) enemy=id; e.Sleep(33) end
    run(fn(path,'startFleeing'),e)
    r.call(e,e.startFleeing,42); r.call(e,e.startFleeing,99)
    r.tick(8); assert(enemy==99 and r.pending()==0)
end

-- Ownership call-in supplies all arguments and acts in the correct unit
-- context. Multiple same-frame captures transfer the loadout only once.
do
    local r=runtime(); local e=r.unit(1); local team, transfers=2,{}
    e.Spring.GetUnitTeam=function() return team end
    e.doesUnitExistAlive=function(id) return id==42 end
    e.transferUnitTeam=function(id,t) transfers[#transfers+1]={id,t} end
    local path='scripts/Truckscript.lua'
    run('local loadOutUnitID=42\n'..fn(path,'updateLoadOutOwnership')..'\n'..fn(path,'onUnitGivenEvent'),e)
    local g=setmetatable({gadget={},gadgetHandler={IsSyncedCode=function() return true end},Spring=e.Spring},{__index=_G})
    g.Spring.UnitScript.GetScriptEnv=function(id) if id==1 then return e end end
    run(read('luarules/gadgets/unit_script_ownership_events.lua'),g)
    g.gadget:UnitGiven(1,7,2,0); team=3; g.gadget:UnitGiven(1,7,3,2)
    g.gadget:UnitGiven(999,7,3,2)
    r.tick(1); assert(#transfers==1 and transfers[1][1]==42 and transfers[1][2]==3)
    e.onUnitGivenEvent=function(def,new,old) assert(def==7 and new==4 and old==3) end
    g.gadget:UnitGiven(1,7,4,3)
end

-- Physics-derived motion is retained even without movement callbacks.
do
    local frame,x,heading=0,0,65000
    local e=setmetatable({Spring={GetUnitPosition=function() return x,0,0 end,
        GetUnitHeading=function() return heading end, GetGameFrame=function() return frame end}},{__index=_G})
    local sample=run(read('scripts/lib_vehicle_motion.lua'),e)(1)
    local moving,turning,left=sample(); assert(not moving and not turning)
    frame=3; x=10; heading=500
    moving,turning,left=sample(); assert(moving and turning and not left)
    frame=6; heading=65000
    moving,turning,left=sample(); assert(not moving and turning and left)
end

-- Moving aim completes; the restore timer begins after aiming finishes.
do
    local r=runtime(); local e=r.unit(1); local result
    e.boolTransported=false; e.boolWalking=true
    e.Spring.GetUnitHeading=function() return e.Spring.GetGameFrame()*100 end
    e.PlayAnimation=function() e.Sleep(1000) end
    e.WTurn=function() e.Sleep(100) end
    run('local SIG_AIM=1; local aimrot=1; y_axis=2\n'..
        fn('scripts/groundwalkerscript.lua','sampleHeadingForAim')..'\n'..
        fn('scripts/groundwalkerscript.lua','delayedDeactivateAiming')..'\n'..
        fn('scripts/groundwalkerscript.lua','script.AimWeapon1'),e)
    r.call(e,e.StartThread,function() result=e.script.AimWeapon1(0.5,0) end)
    r.tick(20); assert(e.boolAiming==true and result==nil)
    r.tick(20); assert(result==true and e.boolAiming==true)
    r.tick(20); assert(e.boolAiming==false and r.pending()==0)
end

-- Population scaling: no dispatcher exists until an actual request arrives.
do
    local r=runtime(); local units={}
    for i=1,500 do units[i]=r.unit(i) end
    assert(r.pending()==0)
    for _,e in ipairs(units) do r.call(e,e.queueEventThread,'one',function() end,33) end
    assert(r.pending()==500); r.tick(1); assert(r.pending()==0)
    r.tick(300); assert(r.pending()==0)
end
print('PASS: deferred events, signals, coalescing, civilians, houses, trucks, ownership, motion, moving aim, population scaling')
