-- Temporary raid exposure. Own only the LOS bit, leaving other visibility
-- mechanisms (radar, permanent discovery, betrayal) intact.
return function(Spring, GG)
    GG.RaidersActive = GG.RaidersActive or {}
    local active = GG.RaidersActive
    local M = {}
    function M.Begin(id)
        if active[id] then return end
        if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return end
        local previous = {}
        active[id] = previous
        for _, ally in ipairs(Spring.GetAllyTeamList()) do
            local raw = Spring.GetUnitLosState(id, ally, true) or 0
            previous[ally] = {masked=math.floor(raw / 16) % 2 == 1, los=raw % 2 == 1}
            Spring.SetUnitLosMask(id, ally, {los=true})
            Spring.SetUnitLosState(id, ally, {los=true})
        end
        Spring.SetUnitCloak(id, false)
    end
    function M.End(id)
        local previous = active[id]
        if not previous then return end
        active[id] = nil
        if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return end
        if (GG.OperativesDiscovered or {})[id] == true
            or Spring.GetUnitRulesParam(id, 'betrayal_defector') == 1
            or Spring.GetUnitRulesParam(id, 'betrayal_pending') == 1 then return end
        for ally, state in pairs(previous) do
            if state.masked then Spring.SetUnitLosState(id, ally, {los=state.los}) end
            -- Removing our override lets the engine recompute natural LOS.
            Spring.SetUnitLosMask(id, ally, {los=state.masked})
        end
    end
    return M
end
