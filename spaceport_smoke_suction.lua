-- Real spaceport recovery + header/includes + cloud hooks + synced registry.
-- In particular, a disappearing proxy must never leave a world-space cloud.
assert(_VERSION=='Lua 5.1')
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua')
local frame,clock=0,0
local names,map,groups,positions,moves,shown={},{},{},{},{},{}
local function piece(name)
    if not map[name] then map[name]=#names+1;names[#names+1]=name;positions[map[name]]={0,0,0}end
    return map[name]
end
for _,group in ipairs({'RocketScience','RocketPlume','RocketPlumeA','RocketPlumeB','FireFlower','SmokeBubble'})do
    groups[group]={};for i=1,5 do groups[group][i]=piece(group..i)end
end
for _,name in ipairs({'ArenaSmoke','Rocket','turbine','turbineHot','turbineCold','SpaceHarbour'})do piece(name)end
local function advance(seconds)
    for id,axes in pairs(moves)do for axis,m in pairs(axes)do
        local current=positions[id][axis];local distance=m.target-current
        local delta=math.min(math.abs(distance),m.speed*seconds)
        positions[id][axis]=current+(distance<0 and -delta or delta)
    end end
    clock=clock+seconds;frame=math.floor(clock*30+.5)
end
local function height(id)
    local value=positions[id][3]
    local tier=tonumber(names[id]:match('^RocketPlume[AB]?(%d+)$'))
    if tier then
        value=value+positions[map.Rocket][3]
        for i=1,tier do value=value+positions[groups.RocketScience[i]][3]end
    end
    return 200+value*.0254
end
Game={gameSpeed=30};GG={};gadget={}
gadgetHandler={IsSyncedCode=function()return true end,AddChatAction=function()end,RemoveChatAction=function()end}
VFS={Include=function(p)return dofile(p)end}
local native={}
native.Show=function(id)shown[id]=true end
native.Hide=function(id)shown[id]=nil end
native.Move=function(id,axis,target,speed)
    moves[id]=moves[id] or {};moves[id][axis]={target=target,speed=speed}
    if speed==0 then positions[id][axis]=target end
end
native.WaitForMove=function(id,axis)return coroutine.yield('move',id,axis)end
native.Sleep=function(ms)return coroutine.yield('sleep',ms)end
native.Turn=function()end;native.Spin=function()end;native.StopSpin=function()end;native.StartThread=function()end
Spring={UnitScript=native,GetUnitDefID=function()return 1 end,GetGameFrame=function()return frame end,GetUnitTeam=function()return 0 end,
    GetUnitPieceMap=function()return map end,ValidUnitID=function()return true end,Echo=function(s)error(s)end,
    GetUnitPieceInfo=function()return {min={-20,-20,-30},max={20,20,30}}end,
    GetUnitPiecePosDir=function(_,id)return 0,height(id),0 end,
    GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0}end,
    GetUnitPieceMatrix=function(_,id)return .0254,0,0,0,0,0,-.0254,0,0,.0254,0,0,0,height(id),0,1 end}
-- Startup logging is expected; warnings from piece registration are not.
local echo=Spring.Echo;Spring.Echo=function()end
dofile('luarules/gadgets/gfx_cloud_volumes.lua');gadget:Initialize();Spring.Echo=echo
local env=setmetatable({unitID=42,unitDefID=1,UnitDefs={[1]={name='Spaceport',customParams={cloud_piece_volumes=1}}},
    Spring=Spring,GG=GG,VFS=VFS,script={},piece=piece,
    getGameConfig=function()return {game={states={normal='normal'}}}end,
    getScrapheapTypeTable=function()return {}end},{__index=_G})
env._G=env
local realIncludes={['lib_UnitScript.lua']=true,['lib_Animation.lua']=true,['lib_radiance_emitters.lua']=true,
    ['lib_cloud_pieces.lua']=true,['lib_objective_ribbon_flames.lua']=true,
    ['lib_spaceport_landing_flames.lua']=true,['lib_spaceport_cold_vapor.lua']=true}
env.include=function(name)
    if not realIncludes[name] then return end
    return setfenv(assert(loadstring(header..'\n'..read('scripts/'..name),name)),env)()
end
setfenv(assert(loadstring(header..'\n'..read('scripts/objective_spaceportscript.lua'))),env)()
env.getPieceTableByNameGroups=function()return groups end
env.initialSetup=function()end -- Preparation is unrelated; recovery runs unmodified.
env.script.Create()
local function attached(id)
    local r=assert(CloudVolumeRecords['42:'..id],'smoke hidden before suction finished: '..names[id])
    assert(r.unitID==42 and r.piece==id and not r.worldHalf,'cloud lost its piece attachment')
end
local function noDetached()
    for _,r in pairs(CloudVolumeRecords)do
        assert(r.unitID==42 and r.piece,'spaceport Hide detached a lingering world-space cloud')
    end
end
local function resume(co,...)
    local ok,kind,a,b=coroutine.resume(co,...);assert(ok,kind);noDetached();return kind,a,b
end
for cycle=1,2 do
    native.Move(map.Rocket,3,58000,0)
    native.Move(map.ArenaSmoke,3,0,0)
    for _,id in ipairs(groups.RocketScience)do native.Move(id,3,0,0)end
    env.Show(map.ArenaSmoke)
    local co=coroutine.create(env.cloudFallingDown)
    local ascent={}
    for i=1,5 do ascent[i]=groups[i%2==0 and 'RocketPlumeA' or 'RocketPlume'][i]end
    local kind,id,axis=resume(co,groups.RocketScience,ascent,groups.RocketPlumeB)
    for i=1,5 do
        assert(kind=='move' and id==groups.RocketScience[i] and axis==3,'recovery skipped a suction stage')
        local smoke=groups.RocketPlumeB[i];attached(smoke);attached(map.ArenaSmoke)
        local before=height(smoke)
        local motion=moves[id][axis];local duration=math.abs(motion.target-positions[id][axis])/motion.speed
        advance(duration*.5);attached(smoke);noDetached()
        assert(height(smoke)<before,'attached cloud did not descend with its mover')
        advance(duration*.5);attached(smoke)
        kind,id,axis=resume(co)
        assert(not CloudVolumeRecords['42:'..smoke],'completed cooling cloud remained registered')
    end
    assert(kind=='sleep' and id==4000)
    attached(map.ArenaSmoke);local before=height(map.ArenaSmoke)
    advance(4);attached(map.ArenaSmoke);assert(height(map.ArenaSmoke)<before)
    kind,id=resume(co);assert(kind=='sleep' and id==9000);attached(map.ArenaSmoke)
    advance(9);attached(map.ArenaSmoke)
    resume(co)
    assert(coroutine.status(co)=='dead' and not next(CloudVolumeRecords),'recovery left smoke behind')
end
-- Optional sphere pieces share the same attachment contract.
env.showT(groups.SmokeBubble);env.hideT(groups.SmokeBubble);noDetached()
assert(not next(CloudVolumeRecords))
-- Destruction midway through suction removes registrations immediately.
env.Show(map.ArenaSmoke)
local co=coroutine.create(env.cloudFallingDown)
resume(co,groups.RocketScience,groups.RocketPlume,groups.RocketPlumeB)
env.script.Killed();assert(not next(CloudVolumeRecords),'destroyed spaceport retained smoke')
env.Show(map.ArenaSmoke);assert(not next(CloudVolumeRecords),'dead spaceport restarted smoke')
print('PASS: real spaceport suction, moving attached spheres, final Hide without detached tails, arena descent, repeated cycles and destruction')
