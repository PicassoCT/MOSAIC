-- Run from the game root: lua tests/city_parade_adapter_test.lua
-- Exercise the actual gadget boundary with a controlled synced controller.
local source = 'luarules/gadgets/game_city_parade.lua'
local function fixture(synced)
    local s = {frame=76543, cheats=false, includes={}, commands={}, messages={},
        previewCalls={}, stopCalls={}, frames={}, damage={}, destroyed={}, recovered=0,
        shutdowns=0, removed={}, accepted=true, reason=nil}
    local env = setmetatable({gadget={}, GG={unrelated='preserve'},
        Game={mapSizeX=8192,mapSizeZ=8192}, UnitDefs={}, UnitDefNames={}}, {__index=_G})
    s.env=env
    local gameConfig, config, catalog, routeBuilder = {}, {}, {}, {}
    local houses = {[10]=10,[20]=20,[30]=30,[40]=40}
    local walkers, trucks = {[50]=50}, {[60]=60}
    local holograms = {[70]=true,[71]=true,[72]=true}
    env.UnitDefs[70]={id=70,customParams={}}
    env.UnitDefs[71]={id=71,customParams={parade_hologram=true}}
    env.UnitDefs[72]={id=72}
    env.UnitDefs[73]={id=73,name='animated_hologram'}
    env.UnitDefs[74]={id=74,name='animated_hologramv2'}
    env.UnitDefNames.animated_hologram=env.UnitDefs[73]
    env.UnitDefNames.animated_hologramv2=env.UnitDefs[74]
    local director = {phase='idle',vehicles={},participants={}}
    s.director=director
    function director:Recover()
        assert(env.GG.CityParade==self, 'publish director before recovery')
        s.recovered=s.recovered+1
    end
    function director:RequestPreview(frame)
        s.previewCalls[#s.previewCalls+1]=frame
        return s.accepted,s.reason
    end
    function director:Stop(...)
        s.stopCalls[#s.stopCalls+1]={...}
    end
    function director:Frame(frame) s.frames[#s.frames+1]=frame end
    function director:UnitDamaged(...) s.damage[#s.damage+1]={...} end
    function director:UnitDestroyed(id) s.destroyed[#s.destroyed+1]=id end
    function director:Shutdown() s.shutdowns=s.shutdowns+1 end
    env.Spring = {
        GetGameFrame=function() return s.frame end,
        IsCheatingEnabled=function() return s.cheats end,
        Echo=function(message) s.messages[#s.messages+1]=message end,
    }
    env.gadgetHandler = {
        IsSyncedCode=function() return synced end,
        AddChatAction=function(_,name,callback,help)
            assert(name=='parade' and type(callback)=='function' and type(help)=='string')
            assert(s.recovered==1, 'recovery precedes command registration')
            assert(not s.commands[name], 'duplicate command registration')
            s.commands[name]=callback
        end,
        RemoveChatAction=function(_,name)
            s.removed[#s.removed+1]=name; s.commands[name]=nil
        end,
    }
    env.getGameConfig=function() return gameConfig end
    env.getCultureUnitModelTypes=function(culture,kind,defs)
        assert(culture=='international' and defs==env.UnitDefs)
        if kind=='house' then return houses end
        if kind=='civilian' then return walkers end
        if kind=='truck' then return trucks end
        error('unexpected cultural type '..tostring(kind))
    end
    env.getBuildingRuinTypeTable=function(defs) assert(defs==env.UnitDefs); return {[20]=20} end
    env.getBuildingScrapHeapTypeTable=function(defs) assert(defs==env.UnitDefs); return {[30]=30} end
    env.getHologramTypes=function(defs) assert(defs==env.UnitDefs); return holograms end
    env.setSpeedEnv=function() end
    env.VFS={Include=function(path)
        s.includes[#s.includes+1]=path
        if path=='scripts/lib_UnitScript.lua' or path=='scripts/lib_mosaic.lua'
            or path=='scripts/lib_staticstring.lua' then return end
        if path=='luarules/configs/city_parade.lua' then return config end
        if path=='scripts/lib_truck_parade_payloads.lua' then return catalog end
        if path=='scripts/lib_parade_clearance.lua' then return dofile(path) end
        if path=='scripts/lib_city_parade_route.lua' then
            return {new=function(context) s.routeContext=context; return routeBuilder end}
        end
        if path=='luarules/gadgets/include/city_parade.lua' then
            return {New=function(context)
                s.context=context
                assert(context.routeBuilder==routeBuilder and s.routeContext==context)
                assert(context.config==config and context.gameConfig==gameConfig)
                assert(context.catalog==catalog and context.setSpeed==env.setSpeedEnv)
                assert(context.Spring==env.Spring and context.GG==env.GG and context.Game==env.Game)
                assert(context.UnitDefs==env.UnitDefs and context.UnitDefNames==env.UnitDefNames)
                assert(context.walkerTypes==walkers and context.truckTypes==trucks)
                return director
            end}
        end
        error('unexpected include '..path)
    end}
    s.loadResult=assert(loadfile(source,'t',env))()
    s.houses=houses
    s.holograms=holograms
    return s
end

local unsynced=fixture(false)
assert(unsynced.loadResult==false, 'unsynced gadget must decline loading')
assert(#unsynced.includes==0 and unsynced.context==nil)
assert(unsynced.env.GG.CityParade==nil and unsynced.env.GG.unrelated=='preserve')
assert(next(unsynced.commands)==nil and not unsynced.env.gadget.Initialize,
    'unsynced load cannot install callbacks or mutate the controller')

local s=fixture(true)
local gadget=s.env.gadget
local info=gadget:GetInfo()
assert(info.layer==2 and info.enabled==true)
gadget:Initialize()
assert(#s.includes==8 and s.recovered==1)
assert(s.env.GG.CityParade==s.director)
assert(s.context.buildingTypes[10]==10 and s.context.buildingTypes[40]==40)
assert(not s.context.buildingTypes[20] and not s.context.buildingTypes[30],
    'ruins and scrap heaps cannot become shower emitters')
assert(s.houses[20]==20 and s.houses[30]==30,
    'filtering must not remove categories from a shared cultural table')
assert(s.context.commercialHologramTypes[70] and s.context.commercialHologramTypes[72],
    'commercial holo types must reach the director even without custom parameters')
assert(not s.context.commercialHologramTypes[71], 'parade projections must remain visible')
assert(s.context.commercialHologramTypes[73] and s.context.commercialHologramTypes[74],
    'native animated station ads must be included despite not using the neon renderer')
assert(s.holograms[71] and s.context.commercialHologramTypes~=s.holograms,
    'commercial filtering must preserve the shared hologram type table')

local command=assert(s.commands.parade)
assert(command('parade','start',{'start'},7)==true)
assert(command('parade','stop',{'stop'},7)==true)
assert(#s.previewCalls==0 and #s.stopCalls==0, 'non-cheat clients cannot start or stop a parade')
s.director.phase='touring'
s.director.vehicles={[101]={},[340]={}}
s.director.participants={[11]={},[19]={},[27]={}}
assert(command('parade','status',{'status'},7)==true)
assert(s.messages[#s.messages]:find('touring') and s.messages[#s.messages]:find('vehicles=2')
    and s.messages[#s.messages]:find('participants=3'), 'status reports live sparse counts')
command('parade','',{},7)
assert(s.messages[#s.messages]:find('touring'), 'empty command defaults to status')
assert(#s.previewCalls==0 and #s.stopCalls==0, 'status must be read-only without cheats')

s.cheats=true
s.frame=123456
command('parade','start',{'start'},7)
assert(#s.previewCalls==1 and s.previewCalls[1]==s.frame, 'preview receives the current simulation frame')
s.accepted=false; s.reason='city emergency'
s.frame=s.frame+30
command('parade',' START ',nil,7)
assert(#s.previewCalls==2 and s.previewCalls[2]==s.frame)
assert(s.messages[#s.messages]:find('city emergency'), 'failed preview explains the controller result')
command('parade','stop',{'stop'},7)
assert(#s.stopCalls==1 and #s.stopCalls[1]==1 and s.stopCalls[1][1]=='manual preview stop',
    'stop passes the agreed reason only; controller owns its frame clock')
command('parade','nonsense',{'nonsense'},7)
assert(#s.previewCalls==2 and #s.stopCalls==1, 'unknown commands cannot mutate the parade')
assert(s.messages[#s.messages]:find('Usage:'))

s.director.GetStatus=function() return 'preparing','route search: no safe circuit',nil end
command('parade','status',{'status'},7)
assert(s.messages[#s.messages]:find('preparing') and s.messages[#s.messages]:find('no safe circuit'))
s.director.GetStatus=function() return 'idle',nil,'preview route unavailable' end
command('parade','status',{'status'},7)
assert(s.messages[#s.messages]:find('last stop: preview route unavailable'))

gadget:GameFrame(90123)
gadget:UnitDamaged(77,5,0,16.5,true)
gadget:UnitDestroyed(88,9,0)
assert(s.frames[1]==90123)
assert(#s.damage[1]==2 and s.damage[1][1]==77 and s.damage[1][2]==16.5)
assert(s.destroyed[1]==88)
gadget:Shutdown()
assert(s.shutdowns==1 and s.removed[1]=='parade' and s.commands.parade==nil)
assert(s.env.GG.CityParade==nil and s.env.GG.unrelated=='preserve')

local replaced=fixture(true)
replaced.env.gadget:Initialize()
local replacement={}
replaced.env.GG.CityParade=replacement
replaced.env.gadget:Shutdown()
assert(replaced.env.GG.CityParade==replacement, 'shutdown cannot clear a newer controller owner')
assert(replaced.shutdowns==1 and replaced.removed[1]=='parade')
print('PASS: synced parade adapter, building and commercial-hologram filters, recovery, cheat gates, read-only status, preview time, callins and cleanup')
