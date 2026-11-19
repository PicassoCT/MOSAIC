-- External lab observer: real framebuffer pixels and engine telemetry only.
function widget:GetInfo()
    return {name = 'External Animation Lab Capture', desc = 'Disposable visual evidence recorder',
        author = 'MOSAIC contributors', license = 'GPL-3.0-or-later',
        layer = -100000, enabled = true}
end
local configPath = 'luarules/configs/animation_lab_run.lua'
if not VFS.FileExists(configPath) then return false end
local config = VFS.Include(configPath)
local scenario = config.scenario
local json = VFS.Include('luarules/configs/animation_lab_json.lua')
local capture = scenario.capture
local directory = config.output_dir or 'animlab'
local captureDirectory = config.capture_dir or directory .. '/captures'
local log, started, oldCamera, oldGUI, basis, cameraState, pending = nil, nil, nil, nil, nil, nil, {}
local lastFrame, lastPhase, lastReady, forcedStart, finished, failure = nil, nil, -1, false, false, nil
local armed, readyDraws = false, 0
local drawnFrame, steppedFrame
local targetName = scenario.camera.target or scenario.units[1].name
local subjectIndex, pieceCache = {}, {}
local simFPS = Game.gameSpeed or 30
local viewAngles = {front = 0, side = math.pi / 2, rear = math.pi, threequarter = math.pi / 4}

local function writeRaw(payload)
    if log then
        local ok, err = log:write(payload, '\n')
        if not ok then failure = 'cannot write event log: ' .. tostring(err) else log:flush() end
    end
end
local function write(event)
    event.run_id = config.run_id
    writeRaw(json.encode(event))
end
local function fail(message)
    if failure then return end
    failure = tostring(message)
    Spring.Echo('ANIMLAB_CAPTURE_ERROR ' .. failure)
    if log then write({kind = 'error', frame = Spring.GetGameFrame(), message = failure}) end
end
local function unitID(index) return Spring.GetGameRulesParam('animlab_unit_' .. index) end

local function completePNG(path)
    local file = io.open(path, 'rb')
    if not file then return false end
    local head = file:read(8)
    local size = file:seek('end')
    local tail
    if size and size >= 20 then file:seek('end', -12); tail = file:read(12) end
    file:close()
    return head == '\137PNG\r\n\26\n' and tail == '\0\0\0\0IEND\174\66\96\130'
end

local function finish(status)
    if finished then return end
    finished = true
    local event = {schema_version = 1, run_id = config.run_id, kind = 'complete',
        frame = Spring.GetGameFrame(), status = status, message = failure}
    if log then write(event); log:flush(); log:close(); log = nil end
    local marker, err = io.open(directory .. '/complete.json', 'w')
    if marker then marker:write(json.encode(event), '\n'); marker:close()
    else Spring.Echo('ANIMLAB_CAPTURE_ERROR cannot write completion marker: ' .. tostring(err)) end
    if oldCamera then Spring.SetCameraState(oldCamera, 0) end
    if oldGUI ~= nil then Spring.SendCommands('hideinterface ' .. (oldGUI and '1' or '0')) end
    -- The launcher owns this dedicated engine process and terminates it after
    -- the marker. Never send quit commands to an unrelated interactive game.
end

local function camera()
    local id = unitID(subjectIndex[targetName])
    if not id or not Spring.ValidUnitID(id) then return end
    local x, y, z = Spring.GetUnitPosition(id)
    if not x then return end
    if not basis then
        local fx, _, fz = Spring.GetUnitDirection(id)
        local length = math.sqrt(fx * fx + fz * fz)
        if length < 0.001 then fx, fz, length = 0, 1, 1 end
        basis = {fx / length, fz / length}
    end
    local angle = viewAngles[config.view or 'threequarter']
    local fx, fz = basis[1], basis[2]
    local offsetX = (fx * math.cos(angle) + fz * math.sin(angle)) * scenario.camera.distance
    local offsetZ = (fz * math.cos(angle) - fx * math.sin(angle)) * scenario.camera.distance
    local targetY = y + scenario.camera.target_height
    local px, py, pz = x + offsetX, y + scenario.camera.height, z + offsetZ
    py = math.max(py, Spring.GetGroundHeight(px, pz) + 8)
    local dx, dy, dz = x - px, targetY - py, z - pz
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    cameraState = {name = 'free', mode = 4, px = px, py = py, pz = pz,
        dx = dx / length, dy = dy / length, dz = dz / length,
        -- FreeController reconstructs direction from these angles each update.
        rx = math.asin(dy / length), ry = math.atan2(dx, dz), rz = 0, fov = 40,
        gndLock = 0, gravity = 0, slide = 0, autoTilt = 0,
        vx = 0, vy = 0, vz = 0, avx = 0, avy = 0, avz = 0}
    Spring.SetCameraState(cameraState, 0)
end

