function gadget:GetInfo()
    return {name = "Sticky bomb inventory", desc = "Build carried charges and plant them on an explicit target",
        author = "Mosaic contributors", license = "GNU GPL, v2 or later", layer = 0, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return end
VFS.Include("luarules/configs/commandsIDs.lua")
local config = VFS.Include("luarules/configs/sticky_bombs.lua")
local bombDefID = UnitDefNames.ground_stickybomb.id
local bombDef = UnitDefs[bombDefID]
local BUILD, PLANT = CMD_STICKY_BUILD, CMD_STICKY_PLANT
local carriers, builderDefs, operativeDefs = {}, {}, {}
local dropped, internalSpawn = {}, false
local step = 3
for defID, def in pairs(UnitDefs) do
    for _, buildDefID in ipairs(def.buildOptions or {}) do
        if buildDefID == bombDefID then builderDefs[defID] = true end
    end
end
for _, name in ipairs({"operativeasset", "operativepropagator", "operativeinvestigator", "civilianagent"}) do
    if UnitDefNames[name] then operativeDefs[UnitDefNames[name].id] = true end
end
GG.StickyBombPayloads = GG.StickyBombPayloads or {}

local function alive(id)
    return type(id) == "number" and id == id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function refresh(id, s)
    Spring.SetUnitRulesParam(id, "sticky_bombs", s.stock, {allied = true})
    Spring.SetUnitRulesParam(id, "sticky_bombs_queued", s.queued, {allied = true})
    Spring.SetUnitRulesParam(id, "sticky_bomb_progress", s.progress, {allied = true})
    local build = Spring.FindUnitCmdDesc(id, -bombDefID)
    if build then
        -- Keep the existing build-menu tile, but a click issues an immediate command.
        Spring.EditUnitCmdDesc(id, build, {type = CMDTYPE.ICON,
            params = {s.stock .. " (+" .. s.queued .. ")"},
            tooltip = "Build a carried sticky bomb. Ready: " .. s.stock .. "; queued: " .. s.queued ..
                ". Right-click cancels one queued bomb. Carried bombs explode 2 seconds after death."})
    end
    local plant = Spring.FindUnitCmdDesc(id, PLANT)
    if plant then
        Spring.EditUnitCmdDesc(id, plant, {name = "Plant bomb (" .. s.stock .. ")",
            tooltip = "Click the exact vehicle or building to approach and plant one charge. 5 second fuse. Ready: " .. s.stock})
    end
end
function gadget:UnitCreated(id, defID)
    if not builderDefs[defID] or carriers[id] then return end
    local s = {stock = Spring.GetUnitRulesParam(id, "sticky_bombs") or 0,
        queued = Spring.GetUnitRulesParam(id, "sticky_bombs_queued") or 0,
        progress = Spring.GetUnitRulesParam(id, "sticky_bomb_progress") or 0}
    carriers[id] = s
    if not Spring.FindUnitCmdDesc(id, PLANT) then
        Spring.InsertUnitCmdDesc(id, {id = PLANT, type = CMDTYPE.ICON_UNIT, name = "Plant bomb (0)",
            action = "plantstickybomb", cursor = "Attack", texture = "unitpics/StickyBomb.png"})
    end
    refresh(id, s)
end
function gadget:Initialize()
    gadgetHandler:RegisterCMDID(BUILD)
    gadgetHandler:RegisterCMDID(PLANT)
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id, Spring.GetUnitDefID(id)) end
end
local function validTarget(id, target)
    if not alive(target) or target == id then return false end
    local defID = Spring.GetUnitDefID(target)
    local def = UnitDefs[defID]
    if not def or defID == bombDefID or operativeDefs[defID] or def.canFly then return false end
    local team = Spring.GetUnitTeam(id)
    if Spring.AreTeamsAllied(team, Spring.GetUnitTeam(target)) then return false end
    local los = Spring.GetUnitLosState(target, Spring.GetUnitAllyTeam(id))
    return los and los.los
end
local function editQueue(id, s, opts)
    local amount = opts.shift and 5 or 1
    if opts.ctrl then amount = amount * 20 end
    if opts.right then
        local remove = math.min(amount, s.queued)
        s.queued = s.queued - remove
        if s.queued == 0 and s.progress > 0 then
            local team = Spring.GetUnitTeam(id)
            Spring.AddTeamResource(team, "metal", bombDef.metalCost * s.progress)
            Spring.AddTeamResource(team, "energy", bombDef.energyCost * s.progress)
            s.progress = 0
        end
    else
        s.queued = s.queued + amount
    end
    refresh(id, s)
end
function gadget:AllowCommand(id, defID, team, cmd, p, opts)
    -- Do not let inserted legacy build orders bypass inventory production.
    if cmd == CMD.INSERT and (p[2] == -bombDefID or p[2] == BUILD) then return false end
    if cmd == BUILD or cmd == -bombDefID then
        local s = carriers[id]
        if s then editQueue(id, s, opts or {}) end
        return false -- inventory production never replaces movement/attack orders
    end
    if cmd == PLANT then
        return carriers[id] ~= nil and #p == 1 and validTarget(id, p[1])
    end
    return true
