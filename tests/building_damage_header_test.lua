-- Exercise the actual house and its includes through the production header.
-- A plain loadfile fixture misses header-local animation functions entirely.
local function read(path)
    local f = assert(io.open(path)); local source = f:read('*a'); f:close(); return source
end
local function compile(source, name, env)
    if setfenv then
        local chunk = assert(loadstring(source, name)); setfenv(chunk, env); return chunk
    end
    return assert(load(source, name, 't', env))
end
local function noop() end
local function copy(source) local result={};for k,v in pairs(source) do result[k]=v end;return result end
local header = read('gamedata/unit_script_header.lua')
local defs = {
    [1]={name='house_arab0',customParams={}},
    [2]={name='tank',customParams={}},
    [3]={name='house_asian_split',customParams={house_asian_base='house_asian0'}},
    [4]={name='house_western0',customParams={cloud_piece_volumes=1}},
}
local configEnv = setmetatable({MOSAIC_CONFIG_ONLY=true}, {__index=_G})
local properties = compile(read('scripts/lib_mosaic.lua'),'scripts/lib_mosaic.lua',configEnv)()
local structural = properties.getStructuralBuildingTypeTable(defs)
assert(structural[1] and structural[3] and structural[4] and not structural[2])
local includeCache, compiledIncludes = {}, {}
local motionSource = [[
function script.testPose(p, x, height, z)
    Move(p, 1, x, 0); Move(p, 2, height, 0); Move(p, 3, z, 0)
    Turn(p, 1, 0.1, 0); Turn(p, 2, 0.2, 0); Turn(p, 3, 0.8, 0)
    Spin(p, 3, 0.25, 0)
end
function script.testLateAnimation(p)
    Show(p); Hide(p); Move(p, 2, 100, 10); Turn(p, 1, 1, 1); Spin(p, 3, 1, 1)
end
script.testPrimitives={Show=Show,Hide=Hide,Move=Move,Turn=Turn,Spin=Spin}
]]

