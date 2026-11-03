-- Lua 5.1+: exercise visibility, transport, variant changes and GL ownership.
local catalog = dofile("scripts/lib_truck_parade_payloads.lua")
local config = dofile("luarules/configs/parade_hologram_decorations.lua")
local figures = dofile("luarules/configs/parade_hologram_figures.lua")
local function themeFor(key)
    local placements = {}
    for _, source in ipairs({config, figures}) do
        for _, placement in ipairs(source.themes[key] or {}) do
            placements[#placements + 1] = placement
        end
    end
    return placements
end
local function loadEnv(path, env)
    setmetatable(env, {__index = _G})
    if setfenv then
        local chunk = assert(loadfile(path)); setfenv(chunk, env); return chunk()
    end
    return assert(loadfile(path, "t", env))()
end
local function check(name, test) test(); print("PASS: " .. name) end

local function fixture(options)
    options = options or {}
    local f = {alive = {[5] = true, [20] = true}, defs = {[5] = 7, [20] = 1},
        parents = {[5] = 20}, variants = {[5] = 1}, positions = {[20] = {0, 0, 0}},
        camera = {0, 0, 300}, los = true, inView = true, fullView = false,
        noDraw = false, cloaked = false, seconds = 10, center = 0,
        listCount = 0, lists = {}, draws = {}, transforms = {}, uniforms = {},
        deletedLists = {}, deletedShaders = {}, allUnitReads = 0, removed = false,
        matrixDepth = 0, attribDepth = 0, activeShader = 99, blend = "original",
        depthMask = true, depthTest = false, culling = true, errors = {}}
    local figureData = figures
    if options.invalidTiming then
        figureData = {glyphs = {}, themes = figures.themes}
        for name, glyph in pairs(figures.glyphs) do figureData.glyphs[name] = glyph end
        local name, original = next(figureData.glyphs)
        local invalid = {}; for key, value in pairs(original) do invalid[key] = value end
        invalid.frameDurations = options.invalidTiming
        figureData.glyphs[name] = invalid
    end
    local names = {}
    for _, source in ipairs({config, figureData}) do
        for name, glyph in pairs(source.glyphs) do names[glyph] = name end
    end
    local function scope(fn, ...)
        f.matrixDepth = f.matrixDepth + 1
        local ok, reason = pcall(fn, ...)
        f.matrixDepth = f.matrixDepth - 1
        if not ok then error(reason) end
    end
    local env = {gadget = {}, Game = {gameSpeed = 30}, Spring = {}, gl = {},
        GL = {QUADS = 7, LEQUAL = 515, SRC_ALPHA = 770, ONE = 1},
        UnitDefNames = {truckpayloadparade = {id = 7}},
        VFS = {Include = function(path)
            if path == "scripts/lib_truck_parade_payloads.lua" then return catalog end
            if path == "luarules/configs/parade_hologram_figures.lua" then return figureData end
            assert(path == "luarules/configs/parade_hologram_decorations.lua"); return config
        end}, gadgetHandler = {IsSyncedCode = function() return options.synced end,
            RemoveGadget = function() f.removed = true end}}
    local S, gl = env.Spring, env.gl
    S.ValidUnitID = function(id) return f.alive[id] ~= nil end
    S.GetUnitIsDead = function(id) return not f.alive[id] end
    S.GetUnitDefID = function(id) return f.defs[id] end
    S.GetAllUnits = function() f.allUnitReads = f.allUnitReads + 1; return {5, 20} end
    S.GetUnitTransporter = function(id) return f.parents[id] end
    S.GetUnitRulesParam = function(id, key)
        assert(key == "city_parade_variant"); return f.variants[id]
    end
    S.GetUnitPieceMap = function(id) assert(f.defs[id] == 7); return {center = f.center} end
    S.GetUnitPosition = function(id)
        local p = f.positions[id]; if p then return p[1], p[2], p[3] end
    end
    S.GetCameraPosition = function() return f.camera[1], f.camera[2], f.camera[3] end
    S.GetSpectatingState = function() return f.fullView, f.fullView end
    S.GetMyAllyTeamID = function() return 2 end
    S.GetUnitLosState = function(id, ally) assert(ally == 2); return {los = f.los, radar = true} end
    S.GetUnitNoDraw = function() return f.noDraw end
    S.GetUnitIsCloaked = function() return f.cloaked end
    S.IsSphereInView = function() return f.inView end
    S.GetGameSeconds = function() return f.seconds end
    S.GetFrameTimeOffset = function() return 0 end
    S.Echo = function(message) f.errors[#f.errors + 1] = message end
    gl.CreateShader = function(spec)
        f.shaderSpec = spec; if options.shaderFailure then return nil end; return 1
    end
    gl.GetShaderLog = function() return "test compiler failure" end
    gl.GetUniformLocation = function(_, name) return name end
    gl.CreateList = function(fn, glyph, frame)
        if options.listFailure then return 0 end
        f.listCount = f.listCount + 1
        local id = f.listCount
        local frameIndex
        for index, candidate in ipairs(glyph.frames) do
            if candidate == frame then frameIndex = index end
        end
        f.lists[id] = {glyph = names[glyph], frame = frameIndex, vertices = 0}
        f.compiling = id; fn(glyph, frame); f.compiling = nil
        return id
    end
    gl.BeginEnd = function(mode, fn) assert(mode == env.GL.QUADS); fn() end
    gl.Color = function(r, g, b, a)
        assert(r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1)
        assert(a >= 0 and a <= 1)
    end
    gl.Vertex = function(x, y, z)
        assert(type(x) == "number" and type(y) == "number" and z == 0)
        f.lists[f.compiling].vertices = f.lists[f.compiling].vertices + 1
    end
    gl.DeleteList = function(id)
        assert(not f.deletedLists[id], "display list deleted twice"); f.deletedLists[id] = true
    end
    gl.DeleteShader = function(id)
        assert(not f.deletedShaders[id], "shader deleted twice"); f.deletedShaders[id] = true
    end
    gl.Uniform = function(name, value) f.uniforms[name] = value end
    gl.UnitMultMatrix = function(id)
        f.unit = id; f.transforms[#f.transforms + 1] = {"unit", id}
    end
    gl.UnitPieceMultMatrix = function(id, piece)
        assert(id == f.unit and piece == 0, "center piece zero is valid")
        f.transforms[#f.transforms + 1] = {"piece", id, piece}
    end
    gl.Translate = function(x, y, z) f.anchor = {x, y, z} end
    gl.CallList = function(id)
        if f.throwDraw then error("injected draw failure") end
        assert(f.activeShader == 1 and f.matrixDepth == 2)
        assert(f.depthMask == false and f.depthTest == env.GL.LEQUAL and f.culling == false)
        assert(f.blend == "770:1")
        f.draws[#f.draws + 1] = {unit = f.unit, glyph = f.lists[id].glyph,
            frame = f.lists[id].frame, opacity = f.uniforms.opacity,
            pixelSize = f.uniforms.pixelSize, anchor = f.anchor}
    end
    gl.PushPopMatrix = scope
    gl.ActiveShader = function(shaderID, fn, ...)
        local previous = f.activeShader; f.activeShader = shaderID
        local ok, reason = pcall(fn, ...)
        f.activeShader = previous
        if not ok then error(reason) end
    end
    gl.PushAttrib = function()
        assert(f.attribDepth == 0)
        f.attribDepth = 1
        f.saved = {f.blend, f.depthMask, f.depthTest, f.culling}
    end
    gl.PopAttrib = function()
        assert(f.attribDepth == 1); f.attribDepth = 0
        f.blend, f.depthMask, f.depthTest, f.culling = f.saved[1], f.saved[2], f.saved[3], f.saved[4]
    end
    gl.DepthTest = function(value) f.depthTest = value end
    gl.DepthMask = function(value) f.depthMask = value end
    gl.Culling = function(value) f.culling = value end
    gl.Blending = function(src, dst) f.blend = src .. ":" .. dst end
    f.result = loadEnv("luarules/gadgets/gfx_parade_holograms.lua", env)
    f.env, f.gadget = env, env.gadget
    if not options.synced then f.gadget:Initialize() end
    return f
end

check("all selectable floats have bounded, valid pixel decorations", function()
    for _, variant in ipairs(catalog.variants) do
        local theme = assert(config.themes[variant.hologramTheme or variant.key], variant.key)
        assert(#theme >= 1 and #theme <= 6)
        for _, decoration in ipairs(theme) do
            local glyph = assert(config.glyphs[decoration.glyph])
            assert(decoration.pixelSize > 0 and decoration.pixelSize * #glyph.frames[1] <= 6)
            for _, coordinate in ipairs({"x", "y", "z"}) do
                assert(type(decoration[coordinate]) == "number")
            end
        end
    end
    for name, glyph in pairs(config.glyphs) do
        local width, height = #glyph.frames[1][1], #glyph.frames[1]
        assert(width <= 12 and height <= 12 and #glyph.frames > 0)
        for _, frame in ipairs(glyph.frames) do
            assert(#frame == height, name)
            local lit = 0
            for _, row in ipairs(frame) do
                assert(#row == width, name)
                for symbol in row:gmatch(".") do
                    if symbol ~= "." then assert(glyph.palette[symbol], name); lit = lit + 1 end
                end
            end
            assert(lit > 0 and lit <= 100, name)
        end
    end
end)

check("outlined audience is sparse, covers all four roles and preserves the ornaments", function()
    local categories = {}
    for name, glyph in pairs(figures.glyphs) do
        assert(not config.glyphs[name], "figure must not replace an ornament")
        categories[glyph.category] = true
        local width, height = #glyph.frames[1][1], #glyph.frames[1]
        assert(width <= 17 and height <= 21)
        assert(#glyph.frameDurations == #glyph.frames and #glyph.frames >= 3)
        local total = 0
        for index, frame in ipairs(glyph.frames) do
            assert(#frame == height)
            local lit = 0
            for _, row in ipairs(frame) do
                assert(#row == width)
                for symbol in row:gmatch(".") do
                    if symbol ~= "." then assert(glyph.palette[symbol]); lit = lit + 1 end
                end
            end
            assert(lit > 0 and lit <= 110 and lit < width * height * 0.60,
                "outlined figure should have a hollow interior: " .. name)
            local duration = glyph.frameDurations[index]
            assert(type(duration) == "number" and duration > 0 and duration < math.huge)
            total = total + duration
        end
        assert(total >= 3 and total <= 7, "gentle blink/gesture cycle: " .. name)
    end
    for _, category in ipairs({"ghost", "memorial", "remote", "ai"}) do assert(categories[category]) end
    for _, variant in ipairs(catalog.variants) do
        local key = variant.hologramTheme or variant.key
        local added, all = assert(figures.themes[key]), themeFor(key)
        assert(#added == 4 and #all == 10 and #config.themes[key] == 6)
        for i = 1, 6 do assert(all[i] == config.themes[key][i]) end
        for _, placement in ipairs(added) do
            local glyph = assert(figures.glyphs[placement.glyph])
            local height = placement.pixelSize * #glyph.frames[1]
            assert(height >= 5 and height <= 8)
            assert((placement.opacity or 1) >= 0 and (placement.opacity or 1) <= 1)
            assert((placement.bobAmplitude or 0.24) >= 0 and (placement.bobAmplitude or 0.24) <= 0.6)
            assert((placement.swayAmplitude or 0) >= 0 and (placement.swayAmplitude or 0) <= 0.4)
        end
    end
end)

check("renderer is entirely unsynced and has no simulation side effects", function()
    local f = fixture({synced = true})
    assert(f.result == false and f.listCount == 0 and f.allUnitReads == 0)
end)

check("attached decorations inherit unit and center transforms without rebuilding pixels", function()
    local f = fixture(); local lists = f.listCount
    f.gadget:DrawWorld(); f.gadget:DrawWorld()
    assert(#f.draws == 20 and f.listCount == lists and f.allUnitReads == 1)
    assert(f.transforms[1][1] == "unit" and f.transforms[2][1] == "piece")
    assert(f.draws[1].unit == 5 and f.draws[1].glyph == config.themes.forest_dreamer[1].glyph)
    assert(f.matrixDepth == 0 and f.attribDepth == 0 and f.activeShader == 99)
    assert(f.blend == "original" and f.depthMask == true and f.depthTest == false)
end)

check("live payload selection changes the motif without using stale carrier identity", function()
    local f = fixture()
    for index, variant in ipairs(catalog.variants) do
        f.variants[5] = index; f.draws = {}; f.gadget:DrawWorld()
        local expected = themeFor(variant.key)
        assert(#f.draws == #expected)
        for n, draw in ipairs(f.draws) do assert(draw.glyph == expected[n].glyph) end
    end
    for _, invalid in ipairs({0, 999}) do
        f.variants[5] = invalid; f.draws = {}; f.gadget:DrawWorld(); assert(#f.draws == 0)
    end
end)

check("no symbols on detached, dead, hidden, cloaked, distant or offscreen carriers", function()
    local cases = {
        function(f) f.parents[5] = nil end,
        function(f) f.alive[20] = false end,
        function(f) f.alive[5] = false end,
        function(f) f.positions[20] = nil end,
        function(f) f.los = false end,
        function(f) f.noDraw = true end,
        function(f) f.cloaked = true end,
        function(f) f.inView = false end,
        function(f) f.camera = {0, 0, 1500} end,
    }
    for _, prepare in ipairs(cases) do
        local f = fixture(); prepare(f); f.gadget:DrawWorld()
        assert(#f.draws == 0 and f.attribDepth == 0)
    end
    local f = fixture(); f.los = false; f.fullView = true; f.gadget:DrawWorld()
    assert(#f.draws == 10, "full-view spectator should see attached float")
    f.fullView = false; f.draws = {}; f.gadget:DrawWorld()
    assert(#f.draws == 0, "losing full-view must apply immediately")
end)

check("decorations fade with distance and discover later units through events", function()
    local f = fixture(); f.camera = {0, 0, 900}; f.gadget:DrawWorld()
    local alpha = f.draws[1].opacity
    f.draws = {}; f.camera = {0, 0, 1200}; f.gadget:DrawWorld()
    assert(math.abs(f.draws[1].opacity / alpha - 0.5) < 0.000001)
    f.gadget:UnitDestroyed(5); f.draws = {}; f.gadget:DrawWorld(); assert(#f.draws == 0)
    f.gadget:UnitEnteredLos(5, 0, 2, 7); f.gadget:DrawWorld(); assert(#f.draws == 10)
    assert(f.allUnitReads == 1)
end)

check("dense previews draw a bounded nearest subset and release GPU resources", function()
    local f = fixture(); f.camera = {0, 0, 0}
    for id = 30, 49 do
        local parent = id + 100
        f.alive[id], f.alive[parent], f.defs[id] = true, true, 7
        f.parents[id], f.variants[id], f.positions[parent] = parent, 1, {id, 0, 0}
        f.gadget:UnitCreated(id, 7)
    end
    f.gadget:DrawWorld(); assert(#f.draws == 12 * 10)
    assert(f.draws[1].unit == 5 and f.draws[#f.draws].unit == 40)
    f.gadget:Shutdown(); f.gadget:Shutdown()
    local deleted = 0; for _ in pairs(f.deletedLists) do deleted = deleted + 1 end
    assert(deleted == f.listCount and f.deletedShaders[1])
end)

check("shader failure and draw failure leave no leaked GL state or resources", function()
    local f = fixture({shaderFailure = true})
    assert(f.removed and f.listCount == 0 and #f.errors == 1)
    f = fixture({listFailure = true})
    assert(f.removed and f.deletedShaders[1] and f.listCount == 0)
    f = fixture(); f.throwDraw = true; f.gadget:DrawWorld()
    assert(f.removed and f.matrixDepth == 0 and f.attribDepth == 0 and f.activeShader == 99)
    assert(f.blend == "original" and f.depthMask == true and f.depthTest == false)
    assert(f.deletedShaders[1] and #f.errors == 1)
end)

check("short blink frames use their authored duration while old animation stays unchanged", function()
    local placement = figures.themes.forest_dreamer[1]
    local glyph = figures.glyphs[placement.glyph]
    local total = 0; for _, duration in ipairs(glyph.frameDurations) do total = total + duration end
    local phase = (placement.phase or 7 * 0.37) + 5 * 0.173
    local f = fixture(); local lists = f.listCount
    local function at(time, expected)
        f.seconds = total * 10 - phase + time
        f.draws = {}; f.gadget:DrawWorld()
        local draw = f.draws[7]
        assert(draw.glyph == placement.glyph and draw.frame == expected)
        local clock = f.seconds + phase
        local shimmer = 0.91 + 0.06 * math.sin(clock * 4.1)
        assert(math.abs(draw.opacity - shimmer * (placement.opacity or 1)) < 0.000001)
        assert(math.abs(draw.anchor[2] - placement.y) <= (placement.bobAmplitude or 0.24) + 0.000001)
        assert(math.abs(draw.anchor[1] - placement.x) <= (placement.swayAmplitude or 0) + 0.000001)
        local old = config.themes.forest_dreamer[1]
        local oldClock = f.seconds + (old.phase or 0.37) + 5 * 0.173
        local oldGlyph = config.glyphs[old.glyph]
        assert(f.draws[1].frame == math.floor(oldClock / oldGlyph.frameSeconds) % #oldGlyph.frames + 1)
    end
    at(0.001, 1)
    local boundary = 0
    for index = 1, #glyph.frameDurations - 1 do
        boundary = boundary + glyph.frameDurations[index]
        at(boundary - 0.00001, index)
        at(boundary + 0.00001, index + 1)
    end
    at(total + 0.001, 1)
    assert(f.listCount == lists and f.allUnitReads == 1)
end)

check("invalid frame-duration data disables the effect and releases its resources", function()
    local _, glyph = next(figures.glyphs)
    for _, bad in ipairs({0, -0.1, math.huge, "slow"}) do
        local durations = {}; for i = 1, #glyph.frames do durations[i] = 1 end
        durations[2] = bad
        local f = fixture({invalidTiming = durations})
        assert(f.removed and f.deletedShaders[1] and #f.errors == 1)
    end
    local f = fixture({invalidTiming = {1}})
    assert(f.removed and f.deletedShaders[1])
end)

print("PASS: parade pixel hologram regression suite")
