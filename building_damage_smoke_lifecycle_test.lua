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
    local state={frame=0,emitted={},dead={},invalid={},missing={},windCalls=0,strength=8}
    local env=setmetatable({gadget={},GG={BuildingTable={[7]={x=0,z=0}}},
        Game={windMax=windMax},UnitDefs={},UnitDefNames={},
        gadgetHandler={IsSyncedCode=function() return true end},math={}}, {__index=_G})
    env._G=env
    for key,value in pairs(math) do env.math[key]=value end
    env.math.random=function(low,high) return low or .5 end
    env.Spring={
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
f:tick(18)
assert(f:count('civilbuildingdamage')==2 and f:count('vehsmokepillar')==4,
    'unchanged records repeated paper bursts or failed to continue smoke')
f:tick(19)
assert(f:count('vehsmokepillar')==4,'smoke emitted outside the six-frame cadence')

f.env.GG.BuildingDamageEffects[7][2].visible=false
f:tick(24)
assert(f:count('vehsmokepillar',24,24,2)==0 and f:count('vehsmokepillar',24,24,4)==1,
    'a hidden anchor emitted smoke or hid the other slot')
f.env.GG.BuildingDamageEffects[7][4]=nil
f:tick(30)
assert(f:count('vehsmokepillar',30)==0,'removed authoritative anchor kept emitting')
f.env.GG.BuildingDamageEffects[7][2]=f:record(2,36)
f:tick(36)
assert(f:count('civilbuildingdamage')==3,'new burst timestamp did not receive its one paper burst')

f.env.GG.BuildingDamageEffects[8]={[4]=f:record(4,36)}
f.dead[7],f.invalid[8]=true,true
f:tick(42)
assert(f:count('vehsmokepillar',42)==0,'dead or invalid unit emitted smoke from stale metadata')
f.env.gadget:UnitDestroyed(7)
f.dead[7]=false
f.env.GG.BuildingDamageEffects[7][2]=f:record(2,48)
f:tick(48)
assert(f:count('civilbuildingdamage')==4,'unit destruction retained the previous burst state')
f.missing[2]=true
f:tick(54)
assert(f:count('vehsmokepillar',54)==0,'missing piece position spawned smoke')
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
print('building damage smoke lifecycle: authoritative slots, hide/removal/death, finite fade, calm maps and newspaper passed')
