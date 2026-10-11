-- Run from the repository root with Lua 5.1+.
-- Exercises the real spawner, reconstruction state machine, rubble gadget and
-- rubble UnitDefs. Engine calls and the central set providers are fixtures.
local function loadEnv(path, env)
    if setfenv then
        local f = assert(loadfile(path)); setfenv(f, env); return f()
    end
    return assert(loadfile(path, 't', env))()
end
local function noop() end
local function size(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function fixture(culture)
    local names, defs = {}, {}
    for i, name in ipairs({'house_arab0','house_asian0','house_asian1',
        'house_asian2','house_asian3','house_asian4','house_western0',
        'house_ruin','gcscrapheap','truck_arab0','house_asian_split_1_3',
        'protagonsafehouse','future_rubble_variant'}) do
        defs[i]={id=i,name=name,customParams={},moveDef={id=1,name='truck'}}
        names[name]=defs[i]
    end
    local houses={[1]=1,[2]=2,[3]=3,[4]=4,[5]=5,[6]=6,[7]=7,[8]=8,[11]=11}
    local rubble={[8]=8,[9]=9,[13]=13}
    local cultureSets={arabic={[1]=1,[8]=8},western={[7]=7,[8]=8},
        asian={[2]=2,[3]=3,[4]=4,[5]=5,[6]=6,[8]=8,[11]=11},international=houses}
    local live, rules, writes, nextID, frame = {}, {}, {}, 100, 0
    local peaceful, failSite = false, false
    local config={game={culture=culture,states={normal='normal',anarchy='anarchy',
        postLaunch='postlaunch',gameOver='gameover'}},city={buildings={sizeX=256,sizeY=64,sizeZ=256},
        alleys={sizeX=25,sizeZ=25},rubble={decayFrames=60,constructionFrames=45}}}
    local env=setmetatable({GG={GlobalGameState='normal'},gadget={},UnitDefs=defs,UnitDefNames=names,
        Game={mapName='MOSAIC_LastDayOfDubai_V3',mapSizeX=8192,mapSizeZ=8192},
        gadgetHandler={IsSyncedCode=function() return true end}}, {__index=_G})
    env.getGameConfig=function() return config end
    env.getUnitDefNames=function() return names end
    env.getBuildingScrapHeapTypeTable=function() return rubble end
    env.getBuildingRuinTypeTable=function() return {[8]=8} end
    env.getCultureUnitModelTypes=function(c, kind)
        if kind=='truck' then return {[10]=10} end
        return assert(cultureSets[c])
    end
    env.getHouseTypeLimitations=function() return {[3]=10,[6]=3} end
    env.getHouseTypeIsInnerCityOnly=function() return {} end
    env.removeDictFromDict=function(t) return t end
    env.getLoadAbleTruckTypes=function() return {} end
    env.getRefugeeAbleTruckTypes=function() return {} end
    env.makeTable=function() return {} end
    env.isMapControlledBuildingPlacement=function() return true end
    env.toString=tostring
    env.setHouseStreetNameTooltip=noop
    env.randDict=function(t) local k=next(t); return k and t[k] end
    env.foreach=function(t, select, action)
        for _,v in ipairs(t) do local selected=select(v); if selected and action then action(selected) end end
    end
    env.doesUnitExistAlive=function(id) return live[id] and not live[id].dead end
    local function position(id)
        local u=live[id]; if u then return u.x,0,u.z end
    end
    local createUnit, destroyUnit
    env.Spring={CreateUnit=function(...) return createUnit(...) end,
        DestroyUnit=function(...) return destroyUnit(...) end,GetGaiaTeamID=function() return 0 end,GetGroundHeight=function() return 0 end,
        GetUnitPosition=position,GetUnitDefID=function(id) return live[id] and live[id].def end,
        GetUnitBuildFacing=function(id) return live[id] and live[id].facing end,
        ValidUnitID=function(id) return live[id]~=nil end,
        GetUnitIsDead=function(id) return not live[id] or live[id].dead end,
        GetAllUnits=function() local ids={};for id in pairs(live) do ids[#ids+1]=id end;table.sort(ids);return ids end,
        GetGameFrame=function() return frame end,SetUnitAlwaysVisible=noop,
        SetUnitTooltip=noop,SetGameRulesParam=noop,Echo=noop,
        SetUnitRulesParam=function(id,k,v) rules[id]=rules[id] or {}; rules[id][k]=v end,
        SetUnitBlocking=function(id,blocking,solid,projectile,ray,crushable,push,height)
            assert(live[id], 'blocking a missing unit')
            local u=live[id];u.blocking=blocking;u.solid=solid
            if crushable~=nil then u.crushable=crushable end
            writes[#writes+1]={id=id,blocking=blocking,solid=solid}
        end,
        GetUnitHealth=function(id)
            local u=live[id];if u then return u.hp,1000,0,0,u.progress end
        end,
        SetUnitHealth=function(id,v) local u=live[id];u.hp=v.health;u.progress=v.build end,
    }
    env.GG.CityAreaState={IsPeaceful=function() return peaceful end}
    env.VFS={Include=function(path)
        if path:find('city_reconstruction.lua',1,true) then return loadEnv(path,env) end
        if path:find('lib_house_asian_split.lua',1,true) then return {newState=function() return {} end} end
    end}
    env.include=function() return {} end
    loadEnv('luarules/gadgets/game_spawnCity.lua',env)
    local city=env.gadget
    env.spawnInitialHouses=noop;env.regenerateRoutesTable=noop
    local blockerEnv=setmetatable({gadget={},VFS=env.VFS,Spring=env.Spring,UnitDefs=defs,
        gadgetHandler=env.gadgetHandler,getBuildingScrapHeapTypeTable=env.getBuildingScrapHeapTypeTable}, {__index=_G})
    loadEnv('luarules/gadgets/game_building_rubble_blocking.lua',blockerEnv)
    local blocker=blockerEnv.gadget
    local function add(id,def,team)
        live[id]={def=def,team=team or 0,x=id*10,z=id*12,facing=2,hp=1000,progress=1,
            blocking=false,solid=false,yard='original entrances',crushable=true}
    end
    local function kill(id)
        local u=assert(live[id]);u.dead=true
        city:UnitDestroyed(id,u.def,u.team)
        live[id]=nil
    end
    createUnit=function(def,x,y,z,facing,team,beingBuilt)
        if beingBuilt and failSite then return nil end
        nextID=nextID+1;add(nextID,def,team)
        local u=live[nextID];u.x=x;u.z=z;u.facing=facing;u.progress=beingBuilt and 0 or 1
        city:UnitCreated(nextID,def);blocker:UnitCreated(nextID,def)
        return nextID
    end
    destroyUnit=kill
    city:Initialize()
    return {env=env,city=city,blocker=blocker,live=live,rules=rules,writes=writes,add=add,kill=kill,
        tick=function() frame=frame+15;city:GameFrame(frame) end,
        peace=function(v) peaceful=v end,fail=function(v) failSite=v end,rubble=rubble}
end

-- All live-house types, including standalone/arcology/split models, reconstruct
-- in every map culture. A captured/scenario-owned house is not excluded.
for _,culture in ipairs({'arabic','western','asian','international'}) do
    local f=fixture(culture)
    for _,def in ipairs({1,2,3,4,5,6,7,11}) do
        local id=def+20;f.add(id,def,def%2);f.kill(id)
    end
    assert(size(f.env.GG.CityReconstruction.plots)==8, culture..' lost a civilian house')
    f.tick()
    assert(size(f.env.GG.CityRubble)==8)
    for id,plot in pairs(f.env.GG.CityRubble) do
        assert(f.live[id].blocking and f.live[id].solid and not f.live[id].crushable)
        assert(plot.elapsed==0 and plot.paused, 'rubble decayed during combat')
    end
end
print('PASS: all-culture reconstruction, captured houses and immediate blocking rubble')

-- Every member of the injected shared category receives the policy, including
-- a future member with a name the gadget has never seen. No house is touched.
local f=fixture('western')
for def in pairs(f.rubble) do f.add(def,def);f.blocker:UnitCreated(def,def) end
f.add(20,1);f.live[20].blocking=true;f.live[20].solid=true
local n=#f.writes
f.blocker:UnitCreated(20,1);f.blocker:UnitFinished(20,1)
assert(#f.writes==n and f.live[20].yard=='original entrances')
for def in pairs(f.rubble) do assert(f.live[def].blocking and not f.live[def].crushable) end
for def in pairs(f.rubble) do f.live[def].blocking=false end
f.blocker:Initialize()
for def in pairs(f.rubble) do assert(f.live[def].blocking) end
assert(f.blocker.UnitDamaged==nil, 'damage must not edit footprints')
print('PASS: category-wide creation/reload blocking; houses are untouched')

-- Initial map registration must never undo blocking of preplaced ruins. Managed
-- rubble is not re-registered as a finished civilian destination.
f.env.setCityBuildingBlocking(8);assert(f.live[8].blocking)
f.env.GG.CityRubble[8]={};f.env.registerManuallyPlacedHouses(0)
assert(not f.env.GG.BuildingTable[8], 'managed rubble registered as a live house')
assert(f.env.GG.BuildingTable[20], 'off-culture live house missed by map registration')
print('PASS: map-placed ruins stay solid; managed rubble excluded from city routes')

-- Repeated rubble destruction stays on one plot. Unmanaged decorative rubble
-- and unrelated units do not start infinite reconstruction chains.
f=fixture('western');f.add(30,1);f.kill(30);f.tick()
local plot=assert(f.env.GG.CityReconstruction.plots[1]);local rubbleID=plot.unitID
f.kill(rubbleID);f.tick()
assert(size(f.env.GG.CityReconstruction.plots)==1 and plot.unitID~=rubbleID)
for _,def in ipairs({8,9,12,13}) do f.add(40+def,def);f.kill(40+def) end
assert(size(f.env.GG.CityReconstruction.plots)==1)
print('PASS: no duplicate plots or rubble-to-rubble reconstruction loops')

-- When the solid heap expires, failed site placement restores its footprint.
-- Successful placement removes the heap within the same update.
rubbleID=plot.unitID;f.peace(true);f.fail(true)
for _=1,4 do f.tick() end
assert(plot.stage=='rubble' and plot.unitID==rubbleID)
assert(f.live[rubbleID].blocking and f.live[rubbleID].solid)
f.fail(false);f.tick()
assert(plot.stage=='construction' and not f.live[rubbleID])
local site=plot.unitID
assert(not f.city:AllowUnitBuildStep(nil,nil,site))
f.env.GG.GlobalGameState='anarchy';local elapsed=plot.elapsed;f.tick()
assert(plot.elapsed==elapsed and plot.paused)
f.env.GG.GlobalGameState='normal'
for _=1,3 do f.tick() end
assert(size(f.env.GG.CityReconstruction.plots)==0 and f.live[site].def==1)
assert(f.env.GG.BuildingTable[site] and not f.env.GG.CityConstructionSites[site])
print('PASS: blocked-site retry, atomic rubble handoff and peaceful completion')

-- Both current category members have closed, correctly sized footprint cells.
-- An open-yard toggle cannot turn the 'o' cells into new vehicle entrances.
local base={}
function base:New(t) return setmetatable(t or {},{__index=self}) end
local defEnv=setmetatable({Building=base,lowerkeys=function(t)
    local o={};for k,v in pairs(t) do o[k:lower()]=v end;return o
end},{__index=_G})
for _,file in ipairs({'gCScrapHeap','house_ruin'}) do
    local defs=loadEnv('units/neutral/'..file..'.lua',defEnv)
    local _,def=next(defs)
    local yard=def.YardMap:gsub('%s','')
    assert(def.blocking==true and #yard==def.FootprintX*def.FootprintZ)
    assert(not yard:find('[^o]'),file..' has a vehicle opening')
end
print('PASS: closed rubble yardmaps, exact footprint lengths')
print('civilian reconstruction/blocking tests passed')
