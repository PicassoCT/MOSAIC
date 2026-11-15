-- Exercise the real controller using engine-like coroutines: a Lua error kills
-- only its worker, while a native motion may keep its waiter suspended forever.
local function scenario()
    local now,current,workers,logs,errors=0,nil,{},{},{}
    local states={}
    for p=1,6 do states[p]={pos={0,0,0},rot={0,0,0},move={},turn={},spin={},visible=true} end
    local function resume(w)
        local previous=current;current=w
        local ok,err=coroutine.resume(w.co)
        if not ok then errors[#errors+1]=err end
        current=previous
    end
    local env=setmetatable({unitID=42},{__index=_G})
    env.Sleep=function(ms)current.wake=now+ms;coroutine.yield()end
    env.StartThread=function(fn)
        local w={mask=0,wake=now,active=true,co=coroutine.create(fn)}
        workers[#workers+1]=w;resume(w)
    end
    env.SetSignalMask=function(mask)current.mask=mask end
    env.Signal=function(mask)
        for _,w in ipairs(workers)do if math.floor(w.mask/mask)%2==1 then w.active=false end end
    end
    env.Show=function(p)states[p].visible=true end
    env.Hide=function(p)states[p].visible=false end
    env.IsBuildingPieceDetached=function(p)return states[p].detached end
    env.IsBuildingPieceVisible=function(p)return states[p].visible end
    for _,kind in ipairs({'Move','Turn'})do
        local field=kind:lower();local pose=kind=='Move' and 'pos' or 'rot'
        env[kind]=function(p,a,v,s)
            if s==0 then states[p][pose][a]=v -- deliberately retain old destination
            else states[p][field][a]={target=v,speed=s} end
        end
    end
    env.Spin=function(p,a)states[p].spin[a]=true end
    env.StopSpin=function(p,a)states[p].spin[a]=nil end
    env.Spring={UnitScript={},Echo=function(s)logs[#logs+1]=s end,
        GetUnitPieceMap=function()return {broken=1,stalled=2,slow=3,spinner=4,finite=5,persistent=6}end,
        GetUnitPieceInfo=function()return {children={}}end}
    local native=env.Spring.UnitScript
    native.Move,native.Turn=env.Move,env.Turn
    native.GetPieceTranslation=function(p)return unpack(states[p].pos)end
    native.GetPieceRotation=function(p)return unpack(states[p].rot)end
    for _,kind in ipairs({'Move','Turn','Spin'})do
        native['IsIn'..kind]=function(p,a)return states[p][kind:lower()][a]~=nil end
    end
    local f=assert(loadfile('scripts/lib_house_asian_animations.lua'));setfenv(f,env)
    local controller=f()
    local function advance(ms)
        for _=1,math.ceil(ms/50)do
            now=now+50
            for _,s in ipairs(states)do
                for _,kind in ipairs({'move','turn'})do
                    local pose=kind=='move' and s.pos or s.rot
                    for a,m in pairs(s[kind])do
                        if not s.stalled or m.target==pose[a] then
                            local delta=m.target-pose[a];local step=m.speed*.05
                            if math.abs(delta)<=step then pose[a]=m.target;s[kind][a]=nil
                            else pose[a]=pose[a]+(delta>0 and step or -step)end
                        end
                    end
                end
            end
            for _,w in ipairs(workers)do
                if w.active and coroutine.status(w.co)~='dead' and w.wake<=now then resume(w)end
            end
        end
    end
    return controller,env,states,advance,logs,errors
end

local c,e,s,advance,logs,errors=scenario()
local runs={0,0,0,0,0,0}
c.add(1,function()
    runs[1]=runs[1]+1
    if runs[1]==1 then e.Move(1,3,99,5);e.Sleep(100);error('injected assembly failure')end
    assert(s[1].pos[3]==0,'retry did not restore original position')
end)
c.add(2,function()
    runs[2]=runs[2]+1
    if runs[2]==1 then
        s[2].stalled=true;e.Move(2,3,99,5);e.Spin(2,1)
        while true do e.Sleep(100)end
    end
    assert(s[2].pos[3]==0 and not s[2].spin[1],'stalled motion/spin survived restoration')
end)
c.add(3,function()
    runs[3]=runs[3]+1;e.Turn(3,1,1,.001)
    while true do e.Sleep(100)end
end)
c.add(4,function()runs[4]=runs[4]+1;e.Spin(4,3)end)
c.add(5,function()runs[5]=runs[5]+1 end)
c.start();advance(35000)
assert(runs[1]==2 and runs[2]==2,'failed or stalled worker did not recover')
assert(runs[3]==1 and runs[4]==1 and runs[5]==1,'healthy worker restarted')
assert(#logs==2 and #errors==1 and errors[1]:find('injected assembly failure',1,true))
assert(logs[1]:find('broken',1,true) and logs[2]:find('no movement progress',1,true),'diagnostics omit worker/reason')
advance(35000);assert(runs[3]==1,'slow crane-like turn was mistaken for a stall')
c.stop(true);local before=runs[3];advance(40000);assert(runs[3]==before and not s[4].spin[3])
c.start();advance(1000);assert(runs[3]==before+1 and s[4].spin[3],'reveal did not restart native spin')
s[3].detached=true;c.detach({3});before=runs[3]
c.stop(true);c.start();advance(40000);assert(runs[3]==before,'detached worker resurrected')
c.stop(false,true);before=runs[4];c.start();advance(40000);assert(runs[4]==before,'dead building restarted')

-- Persistent failures back off, and a pending retry cannot survive hide/death.
c,e,s,advance,logs,errors=scenario()
local attempts=0
c.add(6,function()attempts=attempts+1;e.Sleep(50);error('persistent failure')end)
c.start();advance(20000)
assert(attempts>=4 and attempts<=6,'persistent errors are not rate limited')
c.stop(true);local beforeAttempts=attempts;advance(60000);assert(attempts==beforeAttempts,'hidden retry fired')
c.start();advance(100);assert(attempts==beforeAttempts+1)
c.stop(false,true);c.start();advance(60000);assert(attempts==beforeAttempts+1,'retired retry fired')
print('PASS Asian recovery: yielded errors, stuck native waits, slow turns, finite setup, backoff, hide/reveal, detach/death')
