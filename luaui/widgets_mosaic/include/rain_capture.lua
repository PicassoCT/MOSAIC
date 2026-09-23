-- Local visual regression capture. No synced weather changes or shader changes.
-- The caller supplies the rain state; the engine supplies camera/pause/file APIs.
return function(api)
    local capture, serial = nil, 0
    local controller = {}

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
        local delay = tonumber(args[2] or "2")
        local frames = tonumber(args[3] or "1")
        if not delay or delay < 0.25 or delay > 30 or not frames or
           frames < 1 or frames > 10 or frames ~= math.floor(frames) or #args > 3 then
            echo("/rainsnap [settle seconds: 0.25-30] [frames per level: 1-10]; /rainsnap cancel")
            return true
        end
        if capture then echo("already running; /rainsnap cancel to stop"); return true end
        if not api.ready() then echo("rain shader is unavailable"); return true end
        if not gl.SaveImage then echo("gl.SaveImage is unavailable"); return true end
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
            directory = string.format("Screenshots/rain_%s_f%d_%02d/",
                os.date("%Y%m%d_%H%M%S"), Spring.GetGameFrame(), serial)
            local existing = io.open(directory .. "manifest.txt", "r")
            if existing then existing:close() else break end
        until false
        Spring.CreateDir(directory)
        manifest = io.open(directory .. "manifest.txt", "w")
        if not manifest then echo("cannot write " .. directory); return true end
        capture = {
            directory = directory, manifest = manifest, saved = api.save(),
            camera = Spring.GetCameraState(), ownsPause = not wasPaused,
            delay = delay, frames = frames, level = 0, sample = 1, count = 0,
            elapsed = 0, draws = 0, waiting = true,
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
        if not wasPaused then Spring.SendCommands("pause 1") end
        return true
    end

    function controller.update(dt)
        if not capture then return false end
        local c = capture
        c.elapsed = c.elapsed + dt
        Spring.SetCameraState(c.camera, 0)
        if c.waiting then
            if not paused() then
                if c.elapsed > 5 then finish("aborted: pause was not acknowledged") end
                return true
            end
            c.waiting, c.elapsed = false, 0
            c.gameFrame = Spring.GetGameFrame()
            api.prepare()
            c.manifest:write("game_frame\t", c.gameFrame, "\n", api.metadata(),
                "\nfile\train\tshader_time\tgame_frame\n")
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
        return true
    end

    function controller.shaderTime()
        if capture and not capture.waiting then
            return 30 + (capture.sample - 1) * 0.25
        end
    end

    function controller.draw()
        if not capture or capture.waiting then return end
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
        local ok, saved = pcall(gl.SaveImage, x, y, width, height,
            c.directory .. filename, {alpha = false, yflip = true})
        if not ok or not saved then finish("aborted: screenshot write failed"); return end
        c.count = c.count + 1
        c.manifest:write(filename, "\t", string.format("%.1f", c.level / 10), "\t",
            controller.shaderTime(), "\t", c.gameFrame, "\n")
        c.manifest:flush()
        c.sample = c.sample + 1
        if c.sample > c.frames then c.sample, c.level = 1, c.level + 1 end
        if c.level > 10 then finish("complete"); return end
        c.elapsed, c.draws = 0, 0
        -- The next intensity is applied in Update, before the next world render.
    end

    function controller.active() return capture ~= nil end
    function controller.shutdown() finish("cancelled: widget shutdown") end
    return controller
end
