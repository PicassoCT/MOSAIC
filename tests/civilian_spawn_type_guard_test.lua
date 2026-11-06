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
        'hivemind','warheadfactory','truckpayload','truckpayloadparade'}) do add(name) end
    local venueDef = add('shopping_market', {civilian_venue='shopping'})
    local live = {
        [100]={def=names.house_arab0.id,x=200,z=220,team=0},
        [101]={def=names.house_western0.id,x=700,z=720,team=0},
        [102]={def=venueDef,x=210,z=220,team=0},
        [103]={def=names.house_ruin.id,x=1200,z=720,team=0},
        [104]={def=names.vehiclecorpse.id,x=1200,z=900,team=0},
    }
    local created, visible, neutral, nextID, frame, pools = {}, {}, {}, 1000, 1, {}
    local env = setmetatable({arg=false, gadget={}, UnitDefs=defs, UnitDefNames=names,
        Game={mapName='civilian_spawn_guard_test',mapSizeX=8192,mapSizeZ=8192},
        GG={InstanceCulture=culture,AllCultures={international='international'},
            BuildingTable={[100]={x=200,z=220},[101]={x=700,z=720}}},
        CMD={MOVE=10,STOP=0,GUARD=25}, SendToUnsynced=noop,
        gadgetHandler={IsSyncedCode=function() return true end}}, {__index=_G})
    env._G=env
    env._setFrame=function(value) frame=value end
    env._orders={}
    env._destroyed={}
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
        GetUnitRadius=function() return 90 end,
        TestMoveOrder=function() return true end,
        GetUnitsInCylinder=function(x,z,radius,team)
            local ids={}
            for id,u in pairs(live) do
                if (not team or u.team==team) and (u.x-x)^2+(u.z-z)^2<=radius^2 then ids[#ids+1]=id end
            end
            table.sort(ids)
            return ids
        end,
        SetUnitPosition=function(id,x,y,z)
            live[id].x,live[id].z=x,z
        end,
        GetUnitTransporter=function(id) return live[id] and live[id].transporter end,
        GetUnitPieceMap=function() return {attachPoint=4} end,
        UnitAttach=function(carrier,payload,piece)
            assert(live[carrier] and live[payload] and piece==4)
            live[payload].transporter=carrier
        end,
        GetUnitHealth=function() return 100,100 end,
        GiveOrderToUnit=function(id,command,params,options)
            env._orders[#env._orders+1]={id,command,params,options}
        end,
        SetUnitAlwaysVisible=function(id) visible[id]=true end,
        SetUnitNeutral=function(id,value) neutral[id]=value end,
        SetUnitNoSelect=noop, SetGameRulesParam=noop,
        DestroyUnit=function(id) env._destroyed[id]=true; live[id]=nil end,
        RequestPath=function() return {} end,
        GetUnitRulesParam=function(id,key)
            if id==102 and key=='city_street_name' then return 'Market Street' end
        end,
        UnitScript={GetScriptEnv=function() end},
        CreateUnit=function(defID,x,y,z,dir,team)
            if type(defID)=='string' then defID=assert(names[defID]).id end
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
    return env, names, mobileNames, live, created, visible, pools, neutral
end

local checked=0
for _, culture in ipairs({'arabic','western','asian','international'}) do
    local env,names,mobileNames,live,created,visible,pools,neutral=fixture(culture)
    assert(not neutral[100] and not neutral[101], 'civilian houses were made neutral')
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

    -- Float carriers are explicitly admitted in every culture, while ordinary
    -- traffic and its service-payload quota keep their original membership.
    local traffic=assert(env.GG.CivilianTraffic)
    local beforePool={}
    for defID,value in pairs(pools.truck) do beforePool[defID]=value end
    local quota=env.GG.CivilianServicePayloadSelection.eligibleSpawns
    for _,name in ipairs({'truck_arab6','truck_arab7','truck_arab8'}) do
        local defID=names[name].id
        local carrier=assert(traffic.SpawnParade(defID,400,420,100,101))
        assert(env.GG.CivilianTable[carrier].defID==defID)
        local payload=assert(traffic.Load(carrier,'truckpayloadparade'))
        assert(live[payload].def==names.truckpayloadparade.id)
        assert(live[payload].transporter==carrier, 'float not attached to its carrier')
        local route=assert(env.buildRouteSquareFromTwoUnits(100,101,defID))
        assert((route[1].x-200)^2+(route[1].z-220)^2>90^2,
            'cross-culture float carrier starts inside a building')
        env.gadget:UnitDestroyed(carrier,defID,0)
        live[carrier]=nil
        assert(not env.GG.CivilianTable[carrier] and not env.GG.UnitArrivedAtTarget[carrier],
            'dead cross-culture parade carrier leaked a population or arrival record')
    end
    assert(env.GG.CivilianServicePayloadSelection.eligibleSpawns==quota,
        'explicit parade loads consumed the service-payload quota')
    for id,value in pairs(pools.truck) do assert(beforePool[id]==value) end
    for id,value in pairs(beforePool) do assert(pools.truck[id]==value) end
    assert(traffic.SpawnParade(names.house_ruin.id,400,420,100,101)==nil)
    assert(traffic.SpawnParade(names.truck_western0.id,400,420,100,101)==nil)

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
    local car=created[count+2]
    env.gadget:UnitCreated(car.id,car.defID,0)
    assert(not neutral[car.id], 'civilian traffic was made neutral')
    assert((car.x-200)^2+(car.z-220)^2>90^2,
        'traffic spawned inside its source building')
    local route=assert(env.buildRouteSquareFromTwoUnits(100,101,truck))
    assert((route[1].x-200)^2+(route[1].z-220)^2>90^2,
        'traffic route starts inside its source building')
    local nearDestination=false
    for _,point in ipairs(route) do
        local fromSource=(point.x-200)^2+(point.z-220)^2
        local fromDestination=(point.x-700)^2+(point.z-720)^2
        assert(fromSource>90^2 and fromDestination>90^2,
            'traffic route enters a building')
        if fromDestination<=130^2+1 then nearDestination=true end
    end
    assert(nearDestination,'traffic route no longer visits its destination')
    live[105]={def=names.protagonsafehouse.id,x=200,z=220,team=1}
    live[106]={def=truck,x=200,z=220,team=1}
    env.gadget:UnitFromFactory(106,truck,1,105)
    assert((live[106].x-200)^2+(live[106].z-220)^2>90^2,
        'safehouse released a truck inside its civilian building')
    live[107]={def=names.house_arab0.id,x=car.x,z=car.z,team=0}
    local rerouted=assert(env.buildRouteSquareFromTwoUnits(100,101,truck))
    assert((rerouted[1].x-car.x)^2+(rerouted[1].z-car.z)^2>90^2,
        'traffic curb was inside a neighbouring civilian building')
end

-- EventStream runs at gadget layer 0, before traffic (1) and parade (2).
-- ID multiples of 100 must never schedule their first trip in the past.
for _,culture in ipairs({'arabic','western','asian','international'}) do
    local env,names,_,live=fixture(culture)
    env.regenerateRoutesTable()
    local cityGadget=env.gadget
    env.gadget={}
    loadEnv('luarules/gadgets/game_eventstream.lua',env)
    local eventGadget=env.gadget
    env.gadget=cityGadget
    env._setFrame(1)
    eventGadget:GameFrame(1)
    live[50000]={def=names.truck_arab6.id,x=400,z=420,team=0}
    env.GG.CivilianTable[50000]={defID=names.truck_arab6.id,startID=100,goalID=101}
    assert(env.GG.CivilianTraffic.BeginTravel(50000))
    local event=assert(env.GG.EventStream[0])
    assert(event.startFrame==2, 'new trip was scheduled on the already dispatched frame')
    env.GG.CityParade={OwnsUnit=function(_,id) return id==50000 end}
    env._setFrame(2); eventGadget:GameFrame(2)
    assert(env.GG.EventStream[0] and #env._orders==0,
        'ordinary traffic interfered with parade ownership')
    live[50000].team=1
    env._setFrame(17); eventGadget:GameFrame(17)
    assert(env.GG.EventStream[0]==nil and env.GG.CivilianTable[50000]==nil,
        'captured parade traffic retained its civilian event')
    assert(#env._orders==0 and not env._destroyed[50000] and live[50000],
        'captured carrier received a city command or was destroyed')
end
print('PASS civilian spawn guard: rejected static units and contaminated pools; ' ..
    checked .. ' culture mobile variants, cross-culture parade loads, quotas, future events and capture preserved')
