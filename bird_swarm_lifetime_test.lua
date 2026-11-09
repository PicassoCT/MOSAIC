-- Run the actual unit script on a virtual clock with independently scheduled
-- script threads. This catches sleeps that accidentally multiply the lifetime.
local file=assert(io.open('scripts/birdswarmscript.lua'))
local source=file:read('*a');file:close()
local function run(height,kind,stallFlight)
    local now,dead,destroyed,disabled,goals=0,false,0,0,{}
    local position={20,height,20}
    local threads,current={},nil
    local env=setmetatable({unitID=99,unitDefID=1,UnitDefs={[1]={name=kind}},
        script={},y_axis=2},{__index=_G})
    env._G=env
    env.include=function()end;env.piece=function()return 1 end
    env.getPieceTableByNameGroups=function()return {Raven={2,3},Gull={4,5}}end
    env.Hide=function()end;env.Show=function()end;env.Spin=function()end
    env.Sleep=function(ms)
        if current==2 then
            assert(ms<1000,'flight loop added seconds of delay per animation step')
            if stallFlight then ms=120000 end
        end
        coroutine.yield(ms)
    end
    env.StartThread=function(fn)
        threads[#threads+1]={co=coroutine.create(fn),wake=now}
    end
    env.Spring={
        GetUnitPosition=function()return position[1],position[2],position[3]end,
        GetGroundHeight=function()return 0 end,
        SetUnitAlwaysVisible=function()end,SetUnitNoSelect=function()end,
        SetUnitBlocking=function()end,PlaySoundFile=function()end,
        SetUnitMoveGoal=function(id,x,y,z)
            assert(id==99 and x==x and y==y and z==z)
            goals[#goals+1]=now
        end,
        DestroyUnit=function(id,selfDestruct,reclaimed)
            assert(id==99 and not selfDestruct and reclaimed)
            dead=true;destroyed=destroyed+1
        end,
        MoveCtrl={Enable=function()end,Disable=function()disabled=disabled+1 end,
            SetPosition=function(id,x,y,z)
                assert(id==99 and x==x and y==y and z==z)
                position={x,y,z}
            end},
    }
    local chunk
    if setfenv then chunk=assert(loadstring(source));setfenv(chunk,env)
    else chunk=assert(load(source,'bird swarm','t',env))end
    chunk();env.script.Create()
    env.setShotNearby({x=20,z=20,height=height}) -- coincidence must stay finite
    while not dead do
        local selected
        for i,t in ipairs(threads) do
            if coroutine.status(t.co)~='dead' and (not selected or t.wake<threads[selected].wake) then selected=i end
        end
        assert(selected,'all script threads ended without removing swarm')
        current=selected;local t=threads[selected];now=t.wake
        assert(now<=60000,'swarm outlived hard lifetime')
        local ok,delay=coroutine.resume(t.co);assert(ok,delay)
        t.wake=now+(delay or 0)
    end
    assert(destroyed==1)
    if stallFlight or height>1000 then assert(now==60000,'hard expiry did not run')
    else assert(now>30000 and now<60000,'normal flight/descent lifetime changed unexpectedly')end
    if not stallFlight then
        assert(disabled==1 and #goals==4,'wandering handoff or five-second retarget interval changed')
        for i=2,#goals do assert(goals[i]-goals[i-1]>=4980 and goals[i]-goals[i-1]<=5020)end
    end
    assert(env.sx==nil and env.sy==nil and env.sz==nil and env.gh==nil,'flight leaked globals')
end
for _,kind in ipairs({'ravenswarm','gullswarm'}) do
    run(180,kind,false)
    run(3000,kind,false)
    run(180,kind,true)
end
print('PASS: gull/raven flight and descent finish below 60s; tall/stalled flights expire at 60s; wandering retargets every 5s without extending flight')
