-- The fixture is the map's unmodified pure weather schedule. The production
-- gadget imports it directly from VFS.MAP, not from this test copy.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function compile(s,env)
    if setfenv then local f=assert(loadstring(s));setfenv(f,env);return f end
    return assert(load(s,'weather masks','t',env))
end
local function scriptMask(path,shared)
    local source=read(path)
    local a=assert(source:find('local MilitiaMask = nil',1,true))
    local b=assert(source:find('local LowArm1',a,true))
    local result={shows=0,hides=0}
    local env=setmetatable({GG=shared},{__index=_G})
    env.Show=function(p) assert(p==7);result.visible=true;result.shows=result.shows+1 end
    env.Hide=function(p) assert(p==7);result.visible=false;result.hides=result.hides+1 end
    local suffix=[[
return {init=function(p,base) MilitiaMask=p;setCivilianMask(base) end,
    set=setCivilianMask,refresh=updateWeatherMask,
    die=function() boolDying=true end}
]]
    result.api=compile('local boolDying=false\n'..source:sub(a,b-1)..suffix,env)()
    result.env={updateWeatherMask=result.api.refresh}
    result.scriptEnv=env
    return result
end

-- Execute the actual outfit builder's non-normal-day branch too: a civilian
-- masking up during anarchy must not lose that mask when the storm ends.
for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
    local state={GlobalGameState='anarchy',CivilianWeatherMasks=true}
    local mask=scriptMask(path,state);mask.api.init(7,false)
    local env=mask.scriptEnv
    env.GameConfig={game={states={normal='normal'}}}
    env.bodyConfig={boolArmed=false,boolLoaded=false}
    env.TablesOfPiecesGroups={}
    env.randChance=function() return false end
    env.math=setmetatable({random=function() return 0 end},{__index=math})
    env.hideAll=function() mask.visible=false end
    local show=env.Show
    env.Show=function(piece) if piece==7 then show(piece) end end
    env.showT=function() end;env.showOnePiece=function() end
    local source=read(path)
    local a=assert(source:find('function bodyBuild()',1,true))
    local b=assert(source:find('function carriesShoppingBag()',a,true))
    compile(source:sub(a,b-1),env)();env.bodyBuild()
    assert(mask.visible,'anarchy outfit puts its mask on during storm')
    state.CivilianWeatherMasks=false;mask.api.refresh()
    assert(mask.visible,'weather clearing must not remove an anarchy mask')
end

local shared={}
for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
    local mask=scriptMask(path,shared)
    mask.api.init(7,false);assert(not mask.visible,'unmasked outfit remains unchanged in clear weather')
    shared.CivilianWeatherMasks=true;mask.api.refresh();assert(mask.visible,'storm adds mask')
    mask.api.set(false);assert(mask.visible,'prop cleanup cannot remove a required weather mask')
    mask.api.set(true);shared.CivilianWeatherMasks=false;mask.api.refresh()
    assert(mask.visible,'weather clearing preserves ordinary outfit/militia/protest mask')
    mask.api.set(false);assert(not mask.visible,'unmasked outfit restored')
    shared.CivilianWeatherMasks=true;mask.api.init(7,false);assert(mask.visible,'new civilian masks up mid-event')
    mask.api.set(true);mask.api.die();local changes=mask.shows+mask.hides
    shared.CivilianWeatherMasks=false;mask.api.refresh();mask.api.set(false)
    assert(mask.shows+mask.hides==changes,'weather does not rewrite death presentation')
    local missing=scriptMask(path,shared);missing.api.init(nil,false)
    shared.CivilianWeatherMasks=true;missing.api.refresh();assert(missing.shows+missing.hides==0,'missing optional piece is safe')
    shared.CivilianWeatherMasks=false
end

