function gadget:GetInfo()
    return {name = "Safehouse lifecycle trace", desc = "Persistent safehouse and upgrade lifecycle diagnostics",
        author = "MOSAIC contributors", license = "GPL3", layer = -10000, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local trackedDefs = getSafeHouseTypeTable(UnitDefs)
for def in pairs(getAllSafeHouseUpgradeTypeTable(UnitDefs)) do trackedDefs[def] = true end
local records, removals = {}, {}
local api = {}

local function name(def)
    return def and UnitDefs[def] and UnitDefs[def].name or "unknown"
end
local function refresh(id, def, team)
    def = def or Spring.GetUnitDefID(id)
    local record = records[id]
    if not record and not trackedDefs[def] then return end
    record = record or {id = id, def = def}
    record.team = team or Spring.GetUnitTeam(id) or record.team
    local x,y,z = Spring.GetUnitPosition(id)
    if x then record.x,record.y,record.z = x,y,z end
    local hp,_,_,_,build = Spring.GetUnitHealth(id)
    if hp then record.hp,record.build = hp,build end
    for house, occupant in pairs(GG.houseHasSafeHouseTable or {}) do
        if occupant == id then
            record.host = house
            record.hostName = Spring.GetUnitTooltip(house)
            break
        end
    end
    records[id] = record
    return record
end
local function emit(record, event, details)
    if not record then return end
    local fields = {"[MOSAIC safehouse]", "event="..event,
        "frame="..Spring.GetGameFrame(), "unit="..record.id, "type="..name(record.def),
        "team="..tostring(record.team), "host="..tostring(record.host or "none"),
        "host_name="..string.format("%q", record.hostName or "unknown"),
        string.format("pos=(%.1f,%.1f,%.1f)", record.x or 0,record.y or 0,record.z or 0),
        "hp="..tostring(record.hp), "build="..tostring(record.build)}
    local keys = {}
    for key in pairs(details or {}) do keys[#keys+1] = key end
    table.sort(keys)
    for _,key in ipairs(keys) do
        fields[#fields+1] = key.."="..string.format("%q", tostring(details[key]))
    end
    Spring.Echo(table.concat(fields, " "))
end
function api.Event(id, event, details)
    if id then emit(refresh(id), event, details) end
end
function api.Removal(id, reason, details)
    local record = id and refresh(id)
    if not record then return end
    removals[id] = reason
    local fields = {reason = reason}
    for key,value in pairs(details or {}) do fields[key] = value end
    emit(record, "removal_requested", fields)
end
function api.BeginTransform(id, newDef, newTeam, reason)
    local record = refresh(id)
    if not record then return end
    local context = {record = {}, newDef = newDef, newTeam = newTeam, reason = reason}
    -- Retain the old identity even when the engine recycles its unit ID.
    for key,value in pairs(record) do context.record[key] = value end
    emit(record, "transform_begin", {new_type = name(newDef), new_team = newTeam, reason = reason})
    return context
end
function api.EndTransform(context, newID)
    if not context then return end
    emit(context.record, newID and "transform_complete" or "transform_failed", {
        new_unit = newID or "none", new_type = name(context.newDef),
        new_team = context.newTeam, reason = context.reason})
end

function gadget:Initialize()
    GG.SafehouseTrace = api
    for _,id in ipairs(Spring.GetAllUnits()) do api.Event(id, "existing") end
end
function gadget:UnitCreated(id, def, team, builder)
    if trackedDefs[def] then
        records[id],removals[id] = nil,nil
        emit(refresh(id,def,team), "created", {builder = builder or "none"})
    end
end
function gadget:UnitFinished(id, def, team)
    if trackedDefs[def] then emit(refresh(id,def,team), "finished") end
end
function gadget:UnitCloaked(id, def, team)
    if trackedDefs[def] then emit(refresh(id,def,team), "cloaked") end
end
function gadget:UnitDecloaked(id, def, team)
    if trackedDefs[def] then emit(refresh(id,def,team), "decloaked") end
end
function gadget:UnitTaken(id, def, oldTeam, newTeam)
    if trackedDefs[def] then
        emit(refresh(id,def,oldTeam), "ownership_taken", {old_team = oldTeam, new_team = newTeam})
    end
end
function gadget:UnitGiven(id, def, newTeam, oldTeam)
    if trackedDefs[def] then
        emit(refresh(id,def,newTeam), "ownership_given", {old_team = oldTeam, new_team = newTeam})
    end
end
function gadget:UnitDamaged(id, def, team, damage, paralyzer, weapon, projectile, attacker, attackerDef, attackerTeam)
    if not trackedDefs[def] or damage <= 0 or paralyzer then return end
    local record = refresh(id,def,team)
    record.lastHit = {last_damage_frame = Spring.GetGameFrame(), last_damage = damage,
        last_attacker = attacker or "none", last_attacker_type = name(attackerDef),
        last_attacker_team = attackerTeam or "none", last_weapon = weapon or "none"}
end
function gadget:UnitCommand(id, def, team, cmd, params)
    if trackedDefs[def] then
        emit(refresh(id,def,team), "command", {command = cmd, params = table.concat(params or {}, ",")})
    elseif cmd == CMD.RECLAIM and params and #params == 1 then
        api.Event(params[1], "reclaim_order", {builder = id, builder_team = team})
    end
end
function gadget:UnitDestroyed(id, def, team, attacker, attackerDef, attackerTeam)
    -- This early-layer observer runs before city/dependency cleanup clears the
    -- host link and recursively destroys the occupant.
    local occupant = GG.houseHasSafeHouseTable and GG.houseHasSafeHouseTable[id]
    if occupant then
        api.Removal(occupant, "host_destroyed", {host_attacker = attacker or "none",
            host_attacker_type = name(attackerDef), host_attacker_team = attackerTeam or "none"})
    end
    if trackedDefs[def] or records[id] then
        local record = refresh(id,def,team)
        local fields = {reason = removals[id] or "unattributed_engine_destruction",
            attacker = attacker or "none", attacker_type = name(attackerDef),
            attacker_team = attackerTeam or "none"}
        for key,value in pairs(record.lastHit or {}) do fields[key] = value end
        emit(record, "destroyed", fields)
    end
    records[id],removals[id] = nil,nil
end
function gadget:Shutdown()
    if GG.SafehouseTrace == api then GG.SafehouseTrace = nil end
end
