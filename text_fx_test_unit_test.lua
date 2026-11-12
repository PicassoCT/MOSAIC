-- Execute the actual preview script and shared FX with a unit-thread scheduler.
local header=assert(io.open('gamedata/unit_script_header.lua'))
local headerSource=header:read('*a');header:close()
x_axis=assert(tonumber(headerSource:match('local x_axis = (%d+)')))
y_axis=assert(tonumber(headerSource:match('local y_axis = (%d+)')))
z_axis=assert(tonumber(headerSource:match('local z_axis = (%d+)')))
unitID=7;script={};UnitDefs={};GG={}
local now,current,nextID=0,nil,0
local threads,announcements,drawn,spins={},{},{},{}
local completed,pendingMove,pendingTurn={},0,0
local cleanupFinished,visibleAtFinish={},{}
local groups,pieceMap={}, {text_spin=1}
local danceCalls,stoppedDance=0,false
for i,name in ipairs({'DirectionArcPoint','BallArcPoint','handr','handl','ball','tigLil'}) do pieceMap[name]=100+i end
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
local function overlaps(a,b)
    while a>0 and b>0 do
        if a%2==1 and b%2==1 then return true end
        a,b=math.floor(a/2),math.floor(b/2)
    end
    return false
end
function Signal(mask) for id,t in pairs(threads) do if overlaps(t.mask,mask) then threads[id]=nil end end end
function piece(name) return assert(pieceMap[name]) end
function Show(id) assert(type(id)=='number');drawn[id]=true end
function Hide(id) drawn[id]=nil end
function Move(id,axis,value,speed) assert(type(id)=='number' and axis>=1 and axis<=3 and value==value) end
function Turn(id,axis,value,speed) assert(type(id)=='number' and axis>=1 and axis<=3 and value==value) end
function Spin(id,axis,speed,accel)
    if id==1 then assert(axis==y_axis,'parent tips over');spins[speed]=true end
end
function StopSpin() end
function WaitForMove()
    if pendingMove>0 then local delay=math.max(0,pendingMove-now);pendingMove=0;Sleep(delay) end
end
function WaitForTurn()
    if pendingTurn>0 then local delay=math.max(0,pendingTurn-now);pendingTurn=0;Sleep(delay) end
end
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
Spring={UnitScript={IsInMove=function()return now<pendingMove end,IsInTurn=function()return now<pendingTurn end},GetGameSeconds=function()return now/1000 end,GetUnitPieceMap=function() return pieceMap end,SetUnitBlocking=function() end,SetUnitNeutral=function() end,
    SetUnitRulesParam=function() end,Echo=function(text)
        if text:find(' | ',1,true) then announcements[#announcements+1]={time=now,text=text} end
    end}
Spring.GetUnitPieceInfo=function() return {parent='text_spin'} end
Spring.GetUnitPieceMatrix=function() return 1,0,0,0, 0,0,-1,0, 0,1,0,0, 0,0,0,1 end
Spring.GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end
Spring.GetUnitPosition=function() return 0,0,0 end
Spring.GetGroundHeight=function() return 0 end
function include(file)
    if file=='lib_textFx.lua' then return dofile('scripts/'..file) end
    if file=='tigLilAnimation.lua' then
        function TigLilSetup() ShowReg(pieceMap.tigLil);Sleep(34) end
        function TigLilStopSmoothing() stoppedDance=true end
        local function routine()
            danceCalls=danceCalls+1
            assert(drawn[pieceMap.tigLil],'dancer hidden during text effects')
            Sleep(650)
        end
        idle_stance_10,idle_stance17,idle_stance_12=routine,routine,routine
        return {idle_stance11=routine}
    end
end
-- Detect accidental neon registration or special-renderer dependencies.
setmetatable(GG,{__newindex=function() error('test unit registered shared renderer state') end})
dofile('scripts/text_fx_test_script.lua')
local effects=getAllTextFx();local invoked={}
for name,fn in pairs(effects) do effects[name]=function(...)
    invoked[name]=true
    fn(...)
    completed[#announcements]=now
    visibleAtFinish[#announcements]=false
    for id in pairs(drawn) do if id<100 then visibleAtFinish[#announcements]=true end end
    -- Model a final Move/Turn still in flight when the effect function returns.
    pendingMove,pendingTurn=now+250,now+375
end end
getAllTextFx=function() return effects end
local cleanup=waitHologramTextCleanup
function waitHologramTextCleanup(...)
    local ok=cleanup(...)
    cleanupFinished[#announcements]=now
    return ok
end
script.Create()
while #announcements<94 do
    local nextThread
    for _,t in pairs(threads) do
        if not nextThread or t.wake<nextThread.wake or (t.wake==nextThread.wake and t.id<nextThread.id) then nextThread=t end
    end
    assert(nextThread,'preview stopped');now=nextThread.wake;resume(nextThread)
end
local longEffect=false
for i=2,#announcements do
    local start=announcements[i-1].time
    local finish=completed[i-1]
    if finish then
        if visibleAtFinish[i-1] then assert(cleanupFinished[i-1]>=finish+375,'cleanup did not wait for final motions') end
        assert(announcements[i].time==cleanupFinished[i-1]+5000+34,'hold began before animation and final motions finished')
        longEffect=longEffect or finish-start>5000
    else
        assert(announcements[i-1].text:find('plain',1,true),'effect was interrupted instead of completing')
        assert(announcements[i].time==cleanupFinished[i-1]+5000+34,'plain case lost its five-second hold')
    end
end
assert(longEffect,'did not exercise an animation longer than five seconds')
local spiralCases=0
for i=1,93 do
    if announcements[i].text:find('] spiralProject |',1,true) then
        spiralCases=spiralCases+1
        assert(announcements[i].text:find('upright spiral',1,true))
    end
end
assert(spiralCases==3,'spiral must appear once per rotation, without a lengthwise variant')
for name in pairs(effects) do assert(invoked[name],'mode skipped: '..name) end
assert(spins[math.rad(20)] and spins[math.rad(-20)],'missing rotation direction')
assert(danceCalls>93 and drawn[pieceMap.tigLil],'Tiglil must keep dancing through the full text cycle')
assert(script.Killed()==0 and stoppedDance)
assert(not next(threads),'killed unit left its cycling thread running')
local defEnv={lowerkeys=function(t)return t end}
setmetatable(defEnv,{__index=_G})
local def=setfenv(assert(loadfile('units/shared/text_fx_test.lua')),defEnv)().text_fx_test
assert(def.objectName=='house_western_hologram.dae' and def.script=='text_fx_test_script.lua')
assert(not def.customParams.neon_hologram_type and not def.customParams.house_icon_hologram)
print('PASS: all 28 shared FX, 93 complete animations followed by five-second holds, vertical-only spiral, both parent rotations and glyph cleanup')
