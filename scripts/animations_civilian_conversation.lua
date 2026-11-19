-- Source/Blender axes, compiled once before setupAnimation like the prayer bank.
-- Uses the existing Turn-keyframe player; no extra coroutine or physics owner.
local M = {}
local pieces = {'Head1','UpBody','UpArm1','UpArm2','LowArm1','LowArm2'}
local axes = {x_axis,y_axis,z_axis}
local neutral = {
    Head1={0,0,0}, UpBody={0,0,0},
    UpArm1={0,-12,0}, UpArm2={0,12,0},
    LowArm1={-12,0,0}, LowArm2={-12,0,0},
}
-- Distinct communicative beats, not independent random noise on each joint.
-- Shoulder/elbow lead, head acknowledgement and torso counterweight are linked.
local profiles = {
    {name='EXPLAIN', bank='UPBODY_NORMAL_TALK', duration=90, side=1, lift=-35, bend=-65, spread=23, twist=20, nod=7, lean=3, beats=2},
    {name='OFFER', bank='UPBODY_NORMAL_TALK', duration=102, side=-1, lift=-48, bend=-42, spread=29, twist=38, nod=4, lean=2, beats=1},
    {name='WEIGH', bank='UPBODY_NORMAL_TALK', duration=96, side=1, lift=-32, bend=-70, spread=32, twist=25, nod=5, lean=-2, beats=2, bilateral=.75},
    {name='REASSURE', bank='UPBODY_NORMAL_TALK', duration=108, side=-1, lift=-20, bend=-82, spread=16, twist=10, nod=9, lean=4, beats=1},
    {name='QUALIFY', bank='UPBODY_NORMAL_TALK', duration=84, side=1, lift=-42, bend=-55, spread=19, twist=-12, nod=-4, lean=-3, beats=2},
    {name='INSIST', bank='UPBODY_AGGRO_TALK', duration=72, side=1, lift=-72, bend=-58, spread=20, twist=12, nod=10, lean=7, beats=2},
    {name='CHALLENGE', bank='UPBODY_AGGRO_TALK', duration=84, side=-1, lift=-58, bend=-80, spread=30, twist=-20, nod=-6, lean=5, beats=2},
    {name='DISMISS', bank='UPBODY_AGGRO_TALK', duration=78, side=1, lift=-48, bend=-36, spread=45, twist=32, nod=5, lean=-4, beats=1},
}
local pools={UPBODY_NORMAL_TALK={'UPBODY_NORMAL_TALK'},UPBODY_AGGRO_TALK={'UPBODY_AGGRO_TALK'}}
for _,p in ipairs(profiles) do
    p.clip=p.bank..'_'..p.name
    pools[p.bank][#pools[p.bank]+1]=p.clip
end
local function smooth(t)
    t=math.max(0,math.min(1,t));return t*t*t*(t*(t*6-15)+10)
end
local function envelope(t)
    -- Preparation, stroke, held thought, recovery; zero slope at both ends.
    return smooth(t/.26)*(1-smooth((t-.70)/.30))
end
local function pose(p,t)
    local result={}
    for _,name in ipairs(pieces) do
        result[name]={neutral[name][1],neutral[name][2],neutral[name][3]}
    end
    local e=envelope(t)
    local pulse=1-.13*math.sin(math.pi*p.beats*math.max(0,t-.24)/.50)^2
    local lead=p.side==1 and '1' or '2'
    local other=p.side==1 and '2' or '1'
    local function arm(suffix,amount,sign,delay)
        local weight=envelope(t-delay)*amount
        result['UpArm'..suffix]={p.lift*weight*pulse,neutral['UpArm'..suffix][2]-sign*p.spread*weight,p.twist*sign*weight*.18}
        result['LowArm'..suffix]={-12+(p.bend+12)*weight*pulse,0,p.twist*sign*weight}
    end
    arm(lead,1,p.side,0)
    arm(other,p.bilateral or .13,-p.side,.035)
    -- Let all channels arrive at neutral together, including delayed support.
    local release=1-smooth((t-.85)/.15)
    for _,name in ipairs(pieces) do
        for axis=1,3 do result[name][axis]=neutral[name][axis]+(result[name][axis]-neutral[name][axis])*release end
    end
    result.UpBody={p.lean*e,0,-p.side*2.5*e}
    result.Head1={p.nod*envelope(t-.04)*release,0,p.side*4*e}
    return result
end
local function compile(p)
    local clip={}
    local initial={time=0,commands={}}
    -- A short, bounded entry blend from the preceding clip's actual pose.
    for _,name in ipairs(pieces) do
        for axis=1,3 do initial.commands[#initial.commands+1]={c='turn',p=name,a=axes[axis],t=math.rad(neutral[name][axis]),s=3} end
    end
    clip[1]=initial
    local previous=pose(p,0)
    for frame=0,p.duration-3,3 do
        local nextPose=pose(p,(frame+3)/p.duration)
        local commands={}
        for _,name in ipairs(pieces) do
            for axis=1,3 do
                local delta=math.rad(nextPose[name][axis]-previous[name][axis])
                if math.abs(delta)>1e-7 then
                    commands[#commands+1]={c='turn',p=name,a=axes[axis],t=math.rad(nextPose[name][axis]),s=math.abs(delta)/.1}
                end
            end
        end
        clip[#clip+1]={time=12+frame,commands=commands}
        previous=nextPose
    end
    clip[#clip+1]={time=12+p.duration,commands={}}
    return clip
end
function M.register(animations)
    for _,p in ipairs(profiles) do animations[p.clip]=compile(p) end
end
function M.select(name,previous,random)
    local pool=pools[name]
    if not pool then return name end
    random=random or math.random
    -- Uniform choice among alternatives, without retry loops or repeat bias.
    local excluded
    for i,clip in ipairs(pool) do if clip==previous then excluded=i;break end end
    local index=random(1,#pool-(excluded and 1 or 0))
    if excluded and index>=excluded then index=index+1 end
    return pool[index]
end
return M
