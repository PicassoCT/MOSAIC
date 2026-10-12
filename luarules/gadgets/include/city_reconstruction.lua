-- Plot records are independent of unit IDs (which the engine reuses).
-- The adapter owns units/visuals; this state machine owns every stage clock.
return function(config, adapter)
    local self = {plots={}, byUnit={}, retiring={}, nextID=0, completed=0}
    -- Optional diagnostics keep this state machine usable without Spring/GG.
    local trace = adapter.Trace or function() end
    local function retire(plot, unitID)
        plot.sourceUnitID = unitID
        if unitID then self.retiring[unitID] = plot end
        trace(plot, 'source_removal_pending', {retiringUnitID=unitID})
    end
    function self:UnitCreated(unitID)
        -- Recoil can reuse an ID before the next lifecycle tick. Its new
        -- UnitCreated marks the previous lifetime as removed, even when the
        -- replacement happens to have exactly the same UnitDef.
        local plot = self.retiring[unitID]
        if plot then
            trace(plot, 'source_lifetime_cleared', {retiringUnitID=unitID})
            plot.sourceUnitID, self.retiring[unitID] = nil, nil
        end
    end
    function self:Add(data)
        self.nextID = self.nextID + 1
        data.id, data.stage, data.elapsed = self.nextID, 'rubble', 0
        self.plots[data.id] = data
        trace(data, 'plot_tracked', {defID=data.defID, x=data.x, z=data.z})
        retire(data, data.sourceUnitID)
        return data
    end
    function self:LostUnit(id)
        local plot = self.byUnit[id]
        if not plot then return end
        trace(plot, 'managed_unit_lost', {lostUnitID=id, lifecycleStage=plot.stage, elapsed=plot.elapsed})
        self.byUnit[id], plot.unitID = nil, nil
        retire(plot, id)
        if plot.stage == 'construction' then plot.stage, plot.elapsed = 'rubble', 0 end
        trace(plot, 'rubble_retry_queued', {lifecycleStage=plot.stage, elapsed=plot.elapsed})
        return plot
    end
    function self:GetStatus()
        -- Copy on request only: diagnostics must not expose mutable plot state
        -- or allocate snapshots on the regular simulation tick.
        local status = {queued=self.nextID, completed=self.completed, active=0,
            waitingForRemoval=0, rubble=0, construction=0, plots={}}
        local ids = {}
        for id in pairs(self.plots) do ids[#ids+1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local plot = self.plots[id]
            local waiting = plot.sourceUnitID ~= nil and adapter.Exists(plot.sourceUnitID)
            local info = {id=id, stage=plot.stage, x=plot.x, z=plot.z,
                originalUnitID=plot.originalUnitID, sourceUnitID=plot.sourceUnitID,
                sourceWaiting=waiting, unitID=plot.unitID, defID=plot.defID,
                rubbleDefID=plot.rubbleDefID, elapsed=plot.elapsed, paused=plot.paused,
                pauseReason=plot.pauseReason,
                rubbleSpawnAttempts=plot.rubbleSpawnAttempts or 0,
                rubbleSpawnFailures=plot.rubbleSpawnFailures or 0,
                siteSpawnAttempts=plot.siteSpawnAttempts or 0,
                siteSpawnFailures=plot.siteSpawnFailures or 0}
            status.plots[#status.plots+1] = info
            status.active = status.active + 1
            if plot.unitID then status[plot.stage] = status[plot.stage] + 1 end
            if waiting then status.waitingForRemoval = status.waitingForRemoval + 1 end
        end
        return status
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
                -- UnitDestroyed is sent before script.Killed, while the model
                -- and its footprint can remain for the entire death animation.
                -- A replacement belongs on the plot only after that lifetime
                -- is actually removed, not merely once GetUnitIsDead is true.
                if plot.sourceUnitID and not adapter.Exists(plot.sourceUnitID) then
                    trace(plot, 'source_removal_observed', {reason='unit-id-no-longer-valid'})
                    self:UnitCreated(plot.sourceUnitID)
                elseif plot.sourceUnitID then
                    trace(plot, 'source_removal_waiting', {reason='unit-id-still-valid'}, 150)
                end
                if not plot.unitID and not plot.sourceUnitID then
                    plot.rubbleSpawnAttempts = (plot.rubbleSpawnAttempts or 0) + 1
                    trace(plot, 'rubble_create_request', {attempt=plot.rubbleSpawnAttempts}, 150)
                    plot.unitID = adapter.CreateRubble(plot)
                    if plot.unitID then
                        self.byUnit[plot.unitID] = plot
                        trace(plot, 'rubble_spawned', {rubbleDefID=plot.rubbleDefID, attempt=plot.rubbleSpawnAttempts})
                    else
                        plot.rubbleSpawnFailures = (plot.rubbleSpawnFailures or 0) + 1
                        trace(plot, 'rubble_create_failed', {reason='adapter-returned-no-unit',
                            rubbleDefID=plot.rubbleDefID, failures=plot.rubbleSpawnFailures}, 150)
                    end
                end
                local peaceful, reason = adapter.Peaceful(plot)
                local wasPaused, previousReason = plot.paused, plot.pauseReason
                plot.paused = not peaceful
                plot.pauseReason = reason or (peaceful and 'none' or 'combat-or-quiet-period')
                if wasPaused ~= plot.paused or previousReason ~= plot.pauseReason then
                    trace(plot, plot.paused and 'rebuild_paused' or 'rebuild_peaceful',
                        {reason=plot.pauseReason, lifecycleStage=plot.stage, elapsed=plot.elapsed})
                end
                if plot.unitID and peaceful then
                    local duration = plot.stage == 'rubble' and config.decayFrames or config.constructionFrames
                    plot.elapsed = math.min(duration, plot.elapsed + frames)
                    if plot.elapsed >= duration then
                        if plot.stage == 'rubble' then
                            plot.siteSpawnAttempts = (plot.siteSpawnAttempts or 0) + 1
                            trace(plot, 'site_create_request', {defID=plot.defID, attempt=plot.siteSpawnAttempts}, 150)
                            local site = adapter.CreateSite(plot)
                            if site then
                                local rubble = plot.unitID
                                self.byUnit[rubble] = nil
                                plot.unitID, plot.stage, plot.elapsed = site, 'construction', 0
                                self.byUnit[site] = plot
                                trace(plot, 'site_spawned', {rubbleUnitID=rubble, defID=plot.defID})
                                trace(plot, 'old_rubble_remove_request', {rubbleUnitID=rubble})
                                adapter.RemoveRubble(rubble)
                                trace(plot, 'old_rubble_remove_returned', {rubbleUnitID=rubble})
                            else
                                plot.siteSpawnFailures = (plot.siteSpawnFailures or 0) + 1
                                trace(plot, 'site_create_failed', {reason='adapter-returned-no-unit',
                                    failures=plot.siteSpawnFailures}, 150)
                            end
                        else
                            trace(plot, 'rebuild_complete_request', {defID=plot.defID})
                            adapter.Complete(plot)
                            self.byUnit[plot.unitID], self.plots[id] = nil, nil
                            self.completed = self.completed + 1
                            trace(plot, 'rebuild_completed', {defID=plot.defID})
                        end
                    end
                end
                if self.plots[id] and plot.unitID then adapter.Publish(plot) end
            end
        end
    end
    return self
end
