-- Event-driven slots: each returning booster owns its three nozzle flames.
-- Pad contact and the upward curl are evaluated locally, with no synced polling.
return function(unitID)
    local active, dead = {}, false
    local self = {}
    function self.Stop(booster)
        for _, slot in ipairs(active[booster] or {}) do
            if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID, slot) end
        end
        active[booster] = nil
    end
    function self.Start(booster, nozzles, pad)
        if dead or not GG.SmokeRibbon then return false end
        self.Stop(booster)
        active[booster] = {}
        for i, nozzle in ipairs(nozzles) do
            local slot = 'spaceport-landing-'..booster..'-'..i
            local ok, err = GG.SmokeRibbon.Set(unitID, slot, nozzle, {
                mode='landing', padPiece=pad, directionSpace='world', direction={0,-1,0},
                length=320, width=42, curl=0.65, speed=3, strands=4,
                colorStart={0.65,0.8,1,0.95}, colorEnd={1,0.25,0.04,0},
                emission={4,1}, windAffected=true, windInfluence=0.15, trailTime=0.5,
                distanceCulling=false, drawInIcon=true,
            })
            if not ok then
                Spring.Echo('Spaceport landing flame: '..tostring(err))
                self.Stop(booster)
                return false
            end
            active[booster][#active[booster]+1] = slot
        end
        return true
    end
    function self.Shutdown()
        dead = true
        for booster in pairs(active) do self.Stop(booster) end
    end
    return self
end
