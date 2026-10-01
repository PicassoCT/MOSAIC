function gadget:GetInfo()
    return {
        name = "Objectives",
        desc = "Spawns objectives and rewards holding their current state",
        author = "Pircossa, Mosaic contributors",
        date = "2.2.2009", license = "GPL2.1", layer = 50, enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end
VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_mosaic.lua")

local Income = VFS.Include("luarules/gadgets/include/objective_income.lua")
local gaiaTeamID = Spring.GetGaiaTeamID()
local objectiveTypes = getObjectiveTypes(UnitDefs)
local config = getGameConfig().objectives
local server = UnitDefNames.propagandaserver
local serverDef = server and UnitDefs[server.id]
local serverIncome = serverDef and (serverDef.metalMake or serverDef.metalmake) or 0
local sides = {protagon=getAllTeamsOfType("protagon", UnitDefs), antagon=getAllTeamsOfType("antagon", UnitDefs)}
GG.Objectives = GG.Objectives or {}
GG.DeadObjectives = GG.DeadObjectives or {}
GG.ObjectiveRestores = GG.ObjectiveRestores or {}
GG.ObjectiveIncomeClock = GG.ObjectiveIncomeClock or {frame=Spring.GetGameFrame()}
GG.ObjectiveSiteCounter = GG.ObjectiveSiteCounter or 0
for _, group in ipairs({GG.Objectives, GG.DeadObjectives, GG.ObjectiveRestores}) do
    for id, record in pairs(group) do
        record.siteID = record.siteID or id
        record.income = record.income or {pressure=0, accrued=0}
        GG.ObjectiveSiteCounter = math.max(GG.ObjectiveSiteCounter, record.siteID)
    end
end

local function getSites()
    local sites, ids, records = {}, {}, {}
    for _, group in ipairs({GG.Objectives, GG.DeadObjectives}) do
        for id, record in pairs(group) do
            sites[record.siteID] = record
        end
    end
    for _, record in ipairs(GG.ObjectiveRestores) do
        -- Creation calls UnitCreated synchronously, before the pending entry
        -- is removed. Count the new unit and pending restore as one site.
        if not sites[record.siteID] then sites[record.siteID] = record end
    end
    for id in pairs(sites) do ids[#ids+1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do records[#records+1] = sites[id] end
    return records
end

local income = Income.New(Spring, Game, config.income, serverIncome, sides,
    function(amount, team, id)
        -- The bank replaces its queue after processing: always use the live API.
        GG.Bank:TransferToTeam(amount, team, id, {r=0, g=0, b=255})
    end, getSites, GG.ObjectiveIncomeClock)
local initializing, restoring = false, nil

local function describe(record, dead)
    local defender = record.boolProProtagon and "Protagon" or "Antagon"
    local attacker = record.boolProProtagon and "Antagon" or "Protagon"
    local name = UnitDefs[record.defID].humanName or UnitDefs[record.defID].name
    Spring.SetUnitTooltip(record.uid, name .. (dead and " <Destroyed objective> " or " <Objective> ")
        .. defender .. " must defend / " .. attacker .. (dead and " must attack to restore" or " must destroy"))
    Spring.SetUnitAlwaysVisible(record.uid, true)
end

local function newRecord(id, defID, x, y, z, pro, facing, siteID)
    if not siteID then
        GG.ObjectiveSiteCounter = GG.ObjectiveSiteCounter + 1
        siteID = GG.ObjectiveSiteCounter
    end
    local record = {uid=id, siteID=siteID, defID=defID, x=x, y=y, z=z, boolProProtagon=pro, facing=facing or 0}
    income.Register(record, Spring.GetGameFrame())
    return record
end

local function defaultInit()
    local centerX, centerZ = Game.mapSizeX / 2, Game.mapSizeZ / 2
    local oz = math.min(Game.mapSizeX, Game.mapSizeZ) - math.random(500, 1000)
    local angle = math.random(7, 20) * randSign()
    for i = 1, 2 do
        local rx, rz = Rotate(0, oz - centerZ, math.rad(i * 180 + 90 + angle))
        rx, rz = rx + centerX, rz + centerZ
        local height = Spring.GetGroundHeight(rx, rz)
        local medium = height > 5 and "land" or "water"
        local candidates = {}
        for id, kind in pairs(objectiveTypes) do
            if kind == medium then candidates[id] = id end
        end
        if next(candidates) then
            local _, defID = randDict(candidates)
            Spring.CreateUnit(defID, rx, height, rz, 1, gaiaTeamID)
        end
    end
    initializing = false
end

function gadget:Initialize()
    -- Preserve tracked states on LuaRules reload instead of spawning duplicates.
    initializing = not (next(GG.Objectives) or next(GG.DeadObjectives) or next(GG.ObjectiveRestores))
end

function gadget:UnitCreated(id, defID, teamID)
    defID = defID or Spring.GetUnitDefID(id)
    teamID = teamID or Spring.GetUnitTeam(id)
    if not objectiveTypes[defID] or teamID ~= gaiaTeamID then return end
    local x, y, z = Spring.GetUnitPosition(id)
    local pro = count(GG.Objectives) % 2 == 0
    local facing = Spring.GetUnitBuildFacing(id)
    local siteID
    if restoring and restoring.defID == defID and math.abs(x-restoring.x)<1 and math.abs(z-restoring.z)<1 then
        pro, facing = restoring.boolProProtagon, restoring.facing
        siteID = restoring.siteID
    end
    local record = newRecord(id, defID, x, y, z, pro, facing, siteID)
    GG.Objectives[id] = record
    describe(record, false)
end

function gadget:UnitDamaged(id, defID, teamID, damage, paralyzer, weaponID, projectileID, attackerID, attackerDefID, attackerTeam)
    local record = GG.Objectives[id] or GG.DeadObjectives[id]
    if not record then return end
    if not attackerTeam and attackerID then attackerTeam = Spring.GetUnitTeam(attackerID) end
    local _, maxHealth = Spring.GetUnitHealth(id)
    income.Damage(record, Spring.GetGameFrame(), damage, maxHealth, attackerTeam, paralyzer)
end

function gadget:UnitDestroyed(id, defID, teamID)
    local live, dead = GG.Objectives[id], GG.DeadObjectives[id]
    local record = live or dead
    if not record then return end
    -- Settle only time actually held. A flip just before a tick earns no
    -- full-interval windfall; newly captured states inherit no pressure.
    income.Pay(record, Spring.GetGameFrame())
    GG.Objectives[id], GG.DeadObjectives[id] = nil, nil
    if live then
        local marker = Spring.CreateUnit("destroyedobjectiveicon", record.x, record.y, record.z, 0, gaiaTeamID)
        if marker then
            local nextRecord = newRecord(marker, record.defID, record.x, record.y, record.z, not record.boolProProtagon, record.facing, record.siteID)
            GG.DeadObjectives[marker] = nextRecord
            describe(nextRecord, true)
        else
            -- Retry failed marker creation instead of losing the objective.
            GG.ObjectiveRestores[#GG.ObjectiveRestores+1] = {marker=true, defID=record.defID, x=record.x, y=record.y,
                z=record.z, facing=record.facing, boolProProtagon=not record.boolProProtagon, siteID=record.siteID}
        end
    elseif dead then
        GG.ObjectiveRestores[#GG.ObjectiveRestores+1] = {defID=record.defID, x=record.x, y=record.y,
            z=record.z, facing=record.facing, boolProProtagon=not record.boolProProtagon, siteID=record.siteID}
    end
end

local function restorePending()
    local remaining = {}
    for _, record in ipairs(GG.ObjectiveRestores) do
        restoring = record
        local id = Spring.CreateUnit(record.marker and "destroyedobjectiveicon" or record.defID,
            record.x, record.y, record.z, record.facing or 0, gaiaTeamID)
        restoring = nil
        if not id then
            remaining[#remaining+1] = record
        elseif record.marker then
            local marker = newRecord(id, record.defID, record.x, record.y, record.z, record.boolProProtagon, record.facing, record.siteID)
            GG.DeadObjectives[id] = marker
            describe(marker, true)
        end
    end
    GG.ObjectiveRestores = remaining
end

local function payAll(records, frame)
    local ids = {}
    for id in pairs(records) do ids[#ids+1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        if doesUnitExistAlive(id) then
            local record = records[id]
            income.Pay(record, frame)
            Spring.SetUnitRulesParam(id, "objective_income", income.Rate(record, frame), {public=true})
        end
    end
end

function gadget:GameFrame(frame)
    if initializing then
        if getManualObjectiveSpawnMapNames(Game.mapName) then
            detectMapControlledPlacementComplete()
            initializing = not GG.MapCompletedBuildingPlacement
        else
            defaultInit()
        end
        if initializing then return end
    end
    if frame % (Game.gameSpeed or 30) == 0 then restorePending() end
    if frame % config.payoutIntervalFrames == 0 then
        payAll(GG.Objectives, frame)
        payAll(GG.DeadObjectives, frame)
    end
end
