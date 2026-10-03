-- Shared dawn/dusk fade for cascade sources and night-only combat tracers.
local M={dayLength=28800,morningOffset=14400}
function M.Intensity(percent)
    local dawnEnd,duskStart=7/24,17/24
    if percent<dawnEnd then return 1-percent/dawnEnd end
    if percent>duskStart then return 1-(1-percent)/(1-duskStart) end
    return 0
end
function M.AtFrame(frame)
    return M.Intensity(((frame+M.morningOffset)%M.dayLength)/M.dayLength)
end
return M
