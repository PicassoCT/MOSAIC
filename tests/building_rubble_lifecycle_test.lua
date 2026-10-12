-- Run from the repository root with Lua 5.1+.
-- Real category helpers, city adapter/state machine, house Killed, structural
-- damage and both rubble scripts. Engine calls model Recoil 058c8ea ordering:
-- isDead -> UnitDestroyed -> Killed coroutine -> actual removal -> ID reuse.
local function loadEnv(path, env)
    if setfenv then
        local chunk = assert(loadfile(path)); setfenv(chunk, env); return chunk()
    end
    return assert(loadfile(path, 't', env))()
end
local function noop() end
local function copy(t) local out={};for k,v in pairs(t) do out[k]=v end;return out end
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end

local function fixture(rubbleName)
    local defs, names = {}, {}
    local function def(name, params)
        local id=#defs+1
        defs[id]={id=id,name=name,customParams=params or {},moveDef={id=1,name='truck'},buildOptions={}}
        names[name]=defs[id]
    end
    local function family(name,last) for i=0,last do def(name..i) end end
    family('house_arab',0);family('house_western',0);family('house_asian',4)
    family('truck_arab',9);family('truck_western',4)
    family('civilian_arab',5);family('civilian_western',4)
    for a=1,4 do for b=a,4 do
        def('house_asian_split_'..a..'_'..b,{house_asian_base='house_asian0'})
    end end
    for _,name in ipairs({'house_ruin','gcscrapheap','protagonsafehouse','antagonsafehouse',
        'nimrod','propagandaserver','protagonassembly','antagonassembly','launcher',
        'hivemind','warheadfactory'}) do def(name) end
    local state={units={},tasks={},created={},frame=0,nextID=100,peaceful=false,
        failRubble=false,failSite=false,forcedID=nil}
    local env=setmetatable({arg=false,gadget={},UnitDefs=defs,UnitDefNames=names,
        GG={InstanceCulture='international',GlobalGameState='normal'},
        Game={mapName='MOSAIC_LastDayOfDubai_V3',mapSizeX=8192,mapSizeZ=8192},
        gadgetHandler={IsSyncedCode=function() return true end},math=copy(math),
        include=function() return {} end}, {__index=_G})
    env._G=env
    env.table=copy(table)
    env.table.getn=env.table.getn or function(t) return #t end
    -- Force each *real* category choice in turn. Production randDict and the
    -- true-valued set are unchanged; the previous fixtures returned numeric
    -- set values instead and never executed either rubble unit script.
    env.math.random=function(low,high)
        if low==1 and high==2 and env.getBuildingScrapHeapTypeTable then
            local index=0
            for id in pairs(env.getBuildingScrapHeapTypeTable(defs)) do
                index=index+1;if defs[id].name==rubbleName then return index end
            end
        end
        return low or 0.5
    end
    local S
    local function resume(task,...)
        local ok,delay=coroutine.resume(task.co,...)
        assert(ok,delay)
        if coroutine.status(task.co)=='dead' then
            if task.killed then task.unit.deathFinished=true end
        else
            task.wake=state.frame+math.max(1,math.ceil((delay or 0)*30/1000))
            state.tasks[#state.tasks+1]=task
        end
    end
    local function start(unit,fn,killed,...)
        local task={co=coroutine.create(fn),unit=unit,killed=killed}
        resume(task,...)
        return task
    end
    local function scriptEnvironment(id)
        local u=state.units[id]
        local e=setmetatable({unitID=id,unitDefID=u.def,script={},GG=env.GG,
            Game=env.Game,UnitDefs=defs,UnitDefNames=names,Spring=S,
            x_axis=1,y_axis=2,z_axis=3,SFX={FALL=1,FIRE=2},arg=false,
            VFS={},math=copy(math),table=env.table}, {__index=_G})
        e._G=e
        e.piece=function(name) return assert(u.pieces[name],name) end
        e.Show=function(p) assert(p);u.shown[p]=true end
        e.Hide=function(p) assert(p);u.shown[p]=nil end
        e.Move=function(p,axis,goal,speed)
            local at=u.positions[p] or {0,0,0};u.positions[p]=at
            u.moveWait[p]=speed and speed>0 and math.abs(goal-at[axis])/speed*1000 or 0
            at[axis]=goal
        end
        e.Turn=noop;e.Spin=noop;e.StopSpin=noop;e.Explode=noop
        e.Sleep=function(ms) return coroutine.yield(ms) end
        e.WaitForMove=function(p) if (u.moveWait[p] or 0)>0 then e.Sleep(u.moveWait[p]) end end
        e.WaitForTurn=noop
        e.StartThread=function(fn,...) return start(u,fn,false,...) end
        e.SetSignalMask=noop;e.Signal=noop
        e.VFS.Include=function(path) return loadEnv(path,e) end
        e.include=function(path)
            local result=loadEnv('scripts/'..path,e)
            if path=='lib_building_damage.lua' then u.damage=result end
            return result
        end
        u.env=e
        return e
    end
    local function addPieces(u, list)
        for _,name in ipairs(list) do
            local id=#u.pieceList+1
            u.pieceList[id]=name;u.pieces[name]=id
            u.shown[id]=true;u.positions[id]={0,0,0}
        end
    end
    local function addUnit(id,defID,x,z,facing,team,beingBuilt)
        assert(not state.units[id],'engine reused a still-present unit ID')
        local u={id=id,def=defID,x=x,z=z,facing=facing,team=team,dead=false,
            hp=beingBuilt and 1 or 1000,build=beingBuilt and 0 or 1,rules={},
            inLOS=false,alwaysVisible=false,pieces={},pieceList={},shown={},positions={},moveWait={}}
        state.units[id]=u
        local name=defs[defID].name
        if name=='gcscrapheap' then
            addPieces(u,{'center','scrapHeap1','scrapHeap2','corn1','girder1','wall1',
                'winWall1','winDebB1','skyscrape1','excavatorcenter','Excavator',
                'ExArm','ExArmLow','Shovell','Base'})
        elseif name=='house_ruin' then
            addPieces(u,{'Ruin','RuinSub1','RuinCore','RuinCoreSub1','RuinCoreSub1Sub1'})
        else
            addPieces(u,{'center','block1','block2','block3','block4','block5','block6'})
        end
        env.gadget:UnitCreated(id,defID,team)
        if state.blocker then state.blocker:UnitCreated(id,defID) end
        -- Unit-script Create executes synchronously inside Spring.CreateUnit.
        if name=='gcscrapheap' or name=='house_ruin' then
            local script=scriptEnvironment(id)
            loadEnv(name=='gcscrapheap' and 'scripts/gCScrapHeap.lua' or 'scripts/house_ruin_script.lua',script)
            start(u,script.script.Create,false)
        end
        return u
    end
    local function destroy(id,selfd,reclaimed)
        local u=assert(state.units[id]);if u.dead then return end
        u.dead=true
        env.gadget:UnitDestroyed(id,u.def,u.team,nil,nil,nil)
        if state.damageGadget then state.damageGadget:UnitDestroyed(id) end
        if reclaimed or u.build<1 or not u.env or not u.env.script.Killed then
            u.deathFinished=true
        else
            start(u,u.env.script.Killed,true,1000,1000)
        end
    end
    S={GetGaiaTeamID=function() return 0 end,GetModOptions=function() return {} end,
        GetGroundHeight=function() return 10 end,GetGameFrame=function() return state.frame end,
        Echo=noop,SetGameRulesParam=noop,SetUnitTooltip=noop,SetUnitNanoPieces=noop,
        PlaySoundFile=noop,SpawnCEG=noop,SetUnitNeutral=noop,
        SetUnitAlwaysVisible=function(id,value) assert(state.units[id]).alwaysVisible=value end,
        SetUnitBlocking=function(id,blocking,solid,projectile,ray,crushable,push,height)
            local u=assert(state.units[id]);u.blocking=blocking;u.solid=solid
            if crushable~=nil then u.crushable=crushable end
        end,
        GetUnitDefID=function(id) return state.units[id] and state.units[id].def end,
        GetUnitPosition=function(id) local u=state.units[id];if u then return u.x,10,u.z end end,
        GetUnitBuildFacing=function(id) return state.units[id] and state.units[id].facing end,
        ValidUnitID=function(id) return state.units[id]~=nil end,
        GetUnitIsDead=function(id) local u=state.units[id];return u and u.dead end,
        GetUnitHealth=function(id) local u=state.units[id];if u then return u.hp,1000,0,0,u.build end end,
        SetUnitHealth=function(id,t) local u=assert(state.units[id]);u.hp=t.health;u.build=t.build end,
        SetUnitRulesParam=function(id,k,v) assert(state.units[id]).rules[k]=v end,
        GetAllUnits=function()
            local ids={};for id in pairs(state.units) do ids[#ids+1]=id end;table.sort(ids);return ids
        end,
        GetUnitPieceMap=function(id) return assert(state.units[id]).pieces end,
        GetUnitPieceList=function(id) return assert(state.units[id]).pieceList end,
        GetUnitPieceInfo=function(id,p) return {children={},name=state.units[id].pieceList[p]} end,
        GetUnitPiecePosDir=function(id,p)
            local u=assert(state.units[id]);local at=assert(u.positions[p])
            return u.x+at[1],10+at[2],u.z+at[3],0,1,0
        end,
        GetUnitLastAttackedPiece=function() return nil,-1 end,
        UnitScript={GetScriptEnv=function(id) return state.units[id] and state.units[id].env end,
            CallAsUnit=function(id,fn,...) return fn(...) end},
        DestroyUnit=destroy,
        CreateUnit=function(defID,x,y,z,facing,team,beingBuilt)
            assert(type(defID)=='number' and defs[defID], 'invalid real category output')
            if (beingBuilt and state.failSite) or (not beingBuilt and state.failRubble) then return nil end
            local id=state.forcedID
            state.forcedID=nil
            if not id then state.nextID=state.nextID+1;id=state.nextID end
            addUnit(id,defID,x,z,facing,team,beingBuilt)
            state.created[#state.created+1]=id
            return id
        end}
    env.Spring=S
    env.GG.CityAreaState={IsPeaceful=function() return state.peaceful end}
    env.VFS={Include=function(path) return loadEnv(path,env) end}
    loadEnv('luarules/gadgets/game_spawnCity.lua',env)
    env.spawnInitialHouses=noop;env.regenerateRoutesTable=noop;env.setHouseStreetNameTooltip=noop
    env.gadget:Initialize()
    local blocker=setmetatable({gadget={},GG=env.GG,Spring=S,UnitDefs=defs,
        VFS={Include=noop},getBuildingScrapHeapTypeTable=env.getBuildingScrapHeapTypeTable,
        gadgetHandler=env.gadgetHandler},{__index=_G})
    loadEnv('luarules/gadgets/game_building_rubble_blocking.lua',blocker)
    state.blocker=blocker.gadget
    local damageEnv=setmetatable({gadget={},GG=env.GG,Spring=S,UnitDefs=defs,
        VFS={Include=noop},getStructuralBuildingTypeTable=env.getStructuralBuildingTypeTable,
        getBlockDestroyableHouseTypes=env.getBlockDestroyableHouseTypes,
        gadgetHandler=env.gadgetHandler},{__index=_G})
    loadEnv('luarules/gadgets/game_building_block_damage.lua',damageEnv)
    state.damageGadget=damageEnv.gadget;state.damageGadget:Initialize()
    local function tick(frames)
        for _=1,frames do
            state.frame=state.frame+1
            for id,u in pairs(state.units) do
                if u.dead and u.deathFinished then state.units[id]=nil end
            end
            local tasks=state.tasks;state.tasks={}
            for _,task in ipairs(tasks) do
                if state.units[task.unit.id]==task.unit then
                    if task.wake<=state.frame then resume(task)
                    else state.tasks[#state.tasks+1]=task end
                end
            end
            state.damageGadget:GameFrame(state.frame)
            env.gadget:GameFrame(state.frame)
        end
    end
    local function house(id,name,structural)
        local u=addUnit(id,names[name].id,1500,1800,2,1,false)
        env.GG.BuildingTable[id]={x=1500,z=1800,routeID=17}
        if structural then
            local e=scriptEnvironment(id)
            loadEnv('scripts/house_arab_script.lua',e)
            e.initializeBuildingShadowVoxels(20,10,1)
            for column=0,1 do for floor=0,2 do
                local p=u.pieces['block'..(column*3+floor+1)]
                e.Move(p,1,column*20,0);e.Move(p,2,floor*10,0)
                e.houseAddDestructionTable(e.LevelPieces,floor+1,p,column*20,0,floor*10)
                e.addShadowVoxel(column*20,0,floor*10,p)
                e.ToShowTable[#e.ToShowTable+1]=p;e.Show(p)
            end end
            u.damage.initialize(e.LevelPieces,e.ToShowTable,{},nil,10,20,1)
        end
        return u
    end
    return {env=env,S=S,state=state,names=names,house=house,tick=tick,add=addUnit}
end

-- Both authored rubble models replace the completed collapse visibly even
-- outside allied LOS, and are managed before gCScrapHeap's first Sleep ends.
for _,rubble in ipairs({'house_ruin','gcscrapheap'}) do
    local f=fixture(rubble)
    local house=f.house(30,'house_arab0',true)
    local plan={unitName='house_arab0',styles={1,3}}
    f.env.GG.HouseAsianUnitPlans[30]=plan
    f.S.DestroyUnit(30,false,false)
    local lifecycle=f.env.GG.CityReconstruction
    local plot=assert(lifecycle.plots[1])
    assert(f.S.ValidUnitID(30) and f.S.GetUnitIsDead(30),'missing Recoil pre-death window')
    assert(plot.data.routeID==17 and plot.plan==plan and plot.facing==2)
    f.tick(15)
    assert(f.S.ValidUnitID(30) and not plot.unitID,'rubble overlapped the original collapsing model')
    local status=lifecycle:GetStatus()
    assert(status.waitingForRemoval==1 and status.plots[1].rubbleSpawnAttempts==0)
    f.tick(30)
    assert(not f.S.ValidUnitID(30) and plot.unitID,'completed collapse did not leave a heap')
    local remains=assert(f.state.units[plot.unitID])
    assert(remains.def==f.names[rubble].id,'did not exercise requested real rubble variant')
    assert(remains.alwaysVisible and not remains.inLOS and next(remains.shown),
        'city remains disappeared outside LOS after always-visible house destruction')
    assert(remains.blocking and remains.solid and not remains.crushable)
    assert(f.env.GG.CityRubble[remains.id]==plot and plot.elapsed==0 and plot.paused)
    assert(plot.rubbleSpawnAttempts==1 and (plot.rubbleSpawnFailures or 0)==0)
    f.tick(30)
    if rubble=='gcscrapheap' then
        assert(remains.positions[remains.pieces.center][3]==0,'managed rubble self-sank during combat')
    end
end
print('PASS: real Killed coroutine/removal ordering, both real rubble scripts, visibility and blocking')

-- The last structural supports use production block-damage dispatch and
-- DestroyUnit. Visual disappearance must reach the same plot lifecycle.
local f=fixture('gcscrapheap')
local house=f.house(40,'house_arab0',true);house.hp=350
f.state.damageGadget:UnitDamaged(40,house.def,1,150,false,1,nil,nil)
f.tick(18)
assert(not house.dead,'one support column should survive the first partial collapse')
house.hp=200
f.state.damageGadget:UnitDamaged(40,house.def,1,150,false,1,nil,nil)
f.tick(18)
assert(house.dead and f.env.GG.CityReconstruction.nextID==1,
    'last visible support disappeared without queuing a destroyed plot')
f.tick(15)
assert(f.env.GG.CityReconstruction.plots[1].unitID and not f.S.ValidUnitID(40))
print('PASS: real structural damage to last-support destruction to managed scrapheap')

-- Real all-culture membership covers captured/off-culture/standalone houses and
-- all ten generated variants, independently of the current map spawn lottery.
f=fixture('gcscrapheap')
local count=0
for defID in pairs(f.env.getCivilianHouseTypeTable(f.env.UnitDefs)) do
    count=count+1
    local id=200+defID
    f.house(id,f.env.UnitDefs[defID].name,false);f.S.DestroyUnit(id,false,false)
end
f.tick(15)
assert(count==17 and size(f.env.GG.CityRubble)==count,'a real civilian-house category member was lost')
print('PASS: actual central sets reconstruct all 17 base/standalone/split house variants')

-- A same-def ID reused before the next tick must release the old lifetime
-- without attaching its queued reconstruction to the new, living house.
f=fixture('house_ruin')
f.house(50,'house_arab0',false);f.S.DestroyUnit(50,false,false);f.tick(1)
local original=f.env.GG.CityReconstruction.plots[1]
f.house(50,'house_arab0',false)
assert(not original.sourceUnitID)
f.tick(14)
assert(original.unitID and original.unitID~=50 and not f.state.units[50].dead)
local rubble=original.unitID
f.S.DestroyUnit(rubble,false,false);f.tick(15)
assert(not original.unitID and original.sourceUnitID==rubble,'dying ruin was immediately duplicated')
f.tick(100)
assert(original.unitID and original.unitID~=rubble and f.env.GG.CityReconstruction.nextID==1)
print('PASS: same-def ID reuse and managed ruin Killed preserve one plot')

-- A full unit cap loses neither the plot nor its source snapshot. Diagnostics
-- distinguish blocked placement, pending removal and peace-gated progression.
f=fixture('gcscrapheap');f.house(60,'house_arab0',false)
f.state.failRubble=true;f.S.DestroyUnit(60,false,false);f.tick(30)
local lifecycle=f.env.GG.CityReconstruction
local status=lifecycle:GetStatus();local info=status.plots[1]
assert(status.active==1 and info.rubbleSpawnAttempts==2 and info.rubbleSpawnFailures==2)
assert(not info.sourceWaiting and not info.unitID and info.pauseReason=='combat-or-quiet-period')
info.x=0;assert(lifecycle.plots[1].x==1500,'diagnostic snapshot aliases mutable plot state')
f.state.failRubble=false;f.tick(15)
assert(lifecycle.plots[1].unitID and lifecycle.plots[1].rubbleSpawnAttempts==3)
f.env.GG.GlobalGameState='anarchy';f.state.peaceful=true;f.tick(15)
assert(lifecycle:GetStatus().plots[1].pauseReason=='anarchy' and lifecycle.plots[1].elapsed==0)
print('PASS: spawn-failure retry, immutable diagnostic snapshots and global/local peace reasons')
