-- Reproduce Recoil UnitScript.cpp MoveToward/TurnToward with float32 state,
-- including the float (dest-cur+THREEPI) angular wrap. Double-only mocks miss
-- the final-turn stall in TigLilSetup. Queued snaps and 30 Hz waits match the
-- native scheduler; actual Tiglil routines must finish without timeouts.
-- Float rounding here covers normal values used by these animation fixtures.
assert(_VERSION=='Lua 5.1')
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua')
for _,name in ipairs({'tigLilAnimation.lua','lib_tiglil_motion.lua','lib_tiglil_retarget.lua','lib_hologram_tiglil.lua'})do
    assert(loadstring(header..'\n'..read('scripts/'..name)),name..' fails with production header')
end
local function f32(x)
    if x==0 then return x end
    local sign=x<0 and -1 or 1
    local mantissa,exponent=math.frexp(math.abs(x))
    local scaled=mantissa*2^24
    local rounded=math.floor(scaled)
    if scaled-rounded>0.5 or (scaled-rounded==0.5 and rounded%2==1) then rounded=rounded+1 end
    return sign*math.ldexp(rounded,exponent-24)
end
local pi=f32(math.pi);local tau=f32(2*pi);local threepi=f32(3*pi)
local function clamp(x) return f32(x-f32(tau*math.floor(f32(x/tau)))) end

local frame, threads, current, nextID = 0, {}, nil, 0
local moves, turns, translations, rotations = {}, {}, {}, {}
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
    target=f32(target);speed=f32(speed);if kind=='turn' then target=clamp(target) end
    assert(type(id)=='number' and axis>=1 and axis<=3)
    assert(target==target and speed==speed and math.abs(speed)<math.huge)
    store[id]=store[id] or {0,0,0};anims[id]=anims[id] or {}
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
end
function api.StopSpin() end
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
                local value=pair[1][id][axis];local d=f32(a.target-value)
                if pair[3] then d=f32(f32(math.fmod(f32(d+threepi),tau))-pi) end
                local step=f32(a.speed/30)
                if math.abs(d)<=step then pair[1][id][axis]=a.target;axes[axis]=nil
                else pair[1][id][axis]=f32(value+(d<0 and -1 or 1)*step)
                    if pair[3] then pair[1][id][axis]=clamp(pair[1][id][axis]) end
                end
            end
        end
    end
    local ready={}
    for _,t in pairs(threads)do if t.wake<=frame then ready[#ready+1]=t end end
    table.sort(ready,function(a,b)return a.id<b.id end)
    for _,t in ipairs(ready)do if threads[t.id]then resume(t)end end
end
local function drain(limit)
    local deadline=frame+(limit or 300)
    while next(threads) do
        if frame>=deadline then
            for _,t in pairs(threads) do print(debug.traceback(t.co)) end
            error('native animation/wait stalled at float32 precision')
        end
        tick()
    end
end
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
SIG_ONTHEMOVE=64
local library=include('tigLilAnimation.lua')
assert(type(library.idle_stance11)=='function' and type(library.idle_playBall)=='function')
local setupDone=false
StartThread(function()TigLilSetup();setupDone=true end);drain(1000);assert(setupDone)
near(delta(math.rad(-74),rotations[pieceIDs.tlhairup][1],true),0)
near(delta(math.rad(-19),rotations[pieceIDs.tlhairdown][1],true),0)

assert(frame<60,'initial setup did not finish promptly')
local routines={
    {'idle_stance_10',idle_stance_10},
    {'idle_stance17',idle_stance17},
    {'danceShuffle',danceShuffle},
    {'danceDisco',danceDisco},
    {'dancePopping',dancePopping},
    {'danceJoi',danceJoi},
    {'danceShakira',danceShakira},
    {'dancePole',dancePole},
    {'danceBallet',danceBallet},
    {'advertiseSales',advertiseSales},
    {'modelWalk',modelWalk},
    {'presentGala',presentGala},
    {'advertiseWeightlessYoga',advertiseWeightlessYoga},
    {'idle_stance',idle_stance},
    {'idle_stance2',idle_stance2},
    {'idle_stance13',idle_stance13},
    {'idle_stance15',idle_stance15},
    {'idle_stance18',idle_stance18},
    {'danceBurlesqueSway',danceBurlesqueSway},
    {'danceBurlesqueWave',danceBurlesqueWave},
    {'danceBurlesqueFan',danceBurlesqueFan},
    {'lingerBrothel',lingerBrothel},
    {'danceBehindGlass',danceBehindGlass},
    {'idle_stance4',idle_stance4},
    {'idle_stance5',idle_stance5},
    {'danceHandstandSplit',danceHandstandSplit},
    {'idle_stance_12',idle_stance_12},
    {'idle_stance11',library.idle_stance11},
}
for _,seed in ipairs({1,17,99}) do
    math.randomseed(seed)
    for _,entry in ipairs(routines) do
        local completed=false
        StartThread(function() TigLilSetup();entry[2]();completed=true end)
        drain(30*600)
        assert(completed,entry[1]..' was interrupted')
    end
end
print('PASS: float32 native turns complete Tiglil setup and all twenty-eight tested routines across three random seeds')
