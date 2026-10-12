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
    Show(p); Move(p, 2, 100, 10); Turn(p, 1, 1, 1); Spin(p, 3, 1, 1)
end
script.testPrimitives={Show=Show,Hide=Hide,Move=Move,Turn=Turn,Spin=Spin}
]]

local function fixture(id, defID)
    local state={shown={},positions={},moves={},turns={},spins={},fires={},removedFires={},rules={},cloudShows=0,cloudHides=0}
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
        GetGaiaTeamID=function()return 0 end,GetGameFrame=function()return 0 end,
        ValidUnitID=function(unit)return unit==id and not state.destroyed end,
        GetUnitIsDead=function(unit)return unit~=id or state.destroyed==true end,
        GetUnitPosition=function()return 100,0,200 end,GetGroundHeight=function()return 0 end,
        GetUnitPieceMap=function()return names end,GetUnitPieceInfo=function()return {children={}}end,
        GetUnitPiecePosDir=function(_,p)
            local at=state.positions[p] or {0,0,0};return 100+at[1],at[2],200+at[3],0,1,0
        end,
        GetUnitHealth=function()return 400,1000 end,
        SetUnitNanoPieces=noop,SpawnCEG=noop,SetUnitRulesParam=function(_,key,value)state.rules[key]=value end,
        DestroyUnit=function()state.destroyed=true end,
    }
    -- Load the actual synced provider and normalizer in their own gadget env.
    -- Capture requests while preserving real validation, registry and revisions.
    local provider=setmetatable({gadget={},GG=env.GG,Spring=env.Spring,VFS={},
        gadgetHandler={IsSyncedCode=function()return true end,AddChatAction=noop,RemoveChatAction=noop},
        SendToUnsynced=noop}, {__index=_G})
    provider._G=provider
    provider.VFS.Include=function(path)return compile(read(path),path,provider)()end
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
    env.VFS.Include=function(path) return compile(read(path),path,env)() end
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

local a=fixture(42,1)
assemble(a)
assert(a.shown[3] and a.rules.building_structural_blocks==6)
a.env.hideHouse()
assert(not a.env.BuildingBlockDamaged({{x=100,y=10,z=300,damage=100}},0) and #a.fires==0,
    'hidden geometry remained eligible for damage')
assert(a.provider.SmokeRibbonRevision==0 and not next(a.provider.SmokeRibbonRecords),
    'unselected damage modified the synced flame registry')
a.show()
assert(a.env.BuildingBlockDamaged({{x=100,y=10,z=300,damage=100}},6),
    'real header Show/showT calls bypassed structural visibility tracking')
assert(#a.fires==1 and a.fires[1].unit==42 and a.fires[1].piece==3,
    'selected damaged block never reached the real SmokeRibbon request')
local fire=a.provider.SmokeRibbonRecords['42:block_fire_3']
assert(fire and fire.unitID==42 and fire.piece==3 and fire.enabled==true,
    'damaged-block fire was rejected or registered on the wrong anchor')
assert(fire.mode=='smoke' and fire.scale==1 and fire.rootOffset[1]==0,
    'synced fire record did not receive normalized defaults')
assert(fire.directionSpace=='world' and fire.direction[1]==0 and fire.direction[2]==1 and fire.direction[3]==0,
    'synced fire record lost its fixed upward direction')
assert(fire.colorStart~=a.fires[1].options.colorStart and a.provider.SmokeRibbonRevision==1,
    'provider did not publish a normalized copy and revision')
assert(a.env.GG.BuildingDamageAnchor[42]==3)
assert(a.env.BuildingBlockDamaged({},12))
assert(a.rules.building_detached_blocks==2 and a.shown[3] and a.shown[4],
    'supported roof should settle with the struck block before hiding')
local falls=0
for _,move in ipairs(a.moves) do if move.speed and move.speed>0 then
    falls=falls+1
    assert(move.axis==2,'fall used the header rotation alias instead of the house height axis')
    assert((move.piece==3 and move.goal==5.5) or (move.piece==4 and move.goal==15.5),
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
assert(not a.env.BuildingBlockDamaged({},18))
a.show();a.env.script.testLateAnimation(3)
assert(not a.shown[3] and not a.shown[4] and a.shown[2], 'a later show resurrected detached geometry')
assert(#a.removedFires==1, 'the detached block retained its fire slot')
assert(not a.provider.SmokeRibbonRecords['42:block_fire_3'] and a.provider.SmokeRibbonRevision==2,
    'fall completion did not remove the actual synced record and publish its revision')

-- Reused include source must bind each unit's hooks and private support state.
local b=fixture(84,3);assemble(b)
assert(b.env.BuildingBlockDamaged({{piece=3,damage=100}},6))
assert(b.fires[1].unit==84 and a.rules.building_detached_blocks==2)
assert(b.rules.building_detached_blocks==0 and b.shown[3])
assert(b.provider.SmokeRibbonRecords['84:block_fire_3'].piece==3 and not next(a.provider.SmokeRibbonRecords),
    'another unit reused the first unit\'s flame registry state')

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
print('PASS: real house/header/includes, visibility, synced fire normalization/registry/removal, height-axis fall, authored rotation, animation suppression, unit isolation, cloud composition and direct ordinary path')