local function world(mode,mapPresent)
    local w={calls=0,scans=0,frame=0,units={}}
    GG={};Game={mapChecksum=70427,mapName='MOSAIC_LastDayOfDubai_V3'};UnitDefs={
        [1]={id=1,name='civilian_arab0'},[2]={id=2,name='civilian_western0'},
        [3]={id=3,name='civilianagent'},[4]={id=4,name='operativeasset'}}
    UnitDefNames={};for _,def in pairs(UnitDefs) do UnitDefNames[def.name]=def end
    function w:add(id,def,baseline)
        local mask=scriptMask(def==3 and 'scripts/civilianagentscript.lua' or 'scripts/civilianscript.lua',GG)
        self.units[id]={def=def,mask=mask}
        if self.gadget then self.gadget:UnitCreated(id,def) end
        mask.api.init(7,baseline or false)
    end
    w:add(10,1);w:add(11,2,true);w:add(12,3);w:add(13,4)
    Spring={GetMapOptions=function() return {dhubai_weather=mode} end,
        GetGameFrame=function() return w.frame end,
        GetAllUnits=function() w.scans=w.scans+1;return {10,11,12,13} end,
        GetUnitDefID=function(id) return w.units[id].def end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return w.units[id].dead end,
        UnitScript={GetScriptEnv=function(id) return w.units[id].mask.env end,
            CallAsUnit=function(id,fn) w.calls=w.calls+1;fn() end}}
    gadget={};gadgetHandler={IsSyncedCode=function() return true end}
    function getCultureUnitModelTypes(culture,kind)
        assert(culture=='international' and kind=='civilian');return {[1]=1,[2]=2}
    end
    VFS={MAP='map',FileExists=function(path,scope)
        assert(path=='LuaUI/Widgets_Map/Include/dhubai_weather.lua' and scope=='map')
        return mapPresent~=false
    end,Include=function(path,env,scope)
        if scope=='map' then return dofile('tests/fixtures/weather/dhubai_weather.lua') end
        if path=='scripts/lib_mosaic.lua' or path=='scripts/lib_UnitScript.lua' then return end
        return dofile(path)
    end}
    local loaded=dofile('luarules/gadgets/game_civilian_weather_masks.lua')
    if loaded==false then w.disabled=true;return w end
    w.gadget=gadget;gadget:Initialize()
    function w:frameAt(frame) self.frame=frame;self.gadget:GameFrame(frame) end
    return w
end
for _,mode in ipairs({'smog','sandstorm'}) do
    local w=world(mode)
    assert(GG.CivilianWeatherMasks and w.units[10].mask.visible and w.units[11].mask.visible and w.units[12].mask.visible)
    assert(not w.units[13].mask.visible,'military operative is not a civilian mask consumer')
    local calls=w.calls
    for frame=1,600 do w:frameAt(frame) end
    assert(w.calls==calls and w.scans==1,'steady weather performs no population scans or per-civilian polling')
    w:add(20,1);assert(w.units[20].mask.visible,'Create applies mask without waiting for next weather transition')
    w.gadget:UnitDestroyed(10);w.units[10]=nil
    w.gadget:Shutdown()
    assert(not w.units[12].mask.visible and not w.units[20].mask.visible and w.units[11].mask.visible,'shutdown restores baseline masks')
end
for _,mode in ipairs({'fog','off'}) do
    local w=world(mode);assert(not GG.CivilianWeatherMasks and not w.units[10].mask.visible and w.units[11].mask.visible)
end
local absent=world('automatic',false);assert(absent.disabled and absent.scans==0,'other maps require no weather work')
local w=world('automatic')
local reference=dofile('tests/fixtures/weather/dhubai_weather.lua').New(Game.mapChecksum)
local expected=false;local seen={}
for frame=0,28800*40,30 do
    local weather,strength=reference.Evaluate(frame,0,'automatic')
    seen[weather]=true
    expected=(weather=='smog' or weather=='sandstorm') and strength>=(expected and .02 or .05)
    w:frameAt(frame)
    assert(GG.CivilianWeatherMasks==expected,'mask state must match the actual map event schedule')
    assert(w.units[10].mask.visible==expected and w.units[12].mask.visible==expected,'both civilian kinds follow weather')
    assert(w.units[11].mask.visible,'automatic weather must preserve a permanent mask')
end
assert(seen.clear and seen.fog and seen.smog and seen.sandstorm,'exercise all actual automatic weather modes')
assert(w.scans==1,'automatic events never rescan the world')
print('PASS: map-scheduled smog/sandstorm masks, clear/fog/off, births/deaths, preserved outfits, shared deterministic weather and transition-only updates')
