-- The six existing lantern spline floats, exported together without a truck.
-- Numbering preserves their editable CONTAINER66..CONTAINER71 source roots.
return {
    unitName = "truckpayloadparade",
    modelName = "truckPayloadParade.dae",
    carrierNames = {"truck_arab6", "truck_arab7", "truck_arab8"},
    -- Measured against each actual bed under the 17.6 x 45.6 float skid.
    -- The narrow skid fits inside truck_arab8's raised service-body walls.
    carrierOffsets = {
        truck_arab6 = {y = 0, z = -3.5},
        truck_arab7 = {y = 3.2, z = 1},
        truck_arab8 = {y = -1.8, z = 0},
    },
    variants = {
        {key = "forest_dreamer", title = "The Forest Dreamer", pieceName = "container66",
            pieces = {"container66"}},
        {key = "wandering_bathhouse", title = "The Wandering Bathhouse", pieceName = "container67",
            pieces = {"container67"}},
        {key = "moonwhale", title = "The Moonwhale", pieceName = "container68",
            pieces = {"container68", "container68ActFinLeft", "container68ActFinRight", "container68ActTail"},
            motion = {
                {pieceName = "container68ActFinLeft", axis = "z", angle = -4},
                {pieceName = "container68ActFinRight", axis = "z", angle = 4},
                {pieceName = "container68ActTail", axis = "x", angle = -3},
            }},
        {key = "lantern_koi", title = "The Lantern Koi", pieceName = "container69",
            pieces = {"container69"}},
        {key = "cloud_mill", title = "The Cloud Mill", pieceName = "container70",
            pieces = {"container70", "container70ActWindmillRotor"},
            -- The rotor's authored axis is horizontal, facing the truck's cab.
            motion = {{pieceName = "container70ActWindmillRotor", axis = "z", spin = 18}}},
        {key = "night_post", title = "The Night Post", pieceName = "container71",
            pieces = {"container71", "container71ActForewing1", "container71ActHindwing1",
                "container71ActForewing3", "container71ActHindwing3"},
            motion = {
                {pieceName = "container71ActForewing1", axis = "z", angle = -3},
                {pieceName = "container71ActHindwing1", axis = "z", angle = -3},
                {pieceName = "container71ActForewing3", axis = "z", angle = 3},
                {pieceName = "container71ActHindwing3", axis = "z", angle = 3},
            }},
    },
}
