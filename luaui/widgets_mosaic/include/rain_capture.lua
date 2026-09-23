-- Local visual regression capture. No synced weather changes or shader changes.
-- The caller supplies the rain state; the engine supplies camera/pause/file APIs.
return function(api)
    local capture, serial = nil, 0
    local controller = {}
    local function elapsed(timer)
        return Spring.DiffTimers(Spring.GetTimer(), timer)
    end
    local function screenshotFiles()
        return VFS.DirList("screenshots/", "*.png", VFS.RAW_ONLY) or {}
    end
    local function completePNG(path)
        local file = io.open(path, "rb")
        if not file then return end
        local data = file:read("*a")
        file:close()
        -- Engine screenshot writes are asynchronous. Wait for the PNG end chunk.
        if data and data:sub(1, 8) == "\137PNG\r\n\26\n" and
           data:sub(-12) == "\0\0\0\0IEND\174\66\96\130" then return data end
    end

    local function echo(message) Spring.Echo("Rain capture: " .. message) end
    local function paused()
        local _, _, value = Spring.GetGameSpeed()
        return value
    end
    local function finish(reason)
        if not capture then return end
        local c = capture
        capture = nil
        api.restore(c.saved)
        if c.guiHidden ~= nil then
            Spring.SendCommands("hideinterface " .. (c.guiHidden and "1" or "0"))
        end
        Spring.SetCameraState(c.camera, 0)
        if c.manifest then
            c.manifest:write("result\t", reason, "\n")
            c.manifest:close()
        end
        -- Also undo a pause request cancelled before its acknowledgement.
        if c.ownsPause then Spring.SendCommands("pause 0") end
        echo(reason .. "; " .. c.count .. " PNGs saved in " .. c.directory)
    end

    function controller.command(command)
        if not command:match("^rainsnap%s*$") and not command:match("^rainsnap%s+") then
            return false
        end
        local args = {}
        for word in command:gmatch("%S+") do args[#args + 1] = word end
        if args[2] == "cancel" then
            finish("cancelled")
            return true
        end
        if args[2] == "status" then
            echo(capture and string.format("%d saved; rain %.1f; %s; output %s", capture.count,
                capture.level / 10, capture.pending and "waiting for engine PNG" or
                (capture.waiting and "waiting for pause" or "settling/rendering"), capture.directory)
                or "idle")
            return true
        end
        local delay = tonumber(args[2] or "2")
        local frames = tonumber(args[3] or "1")
        if not delay or delay < 0.25 or delay > 30 or not frames or
           frames < 1 or frames > 10 or frames ~= math.floor(frames) or #args > 3 then
            echo("/rainsnap [settle seconds: 0.25-30] [frames per level: 1-10]; /rainsnap cancel")
            return true
        end
        if capture then echo("already running; /rainsnap cancel to stop"); return true end
        if not api.ready() then echo("rain shader is unavailable"); return true end

        local wasPaused = paused()
        if not wasPaused then
            for _, id in ipairs(Spring.GetPlayerList()) do
                local _, active, spectator = Spring.GetPlayerInfo(id, false)
                if active and not spectator and id ~= Spring.GetMyPlayerID() then
                    echo("pause the multiplayer game before starting this capture")
                    return true
                end
            end
        end
        -- A manifest is also the writable-directory probe. Never overwrite a run.
        local directory, manifest
        repeat
            serial = serial + 1
            directory = string.format("screenshots/rain_%s_f%d_%02d/",
                os.date("%Y%m%d_%H%M%S"), Spring.GetGameFrame(), serial)
            local existing = io.open(directory .. "manifest.txt", "r")
            if existing then existing:close() else break end
        until false
        Spring.CreateDir("screenshots")
        Spring.CreateDir(directory)
        manifest = io.open(directory .. "manifest.txt", "w")
        if not manifest then echo("cannot write " .. directory); return true end
        capture = {
            directory = directory, manifest = manifest, saved = api.save(),
            guiHidden = Spring.IsGUIHidden and Spring.IsGUIHidden(),
            camera = Spring.GetCameraState(), ownsPause = not wasPaused,
            delay = delay, frames = frames, level = 0, sample = 1, count = 0,
            timer = Spring.GetTimer(), draws = 0, waiting = true,
            width = select(1, Spring.GetViewGeometry()),
            height = select(2, Spring.GetViewGeometry()),
        }
        manifest:write("map\t", tostring(Game.mapName), "\nsettle_seconds\t", delay,
            "\nframes_per_level\t", frames,
            "\nshader_phase_base\t30\nshader_phase_step\t0.25\n")
        for key, value in pairs(capture.camera) do
            manifest:write("camera.", tostring(key), "\t", tostring(value), "\n")
        end
        manifest:write("width\t", capture.width, "\nheight\t", capture.height, "\n")
        manifest:flush()
        echo("capturing dry + 0.1-1.0 at this camera/time; /rainsnap cancel to stop")
        if capture.guiHidden ~= nil then Spring.SendCommands("hideinterface 1") end
        if not wasPaused then Spring.SendCommands("pause 1") end
        return true
    end

    function controller.update(dt)
        if not capture then return false end
        local c = capture
        c.elapsed = elapsed(c.timer)
        Spring.SetCameraState(c.camera, 0)
        if c.waiting then
            if not paused() then
                if c.elapsed > 5 then finish("aborted: pause was not acknowledged") end
                return true
            end
            c.waiting, c.elapsed, c.timer = false, 0, Spring.GetTimer()
            c.gameFrame = Spring.GetGameFrame()
            api.prepare()
            c.manifest:write("game_frame\t", c.gameFrame, "\n", api.metadata(),
                "\nfile\train\tshader_time\tgame_frame\tengine_file\n")
            c.manifest:flush()
        elseif not paused() or Spring.GetGameFrame() ~= c.gameFrame then
            finish("aborted: simulation resumed")
            return true
        end
        local width, height = Spring.GetViewGeometry()
        if width ~= c.width or height ~= c.height then
            finish("aborted: viewport resized")
            return true
        end
        api.setRain(c.level / 10)
        if c.pending then
            for _, path in ipairs(screenshotFiles()) do
                if not c.pending.before[path] then
                    local data = completePNG(path)
                    if data then
                        local destination = c.directory .. c.pending.filename
                        local file, err = io.open(destination, "wb")
                        if not file then finish("aborted: " .. tostring(err)); return true end
                        local ok, writeError = file:write(data)
                        local closed, closeError = file:close()
                        if not ok or not closed then
                            finish("aborted: " .. tostring(writeError or closeError)); return true
                        end
                        if not completePNG(destination) then
                            finish("aborted: saved PNG verification failed"); return true
                        end
                        c.count = c.count + 1
                        c.manifest:write(c.pending.filename, "\t", string.format("%.1f", c.level / 10),
                            "\t", controller.shaderTime(), "\t", c.gameFrame, "\t", path, "\n")
                        c.manifest:flush()
                        echo(string.format("saved %d/%d: %s", c.count, 11 * c.frames, destination))
                        c.pending = nil
                        c.sample = c.sample + 1
                        if c.sample > c.frames then c.sample, c.level = 1, c.level + 1 end
                        if c.level > 10 then finish("complete"); return true end
                        c.timer, c.draws, c.elapsed = Spring.GetTimer(), 0, 0
                        api.setRain(c.level / 10)
                        return true
                    end
                end
            end
            if elapsed(c.pending.timer) > 15 then
                finish("aborted: engine screenshot did not produce a complete PNG within 15 seconds")
            end
        elseif c.elapsed > c.delay + 10 then
            finish("aborted: capture render callback did not run; check infolog.txt")
        end
        return true
    end

    function controller.shaderTime()
        if capture and not capture.waiting then
            return 30 + (capture.sample - 1) * 0.25
        end
    end

    function controller.draw()
        if not capture or capture.waiting or capture.pending then return end
        local c = capture
        if not paused() or Spring.GetGameFrame() ~= c.gameFrame then
            finish("aborted: simulation resumed"); return
        end
        c.draws = c.draws + 1
        if c.elapsed < c.delay or c.draws < 2 then return end
        local width, height, x, y = Spring.GetViewGeometry()
        if width ~= c.width or height ~= c.height then
            finish("aborted: viewport resized"); return
        end
        local filename = string.format("rain_%03d_frame_%02d.png", c.level * 10, c.sample)
        local before = {}
        for _, path in ipairs(screenshotFiles()) do before[path] = true end
        c.pending = {before = before, filename = filename, timer = Spring.GetTimer()}
        -- Same engine command as F12; copies only a fully written PNG on a later Update.
        -- Keep camera, rain and phase unchanged until the asynchronous save completes.
        Spring.SendCommands("screenshot png")
    end

    function controller.active() return capture ~= nil end
    function controller.shutdown() finish("cancelled: widget shutdown") end
    return controller
end

