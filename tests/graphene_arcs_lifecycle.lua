-- Run from the repository root with Lua 5.1 or Lua 5.4.
-- Exercise the real Create, fallingDown and stationary-detection coroutines.
local unpack = unpack or table.unpack
local function loadEnv(path, env)
    local chunk = assert(loadfile(path, 't', env))
    if setfenv then setfenv(chunk, env) end
    return chunk()
end

local function fixture(options)
    options = options or {}
    local state = {registered={}, removed={}, registry={}, attached={}, detached={}, destroyed={},
        threads={}, shown={}, showCalls={}, cordMoves={}, moves={}, turns={},
        position={10,500,20}, ground=0, checks=2, frame=0}
    local pieces = {anchor=201, Infantrz=202, step=203}
    local groups, web = {Rotator={}, DownWardSpiral={}, Cord={}}, {}
    for i=1,156 do pieces['Rotator'..i]=i;groups.Rotator[i]=i;web[i]=true;state.shown[i]=true end
    for i=1,3 do
        local p=400+i;pieces['DownWardSpiral'..i]=p;groups.DownWardSpiral[i]=p
        web[p]=true;state.shown[p]=true
    end
    for i=1,12 do pieces['Cord'..i]=300+i;groups.Cord[i]=300+i end
    local env = setmetatable({unitID=7, script={}, Unitdefs={}, x_axis=1,y_axis=2,z_axis=3,
        CMD={MOVE=10}, GG={ParachutPassengers={[7]={id=8,x=10,y=500,z=20}}}}, {__index=_G})
    env._G=env
    local scale=options.scale or 1
    env.Spring = {
        ValidUnitID=function(id) return id==7 or id==8 end,
        GetUnitIsDead=function() return false end,
        GetUnitPosition=function() return unpack(state.position) end,
        GetUnitPieceMap=function() return pieces end,
        GetUnitPieceInfo=function(_,p)
            if p==pieces.step then
                if options.missingBounds then return end
                return {min={-3,-3,0},max={3,3,8}}
            end
            -- The discarded sheet bounds are deliberately enormous.
            return {min={-10000,-20000,-30000},max={10000,20000,30000}}
        end,
        GetUnitPieceMatrix=function()
            if options.missingMatrix then return end
            -- The imported step rotates its local +Z into world +Y.
            return scale,0,0,0, 0,0,-scale,0, 0,scale,0,0, scale,20*scale,-3*scale,1
        end,
        GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
        GetUnitPiecePosDir=function()
            -- A deliberately displaced mesh vertex (2,-1,5), not the pivot.
            return state.position[1]+3*scale,state.position[2]+25*scale,state.position[3]-2*scale,0,1,0
        end,
        GetUnitDefID=function() return 42 end,
        GetUnitIsTransporting=function() return {} end,
        GetUnitIsCloaked=function() return options.cloaked or false end,
        GetUnitCommands=function() return {{id=10,params={100,0,20}}} end,
        GetGroundHeight=function() return state.ground end,
        GetGameFrame=function() return state.frame end,
        SetUnitNoSelect=function(id,value) state.noSelect={id,value} end,
        UnitAttach=function(...) state.attached={...} end,
        UnitDetach=function(...) state.detached={...} end,
        DestroyUnit=function(...) state.destroyed={...} end,
        MoveCtrl={Enable=function(...) state.moveEnabled={...} end,
            SetPosition=function(id,x,y,z)
                assert(id==7);state.position={x,y,z};state.moves[#state.moves+1]={x,y,z}
            end},
        Echo=function(message) error(message) end,
    }
    env.VFS={Include=function(path) return loadEnv(path,env) end}
    env.include=function() end
    env.piece=function(name) return assert(pieces[name]) end
    env.getPieceTableByNameGroups=function() return groups end
    env.getOperativeTypeTable=function() return {[42]=true} end
    env.waitTillComplete=function(id) assert(id==7) end
    env.Sleep=function(ms) return coroutine.yield(ms) end
    env.StartThread=function(fn,...)
        local thread={fn=fn,co=coroutine.create(fn),arguments={...}}
        state.threads[#state.threads+1]=thread
        return thread
    end
    env.Show=function(p) state.shown[p]=true;state.showCalls[#state.showCalls+1]=p end
    env.Hide=function(p) state.shown[p]=nil end
    env.showT=function(list) for _,p in ipairs(list) do env.Show(p) end end
    env.hideT=function(list) for _,p in ipairs(list) do env.Hide(p) end end
    env.Turn=function(...) state.turns[#state.turns+1]={...} end
    env.Spin=function(p) error('removed canopy animation started a spin on '..p) end
    env.isUnitAlive=function() return not options.deadPassenger end
    env.isPieceAboveGround=function(id,p,height)
        assert(id==7 and p==pieces.anchor and height==15)
        state.checks=state.checks-1;return state.checks>=0
    end
    env.WMove=function(...) state.cordMoves[#state.cordMoves+1]={...} end
    local config=env.VFS.Include('luarules/gadgets/include/smoke_ribbon_config.lua')
    if not options.noProvider then
        env.GG.SmokeRibbon={Set=function(id,slot,p,settings)
            local record=config.Normalize(id,p,settings)
            state.registered[#state.registered+1]={slot=slot,record=record}
            state.registry[slot]=record
            return true
        end,Remove=function(id,slot)
            assert(id==7 and state.registry[slot], 'removed an unregistered canopy slot')
            state.registry[slot]=nil;state.removed[#state.removed+1]=slot
        end}
    end
    loadEnv('scripts/parachutscript.lua',env)
    function state.resume(thread)
        local ok,ms=coroutine.resume(thread.co,unpack(thread.arguments or {}));thread.arguments=nil
        assert(ok,ms);state.frame=state.frame+(ms or 0)*0.03
    end
    function state.assertWebHidden()
        for p in pairs(web) do assert(not state.shown[p], 'polygon canopy was resurrected: '..p) end
        for _,p in ipairs(state.showCalls) do assert(not web[p], 'legacy animation showed a polygon sheet: '..p) end
    end
    function state.createAndDeploy()
        env.script.Create()
        assert(state.noSelect[1]==7 and state.noSelect[2] and state.moveEnabled[1]==7,
            'canopy replacement changed chute movement/selectability setup')
        state.assertWebHidden()
        assert(#state.threads==2 and state.threads[1].fn==env.fallingDown
            and state.threads[2].fn==env.detectStationary,'legacy canopy animation is still scheduled')
        state.resume(state.threads[1]);state.resume(state.threads[1])
    end
    return state,env,pieces,groups
end

local s,env,pieces,groups=fixture()
s.createAndDeploy()
assert(#s.registered==12,'chute must use eight mist canopy sources and four electrical sources')
local black,arcs={},{}
for _,effect in ipairs(s.registered) do
    local r=effect.record
    assert(r.piece==pieces.step,'effect still follows a hidden animated web remnant')
    if r.mode=='canopy' then black[#black+1]=r
    elseif r.mode=='electric' then arcs[#arcs+1]=r
    else error('chute registered an unrelated material: '..tostring(r.mode)) end
end
assert(#black==8 and #arcs==4,'canopy/electric source counts changed')
local previousRadius=48 -- This fixture's 8-unit support previously used a 6x radius.
local expectedRadius=previousRadius*2
for i,r in ipairs(black) do
    assert(r.strands==2,'dense canopy exceeded its bounded sixteen-strip mesh budget')
    assert(r.emission[1]==0 and r.emission[2]>1,'canopy lost its dark roots or luminous tips')
    for axis=1,4 do assert(r.sourceGlow[axis]==0,'black canopy gained source glow') end
    assert(r.colorStart[1]==0 and r.colorStart[2]==0 and r.colorStart[3]==0 and r.colorStart[4]>0,
        'graphene roots must remain black with visible material coverage')
    assert(r.colorEnd[3]>r.colorEnd[1] and r.colorEnd[1]>r.colorEnd[2] and r.colorEnd[4]>0,
        'graphene tips lost electric violet-blue colour')
    assert(r.windAffected and r.motionAffected and r.windInfluence>0 and r.motionInfluence>0,
        'canopy stopped responding to wind or the passenger movement')
    assert(r.speed>0 and r.curl>0.3 and r.stiffness<0.72,
        'canopy retained the nearly rigid old ribbon settings')
    assert(r.directionSpace=='piece' and r.direction[3]>0,'black canopy does not rise above the support')
    -- Put back the emitted mesh vertex to recover the desired local target.
    local tx,ty=r.rootOffset[1]+2,r.rootOffset[2]-1
    local radial=math.sqrt(tx^2+ty^2)
    assert(math.abs(radial-expectedRadius)<1e-8 and r.rootOffset[3]+5==8,
        'canopy did not double its asset-scaled radius or lost the emitter-vertex correction')
    assert(r.length>radial*1.7 and r.length<radial*1.9 and r.width>radial*.6 and r.width<radial*1.6,
        'black mist sheets lost their broad, bounded canopy proportions')
    assert(r.direction[1]*tx+r.direction[2]*ty<0,
        'canopy sheets point away from the suspended passenger')
    for j=1,i-1 do
        local other=black[j].rootOffset
        assert((other[1]-r.rootOffset[1])^2+(other[2]-r.rootOffset[2])^2>(expectedRadius*.7)^2,
            'mist canopy sheets collapsed onto one rim attachment')
    end
end
for i,a in ipairs(arcs) do
    local rim=black[i*2-1]
    for axis=1,3 do assert(a.rootOffset[axis]==rim.rootOffset[axis], 'electric source detached from its alternating canopy rim') end
    assert(a.mode=='electric' and a.strands==4 and math.abs(a.length-expectedRadius*1.5)<1e-8,
        'electrical fan lost its bounded canopy scale')
    assert(a.directionSpace=='world' and a.direction[1]==0 and a.direction[2]==1 and a.direction[3]==0,
        'support rotation pointed the electrical plume downward')
    assert(a.colorStart[2]>a.colorStart[1]*4 and a.colorStart[3]>a.colorStart[2], 'electrical source lost cyan')
    assert(a.colorEnd[1]>a.colorEnd[2]*4 and a.colorEnd[3]>a.colorEnd[1], 'electrical tail lost violet')
end
assert(s.attached[1]==7 and s.attached[2]==8 and s.attached[3]==pieces.step,
    'visual replacement changed the live passenger attachment')
assert(math.abs(s.position[1]-11.52)<1e-8 and s.position[2]==499.5,
    'visual replacement changed commanded travel or the travelling drop rate')
for _,p in ipairs(groups.Cord) do assert(s.shown[p],'suspension cord was removed with the canopy web') end
assert(not s.shown[pieces.Infantrz],'uncloaked passenger gained a duplicate infantry mesh')

-- Stationary descent used to resurrect all three enormous spiral meshes.
local stationary=s.threads[2]
for _=1,53 do s.resume(stationary) end
assert(env.boolStationary and env.dropRate==env.stationaryDropRate,'stationary descent rate changed')
s.assertWebHidden()
env.x=env.x+10;s.resume(stationary)
assert(not env.boolStationary and env.dropRate==env.travellingDropRate,'movement no longer restores travelling descent')
s.ground=-1;s.resume(stationary)
assert(env.dropRate==0.00000001,'water descent behavior changed')
s.ground=0;env.dropRate=env.travellingDropRate
while coroutine.status(s.threads[1].co)~='dead' do s.resume(s.threads[1]) end
assert(s.detached[1]==8 and s.destroyed[1]==7,'landing teardown changed')
assert(#s.removed==12 and next(s.registry)==nil,'landing left black or electrical ribbons registered')
assert(#s.cordMoves==11,'landing lost the existing suspension-cord retraction')
for i,move in ipairs(s.cordMoves) do
    assert(move[1]==groups.Cord[i+1] and move[2]==2 and move[3]==(i+1)*-15 and move[4]==900,
        'landing changed a suspension-cord movement')
end
s.assertWebHidden()
env.script.Killed(1,1);assert(#s.removed==12,'later destruction removed the same ribbons twice')

local scaled=fixture({scale=2});scaled.createAndDeploy()
for i,effect in ipairs(scaled.registered) do
    local original=s.registered[i].record
    assert(effect.record.length==original.length*2 and effect.record.width==original.width*2,
        'imported model scale was lost or applied twice to effect dimensions')
    for axis=1,3 do assert(effect.record.rootOffset[axis]==original.rootOffset[axis],
        'piece-local offsets were scaled before the renderer applies the imported matrix') end
end
local cloaked,cloakEnv,cloakPieces=fixture({cloaked=true});cloaked.createAndDeploy()
assert(cloaked.shown[cloakPieces.Infantrz], 'cloaked operative lost the existing infantry stand-in')
assert(cloakEnv.script.Killed(1,1)==1 and #cloaked.removed==12 and next(cloaked.registry)==nil,
    'killed chute left its canopy registered')
for _,option in ipairs({'missingBounds','missingMatrix','noProvider','deadPassenger'}) do
    local settings={[option]=true};local state=fixture(settings);state.createAndDeploy()
    while coroutine.status(state.threads[1].co)~='dead' do state.resume(state.threads[1]) end
    assert(state.destroyed[1]==7 and next(state.registry)==nil,'optional canopy failure stranded a parachute: '..option)
    if option=='deadPassenger' then assert(#state.attached==0,'dead passenger was attached')
    else assert(state.attached[2]==8 and state.detached[1]==8,'missing VFX changed transport behavior: '..option) end
    state.assertWebHidden()
end
print('PASS: real chute Create/fall/stationary/landing, 159 polygon pieces stay hidden, doubled black mist canopy with sixteen strips, four cyan/violet rim sources, imported scale, emitter correction, cords, passenger movement/cloak and twelve-slot teardown')
