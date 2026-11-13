-- Journeywar's body rest height is 12; the hologram exports use 11060.378906
-- in their Z-up glyph space. Preserve movement proportions AND arrival times.
-- deathpivot translates in its parent's space, before its own 0.072006 scale.
-- Keep these calibrated to the three exported rigs (covered by the model test).
return function(motion, piece)
    local bodyScale = 11060.378906 / 12
    local scales = {}
    for _,name in ipairs({"tigLil", "dancepivot", "tldancedru", "tlHead",
        "tlhairup", "tlhairdown", "tlarm", "tlarmr", "tllegUp", "tllegLow",
        "tllegUpR", "tllegLowR", "tldrum", "tlpole", "tlflute"}) do
        scales[piece(name)] = bodyScale
    end
    scales[piece("deathpivot")] = bodyScale * 0.072006
    local authored = setmetatable({}, {__index=motion})
    function authored.Move(id, axis, target, speed)
        local scale = scales[id] or 1
        return motion.Move(id, axis, target * scale, speed and speed * scale)
    end
    function authored.MoveInTime(id, axis, target, milliseconds)
        return motion.MoveInTime(id, axis, target * (scales[id] or 1), milliseconds)
    end
    return authored
end
