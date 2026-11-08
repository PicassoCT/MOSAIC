-- Lua 5.1+: run from the repository root. Exercise the production selector,
-- loader callback, inherited UnitDef and complete unitscript with engine mocks.
local function loadEnv(path, env)
    if setfenv then
        local chunk = assert(loadfile(path)); setfenv(chunk, env); return chunk()
    end
    return assert(loadfile(path, 't', env))()
end
local function read(path)
    local file = assert(io.open(path)); local source = file:read('*a'); file:close(); return source
end
local function run(source, env)
    if setfenv then return setfenv(assert(loadstring(source)), env)() end
    return assert(load(source, 'production callback', 't', env))()
end
local function callback(source, name)
    return assert(source:match('(function '..name..'%([^\n]*\n.-\nend)'))
end
local function check(name, fn)
    fn(); print('PASS: '..name)
end
local function noop() end
local function environment(values)
    local env = setmetatable(values or {}, {__index = _G})
    env._G = env
    return env
end
local catalog = dofile('scripts/lib_truck_service_payloads.lua')

local function loaderFixture(hasServiceDefinition)
    local definitions = {
        [1] = {name='truck_arab6', scriptName='Truckscript.lua'},
        [2] = {name='truck_arab7', scriptName='Truckscript.lua'},
        [3] = {name='truck_arab8', scriptName='Truckscript.lua'},
        [4] = {name='truck_western3', scriptName='LongTruckscript.lua'},
        [5] = {name='truck_arab99', scriptName='scripts/LongTruckscript.lua'},
        [6] = {name='civilian_truck_mg', scriptName='Truckscript.lua'},
        [7] = {name='truck_arab0', scriptName='Truckscript.lua'},
        [8] = {name='truck_arab7', scriptName='Truckscript.lua'},
    }
    local names = {truckpayload={id=20}}
    if hasServiceDefinition ~= false then names.truckpayloadservice={id=21} end
    local loadable = {[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[8]=true}
    local civilian = {[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true}
    local f = {state={}, requests={}, attached={}, fail={}, carrierDef=1, team=0, nextID=100}
    local options = {state=f.state, unitDefs=definitions, unitDefNames=names,
        loadableTypes=loadable, civilianTypes=civilian, gaiaTeamID=0}
    local env = environment({gaiaTeamID=0, loadableTruckType=loadable,
        servicePayloadSelector=catalog.newSelector(options), Spring={}})
    env.spGetUnitDefID = function(id) assert(id==10); return f.carrierDef end
    env.spGetUnitTeam = function(id) assert(id==10); return f.team end
    env.createUnitAtUnit = function(team, name, carrier)
        assert(team==0 and carrier==10)
        f.requests[#f.requests+1]=name
        if f.fail[name] then return end
        f.nextID=f.nextID+1
        return f.nextID
    end
    env.Spring.SetUnitAlwaysVisible = function(id, value) assert(value and id>100) end
    env.Spring.GetUnitPieceMap = function(id) assert(id==10); return {attachPoint=7} end
    env.Spring.UnitAttach = function(carrier, payload, piece)
        assert(carrier==10 and payload>100 and piece==7)
        f.attached[#f.attached+1]=payload
    end
    env.Spring.Echo = noop
    local source=read('luarules/gadgets/game_civilians.lua')
    run(callback(source,'attachPayload'),env)
    run(callback(source,'loadTruck'),env)
    f.load=function(name) return env.loadTruck(10,name or 'truckpayload') end
    f.reload=function() env.servicePayloadSelector=catalog.newSelector(options) end
    return f
end

check('ordinary payload quota is exactly 25 percent across two complete service cycles',function()
    local f=loaderFixture()
    local old,new=0,0
    local pieces,variantState,seen={},{},{}
    for index=1,13 do pieces[index]=index end
    for index=1,104 do
        f.carrierDef=((index-1)%3)+1
        assert(f.load())
        local selected=f.requests[#f.requests]
        assert(selected==(index%4==0 and 'truckpayloadservice' or 'truckpayload'))
        if selected=='truckpayloadservice' then
            new=new+1
            local variant,piece,variantIndex=catalog.selectVariant(pieces,variantState)
            assert(piece==variantIndex and variantIndex==((new-1)%13)+1)
            seen[variant.key]=(seen[variant.key] or 0)+1
        else
            old=old+1
        end
        if index==37 then f.reload() end
    end
    assert(old==78 and new==26 and #f.attached==104)
    assert(f.state.eligibleSpawns==104 and f.state.serviceSpawns==26)
    assert(variantState.spawns==26)
    for _,variant in ipairs(catalog.variants) do assert(seen[variant.key]==2) end
end)

check('refugees, special loads, military, long trucks and non-Gaia do not consume quota',function()
    local f=loaderFixture()
    for _=1,3 do assert(f.load()) end
    for _,request in ipairs({'truckpayloadrefugee','truckpayloadfortnox','physicspayload'}) do
        assert(f.load(request)); assert(f.requests[#f.requests]==request)
    end
    for _,definition in ipairs({4,5,6,8}) do
        f.carrierDef=definition
        assert(f.load()); assert(f.requests[#f.requests]=='truckpayload')
    end
    f.carrierDef=7
    local count=#f.requests
    assert(not f.load() and #f.requests==count)
    f.carrierDef=1; f.team=2
    assert(f.load()); assert(f.requests[#f.requests]=='truckpayload')
    assert(f.state.eligibleSpawns==3)
    f.team=0
    assert(f.load()); assert(f.requests[#f.requests]=='truckpayloadservice')
end)

check('missing new definition and failed creation fall back without empty trucks',function()
    local absent=loaderFixture(false)
    for _=1,12 do assert(absent.load()); assert(absent.requests[#absent.requests]=='truckpayload') end
    assert(absent.state.eligibleSpawns==12 and not absent.state.serviceSpawns)
    local f=loaderFixture()
    for _=1,3 do assert(f.load()) end
    f.fail.truckpayloadservice=true
    assert(f.load())
    assert(f.requests[#f.requests-1]=='truckpayloadservice' and f.requests[#f.requests]=='truckpayload')
    assert(f.state.eligibleSpawns==4 and not f.state.serviceSpawns)
    for _=1,3 do assert(f.load()) end
    f.fail.truckpayload=true
    assert(not f.load() and f.state.eligibleSpawns==7)
    f.fail={}
    assert(f.load() and f.requests[#f.requests]=='truckpayloadservice')
    assert(f.state.eligibleSpawns==8 and f.state.serviceSpawns==1)
end)

check('thirteen numbered bodies retain their order, cycle fairly and tolerate missing pieces',function()
    local keys={'air_scrubber','night_kitchen','battery_exchange','salvage_press',
        'cold_chain','sleeper_shuttle','crematorium','noodle_shop','casino',
        'strip_club','bar','band','unato_rations'}
    assert(#catalog.variants==13)
    local pieces,state,seen={},{},{}
    for index,key in ipairs(keys) do
        assert(catalog.variants[index].key==key)
        pieces[index]=100+index
    end
    assert(catalog.variants[13].title=='UNATO ration dispenser')
    for _=1,52 do
        local variant,piece,index=catalog.selectVariant(pieces,state)
        assert(piece==100+index and variant.pieceName=='container'..index)
        seen[index]=(seen[index] or 0)+1
    end
    for index=1,13 do assert(seen[index]==4) end
    local partial,counts={},{}
    for _=1,6 do
        local _,piece,index=catalog.selectVariant({[2]=22,[13]=33},partial)
        assert(piece==22 or piece==33)
        counts[index]=(counts[index] or 0)+1
    end
    assert(counts[2]==3 and counts[13]==3)
    assert(not catalog.selectVariant({},partial) and partial.spawns==6)
end)

check('single service UnitDef inherits original transport and health properties',function()
    local function normalize(value)
        if type(value)~='table' then return value end
        local result={}
        for key,item in pairs(value) do
            result[type(key)=='string' and key:lower() or key]=normalize(item)
        end
        return result
    end
    -- Account for recursive engine normalization and direct authoring loads.
    for _,lower in ipairs({normalize,function(value) return value end}) do
        local env=environment({lowerkeys=lower})
        env.VFS={Include=function(path) return loadEnv(path,env) end}
        local base=normalize(loadEnv('units/neutral/truckPayload.lua',env).truckpayload)
        local definitions=loadEnv('units/neutral/truckPayloadService.lua',env)
        local service=assert(definitions.truckpayloadservice)
        local count=0; for _ in pairs(definitions) do count=count+1 end; assert(count==1)
        for _,key in ipairs({'maxdamage','mass','upright','blocking','cantbetransported',
            'footprintx','footprintz','canmove','canattack','reclaimable','category'}) do
            assert(service[key]==base[key], 'changed original gameplay property: '..key)
        end
        assert(service.objectname=='truckPayloadService.dae')
        assert(service.script=='truckServicePayloadScript.lua')
        assert(service.customparams.normaltex=='unittextures/house_asian_normal.dds')
        assert(base.customparams.normaltex=='unittextures/house_arab_normal.dds')
    end
end)

local function scriptFixture(previousSpawns, missingPieces)
    local f={parent=nil,alive={[7]=true,[101]=true,[102]=true,[103]=true},
        tips={[101]='Plate A',[102]='Plate B',[103]='Plate C'},moves={},shown={},hidden={},flags={}}
    local pieces,list={center=0},{'center'}
    if not missingPieces then
        for index=13,1,-1 do
            pieces['container'..index]=index; list[#list+1]='container'..index
        end
    end
    local env=environment({arg=false,unitID=7,unitDefID=20,script={},
        Game={mapSizeX=1024,mapSizeZ=1024},
        GG={CivilianServicePayloadVariants={spawns=previousSpawns or 0}},
        UnitDefs={[20]={name='truckpayloadservice'},[1]={name='truck_arab6'},
            [2]={name='truck_arab7'},[3]={name='truck_arab8'}},
        y_axis=2,z_axis=3,Spring={}})
    env.VFS={Include=function(path) return loadEnv(path,env) end}
    env.include=function(path) return loadEnv('scripts/'..path,env) end
    env.piece=function(name) return assert(pieces[name]) end
    env.Hide=function(piece) f.hidden[piece]=true; f.shown[piece]=nil end
    env.Show=function(piece) f.shown[piece]=true; f.hidden[piece]=nil end
    env.Move=function(piece,axis,value,speed)
        assert(piece==0 and speed==0); f.moves[#f.moves+1]={axis=axis,value=value}
    end
    env.Sleep=function(ms) f.sleep=ms; coroutine.yield() end
    env.StartThread=function(fn)
        f.thread=coroutine.create(fn); assert(coroutine.resume(f.thread)); return f.thread
    end
    local S=env.Spring
    S.GetUnitPieceMap=function() return pieces end
    S.GetUnitPieceList=function() return list end
    S.ValidUnitID=function(id) return f.alive[id] or false end
    S.GetUnitIsDead=function(id) return not f.alive[id] end
    S.GetUnitTransporter=function() return f.parent end
    S.GetUnitDefID=function(id) return ({[101]=1,[102]=2,[103]=3})[id] end
    S.GetUnitTooltip=function(id) assert(f.alive[id]); return f.tips[id] end
    S.SetUnitTooltip=function(id,text) assert(f.alive[id]); f.tips[id]=text end
    for _,method in ipairs({'SetUnitNeutral','SetUnitBlocking','SetUnitAlwaysVisible','SetUnitNoSelect'}) do
        local name=method
        S[name]=function(id,value) assert(id==7); f.flags[name]=value end
    end
    S.Echo=function(message) f.echo=message end
    loadEnv('scripts/truckServicePayloadScript.lua',env)
    f.script=env.script; f.GG=env.GG
    f.step=function(times)
        for _=1,times or 1 do assert(coroutine.resume(f.thread)) end
    end
    f.script.Create()
    return f
end

check('one complete piece is visible and only sleeper reuses existing bus routines',function()
    for index=1,13 do
        local f=scriptFixture(index-1)
        local count=0; for piece in pairs(f.shown) do count=count+1; assert(piece==index) end
        assert(count==1 and f.hidden[0])
        assert(f.flags.SetUnitNeutral and f.flags.SetUnitAlwaysVisible and f.flags.SetUnitNoSelect)
        assert(f.flags.SetUnitBlocking==false)
        assert((f.GG.BusesTable and f.GG.BusesTable[7]~=nil or false)==(index==6))
        f.script.Killed(1,1)
        assert(not f.GG.BusesTable or not f.GG.BusesTable[7])
    end
    local missing=scriptFixture(0,true)
    assert(not missing.thread and missing.echo and next(missing.shown)==nil)
end)

check('carrier fitting precedes tooltip delay and follows detach and reattachment',function()
    local f=scriptFixture()
    assert(f.sleep==100 and #f.moves==0)
    f.parent=101; f.step()
    assert(#f.moves==2 and f.moves[1].value==0 and f.moves[2].value==-3.5)
    assert(f.tips[101]=='Plate A')
    f.step(2)
    assert(f.tips[101]:find(' transporting Municipal air scrubber',1,true))
    assert(#f.moves==2, 'fitting repeated while the same carrier remained attached')
    f.parent=nil; f.flags.SetUnitNoSelect=false; f.step()
    assert(f.tips[101]=='Plate A' and f.flags.SetUnitNoSelect)
    assert(f.moves[3].value==0 and f.moves[4].value==0)
    f.parent=102; f.step(3)
    assert(f.moves[5].value==3.5 and f.moves[6].value==1)
    assert(f.tips[102]:find(' transporting ',1,true))
    f.tips[102]='Refugee from somewhere'
    f.parent=103; f.step(3)
    assert(f.tips[102]=='Refugee from somewhere', 'overwrote a later special description')
    assert(f.moves[7].value==4.1 and f.moves[8].value==0)
    f.alive[103]=nil -- transporter may remain briefly stale during destruction
    f.step()
    assert(f.moves[9].value==0 and f.moves[10].value==0)
    f.script.Killed(1,1)
end)

check('team platters remain on carriers and skip old and new payload bodies',function()
    local path='luaui/widgets_mosaic/gui_team_platter.lua'
    local names,defs,dimensions={},{},{}
    for name in read(path):gmatch('UnitDefNames%["([^"]+)"%]') do
        if not names[name] then
            local id=#defs+1
            defs[id]={name=name,customParams={}}; names[name]={id=id}
        end
    end
    local service=#defs+1; defs[service]={name='truckpayloadservice',customParams={civilian_service_payload=true}}
    local carrier=#defs+1; defs[carrier]={name='truck_arab6',customParams={}}
    local splitHouse=#defs+1; defs[splitHouse]={name='house_asian_split_1_2',customParams={house_asian_base='house_asian0'}}
    local units={service,carrier,splitHouse,names.truckpayload.id,names.truckpayloadrefugee.id}
    local env=environment({widget={},WG={},UnitDefs=defs,UnitDefNames=names,
        GL={LINE_LOOP=1,TRIANGLE_FAN=2},gl=setmetatable({},{__index=function() return noop end}),
        Spring={
            GetGaiaTeamID=function() return 0 end,
            GetTimer=function() return 0 end,
            GetSelectedUnits=function() return {} end,
            GetAllUnits=function() return units end,
            IsUnitVisible=function() return true end,
            GetUnitTeam=function() return 0 end,
            GetUnitDefID=function(id) return id end,
            GetUnitDefDimensions=function(id)
                dimensions[id]=(dimensions[id] or 0)+1
                return nil -- filtering has already occurred before draw setup
            end,
        }})
    loadEnv(path,env)
    env.widget:DrawWorldPreUnit()
    assert(dimensions[carrier]==1)
    assert(not dimensions[service] and not dimensions[splitHouse])
    assert(not dimensions[names.truckpayload.id] and not dimensions[names.truckpayloadrefugee.id])
end)

print('PASS: civilian service payload regression suite')
