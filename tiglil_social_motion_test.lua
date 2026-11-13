-- Check the real smoother/native interpolation, not just authored social poses.
local f=assert(io.open('tests/tiglil_precision_test.lua'));local source=f:read('*a');f:close()
source=source:sub(1,assert(source:find('local routines={',1,true))-1)
source=source:gsub("function include%(name%)return dofile%('scripts/'%.%.name%)end",[==[
local targetAvailable=true
local projection=false
function include(name)
    if name=='lib_tiglil_ground.lua' then
        return {new=function()return {
            begin=function(config)
                assert(config.personal)
                projection=targetAvailable
                return projection and {person=10,height=20,bodyScale=1} or false
            end,
            stop=function()projection=false end,
            isActive=function()return projection and targetAvailable end,
        }end}
    end
    return dofile('scripts/'..name)
end
]==])
source=source..[=[
assert(greetPasserby()==false,'personal interactions must be opt-in')
library.enablePeopleAnimations()

local geometry=include('lib_tiglil_dance.lua')
local scale=11060.378906/12
local function angles(name)
    local r=rotations[pieceIDs[name]] or {0,0,0}
    return {math.deg(r[1]),math.deg(r[3]),math.deg(r[2])}
end
local random=math.random
for _,entry in ipairs({{'greeting',greetPasserby},{'embrace',embracePasserby},{'danceEmbrace',danceEmbracePasserby},{'kiss',kissPasserby},{'invitation',invitePasserby}})do
for _,sign in ipairs({0,1})do
    StartThread(TigLilSetup);drain(1000)
    math.random=function(a,b)assert(a==0 and b==1);return sign end
    local started=frame
    local previous,yaw,distance=0,0,0
    local low,high=math.huge,-math.huge
    StartThread(entry[2])
    while next(threads)do
        tick();assert(frame-started<30*35,'social routine never finishes')
        local current=rotations[pieceIDs.tigLil][3]
        local step=delta(current,previous,true)
        yaw=yaw+step;distance=distance+math.abs(step);previous=current
        assert(math.abs(step)<math.rad(12),'turn jerks more than 12 degrees in one native frame')
        if frame-started>25 then
            local p={body=angles('tigLil'),left=angles('tllegUp'),right=angles('tllegUpR')}
            p.left[4]=angles('tllegLow')[1];p.right[4]=angles('tllegLowR')[1]
            local gap=translations[pieceIDs.tigLil][3]/scale-geometry.height(p)
            low,high=math.min(low,gap),math.max(high,gap)
        end
    end
    near(yaw,0,.001)
    assert(low>-.2 and high<.3,'support foot clips/floats during social routine: '..low..', '..high)
    near(translations[pieceIDs.tigLil][1],0,1e-5);near(translations[pieceIDs.tigLil][2],0,1e-5)
    assert(frame-started>30*5,'social routine rushed its choreography')
    for _,name in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR','deathpivot'})do
        for _,v in ipairs(rotations[pieceIDs[name]])do near(delta(0,v,true),0,1e-5)end
    end
    print('PASS: native '..entry[1]..' mirror '..sign..': neutral exit, floor range '..low..' to '..high)
end
end
math.random=random
assert(not projection,'projection leaked at end of interaction')
for _,routine in ipairs({embracePasserby,danceEmbracePasserby})do
    targetAvailable=true
    StartThread(TigLilSetup);drain(1000)
    local started=frame
    StartThread(routine)
    for i=1,40 do tick()end
    targetAvailable=false
    drain(100)
    assert(frame-started<30*5 and not projection,'departed pedestrian leaves an embrace running')
end
assert(greetPasserby()==false,'no-target interaction did not skip')
print('PASS: target departure interrupts interaction and absent people skip it')
]=]
assert(loadstring(source))()