local function fixture(id, defID)
    local state={shown={},positions={},moves={},turns={},spins={},fires={},removedFires={},rules={},cloudShows=0,cloudHides=0,
        frame=0,healthReads=0}
    local names={center=1,block1=2,block2=3,block3=4,block4=5,block5=6,block6=7,base=8}
    local raw = {
        Show=function(p) assert(p);state.shown[p]=true end,
        Hide=function(p) assert(p);state.shown[p]=nil end,
        Move=function(p,axis,goal,speed)
            state.positions[p]=state.positions[p] or {0,0,0}
            state.positions[p][axis]=goal
            state.moves[#state.moves+1]={piece=p,axis=axis,goal=goal,speed=speed}
        end,
        Turn=function(p,axis,goal,speed) state.turns[#state.turns+1]={piece=p,axis=axis,goal=goal,speed=speed} end,
        Spin=function(p,axis,speed) state.spins[#state.spins+1]={piece=p,axis=axis,speed=speed} end,
        StopSpin=noop,Sleep=noop,WaitForMove=noop,WaitForTurn=noop,
        StartThread=noop,SetSignalMask=noop,Signal=noop,
    }
    local env=setmetatable({unitID=id,unitDefID=defID,UnitDefs=defs,script={},
        buildingDamageEnabled=structural[defID] or false,MOSAIC_CONFIG_ONLY=true,
        Game={mapSizeX=8192,mapSizeZ=8192},GG={},VFS={},table=copy(table)}, {__index=_G})
    env._G=env;env.table.getn=env.table.getn or function(t)return #t end
    env.Spring={UnitScript=raw,Echo=noop,GetUnitTeam=function()return 0 end,
        GetGaiaTeamID=function()return 0 end,GetGameFrame=function()return state.frame end,
        ValidUnitID=function(unit)return unit==id and not state.destroyed end,
        GetUnitIsDead=function(unit)return unit~=id or state.destroyed==true end,
        GetUnitPosition=function()return 100,0,200 end,GetGroundHeight=function()return 0 end,
        GetUnitPieceMap=function()return names end,GetUnitPieceInfo=function()return {children={}}end,
        GetUnitPiecePosDir=function(_,p)
            local at=state.positions[p] or {0,0,0};return 100+at[1],at[2],200+at[3],0,1,0
        end,
        GetUnitHealth=function()state.healthReads=state.healthReads+1;return 400,1000 end,
        SetUnitNanoPieces=noop,SpawnCEG=noop,SetUnitRulesParam=function(_,key,value)state.rules[key]=value end,
        DestroyUnit=function()state.destroyed=true end,
    }
    -- Load the actual synced provider and normalizer in their own gadget env.
    -- Capture requests while preserving real validation, registry and revisions.
    local provider=setmetatable({gadget={},GG=env.GG,Spring=env.Spring,VFS={},
        gadgetHandler={IsSyncedCode=function()return true end,AddChatAction=noop,RemoveChatAction=noop},
        SendToUnsynced=noop}, {__index=_G})
    provider._G=provider
    provider.VFS.Include=function(path,scope)return compile(read(path),path,scope or provider)()end
    compile(read('luarules/gadgets/gfx_smoke_ribbons.lua'),'gfx_smoke_ribbons.lua',provider)()
    provider.gadget:Initialize()
    local api=env.GG.SmokeRibbon
    local setRibbon,removeRibbon=api.Set,api.Remove
    api.Set=function(unit,slot,piece,options)
        state.fires[#state.fires+1]={unit=unit,slot=slot,piece=piece,options=options}
        return setRibbon(unit,slot,piece,options)
    end
    api.Remove=function(unit,slot)
        state.removedFires[#state.removedFires+1]={unit=unit,slot=slot}
        return removeRibbon(unit,slot)
    end
    state.provider=provider
    env.getGameConfig=function()return {game={culture='international'}}end
    env.getCultureUnitModelTypes=function()return {}end
    env.piece=function(name)return assert(names[name],name)end
    env.VFS.Include=function(path,scope) return compile(read(path),path,scope or env)() end
    env.include=function(name)
        local source=includeCache[name]
        if not source then source=header..'\n'..read('scripts/'..name);includeCache[name]=source end
        local chunk
        if setfenv then
            -- Production Lua 5.1 reuses parsed chunks and swaps their owning env.
            chunk=compiledIncludes[name] or assert(loadstring(source,name))
            compiledIncludes[name]=chunk;setfenv(chunk,env)
        else
            chunk=compile(source,name,env)
        end
        local result=chunk()
        if name=='lib_building_damage.lua' then state.damage=result end
        return result
    end
    if env.buildingDamageEnabled then
        -- This is the real house script; showOne and showT exercise direct and
        -- included-header aliases without mocking the procedural asset builder.
        compile(header..'\n'..read('scripts/house_arab_script.lua'),'house_arab_script.lua',env)()
        state.show=function()env.showOne({names.base},true);env.showT(env.ToShowTable)end
    end
    compile(header..'\n'..motionSource,'header_motion_driver',env)()
    state.env,state.raw=env,raw
    return state
end

local function assemble(state)
    local e=state.env
    for column=0,1 do for floor=0,2 do
        local p=2+column*3+floor
        -- Deliberately different height and Z values expose swapped-axis caches.
        e.script.testPose(p,column*20,floor*10,100)
        e.houseAddDestructionTable(e.LevelPieces,floor+1,p,column*20,100,floor*10)
        e.ToShowTable[#e.ToShowTable+1]=p
    end end
    state.damage.initialize(e.LevelPieces,e.ToShowTable,{},nil,10,20,1)
    state.show()
end

local function update(state, hits, frame)
    state.frame=frame
    return state.env.BuildingBlockDamaged(hits,frame)
end

local a=fixture(42,1)
assemble(a)
assert(a.shown[3] and a.rules.building_structural_blocks==6)
a.env.hideHouse()
assert(not update(a,{{x=100,y=10,z=300,damage=100}},0) and #a.fires==0,
    'hidden geometry remained eligible for damage')
assert(a.provider.SmokeRibbonRevision==0 and not next(a.provider.SmokeRibbonRecords),
    'unselected damage modified the synced flame registry')
a.show()
assert(update(a,{{x=100,y=10,z=300,damage=134}},6),
    'real header Show/showT calls bypassed structural visibility tracking')
assert(#a.fires==1 and a.fires[1].unit==42 and a.fires[1].piece==3,
    'selected damaged block never reached the real SmokeRibbon request')
local fire=a.provider.SmokeRibbonRecords['42:block_fire_3']
assert(fire and fire.unitID==42 and fire.piece==3 and fire.enabled==true,
    'damaged-block fire was rejected or registered on the wrong anchor')
assert(fire.mode=='smoke' and fire.scale==1 and type(fire.rootOffset[1])=='number',
    'synced fire record did not receive normalized defaults')
assert(fire.directionSpace=='world' and fire.direction[1]==0 and fire.direction[2]==1 and fire.direction[3]==0,
    'synced fire record lost its fixed upward direction')
assert(fire.colorStart~=a.fires[1].options.colorStart and a.provider.SmokeRibbonRevision==1,
    'provider did not publish a normalized copy and revision')
assert(a.env.GG.BuildingDamageAnchor[42]==3)
local effect=a.env.GG.BuildingDamageEffects[42][3]
assert(effect.piece==3 and effect.visible and effect.started==6 and effect.fireUntil==246 and effect.smokeUntil==306,
    'authoritative effect snapshot lost its finite lifetime or anchor')
assert(fire.endFrame==246 and fire.fadeFrames==60, 'flame lifetime/fade did not reach the real normalized record')
assert(update(a,{},12))
assert(a.rules.building_detached_blocks==2 and a.shown[3] and a.shown[4],
    'supported roof should settle with the struck block before hiding')
local falls=0
for _,move in ipairs(a.moves) do if move.speed and move.speed>0 then
    falls=falls+1
    assert(move.axis==2,'fall used the header rotation alias instead of the house height axis')
    assert((move.piece==3 and move.goal==2) or (move.piece==4 and move.goal==15.5),
        'fall lost the authored height or used a horizontal offset')
end end
assert(falls==2,'native movement bypass failed or moved a block more than once')
for _,turn in ipairs(a.turns) do if turn.speed and turn.speed>0 then
    local authored=turn.axis==1 and 0.1 or 0.2
    assert(turn.axis==1 or turn.axis==2,'collapse replaced the authored yaw axis')
    assert(math.abs(turn.goal-authored)<=math.rad(5)+1e-9,'collapse lost the authored rotation')
end end
local beforeMoves,beforeTurns,beforeSpins=#a.moves,#a.turns,#a.spins
a.env.script.testLateAnimation(3)
assert(#a.moves==beforeMoves and #a.turns==beforeTurns and #a.spins==beforeSpins,
    'a header-local animation overrode detached geometry')
assert(update(a,{},18), 'retained visible fire stopped receiving lifetime ticks')
a.show();a.env.script.testLateAnimation(3)
assert(a.shown[3] and not a.shown[4] and a.shown[2], 'a later animation changed the retained visibility snapshot')
assert(a.rules.building_remnant_blocks==1 and a.env.IsBuildingPieceDetached(3)
    and a.env.IsBuildingPieceVisible(3), 'retained section stayed structurally available or became invisible')
local healthReads=a.healthReads
assert(update(a,{},240) and a.provider.SmokeRibbonRecords['42:block_fire_3'])
assert(a.healthReads==healthReads, 'effects-only tick rescanned the structure')
assert(update(a,{},246) and #a.removedFires==1, 'fire did not stop at its fixed deadline')
assert(not a.provider.SmokeRibbonRecords['42:block_fire_3'] and a.provider.SmokeRibbonRevision==2,
    'fire expiry did not remove the actual synced record and publish its revision')
assert(a.env.GG.BuildingDamageEffects[42][3]==effect and update(a,{},300),
    'smoke did not retain the original lifetime after fire expiry')
assert(not update(a,{},306) and not a.env.GG.BuildingDamageEffects[42] and not a.env.GG.BuildingDamageAnchor[42],
    'smoke expiry left a stale anchor or permanent update loop')
assert(not update(a,{},600) and #a.fires==1 and a.shown[3], 'low health rekindled an old remnant')
-- Reused include source must bind each unit's hooks and private support state.
local b=fixture(84,3);assemble(b)
assert(update(b,{{piece=3,damage=134}},6))
assert(b.fires[1].unit==84 and a.rules.building_detached_blocks==2)
assert(b.rules.building_detached_blocks==0 and b.shown[3])
assert(b.provider.SmokeRibbonRecords['84:block_fire_3'].piece==3 and not next(a.provider.SmokeRibbonRecords),
    'another unit reused the first unit\'s flame registry state')

-- Explicitly hidden live pieces immediately lose both their synced ribbon and
-- smoke snapshot. An existing effect cannot be extended by another small hit.
local hidden=fixture(43,1);assemble(hidden)
assert(update(hidden,{{piece=3,damage=10}},6))
local original=hidden.env.GG.BuildingDamageEffects[43][3]
assert(update(hidden,{{piece=3,damage=10}},12))
assert(hidden.env.GG.BuildingDamageEffects[43][3]==original and #hidden.fires==1
    and original.started==6 and original.fireUntil==246, 'a repeated hit renewed an active effect')
hidden.env.script.testPrimitives.Hide(3)
assert(not hidden.shown[3] and not hidden.env.IsBuildingPieceVisible(3)
    and not hidden.env.GG.BuildingDamageEffects[43] and not hidden.env.GG.BuildingDamageAnchor[43],
    'explicit hide left a visible-effect snapshot or compatible anchor')
assert(not next(hidden.provider.SmokeRibbonRecords) and hidden.provider.SmokeRibbonRevision==2
    and not update(hidden,{},18), 'explicit hide did not remove the actual provider record immediately')

-- The disappearing deterministic outcome removes its fire at fall completion,
-- while the selected upper remnant keeps its pose and rejects Hide/Show calls.
local falling=fixture(43,1);assemble(falling)
assert(update(falling,{{piece=3,damage=134}},6));assert(update(falling,{},12))
assert(not update(falling,{},18))
assert(not falling.shown[3] and falling.shown[4] and not next(falling.provider.SmokeRibbonRecords)
    and falling.provider.SmokeRibbonRevision==2, 'disappearing block kept fire or selected upper remnant disappeared')
assert(not falling.env.GG.BuildingDamageEffects[43] and not falling.env.GG.BuildingDamageAnchor[43])
falling.env.script.testLateAnimation(4);assert(falling.shown[4] and falling.positions[4][2]==2)
falling.damage.collapse(falling.env.LevelPieces,falling.env.ToShowTable)
assert(not next(falling.shown) and falling.rules.building_remnant_blocks==0)

-- Fire and smoke share two anchors. New hits cannot evict live effects; once a
-- visible piece is hidden, its freed slot may be used by a later real impact.
local budget=fixture(44,1);assemble(budget)
assert(update(budget,{{piece=2,damage=1},{piece=3,damage=1},{piece=5,damage=1}},6))
local map=budget.env.GG.BuildingDamageEffects[44]
assert(map[2] and map[3] and not map[5] and #budget.fires==2
    and budget.provider.SmokeRibbonRevision==2, 'effect limit evicted or exceeded the two live slots')
local previous=map[3]
budget.env.script.testPrimitives.Hide(2)
assert(update(budget,{{piece=5,damage=1}},12))
assert(map[3]==previous and previous.started==6 and map[5].started==12 and not map[2]
    and #budget.fires==3 and budget.provider.SmokeRibbonRevision==4,
    'freed effect slot was not reused without refreshing the surviving anchor')
budget.damage.collapse(budget.env.LevelPieces,budget.env.ToShowTable)
assert(not budget.env.GG.BuildingDamageEffects[44] and not next(budget.provider.SmokeRibbonRecords),
    'full collapse retained live effects on original pieces')

-- Cloud hooks may be installed after the structural library. Compose at call time.
local cloud=fixture(126,4)
cloud.env.CloudPieceShow=function(p)cloud.cloudShows=cloud.cloudShows+1;cloud.raw.Show(p)end
cloud.env.CloudPieceHide=function(p)cloud.cloudHides=cloud.cloudHides+1;cloud.raw.Hide(p)end
assemble(cloud)
assert(cloud.cloudShows>0, 'structural Show bypassed a live cloud hook')
cloud.env.hideHouse()
assert(cloud.cloudHides>0 and not cloud.shown[3], 'structural Hide bypassed a live cloud hook')
cloud.show();cloud.damage.collapse(cloud.env.LevelPieces,cloud.env.ToShowTable)
local cloudShows=cloud.cloudShows
cloud.show();cloud.env.script.testLateAnimation(3)
assert(cloud.cloudShows==cloudShows and not next(cloud.shown),'collapse restarted cloud or mesh visibility')

-- The common nonstructural path must retain the existing direct aliases.
local ordinary=fixture(168,2)
for _,name in ipairs({'Show','Hide','Move','Turn','Spin'}) do
    assert(ordinary.env.script.testPrimitives[name]==ordinary.raw[name],name..' gained dispatch for an unrelated unit')
end
print('PASS: real house/header/includes and provider, finite flame/smoke lifetimes, hidden-anchor removal, deterministic retained/disappearing sections, height-axis pose, frozen geometry, unit isolation and cloud composition')
