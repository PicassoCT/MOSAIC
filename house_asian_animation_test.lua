-- Lua 5.1+: real house sequences and lifecycle controller, cooperative scheduler.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function compile(source,env)
    if setfenv then local f=assert(loadstring(source));setfenv(f,env);return f end
    return assert(load(source,'asian animation test','t',env))
end
local source=read('scripts/house_asian_script.lua')
local function section(a,b)
    local first=assert(source:find(a,1,true))
    return source:sub(first,assert(source:find(b,first+#a,true))-1)
end
local function scenario(reconstruction, invisibleCrane)
    local names, states, children, groups, selected, events={}, {}, {}, {}, {}, {}
    local workers, current, now={},nil,0
    local function piece(name)
        if not names[name] then
            local p=#states+1;names[name]=p
            states[p]={pos={11,22,33},rot={0.1,0.2,0.3},move={},turn={},spin={}}
            children[p]={}
        end
        return names[name]
    end
    local function group(name,count,parent)
        local t={};groups[name]=t
        for i=1,count do t[i]=piece(name..i);if parent then children[parent][#children[parent]+1]=t[i] end end
        return t
    end
    local weld=piece('ID_l100_Industrial_RoofBlock1');group('ID_l100_Industrial_RoofBlock1Sub',29,weld)
    local factory=piece('ID_l100_Industrial_RoofBlock2');group('ID_l100_Industrial_RoofBlock2Sub',10,factory)
    local turntable=group('ID_l100_Industrial_RoofBlock2Spin',1,factory)[1]
    for _,n in ipairs({'Raise','Grab'})do children[factory][#children[factory]+1]=piece('ID_l100_Industrial_RoofBlock2'..n) end
    local mill=piece('ID_l100_Industrial_RoofBlock4');group('ID_l100_Industrial_RoofBlock4Sub',10,mill)
    local oil=piece('Industrial_Floor1');group('Industrial_Floor1Sub',8,oil)
    local crane=piece('ID_a1_Office_Industrial_Pod_Wall3Sub1')
    piece('ID_a1_Office_Industrial_Pod_Wall3')
    local generic=group('Roof84Spin',2)
    local hiddenRoot=piece('Roof89');local hiddenSpins=group('Roof89Spin',2,hiddenRoot)
    for _,p in ipairs({weld,factory,mill,oil,crane,generic[1],turntable})do selected[p]=p end
    local function event(kind,p,a,value,speed)
        events[#events+1]={kind=kind,p=p,axis=a,value=value,speed=speed,time=now}
    end
    local env=setmetatable({unitID=1,x_axis=1,y_axis=3,z_axis=2,_x_axis=1,
        piece=piece, boolDoneShowing=false, toShowDict=selected,
        pieceName_pieceNr=names,TablesOfPiecesGroups=groups,
        GG={ManualRenderedBuildingWithWindowsVisiblePieces={}},Icon=piece('Icon'),
        SetRadiancePlaceables=function()end,
        maRa=function()return invisibleCrane end,randSign=function()return 1 end,
        lecho=function()end,
    },{__index=_G})
    env._G=env
    local function resume(w)
        local previous=current;current=w
        local ok,err=coroutine.resume(w.co);assert(ok,err);current=previous
    end
    env.Sleep=function(ms)current.wake=now+ms;coroutine.yield()end
    env.StartThread=function(fn,...)
        local args={...};local w={mask=0,wake=now,active=true}
        w.co=coroutine.create(function()fn(unpack(args))end);workers[#workers+1]=w;resume(w)
    end
    env.SetSignalMask=function(mask)current.mask=mask end
    env.Signal=function(mask)
        for _,w in ipairs(workers)do
            if math.floor(w.mask/mask)%2==1 then w.active=false end
        end
    end
    env.Show=function(p)assert(states[p]);if not states[p].detached then states[p].visible=true;event('show',p) end end
    env.Hide=function(p)states[p].visible=false;event('hide',p)end
    env.IsBuildingPieceVisible=function(p)return states[p].visible end
    env.IsBuildingPieceDetached=function(p)return states[p].detached end
    for _,kind in ipairs({'Move','Turn'})do
        local field=kind:lower();local pose=kind=='Move' and 'pos' or 'rot'
        env[kind]=function(p,a,v,s)
            assert(p);assert(v);event(field,p,a,v,s)
            if s==0 then states[p][pose][a]=v
            else states[p][field][a]=v end
        end
    end
    env.Spin=function(p,a,v,s)states[p].spin[a]=v;event('spin',p,a,v,s)end
    env.StopSpin=function(p,a)states[p].spin[a]=nil;event('stop',p,a)end
    for _,kind in ipairs({'Move','Turn'})do
        env['WaitFor'..kind]=function(p,a)
            if not a or states[p][kind:lower()][a]==nil then return end
            env.Sleep(50)
            if a and states[p][kind:lower()][a] then
                local field=kind=='Move' and 'pos' or 'rot'
                states[p][field][a]=states[p][kind:lower()][a];states[p][kind:lower()][a]=nil
            end
        end
        env['W'..kind]=function(p,a,v,s)env[kind](p,a,v,s);env['WaitFor'..kind](p,a)end
    end
    env.WaitForMoves=function()env.Sleep(50)end
    env.Spring={UnitScript={},GetUnitPieceMap=function()return names end,
        SetUnitRulesParam=function()end,
        GetUnitPieceInfo=function(_,p)return {children=children[p]}end}
    local native=env.Spring.UnitScript
    for _,name in ipairs({'Move','Turn','Spin','StopSpin'})do native[name]=env[name]end
    for _,kind in ipairs({'Move','Turn','Spin'})do
        native['IsIn'..kind]=function(p,a)return states[p][kind:lower()][a]~=nil end
    end
    native.GetPieceTranslation=function(p)return unpack(states[p].pos)end
    native.GetPieceRotation=function(p)return unpack(states[p].rot)end
    env.reset=function(p,s)
        for a=1,3 do env.StopSpin(p,a);env.Move(p,a,0,s or 0);env.Turn(p,a,0,s or 0)end
    end
    env.resetT=function(t,s)for _,p in ipairs(t)do env.reset(p,s)end end
    env.showT=function(t,first,last)for i=first or 1,last or #t do env.Show(t[i])end end
    env.hideT=function(t)for _,p in ipairs(t)do env.Hide(p)end end
    env.takeTableSubRange=function(t,a,b)local r={};for i=a,b do r[#r+1]=t[i]end;return r end
    env.inToShowDict=function(p)return selected[p]~=nil end
    env.showOneOrAllOfTablePieceGroup=function(name)
        if groups[name] then selected[groups[name][1]]=groups[name][1] end
    end
    env.sortPiecesInDictionaryByHeight=function(t)local r={};for p in pairs(t)do r[#r+1]=p end;table.sort(r);return r end
    local clearance=false
    env.waitForCityConstruction=function()while not clearance do env.Sleep(100)end end
    env.controller=compile(read('scripts/lib_house_asian_animations.lua'),env)()
    compile('local houseAnimations=controller;local selectedSpins={};local animationsReady=false;local ToShowTable={}\n'..
        'local windowGeometryRevision,windowGeometryReady=0,false;local pieceNr_pieceName={}\n'..
        section('function weldingAnimation(set)','function getNameFilteredDictionary(')..
        section('function showSubsAnimateSpins(pieceGroupName','function showHideSwitch(')..
        section('local function updateWindowGeometryRevision()','function addGroundPlaceables()')..
        '\nfunction SetPlan() for p in pairs(toShowDict)do ToShowTable[#ToShowTable+1]=p end end',env)()
    local function advance(ms)
        for _=1,math.ceil(ms/50)do
            now=now+50
            -- Finish only hold-at-current-pose commands automatically. Other
            -- native animations remain active until their mocked wait completes.
            for _,s in ipairs(states)do
                for a=1,3 do
                    if s.move[a]==s.pos[a] then s.move[a]=nil end
                    if s.turn[a]==s.rot[a] then s.turn[a]=nil end
                end
            end
            for _,w in ipairs(workers)do
                if w.active and coroutine.status(w.co)~='dead' and w.wake<=now then resume(w)end
            end
        end
    end
    env.showSubsAnimateSpins('Roof',84)
    env.showSubsAnimateSpins('ID_l100_Industrial_RoofBlock',2)
    env.SetPlan();env.StartThread(env.buildAnimation,reconstruction);advance(500)
    env.boolDoneShowing=true;advance(5000)
    if reconstruction then
        for _,e in ipairs(events)do assert(e.kind~='spin' and e.kind~='move' and e.kind~='turn','animation before reconstruction clearance')end
        clearance=true;advance(30000)
    end
    advance(5000)
    local spun,forward,backward={},{},{}
    for _,e in ipairs(events)do
        if e.kind=='spin' then spun[e.p]=true end
        assert(e.p~=generic[2] and e.p~=hiddenSpins[1] and e.p~=hiddenSpins[2],'unselected spinner animated')
        if e.kind=='turn' and e.p==groups.ID_l100_Industrial_RoofBlock1Sub[3] then
            if e.value>0 then forward[e.p]=true elseif e.value<0 then backward[e.p]=true end
        end
    end
    assert(spun[generic[1]] and not spun[turntable],'generic spinner missing or competing with turntable')
    assert(forward[groups.ID_l100_Industrial_RoofBlock1Sub[3]] and backward[groups.ID_l100_Industrial_RoofBlock1Sub[3]],'welding did not alternate')
    for _,key in ipairs({'robotTable','offset','movePiece','spinPiece','workSteps','val','jack1'})do
        assert(rawget(env,key)==nil,'animation leaked shared state: '..key)
    end
    local count=#workers;env.controller.start();assert(#workers==count,'duplicate animation startup')
    env.hideHouse()
    local before=#events;advance(10000);assert(#events==before,'hidden machinery kept running')
    for _,s in ipairs(states)do assert(not next(s.spin) and not next(s.move) and not next(s.turn),'hidden native animation survived')end
    env.showHouse();advance(5000);assert(#events>before,'revealed machinery failed to restart')
    local detached={oil};for _,p in ipairs(children[oil])do detached[#detached+1]=p end
    for _,p in ipairs(detached)do states[p].detached=true end
    env.controller.detach(detached)
    before=#events;advance(5000)
    for i=before+1,#events do assert(not states[events[i].p].detached,'detached module worker survived')end
    for _,p in ipairs(detached)do assert(not next(states[p].spin) and not next(states[p].move) and not next(states[p].turn),'detached native motion survived')end
    env.hideHouse();env.showHouse();env.hideHouse();env.showHouse();before=#events;advance(5000)
    for i=before+1,#events do assert(not states[events[i].p].detached,'detached module restarted')end
    env.controller.stop(false,true);before=#events;advance(10000);assert(#events==before,'workers survived building death')
end
scenario(false,false)
scenario(true,true)
print('PASS Asian animations: selected spins, construction gating, concurrent sequences, hide/reveal, native motion cancellation and permanent retirement')
