-- Source/Blender axes, compiled once before setupAnimation like the prayer bank.
-- Uses the existing Turn-keyframe player; no extra coroutine or physics owner.
local M = {}
local pieces = {'Head1','UpBody','UpArm1','UpArm2','LowArm1','LowArm2'}
local axes = {x_axis,y_axis,z_axis}
local neutral = {
    Head1={0,0,0}, UpBody={0,0,0},
    UpArm1={0,0,-33}, UpArm2={0,0,33},
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
    -- Expressive conversational beats, with elbows bent and hands in front.
    {name='GATHER_BOTH', bank='UPBODY_NORMAL_TALK', duration=108, side=1, lift=-52, bend=-82, spread=12, twist=8, nod=7, lean=3, beats=3, bilateral=1, emphasis=.30, fold=115},
    {name='OPEN_PALMS', bank='UPBODY_NORMAL_TALK', duration=114, side=-1, lift=-65, bend=-52, spread=60, twist=22, nod=5, lean=2, beats=2, bilateral=.9, emphasis=.25, fold=50, elbow=-85},
    {name='HAND_EMPHASIS', bank='UPBODY_NORMAL_TALK', duration=96, side=1, lift=-58, bend=-90, spread=16, twist=-8, nod=9, lean=4, beats=3, bilateral=.2, emphasis=.35, fold=120},
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
local function pose(p,t,neutral)
    local result={}
    for _,name in ipairs(pieces) do
        result[name]={neutral[name][1],neutral[name][2],neutral[name][3]}
    end
    local e=envelope(t)
    local pulse=1-(p.emphasis or .13)*math.sin(math.pi*p.beats*math.max(0,t-.24)/.50)^2
    local lead=p.side==1 and '1' or '2'
    local other=p.side==1 and '2' or '1'
    local function arm(suffix,amount,sign,delay)
        local weight=envelope(t-delay)*amount
        -- These are source-keyframe axes: setupAnimation swaps Y/Z.
        -- Local X pitches forward, mirrored local Z sweeps forward, and
        -- mirrored local Y bends the elbow inward (not behind the torso).
        result['UpArm'..suffix]={p.lift*.65*weight*pulse,sign*(18+p.twist*.2)*weight,
            neutral['UpArm'..suffix][3]+sign*p.spread*.35*weight}
        result['LowArm'..suffix]={-12+((p.elbow or p.bend*.35)+12)*weight*pulse,0,
            -sign*(p.fold or (85-p.bend*.2))*weight*pulse}
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
local function compile(p,neutral)
    local clip={}
    local initial={time=0,commands={}}
    -- A short, bounded entry blend from the preceding clip's actual pose.
    for _,name in ipairs(pieces) do
        for axis=1,3 do initial.commands[#initial.commands+1]={c='turn',p=name,a=axes[axis],t=math.rad(neutral[name][axis]),s=3} end
    end
    clip[1]=initial
    local previous=pose(p,0,neutral)
    for frame=0,p.duration-3,3 do
        local nextPose=pose(p,(frame+3)/p.duration,neutral)
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
-- The older ambient clips were authored around outstretched shoulders.
-- Retarget their existing curves, including random ranges, to a forward rest.
-- Keep all keyframes and props; do not affect aiming, carrying or prayer clips.
local ambientClips = {
    UPBODY_NORMAL_TALK={bothArms=true}, UPBODY_AGGRO_TALK={bothArms=true},
    UPBODY_PHONE={bothArms=false}, UPBODY_CONSUMPTION={bothArms=false},
}
local function retargetAmbient(animations, rest)
    local transforms = {}
    for side=1,2 do
        local sign=side==1 and 1 or -1
        transforms['UpArm'..side]={
            [x_axis]={scale=.35,bias=math.rad(-17)},
            [y_axis]={scale=-.35,bias=math.rad(sign*18)},
            [z_axis]={scale=.35,bias=math.rad(rest['UpArm'..side][3])},
        }
        transforms['LowArm'..side]={
            [x_axis]={scale=.30,bias=math.rad(-14)},
            [y_axis]={scale=.25,bias=0},
            [z_axis]={scale=-.45,bias=math.rad(-sign*30)},
        }
    end
    for name,profile in pairs(ambientClips) do
        local clip=animations[name]
        if clip then
            for _,frame in ipairs(clip) do
                for _,cmd in ipairs(frame.commands) do
                    local transform=transforms[cmd.p] and transforms[cmd.p][cmd.a]
                    if cmd.c=='turn' and transform and
                        (profile.bothArms or cmd.p=='UpArm2' or cmd.p=='LowArm2') then
                        local scale=transform.scale
                        cmd.t=cmd.t*scale+transform.bias
                        cmd.s=math.max(cmd.s*math.abs(scale),2.5)
                        if cmd.r then cmd.r=cmd.r*math.abs(scale) end
                        if cmd.rl or cmd.ru then
                            local low,high=(cmd.rl or 0)*scale,(cmd.ru or .01)*scale
                            cmd.rl,cmd.ru=math.min(low,high),math.max(low,high)
                        end
                    end
                end
            end
        end
    end
end
function M.register(animations, restingArms)
    local rest = {}
    for name, angles in pairs(neutral) do rest[name] = angles end
    if restingArms then
        rest.UpArm1 = restingArms.UpArm1
        rest.UpArm2 = restingArms.UpArm2
    end
    retargetAmbient(animations,rest)
    for _,p in ipairs(profiles) do animations[p.clip]=compile(p,rest) end
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
