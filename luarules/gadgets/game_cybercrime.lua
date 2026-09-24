function gadget:GetInfo()
    return {name = "Building cybercrime", desc = "Finite city extraction and covert economic sabotage",
        author = "Mosaic contributors", license = "GPL3", layer = 2, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return end
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

local cfg = getGameConfig().CyberCrime
local cyberDef = UnitDefNames.icon_cybercrime.id
local serverDef = UnitDefNames.propagandaserver.id
local safehouseTypes = getSafeHouseTypeTable(UnitDefs)
local gaia = Spring.GetGaiaTeamID()
local nodes, builders, accounts = {}, {}, {}
local private = {private = true}

local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function finished(id)
    local _, _, _, _, progress = Spring.GetUnitHealth(id)
    return progress and progress >= 1
end
local function distance(a, b)
    local x, _, z = Spring.GetUnitPosition(a)
    local bx, _, bz = Spring.GetUnitPosition(b)
    if not x or not bx then return math.huge end
    return (x-bx)^2 + (z-bz)^2
end
local function nearestBuilding(id)
    local x, _, z = Spring.GetUnitPosition(id)
    if not x then return end
    local best, bestDistance
    for _, house in ipairs(Spring.GetUnitsInCylinder(x, z, cfg.buildingRange)) do
        if GG.BuildingTable and GG.BuildingTable[house] and alive(house) then
            local d = distance(id, house)
            if not bestDistance or d < bestDistance or (d == bestDistance and house < best) then
                best, bestDistance = house, d
            end
        end
    end
    return best
end
local function recover(account, frame)
    if not account.node then
        account.funds = math.min(cfg.buildingCapacity,
            account.funds + (frame-account.updated) * cfg.recoveryPerSecond / 30)
    end
    account.updated = frame
end
local function stop(id, alreadyDestroyed)
    local node = nodes[id]
    if not node then return end
    nodes[id] = nil
    local account = accounts[node.building]
    if account and account.node == id then
        account.node, account.updated = nil, Spring.GetGameFrame()
    end
    if GG.CancelCyberCrimeReport then GG.CancelCyberCrimeReport(id) end
    if not alreadyDestroyed and alive(id) then Spring.DestroyUnit(id, false, true) end
end
local function enemyOccupier(building, team)
    local occupant = GG.houseHasSafeHouseTable and GG.houseHasSafeHouseTable[building]
    local otherTeam
    if alive(occupant) and finished(occupant) then otherTeam = Spring.GetUnitTeam(occupant) end
    if not otherTeam then otherTeam = Spring.GetUnitTeam(building) end
    if otherTeam and otherTeam ~= gaia and otherTeam ~= team and not Spring.AreTeamsAllied(team, otherTeam) then
        return otherTeam
    end
end
local function supported(building, team)
    local x, _, z = Spring.GetUnitPosition(building)
    for _, id in ipairs(Spring.GetUnitsInCylinder(x, z, cfg.safehouseRange)) do
        if safehouseTypes[Spring.GetUnitDefID(id)] and Spring.GetUnitTeam(id) == team and finished(id) then
            return true
        end
    end
    return false
end
local function comeback(team)
    if not cfg.comebackEnabled or Spring.GetTeamRulesParam(team, "cybercrime_comeback_used") == 1 then return 0,0 end
    local def = UnitDefs[serverDef]
    local money = Spring.GetTeamResources(team, "metal") or 0
    local energy = Spring.GetTeamResources(team, "energy") or 0
    if money >= def.metalCost and energy >= def.energyCost then return 0,0 end
    for _, id in ipairs(Spring.GetTeamUnitsByDefs(team, serverDef)) do
        if alive(id) and finished(id) then return 0,0 end
    end
    -- Store on the team, not the icon: parallel nodes, transfers and gadget reloads
    -- cannot claim the temporary recovery aid again.
    Spring.SetTeamRulesParam(team, "cybercrime_comeback_used", 1, private)
    return cfg.comebackMoney, cfg.comebackEnergy
end
local function start(id, team)
    if nodes[id] then return end
    local building = nearestBuilding(id)
    local frame = Spring.GetGameFrame()
    local account = building and accounts[building]
    if building and not account then
        account = {funds = cfg.buildingCapacity, updated = frame}
        accounts[building] = account
    end
    if account then recover(account, frame) end
    if not account or account.node or account.funds < cfg.payout then
        -- Invalid placement/duplicate construction cannot be used as an income source.
        Spring.AddTeamResource(team, "metal", UnitDefs[cyberDef].metalCost or 0)
        Spring.DestroyUnit(id, false, true)
        return
    end
    account.node = id
    nodes[id] = {building = building, team = team, builder = builders[id],
        ends = frame+cfg.durationFrames, nextPayout = frame+cfg.payoutIntervalFrames,
        reportDue = frame+cfg.policeDelayFrames}
    Spring.SetUnitRulesParam(id, "cybercrime_building", building, private)
    Spring.SetUnitRulesParam(id, "cybercrime_until", frame+cfg.durationFrames, private)
    Spring.SetUnitRulesParam(id, "cybercrime_paid", 0, private)
    if GG.ReportCyberCrime then
        GG.ReportCyberCrime(id, building, nodes[id].reportDue)
        nodes[id].reported = true
    end
end
function gadget:UnitCreated(id, defID, team, builder)
    if defID == cyberDef then builders[id] = builder end
end
function gadget:UnitFinished(id, defID, team)
    if defID == cyberDef then start(id, team) end
end
function gadget:UnitDestroyed(id)
    stop(id, true)
    builders[id] = nil
    if accounts[id] then
        local node = accounts[id].node
        accounts[id] = nil
        if node then stop(node) end
    end
end
function gadget:UnitTaken(id, defID)
    -- Capturing an icon must not preserve the old owner's extraction or free-refund it.
    if defID == cyberDef then stop(id) end
end
function gadget:Initialize()
    GG.CyberCrime = {
        Stop = stop,
        GetBuilder = function(id) return nodes[id] and nodes[id].builder end,
    }
    for _, id in ipairs(Spring.GetAllUnits()) do
        if Spring.GetUnitDefID(id) == cyberDef and finished(id) then start(id, Spring.GetUnitTeam(id)) end
    end
end
function gadget:GameFrame(frame)
    if frame % 30 ~= 0 then return end
    -- Stable ordering matters when simultaneous siphons share a victim team's balance.
    local ids = {}
    for id in pairs(nodes) do ids[#ids+1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local node = nodes[id]
        if not node.reported and GG.ReportCyberCrime then
            GG.ReportCyberCrime(id, node.building, node.reportDue)
            node.reported = true
        end
        if not alive(id) or not alive(node.building) or Spring.GetUnitTeam(id) ~= node.team then
            stop(id)
        elseif frame >= node.nextPayout then
            local account = accounts[node.building]
            local victim = enemyOccupier(node.building, node.team)
            local multiplier = not victim and supported(node.building, node.team) and cfg.safehouseMultiplier or 1
            local amount = math.min(account.funds, cfg.payout * multiplier)
            if amount > 0 then
                -- The victim's loss never generates a position popup or public unit parameter.
                if victim then
                    local balance = Spring.GetTeamResources(victim, "metal") or 0
                    local debit = math.min(balance, amount * cfg.enemyDrainMultiplier)
                    if debit > 0 then Spring.UseTeamResource(victim, "metal", debit) end
                end
                local bonus, energy = comeback(node.team)
                if GG.Bank then GG.Bank:TransferToTeam(amount+bonus, node.team, id)
                else Spring.AddTeamResource(node.team, "metal", amount+bonus) end
                if energy > 0 then Spring.AddTeamResource(node.team, "energy", energy) end
                if bonus > 0 then Spring.SetUnitRulesParam(id, "cybercrime_comeback", bonus, private) end
                node.paid = (node.paid or 0) + amount+bonus
                Spring.SetUnitRulesParam(id, "cybercrime_paid", node.paid, private)
                account.funds = account.funds-amount
            end
            node.nextPayout = frame+cfg.payoutIntervalFrames
            if account.funds <= 0 or frame >= node.ends then stop(id) end
        elseif frame >= node.ends then stop(id) end
    end
end
function gadget:Shutdown()
    GG.CyberCrime = nil
end
