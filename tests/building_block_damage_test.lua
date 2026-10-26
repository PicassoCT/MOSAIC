-- Run with Lua 5.1 or later, from the repository root.
local function loadEnv(path, env)
    local f
    if setfenv then f = assert(loadfile(path)); setfenv(f, env)
    else f = assert(loadfile(path, 't', env)) end
    return f()
end
local function noop() end
local function fixture(columnCount, floorCount, scale, id, baseHeight)
    columnCount, floorCount, scale = columnCount or 2, floorCount or 3, scale or 1
    id, baseHeight = id or 42, baseHeight or 0
    local hp, frame, lastPiece, lastFrame = 1000, 0, nil, -1
    local positions, names, children, visible = {}, {}, {}, {}
    local losses, puffs, sleeps, moves, turns, removed = {}, {}, {}, {}, {}, {}
    local dirty, calls, destroyed, poseReads, healthReads = 0, 0, false, 0, 0
    local rules = {}
    local stoppedSpins, retiredPieces = {}, {}
    local childUnits = {}
    local env = setmetatable({unitID=id, x_axis=1, y_axis=2, z_axis=3,
        GG={InstanceCulture='international'}, VFS={}}, {__index=_G})
    env._G=env
    env.VFS.Include=function(path,scope)
        return loadEnv(path,scope or env)
    end
    env.Show=function(p) visible[p]=true end
    env.Hide=function(p) visible[p]=nil end
    env.Move=function(p,axis,goal,speed)
        positions[p]=positions[p] or {0,0,0}; positions[p][axis]=goal
        moves[#moves+1]={piece=p,axis=axis,goal=goal,speed=speed}
    end
    env.Turn=function(p,axis,goal,speed)
        turns[#turns+1]={piece=p,axis=axis,goal=goal,speed=speed}
    end
    env.Spin=noop
    env.StopSpin=function(p,axis)
        stoppedSpins[p]=stoppedSpins[p] or {}
        stoppedSpins[p][axis]=true
    end
    env.OnBuildingPiecesDetached=function(pieces)
        for _,p in ipairs(pieces)do
            assert(env.IsBuildingPieceDetached(p), 'retirement callback preceded detachment')
            retiredPieces[p]=true
        end
    end
    env.Explode=function() error('building damage must never emit model pieces') end
    env.Sleep=function(ms) sleeps[#sleeps+1]=ms end
    env.hideAll=function() for p in pairs(visible) do visible[p]=nil end end
    env.Spring={
        UnitScript={Show=env.Show,Hide=env.Hide,Move=env.Move,Turn=env.Turn,Spin=env.Spin},
        GetUnitPieceMap=function() return names end,
        GetUnitPieceInfo=function(_,p) return {children=children[p] or {}} end,
        -- Rotate the entire building to ensure attachment lookup uses positions,
        -- while supports still follow the original generated columns.
        GetUnitPiecePosDir=function(_,p)
            poseReads=poseReads+1
            local v=assert(positions[p], 'unknown piece '..tostring(p))
            return 100+v[3]*scale, v[2]*scale, 200-v[1]*scale
        end,
        GetUnitPosition=function() return 100,0,200 end,
        GetUnitHealth=function() healthReads=healthReads+1;return hp,1000 end,
        SetUnitRulesParam=function(_,key,value)rules[key]=value end,
        GetUnitLastAttackedPiece=function() return lastPiece,lastFrame end,
        GetGameFrame=function() return frame end,
        GetUnitIsDead=function() return destroyed end,
        GetProjectilePosition=function(id) return id*20,0,0 end,
        SpawnCEG=function(name) assert(name=='building_block_dust');puffs[#puffs+1]=frame end,
        ValidUnitID=function(unit) return unit==id or childUnits[unit] end,
        DestroyUnit=function(unit)
            if unit==id then destroyed=true else childUnits[unit]=nil end
        end,
    }
    env.GG.MarkBuildingShadowVolumeDirty=function() dirty=dirty+1 end
    env.OnBuildingGeometryChanged=function()
        rules.windowGeometryChanges=(rules.windowGeometryChanges or 0)+1
    end
    env.GG.SetObjectiveRadiancePieceVisible=function(_,p,on) assert(not on);removed[p]=true end
    loadEnv('scripts/lib_UnitScript.lua',env)
    -- Restore a small hideAll after loading the unrelated helper definitions.
    env.hideAll=function() for p in pairs(visible) do visible[p]=nil end end
    loadEnv('scripts/lib_building_voxels.lua',env)
    local removeShadow=env.RemoveBuildingShadowPiece
    env.RemoveBuildingShadowPiece=function(p)
        losses[#losses+1]={p=p,frame=frame}
        return removeShadow(p)
    end
    local damage=loadEnv('scripts/lib_building_damage.lua',env)
    env.initializeBuildingShadowVoxels(20,10,scale)
    local levels, shown, roofs, windows={},{},{},{}
    for col=1,columnCount do for floor=1,floorCount do
        local p=(col-1)*floorCount+floor
        names['block'..p]=p
        env.Move(p,1,(col-1)*20,0);env.Move(p,2,baseHeight+(floor-1)*10,0);env.Move(p,3,0,0)
        env.Turn(p,3,math.pi/2,0) -- preserve authored pose when adding collapse tilt
        env.houseAddDestructionTable(levels,floor,p,(col-1)*20,0,baseHeight+(floor-1)*10)
        env.addShadowVoxel((col-1)*20,0,baseHeight+(floor-1)*10,p)
        shown[#shown+1]=p;windows[p]=p;env.Show(p)
        if floor==floorCount then roofs[col]=p end
    end end
    local roof=floorCount
    names.RoofDay1=roof;names.RoofNight1=1003;names.roofChild=1001;names.roofDecor=1002
    children[roof]={'roofChild'}
    for _,p in ipairs({1001,1002,1003}) do
        env.Move(p,1,0,0);env.Move(p,2,baseHeight+(floorCount-1)*10+2,0);env.Move(p,3,0,0)
        if p~=1003 then shown[#shown+1]=p;windows[p]=p;env.Show(p) end
    end
    roofs.decor=1002
    damage.initialize(levels,shown,roofs,windows,10,20,scale)
    local gadgetEnv=setmetatable({gadget={},GG=env.GG,Spring=env.Spring,UnitDefs={
        [1]={name='house_asian0'},[2]={name='house_western0'},[3]={name='house_arab0'},
        [4]={name='house_asian_split_1_3',customParams={house_asian_base='house_asian0'}},
        [5]={name='tank'},[6]={name='protagonsafehouse',buildOptions={}},
        [7]={name='antagonsafehouse',buildOptions={}}},gadgetHandler={IsSyncedCode=function() return true end}}, {__index=_G})
    -- Eligibility is now exported by the real central configuration. The
    -- previous fixture predated that include and failed before any damage ran.
    gadgetEnv._G=gadgetEnv
    gadgetEnv.GG.InstanceCulture='international'
    gadgetEnv.UnitDefNames={}
    for id,def in pairs(gadgetEnv.UnitDefs) do
        def.id=id;gadgetEnv.UnitDefNames[def.name]=def
    end
    gadgetEnv.VFS={Include=function(path,scope) return loadEnv(path,scope or gadgetEnv) end}
    local batchSizes={}
    env.Spring.UnitScript={GetScriptEnv=function()
        calls=calls+1
        return {BuildingBlockDamaged=function(hits,tick)
            batchSizes[#batchSizes+1]=#hits
            return damage.update(hits,tick)
        end}
    end,CallAsUnit=function(_,fn,...) return fn(...) end}
    loadEnv('luarules/gadgets/game_building_block_damage.lua',gadgetEnv)
    local g=gadgetEnv.gadget
    g:Initialize()
    return {
        env=env,gadget=g,damage=damage,levels=levels,shown=shown,roofs=roofs,windows=windows,
        visible=visible,positions=positions,losses=losses,puffs=puffs,sleeps=sleeps,moves=moves,turns=turns,removed=removed,
        batchSizes=batchSizes,rules=rules,stoppedSpins=stoppedSpins,retiredPieces=retiredPieces,
        health=function(value) hp=value end,
        tick=function(value) frame=value;g:GameFrame(frame) end,
        hit=function(amount,p,opts)
            opts=opts or {}; if not opts.paralyze then hp=hp-amount end
            lastPiece,lastFrame=p,opts.stale and frame-1 or frame
            g:UnitDamaged(id,opts.def or 1,0,amount,opts.paralyze,1,opts.projectile,nil)
        end,
        dirty=function() return dirty end, calls=function() return calls end,
        destroyed=function() return destroyed end, reads=function() return poseReads end,
        healthReads=function() return healthReads end,
        childUnits=childUnits,
    }
end

-- Exactly 80% HP remains intact; threshold-crossing damage is clipped to its
-- below-80% portion. Small impacts accumulate across updates on the same block.
local a=fixture()
a.childUnits[77]=true;a.env.RegisterBuildingPieceAttachment(1002,77)
assert(a.levels[1][1]==1 and a.levels[3][2]==6, 'registration must preserve actual pID')
a.hit(200,2);a.tick(6);assert(a.calls()==0 and #a.losses==0)
a.hit(20,2);a.hit(20,2);a.tick(7);assert(a.calls()==0)
a.tick(12);assert(#a.losses==0 and a.calls()==1)
a.hit(94,2);a.tick(18);assert(#a.losses==0, 'failure must be delayed')
a.tick(23);assert(#a.losses==0)
a.tick(24);assert(#a.losses==2, 'struck middle block and supported roof must fall')
assert(a.rules.windowGeometryChanges==1,'detachment did not invalidate the facade capture')
assert(a.visible[1] and a.visible[4] and a.visible[5] and a.visible[6], 'lower/adjacent supports survive')
for _,p in ipairs({2,3,1001,1002,1003}) do
    assert(a.env.IsBuildingPieceDetached(p) and a.removed[p], 'falling geometry kept access/lighting')
    assert(a.retiredPieces[p], 'animation owner did not receive detachment')
    for axis=1,3 do
        assert(a.stoppedSpins[p] and a.stoppedSpins[p][axis], 'descendant spin survived detachment')
    end
end
assert(a.visible[2] and a.visible[3], 'model sections disappeared before settling')
local beforeMoves,beforeTurns=#a.moves,#a.turns
a.env.Move(2,2,100,10);a.env.Turn(2,3,0,10);a.env.Show(1003)
assert(#a.moves==beforeMoves and #a.turns==beforeTurns and not a.visible[1003], 'animation overrode collapse')
for _,move in ipairs(a.moves) do
    if move.speed>0 then
        assert(move.piece==2 or move.piece==3 or move.piece==1002 or move.piece==1003)
        local drop=move.piece==2 and 8 or 18
        assert(move.speed==drop/0.2, 'remnant drop must span the settling interval')
        if move.piece==2 or move.piece==3 then assert(move.goal==2) end
        if move.piece==1002 then assert(move.goal==4, 'decoration lost its authored offset') end
    end
end
for _,turn in ipairs(a.turns) do
    if turn.speed>0 then
        assert(turn.piece~=1001, 'child mesh was tilted twice')
        local base=turn.axis==3 and turn.piece<1000 and math.pi/2 or 0
        assert(math.abs(turn.goal-base)<=math.rad(5)+1e-9, 'tilt replaced authored rotation')
        if turn.piece==3 and turn.axis==3 then assert(math.abs(turn.goal-base)>=math.rad(3)) end
    end
end
assert(not a.roofs[1] and not a.roofs.decor and a.roofs[2]==6)
assert(not a.childUnits[77], 'roof hologram survived losing its anchor')
a.childUnits[79]=true;a.env.RegisterBuildingPieceAttachment(1002,79)
assert(not a.childUnits[79], 'late attachment callback repopulated a structurally gone remnant')
local shadow=a.env.GetBuildingShadowColumns()
assert(shadow.columns[1][1]==1 and shadow.columns[2][1]==3, 'shadow retained unsupported floors')
assert(a.dirty()==1, 'geometry notifications should coalesce per update')
a.tick(29);assert(a.visible[3], 'settling ended outside the fixed interval')
a.tick(30)
assert(a.rules.windowGeometryChanges==2,'settled facade kept a capture from its falling pose')
for _,p in ipairs({2,3,1001,1002,1003}) do
    a.env.Show(p);a.env.Hide(p)
    assert((a.visible[p]==true)==(p~=1003), 'animation changed the retained visibility snapshot')
    assert(not a.windows[p], 'window entry retained after settling')
end
assert(a.rules.building_remnant_blocks==2 and not a.env.IsBuildingPieceVisible(1003))
local healthReads=a.healthReads()
a.tick(36);a.tick(306)
assert(a.rules.windowGeometryChanges==2,'effect-only updates repeatedly recaptured the facade')
assert(a.healthReads()==healthReads, 'effect-only update rescanned structural health')
assert(a.env.GG.BuildingDamageEffects[42][2].started==12, 'low HP refreshed effect lifetime')
a.tick(312)
assert(not a.env.GG.BuildingDamageEffects[42] and not a.env.GG.BuildingDamageAnchor[42])
local before=a.calls();a.tick(318);a.tick(324);assert(a.calls()==before, 'expired building still polled')

local b=fixture();b.health(801);b.hit(2,2);b.tick(6)
b.hit(132,2);b.tick(12);b.tick(18);assert(#b.losses==0, 'above-80% damage incorrectly counted')
b.hit(1,2);b.tick(24);b.tick(30);assert(#b.losses==2)

-- Paralyzers, healing, unrelated units and lethal damage never queue a chip.
local c=fixture();c.health(400)
c.hit(100,2,{paralyze=true});c.hit(-5,2);c.hit(100,2,{def=5});c.tick(6)
assert(c.calls()==0)
c.hit(1000,2);c.tick(12);assert(c.calls()==0)

-- Split variants dispatch normally. Cached positions make an ordinary batched
-- hit independent of the model's total piece count (no runtime pose scans).
local d=fixture(2,3,0.0254);d.health(400)
local reads=d.reads();d.hit(134,'block2',{def=4});d.tick(6)
assert(d.reads()==reads);d.tick(12);assert(#d.losses==2)

-- Bursts produce one bounded batch. Excess queued impact buckets merge without
-- losing health damage; stale piece hits cannot override a current projectile.
local e=fixture(10,4);e.health(490)
for i=1,100 do e.hit(1,2,{stale=true,projectile=i}) end
e.tick(6);assert(e.calls()==1 and e.batchSizes[1]<=8 and #e.losses==0)
e.tick(12);assert(#e.losses<=3*4 and #e.puffs<=3)
e.gadget:UnitDestroyed(42);local before=e.calls();e.tick(18);assert(e.calls()==before)

-- Four failed columns exceed a tick's scheduling limit: accumulated damage in
-- the fourth column must be retained and resolved on the next fixed update.
local f=fixture(5,4)
local hits={};for col=1,4 do hits[#hits+1]={piece=(col-1)*4+1,damage=40} end
assert(f.damage.update(hits,6));assert(#f.losses==0)
assert(f.damage.update({},12));assert(#f.losses==9 and #f.puffs==3)
assert(f.damage.update({},18));assert(#f.losses==12 and #f.puffs==4)
assert(f.damage.update({},24), 'retained bottom smoke stopped being ticked')
for _,p in ipairs({1,5,9,13}) do
    assert(f.visible[p] and f.env.IsBuildingPieceDetached(p), 'failed bottom was not retained')
end
assert(f.visible[2] and f.visible[3] and not f.visible[4], 'stable rolls did not cover both remnant outcomes')
local shadow=f.env.GetBuildingShadowColumns()
for col=1,4 do assert(shadow.columns[col][1]==1, 'retained bottom lost its shadow extent') end
local slots=0;for _ in pairs(f.env.GG.BuildingDamageEffects[42]) do slots=slots+1 end
assert(slots==2, 'simultaneous smoke anchors exceeded the configured fire budget')
assert(not f.damage.update({},306))
assert(f.visible[17] and f.visible[20], 'intact fifth column removed')

-- Remnant choices do not consume global randomness and do not change between
-- runs. Frozen bottoms keep their authored height and reject later animations.
local stable=fixture(5,4)
stable.env.math=setmetatable({random=function()error('remnant selection used shared RNG')end}, {__index=math})
stable.damage.update(hits,6);stable.damage.update({},12);stable.damage.update({},18);stable.damage.update({},24)
for p=1,20 do assert(stable.visible[p]==f.visible[p], 'remnant choice changed across identical runs') end
local beforeMoves,beforeTurns=#stable.moves,#stable.turns
stable.env.Show(1);stable.env.Hide(1);stable.env.Move(1,2,-100,10);stable.env.Turn(1,3,0,10)
assert(stable.visible[1] and #stable.moves==beforeMoves and #stable.turns==beforeTurns)
for _,move in ipairs(stable.moves) do
    if move.piece==1 then assert(move.speed==0 and move.goal==0, 'bottom moved below the terrain') end
end
stable.damage.collapse(stable.levels,stable.shown)
assert(not next(stable.visible) and stable.rules.building_remnant_blocks==0,
    'full death retained partial-collapse ruins in the original model')

-- A raised foundation and independent decoration offsets are not zero-based:
-- sink to bottomY + 0.2 floorHeight, retaining each mesh's authored offset.
local raised=fixture(2,3,1,42,7)
raised.damage.update({{piece=2,damage=134}},6);raised.damage.update({},12);raised.damage.update({},18)
assert(raised.positions[1][2]==7 and raised.positions[2][2]==9 and raised.positions[3][2]==9,
    'sunken remnants used a zero-height foundation')
assert(raised.positions[1002][2]==11 and raised.visible[1002] and not raised.visible[1003],
    'independent decoration offset or hidden variant changed during sinking')
assert(raised.env.GetBuildingShadowColumns().baseHeights[1][1]==7)

-- Killed pauses, then lower floors crumble before the surviving upper mass
-- descends. Children inherit parent motion instead of being translated twice.
local k=fixture();k.childUnits[78]=true;k.env.RegisterBuildingPieceAttachment(1002,78)
k.damage.collapse(k.levels,k.shown)
assert(not k.childUnits[78], 'hologram remained above collapsing roof')
assert(k.sleeps[1]==200 and #k.sleeps==4)
assert(k.losses[1].p==1 and k.losses[2].p==4)
assert(k.losses[3].p==2 and k.losses[4].p==5 and k.losses[5].p==3)
local upperMoves,childMoves=0,0
for _,move in ipairs(k.moves) do
    if move.speed>0 then
        if move.piece==3 then upperMoves=upperMoves+1 end
        if move.piece==1001 then childMoves=childMoves+1 end
        assert(move.piece~=1 and move.piece~=4, 'ground floor sank below terrain')
        assert(move.speed==10/0.32, 'each collapse stage must move one floor at a constant speed')
    end
end
assert(upperMoves==2 and childMoves==0)
assert(not next(k.visible));k.env.Show(6);assert(not k.visible[6])
assert(not next(k.roofs) and not next(k.windows))
local count=#k.losses;k.damage.collapse(k.levels,k.shown);assert(#k.losses==count)

-- A pending chip followed by death is handled by the single collapse sequence.
local q=fixture();q.health(400);q.hit(134,2);q.tick(6)
q.damage.collapse(q.levels,q.shown)
local count=#q.losses;q.tick(12);assert(#q.losses==count)

-- Death during a short fall finishes that animation once, then collapses only
-- the surviving columns. It cannot restart a drop or leave a floating roof.
local q2=fixture();q2.health(400);q2.hit(134,2);q2.tick(6);q2.tick(12)
assert(q2.visible[3] and #q2.losses==2)
q2.damage.collapse(q2.levels,q2.shown)
assert(#q2.losses==6 and not next(q2.visible))
q2.tick(18);assert(#q2.losses==6)

-- Empty scaffolding and late construction callbacks must not resurrect a house.
local env=setmetatable({Show=noop,Hide=noop,Move=noop,Turn=noop,Spin=noop,
    Sleep=noop,hideAll=noop,unitID=1,GG={},Spring={UnitScript={
        Show=noop,Hide=noop,Move=noop,Turn=noop,Spin=noop}}}, {__index=_G})
env._G=env
env.VFS={Include=function(path,scope)return loadEnv(path,scope or env)end}
local early=loadEnv('scripts/lib_building_damage.lua',env)
assert(not early.update({{damage=100}},6));assert(early.collapse({}, {})==1)
env.Show(123)

-- Removing the last support stack destroys the remaining building shell.
local last=fixture(1,3);last.health(400);last.hit(267,1);last.tick(6);last.tick(12)
assert(not last.destroyed() and last.visible[3], 'last stack destroyed before settling')
for _,move in ipairs(last.moves) do
    assert(move.speed==0 or move.piece~=1, 'lowest support dropped into terrain')
end
last.tick(18)
assert(last.destroyed() and not last.env.GG.BuildingDamageEffects[42],
    'retained geometry prevented the last support from triggering normal unit death')

-- Whole-city budget is shared by normal damage and final-collapse scripts, and
-- resets only at the common fixed interval, not at each building callback.
local city=fixture()
local allow=city.env.GG.AllowBuildingBlockDamageEffect
assert(not allow('debris'))
for _=1,16 do assert(allow('dust')) end
assert(not allow('debris') and not allow('dust'))
city.tick(5);assert(not allow('dust'))
city.tick(6);assert(not allow('debris') and allow('dust'))
city.gadget:Shutdown();assert(not city.env.GG.AllowBuildingBlockDamageEffect)
print('PASS: 80% threshold/strength, accumulation, deterministic sunken remnants, permanent bottoms, authored poses, attachments, lighting/shadows, bounded finite effects, idle path and complete staged death')
