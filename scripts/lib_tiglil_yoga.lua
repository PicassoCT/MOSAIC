-- Two user-authored weightless-yoga poses, native DAE X/Y/Z degrees (Z up).
-- Keep all three lower-leg axes: these poses do not use hinge-only knees.
local M={repetitions=4,transitionMs=1600,holdMs=400,entryExitMs=1000,hoverHeight=3}
M.poses={
    {
        tlHead={-15.6,0,0},tlhairup={-71,0,0},tigLil={10.4,0,0},
        tlarm={31,-65,2},tlarmr={45,57.8,14.5},
        tllegUp={8.7,-16.7,2.2},tllegUpR={8.7,13.7,-2.2},
        tllegLow={-12,12,-3},tllegLowR={-13,-8.5,1.1},
    },
    {
        tlHead={4.6,0,0},tlhairup={-83,0,0},tigLil={3,0,0},
        tlarm={68,-54,-32},tlarmr={55,44,25},
        tllegUp={0,-16.7,5},tllegUpR={3,13.7,-3.2},
        tllegLow={15,12,-5},tllegLowR={8,-8,3},
    },
}
function M.play(api)
    api.prepare(M.hoverHeight,M.entryExitMs)
    api.sleep(M.entryExitMs+100)
    for repetition=1,M.repetitions do
        for _,pose in ipairs(M.poses) do
            for name,angles in pairs(pose) do api.turn(name,angles,M.transitionMs) end
            api.sleep(M.transitionMs+M.holdMs)
        end
    end
    api.restore(M.entryExitMs)
    api.sleep(M.entryExitMs+100)
    api.finish()
end
return M
