-- Full production cycles at real movement speeds, with the exported hierarchy.
local function scenario(passes, stallFirstTakeoff)
    local now,current,workers,states,names,children=0,nil,{},{},{},{}
    local launches,recoveries,errors=0,0,{}
    local flightStarted,stallInjected,recovering=false,false,false
    local prefix='ID_l100_Industrial_RoofBlock1Sub'
    local function piece(name,parent)
        local p=#states+1;names[name]=p
        states[p]={pos={0,0,0},rot={0,0,0},move={},turn={},spin={},visible=false}
        children[p]={}
        if parent then table.insert(children[parent],name)end
        return p
    end
    local root=piece('ID_l100_Industrial_RoofBlock1')
    local elevator=piece(prefix..25,root)
    local raw=piece(prefix..26,elevator)
    local final=piece(prefix..27,elevator)
    local doors={piece(prefix..28,root),piece(prefix..29,root)}
    local chains={}
    for i,indices in ipairs({{1,101,102,103,104,105},{7,8,9,10,11,12},{13,14,15,16,17,18},{19,20,21,22,23,24}})do
        local parent=elevator;chains[i]={}
        for j,n in ipairs(indices)do parent=piece(prefix..n,parent);chains[i][j]=parent end
    end
    local function resume(w)
        local previous=current;current=w
        local ok,err=coroutine.resume(w.co)
        if not ok then errors[#errors+1]=err end
        current=previous
    end
    local env=setmetatable({unitID=1,x_axis=1,y_axis=3,z_axis=2},{__index=_G})
    env.math=setmetatable({random=function(a,b)
        if a==7 and b==15 then return passes end
        return math.floor((a+b)/2)
    end},{__index=math})
    env.Sleep=function(ms)current.wake=now+ms;coroutine.yield()end
    env.StartThread=function(fn)
        local w={co=coroutine.create(fn),mask=0,wake=now,active=true}
        workers[#workers+1]=w;resume(w)
    end
    env.SetSignalMask=function(mask)current.mask=mask end
    env.Signal=function(mask)
        for _,w in ipairs(workers)do if math.floor(w.mask/mask)%2==1 then w.active=false end end
    end
    env.IsBuildingPieceDetached=function()return false end
    env.IsBuildingPieceVisible=function(p)return states[p].visible end
    env.Show=function(p)
        if p==raw then
            assert(not states[final].visible and states[elevator].pos[3]==0,'new frame loaded before platform returned')
            recovering=false
        elseif p==final then assert(not states[raw].visible,'finished vehicle overlaps raw frame')end
        states[p].visible=true
    end
    env.Hide=function(p)
        if p==final and flightStarted then
            assert(states[final].pos[2]==720 and states[final].pos[3]==600,'VTOL hidden before departure finished')
            launches=launches+1;flightStarted=false
        end
        states[p].visible=false
    end
    for _,kind in ipairs({'Move','Turn'})do
        local field=kind:lower();local pose=kind=='Move' and 'pos' or 'rot'
        env[kind]=function(p,a,v,speed)
            assert(states[p] and a and v and speed,'invalid motion')
            if kind=='Move' and p==elevator and a==3 and v==0 then
                assert(recovering or not states[final].visible,'elevator lowered while its child VTOL was visible')
            end
            if kind=='Move' and p==final and a==2 and v==720 then
                assert(states[elevator].pos[3]==85 and states[final].pos[3]==150,'VTOL left before clearing hatch')
                assert(math.abs(states[doors[1]].rot[1]+math.rad(110))<1e-5)
                assert(math.abs(states[doors[2]].rot[1]-math.rad(110))<1e-5)
                flightStarted=true
            end
            if stallFirstTakeoff and not stallInjected and kind=='Move' and p==final and a==3 and v==150 then
                states[final].stalled=true;stallInjected=true
            end
            if speed==0 then states[p][pose][a]=v
            else states[p][field][a]={target=v,speed=speed}end
        end
        env['WaitFor'..kind]=function(p,a)
            assert(states[p] and a,'invalid wait')
            while states[p][field][a] do env.Sleep(50)end
        end
    end
    env.StopSpin=function(p,a)states[p].spin[a]=nil end
    env.Spring={UnitScript={},GetUnitPieceMap=function()return names end,
        GetUnitPieceInfo=function(_,p)return {children=children[p]}end,
        Echo=function(message)
            assert(message:find('no movement progress',1,true),message)
            recoveries=recoveries+1;states[final].stalled=false;recovering=true
        end}
    local native=env.Spring.UnitScript
    native.Move,native.Turn=env.Move,env.Turn
    native.GetPieceTranslation=function(p)return unpack(states[p].pos)end
    native.GetPieceRotation=function(p)return unpack(states[p].rot)end
    for _,kind in ipairs({'Move','Turn','Spin'})do
        native['IsIn'..kind]=function(p,a)return states[p][kind:lower()][a]~=nil end
    end
    local function load(name)local f=assert(loadfile('scripts/'..name));setfenv(f,env);return f()end
    local assembly=load('lib_house_asian_vehicle_assembly.lua')
    local controller=load('lib_house_asian_animations.lua')
    local set={elevator=elevator,rawWorks=raw,finalWorks=final,doors=doors}
    for i,chain in ipairs(chains)do
        set['robot'..i..'T']=assembly.robotChain(chain[1])
        for j,p in ipairs(chain)do assert(set['robot'..i..'T'][j]==p,'wrong exported joint chain')end
    end
    controller.add(root,function()assembly.run(set)end)
    controller.start()
    for tick=1,6000 do
        now=now+50
        for _,s in ipairs(states)do
            for _,field in ipairs({'move','turn'})do
                local pose=field=='move' and s.pos or s.rot
                for a,m in pairs(s[field])do
                    if not s.stalled or m.target==pose[a] then
                        local delta=m.target-pose[a]
                        if field=='turn' then delta=(delta+math.pi)%(2*math.pi)-math.pi end
                        local step=m.speed*.05
                        if math.abs(delta)<=step then pose[a]=m.target;s[field][a]=nil
                        else pose[a]=pose[a]+(delta>0 and step or -step)end
                    end
                end
            end
        end
        for _,w in ipairs(workers)do
            if w.active and coroutine.status(w.co)~='dead' and w.wake<=now then resume(w)end
        end
        assert(#errors==0,errors[1])
        if launches>=2 then break end
    end
    assert(launches==2,'assembly failed to complete two production cycles')
    assert(recoveries==(stallFirstTakeoff and 1 or 0),'unexpected stall or missing recovery')
    print('PASS vehicle assembly: '..passes..' passes, two VTOL launches, '..recoveries..' recovered takeoff stall')
end
scenario(7,false)
scenario(15,false)
scenario(7,true)
