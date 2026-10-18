-- On-demand CPU diagnostics. No rendering, setting changes, or polling.
local M = {maxLampRows = 16}
local function count(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end
local function yes(value) return value and 'yes' or 'no' end
local function finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < math.huge
end
local function visibility(id)
    if not Spring.ValidUnitID(id) then return 'invalid' end
    if Spring.GetUnitIsDead(id) then return 'dead' end
    if Spring.GetUnitIsCloaked(id) then return 'cloaked' end
    if Spring.GetUnitNoDraw(id) then return 'no-draw' end
    if Spring.GetUnitTransporter(id) then return 'transported' end
    local _, full = Spring.GetSpectatingState()
    local los = not full and Spring.GetUnitLosState(id, Spring.GetMyAllyTeamID())
    if not full and not (los and los.los) then return 'outside-unit-LOS' end
    return 'visible'
end

-- Called inside Light Effects, against its REAL collector, not a test source.
-- Return copies only; callers cannot mutate the live light records.
function M.SourceSnapshot(sources, profiles, limit)
    profiles = profiles or {}
    local result = {initialized = sources ~= nil, limit = limit, lamps = {},
        tracked = 0, candidates = 0, visible = 0, queuedLamps = 0, registry = {}}
    if not sources then return result end
    for _, key in ipairs({'transient', 'fires', 'wrecks', 'police', 'tanks',
        'debugLamps', 'torches', 'pyros', 'projectiles'}) do
        result.registry[key] = count(sources[key])
    end
    local ok, lights = pcall(sources.Collect, sources)
    local byOwner = {}
    if ok and type(lights) == 'table' then
        result.queued = #lights
        for _, light in ipairs(lights) do
            if light.unitID then byOwner[light.unitID] = light end
        end
    else
        result.collectError = tostring(ok and 'collector returned no light table' or lights)
    end
    local candidates = {}
    for id in pairs(sources.debugLamps or {}) do candidates[id] = true end
    for _, id in ipairs(Spring.GetAllUnits() or {}) do
        if profiles[Spring.GetUnitDefID(id)] then candidates[id] = true end
    end
    local selected = {}
    for _, id in ipairs(Spring.GetSelectedUnits() or {}) do selected[id] = true end
    local ids = {}
    for id in pairs(candidates) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b)
        if not not selected[a] ~= not not selected[b] then return not not selected[a] end
        return a < b
    end)
    for _, id in ipairs(ids) do
        local record = (sources.debugLamps or {})[id]
        local profile = record and record.profile or profiles[Spring.GetUnitDefID(id)]
        local state = visibility(id)
        local light = byOwner[id]
        local row = {id = id, tracked = record ~= nil, visibility = state,
            queued = light ~= nil, selected = not not selected[id]}
        result.candidates = result.candidates + 1
        if record then result.tracked = result.tracked + 1 end
        if state == 'visible' then result.visible = result.visible + 1 end
        if light then result.queuedLamps = result.queuedLamps + 1 end
        -- Never query hidden anchors or print their cached coordinates.
        if state == 'visible' and profile then
            local map = Spring.GetUnitPieceMap(id)
            row.pieceName = profile.piece
            row.piece = map and map[profile.piece]
            local px, py, pz
            if row.piece ~= nil then
                px, py, pz = Spring.GetUnitPiecePosDir(id, row.piece)
            end
            row.anchorAvailable = finite(px) and finite(py) and finite(pz)
            if light then
                row.x, row.y, row.z = light.x, light.y, light.z
                row.radius, row.strength = light.radius, light.strength
                row.nightOnly = light.nightOnly
                row.finite = finite(row.x) and finite(row.y) and finite(row.z)
                    and finite(row.radius) and finite(row.strength)
                if row.finite then
                    row.ground = math.max(0, Spring.GetGroundHeight(row.x, row.z)) + 1
                    row.groundReach = math.abs(row.y - row.ground) < row.radius
                end
            end
        end
        if #result.lamps < M.maxLampRows then result.lamps[#result.lamps + 1] = row end
    end
    return result
