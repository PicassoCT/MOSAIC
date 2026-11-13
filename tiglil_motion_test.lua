-- Engine-like 30 Hz scheduler: native targets remain active until reached;
-- zero-speed commands snap WITHOUT clearing a queued animation.
assert(_VERSION=='Lua 5.1')
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua')
for _,name in ipairs({'tigLilAnimation.lua','lib_tiglil_motion.lua','lib_tiglil_retarget.lua','lib_hologram_tiglil.lua'})do
    assert(loadstring(header..'\n'..read('scripts/'..name)),name..' fails with production header')
end
local frame, threads, current, nextID = 0, {}, nil, 0
local moves, turns, translations, rotations, calls = {}, {}, {}, {}, {}
local function overlap(a,b)
    while a>0 and b>0 do
        if a%2==1 and b%2==1 then return true end
        a,b=math.floor(a/2),math.floor(b/2)
    end
    return false
end
local function resume(t)
    local caller=current;current=t
    local ok,delay=coroutine.resume(t.co);assert(ok,delay)
    if coroutine.status(t.co)=='dead' then threads[t.id]=nil
    else t.wake=frame+math.max(1,math.ceil(delay*30/1000)) end
    current=caller
end
function StartThread(fn,...)
    nextID=nextID+1
    local args={...};local t={id=nextID,mask=current and current.mask or 0}
    t.co=coroutine.create(function()fn(unpack(args))end);threads[t.id]=t;resume(t)
    return t
end
function Sleep(ms) return coroutine.yield(ms) end
function SetSignalMask(mask) current.mask=mask end
function Signal(mask) for id,t in pairs(threads) do if overlap(mask,t.mask) then threads[id]=nil end end end
local function delta(target,value,turn)
    if turn then return (target-value+math.pi)%(2*math.pi)-math.pi end
    return target-value
