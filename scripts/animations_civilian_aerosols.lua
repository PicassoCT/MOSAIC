-- SOURCE/Blender axes; setupAnimation() performs the normal Y/Z conversion.
local M={}
local axes={x_axis,y_axis,z_axis}
local names={'Head1','UpBody','UpArm1','UpArm2','LowArm1','LowArm2'}
local function pose(time,values)
    local commands={}
    for _,name in ipairs(names) do
        for axis,value in ipairs(values[name] or {0,0,0}) do
            commands[#commands+1]={c='turn',p=name,a=axes[axis],t=math.rad(value),s=2.4}
        end
    end
    return {time=time,commands=commands}
end
local function body(head,lean,arm,spread,elbow,tilt)
    return {Head1={head,tilt or 0,0},UpBody={lean,0,0},
        UpArm1={arm,-spread,0},UpArm2={arm+12,spread,0},
        LowArm1={elbow,0,12},LowArm2={elbow-10,0,-8}}
end
local function cycle(a,b)
    return {pose(0,a),pose(12,b),pose(24,a),{time=30,commands={}}}
end
function M.register(animations)
    animations.UPBODY_TOLLWUTOX=cycle(body(25,14,-55,14,-25,-12),body(12,20,-70,20,-40,9))
    animations.UPBODY_TOLLWUTOX_LUNGE=cycle(body(10,22,-85,14,-20,-5),body(30,26,-65,20,-45,12))
    animations.UPBODY_AEROSOL_STRIKE=cycle(body(8,15,-40,20,-85,-8),body(28,26,-110,8,-10,8))
    animations.UPBODY_WANDERLOST=cycle(body(34,12,-22,10,-10,-18),body(22,17,-42,16,-22,12))
    animations.UPBODY_DEPRESSOL=cycle(body(48,18,10,6,-8,-4),body(40,22,16,8,-12,4))
    animations.LOWBODY_AEROSOL_COLLAPSE={
        {time=0,commands={{c='turn',p='center',a=x_axis,t=math.rad(35),s=.8}}},
        {time=20,commands={{c='turn',p='center',a=x_axis,t=math.rad(85),s=.8}}},
        {time=40,commands={}},
    }
end
function M.clip(status,upper,moving,frame)
    local kind=status.aerosolType
    if kind~='tollwutox' and kind~='wanderlost' and kind~='depressol' then return end
    if upper then
        if (status.aerosolAttackUntil or 0)>frame then return 'UPBODY_AEROSOL_STRIKE',1.4 end
        if kind=='tollwutox' then
            return status.aerosolAgitated and 'UPBODY_TOLLWUTOX_LUNGE' or 'UPBODY_TOLLWUTOX',1
        end
        return kind=='wanderlost' and 'UPBODY_WANDERLOST' or 'UPBODY_DEPRESSOL',.85
    end
    if status.aerosolDrowning then return 'LOWBODY_AEROSOL_COLLAPSE',1 end
    if not moving then return 'LOWBODY_STANDING_ZOMBIE',.8 end
    if kind=='depressol' then return 'WALKCYCLE_WOUNDED',.6 end
    return 'LOWBODY_WALKING_ZOMBIE',status.aerosolAgitated and 1.25 or (kind=='wanderlost' and .55 or .7)
end
return M
