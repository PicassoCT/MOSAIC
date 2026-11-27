-- Shared noon-offset simulation clock. Day one remains Monday, preserving the
-- existing seventh-evening parade schedule; weekday numbering is ISO 1..7.
local M = {}
function M.Clock(frame, dayLength)
    local shifted = frame + dayLength / 2
    return math.floor(shifted / dayLength) + 1, (shifted % dayLength) * 24 / dayLength
end
function M.Weekday(day) return (day - 1) % 7 + 1 end
function M.AtHour(day, hour, dayLength)
    return math.floor((day - 1 + hour / 24 - .5) * dayLength)
end
return M
