-- A fixed, server-strategy-sized map budget, apportioned by relative risk.
-- No scans of units, LOS or concealed bases. All times are simulation frames.
local M = {}
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

function M.New(Spring, Game, config, serverBaseIncome, teamsBySide, transfer, getRecords, clock)
    local api = {}
    local fps = Game.gameSpeed or 30
    local servers = math.max(1, config.referenceServerCount)
    local pool = servers * (serverBaseIncome + servers * config.serverNetworkBonus)
        * clamp(config.strategyIncomeFraction, 0, .95)
    local window = config.pressureSeconds
    clock = clock or {frame=Spring.GetGameFrame()}

    local function teams(protagon)
        local result = {}
        for id in pairs(teamsBySide[protagon and 'protagon' or 'antagon']) do
            local team, _, dead = Spring.GetTeamInfo(id)
            if team ~= nil and not dead then result[#result + 1] = id end
        end
        table.sort(result)
        return result
    end

    local function nearestStart(record, group)
        local nearest
        for _, id in ipairs(group) do
            local x, _, z = Spring.GetTeamStartPosition(id)
            if x and z and x >= 0 and z >= 0 and x <= Game.mapSizeX and z <= Game.mapSizeZ then
                local distance = math.sqrt((record.x - x)^2 + (record.z - z)^2)
                nearest = nearest and math.min(nearest, distance) or distance
            end
        end
        return nearest
    end

    function api.Exposure(record)
        local own = nearestStart(record, teams(record.boolProProtagon))
        local enemy = nearestStart(record, teams(not record.boolProProtagon))
        if own and enemy and own + enemy > 0 then return own / (own + enemy) end
        return clamp(1 - math.max(math.abs(2 * record.x / math.max(1, Game.mapSizeX) - 1),
            math.abs(2 * record.z / math.max(1, Game.mapSizeZ) - 1)), 0, 1)
    end

    local function baseWeight(record)
        return config.baseRiskWeight + config.exposureRiskWeight * api.Exposure(record)
    end

    function api.Register(record, frame)
        -- Advance existing sites before introducing another claim on the pool.
        api.Advance(frame)
        record.income = {pressure=0, accrued=0}
    end

    function api.Advance(frame)
        local seconds = math.max(0, frame - clock.frame) / fps
        if seconds <= 0 then return end
        local records = getRecords()
        local weights, pressures, stops = {}, {}, {0, seconds}
        for i, record in ipairs(records) do
            record.income = record.income or {pressure=0, accrued=0}
            weights[i], pressures[i] = baseWeight(record), clamp(record.income.pressure, 0, 1)
            local stop = pressures[i] * window
            if stop > 0 and stop < seconds then stops[#stops + 1] = stop end
        end
        table.sort(stops)
        for k = 1, #stops - 1 do
            local start, duration = stops[k], stops[k+1] - stops[k]
            if duration > 0 and #records > 0 then
                local numerator, slope, total, totalSlope = {}, {}, 0, 0
                for i in ipairs(records) do
                    numerator[i] = weights[i] + config.pressureRiskWeight * math.max(0, pressures[i] - start / window)
                    slope[i] = pressures[i] * window > start + 1e-9 and -config.pressureRiskWeight / window or 0
                    total, totalSlope = total + numerator[i], totalSlope + slope[i]
                end
                for i, record in ipairs(records) do
                    local shareSeconds
                    if math.abs(totalSlope) < 1e-12 then
                        shareSeconds = duration * numerator[i] / total
                    else
                        -- Exact integral of (a+b*t)/(c+d*t), until the next
                        -- pressure reaches zero. A late hit never back-pays.
                        local ratio = slope[i] / totalSlope
                        shareSeconds = ratio * duration + (numerator[i] - ratio * total) / totalSlope
                            * math.log((total + totalSlope * duration) / total)
                    end
                    -- Pending markers/restores retain the site's budget weight
                    -- but earn nothing while absent. No destruction windfall.
                    if record.uid then
                        record.income.accrued = record.income.accrued + pool * math.max(0, shareSeconds)
                    end
                end
            end
        end
        for i, record in ipairs(records) do
            record.income.pressure = math.max(0, pressures[i] - seconds / window)
        end
        clock.frame = math.max(clock.frame, frame)
    end

    function api.Damage(record, frame, damage, maxHealth, attackerTeam, paralyzer)
        if paralyzer or not attackerTeam or not damage or damage <= 0 or damage ~= damage
            or damage == math.huge or not maxHealth or maxHealth <= 0 then return end
        local hostile = false
        for _, id in ipairs(teams(not record.boolProProtagon)) do
            if id == attackerTeam then hostile = true; break end
        end
        if not hostile then return end
        for _, id in ipairs(teams(record.boolProProtagon)) do
            if id == attackerTeam or Spring.AreTeamsAllied(id, attackerTeam) then return end
        end
        api.Advance(frame)
        record.income.pressure = math.min(1, record.income.pressure + damage / (maxHealth * config.pressureDamageFraction))
    end

    function api.Pay(record, frame)
        api.Advance(frame)
        local recipients = teams(record.boolProProtagon)
        local amount = record.income and record.income.accrued or 0
        if record.income then record.income.accrued = 0 end
        if #recipients == 0 or amount <= 0 then return end
        for _, team in ipairs(recipients) do transfer(amount / #recipients, team, record.uid) end
    end

    function api.Rate(record, frame)
        api.Advance(frame)
        local total = 0
        for _, r in ipairs(getRecords()) do
            total = total + baseWeight(r) + config.pressureRiskWeight * (r.income and r.income.pressure or 0)
        end
        if total <= 0 or not record.uid then return 0 end
        return pool * (baseWeight(record) + config.pressureRiskWeight * (record.income and record.income.pressure or 0)) / total
    end

    return api
end

return M
