-- Capture commands from the real animation library, including its local helpers.
assert(_VERSION=='Lua 5.1')
x_axis,y_axis,z_axis=1,3,2
local ids,serial={},0
function piece(name) if not ids[name] then serial=serial+1;ids[name]=serial end;return ids[name] end
local calls={}
local api={}
for _,kind in ipairs({'Turn','Move','TurnInTime','MoveInTime','Spin','StopSpin'}) do
    api[kind]=function(id,axis,target,speed) calls[#calls+1]={kind,id,axis,target,speed} end
end
function api.cancel() end
Spring={UnitScript=api}
function include(name)
    if name=='lib_tiglil_motion.lua' then return function() return api end end
    return dofile('scripts/'..name)
end
function Sleep() end
function WaitForMoves() end
function WaitForTurns() end
function WaitForTurn() end
function ShowReg() end
function HideReg() end
function Signal() end
function whileInTurn() end
local f=assert(io.open('scripts/tigLilAnimation.lua'));local source=f:read('*a');f:close()
local prefix=assert(source:find('-------------------------------------------TIGLILI',1,true))
local helpers=assert(loadstring(source:sub(1,prefix-1)..
    'return {tP=tP,tSyncIn=tSyncIn,mSyncIn=mSyncIn,Move=Move}'))()
local scale=11060.378906/12
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a)..' ~= '..tostring(b)) end
local function find(kind,id,axis)
    for i=#calls,1,-1 do local c=calls[i];if c[1]==kind and c[2]==id and c[3]==axis then return c end end
    error('missing '..kind)
end
helpers.tP(piece('tigLil'),0,90,-30,4)
helpers.tSyncIn(piece('tigLil'),0,90,-30,250)
for axis=1,3 do
    near(find('Turn',ids.tigLil,axis)[4],find('TurnInTime',ids.tigLil,axis)[4])
end
near(find('TurnInTime',ids.tigLil,3)[4],math.pi/2)
helpers.Move(ids.tigLil,3,-8,19)
local c=find('Move',ids.tigLil,3);near(c[4],-8*scale);near(c[5],19*scale)
near(math.abs(c[4])/c[5],8/19) -- duration survives scale conversion
helpers.Move(piece('deathpivot'),3,2,2)
c=find('Move',ids.deathpivot,3);near(c[4],2*scale*0.072006);near(c[5],c[4])
helpers.mSyncIn(ids.tigLil,0,-4,12,450)
near(find('MoveInTime',ids.tigLil,3)[4],-4*scale)
near(find('MoveInTime',ids.tigLil,2)[4],12*scale)
near(find('MoveInTime',ids.tigLil,2)[5],450)
helpers.Move(piece('ball'),2,7,3)
c=find('Move',ids.ball,2);near(c[4],7);near(c[5],3)
-- The expanded pole routine keeps the prop still and moves the body around
-- the pole centre. Contact/geometry checks now live in tiglil_pole_model_test.
local pole=dofile('scripts/lib_tiglil_pole.lua')
local sample=pole.pose(pole.sequence[1],0)
near(sample.move[1]+pole.bodyBind[1],pole.pole[1]+pole.sequence[1].radius)
near(sample.move[2]+pole.bodyBind[2],pole.pole[2])
-- Exercise the production orbit scheduler; inner limb routines are irrelevant.
assert(loadstring(source))()
function danceInCircle() end
function danceEnd() end
function legs_down() end
calls={};idle_stance_10()
local orbit={}
local lapResets=0
for _,v in ipairs(calls) do
    if v[1]=='Turn' and v[2]==ids.tigLil and v[3]==3 and v[5]==0 then
        near(v[4],math.pi);lapResets=lapResets+1
    end
    if v[1]=='Turn' and v[2]==ids.dancepivot and v[5]==0.35 then orbit[#orbit+1]=math.deg(v[4]) end
end
assert(#orbit==20 and lapResets==5)
for i=1,#orbit,4 do
    assert(orbit[i]>=75 and orbit[i]<=105)
    assert(orbit[i+1]>=160 and orbit[i+1]<=190)
    assert(orbit[i+2]>=245 and orbit[i+2]<=290)
    near(orbit[i+3],360)
end
print('PASS: Tiglil timed axes, body/root scale and timing, positive orbit, pole-centred orbit, ball exclusion')
