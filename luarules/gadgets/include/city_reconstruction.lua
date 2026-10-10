-- Plot records are independent of unit IDs (which the engine reuses).
-- The adapter owns units/visuals; this state machine owns every stage clock.
return function(config, adapter)
    local self = {plots={}, byUnit={}, nextID=0}
    function self:Add(data)
        self.nextID = self.nextID + 1
        data.id, data.stage, data.elapsed = self.nextID, 'rubble', 0
        self.plots[data.id] = data
        return data
    end
    function self:LostUnit(id)
        local plot = self.byUnit[id]
        if not plot then return end
        self.byUnit[id], plot.unitID = nil, nil
        if plot.stage == 'construction' then plot.stage, plot.elapsed = 'rubble', 0 end
        return plot
    end
    function self:Update(frames)
        -- Numeric order also fixes CreateUnit/random order across simulations.
        local ids = {}
        for id in pairs(self.plots) do ids[#ids+1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local plot = self.plots[id]
            if plot then
                if plot.unitID and not adapter.Alive(plot.unitID) then self:LostUnit(plot.unitID) end
                if not plot.unitID then
                    plot.unitID = adapter.CreateRubble(plot)
                    if plot.unitID then self.byUnit[plot.unitID] = plot end
                end
                local peaceful = adapter.Peaceful(plot)
                plot.paused = not peaceful
                if plot.unitID and peaceful then
                    local duration = plot.stage == 'rubble' and config.decayFrames or config.constructionFrames
                    plot.elapsed = math.min(duration, plot.elapsed + frames)
                    if plot.elapsed >= duration then
                        if plot.stage == 'rubble' then
                            local site = adapter.CreateSite(plot)
                            if site then
                                local rubble = plot.unitID
                                self.byUnit[rubble] = nil
                                plot.unitID, plot.stage, plot.elapsed = site, 'construction', 0
                                self.byUnit[site] = plot
                                adapter.RemoveRubble(rubble)
                            end
                        else
                            adapter.Complete(plot)
                            self.byUnit[plot.unitID], self.plots[id] = nil, nil
                        end
                    end
                end
                if self.plots[id] and plot.unitID then adapter.Publish(plot) end
            end
        end
    end
    return self
end
