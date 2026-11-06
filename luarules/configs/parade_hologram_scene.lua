-- World-anchored audiences own the close view; the original ten float-local
-- sprites remain the complete distance/capacity/renderer-failure fallback.
-- All positions/heights are game-world units; mesh vertices are already at
-- that scale and are drawn without the payload's FBX import transform.
local scene = {
    enabled = true, -- false restores the original native roadside projections
    maxVisiblePayloads = 4,
    maxDistance = 1150,
    fadeStart = 750,
    stationSpacing = 108,
    stationFadeSeconds = 1.6,
    visibilityResetSeconds = 3,
    groundRefreshSeconds = 1,
    viewRadius = 125,
    figures = {},
    props = {},
}

local families = {
    {prefix = "paradecivilian", category = "civilian", side = 37, along = {-25, 25},
        hover = 0, opacity = 0.74},
    {prefix = "paradedead", category = "dead", side = 43, along = {-13, 13},
        hover = 8.8, opacity = 0.55},
    {prefix = "paradeai", category = "ai", side = 51, along = {-34, 34},
        hover = 1.1, opacity = 0.70},
    {prefix = "paradehelper", category = "helper", side = 32, along = {-22, 22},
        hover = 0, opacity = 0.88},
}
for _, family in ipairs(families) do
    for index = 1, 4 do
        local side = index % 2 == 1 and -1 or 1
        scene.figures[#scene.figures + 1] = {
            model = family.prefix .. index, category = family.category,
            x = side * family.side, z = family.along[math.floor((index - 1) / 2) + 1],
            hover = family.hover, opacity = family.opacity,
            phase = index * 1.71 + #scene.figures * 0.37,
            task = family.category == "helper" and ({"tend", "gather", "guide", "inspect"})[index] or nil,
        }
    end
end

-- Ground candles never bob. Their flames are modeled geometry, with a very
-- small brightness pulse rather than a whole candle bouncing above the curb.
for _, side in ipairs({-1, 1}) do
    for _, along in ipairs({-25, 25}) do
        scene.props[#scene.props + 1] = {model = "candle", x = side * 34, z = along,
            y = 0, ground = true, opacity = 0.94, phase = along * 0.13 + side}
    end
end
local props = {
    {"lantern", -30, 8.5, -18}, {"lantern", 30, 10, 18},
    {"moon", -26, 24, 4}, {"envelope", 28, 15, -14},
    {"money", -28, 14, 18}, {"koi", 29, 17, 6},
    {"lotus", -28, 11, -6}, {"leaf", 26, 21, -25},
    {"star", -24, 27, -24}, {"star", 24, 25, 25},
    {"cloud", 22, 23, 0}, {"pinwheel", -25, 18, 28}, {"moth", 26, 14, 29},
}
for index, prop in ipairs(props) do
    scene.props[#scene.props + 1] = {model = prop[1], x = prop[2], y = prop[3], z = prop[4],
        opacity = 0.88, phase = index * 0.79}
end

return scene