local function pieceNames(id, spec)
    if pieceCache[id] then return pieceCache[id] end
    local map = Spring.GetUnitPieceMap(id) or {}
    local names, result, total = {}, {}, 0
    if spec.pieces and #spec.pieces > 0 then
        for _, name in ipairs(spec.pieces) do
            if map[name] == nil then error('requested piece is missing: ' .. spec.name .. '/' .. name) end
            names[#names + 1] = name
        end
    else for name in pairs(map) do names[#names + 1] = name end end
    table.sort(names)
    total = #names
    for index = 1, math.min(total, 256) do
        result[#result + 1] = {name = names[index], id = map[names[index]]}
    end
    pieceCache[id] = {pieces = result, total = total}
    return pieceCache[id]
end

local function collectUnit(index, spec, width, height)
    local id = unitID(index)
    if not id or not Spring.ValidUnitID(id) or (Spring.GetUnitIsDead(id) and not spec.piece_geometry) then
        return {name = spec.name, id = id or -1, alive = false, camera_subject = spec.name == targetName,
            expected_destroyed = Spring.GetGameRulesParam('animlab_destroyed_' .. index) == 1}
    end
    local x, y, z = Spring.GetUnitPosition(id)
    local sx, sy, sz = Spring.WorldToScreenCoords(x, y + scenario.camera.target_height, z)
    local record = {name = spec.name, id = id, unit_def = spec.def, alive = not Spring.GetUnitIsDead(id),
        expected_destroyed = Spring.GetGameRulesParam('animlab_destroyed_' .. index) == 1,
        camera_subject = spec.name == targetName, position = {x, y, z},
        heading = Spring.GetUnitHeading(id), direction = {Spring.GetUnitDirection(id)},
        velocity = {Spring.GetUnitVelocity(id)}, transporter = Spring.GetUnitTransporter(id),
        screen = {sx, sy}, root_in_view = sx >= 0 and sx <= width and sy >= 0 and sy <= height and sz >= 0 and sz <= 1,
        in_view = Spring.IsUnitInView and Spring.IsUnitInView(id),
        states = {upper = Spring.GetGameRulesParam('animlab_upper_' .. index),
            lower = Spring.GetGameRulesParam('animlab_lower_' .. index)},
        rules = {}, pieces = json.array()}
    local diagnosticRules = {'text_fx_test_mode', 'text_fx_test_rotation', 'text_fx_test_speed',
        'human_shield_hostage', 'human_shield_carrier',
        'melee_style', 'melee_attacker', 'melee_exchange'}
    for _, key in ipairs(diagnosticRules) do record.rules[key] = Spring.GetUnitRulesParam(id, key) end
    if spec.piece_geometry then
        local front,up,right=Spring.GetUnitVectors(id)
        record.orientation={front=front,up=up,right=right}
    end
    local selected = pieceNames(id, spec)
    record.total_pieces, record.sampled_pieces = selected.total, #selected.pieces
    local minX, minY, maxX, maxY
    for _, piece in ipairs(selected.pieces) do
        local px, py, pz = Spring.GetUnitPiecePosDir(id, piece.id)
        if px then
            local qx, qy, depth = Spring.WorldToScreenCoords(px, py, pz)
            record.pieces[#record.pieces + 1] = {name = piece.name, position_kind = 'emission_point', position = {px, py, pz},
                ground_y = Spring.GetGroundHeight(px, pz), screen = {qx, qy}, screen_depth = depth}
            if spec.piece_geometry then
                piece.geometry=piece.geometry or Spring.GetUnitPieceInfo(id,piece.id)
                record.pieces[#record.pieces].geometry=piece.geometry
                record.pieces[#record.pieces].model_matrix={Spring.GetUnitPieceMatrix(id,piece.id)}
            end
            if depth and depth >= 0 and depth <= 1 then
                minX, minY = math.min(minX or qx, qx), math.min(minY or qy, qy)
                maxX, maxY = math.max(maxX or qx, qx), math.max(maxY or qy, qy)
            end
        end
    end
    if minX then record.screen_bounds = {minX, minY, maxX, maxY} end
    return record
end

function widget:Initialize()
    started = Spring.GetTimer()
    for index, spec in ipairs(scenario.units) do subjectIndex[spec.name] = index end
    Spring.CreateDir(directory)
    Spring.CreateDir(captureDirectory)
    log = io.open(directory .. '/events.jsonl', 'w')
    if not log then fail('cannot open capture event log'); finish('failed'); return end
    widgetHandler:RegisterGlobal('AnimationLabEvent', writeRaw)
    write({kind = 'session', schema_version = 1, sim_fps = simFPS,
        capture_every_frames = capture.interval_frames, scenario = scenario.name,
        view = config.view, seed = config.seed, engine = Engine and Engine.version,
        map = Game.mapName, game = Game.gameName, fixture_kind = scenario.fixture_kind or 'gameplay',
        piece_coordinates = 'synced engine world emission points; not pivots, mesh surfaces or contacts',
        note = 'Pixels include engine render interpolation. GetUnitPiecePosDir reports synced emission points; scripts may remap axes. No images are reconstructed from telemetry.'})
end

function widget:Update()
    if finished then return end
    local elapsed = Spring.DiffTimers(Spring.GetTimer(), started)
    local frame = Spring.GetGameFrame()
    if frame == 0 and elapsed > 3 and not forcedStart then
        forcedStart = true
        Spring.SendCommands('forcestart')
    end
    if armed and frame ~= lastReady and Spring.GetGameRulesParam('animlab_status') == 0 then
        Spring.SendLuaRulesMsg('animlab_ready:' .. config.run_id)
        lastReady = frame
    end
    if armed then
        if WG and WG.MosaicArrival and WG.MosaicArrival.active then
            fail('opening cinematic became active during capture')
        else
            local ok, err = pcall(camera)
            if not ok then fail(err) end
        end
    end
    while #pending > 0 do
        local item = pending[1]
        if completePNG(item.record.image) then
            write(item.record)
            table.remove(pending, 1)
        elseif Spring.DiffTimers(Spring.GetTimer(), item.started) > 15 then
            fail('PNG was not completed within 15 seconds: ' .. item.record.image)
            break
        else break end
    end
    local status = Spring.GetGameRulesParam('animlab_status')
    if status == 3 then fail(Spring.GetGameRulesParam('animlab_error') or 'scenario controller failed') end
    if failure then finish('failed')
    elseif status == 2 and #pending == 0 then finish('complete') end
    if config.single_step_capture and armed and not finished and status == 1
        and (Spring.GetGameRulesParam('animlab_phase') or 0)>0 then
        local _,_,paused = Spring.GetGameSpeed()
        if not paused then
            Spring.SendCommands('pause 1')
        elseif drawnFrame == frame and steppedFrame ~= frame and #pending == 0 then
            -- Advance the isolated host by exactly one real simulation frame.
            -- Wait for the completed PNG before requesting another frame.
            steppedFrame = frame
            Spring.SendCommands('singlestep')
        end
    end
end

function widget:DrawScreenPost()
    if finished or failure or not log or #pending >= 8 then return end
    if not armed then
        -- Mosaic suppresses this callback for ordinary widgets during its
        -- opening cinematic. Readiness must prove that actual draws are now
        -- reaching us; initialize order and a fixed sleep are not sufficient.
        if Spring.GetGameFrame() < 1 or (WG and WG.MosaicArrival and WG.MosaicArrival.active) then
            readyDraws = 0
            return
        end
        readyDraws = readyDraws + 1
        if readyDraws < 2 then return end
        oldCamera = Spring.GetCameraState()
        oldGUI = Spring.IsGUIHidden and Spring.IsGUIHidden()
        armed = true
        Spring.SendCommands('hideinterface 1')
        Spring.SendLuaRulesMsg('animlab_ready:' .. config.run_id)
        write({kind = 'observer_ready', frame = Spring.GetGameFrame()})
        return
    end
    if Spring.GetGameRulesParam('animlab_status') ~= 1 then return end
    local phaseIndex = Spring.GetGameRulesParam('animlab_phase') or 0
    if phaseIndex == 0 then return end
    local frame = Spring.GetGameFrame()
    drawnFrame = frame
    local phaseStart = Spring.GetGameRulesParam('animlab_phase_start')
    if lastFrame == frame then return end
    if lastFrame and lastPhase == phaseIndex and frame - lastFrame < capture.interval_frames then return end
    local width, height, offsetX, offsetY = Spring.GetViewGeometry()
    offsetX, offsetY = offsetX or 0, offsetY or 0
    if width ~= capture.width or height ~= capture.height then
        fail(string.format('viewport is %dx%d; expected %dx%d', width, height, capture.width, capture.height)); return
    end
    local ok, err = pcall(function()
        local phase = scenario.phases[phaseIndex]
        local record = {kind = 'sample', frame = frame, sim_time = frame / simFPS,
            draw_frame = Spring.GetDrawFrame and Spring.GetDrawFrame(),
            frame_time_offset = Spring.GetFrameTimeOffset and Spring.GetFrameTimeOffset(),
            wall_seconds = Spring.DiffTimers(Spring.GetTimer(), started),
            phase = phase.name, phase_index = phaseIndex, phase_frame = frame - phaseStart,
            view = config.view, image = string.format('%s/frame_%09d.png', captureDirectory, frame),
            capture_ok = true, width = width, height = height, viewport_offset = {offsetX, offsetY},
            camera = Spring.GetCameraState(), state_frame = Spring.GetGameRulesParam('animlab_state_frame'),
            units = json.array()}
        for index, spec in ipairs(scenario.units) do
            record.units[#record.units + 1] = collectUnit(index, spec, width, height)
        end
        -- gl.SaveImage reads this framebuffer, unlike deferred /screenshot.
        local saved = gl.SaveImage(offsetX, offsetY, width, height, record.image, {alpha = false, yflip = true})
        if saved ~= true then error('gl.SaveImage failed: ' .. record.image) end
        pending[#pending + 1] = {record = record, started = Spring.GetTimer()}
        lastFrame, lastPhase = frame, phaseIndex
    end)
    if not ok then fail(err) end
end

function widget:Shutdown()
    widgetHandler:DeregisterGlobal('AnimationLabEvent')
    if not finished then fail('capture widget shut down before scenario completion'); finish('failed') end
end
