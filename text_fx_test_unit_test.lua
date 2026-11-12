-- Execute the actual preview script and shared FX with a unit-thread scheduler.
x_axis,y_axis,z_axis=1,2,3
unitID=7;script={};UnitDefs={};GG={}
local now,current,nextID=0,nil,0
local threads,announcements,drawn,spins={},{},{},{}
local groups,pieceMap={}, {text_spin=1}
for code=65,90 do
    local name=string.char(code);groups[name]={}
    for n=1,3 do local id=2+(code-65)*3+n;groups[name][n]=id;pieceMap[name..n]=id end
end
local function resume(t)
    current=t
    local ok,delay=coroutine.resume(t.co)
    assert(ok,delay)
    if coroutine.status(t.co)=='dead' then threads[t.id]=nil else t.wake=now+(delay or 0) end
    current=nil
end
function StartThread(fn,...)
    nextID=nextID+1
    local args={...};local t={id=nextID,mask=current and current.mask or 0,wake=now}
    t.co=coroutine.create(function() fn(unpack(args)) end);threads[t.id]=t
    local caller=current;resume(t);current=caller
end
function Sleep(ms) assert(ms>=0);return coroutine.yield(ms) end
function SetSignalMask(mask) current.mask=mask end
function Signal(mask) for id,t in pairs(threads) do if t.mask==mask then threads[id]=nil end end end
function piece(name) return assert(pieceMap[name]) end
function Show(id) assert(type(id)=='number');drawn[id]=true end
function Hide(id) drawn[id]=nil end
function Move(id,axis,value,speed) assert(type(id)=='number' and axis>=1 and axis<=3 and value==value) end
function Turn(id,axis,value,speed) assert(type(id)=='number' and axis>=1 and axis<=3 and value==value) end
function Spin(id,axis,speed,accel)
    if id==1 then assert(axis==y_axis,'parent tips over');spins[speed]=true end
end
function StopSpin() end
function WaitForMove() end
function WaitForTurn() end
function WaitForMoves() end
function WaitForTurns() end
function reset(id) for axis=1,3 do StopSpin(id,axis,0);Turn(id,axis,0,0);Move(id,axis,0,0) end end
function resetT(ids) for _,id in ipairs(ids) do reset(id) end end
function foreach(t,fn) local out={};for _,id in ipairs(t) do local v=fn(id);if v then out[#out+1]=v end end;return out end
function WMove(...) Move(...) end
function WTurn(...) Turn(...) end
function tP(id,x,y,z,speed) for axis,v in ipairs({x,y,z}) do Turn(id,axis,math.rad(v),speed) end end
function randSign() return 1 end
function maRa() return false end
function count(t) return #t end
function getDayTime() return 23 end
function getAllNearUnit() return {} end
function getCivilianTypeTable() return {} end
function getPieceTableByNameGroups() return groups end
Spring={GetGameSeconds=function()return now/1000 end,GetUnitPieceMap=function() return pieceMap end,SetUnitBlocking=function() end,SetUnitNeutral=function() end,
    SetUnitRulesParam=function() end,Echo=function(text) announcements[#announcements+1]={time=now,text=text} end}
function include(file) if file=='lib_textFx.lua' then dofile('scripts/'..file) end end
-- Detect accidental neon registration or special-renderer dependencies.
setmetatable(GG,{__newindex=function() error('test unit registered shared renderer state') end})
dofile('scripts/text_fx_test_script.lua')
local effects=getAllTextFx();local invoked={}
for name,fn in pairs(effects) do effects[name]=function(...) invoked[name]=true;return fn(...) end end
getAllTextFx=function() return effects end
script.Create()
while #announcements<79 do
    local nextThread
    for _,t in pairs(threads) do
        if not nextThread or t.wake<nextThread.wake or (t.wake==nextThread.wake and t.id<nextThread.id) then nextThread=t end
    end
    assert(nextThread,'preview stopped');now=nextThread.wake;resume(nextThread)
end
for i=2,#announcements do assert(announcements[i].time-announcements[i-1].time==5000,'mode exceeded five seconds') end
for name in pairs(effects) do assert(invoked[name],'mode skipped: '..name) end
assert(spins[math.rad(20)] and spins[math.rad(-20)],'missing rotation direction')
assert(script.Killed()==0)
local defEnv={lowerkeys=function(t)return t end}
setmetatable(defEnv,{__index=_G})
local def=setfenv(assert(loadfile('units/shared/text_fx_test.lua')),defEnv)().text_fx_test
assert(def.objectName=='house_western_hologram.dae' and def.script=='text_fx_test_script.lua')
assert(not def.customParams.neon_hologram_type and not def.customParams.house_icon_hologram)
print('PASS: all 22 shared FX, 78 five-second cases, both parent rotations, glyph cleanup and ordinary model unit')
