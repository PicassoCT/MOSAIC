-- One upper-body gesture owner shared by both civilian scripts. The parade
-- gadget owns movement; this helper never changes commands or walking speed.
return function(context)
    local state, generation = nil, 0
    local participation = {}

    function participation:IsActive()
        return state ~= nil and
            (GG.CivilianUnitInternalLogicActive or {})[unitID] == state and
            state.state == context.activityStates.started
    end

    function participation:Stop(restoreAnimation)
        local previous = state
        if not previous then return false end
        state = nil
        generation = generation + 1
        -- A panic, prayer call or aerosol may already own the shared record.
        -- Never clear or replace that newer activity during parade cleanup.
        local stillOwnsState = (GG.CivilianUnitInternalLogicActive or {})[unitID] == previous
        if stillOwnsState then
            previous.state = context.activityStates.ended
        end
        Signal(context.signal)
        if stillOwnsState and restoreAnimation ~= false then context.restoreAnimation() end
        return true
    end

    function participation:Start(callIndex)
        if self:IsActive() then return true end
        local current = (GG.CivilianUnitInternalLogicActive or {})[unitID]
        local currentState = type(current) == "table" and current.state or current
        if currentState == context.activityStates.started or not context.eligible() then
            return false
        end
        if state then self:Stop(false) end
        generation = generation + 1
        local requestGeneration = generation
        state = {state = context.activityStates.started, behaviour = "parade"}
        GG.CivilianUnitInternalLogicActive = GG.CivilianUnitInternalLogicActive or {}
        GG.CivilianUnitInternalLogicActive[unitID] = state
        context.selectAnimation(callIndex)
        context.queue("parade", function()
            -- Cancellation may happen before the queued coroutine gets a turn.
            if generation ~= requestGeneration or not participation:IsActive() then return end
            SetSignalMask(context.signal)
            context.prepareAnimation()
            while participation:IsActive() and context.eligible() do
                context.playAnimation()
                Sleep(250)
            end
            -- Do not let the stop signal cancel our own cleanup halfway through.
            SetSignalMask(0)
            local stillOwnsAnimation = participation:IsActive()
            participation:Stop(stillOwnsAnimation)
        end, 1)
        return true
    end

    return participation
end
