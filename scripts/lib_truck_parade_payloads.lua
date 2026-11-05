-- Re-exported Float01..Float24; child names deliberately have no leading zero.
local variants = {}
local themes = {"forest_dreamer", "wandering_bathhouse", "moonwhale",
    "lantern_koi", "night_post", "cloud_mill"}
for index = 1, 24 do
    local name = string.format("Float%02d", index)
    variants[index] = {key = string.format("float_%02d", index),
        title = "Lantern Float " .. index, pieceName = name, pieces = {name},
        hologramTheme = themes[(index - 1) % #themes + 1]}
end
local function identify(index, key, title)
    variants[index].key, variants[index].title = key, title
    variants[index].hologramTheme = key
end
identify(1, "forest_dreamer", "The Forest Dreamer")
identify(2, "wandering_bathhouse", "The Wandering Bathhouse")
identify(3, "moonwhale", "The Moonwhale")
identify(4, "lantern_koi", "The Lantern Koi")
identify(5, "night_post", "The Night Post")
identify(24, "cloud_mill", "The Cloud Mill")

local function motion(index, child, settings)
    local entry = variants[index]
    local name = "Float" .. index .. "Sub" .. child
    entry.pieces[#entry.pieces + 1] = name
    entry.motion = entry.motion or {}
    settings.pieceName = name
    entry.motion[#entry.motion + 1] = settings
end
-- Exported local X points along model -Z; local Z points up.
-- Gentle, staggered pendulum swings keep the authored suspension pivots fixed.
motion(1, 1, {axis = "x", angle = 4, halfPeriodMs = 2200})
-- The flag turns slightly around its upright pole; this is a rigid flag mesh.
motion(2, 1, {axis = "z", angle = 6, halfPeriodMs = 900})
for child = 2, 9 do
    motion(2, child, {axis = "x", angle = child % 2 == 0 and 4 or -4,
        halfPeriodMs = 1900 + (child % 3) * 200, delayMs = (child - 2) * 130})
end
-- Tail at its root, then four dangling ornaments beneath the fins.
motion(3, 1, {axis = "y", angle = 3, halfPeriodMs = 3000})
for child = 2, 5 do
    motion(3, child, {axis = "x", angle = child % 2 == 0 and 4 or -4,
        halfPeriodMs = 2300, delayMs = (child - 2) * 190})
end
-- Only this rotor spins. Its local X is the horizontal axle, not local Z.
motion(24, 1, {axis = "x", spin = 18, pauseMs = 3000, spinMs = 5000})

return {
    unitName = "truckpayloadparade",
    modelName = "truckPayloadParade.dae",
    carrierNames = {"truck_arab6", "truck_arab7", "truck_arab8"},
    -- COLLADA's meter=0.0254 scales the scene above center. Move destinations
    -- are in that parent's coordinates; convert model-space mounting offsets.
    centerMoveScale = 1 / 0.0254,
    carrierOffsets = {
        truck_arab6 = {y = 0, z = -3.5},
        truck_arab7 = {y = 3.2, z = 1},
        truck_arab8 = {y = -1.8, z = 0},
    },
    variants = variants,
}
