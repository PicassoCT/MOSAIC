assert(_VERSION=='Lua 5.1')
x_axis,y_axis,z_axis=1,3,2
sizeSpacingLetter,sizeDownLetter=321,350
textSpinner=999
local now,positions,visible,trace,shows,turns,spins,restored
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function Move(id,axis,value,speed)
    assert(finite(value) and finite(speed) and speed>=0)
    positions[id]=positions[id] or {};positions[id][axis]=value
end
function Turn(id,axis,value,speed)
    assert(value==0,'spline tilted a readable glyph');turns=turns+1
end
function Spin(id,axis,speed) assert(id==textSpinner and axis==3);spins[id]=speed end
function StopSpin(id,axis) if spins[id] then spins[id]=nil end end
function HideReg(id) visible[id]=nil end
function ShowReg(id)
    assert(id~=textSpinner)
    visible[id]=true;shows[#shows+1]={id=id,time=now}
end
function hideTReg(ids) for _,id in ipairs(ids) do HideReg(id) end end
function Sleep(ms)
    now=now+ms
    if ms==50 then
        local frame={time=now}
        for id in pairs(visible) do frame[id]={unpack(positions[id])} end
        trace[#trace+1]=frame
    else assert(ms==34,'unexpected delay outside traversal') end
end
function restoreMessageOriginalPosition(ids,pos)
    restored=true
    for _,id in ipairs(ids) do
        for axis=1,3 do Move(id,axis,pos[id][axis],0) end
        ShowReg(id)
    end
end
dofile('scripts/lib_textFx.lua')
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b)) end
local function run(count,upright,seed,repeated)
    now,positions,visible,trace,shows,turns,spins,restored=0,{},{},{},{},0,{},false
    math.randomseed(seed)
    local ids,p={}, {spacing={},slotByPiece={},slotPositions={},leases={},spinnerSpeed=-0.3,boolUpright=upright}
    for slot=1,count do
        p.spacing[slot]=' ';p.slotPositions[slot]={17,-(slot-1)*321,23}
        if slot~=2 then -- a word gap must delay every later glyph
            local id=repeated and 1 or slot
            if not p[id] then ids[#ids+1]=id;p[id]=p.slotPositions[slot];p.slotByPiece[id]=slot end
            p.leases[id]=p.leases[id] or {};p.leases[id][#p.leases[id]+1]=slot
            if #p.leases[id]==1 then p.spacing[slot]=id end
        end
    end
    splineShapeFollowing(ids,p)
    assert(restored and spins[textSpinner]==-0.3)
    assert(now<=12000+(count-1)*300+68,'spline exceeded traversal deadline')
    assert(now>=300*(count-1),'trailing text was truncated')
    for _,id in ipairs(ids) do
        assert(visible[id]);for a=1,3 do near(positions[id][a],p[id][a]) end
    end
    if not repeated then
        -- Every unique glyph follows the exact same curve, with source-slot delay.
        for _,id in ipairs(ids) do
            local lag=(p.slotByPiece[id]-1)*6
            local compared=0
            for frame=1,#trace-lag do
                local lead,follower=trace[frame][ids[1]],trace[frame+lag][id]
                if lead then
                    assert(follower,'missing or truncated trailing glyph')
                    for axis=1,3 do near(lead[axis],follower[axis]) end
                    compared=compared+1
                end
            end
            assert(compared>20)
        end
        local lastY,minimum,maximum=nil,math.huge,0
        for _,frame in ipairs(trace) do
            local v=frame[ids[1]]
            if v then
                if lastY then assert(v[2]<lastY,'letter reversed or stopped on path') end
                lastY=v[2]
            end
        end
    else
        assert(#shows>count,'repeated glyph never visited borrowed slots')
    end
    return trace[40][ids[1]][3]
end
assert(getAllTextFx().splineShapeFollowing==splineShapeFollowing)
assert(canProjectTextFx('splineShapeFollowing',{boolUpright=true}))
local a=run(5,false,10,false)
local varied=false
for seed=11,18 do if run(5,true,seed,false)~=a then varied=true end end
assert(varied,'random seeds produced the same spline')
run(1,false,30,false)
run(60,true,40,false)
run(24,false,50,true)
now=0;splineShapeFollowing({},{});assert(now==0)
print('PASS: randomized spline, shared trajectory, word gaps, leases, long/single/empty phrases, time bound and restoration')
