-- Debt collection is independent of propaganda awards: insolvency must never
-- reduce or repeat an opponent's payout. Called outside damage/death callbacks.
return function(Spring, UnitDefNames, cfg, onMoneyCollected, onHealthCollected)
    local self = {}
    local gaia = Spring.GetGaiaTeamID()
    local debt, sources, buildings, owner = {}, {}, {}, {}
    local military = {}
    local epsilon = 0.000001
    local visibility = {allied = true}
    assert(cfg.hpPerMoney > 0)
    for _, name in ipairs(cfg.militaryBuildings) do
        local def = UnitDefNames[name]
        if def then military[def.id] = true end
    end

    local function keys(t)
        local result = {}
        for id in pairs(t) do result[#result + 1] = id end
        table.sort(result)
        return result
    end

    local function save(team, amount)
        amount = math.max(0, amount)
        if amount < epsilon then amount = 0 end
        debt[team] = amount > 0 and amount or nil
        Spring.SetTeamRulesParam(team, "collateral_debt", amount, visibility)
        if amount == 0 then sources[team] = nil end
    end

    function self:RemoveUnit(id)
        local team = owner[id]
        if team and buildings[team] then buildings[team][id] = nil end
        owner[id] = nil
    end

    function self:RegisterUnit(id, defID, team)
        self:RemoveUnit(id)
        if team and team ~= gaia and military[defID] then
            buildings[team] = buildings[team] or {}
            buildings[team][id], owner[id] = true, team
        end
    end

    function self:Initialize()
        for _, team in ipairs(Spring.GetTeamList()) do
            if team ~= gaia then
                save(team, Spring.GetTeamRulesParam(team, "collateral_debt") or 0)
            end
        end
        for _, id in ipairs(Spring.GetAllUnits()) do
            self:RegisterUnit(id, Spring.GetUnitDefID(id), Spring.GetUnitTeam(id))
        end
    end

    function self:Charge(team, amount, source)
        if not team or team == gaia or not amount or not (amount > 0) or amount == math.huge then return end
        save(team, (debt[team] or 0) + amount)
        sources[team] = source or sources[team]
    end

    local function takeMoney(team, requested, debtor)
        local available = math.max(0, Spring.GetTeamResources(team, "metal") or 0)
        local amount = math.min(requested, available)
        if amount > 0 and Spring.UseTeamResource(team, "metal", amount) then
            if onMoneyCollected then onMoneyCollected(team, amount, debtor, sources[debtor]) end
            return amount
        end
        return 0
    end

    local function takeAlliedMoney(team, amount)
        local allies, total = {}, 0
        local teams = Spring.GetTeamList()
        table.sort(teams)
        for _, ally in ipairs(teams) do
            if ally ~= gaia and ally ~= team and Spring.AreTeamsAllied(team, ally) then
                local available = math.max(0, Spring.GetTeamResources(ally, "metal") or 0)
                if available > 0 then
                    allies[#allies + 1] = {team = ally, money = available}
                    total = total + available
                end
            end
        end
        if total == 0 then return amount end
        -- Share the shortfall proportionally rather than always emptying the
        -- lowest-numbered teammate's wallet first.
        local fraction = math.min(1, amount / total)
        for _, ally in ipairs(allies) do
            amount = amount - takeMoney(ally.team, math.min(amount, ally.money * fraction), team)
        end
        return math.max(0, amount)
    end

    local function takeMilitaryHealth(team, amount)
        local candidates, total = {}, 0
        for _, id in ipairs(keys(buildings[team] or {})) do
            if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id)
                or Spring.GetUnitTeam(id) ~= team then
                self:RemoveUnit(id)
            else
                local hp = Spring.GetUnitHealth(id)
                if hp and hp > 0 then
                    candidates[#candidates + 1] = {id = id, hp = hp}
                    total = total + hp
                end
            end
        end
        if total == 0 then return amount end
        local fraction = math.min(1, amount * cfg.hpPerMoney / total)
        for _, building in ipairs(candidates) do
            -- Death scripts may remove/transfer another candidate. Never charge
            -- the ledger for health that was not actually available to collect.
            local id = building.id
            if Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
                and Spring.GetUnitTeam(id) == team then
                local hp = Spring.GetUnitHealth(id)
                if hp and hp > 0 then
                    local loss = math.min(hp, building.hp * fraction, amount * cfg.hpPerMoney)
                    if loss > 0 then
                        if hp - loss < epsilon then
                            -- No combat attacker: foreclosure cannot produce
                            -- kill bounties or another collateral penalty.
                            Spring.DestroyUnit(id, false, false)
                        else
                            Spring.SetUnitHealth(id, {health = hp - loss})
                        end
                        amount = math.max(0, amount - loss / cfg.hpPerMoney)
                        if onHealthCollected then onHealthCollected(team, id, loss) end
                    end
                end
            end
        end
        return amount
    end

    function self:Collect()
        -- Only debtors and their military-building rosters are visited, not the
        -- civilian population. Sorted IDs keep collection deterministic.
        for _, team in ipairs(keys(debt)) do
            local startingDebt = debt[team]
            local amount = startingDebt
            amount = amount - takeMoney(team, amount, team)
            if amount > epsilon then amount = takeAlliedMoney(team, amount) end
            if amount > epsilon then amount = takeMilitaryHealth(team, amount) end
            -- Keep anything still unpaid, including when no military building
            -- exists. Future income or new construction will service the debt.
            save(team, amount + math.max(0, (debt[team] or 0) - startingDebt))
        end
    end

    return self
end
