-- Run from the repository root with Lua 5.1+.
-- The real wind gadget consumes the real shared policy and authoritative
-- per-piece records. No independently mocked timer or UnitDamaged controller.
local function loadEnv(path, env)
    if setfenv then
        local chunk=assert(loadfile(path));setfenv(chunk,env);return chunk()
    end
    return assert(loadfile(path,'t',env))()
end
local function fixture(windMax)
    local state={frame=0,emitted={},dead={},invalid={},missing={},windCalls=0,strength=8,
        echoes={},echoAttempts=0,breakEcho=false}
    local env=setmetatable({gadget={},GG={BuildingTable={[7]={x=0,z=0}}},
        Game={windMax=windMax},UnitDefs={},UnitDefNames={},
        gadgetHandler={IsSyncedCode=function() return true end},math={}}, {__index=_G})
    env._G=env
    for key,value in pairs(math) do env.math[key]=value end
    env.math.random=function(low,high) return low or .5 end
    env.Spring={
        GetGameFrame=function() return state.frame end,
        Echo=function(line)
            state.echoAttempts=state.echoAttempts+1
            if state.breakEcho then error('deliberate Echo failure') end
            local entry={line=line,emissions=#state.emitted}
            for key,value in line:gmatch('([^%s=]+)=([^%s]+)') do entry[key]=value end
            state.echoes[#state.echoes+1]=entry
        end,
        ValidUnitID=function(id) return (id==7 or id==8) and not state.invalid[id] end,
        GetUnitIsDead=function(id) return state.dead[id] or false end,
        GetUnitPieceList=function() return {'block1','block2','block3','block4'} end,
        GetUnitPiecePosDir=function(id,piece)
            assert(not state.invalid[id] and not state.dead[id],'queried a dead or invalid smoke unit')
            if not state.missing[piece] then return id*1000+piece,40,piece,0,1,0 end
        end,
        GetWind=function() state.windCalls=state.windCalls+1;return 1,0,0,state.strength end,
        SpawnCEG=function(name,x,y,z,dx,dy,dz,radius,damage)
            state.emitted[#state.emitted+1]={frame=state.frame,name=name,x=x,y=y,z=z,
                dx=dx,dy=dy,dz=dz,radius=radius,damage=damage}
        end,
    }
    env.VFS={}
    env.VFS.Include=function(path,scope)
        if path=='scripts/lib_mosaic.lua' then
            local configEnv=setmetatable({MOSAIC_CONFIG_ONLY=true}, {__index=env})
            local exported=loadEnv(path,configEnv)
            env.getBuildingDamageConfig=exported.getBuildingDamageConfig
            return exported
        end
        return loadEnv(path,scope or env)
    end
    loadEnv('luarules/gadgets/game_windsfx.lua',env)
    local config=env.getBuildingDamageConfig()
    function state:tick(frame) self.frame=frame;env.gadget:GameFrame(frame) end
    function state:record(piece,started)
        return {piece=piece,started=started,fireUntil=started+config.fireLifetimeFrames,
            smokeUntil=started+config.smokeLifetimeFrames,visible=true}
    end
    function state:count(name,first,last,piece)
        local count=0
        for _,effect in ipairs(self.emitted) do
            if effect.name==name and (not first or effect.frame>=first)
                and (not last or effect.frame<=last) and (not piece or effect.z==piece) then count=count+1 end
        end
        return count
    end
    function state:traces(stage,reason,piece,cycle)
        local matches={}
        for _,entry in ipairs(self.echoes) do
            if entry.stage=='building_smoke_'..stage and (not reason or entry.reason==reason)
                and (not piece or tonumber(entry.piece)==piece)
                and (cycle==nil or tonumber(entry.cycle)==cycle) then matches[#matches+1]=entry end
        end
        return matches
    end
    state.env,state.config=env,config
    return state
end

local f=fixture(0)
assert(f.env.gadget:GetInfo().enabled,'calm maps disabled authoritative building smoke')
assert(not f.env.gadget.UnitDamaged,'smoke still owns an independent damage refresh timer')
f.env.GG.BuildingDamageAnchor={[7]=2}
f:tick(6)
assert(#f.emitted==0,'stale last-hit anchor emitted smoke without an authoritative record')

f.env.GG.BuildingDamageEffects={[7]={[2]=f:record(2,12),[4]=f:record(4,12)}}
f:tick(12)
assert(f:count('civilbuildingdamage')==2 and f:count('vehsmokepillar')==2,
    'two live anchors did not each emit paper and smoke')
local starts=f:traces('anchor_started')
assert(#starts==2 and #f:traces('emission_started')==2,
    'accepted smoke anchors did not reach their happy-path traces')
for _,entry in ipairs(starts) do
    assert(tonumber(entry.cycle)==12 and tonumber(entry.started)==12
        and tonumber(entry.fireUntil)==12+f.config.fireLifetimeFrames
        and tonumber(entry.smokeUntil)==12+f.config.smokeLifetimeFrames,
        'anchor trace lost its fixed birth or lifetime fields')
end
for _,entry in ipairs(f:traces('emission_started')) do
    assert(entry.ceg=='vehsmokepillar' and entry.meaning=='spawn_call_returned' and entry.emissions>=2,
        'smoke trace claimed emission before its SpawnCEG call returned')
end
local steadyLogs=#f.echoes
f:tick(18)
assert(f:count('civilbuildingdamage')==2 and f:count('vehsmokepillar')==4,
    'unchanged records repeated paper bursts or failed to continue smoke')
assert(#f.echoes==steadyLogs,'steady smoke emission repeated its lifecycle traces')
f:tick(19)
assert(f:count('vehsmokepillar')==4,'smoke emitted outside the six-frame cadence')

f.env.GG.BuildingDamageEffects[7][2].visible=false
f:tick(24)
assert(f:count('vehsmokepillar',24,24,2)==0 and f:count('vehsmokepillar',24,24,4)==1,
    'a hidden anchor emitted smoke or hid the other slot')
assert(#f:traces('anchor_stopped','hidden_piece',2,12)==1,'hidden anchor had no concrete stop trace')
f.env.GG.BuildingDamageEffects[7][4]=nil
f:tick(30)
assert(f:count('vehsmokepillar',30)==0,'removed authoritative anchor kept emitting')
assert(#f:traces('anchor_stopped','record_removed',4,12)==1,'record removal had no stop trace')
f.env.GG.BuildingDamageEffects[7][2]=f:record(2,36)
f:tick(36)
assert(f:count('civilbuildingdamage')==3,'new burst timestamp did not receive its one paper burst')

f.env.GG.BuildingDamageEffects[8]={[4]=f:record(4,36)}
f.dead[7],f.invalid[8]=true,true
f:tick(42)
assert(f:count('vehsmokepillar',42)==0,'dead or invalid unit emitted smoke from stale metadata')
assert(#f:traces('anchor_stopped','dead_unit',2,36)==1,'dead unit had no concrete stop trace')
f.env.gadget:UnitDestroyed(7)
f.dead[7]=false
f.env.GG.BuildingDamageEffects[7][2]=f:record(2,48)
f:tick(48)
assert(f:count('civilbuildingdamage')==4,'unit destruction retained the previous burst state')
f.missing[2]=true
f:tick(54)
assert(f:count('vehsmokepillar',54)==0,'missing piece position spawned smoke')
assert(#f:traces('emission_skipped','missing_piece_position',2,48)==1,
    'missing piece position was not visible in the diagnostic path')
f.env.GG.BuildingDamageEffects=nil
f:tick(60)
assert(f:count('vehsmokepillar',60)==0,'removed snapshot left a private smoke timer running')
assert(f.windCalls==0,'calm-map smoke queried wind or divided by windMax')

-- Even if structure leaves an expired record in place, the consumer itself
-- stops at its fixed deadline. The last 60 frames reduce new-particle density.
local finite=fixture(0)
local effect=finite:record(2,0)
finite.env.GG.BuildingDamageEffects={[7]={[2]=effect}}
for frame=0,effect.smokeUntil+60,6 do finite:tick(frame) end
assert(finite:count('civilbuildingdamage')==1,'steady low health repeatedly restarted the paper burst')
assert(finite:count('vehsmokepillar',effect.smokeUntil)==0,'expired record continued smoke emission')
local fadeStart=effect.smokeUntil-finite.config.effectFadeFrames
local full=finite:count('vehsmokepillar',fadeStart-finite.config.effectFadeFrames,fadeStart-1)
local faded=finite:count('vehsmokepillar',fadeStart,effect.smokeUntil-1)
assert(full==finite.config.effectFadeFrames/6 and faded>0 and faded<full,
    'smoke emission did not fade during its final interval')
assert(effect.started==0 and effect.smokeUntil==finite.config.smokeLifetimeFrames,
    'consumer refreshed or rewrote the authoritative lifetime')
assert(#finite:traces('anchor_started',nil,2,0)==1 and #finite:traces('emission_started',nil,2,0)==1
    and #finite:traces('fade_started',nil,2,0)==1 and #finite:traces('anchor_stopped','expired',2,0)==1,
    'finite smoke did not trace its start, first emission, fade and expiry exactly once')
local fadeTrace=finite:traces('fade_started')[1]
assert(tonumber(fadeTrace.frame)>fadeStart and tonumber(fadeTrace.frame)<effect.smokeUntil
    and tonumber(fadeTrace.fade)<1 and tonumber(fadeTrace.remainingFrames)<finite.config.effectFadeFrames,
    'fade trace did not describe the first reduced-emission interval')
assert(#finite.echoes==4,'steady finite smoke produced additional trace spam')

-- Distinguish source replacement, invalid IDs, UnitDestroyed and an expired
-- source already removed by the earlier structural gadget in the same frame.
local stopped=fixture(0)
stopped.env.GG.BuildingDamageEffects={
    [7]={[2]=stopped:record(2,0)}, [8]={[4]=stopped:record(4,0)}}
stopped:tick(0)
stopped.invalid[8]=true
stopped.env.GG.BuildingDamageEffects[7][2]=stopped:record(2,6)
stopped:tick(6)
assert(#stopped:traces('anchor_stopped','replaced',2,0)==1
    and #stopped:traces('anchor_started',nil,2,6)==1,'replacement did not preserve the old and new birth cycles')
assert(#stopped:traces('anchor_stopped','invalid_unit',4,0)==1,'invalid unit had no concrete stop trace')
stopped.env.gadget:UnitDestroyed(7)
stopped.env.gadget:UnitDestroyed(7)
assert(#stopped:traces('anchor_stopped','unit_destroyed',2,6)==1,'UnitDestroyed stop was absent or repeated')
local removedAtExpiry=fixture(0)
removedAtExpiry.env.GG.BuildingDamageEffects={[7]={[2]=removedAtExpiry:record(2,0)}}
removedAtExpiry:tick(0)
removedAtExpiry.env.GG.BuildingDamageEffects[7][2]=nil
removedAtExpiry:tick(removedAtExpiry.config.smokeLifetimeFrames)
assert(#removedAtExpiry:traces('anchor_stopped','expired',2,0)==1,
    'same-frame authoritative expiry was misreported as unexplained record removal')

-- A logger exception must not change a single particle request or its frame.
local brokenEcho=fixture(0)
brokenEcho.breakEcho=true
brokenEcho.env.GG.BuildingDamageEffects={[7]={[2]=brokenEcho:record(2,0)}}
for frame=0,brokenEcho.config.smokeLifetimeFrames+60,6 do brokenEcho:tick(frame) end
assert(brokenEcho.echoAttempts==4 and #brokenEcho.echoes==0,'Echo failures were not contained on each lifecycle stage')
assert(#brokenEcho.emitted==#finite.emitted,'Echo failure changed the number of particle requests')
for index,expected in ipairs(finite.emitted) do
    local actual=brokenEcho.emitted[index]
    for key,value in pairs(expected) do assert(actual[key]==value,'Echo failure changed particle '..key) end
end

-- Preserve the existing windy-map paper effect: same cadence, threshold,
-- ceil(strength/windMax*10) count, random building/piece and +10 emitter lift.
local windy=fixture(10)
windy:tick(269)
assert(#windy.emitted==0,'newspaper emitted before its existing cadence')
windy:tick(270)
assert(windy:count('flyinggarbage')==8,'windy-map newspaper count changed')
for _,paper in ipairs(windy.emitted) do
    assert(paper.x==7001 and paper.y==50 and paper.z==1
        and paper.dx==0 and paper.dy==1 and paper.dz==0
        and paper.radius==0 and paper.damage==0,'newspaper placement or parameters changed')
end
windy.strength=7.5
windy:tick(540)
assert(windy:count('flyinggarbage')==8,'wind threshold became inclusive or was removed')
local gentle=fixture(1)
gentle:tick(270)
assert(gentle.windCalls==0 and #gentle.emitted==0,'old low-wind newspaper gate changed')
print('building damage smoke lifecycle: authoritative slots, finite fade, calm maps, newspaper and bounded diagnostics passed')
