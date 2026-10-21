-- Two bounded FlamePainter layers at the F35's single rear nozzle.
-- Flight eligibility is polled cheaply by the unit script; only transitions
-- change the synced registry. Idle holding circles still count as flight.
return function(unitID, body)
    local self = {}
    local dead, active = false, false
    local registeredAPI, cached, reportedError
    local slots = {'f35-afterburner', 'f35-smoke'}

    local function stop()
        if active and registeredAPI then
            for _, slot in ipairs(slots) do registeredAPI.Remove(unitID, slot) end
        end
        active, registeredAPI = false, nil
    end

    local function flying()
        if not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID)
            or Spring.GetUnitTransporter(unitID) then return false end
        if (Spring.GetUnitRulesParam(unitID, 'aircraft_crash_deadline') or 0) > 0 then
            return false
        end
        local move = Spring.GetUnitMoveTypeData(unitID)
        if not move or move.aircraftState ~= 'flying' then return false end
        local health, _, _, _, build = Spring.GetUnitHealth(unitID)
        if not health or not build or build < 1 then return false end
        local x, y, z = Spring.GetUnitPosition(unitID)
        if not x or y <= math.max(0, Spring.GetGroundHeight(x, z)) + 5 then
            return false
        end
        local vx, vy, vz = Spring.GetUnitVelocity(unitID)
        return vx ~= nil and vx*vx + vy*vy + vz*vz > 0.05*0.05
    end

    local function options()
        local info = Spring.GetUnitPieceInfo(unitID, body)
        if not (info and info.min and info.max) then return nil end
        local span = {}
        for axis=1,3 do
            if type(info.min[axis]) ~= 'number' or type(info.max[axis]) ~= 'number' then
                return nil
            end
            span[axis] = info.max[axis] - info.min[axis]
            if span[axis] <= 0 then return nil end
        end
        -- No separate exhaust piece exists. These ratios describe the actual
        -- nozzle ring in air_plane_F35.dae, not the tail fins' rear bound.
        local nozzleDiameter = span[1] * (123.78326 / 1621.465149)
        local root = {
            (info.min[1] + info.max[1]) * 0.5,
            info.min[2] + span[2] * 0.107971739382 - nozzleDiameter * 0.04,
            info.min[3] + span[3] * 0.330983813932,
        }
        -- Ribbon offsets use piece-local units; length and width use world
        -- units. Include the imported matrix scale exactly once when sizing.
        local matrix = Spring.GetUnitPieceMatrix and {Spring.GetUnitPieceMatrix(unitID, body)} or {}
        local diameter, bodyLength = 3.144094804, 65.01844375
        if matrix[16] then
            diameter = nozzleDiameter * math.sqrt(matrix[1]^2 + matrix[2]^2 + matrix[3]^2)
            bodyLength = span[2] * math.sqrt(matrix[5]^2 + matrix[6]^2 + matrix[7]^2)
        end
        if diameter <= 0 or bodyLength <= 0 then return nil end
        return {
            {
                rootOffset=root, directionSpace='piece', direction={0,-1,0},
                length=diameter*7, width=diameter*2, strands=2,
                curl=0.12, speed=3.0, windAffected=false, motionAffected=false,
                colorStart={0.62,0.8,1,0.95}, colorEnd={1,0.38,0.12,0},
                emission={3.6,1.0}, sourceGlow={0.16,0.24,0.5,0.3},
                distanceFactor=150,
            },
            {
                rootOffset=root, directionSpace='piece', direction={0,-1,0},
                length=bodyLength*2.5, width=diameter*3.8, strands=2,
                curl=0.45, speed=0.9,
                colorStart={0.56,0.61,0.65,0.3}, colorEnd={0.68,0.71,0.74,0},
                emission={0,0}, windAffected=true, windInfluence=0.12,
                motionAffected=true, motionInfluence=0.4, trailTime=0.25,
            },
        }
    end

    function self.Update()
        if dead then return false end
        local api = GG and GG.SmokeRibbon
        if not api or not flying() then stop(); return false end
        if active and registeredAPI == api then return true end
        if registeredAPI and registeredAPI ~= api then stop() end
        cached = cached or options()
        if not cached then return false end
        for i, preset in ipairs(cached) do
            local ok, err = api.Set(unitID, slots[i], body, preset)
            if not ok then
                for _, slot in ipairs(slots) do api.Remove(unitID, slot) end
                active, registeredAPI = false, nil
                if err ~= reportedError then
                    Spring.Echo('F35 exhaust: '..tostring(err))
                    reportedError = err
                end
                return false
            end
        end
        active, registeredAPI, reportedError = true, api, nil
        return true
    end

    function self.Shutdown()
        dead = true
        stop()
    end

    return self
end
