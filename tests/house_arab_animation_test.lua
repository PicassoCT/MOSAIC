-- Exercise the production reveal paths and their cooperative animation workers.
local file = assert(io.open('scripts/house_arab_script.lua'))
local source = file:read('*a'); file:close()
local function section(first, last)
    local a = assert(source:find(first, 1, true))
    return source:sub(a, assert(source:find(last, a + #first, true)) - 1)
end
local function scenario(laterConstruction, selected, clockSelected)
    local now, current = 0, nil
    local workers, events, visible, detached = {}, {}, {}, {}
    local names, nextPiece = {}, 0
    local function piece(name)
        if not names[name] then nextPiece=nextPiece+1; names[name]=nextPiece end
        return names[name]
    end
    local groups = {
        StreetDeco6Sub={piece('clockHand1'),piece('clockHand2')},
        Build={piece('build1'),piece('build2'),piece('build3')},
        Build1Sub={piece('scaffold')},
        BuildCrane={piece('crane1'),piece('crane2')},
    }
    local spin, turn, wind, move = piece('spin'),piece('turn'),piece('wind'),piece('move')
    local hiddenSpin, hiddenTurn, hiddenWind, hiddenMove =
        piece('unusedSpin'),piece('unusedTurn'),piece('unusedWind'),piece('unusedMove')
    local clock = piece('StreetDeco6')
    local env = setmetatable({
        unitID=1, x_axis=1, y_axis=3, z_axis=2, _x_axis=1, _y_axis=2,
        _z_axis=3, cubeDim={heigth=100}, TablesOfPiecesGroups=groups,
        boolDoneShowing=false, ToShowTable={},
        spinYPieces={spin,hiddenSpin},
        pericodicRotationYPieces={[turn]=false,[hiddenTurn]=false},
        windsolar={[wind]=false,[hiddenWind]=false},
        pericodicMovingZPieces={[move]=5000,[hiddenMove]=5000},
        GG={CityConstructionSites=laterConstruction and {[1]={}} or {}},
        Spring={GetGameSeconds=function() return laterConstruction and 20 or 0 end,
            UnitScript={GetPieceRotation=function() return 0.1,0.2,0.3 end}},
        piece=piece, timeOfDay=function()return 0.5 end, randSign=function()return 1 end,
        IsBuildingPieceVisible=function(p)return visible[p] and not detached[p] end,
        IsBuildingPieceDetached=function(p)return detached[p] end,
        finalizeBuildingShadowVoxels=function()end, PlaySoundByUnitDefID=function()end,
    }, {__index=_G})
    local function resume(worker)
        local previous=current; current=worker
        local ok,err=coroutine.resume(worker.co); assert(ok,err)
        current=previous
    end
    env.Sleep=function(ms) current.wake=now+ms; coroutine.yield() end
    env.StartThread=function(fn,...)
        local args={...}
        local worker={mask=0,wake=now,active=true}
        worker.co=coroutine.create(function()fn(unpack(args))end)
        workers[#workers+1]=worker; resume(worker)
    end
    env.SetSignalMask=function(mask)current.mask=mask end
    env.Signal=function(mask)
        for _,w in ipairs(workers)do if w.mask==mask then w.active=false end end
    end
    local function record(kind,p,axis,value,speed)
        events[#events+1]={kind=kind,p=p,axis=axis,value=value,speed=speed,time=now}
    end
    env.Spin=function(p,a,v,s)record('spin',p,a,v,s)end
    env.Turn=function(p,a,v,s)record('turn',p,a,v,s)end
    env.Move=function(p,a,v,s)record('move',p,a,v,s)end
    env.WTurn=function(...)env.Turn(...); env.Sleep(100)end
    env.WMove=env.Move
    env.WaitForTurns=function()end
    env.WaitForMoves=function()end
    env.TurnTowardsWind=function(p,s)env.Turn(p,env.y_axis,0.4,s)end
    env.foreach=function(t,fn)for _,p in pairs(t)do fn(p)end end
    env.showT=function(t)for _,p in pairs(t)do visible[p]=true end end
    env.hideT=function(t)for _,p in pairs(t)do visible[p]=nil end end
    env.moveT=function(t,a,v,s)for _,p in pairs(t)do env.Move(p,a,v,s)end end
    env.moveSyncInTimeT=function()end
    env.waitForCityConstruction=function()
        while env.GG.CityConstructionSites[1] do env.Sleep(100) end
    end
    local code='local decorationsStarted=false; local SIG_BUILD_CRANES=4;\n'..
        section('function rotations()', 'function buildHouse()')..
        section('function buildAnimation()', 'function buildBuilding()')
    local chunk
    if setfenv then chunk=assert(loadstring(code)); setfenv(chunk,env)
    else chunk=assert(load(code,'arab animations','t',env)) end
    chunk()
    local function advance(ms)
        local finish=now+ms
        while now<finish do
            now=now+50
            for _,w in ipairs(workers)do
                if w.active and coroutine.status(w.co)~='dead' and w.wake<=now then resume(w) end
            end
        end
    end
    local function assertNoDecorations()
        for _,e in ipairs(events)do
            assert(e.p~=spin and e.p~=turn and e.p~=wind and e.p~=move,
                'decoration animated before the completed house was revealed')
        end
    end
    env.StartThread(env.buildAnimation)
    advance(1000); assertNoDecorations()
    if selected then env.ToShowTable={spin,turn,wind,move} end
    if clockSelected then env.ToShowTable[#env.ToShowTable+1]=clock end
    env.boolDoneShowing=true
    if laterConstruction then
        advance(16000); assertNoDecorations()
        env.GG.CityConstructionSites[1]=nil
    end
    advance(12000)
    local seen, stoppedCranes = {}, {}
    for _,e in ipairs(events)do
        seen[e.p]=true
        assert(e.p~=hiddenSpin and e.p~=hiddenTurn and e.p~=hiddenWind and e.p~=hiddenMove,
            'unselected decoration received an animation command')
        if e.kind=='turn' and e.speed==1 and (e.p==groups.BuildCrane[1] or e.p==groups.BuildCrane[2]) then
            assert(e.axis==env.y_axis and e.value==0.3,'crane stop changed its current pose or axis')
            stoppedCranes[e.p]=true
        end
    end
    for _,p in ipairs({spin,turn,wind,move})do
        assert((seen[p] or false)==selected,'selected decoration lost its animation')
    end
    for _,p in ipairs(groups.StreetDeco6Sub)do
        assert((seen[p] or false)==clockSelected,'clock selection did not control its hands')
    end
    if laterConstruction then
        for _,p in ipairs(groups.BuildCrane)do assert(stoppedCranes[p] and not visible[p]) end
        local before=#events; advance(5000)
        for i=before+1,#events do
            assert(events[i].p~=groups.BuildCrane[1] and events[i].p~=groups.BuildCrane[2],
                'retired construction crane kept turning')
        end
    end
    local before=#workers; env.StartThread(env.rotations)
    assert(#workers==before+1,'repeated animation startup duplicated workers')
    if selected then
        local periodic={turn,wind,move}
        for _,p in ipairs(periodic)do visible[p]=nil end
        local first=#events+1; advance(3000)
        for i=first,#events do
            for _,p in ipairs(periodic)do
                assert(events[i].p~=p,'hidden decoration received a periodic command')
            end
        end
        for _,p in ipairs(periodic)do visible[p]=true end
        first=#events+1; advance(3000)
        local resumed={}
        for i=first,#events do resumed[events[i].p]=true end
        for _,p in ipairs(periodic)do
            assert(resumed[p],'revealed decoration failed to resume')
            detached[p]=true
        end
        first=#events+1; advance(3000)
        for i=first,#events do
            for _,p in ipairs(periodic)do
                assert(events[i].p~=p,'detached decoration received a periodic command')
            end
        end
        for _,w in ipairs(workers)do
            assert(not w.active or coroutine.status(w.co)=='dead',
                'animation worker survived permanent detachment')
        end
    end
end

scenario(false,false,false)
scenario(false,true,true)
scenario(true,true,false)
print('PASS Arabic house animations: reveal gating, selected variants, clock hands, crane retirement, hiding, and detachment')
