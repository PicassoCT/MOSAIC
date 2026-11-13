-- Run the production smoother in the native float32/30 Hz scheduler. Preserve
-- every supplied XYZ component, including knee twist, throughout all repeats.
local f=assert(io.open('tests/tiglil_precision_test.lua'));local source=f:read('*a');f:close()
source=source:sub(1,assert(source:find('local routines={',1,true))-1)
source=source..[=[
local yoga=include('lib_tiglil_yoga.lua')
local geometry=include('lib_tiglil_dance.lua')
local scale=11060.378906/12
local function rotate(v,name)
    local a=rotations[pieceIDs[name]] or {0,0,0}
    local cx,sx,cy,sy,cz,sz=math.cos(a[1]),math.sin(a[1]),math.cos(a[2]),math.sin(a[2]),math.cos(a[3]),math.sin(a[3])
    local x,y=cz*v[1]-sz*v[2],sz*v[1]+cz*v[2]
    local z=sx*y+cx*v[3];y=cx*y-sx*v[3]
    return {cy*x+sy*z,y,-sy*x+cy*z}
end
local function footHeight()
    local lowest=math.huge
    for side,names in ipairs({{'tllegUp','tllegLow'},{'tllegUpR','tllegLowR'}}) do
        local leg=geometry.legGeometry[side]
        for _,point in ipairs(geometry.footVertices)do
            local v=rotate({point[1]*(side==1 and 1 or -1),point[2],point[3]},names[2])
            for k=1,3 do v[k]=v[k]+leg.knee[k] end
            v=rotate(v,names[1]);for k=1,3 do v[k]=v[k]+leg.hip[k] end
            v=rotate(v,'tigLil')
            lowest=math.min(lowest,12+translations[pieceIDs.tigLil][3]/scale+v[3])
        end
    end
    return lowest
end
StartThread(TigLilSetup);drain(1000)
local started=frame
local entryFrames=math.ceil((yoga.entryExitMs+100)*30/1000)
-- Capture timing, then verify every target in the native scheduler; support
-- editing the repetition count without weakening the warmup/ramp checks.
local sleeps,transitions={},{}
yoga.play({prepare=function()end,restore=function()end,finish=function()end,
    turn=function(name,a,ms)if name=='tigLil' then transitions[#transitions+1]=ms end end,
    sleep=function(ms)sleeps[#sleeps+1]=ms end})
local poseCount=yoga.repetitions*#yoga.poses
assert(#transitions==poseCount and #sleeps==poseCount+2)
local samples,posesEnd={},entryFrames
for i=1,poseCount do
    local ms=sleeps[i+1]
    if i<=yoga.warmupRepetitions*2 then
        assert(transitions[i]==yoga.transitionMs and ms==yoga.transitionMs+yoga.holdMs,'warmup accelerated')
    elseif i%2==1 then
        assert(transitions[i]<transitions[i-2] and ms<sleeps[i-1],'pair did not accelerate')
    end
    if i%2==0 then assert(transitions[i]==transitions[i-1],'speed changed midway through a pair')end
    assert(transitions[i]>=yoga.transitionMs/yoga.maxSpeed-.5,'speed exceeds maximum')
    posesEnd=posesEnd+math.ceil(ms*30/1000);samples[i]=posesEnd-3
end
near(transitions[poseCount],yoga.transitionMs/yoga.maxSpeed,.51)
local endFrames=posesEnd+math.ceil(sleeps[#sleeps]*30/1000)
local checked,lowestHover=0,math.huge
StartThread(advertiseWeightlessYoga)
while next(threads)do
    tick();local elapsed=frame-started
    assert(elapsed<endFrames+30,'yoga routine never finishes')
    if elapsed>entryFrames and elapsed<posesEnd then
        lowestHover=math.min(lowestHover,footHeight())
    end
    if elapsed==samples[checked+1] then
        checked=checked+1
        local expected=yoga.poses[(checked-1)%2+1]
        for name,a in pairs(expected)do
            for axis=1,3 do near(delta(math.rad(a[axis]),rotations[pieceIDs[name]][axis],true),0,1e-4)end
        end
    end
end
assert(checked==poseCount,'did not hold both supplied poses in every repetition')
assert(lowestHover>1,'weightless yoga touches the floor: '..lowestHover)
assert(frame-started>=endFrames and frame-started<endFrames+10,'unexpected accelerated yoga duration')
for _,name in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR','deathpivot','dancepivot'})do
    for _,v in ipairs(rotations[pieceIDs[name]])do near(delta(0,v,true),0,1e-5)end
end
near(translations[pieceIDs.tigLil][1],0,1e-5);near(translations[pieceIDs.tigLil][2],0,1e-5)
near(footHeight(),0,.001)
-- Destruction must stop the routine and its smoothing worker together.
local finished=false
StartThread(function()SetSignalMask(SIG_CORE+SIG_TIGLIL);advertiseWeightlessYoga();finished=true end)
for i=1,230 do tick()end -- interrupt after the warmup, during acceleration
Signal(SIG_CORE);TigLilStopSmoothing()
for i=1,10 do tick()end
assert(not next(threads) and not finished,'cancelled yoga left a worker running')
print('PASS: yoga warms up then accelerates to 2x; all XYZ poses reached; hover clearance '..lowestHover..'; neutral exit and cancellation')
]=]
assert(loadstring(source))()
