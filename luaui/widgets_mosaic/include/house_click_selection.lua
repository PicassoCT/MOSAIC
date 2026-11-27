-- Select an owned installation through its containing civilian building.
-- Private host links also cover new house variants without a second type list.
return function(Spring)
    local pending
    local hostRule = 'house_icon_host_'
    local controller = {}

    local function commandActive()
        local index = Spring.GetActiveCommand()
        return index and index ~= 0
    end

    local function selectable(id, team)
        return Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
            and Spring.GetUnitTeam(id) == team and not Spring.GetUnitNoSelect(id)
    end

    function controller:MousePress(x, y, button)
        pending = nil
        if button ~= 1 or Spring.GetSpectatingState() or Spring.IsGUIHidden()
            or Spring.IsAboveMiniMap(x, y) or commandActive()
            or not Spring.GetPlayerRulesParam then return end
        local alt, ctrl, meta, shift = Spring.GetModKeyState()
        if alt or ctrl or meta then return end
        local kind, house = Spring.TraceScreenRay(x, y)
        if kind ~= 'unit' then return end
        local team, player = Spring.GetMyTeamID(), Spring.GetMyPlayerID()
        local occupant
        for _, id in ipairs(Spring.GetTeamUnits(team) or {}) do
            if selectable(id, team) and Spring.GetPlayerRulesParam(player, hostRule .. id) == house
                and (not occupant or id < occupant) then occupant = id end
        end
        if not occupant then return end
        local selected = {}
        for _, id in ipairs(Spring.GetSelectedUnits()) do selected[#selected+1] = id end
        pending = {id=occupant, house=house, team=team, player=player,
            x=x, y=y, movement=0, shift=shift, selected=selected,
            threshold=Spring.GetConfigInt('MouseDragSelectionThreshold', 4)}
        -- Never own the mouse: the engine and SmartSelect retain box dragging.
    end

    function controller:Update()
        local click = pending
        if not click then return end
        local x, y, left, middle, right = Spring.GetMouseState()
        click.movement = click.movement + math.abs(x-click.x) + math.abs(y-click.y)
        click.x, click.y = x, y
        if middle or right or click.movement > click.threshold or commandActive()
            or Spring.GetSpectatingState() or Spring.IsGUIHidden()
            or Spring.GetMyTeamID() ~= click.team or Spring.GetMyPlayerID() ~= click.player then
            pending = nil
            return
        end
        if left then return end
        pending = nil
        -- Apply only after release, so engine click selection cannot undo it.
        if not selectable(click.id, click.team) or not Spring.ValidUnitID(click.house)
            or Spring.GetUnitIsDead(click.house)
            or Spring.GetPlayerRulesParam(click.player, hostRule .. click.id) ~= click.house then return end
        local kind, house = Spring.TraceScreenRay(x, y)
        if kind ~= 'unit' or house ~= click.house then return end
        local selected, wasSelected = {}, false
        if click.shift then
            for _, id in ipairs(click.selected) do
                if id == click.id then wasSelected = true
                elseif selectable(id, click.team) then selected[#selected+1] = id end
            end
        end
        if not wasSelected then selected[#selected+1] = click.id end
        Spring.SelectUnitArray(selected)
    end

    return controller
end
