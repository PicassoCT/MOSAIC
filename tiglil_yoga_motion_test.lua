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
local poseFrames=math.ceil((yoga.transitionMs+yoga.holdMs)*30/1000)
local checked,lowestHover=0,math.huge
StartThread(advertiseWeightlessYoga)
while next(threads)do
    tick();local elapsed=frame-started
    assert(elapsed<30*25,'yoga routine never finishes')
    if elapsed>entryFrames and elapsed<entryFrames+poseFrames*8 then
        lowestHover=math.min(lowestHover,footHeight())
    end
    local sample=elapsed-entryFrames+3
    if sample>0 and sample%poseFrames==0 and checked<8 then
        checked=checked+1
        local expected=yoga.poses[(checked-1)%2+1]
        for name,a in pairs(expected)do
            for axis=1,3 do near(delta(math.rad(a[axis]),rotations[pieceIDs[name]][axis],true),0,1e-4)end
        end
    end
end
assert(checked==8,'did not hold both supplied poses in all four repetitions')
assert(lowestHover>1,'weightless yoga touches the floor: '..lowestHover)
assert(frame-started>=30*18 and frame-started<30*20,'unexpected yoga duration')
for _,name in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR','deathpivot','dancepivot'})do
    for _,v in ipairs(rotations[pieceIDs[name]])do near(delta(0,v,true),0,1e-5)end
end
near(translations[pieceIDs.tigLil][1],0,1e-5);near(translations[pieceIDs.tigLil][2],0,1e-5)
near(footHeight(),0,.001)
-- Destruction must stop the routine and its smoothing worker together.
local finished=false
StartThread(function()SetSignalMask(SIG_CORE+SIG_TIGLIL);advertiseWeightlessYoga();finished=true end)
for i=1,70 do tick()end
Signal(SIG_CORE);TigLilStopSmoothing()
for i=1,10 do tick()end
assert(not next(threads) and not finished,'cancelled yoga left a worker running')
print('PASS: all eight native yoga poses match supplied XYZ; hover clearance '..lowestHover..'; neutral exit and cancellation')
]=]
assert(loadstring(source))()
