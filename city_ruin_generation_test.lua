-- Lua 5.1+ (or texlua), from the repository root. Exercise the real geographic
-- selector and city gadget with engine calls mocked; never duplicate the policy.
local function loadEnv(path, env)
    if setfenv then
        local f=assert(loadfile(path)); setfenv(f,env); return f()
    end
    return assert(loadfile(path,'t',env))()
end
local function noop() end
local function copy(t) local out={}; for k,v in pairs(t) do out[k]=v end; return out end
local function near(a,b,label) assert(math.abs(a-b)<1e-12,label or 'number differs') end

local pure=setmetatable({MOSAIC_CONFIG_ONLY=true,math=copy(math)},{__index=_G})
pure.math.random=function() error('ruin policy consumed global RNG') end
pure.VFS={Include=function(path) return loadEnv(path,pure) end}
local properties=loadEnv('scripts/lib_mosaic.lua',pure)
local policy=loadEnv('scripts/lib_city_ruins.lua',pure)
local config=properties.getCityRuinConfig()
local geo=properties.getCityGeography(
    {mapName='MOSAIC_LastDayOfDhubai_V3',mapSizeX=8192,mapSizeZ=8192},
    {country='United Arab Emirates',latitude=0})
assert(geo.latitude==0 and geo.source=='map-metadata', 'explicit equatorial latitude lost')
near(policy.Chance(0,config),config.equatorChance,'equatorial endpoint')
near(policy.Chance(90,config),config.polewardChance,'polar endpoint')
local previous=1
for _,latitude in ipairs({0,30,60,90}) do
    local chance=policy.Chance(latitude,config)
    assert(chance>=0 and chance<=previous, 'ruin fraction is not monotonic poleward')
    near(chance,policy.Chance(-latitude,config),'hemisphere symmetry')
    previous=chance
end
assert(policy.Chance(0,config)>policy.Chance(30,config)
    and policy.Chance(30,config)>policy.Chance(60,config), 'equatorial increase missing')
near(policy.Chance(nil,config),policy.Chance(config.unknownLatitude,config))
near(policy.Chance(91,config),policy.Chance(config.unknownLatitude,config))
assert(not policy.ShouldRuin(geo.hash,0/0,5,0,config))
assert(not policy.ShouldRuin(geo.hash,5,math.huge,0,config))

