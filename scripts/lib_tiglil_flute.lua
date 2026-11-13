-- Calibrated to the three hologram DAE rigs, whose arms are shorter than
-- Journeywar's S3O arms. Values are native engine X/Y/Z Euler degrees (YXZ
-- composition), not the script's swapped y_axis/z_axis aliases.
-- Palm contacts (+/-5.1,-0.2,0.15) in retargeted body units meet the flute
-- centreline. Keep shoulder and flute translations at their bind positions.
return {
    across = {
        tlflute={15,0,65},
        tlarm={-2.634728,-8.612284,-46.484780},
        tlarmr={-40.197625,20.109212,131.583523},
    },
    acrossSway = {
        tlflute={14,0,62},
        tlarm={-1.933701,-7.503434,-42.547144},
        tlarmr={-41.541160,19.902526,133.480144},
    },
    forward = {
        tlflute={25,0,18},
        tlarm={3.993477,0.294134,-92.379952},
        tlarmr={-2.884740,4.839334,119.152509},
    },
    down = {
        tlflute={25,0,18},
        tlarm={25.106092,23.746910,-81.238726},
        tlarmr={29.152886,-13.854602,115.298873},
    },
    up = {
        tlflute={25,0,18},
        tlarm={-33.364061,-57.668762,-55.932894},
        tlarmr={-46.444457,73.197406,58.555435},
    },
}