end
local function near(a,b,tolerance) assert(math.abs(a-b)<(tolerance or 1e-6),a..' ~= '..b) end
local function native(store,anims,kind,id,axis,target,speed)
    assert(type(id)=='number' and axis>=1 and axis<=3)
    assert(target==target and speed==speed and math.abs(speed)<math.huge)
    store[id]=store[id] or {0,0,0};anims[id]=anims[id] or {}
    calls[#calls+1]={kind=kind,id=id,axis=axis,target=target,speed=speed,frame=frame}
    if speed==0 then store[id][axis]=target
    else anims[id][axis]={target=target,speed=math.abs(speed)} end
end
local api={}
function api.Move(...)native(translations,moves,'move',...)end
function api.Turn(...)native(rotations,turns,'turn',...)end
function api.GetPieceTranslation(id)return unpack(translations[id] or {0,0,0})end
function api.GetPieceRotation(id)return unpack(rotations[id] or {0,0,0})end
function api.IsInMove(id,axis)return moves[id] and moves[id][axis]~=nil end
function api.IsInTurn(id,axis)return turns[id] and turns[id][axis]~=nil end
function api.Spin(id,axis,speed,accel)
    if turns[id] then turns[id][axis]=nil end
    calls[#calls+1]={kind='spin',id=id,axis=axis,speed=speed,accel=accel,frame=frame}
end
function api.StopSpin(id,axis,decel)calls[#calls+1]={kind='stop',decel=decel,frame=frame}end
function WaitForMove(id,axis)while api.IsInMove(id,axis) do Sleep(33) end end
function WaitForTurn(id,axis)while api.IsInTurn(id,axis) do Sleep(33) end end
function WaitForMoves(...)for _,id in ipairs({...})do for axis=1,3 do WaitForMove(id,axis) end end end
function WaitForTurns(...)for _,id in ipairs({...})do for axis=1,3 do WaitForTurn(id,axis) end end end
Spring={GetGameFrame=function()return frame end,GetWind=function()return 1,0,1 end,UnitScript=api}
local function tick()
    frame=frame+1
    for _,pair in ipairs({{translations,moves,false},{rotations,turns,true}})do
        for id,axes in pairs(pair[2])do
            for axis,a in pairs(axes)do
                local value=pair[1][id][axis];local d=delta(a.target,value,pair[3])
                if math.abs(d)<=a.speed/30+1e-12 then pair[1][id][axis]=a.target;axes[axis]=nil
                else pair[1][id][axis]=value+(d<0 and -1 or 1)*a.speed/30 end
            end
        end
    end
    local ready={}
    for _,t in pairs(threads)do if t.wake<=frame then ready[#ready+1]=t end end
    table.sort(ready,function(a,b)return a.id<b.id end)
    for _,t in ipairs(ready)do if threads[t.id]then resume(t)end end
end
local function advance(n)for _=1,n do tick() end end
local function drain(limit)
    local deadline=frame+(limit or 300)
    while next(threads) do assert(frame<deadline,'animation/wait stalled');tick() end
end
local makeMotion=dofile('scripts/lib_tiglil_motion.lua')
local motion=makeMotion(api,130)
local ended
StartThread(function()motion.Move(1,1,1,1);WaitForMove(1,1);ended=frame end)
advance(3);near(translations[1][1],0.00856)
advance(12);near(translations[1][1],0.5);assert(not ended,'wait ended at an intermediate waypoint')
advance(12);near(translations[1][1],0.99144)
drain();assert(ended==30);near(translations[1][1],1)
for _,call in ipairs(calls)do if call.kind=='move'then assert(call.target==1 and call.speed>0)end end

-- Shortest angular path through zero, never a nearly-complete revolution.
rotations[2]={math.rad(350),0,0}
motion.Turn(2,1,math.rad(10),math.rad(20))
advance(15);near(delta(0,rotations[2][1],true),0)
drain();near(delta(math.rad(10),rotations[2][1],true),0)

-- Repeated commands must not restart easing; overlapping poses remain monotonic.
local started=frame
motion.Move(3,1,1,1)
advance(10);motion.Move(3,1,1,1)
drain();assert(frame-started<=31)
motion.Move(3,1,3,2);advance(10)
local before=translations[3][1]
motion.Move(3,1,4,2)
local last=before
for _=1,80 do tick();assert(translations[3][1]>=last-1e-8 and translations[3][1]<=4);last=translations[3][1]end
drain();near(last,4)
motion.Move(3,1,-1,2);drain();near(translations[3][1],-1)

-- Snaps retire old targets, spins own their axis, cancellation can restart.
motion.Move(4,1,50,5);advance(4);motion.Move(4,1,7,0);advance(10)
near(translations[4][1],7);assert(not api.IsInMove(4,1))
motion.Turn(4,2,2,1);advance(4);motion.Spin(4,2,2)
local n=#calls;advance(10)
for i=n+1,#calls do assert(not(calls[i].kind=='turn' and calls[i].id==4 and calls[i].axis==2))end
motion.StopSpin(4,2);near(calls[#calls].decel,2/0.18)
motion.Spin(4,2,2,7);near(calls[#calls].accel,7)
motion.StopSpin(4,2,0);near(calls[#calls].decel,0)
motion.Move(4,3,100,2);advance(4);motion.cancel()
local frozen=translations[4][3];advance(20);near(translations[4][3],frozen)
assert(not next(threads))
motion.Move(4,3,2,2);drain();near(translations[4][3],2)
motion.Move(4,3,100,2);advance(4);Signal(130);motion.cancel()
motion.Move(4,3,0,5);drain();near(translations[4][3],0)

-- Timed poses finish together even with unequal distances.
local start=frame
motion.TurnInTime(5,1,1,550);motion.TurnInTime(5,2,-2,550)
advance(8);near(rotations[5][2],-2*rotations[5][1])
drain();assert(frame-start<=18);near(rotations[5][1],1);near(rotations[5][2],-2)

-- Load the actual authored library, preserving its production axis aliases.
x_axis,y_axis,z_axis=1,3,2
SIG_CORE,SIG_TIGLIL,SIG_HAIR,SIG_GESTE,SIG_TALKHEAD,SIG_INCIRCLE=2,128,4,32,16,8
local pieceIDs,serial={},20
function piece(name)if not pieceIDs[name]then serial=serial+1;pieceIDs[name]=serial end;return pieceIDs[name]end
function include(name)return dofile('scripts/'..name)end
function ShowReg()end
function HideReg()end
function echo()end
function printf()end
function maRa()return false end
function randSign()return 1 end
function whileInTurn(id,axis,fn,...)while api.IsInTurn(id,axis)do fn(...);Sleep(33)end end
ball,handl,handr,BallArcPoint,DirectionArcPoint=piece('ball'),piece('handl'),piece('handr'),piece('BallArcPoint'),piece('DirectionArcPoint')
local library=include('tigLilAnimation.lua')
assert(type(library.idle_stance11)=='function' and type(library.idle_playBall)=='function')
local setupDone=false
StartThread(function()TigLilSetup();setupDone=true end);drain(1000);assert(setupDone)
near(delta(math.rad(-74),rotations[pieceIDs.tlhairup][1],true),0)
near(delta(math.rad(-19),rotations[pieceIDs.tlhairdown][1],true),0)
-- Every twirl must return to the entry heading, in either direction.
local savedRandom=math.random
for _,choice in ipairs({0,1}) do
    math.random=function() return choice end
    rotations[pieceIDs.tigLil][y_axis]=math.pi
    for repeatIndex=1,3 do
        StartThread(danceInCircle);drain(1000)
        near(delta(math.pi,rotations[pieceIDs.tigLil][y_axis],true),0)
    end
end
math.random=savedRandom
-- The opening cartwheel pose must always lead through all three body poses
-- and back to neutral, without consulting randomness to skip the sequence.
StartThread(TigLilSetup);drain(1000)
math.random=function() error('cartwheel must not choose an early exit') end
local stages={{-90,0,0},{1,-90,90},{90,-187,0}}
local stage,deadline=1,frame+1000
StartThread(idle_stance4)
while next(threads) do
    assert(frame<deadline,'cartwheel did not finish')
    tick()
    if stages[stage] then
        local angles=rotations[pieceIDs.tigLil]
        local expected=stages[stage]
        if math.abs(delta(math.rad(expected[1]),angles[x_axis],true))<1e-6
            and math.abs(delta(math.rad(expected[2]),angles[y_axis],true))<1e-6
            and math.abs(delta(math.rad(expected[3]),angles[z_axis],true))<1e-6 then
            stage=stage+1
        end
    end
end
assert(stage==4,'cartwheel skipped an acrobatic pose')
for axis=1,3 do near(delta(0,rotations[pieceIDs.tigLil][axis],true),0) end
math.random=savedRandom
-- Real gait and timed pose callbacks exercise the scoped helpers too.
StartThread(tradWalk);drain(1000)
StartThread(shakeWalk);drain(1000)
near(delta(math.rad(-16),rotations[pieceIDs.tlHead][2],true),0)
near(delta(math.rad(-29),rotations[pieceIDs.tllegUpR][2],true),0)
StartThread(function()strikeAPose(false)end);drain(3000)
StartThread(idle_stance14);drain(3000) -- synchronized turns, including zero components
TigLilStopSmoothing();Signal(130);advance(2)
assert(not next(threads),'performer left motion workers behind')

-- Production lifecycle must stop easing before resetting hidden pieces.
unitID,unitDefID,GG=3,4,{}
Move,Turn,StopSpin=api.Move,api.Turn,api.StopSpin
function hideTReg()end
local ids={};for _,id in pairs(pieceIDs)do ids[#ids+1]=id end
local controller=dofile('scripts/lib_hologram_tiglil.lua')({pieces=ids,glowSticks={}})
StartThread(function()SetSignalMask(130);idle_stance14()end)
advance(5);controller.stop();advance(3)
assert(not next(threads),'show stop left animation workers alive')
for _,id in ipairs(ids)do for axis=1,3 do
    near((translations[id] or {0,0,0})[axis],0)
    near((rotations[id] or {0,0,0})[axis],0)
end end
StartThread(TigLilSetup);drain(1000)
print('PASS: Tiglil easing, native waits, angular wrap, retargets, timed joints, spin/snap/cancel and authored setup/gait/pose')
