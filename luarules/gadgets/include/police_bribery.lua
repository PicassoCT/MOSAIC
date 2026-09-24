-- Police-only influence. Military response types deliberately never enter this whitelist.
local M = {}
function M.New(config, officers, position, move, canSee)
    local cfg = config.Bribe
    local bribeDef = UnitDefNames.icon_bribe.id
    local eligibleTypes = {}
    for _, name in ipairs({"policetruck", "riotpolice"}) do
        if UnitDefNames[name] then eligibleTypes[UnitDefNames[name].id] = true end
    end
    local operatives = getOperativeTypeTable(UnitDefs)
    local bribes, combatUntil, builders, witnessed = {}, {}, {}, {}
    local private = {private = true}
    GG.PoliceBribes = {}
    local api = {types = eligibleTypes}
    local function sorted(t)
        local ids = {}
        for id in pairs(t) do ids[#ids+1] = id end
        table.sort(ids)
        return ids
    end
    local function close(a, b)
        return a and b and (a.x-b.x)^2+(a.z-b.z)^2 <= cfg.radius^2
    end
    local function clearOfficer(id)
        if GG.PoliceBribes[id] then
            GG.PoliceBribes[id] = nil
            local state = officers[id]
            if state then state.nextOrder = 0 end
            Spring.GiveOrderToUnit(id, CMD.STOP, {}, {})
        end
    end
    local function matches(bribe, incident)
        if not bribe.target or not incident then return true end
        return incident.attacker == bribe.target or
            (incident.kind == "cybercrime" and GG.CyberCrime and
                GG.CyberCrime.GetBuilder(incident.attacker) == bribe.target)
    end
    local function threat(id, state, frame)
        if (combatUntil[id] or 0) > frame then return true end
        local sighting = witnessed[id]
        if sighting and frame < sighting.expires and canSee(id,sighting.attacker) then return true end
        local incident = state and state.incident
        return incident and incident.kind ~= "cybercrime" and canSee(id, incident.attacker)
    end
    local function publish(id, bribe)
        Spring.SetUnitRulesParam(id, "bribe_until", bribe.ends, private)
        Spring.SetUnitRulesParam(id, "bribe_target", bribe.target or -1, private)
        Spring.SetUnitRulesParam(id, "bribe_count", #bribe.officers, private)
        for n=1,cfg.maxOfficers do
            Spring.SetUnitRulesParam(id, "bribe_officer_"..n, bribe.officers[n] or -1, private)
        end
    end
    function api.Created(id, defID, builder)
        if defID == bribeDef then builders[id] = builder end
    end
    function api.Finished(id, defID, team)
        if defID ~= bribeDef or bribes[id] then return end
        local p = position(id)
        if not p then return end
        local frame = Spring.GetGameFrame()
        bribes[id] = {team = team, ends = frame+cfg.durationFrames, goal = p, officers = {}}
        local builder = builders[id]
        if position(builder) and operatives[Spring.GetUnitDefID(builder)] and Spring.GetUnitTeam(builder)==team then
            bribes[id].target = builder
        end
        publish(id, bribes[id])
    end
    function api.Destroyed(id)
        if bribes[id] then
            for officer, bid in pairs(GG.PoliceBribes) do
                if bid == id then clearOfficer(officer) end
            end
            bribes[id] = nil
        end
        GG.PoliceBribes[id], combatUntil[id], builders[id], witnessed[id] = nil, nil, nil, nil
    end
    function api.Command(id, defID, team, command, params)
        if defID ~= bribeDef then return true end
        local bribe = bribes[id]
        if not bribe then return command ~= CMD.GUARD and command ~= CMD.MOVE end
        if command == CMD.GUARD then
            local target = params[1]
            if position(target) and operatives[Spring.GetUnitDefID(target)] and
                Spring.AreTeamsAllied(team, Spring.GetUnitTeam(target)) then
                bribe.target = target
                bribe.goal = position(target)
            end
        elseif command == CMD.MOVE then
            if #params >= 3 then
                bribe.target = nil
                bribe.goal = {x = math.max(1, math.min(Game.mapSizeX-1, params[1])),
                    z = math.max(1, math.min(Game.mapSizeZ-1, params[3]))}
            end
        elseif command == CMD.STOP then
            bribe.target, bribe.goal = nil, position(id)
        else return true end
        for officer, bid in pairs(GG.PoliceBribes) do
            if bid == id then clearOfficer(officer) end
        end
        bribe.officers = {}
        publish(id, bribe)
        -- The gadget owns the icon's position, including following a cloaked operative.
        return false
    end
    function api.Damaged(id, attacker, damage)
        if damage <= 0 then return end
        local frame = Spring.GetGameFrame()
        for _, officer in ipairs({id, attacker or -1}) do
            if officers[officer] then
                combatUntil[officer] = frame+cfg.combatGraceFrames
                clearOfficer(officer)
            end
        end
    end
    function api.Witness(attacker)
        local frame = Spring.GetGameFrame()
        for id, state in pairs(officers) do
            if eligibleTypes[Spring.GetUnitDefID(id)] and canSee(id, attacker) then
                combatUntil[id] = frame+cfg.combatGraceFrames
                witnessed[id] = {attacker=attacker,expires=frame+(config.Police.searchFrames or 1350)}
                clearOfficer(id)
            end
        end
    end
    function api.AllowWeaponTarget(id, target)
        local bribe = bribes[GG.PoliceBribes[id]]
        if not bribe then return true end
        local state = officers[id]
        if threat(id, state, Spring.GetGameFrame()) then return true end
        -- A bribed officer does not acquire incidental targets while looking elsewhere.
        return false
    end
    function api.Update(frame)
        local bribeIDs, officerIDs = sorted(bribes), sorted(officers)
        for _, id in ipairs(bribeIDs) do
            local bribe = bribes[id]
            if frame >= bribe.ends or not position(id) or Spring.GetUnitTeam(id) ~= bribe.team then
                api.Destroyed(id)
                if position(id) then Spring.DestroyUnit(id, false, true) end
            else
                if bribe.target then
                    local target = position(bribe.target)
                    if target and Spring.AreTeamsAllied(bribe.team, Spring.GetUnitTeam(bribe.target)) then
                        bribe.goal = target
                    else bribe.target = nil end
                end
                local p, goal = position(id), bribe.goal
                -- 90 elmos/s; orders cannot teleport the influence across the map.
                local dx, dz = goal.x-p.x, goal.z-p.z
                local d = math.sqrt(dx*dx+dz*dz)
                local scale = d > 0 and math.min(1, 45/d) or 0
                local x,z = p.x+dx*scale,p.z+dz*scale
                Spring.MoveCtrl.SetPosition(id, x, math.max(0,Spring.GetGroundHeight(x,z))+config.iconHoverGroundOffset, z)
                bribe.officers = {}
            end
        end
        for _, id in ipairs(officerIDs) do
            local state = officers[id]
            local bid = GG.PoliceBribes[id]
            local bribe = bribes[bid]
            local allowed = eligibleTypes[Spring.GetUnitDefID(id)] and not threat(id, state, frame)
            if bribe and (not allowed or not matches(bribe, state.incident) or
                #bribe.officers >= cfg.maxOfficers or
                (bribe.target and not close(position(id), position(bribe.target)))) then
                clearOfficer(id)
                bid, bribe = nil, nil
            end
            if not bribe and allowed then
                for _, candidate in ipairs(bribeIDs) do
                    local b = bribes[candidate]
                    if b and #b.officers < cfg.maxOfficers and matches(b, state.incident) and
                        close(position(id), position(candidate)) then
                        bid, bribe = candidate, b
                        GG.PoliceBribes[id] = bid
                        state.nextOrder = 0
                        Spring.GiveOrderToUnit(id, CMD.STOP, {}, {})
                        break
                    end
                end
            end
            if bribe then
                bribe.officers[#bribe.officers+1] = id
                if frame >= (state.nextOrder or 0) then
                    if bribe.target then
                        -- Do not herd the police onto the operative being protected.
                        local p, target = position(id), position(bribe.target)
                        local dx,dz = p.x-target.x,p.z-target.z
                        local d = math.sqrt(dx*dx+dz*dz)
                        if d < 1 then dx,dz,d = 1,0,1 end
                        move(id, {x=math.max(1,math.min(Game.mapSizeX-1,target.x+dx/d*cfg.radius)),
                            z=math.max(1,math.min(Game.mapSizeZ-1,target.z+dz/d*cfg.radius))})
                    else move(id, bribe.goal) end
                    state.nextOrder = frame+90
                end
                state.expires = math.max(state.expires or 0, bribe.ends+30)
            end
        end
        for id, bribe in pairs(bribes) do publish(id, bribe) end
    end
    return api
end
return M