-- Identical coordinates must form nested sets toward the equator, independent
-- of call order. A broad lattice catches hash stripes and strongly biased rolls.
local samples,total,counts={},80*80,{[0]=0,[30]=0,[60]=0,[90]=0}
local differentMap=0
for ix=1,80 do for iz=1,80 do
    local x,z=ix*256+0.125,iz*256+0.25
    local roll=policy.PlotRoll(geo.hash,x,z)
    assert(roll>=0 and roll<1)
    samples[#samples+1]={x=x,z=z,roll=roll}
    local previousRuin=true
    for _,latitude in ipairs({0,30,60,90}) do
        local ruined=policy.ShouldRuin(geo.hash,x,z,latitude,config)
        assert(not ruined or previousRuin, 'poleward ruin is absent from equatorial superset')
        assert(ruined==policy.ShouldRuin(geo.hash,x,z,-latitude,config))
        if ruined then counts[latitude]=counts[latitude]+1 end
        previousRuin=ruined
    end
    if policy.ShouldRuin(geo.hash,x,z,30,config)
        ~=policy.ShouldRuin(geo.hash+1,x,z,30,config) then differentMap=differentMap+1 end
end end
for i=#samples,1,-1 do
    local sample=samples[i]
    assert(policy.PlotRoll(geo.hash,sample.x,sample.z)==sample.roll, 'roll depends on call order')
end
assert(differentMap>total*0.1, 'map identity does not vary ruin locations')
for _,latitude in ipairs({0,30,60,90}) do
    assert(math.abs(counts[latitude]/total-policy.Chance(latitude,config))<0.035,
        'sample ruin fraction disagrees with geographic target at '..latitude)
end

local function fixture(chance)
    local defs,names={},{}
    local function add(name,params)
        local id=#defs+1
        defs[id]={id=id,name=name,customParams=params or {},buildOptions={},moveDef={id=1,name='truck'}}
        names[name]=defs[id]
    end
    local function family(name,last) for i=0,last do add(name..i) end end
    family('house_arab',0); family('house_western',0); family('house_asian',4)
    family('truck_arab',9); family('truck_western',4)
    family('civilian_arab',5); family('civilian_western',4)
    for a=1,4 do for b=a,4 do
        add('house_asian_split_'..a..'_'..b,{house_asian_base='house_asian0'})
    end end
    for _,name in ipairs({'house_ruin','gcscrapheap','protagonsafehouse','antagonsafehouse',
        'nimrod','propagandaserver','protagonassembly','antagonassembly','launcher',
        'hivemind','warheadfactory'}) do add(name) end
    local state={units={},created={},attempts={},rules={},nextID=100,failNext=false,
        jitter={},offset={xRandOffset=0,zRandOffset=0},metadata={latitude=0,country='United Arab Emirates'}}
    local env=setmetatable({arg=false,gadget={},UnitDefs=defs,UnitDefNames=names,
        GG={InstanceCulture='western',AllCultures={international='international'}},
        Game={mapName='MOSAIC_LastDayOfDhubai_V3',mapSizeX=8192,mapSizeZ=8192},
        gadgetHandler={IsSyncedCode=function() return true end},math=copy(math),
        include=function() return {} end}, {__index=_G})
    env._G=env
    env.math.random=function(low,high)
        assert(low and high,'unexpected unbounded fixture random call')
        if #state.jitter>0 then
            local result=table.remove(state.jitter,1)
            assert(result>=low and result<=high,'jitter outside requested interval')
            return result
        end
        return math.floor((low+high)/2)
    end
    env.Spring={
        GetGaiaTeamID=function() return 0 end,GetModOptions=function() return {} end,
        GetGroundHeight=function() return 10 end,GetGameFrame=function() return 1 end,
        Echo=noop,SetUnitAlwaysVisible=noop,
        SetUnitBlocking=function(id,blocking) state.units[id].blocking=blocking end,
        SetGameRulesParam=function(key,value) state.rules[key]=value end,
        GetUnitDefID=function(id) return state.units[id] and state.units[id].def end,
        GetUnitPosition=function(id)
            local u=state.units[id]; if u then return u.x,10,u.z end
        end,
        ValidUnitID=function(id) return state.units[id]~=nil end,
        GetUnitIsDead=function(id) return state.units[id]==nil end,
        GetAllUnits=function()
            local ids={};for id in pairs(state.units) do ids[#ids+1]=id end;return ids
        end,
        DestroyUnit=function() error('initial ruin selection destroyed a unit') end,
        CreateUnit=function(def,x,y,z,facing,team,beingBuilt)
            assert(not beingBuilt and not env.GG.CityReconstructionSpawning,
                'initial ruin selection entered construction')
            state.attempts[#state.attempts+1]={def=def,x=x,z=z}
            if state.failNext then state.failNext=false;return nil end
            state.nextID=state.nextID+1
            local id=state.nextID
            state.units[id]={def=def,x=x,z=z,facing=facing,team=team}
            state.created[#state.created+1]=id
            env.gadget:UnitCreated(id,def)
            return id
        end,
    }
    env.VFS={FileExists=function(path) return path=='mosaic/location.lua' end,
        Include=function(path)
            if path=='mosaic/location.lua' then return state.metadata end
            local result=loadEnv(path,env)
            if path=='scripts/lib_mosaic.lua' then
                local getConfig=env.getGameConfig
                env.getGameConfig=function()
                    local cfg=getConfig()
                    cfg.city.ruins.equatorChance=chance
                    cfg.city.ruins.polewardChance=chance
                    state.config=cfg
                    return cfg
                end
                env.isMapControlledBuildingPlacement=function() return false end
                env.getCultureDependantRandomOffsets=function() return state.offset end
            elseif path=='scripts/lib_staticstring.lua' then
                env.setHouseStreetNameTooltip=noop
            end
            return result
        end}
    loadEnv('luarules/gadgets/game_spawnCity.lua',env)
    env.gadget:Initialize()
    for _,method in ipairs({'Add','LostUnit','Update'}) do
        env.GG.CityReconstruction[method]=function()
            error('initial ruin selection called reconstruction '..method)
        end
    end
    assert(state.rules.mosaic_city_latitude==0,'gadget lost explicit latitude zero')
    near(state.rules.mosaic_city_ruin_chance,chance,'gadget published different ruin chance')
    return env,state,names
end

local city,state,names=fixture(1)
local intact,ruin,arc=names.house_western0.id,names.house_ruin.id,names.house_asian1.id
local function createdAs(id,def)
    assert(id and state.units[id].def==def,'wrong initial plot type')
    return id
end
-- Explicit old ruins retain their plot even before the protected arcologies.
createdAs(city.spawnBuilding(ruin,500,500,true),ruin)
local attempts=#state.attempts
assert(city.spawnBuilding(ruin,500,500,true)==nil)
assert(#state.attempts==attempts,'duplicate plot reached CreateUnit')
local filler=createdAs(city.spawnBuilding(intact,1000,500,true,true),intact)
assert(not city.GG.BuildingTable[filler].arcology,'filler consumed an arcology reservation')
state.failNext=true
assert(city.spawnBuilding(intact,1500,500,true)==nil)
for i=1,3 do
    local id=createdAs(city.spawnBuilding(intact,1000+i*500,500,true),arc)
    assert(city.GG.BuildingTable[id].arcology,'protected plot lost reserved arcology flag')
end
local before=#state.created
local ruined=createdAs(city.spawnBuilding(intact,3000,500,true),ruin)
assert(#state.created==before+1 and not city.GG.BuildingTable[ruined].arcology,
    'eligible plot spawned both a ruin and an intact building')
assert(state.units[ruined].blocking,'ruin did not receive rubble vehicle blocking')
assert(city.spawnBuilding(intact,3000,500,true,true)==nil,'duplicate filler entered full plot')
attempts=#state.attempts
assert(city.spawnBuilding(intact,3128,628,true,true)==nil,'diagonal filler intersects ruin footprint')
assert(#state.attempts==attempts,'intersecting filler reached CreateUnit')
local clearance=state.config.city.ruins.ruinFootprintSize+state.config.city.ruins.plotClearance
createdAs(city.spawnBuilding(intact,3000+clearance,500,true,true),intact)

-- Execute the real filler helper. Explicit ruins never replicate; intact
-- fillers are also barred from the neighbouring ruin's full footprint.
local dimX=state.config.city.buildings.sizeX+state.config.city.alleys.sizeX
local dimZ=state.config.city.buildings.sizeZ+state.config.city.alleys.sizeZ
local cursor={x=20,z=20}
createdAs(city.spawnBuilding(ruin,cursor.x*dimX,cursor.z*dimZ,true),ruin)
before=#state.created
city.fillGapsWithInnerCityBlocks(cursor,ruin)
city.fillGapsWithInnerCityBlocks(cursor,intact)
assert(#state.created==before,'gap helper replicated or intersected a ruin')
before=#state.created
city.fillGapsWithInnerCityBlocks({x=25,z=25},intact)
assert(#state.created>before,'ordinary intact gap fillers disappeared')
for i=before+1,#state.created do
    assert(state.units[state.created[i]].def==intact,'gap filler converted to a full-size ruin')
end

-- Requested coordinates are safe, but the actual random displacement is not.
createdAs(city.spawnBuilding(ruin,7200,1000,true),ruin)
assert(not city.hasAlreadyBuilding(7350,1000,35,intact))
state.offset={xRandOffset=30,zRandOffset=0};state.jitter={-30,0}
attempts=#state.attempts
assert(city.spawnBuilding(intact,7350,1000,false,true)==nil,'jitter moved filler inside ruin')
assert(#state.attempts==attempts,'jitter collision was checked after CreateUnit')
-- Already placed geometry must likewise retain actual, not nominal, positions.
state.offset={xRandOffset=90,zRandOffset=0};state.jitter={90,0}
local shifted=createdAs(city.spawnBuilding(ruin,4000,3000,false),ruin)
assert(state.units[shifted].x==4090 and city.GG.BuildingTable[shifted].x==4000)
attempts=#state.attempts
assert(city.spawnBuilding(intact,4220,3000,true,true)==nil,'stored plot forgot ruin displacement')
assert(#state.attempts==attempts)
assert(next(city.GG.CityReconstruction.plots)==nil and next(city.GG.CityRubble)==nil,
    'initial ruin selection queued reconstruction')

local safe,safeState,safeNames=fixture(0)
for i=1,3 do
    local id=assert(safe.spawnBuilding(safeNames.house_western0.id,i*500,1500,true))
    assert(safeState.units[id].def==safeNames.house_asian1.id)
end
local normal=assert(safe.spawnBuilding(safeNames.house_western0.id,2500,1500,true))
assert(safeState.units[normal].def==safeNames.house_western0.id,'zero chance changed intact plot')
local authored=assert(safe.spawnBuilding(safeNames.house_ruin.id,3000,1500,true))
assert(safeState.units[authored].def==safeNames.house_ruin.id,'zero chance removed authored ruins')

-- Real foreach runs callbacks in separate passes. Manual registration must
-- cache each unit's own definition, not the last filter callback's definition.
for _,trailingName in ipairs({'house_western0','launcher'}) do
    local manual,manualState,manualNames=fixture(0)
    manualState.units[501]={def=manualNames.house_ruin.id,x=5000,z=5000}
    manualState.units[502]={def=manualNames[trailingName].id,x=5500,z=5000}
    manual.Spring.GetAllUnits=function() return {501,502} end
    local count=manual.registerManuallyPlacedHouses(1)
    assert(count==(trailingName=='house_western0' and 2 or 1))
    assert(manual.GG.BuildingTable[501],'manual ruin was not registered')
    if trailingName=='launcher' then assert(not manual.GG.BuildingTable[502]) end
    local nominal=manualNames.house_western0.id
    assert(manual.hasAlreadyBuilding(5128,5128,35,nominal),
        'manual ruin geometry inherited the trailing '..trailingName..' type')
    assert(not manual.hasAlreadyBuilding(5200,5200,35,nominal),'clear manual plot incorrectly blocked')
    local beforeAttempts=#manualState.attempts
    assert(manual.spawnBuilding(nominal,5128,5128,true,true)==nil)
    assert(#manualState.attempts==beforeAttempts,'manual ruin overlap reached CreateUnit')
end
print(string.format('PASS city ruins: deterministic nested latitude sets (%d samples; %.2f%% / %.2f%% / %.2f%%), '..
    'explicit latitude zero, protected arcologies, failed creates, fillers, duplicate, jittered and manual plots',
    total,100*counts[0]/total,100*counts[30]/total,100*counts[60]/total))
