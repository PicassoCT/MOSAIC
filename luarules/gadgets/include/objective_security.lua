-- Event-driven corporate response. Vehicles belong to Gaia, but may only
-- engage the reported attacker while visible. No city-wide unit scans.
local M = {}

local function sortedKeys(t)
    local keys = {}
    for id in pairs(t) do keys[#keys + 1] = id end
    table.sort(keys)
    return keys
end

function M.New(Spring, Game, UnitDefs, UnitDefNames, CMD, config, state)
    local api = {}
    local fps = Game.gameSpeed or 30
    local gaia = Spring.GetGaiaTeamID()
    local ally = Spring.GetTeamAllyTeamID(gaia)
    state.sites, state.units = state.sites or {}, state.units or {}

    local function alive(id)
        return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
    end

    local function visibleTarget(site)
        local id = site.attacker
        if not alive(id) or Spring.GetUnitTeam(id) ~= site.attackerTeam
            or Spring.GetUnitIsCloaked(id) then return end
        local los = Spring.GetUnitLosState(id, ally)
        if not los or not los.los then return end
        local x, _, z = Spring.GetUnitPosition(id)
        if x and (x-site.x)^2 + (z-site.z)^2 <= config.pursuitRadius^2 then return id end
    end

    function api.Plan(record, rate)
        local def = UnitDefs[record.defID]
        local cp = def.customParams or {}
        local military = config.military[def.name] or cp.objective_military == "1" or cp.objective_military == 1
        local truck, tank = UnitDefNames[config.truck].id, UnitDefNames[config.tank].id
        local function cost(id) return math.max(1, UnitDefs[id].metalCost or 1) end
        local budget = math.max(0, rate) * config.valueSeconds
        -- Mandatory truck, plus a mandatory tank at military sites, may exceed
        -- the economic budget. All further vehicles fit within that budget.
        local plan = military and {tank, truck} or {truck}
        budget = budget - cost(truck) - (military and cost(tank) or 0)
        while #plan < config.maxVehicles do
            local id = military and budget >= cost(tank) and tank or truck
            if budget < cost(id) then break end
            plan[#plan+1], budget = id, budget - cost(id)
        end
        return plan
    end

    local function countDef(site, defID)
        local n = 0
        for id in pairs(site.vehicles) do
            local u = state.units[id]
            if u and u.defID == defID and alive(id) and Spring.GetUnitTeam(id) == gaia then n = n+1 end
        end
        return n
    end

    function api.Damage(record, frame, damage, attacker, attackerTeam, rate)
        if type(damage) ~= "number" or damage ~= damage or damage <= 0 or damage == math.huge
            or not attackerTeam or attackerTeam == gaia then return end
        local site = state.sites[record.siteID]
        if not site then
            site = {vehicles={}, nextResponse=0, nextSpawn=frame}
            state.sites[record.siteID] = site
        end
        if site.uid ~= record.uid then
            -- Cache the exit boundary before destruction can remove the model.
            -- Tall decorative collision volumes must not push exits miles away.
            local sx, _, sz, ox, _, oz = Spring.GetUnitCollisionVolumeData(record.uid)
            local def = UnitDefs[record.defID]
            site.spawnRadius = math.max(4*math.sqrt((def.xsize or 8)^2 + (def.zsize or 8)^2),
                math.sqrt((sx or 0)^2 + (sz or 0)^2)/2 + math.sqrt((ox or 0)^2 + (oz or 0)^2)) + config.spawnClearance
        end
        site.uid, site.x, site.z = record.uid, record.x, record.z
        site.attacker, site.attackerTeam = attacker, attackerTeam
        site.expires = frame + config.standDownSeconds * fps
        if frame < site.nextResponse then return end
        site.nextResponse = frame + config.cooldownSeconds * fps
        site.pending = {}
        local desired = {}
        for _, defID in ipairs(api.Plan(record, rate(record, frame))) do
            desired[defID] = (desired[defID] or 0) + 1
            if desired[defID] > countDef(site, defID) then
                site.pending[#site.pending+1] = defID
            end
        end
    end

    local function spawnPosition(site, defID)
        local clearance = config.spawnClearance
        local r = site.spawnRadius
        local vehicle = UnitDefs[defID]
        local halfSize = math.max((vehicle.xsize or 4)*4, (vehicle.zsize or 4)*4, 48)
        for radius = r, r + config.spawnSearchRadius, clearance do
            for side = 0, 15 do
                local angle = side * math.pi / 8
                local x, z = site.x + math.cos(angle)*radius, site.z + math.sin(angle)*radius
                if x > halfSize and z > halfSize and x < Game.mapSizeX-halfSize and z < Game.mapSizeZ-halfSize then
                    local y = Spring.GetGroundHeight(x,z)
                    -- Offshore objectives use nearby passable shore. Never put
                    -- ordinary ground vehicles on the seabed or inside a unit.
                    if y >= 0 and Spring.TestMoveOrder(defID,x,y,z,0,0,0,true,true,false)
                        and #Spring.GetUnitsInRectangle(x-halfSize,z-halfSize,x+halfSize,z+halfSize) == 0 then
                        return x,y,z
                    end
                end
            end
        end
    end

    local function order(id, unit, site, frame)
        local target = visibleTarget(site)
        Spring.GiveOrderToUnit(id,CMD.FIRE_STATE,{0},{})
        if target then
            Spring.GiveOrderToUnit(id,CMD.ATTACK,{target},{})
        else
            -- Replace any old attack order immediately when LOS is lost.
            Spring.GiveOrderToUnit(id,CMD.MOVE,{unit.homeX,unit.homeY,unit.homeZ},{})
        end
        -- Truckscript forwards ATTACK but does not clear its mounted gun's
        -- target when the truck receives MOVE. Clear/order the gun explicitly.
        for _, passenger in ipairs(Spring.GetUnitIsTransporting(id) or {}) do
            if Spring.GetUnitTeam(passenger) == gaia then
                Spring.GiveOrderToUnit(passenger,CMD.FIRE_STATE,{0},{})
                Spring.GiveOrderToUnit(passenger,target and CMD.ATTACK or CMD.STOP,target and {target} or {},{})
            end
        end
        unit.nextOrder = frame + config.orderSeconds*fps
        unit.target = target
    end

    function api.Remove(id)
        local unit = state.units[id]
        if not unit then return end
        local site = state.sites[unit.siteID]
        if site then site.vehicles[id] = nil end
        state.units[id] = nil
    end

    function api.SiteDestroyed(record)
        local site = state.sites[record.siteID]
        -- Finish the already-triggered convoy from the ruins, including a
        -- lethal first hit. The destroyed marker cannot call new convoys.
        if site then site.uid = nil end
    end

    function api.AllowWeaponTarget(id, target)
        local unit = state.units[id]
        if not unit then
            local transport = Spring.GetUnitTransporter(id)
            unit = transport and state.units[transport]
        end
        if not unit then return true end
        local site = state.sites[unit.siteID]
        return site ~= nil and target == visibleTarget(site)
    end

    function api.Update(frame, objectives)
        for _, siteID in ipairs(sortedKeys(state.sites)) do
            local site = state.sites[siteID]
            local active = frame < site.expires
            if active and (not site.uid or (objectives[site.uid] and alive(site.uid)))
                and #site.pending > 0 and frame >= site.nextSpawn then
                local defID = site.pending[1]
                local total = #sortedKeys(site.vehicles)
                local x,y,z
                if total < config.maxVehicles then x,y,z = spawnPosition(site,defID) end
                site.nextSpawn = frame + config.spawnRetrySeconds*fps
                if x then
                    local id = Spring.CreateUnit(defID,x,y,z,0,gaia)
                    if id then
                        local unit = {siteID=siteID,defID=defID,homeX=x,homeY=y,homeZ=z,nextOrder=frame}
                        state.units[id], site.vehicles[id] = unit, true
                        table.remove(site.pending,1)
                        Spring.SetUnitNeutral(id,false)
                        Spring.SetUnitTooltip(id,"Corporate security — " .. (UnitDefs[defID].humanName or UnitDefs[defID].name))
                        Spring.SetUnitRulesParam(id,"objective_security_site",siteID,{inlos=true})
                        order(id,unit,site,frame)
                    end
                end
            end
            for _, id in ipairs(sortedKeys(site.vehicles)) do
                local unit = state.units[id]
                if not alive(id) or Spring.GetUnitTeam(id) ~= gaia then
                    api.Remove(id)
                elseif not active then
                    local passengers = Spring.GetUnitIsTransporting(id) or {}
                    api.Remove(id)
                    Spring.DestroyUnit(id,false,true)
                    -- Reclaiming a transport may release its weapon; do not
                    -- leave an orphaned corporate turret at every stand-down.
                    for _, passenger in ipairs(passengers) do
                        if alive(passenger) and Spring.GetUnitTeam(passenger) == gaia then
                            Spring.DestroyUnit(passenger,false,true)
                        end
                    end
                elseif unit and (frame >= unit.nextOrder or unit.target ~= visibleTarget(site)) then
                    order(id,unit,site,frame)
                end
            end
            if not active then state.sites[siteID] = nil end
        end
    end

    return api
end

return M
