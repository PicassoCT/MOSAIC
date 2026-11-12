-- Engine-faithful animation mock: zero-speed Move/Turn snaps the piece but
-- deliberately leaves an existing animation queued, just like Recoil.
assert(_VERSION=='Lua 5.1')
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua')
local aliases={}
for _,name in ipairs({'x_axis','y_axis','z_axis'}) do aliases[#aliases+1]=assert(header:match('local '..name..' = %d+')) end
sizeSpacingLetter,sizeDownLetter,textSpinner=321,350,90
local positions,angles,moving,turning,now,restores,reports,deathTime,spin
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b)) end
local function command(state,anims,id,axis,target,speed)
    state[id]=state[id] or {0,0,0};anims[id]=anims[id] or {}
    if speed==0 then state[id][axis]=target
    else anims[id][axis]={target=target,speed=speed} end
end
function Move(id,axis,target,speed) command(positions,moving,id,axis,target,speed) end
function Turn(id,axis,target,speed) command(angles,turning,id,axis,target,speed) end
function StopSpin() spin=nil end
function Spin(id,axis,speed) assert(id==textSpinner and axis==3);spin=speed end
local function advance(seconds)
    for _,pair in ipairs({{positions,moving},{angles,turning}}) do
        for id,axes in pairs(pair[2]) do
            for axis,anim in pairs(axes) do
                local difference=anim.target-pair[1][id][axis]
                if math.abs(difference)<=anim.speed*seconds then
                    pair[1][id][axis]=anim.target;axes[axis]=nil
                else pair[1][id][axis]=pair[1][id][axis]+(difference>0 and 1 or -1)*anim.speed*seconds end
            end
        end
    end
    now=now+seconds
end
function Sleep(ms)
    -- Leave one animation-frame of lag at coroutine wake-up.
    advance(math.max(0,ms/1000-(ms>100 and 1/30 or 0)))
end
local function wait(anims,id,axis)
    local limit=now+2
    while anims[id] and anims[id][axis] do
        assert(now<limit,'stale animation caused a long WaitForMove/Turn')
        advance(1/30)
    end
end
function WaitForMove(id,axis) wait(moving,id,axis) end
function WaitForTurn(id,axis) wait(turning,id,axis) end
function foreach(ids,fn) for _,id in ipairs(ids) do fn(id) end end
function ShowReg() end
function hideTReg() end
function getCivilianTypeTable() return {[4]=true} end
function getAllNearUnit() return {10} end
function doesUnitExistAlive() return not deathTime or now<deathTime end
UnitDefs={[4]={name='civilian_test'}}
Spring={
    GetGameFrame=function()return math.floor(now*30) end,
    GetUnitDefID=function()return 4 end,
    GetUnitPieceMap=function()return {root=textSpinner} end,
    GetUnitPieceInfo=function()return {parent='root',min={-1,-1,-1},max={1,1,1}} end,
    GetUnitPieceMatrix=function(_,id)
        local p=positions[id] or {0,0,0}
        return 1,0,0,0, 0,1,0,0, 0,0,1,0, p[1],p[2],p[3],1
    end,
    GetUnitPosition=function(id) if id==10 then return 20+now,0,20 end;return 0,0,0 end,
    GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0} end,
    GetGroundHeight=function()return 0 end,
    UnitScript={IsInMove=function(id,axis)return moving[id] and moving[id][axis]~=nil end,
        IsInTurn=function(id,axis)return turning[id] and turning[id][axis]~=nil end,GetPieceTranslation=function(id)return unpack(positions[id] or {0,0,0}) end},
}
function restoreMessageOriginalPosition(ids,p)
    restores=restores+1
    if restores>1 then
        for _,id in ipairs(ids) do
            assert(not next(moving[id] or {}),'restore teleports while old moves still run')
            assert(not next(turning[id] or {}),'restore leaves old rocking turns running')
        end
    end
    for _,id in ipairs(ids) do for axis=1,3 do Move(id,axis,p[id][axis],0);Turn(id,axis,0,0) end end
end
assert(loadstring(table.concat(aliases,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
local function clear()
    positions,angles,moving,turning,now,restores,reports,spin={},{},{},{},0,0,{},nil
end
clear()
local mover=assert(hologramWorldMover(9,1,{0,0,0},{root=textSpinner}))
mover(100,0,0,1);advance(0.1)
near(positions[1][1],10)
mover(101,0,0,0.2);near(moving[1][1].speed,455)
advance(0.1);near(positions[1][1],55.5)
mover(101,0,0,0.2);near(moving[1][1].speed,227.5)
Move(1,1,200,1)
mover(20,0,0,0);near(moving[1][1].target,20)
advance(0.1);near(positions[1][1],20);assert(not moving[1][1])
for _,dies in ipairs({false,true}) do
    clear();deathTime=dies and 1 or nil
    local ids={1,2}
    local p={unitID=9,[1]={0,0,0},[2]={0,-321,0},spinnerSpeed=-0.2,
        debugTextFx=function(message)reports[#reports+1]=message end}
    civilianCongaText(ids,p)
    assert(restores==2 and now<19 and spin==-0.2)
    assert(#reports==2 and reports[1]:find('civilian_test',1,true))
    assert(reports[2]:find(dies and 'target disappeared' or 'completed',1,true))
    advance(1)
    for _,id in ipairs(ids) do for axis=1,3 do near(positions[id][axis],p[id][axis]);near(angles[id][axis],0) end end
end
-- Hidden letters reset immediately; visible cleanup is bounded even when an
-- engine animation would otherwise take minutes to complete.
local hidden={}
function hideTReg(ids)for _,id in ipairs(ids)do hidden[id]=true end end
clear();Move(1,1,100,1);Turn(1,2,2,0.01)
assert(waitHologramTextCleanup({1},{},5000))
assert(hidden[1] and now<0.1 and not next(moving[1]) and not next(turning[1]))
Move(1,1,25,0);advance(0.1);near(positions[1][1],25)
clear();hidden={};Move(1,1,100,1);Turn(1,2,2,0.01)
assert(not waitHologramTextCleanup({1},{[1]=true},5000))
assert(hidden[1] and now>=5 and now<5.1)
near(positions[1][1],0);near(angles[1][2],0)
assert(not next(moving[1]) and not next(turning[1]))
clear();hidden={};Move(1,1,0.12,1)
assert(waitHologramTextCleanup({1},{[1]=true},5000))
assert(not hidden[1] and now>=0.12 and now<0.2);near(positions[1][1],0.12)
clear();hidden={}
function HideReg(id)hidden[id]=true end
function ShowReg(id)hidden[id]=nil end
function randSign()return 1 end
local cleanupIds,cleanupPositions={},{}
for id=1,20 do
    cleanupIds[id]=id;cleanupPositions[id]={0,-321*id,0}
    Move(id,2,-321*id,0)
end
assert(not HideLetters(cleanupIds,cleanupPositions,nil,5000))
assert(now>=5 and now<5.2,'long cleanup failed to hit deadline')
for _,id in ipairs(cleanupIds)do assert(hidden[id]);for axis=1,3 do near(positions[id][axis],0)end end
clear();hidden={}
local random=math.random;math.random=function()return 4 end
assert(HideLetters({1},{[1]={0,-321,0}},nil,5000))
math.random=random
assert(not hidden[1]);near(positions[1][2],-321)
print('conga: actual-position speeds, stale-target replacement, bounded cleanup, hidden reset and stable restored phrase PASS')
