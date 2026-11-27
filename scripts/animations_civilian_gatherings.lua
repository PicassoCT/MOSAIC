-- Source-space poses, registered before rig calibration and Y/Z conversion.
local M = {releaseKey=4}
local profiles={
    WAVE={duration=75, poses={{UpArm2={-35,-25,25},LowArm2={-45,0,95}},
        {UpArm2={-45,-15,40},LowArm2={-45,0,115}}}},
    CLAP={duration=90, poses={{UpArm1={-40,15,-15},UpArm2={-40,-15,15},LowArm1={-30,0,-110},LowArm2={-30,0,110}},
        {UpArm1={-40,8,-10},UpArm2={-40,-8,10},LowArm1={-30,0,-125},LowArm2={-30,0,125}}}},
    FILM={duration=105, poses={{UpArm1={-45,10,-15},UpArm2={-45,-10,15},LowArm1={-30,0,-115},LowArm2={-30,0,115},Head1={8,0,0}}}},
    YOGA={duration=240, poses={{UpArm1={-10,0,-70},UpArm2={-10,0,70},LowArm1={-5,0,0},LowArm2={-5,0,0}},
        {UpArm1={-60,0,-110},UpArm2={-60,0,110},LowArm1={-5,0,0},LowArm2={-5,0,0},UpBody={0,0,5}}}},
    THROW={duration=54, poses={{UpArm2={25,-10,65},LowArm2={-60,0,100},UpBody={0,0,-8}},
        {UpArm2={-80,-10,25},LowArm2={-12,0,15},UpBody={6,0,8}}}},
}
function M.register(bank, rest)
    local names={"Head1","UpBody","UpArm1","UpArm2","LowArm1","LowArm2"}
    local axes={1,2,3} -- profile X/Z/Y; setupAnimation swaps to native X/Y/Z
    for name,profile in pairs(profiles) do
        local clip={}
        -- At key 4 the forward stroke has completed: the held prop is released.
        local stages={{0,{}},{9,profile.poses[1]},{27,profile.poses[2] or profile.poses[1]},
            {36,profile.poses[2] or profile.poses[1]},{profile.duration,{}}}
        if name=="YOGA" then stages={{0,{}},{30,profile.poses[1]},{100,profile.poses[2]},
            {180,profile.poses[1]},{240,{}}} end
        for i,stage in ipairs(stages) do
            local commands={}
            -- Commands start at this key; they must finish before the next key
            -- (especially before the release callback at key four).
            local seconds=stages[i+1] and math.max(.1,(stages[i+1][1]-stage[1])/30) or .4
            for _,pieceName in ipairs(names) do
                local neutral=rest[pieceName] or {0,0,0}
                local pose=stage[2][pieceName] or neutral
                local previous=i>1 and (stages[i-1][2][pieceName] or neutral) or neutral
                for axis=1,3 do
                    commands[#commands+1]={c="turn",p=pieceName,a=axes[axis],t=math.rad(pose[axis]),
                        s=math.max(.15,math.rad(math.abs(pose[axis]-previous[axis]))/seconds)}
                end
            end
            clip[#clip+1]={time=stage[1],commands=commands}
        end
        bank["UPBODY_EVENT_"..name]=clip
    end
end
return M