end

function M.Report(shared, echo)
    local function log(text) echo('[MOSAIC radiance] ' .. text) end
    local function query(label, fn)
        if type(fn) ~= 'function' then return nil end
        local ok, value = pcall(fn)
        if not ok then log(label .. ' ERROR: ' .. tostring(value)); return nil end
        return value
    end
    local rc = shared.NeonRadiance
    log(string.format('frame=%s | cascade=%s | resolved-texture=%s | providers combat=%s headlights=%s shore=%s',
        tostring(Spring.GetGameFrame()), rc and (rc.ready and 'ready' or 'pending') or 'absent',
        yes(rc and rc.unitTexture), yes(shared.CaptureCombatLightEmission),
        yes(shared.CaptureVehicleHeadlightEmission), yes(shared.CaptureShoreBioluminescence)))
    -- This existing read-only API checks scene enable/readiness, gain and dirty
    -- occupancy. Do not call the fog API: it requests future GPU height work.
    local scene = query('scene state', shared.GetRainRadiance)
    if scene then
        log(string.format('scene=ready | band=%s..%s | gain=%s | local-detail=%s',
            tostring(scene.bottom), tostring(scene.top), tostring(scene.strength), yes(scene.detail)))
    else
        log('scene=unavailable (disabled, not ready, zero gain, or pending occupancy; inspect startup infolog)')
    end
    local effects = shared.lighteffects
    if not effects or type(effects.getRadianceDiagnostics) ~= 'function' then
        log('Light Effects diagnostics unavailable: widget absent or older build; lamp queue is UNKNOWN')
    else
        local s = query('combat diagnostics', effects.getRadianceDiagnostics)
        if s then
            log(string.format('combat capture-ready=%s published=%s | queued=%s/%s | lamp candidates=%d tracked=%d visible=%d queued=%s',
                yes(s.captureReady), yes(s.capturePublished), tostring(s.queued or 'UNKNOWN'),
                tostring(s.limit or '?'), s.candidates, s.tracked, s.visible, s.collectError and 'UNKNOWN' or tostring(s.queuedLamps)))
            if s.collectError then log('COLLECT ERROR: ' .. s.collectError) end
            local r = s.registry
            log(string.format('registered: police=%d tanks=%d wrecks=%d fires=%d transient=%d pyros=%d projectiles=%d',
                r.police or 0, r.tanks or 0, r.wrecks or 0, r.fires or 0,
                r.transient or 0, r.pyros or 0, r.projectiles or 0))
            for _, row in ipairs(s.lamps) do
                local line = string.format('lamp %s%s: tracked=%s visibility=%s queued=%s',
                    tostring(row.id), row.selected and ' (selected)' or '', yes(row.tracked),
                    row.visibility, s.collectError and 'UNKNOWN' or yes(row.queued))
                if row.visibility == 'visible' then
                    line = line .. string.format(' | bulb=%s anchor=%s',
                        tostring(row.piece or 'missing'), row.anchorAvailable and 'piece' or 'fallback/unavailable')
                end
                if row.finite then
                    local band = scene and finite(scene.bottom) and finite(scene.top)
                    local intersects = band and row.y + row.radius > scene.bottom and row.y - row.radius < scene.top
                    line = line .. string.format(' | pos=%.1f,%.1f,%.1f radius=%.1f strength=%.2f night-only=%s ground-reach=%s band=%s',
                        row.x, row.y, row.z, row.radius, row.strength, yes(row.nightOnly),
                        yes(row.groundReach), band and yes(intersects) or 'UNKNOWN')
                elseif row.queued and row.visibility == 'visible' then
                    line = line .. ' | INVALID source coordinates/radius/strength'
                end
                log(line)
            end
            if s.candidates > #s.lamps then
                log(string.format('%d more lamps omitted; select a lamp to prioritize it', s.candidates - #s.lamps))
            end
        end
    end
    log('Queued sources and ready textures do NOT prove visible pixels. Pair with /radiancedebug on and save infolog.txt.')
end
return M
