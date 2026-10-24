-- Lua 5.1+: run from the repository root. Load the actual gadget, cultural
-- property sets and civilian life module; only engine services are fixtures.
local function loadEnv(path, env)
    if setfenv then
        local chunk = assert(loadfile(path)); setfenv(chunk, env); return chunk()
    end
    return assert(loadfile(path, 't', env))()
end
local function noop() end

local function fixture(culture)
    local defs, names, mobileNames = {}, {}, {}
    local function add(name, params)
        local id = #defs + 1
        defs[id] = {id=id, name=name, customParams=params or {}, buildOptions={},
            moveDef={id=1, name='civilian'}}
        names[name] = defs[id]
        return id
    end
    local function family(name, last, mobile)
        for i=0,last do
            local unitName = name .. i
            add(unitName)
            if mobile then mobileNames[unitName] = true end
        end
    end
    family('house_arab',0); family('house_western',0); family('house_asian',4)
    family('truck_arab',9,true); family('truck_western',4,true)
    family('civilian_arab',5,true); family('civilian_western',4,true)
    add('house_asian_split_1_3', {house_asian_base='house_asian0'})
    for _, name in ipairs({'house_ruin','gcscrapheap','vehiclecorpse','tankcorpse',
        'closecombatarena','civilianagent','protagonsafehouse','antagonsafehouse',
        'nimrod','propagandaserver','protagonassembly','antagonassembly','launcher',
        'hivemind','warheadfactory','truckpayload'}) do add(name) end
    local venueDef = add('shopping_market', {civilian_venue='shopping'})
    local live = {
        [100]={def=names.house_arab0.id,x=200,z=220,team=0},
        [101]={def=names.house_western0.id,x=700,z=720,team=0},
        [102]={def=venueDef,x=210,z=220,team=0},
        [103]={def=names.house_ruin.id,x=1200,z=720,team=0},
        [104]={def=names.vehiclecorpse.id,x=1200,z=900,team=0},
    }
    local created, visible, nextID, frame, pools = {}, {}, 1000, 1, {}
    local env = setmetatable({arg=false, gadget={}, UnitDefs=defs, UnitDefNames=names,
        Game={mapName='civilian_spawn_guard_test',mapSizeX=8192,mapSizeZ=8192},
        GG={InstanceCulture=culture,AllCultures={international='international'},
            BuildingTable={[100]={x=200,z=220},[101]={x=700,z=720}}},
        CMD={MOVE=10,STOP=0,GUARD=25}, SendToUnsynced=noop,
        gadgetHandler={IsSyncedCode=function() return true end}}, {__index=_G})
    env._G=env
    local function position(id)
        assert(type(id)=='number', 'engine requires a numeric unit ID')
        local u=live[id]; if u then return u.x,0,u.z end
    end
    env.Spring={
        GetGaiaTeamID=function() return 0 end,
        GetModOptions=function() return {} end, Echo=noop,
        GetGameFrame=function() return frame end,
        GetUnitPosition=position,
        GetUnitDefID=function(id) return live[id] and live[id].def end,
        GetUnitTeam=function(id) return live[id] and live[id].team end,
        ValidUnitID=function(id) return live[id]~=nil end,
        GetUnitIsDead=function(id) return live[id]==nil end,
        GetAllUnits=function()
            local ids={}; for id in pairs(live) do ids[#ids+1]=id end; return ids
        end,
        GetGroundHeight=function() return 12 end,
        GetUnitTransporter=function() end,
        SetUnitAlwaysVisible=function(id) visible[id]=true end,
        SetUnitNoSelect=noop, SetGameRulesParam=noop, DestroyUnit=noop,
        RequestPath=function() return {} end,
        GetUnitRulesParam=function(id,key)
            if id==102 and key=='city_street_name' then return 'Market Street' end
        end,
        UnitScript={GetScriptEnv=function() end},
        CreateUnit=function(defID,x,y,z,dir,team)
            nextID=nextID+1
            live[nextID]={def=defID,x=x,z=z,team=team}
            created[#created+1]={id=nextID,defID=defID,x=x,y=y,z=z,dir=dir,team=team}
            return nextID
        end,
    }
    env.VFS={Include=function(path)
        local result=loadEnv(path,env)
        if path=='scripts/lib_mosaic.lua' then
            local getMobileTypes=env.getMobileCivilianDefIDTypeTable
            env.getMobileCivilianDefIDTypeTable=function(unitDefs)
                local types=getMobileTypes(unitDefs)
                if not pools.mobile then pools.mobile=types end
                return types
            end
            local getTypes=env.getCultureUnitModelTypes
            env.getCultureUnitModelTypes=function(c,kind,unitDefs)
                local types=getTypes(c,kind,unitDefs)
                pools[kind]=types
                return types
            end
            local getConfig=env.getGameConfig
            env.getGameConfig=function()
                local config=getConfig()
                config.city.population.persons=1
                config.city.population.vehicles=1
                config.performance.civilianBatchSize=1
                return config
            end
        end
        return result
    end}
    loadEnv((arg and arg[1]) or 'luarules/gadgets/game_civilians.lua',env)
    env.gadget:Initialize()
    return env, names, mobileNames, live, created, visible, pools
end

local checked=0
for _, culture in ipairs({'arabic','western','asian','international'}) do
    local env,names,mobileNames,live,created,visible,pools=fixture(culture)
    assert(next(env.GG.CivilianTable)==nil, 'map structures registered as population')
    assert(next(env.GG.CivilianLife.people)==nil, 'map structures registered as people')
    local rejected={'house_ruin','gcscrapheap','vehiclecorpse','tankcorpse',
        'house_arab0','house_western0','house_asian0','house_asian_split_1_3',
        'protagonsafehouse','shopping_market'}
    for _, name in ipairs(rejected) do
        local count=#created
        assert(env.spawnUnit(names[name].id,200,220)==nil, name .. ' accepted by raw spawn')
        assert(env.spawnAMobileCivilianUnit(names[name].id,200,220,100,101)==nil,
            name .. ' accepted by mobile spawn')
        assert(#created==count, name .. ' reached Spring.CreateUnit')
    end
    assert(next(env.GG.CivilianTable)==nil and next(env.GG.UnitArrivedAtTarget)==nil,
        'rejected structures added population/arrival state')

    -- Every permitted culture variant, including bus-bearing truck variants,
    -- still emerges at its home node and receives its original route identity.
    local allowed=env.getMobileCivilianDefIDTypeTable(env.UnitDefs)
    local onePedestrian
    for defID in pairs(allowed) do
        assert(mobileNames[env.UnitDefs[defID].name], 'unexpected test mobile definition')
        local count=#created
        local id=assert(env.spawnAMobileCivilianUnit(defID,200,220,100,101))
        local record=created[#created]
        assert(#created==count+1 and record.id==id and record.defID==defID)
        assert(record.x==200 and record.y==12 and record.z==220 and record.team==0,
            'mobile no longer spawns at its home coordinates')
        assert(visible[id] and env.GG.UnitArrivedAtTarget[id])
        local person=assert(env.GG.CivilianTable[id])
        assert(person.defID==defID and person.startID==100 and person.goalID==101)
        if pools.civilian[defID] then
            assert(env.GG.CivilianLife.people[id].home==100)
            onePedestrian=id
        end
        checked=checked+1
    end
    -- The initialization callback must continue to see non-mobile venues.
    env.GG.CivilianLife:Remember(assert(onePedestrian),'shopping',210,220)
    local memories=env.GG.CivilianLife.people[onePedestrian].memories
    assert(memories[#memories].place=='on Market Street', 'initial venue registration was lost')

    env.GG.CivilianTable={}; env.GG.UnitArrivedAtTarget={}
    env.regenerateRoutesTable()
    -- Inject the historical failure into both local pools after their shared
    -- classification was built, then execute the real population batch paths.
    pools.civilian[names.house_ruin.id]=names.house_ruin.id
    pools.truck[names.house_ruin.id]=names.house_ruin.id
    -- A second defence is necessary if the shared classification helper itself
    -- regresses, as it did historically: positive mobile membership can lie.
    pools.mobile[names.house_ruin.id]=true
    pools.mobile[names.gcscrapheap.id]=true
    local intactHouse
    for defID in pairs(pools.house) do
        if defID~=names.house_ruin.id then intactHouse=defID; break end
    end
    pools.mobile[assert(intactHouse)]=true
    local beforeInvalid=#created
    assert(env.spawnAMobileCivilianUnit(intactHouse,200,220,100,101)==nil)
    assert(env.spawnAMobileCivilianUnit(names.gcscrapheap.id,200,220,100,101)==nil)
    assert(#created==beforeInvalid, 'independent house/scrapheap veto was bypassed')
    env.randT=function(t) assert(t[100]); return 100 end
    env.randDict=function() return names.house_ruin.id end
    env.getDayTime=function() return 0,0,0,0 end
    local count=#created
    env.checkReSpawnPopulation()
    env.checkReSpawnTraffic()
    assert(#created==count, 'contaminated batch spawned a ruin over a home')
    assert(next(env.GG.CivilianTable)==nil and next(env.GG.UnitArrivedAtTarget)==nil)
    -- Removing the bad selection still lets these same batch entrypoints work.
    local walker=next(pools.civilian)
    if walker==names.house_ruin.id then walker=next(pools.civilian,walker) end
    local truck=next(pools.truck)
    if truck==names.house_ruin.id then truck=next(pools.truck,truck) end
    env.randDict=function(t)
        if t==pools.civilian then return walker end
        if t==pools.truck then return truck end
        error('unexpected random selection')
    end
    -- Avoid payload creation: this check is about one selected population unit.
    env.loadTruck=noop
    env.checkReSpawnPopulation()
    env.checkReSpawnTraffic()
    assert(#created==count+2 and created[count+1].defID==walker and created[count+2].defID==truck,
        'valid mobile selection no longer reaches the real batch spawn')
end
print('PASS civilian spawn guard: rejected static units and contaminated pools; ' ..
    checked .. ' culture mobile variants, home spawns, routes and initial venues preserved')
