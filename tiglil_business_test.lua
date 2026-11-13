local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local dance=dofile('scripts/lib_tiglil_dance.lua')
local styles=dofile('scripts/lib_tiglil_business.lua')
local random=math.random
for _,sign in ipairs({0,1})do
    math.random=function()return sign end
    for name,style in pairs(styles)do
        local time,frames,finished=0,0,false
        local turns,move={},nil
        local minimumZ=0
        dance.play(name,{
            turn=function(id,a,ms)
                assert(ms>=100 and ms<=1600,'unreadable advertisement transition')
                for i=1,3 do assert(a[i]==a[i] and math.abs(a[i])<=180)end
                turns[id]=a
            end,
            move=function(id,a)
                assert(id=='tigLil','limb is detached by a translation')
                assert(math.abs(a[1])<1 and a[3]>=-8 and a[3]<=0,'walk left its bounded stage')
                move=a;minimumZ=math.min(minimumZ,a[3])
            end,
            sleep=function(ms)frames=frames+1;time=time+ms end,
            finish=function()finished=true end,
        },style)
        assert(finished and time>10000 and time<35000 and frames==#style.frames+2)
        assert(move[1]==0 and move[3]==0,'walk does not return to its starting mark')
        for _,id in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR'})do
            for i=1,3 do assert(turns[id][i]==0,'advertisement leaves a pose behind')end
        end
        if name=='runway' then assert(minimumZ==-8,'runway never walks forward')end
        if name=='presenter' then assert(minimumZ==-4,'presenter never walks onto the stage')end
        if name=='sales' then assert(minimumZ==0,'sales presenter drifts away from the display')end
    end
end
math.random=random

-- Execute the production pool registrations and loop configuration, so an
-- accidental casino/business condition change fails this test.
local source=read('scripts/house_western_hologram_script.lua')
local first=assert(source:find('idleAnimations[#idleAnimations +1] = idle_stance\n',1,true))
local last=assert(source:find('function waterFallProject',first,true))
local environment={idleAnimations={},technoAnimations={},businessAnimations={},businessPresentations={},tigLilAnimations={}}
setmetatable(environment,{__index=_G})
for name in source:sub(first,last-1):gmatch('= ([%w_]+)\n')do
    if name~='true' then environment[name]=function()end end
end
for _,name in ipairs({'advertiseSales','modelWalk','presentGala'})do environment[name]=function()end end
environment.tigLilAnimations.idle_stance11=function()end
environment.tigLilAnimations.idle_playBall=function()end
assert(setfenv(assert(loadstring(source:sub(first,last-1))),environment))()
local loopStart=assert(source:find('local function tiglLilLoop()',1,true))
local loopEnd=assert(source:find('--Direction',loopStart,true))
environment.TableOfPiecesGroups={GlowStick={1,2}}
local options
environment.createTigLilController=function(o)options=o;return {run=function()end}end
local configure=setfenv(assert(loadstring(source:sub(loopStart,loopEnd-1)..'\ntiglLilLoop()')),environment)
local function contains(pool,fn)for _,f in ipairs(pool)do if f==fn then return true end end;return false end
for _,kind in ipairs({'business','casino','normal'})do
    environment.boolIsBuisness=kind=='business';environment.boolIsCasino=kind=='casino'
    configure()
    for _,name in ipairs({'advertiseSales','modelWalk','presentGala'})do
        local fn=environment[name]
        assert(contains(options.animations,fn)==(kind=='business'),name..' leaked into '..kind)
        assert(not options.isTechnoAnimation(fn),'advertisement receives techno props')
    end
    if kind=='business' or kind=='casino' then
        for _,fn in ipairs(environment.technoAnimations)do
            assert(contains(options.animations,fn),'existing dance was removed from '..kind)
            assert(options.isTechnoAnimation(fn),'existing techno dance lost its props')
        end
    end
end
for _,file in ipairs({'house_western_brothel_hologram_script.lua','advertisingblimphologramscript.lua'})do
    local code=read('scripts/'..file)
    for _,name in ipairs({'advertiseSales','modelWalk','presentGala'})do
        assert(not code:find(name,1,true),name..' registered outside business')
    end
end

-- Run the shared controller through an old techno dance and a business
-- presentation. Sticks must be cleared when the next routine takes over.
local visible,performed={},0
unitID,unitDefID,GG,SIG_CORE,SIG_TIGLIL=3,4,{},2,128
SIG_HAIR,SIG_GESTE,SIG_TALKHEAD,SIG_INCIRCLE=4,32,16,8
function SetSignalMask()end
function Signal()end
function Sleep()coroutine.yield()end
function TigLilSetup()end
function ShowReg(id)visible[id]=true end
function hideTReg(ids)for _,id in ipairs(ids or {})do visible[id]=nil end end
function maRa()return false end
Spring={GetGameFrame=function()return 0 end,ValidUnitID=function()return true end,GetUnitIsDead=function()return false end,
    GetUnitPieceMap=function()return setmetatable({},{__index=function()return 1 end})end}
local danceThread
function StartThread(fn)danceThread=coroutine.create(fn);assert(coroutine.resume(danceThread))end
local old=function(techno)assert(techno and visible[1]);performed=performed+1 end
local advertisement=function(techno)assert(not techno and not next(visible));performed=performed+1 end
local picks=0
math.random=function(a,b)
    if a==1 and b==2 then picks=picks+1;return picks==1 and 1 or 2 end
    return a
end
local controller=dofile('scripts/lib_hologram_tiglil.lua')({pieces={},glowSticks={1},techno=true,
    animations={old,advertisement},isTechnoAnimation=function(fn)return fn==old end,
    available=function()return performed<2 end})
local lifecycle=coroutine.create(controller.run);assert(coroutine.resume(lifecycle))
assert(danceThread)
while coroutine.status(danceThread)~='dead' do assert(coroutine.resume(danceThread))end
assert(performed==2)
math.random=random
print('PASS: three bounded business routines; exclusive production pools; old dances retained; no glow sticks during presentations')