end
function gadget:AllowUnitCreation(defID, builderID)
    return defID ~= bombDefID or not builderID or internalSpawn
end
local function spawnBomb(x, y, z, team, target, fuse, count)
    internalSpawn = true
    local bomb = Spring.CreateUnit("ground_stickybomb", x, y, z, 0, team)
    internalSpawn = false
    if not bomb then return end
    if target then
        local pieces = Spring.GetUnitPieceMap(target) or {}
        local anchor = pieces.center or pieces.base
        if not anchor then
            for _, index in pairs(pieces) do
                if not anchor or index < anchor then anchor = index end
            end
        end
        if anchor then Spring.UnitAttach(target, bomb, anchor, true) end
        if Spring.GetUnitTransporter(bomb) ~= target then
            Spring.DestroyUnit(bomb, false, true)
            return
        end
    end
    GG.StickyBombPayloads[bomb] = {target = target, fuse = fuse, count = count or 1}
    Spring.SetUnitBlocking(bomb, false, false, false)
    return bomb
end
function gadget:CommandFallback(id, defID, team, cmd, p)
    if cmd ~= PLANT then return false end
    local s, target = carriers[id], p[1]
    if not s or #p ~= 1 or not validTarget(id, target) then
        Spring.ClearUnitGoal(id)
        return true, true
    end
    if s.stock == 0 then
        Spring.ClearUnitGoal(id)
        return true, s.queued == 0 -- allow planting to wait for a bomb being built
    end
    local x, y, z = Spring.GetUnitPosition(id)
    local tx, ty, tz = Spring.GetUnitPosition(target)
    if not x or not tx then return true, true end
    local range = config.plantRange + (Spring.GetUnitRadius(target) or 0)
    if (x-tx)^2 + (y-ty)^2 + (z-tz)^2 > range^2 then
        Spring.SetUnitMoveGoal(id, tx, ty, tz, range - 8)
        return true, false
    end
    Spring.ClearUnitGoal(id)
    -- Only a successful placement spends inventory; failure never picks a substitute.
    if not spawnBomb(tx, ty, tz, team, target, config.plantedFuseMs) then return true, true end
    s.stock = s.stock - 1
    refresh(id, s)
    return true, true
end
function gadget:GameFrame(frame)
    -- Spawn after the death call-in; the dying unit must finish engine cleanup first.
    for i = #dropped, 1, -1 do
        local d = dropped[i]
        if not d.spawned then
            -- One dropped bundle carries the full blast strength. Separate charges
            -- at the same point would destroy each other before their fuses finish.
            d.failed = not spawnBomb(d.x, d.y, d.z, d.team, nil, config.deathFuseMs, d.count)
            d.spawned = true
        end
        -- Unit limits must not make carried explosives disappear harmlessly.
        if not d.failed or frame >= d.due then
            if d.failed then
                config.explode(nil, nil, d.x, d.y, d.z, d.count)
            end
            table.remove(dropped, i)
        end
    end
    if frame % step ~= 0 then return end
    for id, s in pairs(carriers) do
        if s.queued > 0 and alive(id) then
            local stunned, _, beingBuilt = Spring.GetUnitIsStunned(id)
            if not stunned and not beingBuilt then
                local speed = UnitDefs[Spring.GetUnitDefID(id)].buildSpeed or 0
                local increment = math.min(1 - s.progress, speed * step / (Game.gameSpeed * bombDef.buildTime))
                if increment > 0 and Spring.UseUnitResource(id,
                    {m = bombDef.metalCost * increment, e = bombDef.energyCost * increment}) then
                    s.progress = s.progress + increment
                    if s.progress >= 1 - 1e-9 then
                        s.progress, s.queued, s.stock = 0, s.queued - 1, s.stock + 1
                    end
                    refresh(id, s)
                end
            end
        end
    end
end
function gadget:UnitDestroyed(id, defID, team)
    local s = carriers[id]
    carriers[id] = nil
    GG.StickyBombPayloads[id] = nil
    if not s or s.stock == 0 then return end
    local x, y, z = Spring.GetUnitPosition(id)
    if x then
        dropped[#dropped+1] = {x = x, y = y, z = z, team = team, count = s.stock,
            due = Spring.GetGameFrame() + math.ceil(config.deathFuseMs * Game.gameSpeed / 1000)}
    end
end
function gadget:UnitGiven(id, defID)
    -- Carried inventory belongs to the unit and survives a team transfer.
    if carriers[id] then refresh(id, carriers[id]) else self:UnitCreated(id, defID) end
end

function gadget:UnitFinished(id)
    if carriers[id] then refresh(id, carriers[id]) end
end
