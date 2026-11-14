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

-- Matched to the original design sheets and the current exported silhouettes.
-- Titles and lore are independent of the existing hologram theme selection.
local dedications = {
    {"The Forest Dreamer", "A woodland shrine to the sleeping guardian; its faithful keep a lantern burning for every forest the city has forgotten."}, -- Float01
    {"The Wandering Bathhouse", "A travelling sanctuary whose devotees wash away the day's sins, debts and identities before returning to the street."}, -- Float02
    {"The Moonwhale", "Guardian of those adrift in the night; its followers light the passage between the living city and its remembered dead."}, -- Float03
    {"The Lantern Koi", "A shrine to patient fortune; the faithful follow its light upstream, hoping persistence will succeed where prayer has failed."}, -- Float04
    {"The Night Post", "Patron of undelivered words; its moth-winged shrine carries letters to the absent, the missing and the dead."}, -- Float05
    {"Paper Cranes", "A memorial to lives lost beneath the mushroom cloud; each folded crane carries a wish that no city must learn that prayer again."}, -- Float06
    {"Harbour of Lanterns", "A memorial to the drowned and the homes taken by the wave; lanterns mark the harbour to which they cannot return."}, -- Float07
    {"Ash to Blossom", "A shrine of remembrance beneath the volcano; its mourners plant hope in the ash without forgetting what lies below."}, -- Float08
    {"Reactor Garden", "A memorial to the abandoned gardens around the reactor; its keepers tend the living things that returned before their owners could."}, -- Float09
    {"The Returning Tide", "A memorial to seas blackened by oil; its seabird carries the hope of a tide that brings life back to shore."}, -- Float10
    {"Breath of Remembrance", "A memorial to those taken by poisoned air; an offered breath becomes a promise to remember the people behind the numbers."}, -- Float11
    {"Couch-Potabhodism", "The reclining saint teaches salvation through perfect repose. His followers await enlightenment without leaving the couch."}, -- Float12
    {"Hashing Monks - St. Luddite", "The monks turn their numbered prayer wheels for St. Luddite, trusting that one more sacred computation will reveal the answer."}, -- Float13
    {"Church of the Cycle of Re", "The faithful sort their offerings beneath the endless arrow: everything shall return, redeemed, repackaged and ready to consume."}, -- Float14
    {"Church of the Sim", "A shrine to the world behind the world; its congregation prays that the next intervention from above will be a benevolent one."}, -- Float15
    {"Saint Bureaucracia", "Patron saint of forms, queues and pending approval. No prayer reaches heaven without the correct stamp and a duplicate copy."}, -- Float16
    {"Businessmany Cargo Cult", "The golden bull promises prosperity to those who imitate its rituals: raise the figures, summon the cargo and never question the forecast."}, -- Float17
    {"SanMonto - JohnBarleycorn", "The grain saint dies, ferments and rises in the communal barrel; his congregation celebrates resurrection one cup at a time."}, -- Float18
    {"Nastea - Pearl Carousel", "The faithful orbit the sacred cup, seeking sweetness, renewal and the next pearl at the bottom of an otherwise empty promise."}, -- Float19
    {"DoesNay-World - Paradise in a Suitcase", "A portable promised land for the holiday faithful: palm shade, perfect weather and salvation available as an optional upgrade."}, -- Float20
    {"Lord Ferrum", "The smith of heaven holds the sacred anvil aloft; his devotees honour the hands that forge, mend and bear the weight of the city."}, -- Float21
    {"D.O.N.T.", "The raised finger of the safety cult watches over every forbidden act. Its faithful seek deliverance by doing absolutely nothing unapproved."}, -- Float22
    {"Holy Drive", "The great notification bell calls the faithful to attention; every chime promises recognition, every raised thumb another small blessing."}, -- Float23
    {"The Cloud Mill", "A skyward shrine whose turning sails grind the worries of the waking city into clouds, giving its restless people permission to dream."}, -- Float24
}
for index, dedication in ipairs(dedications) do
    variants[index].title = dedication[1]
    variants[index].description = dedication[2]
end

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
