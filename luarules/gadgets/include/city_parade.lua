-- Synced parade director. Movement stays with ordinary engine MOVE orders;
-- civilian traffic retains its own suspended travel events and daily routines.
local M = {}
local floor, sqrt = math.floor, math.sqrt
local public = {public = true}

function M.Clock(frame, dayLength)
    local shifted = frame + dayLength / 2
    return floor(shifted / dayLength) + 1, (shifted % dayLength) * 24 / dayLength
end

function M.EndFrame(day, dayLength, endHour)
    return floor((day + endHour / 24 - 0.5) * dayLength)
end

function M.New(context)
    local S, G, C = context.Spring, context.GG, context.config
    local gameConfig, catalog = context.gameConfig, context.catalog
    local gaia = S.GetGaiaTeamID()
    G.CityParadeRetired = G.CityParadeRetired or {}
    local director = {vehicles = {}, participants = {}, retired = G.CityParadeRetired, phase = "idle"}
    local convoy, cooldown, lastBuildingBurst = {}, {}, {}
    local hiddenCommercialHolograms = {}
    local commercialHologramTypes = context.commercialHologramTypes or {}
    local previousStartHolograms = {}
    local previousCommercialStart, previousCommercialEnd, previousCommercialFrame
    local previousCommercialEndX, previousCommercialEndZ
    local route, pendingRoute, pendingDay, carrierDefID, eventDay, endFrame
    local routeOffsets, routeLength = {}, 0
    local clearance = context.clearance
    local tourStartFrame, previewRequest, preview = nil, nil, false
    local nextRetirementCheck = 0
    local nextSpawn, nextAttempt, lastEffect, lastRecruit = 0, 0, -C.effectFrames, -C.recruitFrames
    local lastDay = S.GetGameRulesParam("city_parade_last_day") or 0
    local effectsEmitted = 0
    local routeBuilder = context.routeBuilder

    local function sorted(t)
        local out = {}; for id in pairs(t) do out[#out + 1] = id end
        table.sort(out); return out
    end
    local function alive(id)
        return type(id) == "number" and S.ValidUnitID(id) and not S.GetUnitIsDead(id)
    end
    local function normal() return G.GlobalGameState == gameConfig.game.states.normal end
    local function log(message)
        if S.Echo then S.Echo("City parade: " .. message) end
    end
    local function waiting(reason)
        if director.waitingReason ~= reason and (previewRequest or preview) then log(reason) end
        director.waitingReason = reason
    end
    function director:GetStatus()
        return previewRequest and "preparing" or self.phase, self.waitingReason, self.lastStopReason
    end
    local function distance(x, z, a, b) return (x-a)^2 + (z-b)^2 end
    local function dangerous(x, z)
        return G.CityAreaState and G.CityAreaState:IsDangerous(x, z, C.combatHeatThreshold or 300) or false
    end
    local function call(id, name, ...)
        local env = alive(id) and S.UnitScript.GetScriptEnv(id)
        if env and type(env[name]) == "function" then return S.UnitScript.CallAsUnit(id, env[name], ...) end
    end
    local function count(t)
        local n = 0; for _ in pairs(t) do n = n + 1 end; return n
    end
    local function unitRule(id, key, value)
        if alive(id) then S.SetUnitRulesParam(id, key, value, public) end
    end
    local function setCommercialHologramHidden(id, hidden)
        unitRule(id, "city_parade_hide_commercial", hidden and 1 or 0)
        -- Native station ads mask their pieces; neon ads read the same rule in
        -- the shared draw/light gate without losing their current animation.
        call(id, "SetParadeCommercialHidden", hidden)
    end
    local function restoreCommercialHolograms()
        for _, id in ipairs(sorted(hiddenCommercialHolograms)) do
            setCommercialHologramHidden(id, false)
        end
        hiddenCommercialHolograms, previousStartHolograms = {}, {}
        previousCommercialStart, previousCommercialEnd, previousCommercialFrame = nil, nil, nil
        previousCommercialEndX, previousCommercialEndZ = nil, nil
    end
    local function commercialHologramsNear(x, z)
        local nearby = {}
        for _, id in ipairs(S.GetUnitsInCylinder(x, z, C.commercialHologramRadius) or {}) do
            if commercialHologramTypes[S.GetUnitDefID(id)] then nearby[id] = true end
        end
        return nearby
    end
    local function armCommercialHologram(id, expiresFrame)
        local timer = hiddenCommercialHolograms[id]
        if not timer then
            timer = {}
            hiddenCommercialHolograms[id] = timer
            setCommercialHologramHidden(id, true)
        end
        timer.expiresFrame = math.max(timer.expiresFrame or expiresFrame, expiresFrame)
        timer.tailSeen = false
        return timer
    end
    local function updateCommercialHolograms(frame)
        local startFloat, endFloat = convoy[1], convoy[#convoy]
        director.startFloat, director.endFloat = startFloat, endFloat
        if not startFloat then restoreCommercialHolograms(); return end
        local sx, _, sz = S.GetUnitPosition(startFloat)
        local ex, _, ez = S.GetUnitPosition(endFloat)
        if not sx or not ex then return end

        -- Sum the formation segments so bends do not collapse the estimate
        -- to the straight-line distance between the first and last float.
        local paradeLength, px, pz = 0, nil, nil
        for _, id in ipairs(convoy) do
            local x, _, z = S.GetUnitPosition(id)
            if x then
                if px then paradeLength = paradeLength + sqrt(distance(x, z, px, pz)) end
                px, pz = x, z
            end
        end
        local def = context.UnitDefs[S.GetUnitDefID(endFloat)]
        local speed = math.max(1, (def and def.speed or 0) * C.speedFactor)
        local framesPerUnit = (context.Game.gameSpeed or 30) / speed
        -- Include both sides of the detection radius: lead entry to tail exit.
        local passageFrames = math.ceil((paradeLength + 2*C.commercialHologramRadius) * framesPerUnit)
        local endpointsChanged = startFloat ~= previousCommercialStart or endFloat ~= previousCommercialEnd
        local delay = 0
        if not endpointsChanged and previousCommercialFrame then
            local travelled = sqrt(distance(ex, ez, previousCommercialEndX, previousCommercialEndZ))
            -- Shift deadlines by lost travel time. A stopped tail pauses every
            -- timer; slow or faster movement adjusts the predicted expiry.
            delay = frame - previousCommercialFrame - travelled * framesPerUnit
        end
        for _, timer in pairs(hiddenCommercialHolograms) do
            if endpointsChanged then
                timer.expiresFrame = math.max(timer.expiresFrame, frame + passageFrames)
                timer.tailSeen = false
            else
                timer.expiresFrame = timer.expiresFrame + delay
            end
        end

        -- Only the designated first and last float search for advertisements.
        local startNearby = commercialHologramsNear(sx, sz)
        local endNearby = startFloat == endFloat and startNearby or commercialHologramsNear(ex, ez)
        for _, id in ipairs(sorted(startNearby)) do
            if not hiddenCommercialHolograms[id] or not previousStartHolograms[id] then
                armCommercialHologram(id, frame + passageFrames)
            end
        end
        for _, id in ipairs(sorted(endNearby)) do
            local timer = hiddenCommercialHolograms[id]
                or armCommercialHologram(id, frame + math.ceil(2*C.commercialHologramRadius*framesPerUnit))
            timer.tailSeen = true
        end
        for _, id in ipairs(sorted(hiddenCommercialHolograms)) do
            local timer = hiddenCommercialHolograms[id]
            if not startNearby[id] and not endNearby[id] then
                -- An observed tail exit is more precise than the prediction.
                if timer.tailSeen then timer.expiresFrame = frame end
                if frame >= timer.expiresFrame then
                    setCommercialHologramHidden(id, false)
                    hiddenCommercialHolograms[id] = nil
                end
            end
        end
        previousStartHolograms = startNearby
        previousCommercialStart, previousCommercialEnd, previousCommercialFrame = startFloat, endFloat, frame
        previousCommercialEndX, previousCommercialEndZ = ex, ez
    end
    local function publish()
        director.startFloat, director.endFloat = convoy[1], convoy[#convoy]
        S.SetGameRulesParam("city_parade_active", director.phase == "touring" and 1 or 0, public)
        S.SetGameRulesParam("city_parade_phase", director.phase, public)
        S.SetGameRulesParam("city_parade_day", eventDay or 0, public)
        S.SetGameRulesParam("city_parade_vehicle_count", #convoy, public)
        S.SetGameRulesParam("city_parade_start_float", director.startFloat or -1, public)
        S.SetGameRulesParam("city_parade_end_float", director.endFloat or -1, public)
        S.SetGameRulesParam("city_parade_participants", count(director.participants), public)
    end
    local function busy(id)
        local state = (G.CivilianUnitInternalLogicActive or {})[id]
        state = type(state) == "table" and state.state or state
        return state == gameConfig.civilians.activityStates.started
    end
    local function ownsPose(id)
        local state = (G.CivilianUnitInternalLogicActive or {})[id]
        return type(state) == "table" and state.behaviour == "parade"
            and state.state == gameConfig.civilians.activityStates.started
    end
    local function move(id, p)
        S.GiveOrderToUnit(id, CMD.MOVE, {p.x, p.y or S.GetGroundHeight(p.x, p.z), p.z}, {})
    end
    local function stop(id)
        S.GiveOrderToUnit(id, CMD.STOP, {}, {})
    end
    local function consumeDay(day)
        lastDay = day
        S.SetGameRulesParam("city_parade_last_day", day, public)
    end
    local function releasePerson(id, frame)
        director.participants[id] = nil
        cooldown[id] = frame + C.participantCooldownFrames
        if alive(id) then
            -- This call releases only the pose's exact state record. A newer
            -- panic/aerosol state and its commands remain untouched.
            call(id, "stopParadeParticipation")
            unitRule(id, "city_parade_role", 0)
        end
    end
    local function retireVehicle(id)
        local vehicle = director.vehicles[id]
        director.vehicles[id] = nil
        if alive(id) then
            context.setSpeed(id, 1)
            unitRule(id, "city_parade_vehicle", 0)
            if S.GetUnitTeam(id) == gaia then
                director.retired[id] = {payload = vehicle and vehicle.payload}
                unitRule(id, "city_parade_retiring", 1)
                -- Every spawned truck has its ordinary traffic event already.
                -- That event resumes when OwnsUnit becomes false; no new order
                -- here can overwrite an ongoing fleeing response.
            else
                director.retired[id] = nil
                unitRule(id, "city_parade_retiring", 0)
                if G.CivilianTable then G.CivilianTable[id] = nil end
                if G.UnitArrivedAtTarget then G.UnitArrivedAtTarget[id] = nil end
            end
        end
    end

    function director:OwnsUnit(id)
        return self.vehicles[id] ~= nil or self.participants[id] ~= nil
    end

    function director:Stop(reason, frame)
        frame = frame or S.GetGameFrame()
        if self.phase ~= "idle" or previewRequest then
            log("stopped: " .. tostring(reason) ..
                (self.waitingReason and ("; last wait: " .. self.waitingReason) or "") ..
                (self.lastRouteError and ("; last route rejection: " .. self.lastRouteError) or ""))
        end
        self.lastStopReason, self.waitingReason = reason, nil
        restoreCommercialHolograms()
        for _, id in ipairs(sorted(self.participants)) do releasePerson(id, frame) end
        for _, id in ipairs(convoy) do retireVehicle(id) end
        convoy = {}
        self.phase = "idle"
        route, pendingRoute, pendingDay = nil, nil, nil
        previewRequest, preview, tourStartFrame = nil, false, nil
        S.SetGameRulesParam("city_parade_last_stop", reason, public)
        publish()
    end

    -- Traffic calls this before assigning a new trip. Floats return to a city
    -- destination and leave peacefully instead of popping away at 03:00.
    function director:OnArrived(id)
        local retired = self.retired[id]
        if not retired then return false end
        if not alive(id) then self.retired[id] = nil; return false end
        if S.GetUnitTeam(id) ~= gaia then
            self.retired[id] = nil
            unitRule(id, "city_parade_retiring", 0)
            if G.CivilianTable then G.CivilianTable[id] = nil end
            if G.UnitArrivedAtTarget then G.UnitArrivedAtTarget[id] = nil end
            return false
        end
        if not normal() or busy(id) then return false end
        self.retired[id] = nil
        unitRule(id, "city_parade_retiring", 0)
        G.DiedPeacefully = G.DiedPeacefully or {}
        if alive(retired.payload) and S.GetUnitTransporter(retired.payload) == id then
            G.DiedPeacefully[retired.payload] = true
            S.DestroyUnit(retired.payload, false, true)
        end
        G.DiedPeacefully[id] = true
        S.DestroyUnit(id, false, true)
        return true
    end

    -- Rules parameters survive a synced gadget reload even when its local
    -- convoy table does not. Release poses and return tagged floats to traffic.
    function director:Recover()
        local units = S.GetAllUnits() or {}
        table.sort(units)
        local payloads = {}
        local payloadDef = context.UnitDefNames[catalog.unitName]
        for _, id in ipairs(units) do
            if payloadDef and S.GetUnitDefID(id) == payloadDef.id then
                local parent = S.GetUnitTransporter(id)
                if parent then payloads[parent] = id end
            end
        end
        for _, id in ipairs(units) do
            if (S.GetUnitRulesParam(id, "city_parade_hide_commercial") or 0) > 0 then
                setCommercialHologramHidden(id, false)
            end
            if (S.GetUnitRulesParam(id, "city_parade_role") or 0) > 0 then
                call(id, "stopParadeParticipation")
                unitRule(id, "city_parade_role", 0)
            end
            if self.retired[id] or (S.GetUnitRulesParam(id, "city_parade_vehicle") or 0) > 0
                or (S.GetUnitRulesParam(id, "city_parade_retiring") or 0) > 0 then
                context.setSpeed(id, 1)
                unitRule(id, "city_parade_vehicle", 0)
                if S.GetUnitTeam(id) == gaia then
                    local previous = self.retired[id]
                    self.retired[id] = {payload = payloads[id] or (previous and previous.payload)}
                    unitRule(id, "city_parade_retiring", 1)
                else
                    self.retired[id] = nil
                    unitRule(id, "city_parade_retiring", 0)
                    if G.CivilianTable then G.CivilianTable[id] = nil end
                    if G.UnitArrivedAtTarget then G.UnitArrivedAtTarget[id] = nil end
                end
            end
        end
        for id in pairs(self.retired) do
            if not alive(id) then self.retired[id] = nil end
        end
        publish()
    end

    local function resumeRecoveredTraffic(frame)
        if frame < nextRetirementCheck then return end
        nextRetirementCheck = frame + C.retryFrames
        local traffic = G.CivilianTraffic
        for _, id in ipairs(sorted(director.retired)) do
            if not alive(id) then
                director.retired[id] = nil
            elseif S.GetUnitTeam(id) ~= gaia then
                director.retired[id] = nil
                unitRule(id, "city_parade_retiring", 0)
                if G.CivilianTable then G.CivilianTable[id] = nil end
                if G.UnitArrivedAtTarget then G.UnitArrivedAtTarget[id] = nil end
            elseif traffic and G.CivilianTable and not G.CivilianTable[id]
                and normal() and not busy(id) then
                -- If traffic itself reloaded, its population table and events
                -- were rebuilt. Re-register only the surviving tagged floats.
                local x, _, z = S.GetUnitPosition(id)
                local best, goal, nearest
                for _, node in ipairs(sorted(traffic.GetRoutes() or {})) do
                    local edges = traffic.GetRoutes()[node]
                    if alive(node) and type(edges) == "table" then
                        local nx, _, nz = S.GetUnitPosition(node)
                        if x and nx and not dangerous(nx, nz) then
                            for _, target in ipairs(edges) do
                                if alive(target) and target ~= node then
                                    local d = distance(x, z, nx, nz)
                                    if not nearest or d < nearest then
                                        best, goal, nearest = node, target, d
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                if best then
                    G.CivilianTable[id] = {defID=S.GetUnitDefID(id), startID=best, goalID=goal}
                    if not traffic.BeginTravel(id) then G.CivilianTable[id] = nil end
                end
            end
        end
    end

    function director:RequestPreview(frame)
        frame = frame or S.GetGameFrame()
        if self.phase ~= "idle" or previewRequest then return false, "a parade is already active or preparing" end
        if not normal() then return false, "the city is not in normal times" end
        if not G.CitySpawnComplete or not G.CivilianTraffic then return false, "city traffic is not ready" end
        local day = M.Clock(frame, gameConfig.game.dayLengthFrames)
        previewRequest = {day=day, expires=frame+(C.previewRouteTimeoutFrames or 60*30)}
        self.lastStopReason = nil
        self.lastRouteError = nil
        waiting("searching for a safe route")
        pendingRoute, pendingDay, nextAttempt = nil, nil, frame
        return true, "validating a route; preview assembles for 45 seconds and tours for 3 minutes"
    end

    local function carrierFor(day)
        local candidates = {}
        for _, name in ipairs(catalog.carrierNames) do
            local def = context.UnitDefNames[name]
            if def and context.UnitDefs[def.id] and context.UnitDefs[def.id].moveDef then
                candidates[#candidates + 1] = def.id
            end
        end
        if #candidates == 0 or not context.UnitDefNames[catalog.unitName] or #catalog.variants == 0 then return end
        return candidates[((floor(day / C.periodDays) - 1) % #candidates) + 1]
    end

    local function validPoint(defID, x, z)
        if x <= 16 or z <= 16 or x >= context.Game.mapSizeX-16 or z >= context.Game.mapSizeZ-16 then return end
        local y = S.GetGroundHeight(x, z)
        if y < 0 or dangerous(x, z) or not S.TestMoveOrder(defID, x, y, z) then return end
        return {x = x, y = y, z = z}
    end

    local function spawnVehicle(frame)
        local origin = route.points[1]
        if (clearance and not clearance:SegmentClear(origin,origin))
            or not validPoint(carrierDefID, origin.x, origin.z) then
            waiting("assembly point is blocked or unsafe"); return
        end
        -- Spawn one at a time from the same existing curb. Never overlap the
        -- preceding float or create a parked row across a building footprint.
        for _, id in ipairs(S.GetUnitsInCylinder(origin.x, origin.z, C.vehicleSpacing) or {}) do
            if context.truckTypes[S.GetUnitDefID(id)] then
                waiting("waiting for truck " .. id .. " to clear the assembly point"); return
            end
        end
        local id = G.CivilianTraffic.SpawnParade(carrierDefID, origin.x, origin.z, route.nodes[1], route.nodes[2])
        if not id then waiting("carrier creation failed (check Gaia unit limit and carrier eligibility)"); return end
        local vehicle = {goal = 2, lap = 0, progress = 0, speed = C.speedFactor, lastProgress = frame, x = origin.x, z = origin.z}
        director.vehicles[id] = vehicle
        local payload = G.CivilianTraffic.Load(id, catalog.unitName)
        local variant = ((floor(eventDay / C.periodDays) - 1 + #convoy) % #catalog.variants) + 1
        local failure
        if not payload then failure = "payload creation failed"
        elseif not call(payload, "SetParadeVariant", variant) then failure = "payload rejected float variant"
        elseif not G.CivilianTraffic.BeginTravel(id) then failure = "civilian travel registration failed" end
        if failure then
            waiting(failure)
            director.vehicles[id] = nil
            if alive(payload) then S.DestroyUnit(payload, false, true) end
            G.DiedPeacefully = G.DiedPeacefully or {}; G.DiedPeacefully[id] = true
            S.DestroyUnit(id, false, true)
            return
        end
        vehicle.payload = payload
        convoy[#convoy + 1] = id
        unitRule(id, "city_parade_vehicle", 1)
        unitRule(id, "city_parade_retiring", 0)
        unitRule(id, "city_parade_variant", variant)
        context.setSpeed(id, C.speedFactor)
        -- Create a normal travel event now, suspended by OwnsUnit until the
        -- parade disperses. This also preserves emergency traffic behaviour.
        if G.UnitArrivedAtTarget then G.UnitArrivedAtTarget[id] = nil end
        move(id, route.points[2])
        nextSpawn = frame + C.spawnIntervalFrames
        director.waitingReason = nil
        log(string.format("spawned truck=%d payload=%d variant=%d at x=%.1f y=%.1f z=%.1f (frame %d)",
            id, payload, variant, origin.x, origin.y, origin.z, frame))
        publish()
    end

    local function startAssembly(day, frame, isPreview)
        route = pendingRoute
        routeOffsets,routeLength = {0},0
        for i=2,#route.points do
            routeLength=routeLength+sqrt(distance(route.points[i-1].x,route.points[i-1].z,route.points[i].x,route.points[i].z))
            routeOffsets[i]=routeLength
        end
        pendingRoute, pendingDay = nil, nil
        preview, previewRequest = isPreview == true, nil
        eventDay = day
        tourStartFrame = preview and frame+(C.previewAssemblyFrames or 45*30)
            or floor((day-1+C.tourHour/24-0.5)*gameConfig.game.dayLengthFrames)
        endFrame = preview and tourStartFrame+(C.previewTourFrames or 3*60*30)
            or M.EndFrame(day, gameConfig.game.dayLengthFrames, C.endHour)
        director.phase = "assembling"
        convoy, director.vehicles, lastBuildingBurst = {}, {}, {}
        effectsEmitted = 0
        director.waitingReason = nil
        director.lastRouteError = nil
        local origin = route.points[1]
        log(string.format("assembly starts at x=%.1f y=%.1f z=%.1f; carrier=%s; route nodes=%d; frame=%d",
            origin.x, origin.y, origin.z, context.UnitDefs[carrierDefID].name, #route.nodes, frame))
        if not preview then consumeDay(day) end
        nextSpawn = frame
        publish()
    end

    local function updateConvoy(frame)
        local membershipChanged = false
        for i = #convoy, 1, -1 do
            local id = convoy[i]
            local vehicle = director.vehicles[id]
            if not alive(id) or S.GetUnitTeam(id) ~= gaia or not alive(vehicle.payload)
                or S.GetUnitTransporter(vehicle.payload) ~= id then
                retireVehicle(id)
                table.remove(convoy, i)
                membershipChanged = true
            end
        end
        if membershipChanged then publish() end
        if clearance then clearance:Refresh(frame) end
        local positions = {}
        -- Snapshot and project every truck before issuing orders. Distances
        -- along the circuit remain meaningful across bends and the lap seam.
        for _,id in ipairs(convoy) do
            local vehicle=director.vehicles[id]
            local x,_,z=S.GetUnitPosition(id)
            if not x or dangerous(x,z) or busy(id) then return false,"danger" end
            local pos={x=x,z=z};positions[id]=pos
            local goal=route.points[vehicle.goal]
            if dangerous(goal.x,goal.z) then return false,"route unsafe" end
            vehicle.advanced=false
            if distance(x,z,goal.x,goal.z)<=C.goalRadius^2 then
                local nextGoal=vehicle.goal % #route.points+1
                if nextGoal==1 then nextGoal=2 end
                -- Do not cut a building corner merely because its waypoint
                -- falls within the engine's arrival radius.
                if not clearance or clearance:SegmentClear(pos,route.points[nextGoal]) then
                    if nextGoal==2 then vehicle.lap=vehicle.lap+1 end
                    vehicle.goal,vehicle.advanced=nextGoal,true
                    goal=route.points[nextGoal]
                end
            end
            local previous=route.points[vehicle.goal-1]
            local dx,dz=goal.x-previous.x,goal.z-previous.z
            local length=sqrt(dx*dx+dz*dz)
            local along=length>0 and math.max(0,math.min(length,((x-previous.x)*dx+(z-previous.z)*dz)/length)) or 0
            vehicle.progress=vehicle.lap*routeLength+routeOffsets[vehicle.goal-1]+along
            if distance(x,z,vehicle.x,vehicle.z)>16 then
                vehicle.x,vehicle.z,vehicle.lastProgress=x,z,frame
            end
        end
        for i,id in ipairs(convoy) do
            local vehicle,pos=director.vehicles[id],positions[id]
            local goal=route.points[vehicle.goal]
            local hold,obstructed=false,false
            local speed=C.speedFactor
            local minimum=C.minimumVehicleSpacing or C.vehicleSpacing
            local hysteresis=C.spacingHysteresis or 20
            if i>1 then
                local ahead=director.vehicles[convoy[i-1]]
                local gap=ahead.progress-vehicle.progress
                hold=gap<minimum+(vehicle.held and hysteresis or 0)
                -- Gradually slow before entering the stopping gap; do not
                -- race back up to the bumper after every STOP/GO transition.
                speed=C.speedFactor*math.max(.15,math.min(1,(gap-minimum)/math.max(1,C.vehicleSpacing-minimum)))
            elseif convoy[2] then
                local behind=director.vehicles[convoy[2]]
                hold=vehicle.progress-behind.progress>C.maxVehicleGap
                local tail=director.vehicles[convoy[#convoy]]
                hold=hold or tail.progress+routeLength-vehicle.progress<minimum+hysteresis
            end
            -- Arc spacing cannot alone protect an intersection or a loop
            -- folded close to itself. Earlier trucks retain right of way.
            for j=1,i-1 do
                local other=positions[convoy[j]]
                if distance(pos.x,pos.z,other.x,other.z)<minimum^2 then hold=true end
            end
            if clearance then
                obstructed=not clearance:SegmentClear(pos,goal)
                if not obstructed and S.GetUnitVelocity then
                    local vx,_,vz=S.GetUnitVelocity(id)
                    if vx and vz then
                        local lookahead=C.tickFrames*2
                        obstructed=not clearance:SegmentClear(pos,{x=pos.x+vx*lookahead,z=pos.z+vz*lookahead})
                    end
                end
                if obstructed then
                    hold=true
                    waiting("truck "..id.." waiting before a house footprint")
                end
            end
            if hold then
                if not vehicle.held then stop(id);vehicle.held=true end
                if not obstructed then vehicle.lastProgress=frame end
            else
                if vehicle.speed~=speed then context.setSpeed(id,speed);vehicle.speed=speed end
                if vehicle.held or vehicle.advanced then vehicle.held=false;move(id,goal) end
            end
            if frame-vehicle.lastProgress>C.stalledFrames then return false,"route blocked" end
        end
        return true
    end

    local function direction(id)
        local vehicle = director.vehicles[id]
        local x, _, z = S.GetUnitPosition(id)
        if not vehicle or not x then return end
        local goal = route.points[vehicle.goal]
        local dx, dz = goal.x-x, goal.z-z
        local length = sqrt(dx*dx+dz*dz)
        if length < 1 then dx, dz, length = 1, 0, 1 end
        return x, z, dx/length, dz/length
    end

    local function audiencePoint(id, truck, following, slot)
        local tx, tz, dx, dz = direction(truck)
        local x, _, z = S.GetUnitPosition(id)
        if not tx or not x then return end
        local lateral = (x-tx)*(-dz) + (z-tz)*dx
        local side = lateral >= 0 and 1 or -1
        local behind = following and (90 + (slot % 4)*32) or -math.max(-100, math.min(100, (x-tx)*dx+(z-tz)*dz))
        for _, width in ipairs({C.curbOffset, C.curbOffset+45, C.curbOffset+90}) do
            local p = validPoint(S.GetUnitDefID(id), tx-dx*behind-dz*width*side, tz-dz*behind+dx*width*side)
            if p then return p end
        end
    end

    local function ambient(id)
        if not alive(id) or S.GetUnitTeam(id) ~= gaia or not context.walkerTypes[S.GetUnitDefID(id)] then return false end
        if not (G.CivilianTable or {})[id] or (G.DisguiseCivilianFor or {})[id]
            or (G.AerosolAffectedCivilians or {})[id] or S.GetUnitTransporter(id) then return false end
        local hp, maximum = S.GetUnitHealth(id)
        return hp and maximum and hp >= maximum * 0.8
    end

    local function updateAudience(frame)
        for _, id in ipairs(sorted(director.participants)) do
            local participant = director.participants[id]
            local x, z
            if alive(id) then local px, _, pz = S.GetUnitPosition(id); x,z = px,pz end
            local target = participant.following and convoy[#convoy] or participant.truck
            local tx, _, tz
            if target and director.vehicles[target] and alive(target) then tx, _, tz = S.GetUnitPosition(target) end
            if not ambient(id) or not ownsPose(id) or frame >= participant.untilFrame or not tx or not x
                or dangerous(x, z) or distance(x, z, tx, tz) > C.audienceReleaseRadius^2 then
                releasePerson(id, frame)
            elseif participant.following and frame >= participant.nextMove then
                participant.nextMove = frame + C.followerUpdateFrames
                local p = audiencePoint(id, target, true, participant.slot)
                if p and distance(x, z, p.x, p.z) > 45^2 then move(id, p) end
            elseif not participant.following and not participant.stopped
                and distance(x, z, participant.point.x, participant.point.z) < 28^2 then
                stop(id); participant.stopped = true
            end
        end
        if frame-lastRecruit < C.recruitFrames or not G.CivilianLife then return end
        lastRecruit = frame
        local remaining = C.maxParticipants-count(director.participants)
        if remaining <= 0 then return end
        for _, truck in ipairs(convoy) do
            local x, _, z = S.GetUnitPosition(truck)
            local near = S.GetUnitsInCylinder(x, z, C.audienceRadius, gaia) or {}
            table.sort(near)
            for _, id in ipairs(near) do
                if not director.participants[id] and frame >= (cooldown[id] or 0) and ambient(id)
                    and G.CivilianLife:CanSocialize(id) and not G.CivilianLife:IsProtected(id) then
                    local px, _, pz = S.GetUnitPosition(id)
                    local following = (id*17+eventDay*13)%100 < C.followerPercent
                    local target = following and convoy[#convoy] or truck
                    local point = not dangerous(px, pz) and audiencePoint(id, target, following, id)
                    if point and call(id, "startParadeParticipation", (id+eventDay)%8+1) then
                        director.participants[id] = {truck=truck, following=following, slot=id, point=point,
                            untilFrame=frame+(following and C.followerFrames or C.spectatorFrames),
                            nextMove=frame+C.followerUpdateFrames}
                        unitRule(id, "city_parade_role", following and 2 or 1)
                        move(id, point)
                        remaining = remaining-1
                        if remaining <= 0 then publish(); return end
                    end
                end
            end
        end
        publish()
    end

    local function showerBuildings(frame)
        if frame-lastEffect < C.effectFrames then return end
        lastEffect = frame
        local candidates = {}
        for _, truck in ipairs(convoy) do
            local tx, _, tz = S.GetUnitPosition(truck)
            for _, id in ipairs(S.GetUnitsInCylinder(tx, tz, C.buildingRadius, gaia) or {}) do
                if context.buildingTypes[S.GetUnitDefID(id)] and (G.BuildingTable or {})[id]
                    and not (G.CityConstructionSites or {})[id] and frame >= (lastBuildingBurst[id] or 0) then
                    local x, _, z = S.GetUnitPosition(id)
                    local hp, maximum = S.GetUnitHealth(id)
                    if x and hp and maximum and hp > maximum*0.5 and not dangerous(x, z) then
                        local d = distance(x,z,tx,tz)
                        if not candidates[id] or d < candidates[id].distance then
                            candidates[id] = {truck=truck, distance=d}
                        end
                    end
                end
            end
        end
        local ids = sorted(candidates)
        table.sort(ids, function(a,b)
            local aa, bb = lastBuildingBurst[a] or 0, lastBuildingBurst[b] or 0
            return aa < bb or (aa == bb and a < b)
        end)
        for i=1,math.min(C.maxBuildingBursts,#ids) do
            local id = ids[i]
            local x,y,z = S.GetUnitPosition(id)
            local tx,_,tz = S.GetUnitPosition(candidates[id].truck)
            local dx,dz = tx-x,tz-z
            local length = math.max(1,sqrt(dx*dx+dz*dz))
            dx,dz = dx/length,dz/length
            local edge = math.min((S.GetUnitRadius(id) or 80)*0.55,length*0.6)
            local height = math.max(24,(S.GetUnitHeight(id) or 100)*0.85)
            local effect = C.effects[effectsEmitted % #C.effects + 1]
            effectsEmitted = effectsEmitted+1
            local ex,ey,ez = dx,-0.25,dz
            if effect == "parade_petals" then
                height = math.max(C.petalMinimumHeight or 240,
                    (S.GetUnitHeight(id) or 100) * (C.petalHeightFactor or 1.6))
                local windX,_,windZ = S.GetWind()
                -- Petals consume CEG's dir as gravity, not their launch axis.
                -- Scale current map wind into per-frame acceleration; retain
                -- downward gravity even in calm weather. Each burst samples
                -- the wind once because CEG particles have no live wind hook.
                ex,ey,ez = windX*0.0015,-0.05,windZ*0.0015
            elseif effect == "parade_inflationmoney" then
                ex,ey,ez = 0,-1,0
            end
            S.SpawnCEG(effect,x+dx*edge,y+height,z+dz*edge,ex,ey,ez)
            lastBuildingBurst[id] = frame+C.buildingCooldownFrames
        end
    end

    function director:Frame(frame)
        if frame % C.tickFrames ~= 0 then return end
        resumeRecoveredTraffic(frame)
        local day,hour = M.Clock(frame,gameConfig.game.dayLengthFrames)
        if self.phase ~= "idle" then
            if not normal() then self:Stop("city emergency",frame); return end
            if frame >= endFrame then self:Stop("late night",frame); return end
            local moving,reason = updateConvoy(frame)
            if not moving then self:Stop(reason,frame); return end
            if self.phase == "assembling" then
                if frame >= tourStartFrame then
                    if #convoy < C.minimumVehicles then self:Stop("assembly incomplete",frame); return end
                    self.phase = "touring"; publish()
                elseif #convoy < C.vehicleCount and frame >= nextSpawn then
                    spawnVehicle(frame)
                end
            end
            if self.phase == "touring" then
                if #convoy < C.minimumVehicles then self:Stop("floats unavailable",frame); return end
                updateAudience(frame)
                showerBuildings(frame)
            end
            updateCommercialHolograms(frame)
            return
        end
        local requestedPreview = previewRequest ~= nil
        if requestedPreview then
            if not normal() then self:Stop("city emergency",frame); return end
            if frame >= previewRequest.expires then self:Stop("preview route unavailable",frame); return end
            day = previewRequest.day
        elseif day % C.periodDays ~= 0 or day <= lastDay or hour < C.assemblyHour or hour >= C.tourHour then
            pendingRoute,pendingDay = nil,nil
            return
        end
        if not normal() then consumeDay(day); pendingRoute,pendingDay=nil,nil; return end
        if not G.CitySpawnComplete or not G.CivilianTraffic then return end
        if pendingRoute and pendingDay == day then
            local status = routeBuilder:Poll(pendingRoute)
            if status == "ready" then
                startAssembly(day,frame,requestedPreview)
                spawnVehicle(frame)
                updateCommercialHolograms(frame)
            elseif status == "invalid" then
                self.lastRouteError = pendingRoute.reason
                waiting("route rejected: " .. tostring(pendingRoute.reason or "unknown reason"))
                pendingRoute,pendingDay=nil,nil; nextAttempt=frame+C.retryFrames
            end
            return
        end
        if frame < nextAttempt then return end
        nextAttempt = frame+C.retryFrames
        carrierDefID = carrierFor(day)
        if not carrierDefID then waiting("no eligible carrier or parade payload definition"); return end
        pendingRoute = routeBuilder:Begin(day,carrierDefID)
        pendingDay = pendingRoute and day or nil
        if not pendingRoute then waiting("route search: " .. tostring(routeBuilder.lastError or "no route"))
        else waiting("validating native route paths") end
    end

    function director:UnitDamaged(id, damage)
        if not damage or damage <= 0 then return end
        if self:OwnsUnit(id) then self:Stop("parade attacked"); return end
        for _, vehicle in pairs(self.vehicles) do
            if vehicle.payload == id then self:Stop("float attacked"); return end
        end
    end

    function director:UnitDestroyed(id)
        if self.participants[id] then releasePerson(id,S.GetGameFrame()) end
        hiddenCommercialHolograms[id] = nil
        previousStartHolograms[id] = nil
        cooldown[id],lastBuildingBurst[id],self.retired[id] = nil,nil,nil
        if self.vehicles[id] then self:Stop("vehicle lost") end
    end

    function director:Shutdown()
        self:Stop("shutdown")
    end

    publish()
    return director
end

return M
