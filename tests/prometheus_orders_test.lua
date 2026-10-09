-- Executes real main.lua -> team.lua -> strategy managers -> packet serializer
-- -> authenticated synced receiver -> Spring.GiveOrderToUnit boundary. Only the
-- engine API is substituted. Unit costs/menus and morph specs come from game files.
local function eq(a,b,msg) assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
local function loadIn(path,e) return setfenv(assert(loadfile(path)),e)() end
local function definitions()
    local e=setmetatable({}, {__index=_G});e._G=e
    local function lower(t)
        local result={}
        for k,v in pairs(t) do result[type(k)=='string' and k:lower() or k]=type(v)=='table' and lower(v) or v end
        return result
    end
    e.lowerkeys=lower
    local function merge(a,b)
        for k,v in pairs(b) do
            if type(v)=='table' then a[k]=a[k] or {};merge(a[k],v)
            elseif a[k]==nil then a[k]=v end
        end
    end
    e.Unit={}
    function e.Unit:New(t)
        local result=lower(t or {});merge(result,self);result.New=self.New;return result
    end
    for _,p in ipairs({'Human','Buildings','GroundDrones','AirDrones','Abstract','Vehicles'}) do
        for name,def in pairs(loadIn('baseclasses/units/'..p..'.lua',e)) do e[name]=def end
    end
    local paths={
        'units/antagon/OperativePropagator.lua','units/protagon/operativeInvestigator.lua',
        'units/antagon/antagonSafehouse.lua','units/protagon/protagonSafehouse.lua',
        'units/shared/house_expansions/propagandaserver.lua','units/shared/house_expansions/Assembly.lua',
        'units/shared/human/OperativeAsset.lua','units/shared/human/CivilianAgent.lua',
        'units/shared/chasis/air/copter/air_copter_scoutlett.lua',
        'units/shared/chasis/ground/walker/ground_walker_mg.lua',
        'units/shared/chasis/ground/walker/ground_walker_grenade.lua',
        'units/shared/chasis/ground/walker/ground_walker_flame.lua',
        'units/shared/chasis/air/copter/air_copter_antiarmor.lua',
        'units/shared/chasis/air/copter/air_copter_mg.lua',
        'units/shared/chasis/ground/wheels/Truck.lua','units/shared/abstracts/Icons.lua',
    }
    local raw={}
    for _,path in ipairs(paths) do for name,def in pairs(loadIn(path,e)) do raw[name]=def end end
    -- Engine-normalized subset; IDs are test-local. No strategic manager mocks.
    local names={};for name in pairs(raw) do names[#names+1]=name end;table.sort(names)
    local defs,byName={},{}
    for _,name in ipairs(names) do
        local r=raw[name];local id=#defs+1
        local d={id=id,name=name,metalCost=r.buildcostmetal or 0,energyCost=r.buildcostenergy or 0,
            speed=(r.maxvelocity or 0)*30,isFactory=r.yardmap~=nil and (r.maxvelocity or 0)==0 and (r.workertime or 0)>0,
            canFly=r.canfly,canCloak=r.cancloak,customParams=r.customparams or {},weapons=r.weapons or {},buildOptions={}}
        defs[id]=d;byName[name]=d
    end
    local function stub(name,speed,weapons)
        if byName[name] then return end
        local d={id=#defs+1,name=name,speed=speed or 0,metalCost=0,energyCost=0,customParams={},weapons=weapons or {},buildOptions={},fixtureStub=true}
        defs[d.id]=d;byName[name]=d
    end
    for _,name in ipairs(names) do
        for _,opt in ipairs(raw[name].buildoptions or {}) do stub(opt) end
    end
    -- Actual UnitMorph factory upgrade IDs generated from the actual specs.
    for _,side in ipairs({'Antagon','Protagon'}) do
        local specs=loadIn('luarules/configs/side_morph_defs/'..side..'.lua',e)
        local safe=side:lower()..'safehouse'
        for _,spec in ipairs(specs[safe]) do
            stub(spec.into)
            local fake=side:lower()..'_morph_'..safe..'_'..spec.into
            stub(fake,0.3);byName[fake].customParams.isupgrade=true
            raw[safe].buildoptions[#raw[safe].buildoptions+1]=fake
        end
    end
    for _,name in ipairs(names) do
        for _,opt in ipairs(raw[name].buildoptions or {}) do
            byName[name].buildOptions[#byName[name].buildOptions+1]=byName[opt].id
        end
    end
    stub('house_asian1');stub('objective_powerplant');stub('security_truck',60,{{}})
    return defs,byName
end
local defs,names=definitions()
local function world(side)
    local w={frame=0,units={},orders={},logs={},packets={},metal=30000,energy=30000,rules={},fail=false,menus=true,buildable=true}
    local function add(id,name,t,x,z,built)
        local def=assert(names[name],name)
        w.units[id]={def=def.id,team=t,x=x or 500,z=z or 500,hp=100,maxHP=100,built=built or 1,queue={},rules={},los=true}
    end
    w.add=add;w.side=side
    local spring={GetModOptions=function() return {craig_difficulty='3'} end,
        GetMyPlayerID=function() return 7 end,GetGaiaTeamID=function() return 0 end,
        GetTeamList=function() return {0,1,2} end,
        GetTeamInfo=function(t) return t,t==1 and 7 or 8,false,true,t==1 and side or '',t end,
        GetTeamLuaAI=function(t) return t==1 and 'Prometheus' or '' end,
        GetTeamRulesParam=function() return nil end,
        SetTeamRulesParam=function(t,k,v) w.rules[k]=v end,
        GetTeamUnits=function(t) local r={};for id,u in pairs(w.units) do if u.team==t then r[#r+1]=id end end;return r end,
        GetAllUnits=function() local r={};for id in pairs(w.units) do r[#r+1]=id end;return r end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitIsDead=function(id) return not w.units[id] end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitTeam=function(id) return w.units[id] and w.units[id].team end,
        GetUnitHealth=function(id) local u=w.units[id];if u then return u.hp,u.maxHP,0,0,u.built end end,
        GetUnitPosition=function(id) local u=w.units[id];if u then return u.x,0,u.z end end,
        GetUnitRulesParam=function(id,k) return w.units[id] and w.units[id].rules[k] end,
        GetUnitIsCloaked=function(id) return w.units[id] and w.units[id].cloaked or false end,
        GetUnitLosState=function(id) return {los=w.units[id] and w.units[id].los} end,
        GetUnitTransporter=function() return nil end,
        GetTeamStartPosition=function() return 500,0,500 end,
        GetGroundHeight=function() return 0 end,
        GetTeamResources=function(t,r) return r=='metal' and w.metal or w.energy,40000,0,20 end,
        AreTeamsAllied=function(a,b) return a==b end,
        TestBuildOrder=function() return w.buildable and 2 or 0 end,
        TestMoveOrder=function() return true end,
        GetUnitCommands=function(id,n) local q=w.units[id] and w.units[id].queue or {};return n==0 and #q or q end,
        GetFactoryCommands=function(id,n) local q=w.units[id] and w.units[id].queue or {};return n==0 and #q or q end,
        GetUnitCmdDescs=function(id)
            local r={}
            if w.menus and defs[w.units[id].def].name==side..'safehouse' then
                for _,target in ipairs({'propagandaserver',side..'assembly'}) do
                    r[#r+1]={id=1000+names[target].id,texture='#'..names[target].id}
                end
            end
            return r
        end,
        Echo=function(...) w.logs[#w.logs+1]=table.concat({...},' ') end,
        Log=function(_,_,msg) w.logs[#w.logs+1]=msg end,
    }
    local cmd={STOP=0,MOVE=10,ATTACK=20,FIGHT=16,FIRE_STATE=45,CLOAK=95,OPT_ALT=128,OPT_CTRL=64,OPT_SHIFT=32,OPT_RIGHT=16}
    local client,server
    local function realm(synced)
        local e=setmetatable({}, {__index=_G});e._G=e;e.gadget={};e.CMD=cmd;e.Spring={}
        for k,v in pairs(spring) do e.Spring[k]=v end
        e.UnitDefs=defs;e.UnitDefNames=names;e.Game={mapSizeX=8192,mapSizeZ=8192}
        e.gadgetHandler={IsSyncedCode=function() return synced end,UpdateCallIn=function() end,
            AddChatAction=function() end,AddSyncAction=function(self,k,fn) w[k]=fn end,
            RemoveSyncAction=function() end,RemoveChatAction=function() end}
        e.SendToUnsynced=function(k,...) if w[k] then w[k](k,...) end end
        local function include(p)
            p=p:gsub('LuaRules','luarules'):gsub('Gadgets','gadgets')
            return loadIn(p,e)
        end
        e.include=include;e.VFS={Include=include,ZIP=1}
        return e
    end
    client=realm(false);server=realm(true)
    client.Spring.SendLuaRulesMsg=function(packet) w.packets[#w.packets+1]=packet;server.gadget:RecvLuaMsg(packet,7) end
    server.Spring.GiveOrderToUnit=function(id,c,p,o)
        if w.fail then return false end
        local u=assert(w.units[id]);local def=defs[u.def]
        if c<0 then
            local legal=false
            for _,opt in ipairs(def.buildOptions) do if opt==-c then legal=true end end
            assert(legal,'illegal build command from real manager')
            assert(not defs[-c].fixtureStub,'selected production must use real UnitDef costs/menu')
            if not def.isFactory then assert(#p==4,'mobile builder must supply a site') end
        elseif c==20 then assert(w.units[p[1]],'attack target exists') end
        w.orders[#w.orders+1]={id=id,cmd=c,params=p,options=o,frame=w.frame}
        if c==95 then u.cloaked=p[1]==1
        elseif c==0 then u.queue={}
        elseif c~=45 then u.queue={{id=c,params=p}} end
        return true
    end
    loadIn('luarules/gadgets/prometheus/main.lua',client)
    loadIn('luarules/gadgets/prometheus/main.lua',server)
    client.gadget:Initialize();server.gadget:Initialize()
    function w.tick(f) w.frame=f;client.gadget:GameFrame(f);server.gadget:GameFrame(f) end
    function w.created(id,name,builder,x,z)
        add(id,name,1,x,z);server.gadget:UnitCreated(id,names[name].id,1,builder);server.gadget:UnitFinished(id,names[name].id,1)
        if builder then w.units[builder].queue={} end
    end
    w.client=client;w.server=server;w.cmd=cmd
    function w.has(c,id)
        for _,o in ipairs(w.orders) do if o.cmd==c and (not id or o.id==id) then return o end end
    end
    return w
end
for _,side in ipairs({'antagon','protagon'}) do
    local op=side=='antagon' and 'operativepropagator' or 'operativeinvestigator'
    local w=world(side);w.add(10,op,1,500,500)
    for id=100,107 do w.add(id,'house_asian1',0,600+(id-100)*500,500) end
    w.tick(2)
    local build=assert(w.has(-names[side..'safehouse'].id,10),'real startup must build')
    eq(#build.params,4);eq(build.params[1],600)
    w.created(20,side..'safehouse',10,600,500);w.tick(92)
    assert(w.has(-names[op].id,20),'real recruitment order must reach engine')
    assert(w.has(-names[side..'safehouse'].id,10),'expansion starts')
    w.created(21,side..'safehouse',10,1100,500);w.tick(182)
    -- First safehouse is busy recruiting; the second can convert via the
    -- actual morph descriptor, while the first remains a recruitment hub.
    assert(w.has(1000+names.propagandaserver.id,21),'custom upgrade must reach engine')
    w.created(30,op,20,600,500);w.tick(272)
    assert(w.server.gadget.commandAudit[1].dispatched>0)
    eq(w.server.gadget.commandAudit[1].rejected,0)
end
-- Scouting, fog-of-war, raids, split target caps and retreat through real bridge.
do
    local w=world('protagon')
    w.add(10,'operativeinvestigator',1,500,500)
    w.add(20,'protagonsafehouse',1,600,500);w.add(21,'propagandaserver',1,1100,500)
    for i=1,5 do w.add(100+i,'house_asian1',0,1000+i*500,2000) end
    w.add(30,'air_copter_scoutlett',1,500,500)
    w.add(40,'antagonsafehouse',2,700,500)
    w.add(41,'propagandaserver',2,700,800);w.units[41].los=false
    w.tick(2)
    assert(w.has(10,30),'scout moves')
    assert(w.has(20,10),'operative starts exposed-network raid')
    for _,o in ipairs(w.orders) do assert(o.cmd~=20 or o.params[1]~=41,'no hidden target') end
    w.units[10].hp=20;w.tick(92)
    assert(w.has(10,10),'wounded operative retreats')
    eq(w.units[10].cloaked,true,'retreat cloaks')
end
-- No economy orders without money; diagnostics distinguish legitimate waiting.
do
    local w=world('antagon');w.metal=0;w.energy=0
    w.add(10,'operativepropagator',1);w.add(100,'house_asian1',0,600,500)
    w.add(50,'icon_cybercrime',1,600,500) -- active finite recovery job, no duplicate
    for f=2,10000,90 do w.tick(f) end
    assert(not w.has(-names.antagonsafehouse.id),'no unfunded construction')
    local joined=table.concat(w.logs,'\n')
    assert(joined:find('waiting: resources'),'resource waiting diagnosed')
    assert(#w.logs<=6,'default diagnostics bounded')
end
-- Split combat assignments never converge more than three units on one target.
do
    local w=world('antagon');w.metal=0;w.energy=0
    w.add(20,'antagonsafehouse',1,500,500);w.add(21,'propagandaserver',1,1100,500)
    w.add(80,'propagandaserver',2,2500,2500);w.add(81,'propagandaserver',2,4000,4000)
    for id=30,41 do w.add(id,'ground_walker_mg',1,600,700) end
    w.tick(2)
    local attacks=0;local targetCounts={}
    for _,o in ipairs(w.orders) do
        if o.cmd==16 then
            attacks=attacks+1
            local key=o.params[1]>3000 and 81 or 80;targetCounts[key]=(targetCounts[key] or 0)+1
        end
    end
    eq(attacks,6,'two separate three-unit operations');eq(targetCounts[80],3);eq(targetCounts[81],3)
end
-- Engine rejection counted separately from successful serialization and enqueue.
do
    local w=world('antagon');w.add(10,'operativepropagator',1);w.add(100,'house_asian1',0,600,500)
    w.fail=true;w.tick(2);w.server.gadget:GameFrame(900)
    assert(w.server.gadget.commandAudit[1].rejected>0);eq(w.rules.prometheus_orders_dispatched,0)
end
-- Large maps, high target IDs and custom IDs survive the real codec.
do
    local w=world('protagon');w.add(70000,'ground_walker_mg',1)
    assert(w.client.GiveOrderToUnit(70000,50000,{70001,50000,-40000},{'shift'}))
    w.tick(2)
    local o=assert(w.has(50000,70000));eq(o.params[1],70001);eq(o.params[3],-40000);eq(o.options,32)
end
-- Stalled production frees the operative and quarantines its failed building.
do
    local w=world('antagon');w.add(10,'operativepropagator',1)
    w.add(100,'house_asian1',0,600,500);w.add(101,'house_asian1',0,1200,500)
    w.tick(2);w.tick(1892)
    assert(w.has(0,10),'stalled production cancelled')
    w.tick(1982) -- cancellation reaches the engine before selecting another site
    local last
    for _,o in ipairs(w.orders) do if o.cmd==-names.antagonsafehouse.id then last=o end end
    eq(last.params[1],1200,'retry uses another city building')
end
-- An unavailable morph menu waits explicitly rather than issuing -destination.
do
    local w=world('protagon');w.metal=2000;w.energy=2000;w.menus=false
    w.add(20,'protagonsafehouse',1,500,500);w.add(21,'protagonsafehouse',1,1100,500)
    w.tick(2)
    assert(table.concat(w.logs,'\n'):find('waiting: morph menu'),'missing morph diagnosed')
    assert(not w.has(-names.propagandaserver.id),'cannot build an upgrade as an ordinary unit')
end
-- Public objective semantics: attack hostile live sites / restore own destroyed
-- sites, and protect friendly live objectives. No parsing localized tooltips.
do
    local w=world('protagon');w.metal=0;w.energy=0
    w.add(20,'protagonsafehouse',1,500,500);w.add(30,'ground_walker_mg',1,700,500)
    w.add(100,'objective_powerplant',0,900,500)
    w.units[100].rules={objective_protagon=1,objective_destroyed=0,objective_income=5}
    w.tick(2);assert(not w.has(20),'friendly objective untouched')
    w.units[100].rules.objective_destroyed=1;w.tick(92)
    local attack=assert(w.has(20,30));eq(attack.params[1],100)
end
-- Role caps count queued and unfinished work. A full roster stops recruiting
-- instead of filling every safehouse with an endless death-ball queue.
do
    local w=world('antagon');w.add(20,'antagonsafehouse',1,500,500)
    for id=21,24 do w.add(id,'propagandaserver',1,1000+(id-21)*500,500) end
    w.add(25,'antagonassembly',1,4000,500)
    for id=30,33 do w.add(id,'operativepropagator',1,600,700) end
    for id=34,36 do w.add(id,'operativeasset',1,600,700) end
    for id=37,38 do w.add(id,'air_copter_scoutlett',1,600,700) end
    for id=39,40 do w.add(id,'civilianagent',1,600,700) end
    for id=41,52 do w.add(id,'ground_walker_mg',1,600,700) end
    w.tick(2);w.tick(92)
    for _,o in ipairs(w.orders) do assert(o.cmd>=0,'full roster must not queue production') end
end
-- The receiver checks current ownership after enqueue and counts failures.
do
    local w=world('protagon');w.add(30,'ground_walker_mg',1)
    assert(w.client.GiveOrderToUnit(30,10,{1000,0,1000},{}))
    w.client.gadget:GameFrame(2);w.units[30].team=2;w.server.gadget:GameFrame(2)
    assert(not w.has(10,30));assert(w.server.gadget.commandAudit[2].rejected>=1)
end
-- Assassin roles target exposed operatives rather than attempting building raids.
do
    local w=world('antagon');w.metal=0;w.energy=0
    w.add(30,'operativeasset',1,500,500);w.add(80,'operativeinvestigator',2,650,500)
    w.add(81,'protagonsafehouse',2,700,500);w.tick(2)
    local attack=assert(w.has(20,30));eq(attack.params[1],80,'assassination target')
end
-- Air-defence vehicles never receive ineffective ground attack orders.
do
    local w=world('protagon');w.metal=0;w.energy=0
    w.add(30,'ground_truck_rocket',1,500,500);w.add(80,'propagandaserver',2,650,500)
    w.tick(2);assert(not w.has(20,30),'AA truck cannot attack ground')
    w.add(81,'air_copter_mg',2,650,500);w.tick(92)
    local attack=assert(w.has(20,30));eq(attack.params[1],81)
end
print('PASS Prometheus real orders: both factions, construction/recruitment/morph, scouting/raids/retreat, fog, bounded logs, split pressure, rejection audit, wide codec')
