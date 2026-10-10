-- Run with Lua 5.1 or later, from the repository root.
local function loadEnv(path, env)
    local f
    if setfenv then f = assert(loadfile(path)); setfenv(f, env)
    else f = assert(loadfile(path, 't', env)) end
    return f()
end
local function noop() end
local function fixture(columnCount, floorCount, scale)
    columnCount, floorCount, scale = columnCount or 2, floorCount or 3, scale or 1
    local hp, frame, lastPiece, lastFrame = 1000, 0, nil, -1
    local positions, names, children, visible = {}, {}, {}, {}
    local losses, puffs, sleeps, moves, turns, removed = {}, {}, {}, {}, {}, {}
    local dirty, calls, destroyed, poseReads = 0, 0, false, 0
    local childUnits = {}
    local env = setmetatable({unitID=42, x_axis=1, y_axis=2, z_axis=3,
        GG={}, VFS={Include=function() return {} end}}, {__index=_G})
    env.Show=function(p) visible[p]=true end
    env.Hide=function(p) visible[p]=nil end
    env.Move=function(p,axis,goal,speed)
        positions[p]=positions[p] or {0,0,0}; positions[p][axis]=goal
        moves[#moves+1]={piece=p,axis=axis,goal=goal,speed=speed}
    end
    env.Turn=function(p,axis,goal,speed)
        turns[#turns+1]={piece=p,axis=axis,goal=goal,speed=speed}
    end
    env.Spin=noop; env.StopSpin=noop
    env.Explode=function() error('building damage must never emit model pieces') end
    env.Sleep=function(ms) sleeps[#sleeps+1]=ms end
    env.hideAll=function() for p in pairs(visible) do visible[p]=nil end end
    env.Spring={
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
        GetUnitHealth=function() return hp,1000 end,
        GetUnitLastAttackedPiece=function() return lastPiece,lastFrame end,
        GetGameFrame=function() return frame end,
        GetUnitIsDead=function() return destroyed end,
        GetProjectilePosition=function(id) return id*20,0,0 end,
        SpawnCEG=function(name) assert(name=='building_block_dust');puffs[#puffs+1]=frame end,
        ValidUnitID=function(id) return id==42 or childUnits[id] end,
        DestroyUnit=function(id)
            if id==42 then destroyed=true else childUnits[id]=nil end
        end,
    }
    env.GG.MarkBuildingShadowVolumeDirty=function() dirty=dirty+1 end
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
        env.Move(p,1,(col-1)*20,0);env.Move(p,2,(floor-1)*10,0);env.Move(p,3,0,0)
        env.Turn(p,3,math.pi/2,0) -- preserve authored pose when adding collapse tilt
        env.houseAddDestructionTable(levels,floor,p,(col-1)*20,0,(floor-1)*10)
        env.addShadowVoxel((col-1)*20,0,(floor-1)*10,p)
        shown[#shown+1]=p;windows[p]=p;env.Show(p)
        if floor==floorCount then roofs[col]=p end
    end end
    local roof=floorCount
    names.RoofDay1=roof;names.RoofNight1=1003;names.roofChild=1001;names.roofDecor=1002
    children[roof]={'roofChild'}
    for _,p in ipairs({1001,1002,1003}) do
        env.Move(p,1,0,0);env.Move(p,2,(floorCount-1)*10+2,0);env.Move(p,3,0,0)
        if p~=1003 then shown[#shown+1]=p;windows[p]=p;env.Show(p) end
    end
    roofs.decor=1002
    damage.initialize(levels,shown,roofs,windows,10,20,scale)
    local gadgetEnv=setmetatable({gadget={},GG=env.GG,Spring=env.Spring,UnitDefs={
        [1]={name='house_asian0'},[2]={name='house_western0'},[3]={name='house_arab0'},
        [4]={name='house_asian_split_1_3',customParams={house_asian_base='house_asian0'}},
        [5]={name='tank'},},gadgetHandler={IsSyncedCode=function() return true end}}, {__index=_G})
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
        visible=visible,losses=losses,puffs=puffs,sleeps=sleeps,moves=moves,turns=turns,removed=removed,
        batchSizes=batchSizes,
        health=function(value) hp=value end,
        tick=function(value) frame=value;g:GameFrame(frame) end,
        hit=function(amount,p,opts)
            opts=opts or {}; if not opts.paralyze then hp=hp-amount end
            lastPiece,lastFrame=p,opts.stale and frame-1 or frame
            g:UnitDamaged(42,opts.def or 1,0,amount,opts.paralyze,1,opts.projectile,nil)
        end,
        dirty=function() return dirty end, calls=function() return calls end,
        destroyed=function() return destroyed end, reads=function() return poseReads end,
        childUnits=childUnits,
    }
end

-- Exactly half HP remains intact; threshold-crossing damage is clipped to its
-- below-half portion. Small impacts accumulate across updates on the same block.
local a=fixture()
a.childUnits[77]=true;a.env.RegisterBuildingPieceAttachment(1002,77)
assert(a.levels[1][1]==1 and a.levels[3][2]==6, 'registration must preserve actual pID')
a.hit(500,2);a.tick(6);assert(a.calls()==0 and #a.losses==0)
a.hit(20,2);a.hit(20,2);a.tick(7);assert(a.calls()==0)
a.tick(12);assert(#a.losses==0 and a.calls()==1)
a.hit(44,2);a.tick(18);assert(#a.losses==0, 'failure must be delayed')
a.tick(23);assert(#a.losses==0)
a.tick(24);assert(#a.losses==2, 'struck middle block and supported roof must fall')
assert(a.visible[1] and a.visible[4] and a.visible[5] and a.visible[6], 'lower/adjacent supports survive')
for _,p in ipairs({2,3,1001,1002,1003}) do
    assert(a.env.IsBuildingPieceDetached(p) and a.removed[p], 'falling geometry kept access/lighting')
end
assert(a.visible[2] and a.visible[3], 'model sections disappeared before settling')
local beforeMoves,beforeTurns=#a.moves,#a.turns
a.env.Move(2,2,100,10);a.env.Turn(2,3,0,10);a.env.Show(1003)
assert(#a.moves==beforeMoves and #a.turns==beforeTurns and not a.visible[1003], 'animation overrode collapse')
for _,move in ipairs(a.moves) do
    if move.speed>0 then
        assert(move.piece==2 or move.piece==3 or move.piece==1002 or move.piece==1003)
        assert(move.speed==4.5/0.2, 'short drop must span the settling interval')
        if move.piece==2 then assert(move.goal==5.5) end
        if move.piece==3 then assert(move.goal==15.5) end
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
local shadow=a.env.GetBuildingShadowColumns()
assert(shadow.columns[1][1]==1 and shadow.columns[2][1]==3, 'shadow retained unsupported floors')
assert(a.dirty()==1, 'geometry notifications should coalesce per update')
a.tick(29);assert(a.visible[3], 'settling ended outside the fixed interval')
a.tick(30)
for _,p in ipairs({2,3,1001,1002,1003}) do
    a.env.Show(p);assert(not a.visible[p], 'animation resurrected broken piece')
    assert(not a.windows[p], 'window entry retained after settling')
end
local before=a.calls();a.tick(36);a.tick(42);assert(a.calls()==before, 'idle building still polled')

local b=fixture();b.health(501);b.hit(2,2);b.tick(6)
b.hit(82,2);b.tick(12);b.tick(18);assert(#b.losses==0, 'above-half damage incorrectly counted')
b.hit(1,2);b.tick(24);b.tick(30);assert(#b.losses==2)

-- Paralyzers, healing, unrelated units and lethal damage never queue a chip.
local c=fixture();c.health(400)
c.hit(100,2,{paralyze=true});c.hit(-5,2);c.hit(100,2,{def=5});c.tick(6)
assert(c.calls()==0)
c.hit(1000,2);c.tick(12);assert(c.calls()==0)

-- Split variants dispatch normally. Cached positions make an ordinary batched
-- hit independent of the model's total piece count (no runtime pose scans).
local d=fixture(2,3,0.0254);d.health(400)
local reads=d.reads();d.hit(84,'block2',{def=4});d.tick(6)
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
local hits={};for col=1,4 do hits[#hits+1]={piece=(col-1)*4+1,damage=30} end
assert(f.damage.update(hits,6));assert(#f.losses==0)
assert(f.damage.update({},12));assert(#f.losses==12 and #f.puffs==3)
assert(f.damage.update({},18));assert(#f.losses==16 and #f.puffs==4)
assert(not f.damage.update({},24))
for p=1,16 do assert(not f.visible[p], 'unsupported mass retained') end
assert(f.visible[17] and f.visible[20], 'intact fifth column removed')

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
local q=fixture();q.health(400);q.hit(84,2);q.tick(6)
q.damage.collapse(q.levels,q.shown)
local count=#q.losses;q.tick(12);assert(#q.losses==count)

-- Death during a short fall finishes that animation once, then collapses only
-- the surviving columns. It cannot restart a drop or leave a floating roof.
local q2=fixture();q2.health(400);q2.hit(84,2);q2.tick(6);q2.tick(12)
assert(q2.visible[3] and #q2.losses==2)
q2.damage.collapse(q2.levels,q2.shown)
assert(#q2.losses==6 and not next(q2.visible))
q2.tick(18);assert(#q2.losses==6)

-- Empty scaffolding and late construction callbacks must not resurrect a house.
local env=setmetatable({Show=noop,Hide=noop,Move=noop,Turn=noop,Spin=noop,
    Sleep=noop,hideAll=noop,unitID=1,GG={}}, {__index=_G})
local early=loadEnv('scripts/lib_building_damage.lua',env)
assert(not early.update({{damage=100}},6));assert(early.collapse({}, {})==1)
env.Show(123)

-- Removing the last support stack destroys the remaining building shell.
local last=fixture(1,3);last.health(400);last.hit(200,1);last.tick(6);last.tick(12)
assert(not last.destroyed() and last.visible[3], 'last stack destroyed before settling')
for _,move in ipairs(last.moves) do
    assert(move.speed==0 or move.piece~=1, 'lowest support dropped into terrain')
end
last.tick(18)
assert(last.destroyed() and not last.visible[3])

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
print('PASS: threshold, accumulation, fixed ticks, delayed supports/roofs, local drop/tilt without Explode, attachments, lighting, shadows, budgets, cleanup and staged collapse')
