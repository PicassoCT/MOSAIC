-- Run from repository root: lua tests/rain_capture_lifecycle.lua
local make = dofile("luaui/widgets_mosaic/include/rain_capture.lua")
local realIO = io
local function scenario(options)
    options = options or {}
    local s = {paused = options.paused or false, frame = 14400, rain = 0.63,
        width = 1280, shots = {}, commands = {}, files = {}, restores = 0}
    Game = {mapName = "capture test"}
    Spring = {
        Echo = function() end,
        GetGameSpeed = function() return 1, 1, s.paused end,
        GetGameFrame = function() return s.frame end,
        GetPlayerList = function() return options.multiplayer and {0, 1} or {0} end,
        GetPlayerInfo = function() return "player", true, false end,
        GetMyPlayerID = function() return 0 end,
        GetCameraState = function() return {name = "ta", px = 200, py = 500, pz = 300} end,
        SetCameraState = function(camera, transition)
            assert(camera.px == 200 and transition == 0)
        end,
        GetViewGeometry = function() return s.width, 720, 10, 20 end,
        CreateDir = function() end,
        SendCommands = function(command)
            s.commands[#s.commands + 1] = command
            if not options.noAck then s.paused = command == "pause 1" end
        end,
    }
    io = {open = function(path, mode)
        if options.noWrite then return nil end
        if mode == "r" and not s.files[path] then return nil end
        s.files[path] = s.files[path] or ""
        return {
            write = function(_, ...)
                local values = {...}
                for i, value in ipairs(values) do values[i] = tostring(value) end
                s.files[path] = s.files[path] .. table.concat(values)
            end,
            flush = function() end, close = function() end,
        }
    end}
    local c
    gl = {SaveImage = function(x, y, w, h, path, opts)
        assert(x == 10 and y == 20 and w == 1280 and h == 720)
        assert(opts.yflip and not opts.alpha)
        if options.saveThrows then error("disk full") end
        if options.saveFails then return false end
        s.shots[#s.shots + 1] = {rain = s.rain, phase = c.shaderTime(), path = path}
        return true
    end}
    c = make({
        ready = function() return true end,
        save = function() return {rain = s.rain} end,
        restore = function(state) s.rain = state.rain; s.restores = s.restores + 1 end,
        prepare = function() s.prepared = true end,
        setRain = function(rain) s.rain = rain end,
        metadata = function() return "lighting\tfixed\n" end,
    })
    local function tick(dt) c.update(dt or 0.25); c.draw() end
    return s, c, tick
end

for _, samples in ipairs({1, 3}) do
    local s, c, tick = scenario()
    assert(c.command("rainsnap 0.25 " .. samples))
    assert(c.active() and s.paused)
    for i = 1, 100 do tick() end
    assert(not c.active() and not s.paused and s.restores == 1)
    assert(s.rain == 0.63 and #s.shots == 11 * samples)
    for i, shot in ipairs(s.shots) do
        local level, sample = math.floor((i - 1) / samples), (i - 1) % samples
        assert(shot.rain == level / 10 and shot.phase == 30 + sample * 0.25)
        assert(shot.path:match(string.format("rain_%03d_frame_%02d.png$", level * 10, sample + 1)))
    end
    for _, manifest in pairs(s.files) do
        assert(manifest:match("game_frame\t14400") and manifest:match("result\tcomplete"))
    end
end

do
    local s, c, tick = scenario({paused = true})
    c.command("rainsnap")
    tick(); c.command("rainsnap cancel")
    assert(s.paused and #s.commands == 0 and s.restores == 1 and s.rain == 0.63)
end
for _, failure in ipairs({"saveFails", "saveThrows", "noAck"}) do
    local s, c, tick = scenario({[failure] = true})
    c.command("rainsnap 0.25")
    for i = 1, 30 do tick() end
    assert(not c.active() and #s.shots == 0 and s.restores == 1)
    assert(s.commands[#s.commands] == "pause 0")
end
do
    local s, c, tick = scenario()
    c.command("rainsnap"); tick(); s.width = 1920; tick()
    assert(not c.active() and s.restores == 1 and #s.shots == 0)
end
do
    local s, c, tick = scenario()
    c.command("rainsnap"); tick(); s.paused = false; s.frame = s.frame + 1; tick()
    assert(not c.active() and s.restores == 1 and #s.shots == 0)
end
do
    local s, c = scenario({noAck = true})
    c.command("rainsnap"); c.command("rainsnap cancel")
    assert(s.commands[1] == "pause 1" and s.commands[2] == "pause 0")
end
do
    local s, c, tick = scenario()
    c.command("rainsnap"); tick(); c.shutdown()
    assert(not c.active() and not s.paused and s.restores == 1)
end
for _, options in ipairs({{multiplayer = true}, {noWrite = true}}) do
    local s, c = scenario(options)
    c.command("rainsnap")
    assert(not c.active() and #s.commands == 0 and s.restores == 0)
end
do
    local s, c = scenario()
    assert(not c.command("rainsnapshot"))
    for _, command in ipairs({"rainsnap help", "rainsnap 0", "rainsnap 2 1.5", "rainsnap 2 11"}) do
        assert(c.command(command) and not c.active())
    end
end
io = realIO
print("PASS: capture phases/intensities, restoration, cancellation, pause timeout, disk errors, resize, resume, multiplayer")
