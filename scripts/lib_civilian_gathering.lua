-- An activity owns exactly one shared record; stale cleanup cannot stop panic,
-- prayer, transport or a player-directed protest which replaced that record.
return function(c)
    local api, state, generation = {}, nil, 0
    local clips={organizer="UPBODY_NORMAL_TALK",sign="UPBODY_PROTEST",chanter="UPBODY_PROTEST",
        speaker="UPBODY_NORMAL_TALK",filming="UPBODY_EVENT_FILM",couple="UPBODY_EVENT_WAVE",
        guest="UPBODY_EVENT_CLAP",instructor="UPBODY_EVENT_YOGA",yoga="UPBODY_EVENT_YOGA"}
    local function owns()
        return state and (GG.CivilianUnitInternalLogicActive or {})[unitID]==state
            and state.state==c.started
    end
    function api:IsActive(token) return owns() and (not token or state.token==token) or false end
    function api:OwnsUpperBody() return owns() and state.arrived and state.role~="onlooker" end
    function api:Stop(token, restore)
        if not state or (token and state.token~=token) then return false end
        local ours=owns()
        local current=(GG.CivilianUnitInternalLogicActive or {})[unitID]
        local newerActive=current~=state and type(current)=="table" and current.state==c.started
        if ours then state.state=c.ended end
        state=nil; generation=generation+1; self.animation=nil
        Signal(c.signal)
        if not newerActive then c.props(false) else c.hideStones() end
        c.mask(false)
        if ours and restore~=false then c.restore() end
        return ours or false
    end
    function api:Arrive(token)
        if not self:IsActive(token) then return false end
        state.arrived=true; return true
    end
    function api:Throw(token, target)
        if not self:IsActive(token) or not state.arrived or state.role=="sign"
            or not c.freeHands() or not c.stoneAvailable() or state.throw then return false end
        state.throw=target; return true
    end
    function api:Start(token,kind,role)
        local current=(GG.CivilianUnitInternalLogicActive or {})[unitID]
        if (type(current)=="table" and current.state or current)==c.started or not c.eligible() then return false end
        if role~="onlooker" and not c.freeHands() then role="onlooker" end
        self:Stop(nil,false)
        generation=generation+1
        local request=generation
        state={state=c.started,behaviour="gathering",token=token,kind=kind,role=role}
        GG.CivilianUnitInternalLogicActive=GG.CivilianUnitInternalLogicActive or {}
        GG.CivilianUnitInternalLogicActive[unitID]=state
        c.mask(kind=="protest")
        c.queue("gathering",function()
            if request~=generation or not owns() then return end
            SetSignalMask(c.signal)
            Sleep(unitID%7*90)
            while owns() and c.eligible() do
                if state.arrived and role~="onlooker" then
                    c.props(true,role)
                    local target=state.throw
                    if target and c.freeHands() then
                        state.throw=nil
                        local variant=c.holdStone()
                        local released=false
                        api.animation="UPBODY_EVENT_THROW"
                        c.play(api.animation,function(key)
                            if key==c.releaseKey and not released then
                                released=true
                                if owns() and c.eligible() and c.freeHands() then c.release(target,variant,token) end
                                c.hideStones()
                            end
                        end)
                        c.hideStones()
                    else
                        api.animation=clips[role]
                        if api.animation then c.play(api.animation) end
                    end
                end
                Sleep(500+unitID%5*110)
            end
            SetSignalMask(0)
            if request==generation then api:Stop(nil,owns()) end
        end,1)
        return role
    end
    return api
end
