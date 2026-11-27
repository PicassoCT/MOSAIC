-- Rebase the existing phone/filming curves onto model-specific arm directions.
-- Run after legacy axis correction and before setupAnimation; the solver
-- already accounts for the imported bind basis, including reflected limbs.
local M = {}
local profiles = {
    UPBODY_FILMING = {upper={-.18,-.55,-.82},lower={.10,-.65,.75},scale=.12},
    UPBODY_PHONE = {upper={-.30,-.90,-.30},lower={.30,.40,.85},scale=.10},
}
function M.register(bank, solve)
    local axes = {x_axis,y_axis,z_axis} -- setupAnimation resolves these to native XYZ
    for name,profile in pairs(profiles) do
        local clip = bank[name]
        if clip then
            local upper,lower = solve(1,profile.upper,profile.lower)
            local freeUpper,freeLower = solve(2,{.15,-.05,-1},{.05,-.10,-1})
            local bases = {UpArm1=upper,LowArm1=lower,UpArm2=freeUpper,LowArm2=freeLower}
            local first = {}
            for _,frame in ipairs(clip) do
                for _,cmd in ipairs(frame.commands) do
                    if cmd.c=='turn' and bases[cmd.p] then
                        local axis = cmd.a==x_axis and 1 or cmd.a==y_axis and 2 or 3
                        local key = cmd.p..axis
                        first[key] = first[key] or cmd.t
                        -- Keep the original keyframes, head/torso/prop work and
                        -- random variation, with bounded motion around the grip.
                        cmd.t = math.rad(bases[cmd.p][axis])+(cmd.t-first[key])*profile.scale
                        cmd.s = math.max(3,cmd.s*profile.scale)
                        if cmd.r then cmd.r=cmd.r*profile.scale end
                        if cmd.rl then cmd.rl=cmd.rl*profile.scale end
                        if cmd.ru then cmd.ru=cmd.ru*profile.scale end
                        cmd.a = axes[axis]
                    end
                end
            end
        end
    end
end
return M
