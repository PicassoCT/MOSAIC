-- Lua 5.1+: exercise visibility, transport, variant changes and GL ownership.
local catalog = dofile("scripts/lib_truck_parade_payloads.lua")
local config = dofile("luarules/configs/parade_hologram_decorations.lua")
local figures = dofile("luarules/configs/parade_hologram_figures.lua")
local sceneConfig = dofile("luarules/configs/parade_hologram_scene.lua")
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
local function close(a, b) return math.abs(a - b) < 0.000001 end
local function terrainHeight(x, z) return 4 + x * 0.01 + z * 0.02 end

local function fixture(options)
    options = options or {}
    local f = {alive = {[5] = true, [20] = true}, defs = {[5] = 7, [20] = 1},
        parents = {[5] = 20}, variants = {[5] = 1}, positions = {[20] = {0, 0, 0}},
        camera = {0, 0, 300}, los = true, inView = true, fullView = false,
        noDraw = false, cloaked = false, seconds = 10, center = 0,
        listCount = 0, lists = {}, draws = {}, transforms = {}, uniforms = {},
        deletedLists = {}, deletedShaders = {}, allUnitReads = 0, removed = false,
        matrixDepth = 0, attribDepth = 0, activeShader = 99, blend = "original",
        depthMask = true, depthTest = false, culling = true, errors = {},
        shaderCount = 0, meshDraws = {}, texture = "caller-texture",
        materialTexture = "caller-material", direction = {0, 0, 1}, groundReads = {}}
    local sceneModels = {figures = {}, props = {}}
    f.pieceMap = {center = f.center}
    if options.native then
        local nextPiece = 1
        for _, item in ipairs(sceneConfig.figures) do
            local definition = {height = 8, headPivot = {0, 6, 0}, pieces = {}}
            for _, role in ipairs({"body", "head", "mask"}) do
                local name = item.model .. role
                definition.pieces[role] = name
                f.pieceMap[name:upper()] = nextPiece
                nextPiece = nextPiece + 1
            end
            sceneModels.figures[item.model] = definition
        end
        for _, item in ipairs(sceneConfig.props) do
            local name = "parade" .. item.model
            if not sceneModels.props[item.model] then
                sceneModels.props[item.model] = {piece = name}
                f.pieceMap[name:upper()] = nextPiece
                nextPiece = nextPiece + 1
            end
        end
    end
    if options.authored then
        sceneModels = dofile("luarules/configs/parade_hologram_models.lua")
        f.pieceMap = {center = 0}
        local nextPiece = 1
        local function add(name)
            if f.pieceMap[name:upper()] == nil then
                f.pieceMap[name:upper()] = nextPiece; nextPiece = nextPiece + 1
            end
        end
        for _, def in pairs(sceneModels.figures) do for _, name in pairs(def.pieces) do add(name) end end
        for _, def in pairs(sceneModels.props) do
            for _, choice in ipairs(def.variants) do
                add(choice.piece)
                for _, wing in ipairs(choice.wings or {}) do add(wing.piece) end
            end
        end
    end
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
        GL = {QUADS = 7, LEQUAL = 515, SRC_ALPHA = 770, ONE = 1,
            ONE_MINUS_SRC_ALPHA = 771, BACK = 1029},
        UnitDefNames = {truckpayloadparade = {id = 7}},
        VFS = {Include = function(path)
            if path == "scripts/lib_truck_parade_payloads.lua" then return catalog end
            if path == "luarules/configs/parade_hologram_figures.lua" then return figureData end
            if path == "luarules/configs/parade_hologram_decorations.lua" then return config end
            if path == "luarules/configs/parade_hologram_models.lua" then return sceneModels end
            return dofile(path)
        end}, gadgetHandler = {IsSyncedCode = function() return options.synced end,
            RemoveGadget = function() f.removed = true end}}
    env.Script = {LuaUI = setmetatable({ReceiveParadeRadianceScene = function(queue, def)
        f.radiance, f.radianceDef = queue, def
    end}, {__call = function() return true end})}
    local S, gl = env.Spring, env.gl
    S.ValidUnitID = function(id) return f.alive[id] ~= nil end
    S.GetUnitIsDead = function(id) return not f.alive[id] end
    S.GetUnitDefID = function(id) return f.defs[id] end
    S.GetAllUnits = function() f.allUnitReads = f.allUnitReads + 1; return {5, 20} end
    S.GetUnitTransporter = function(id) return f.parents[id] end
    S.GetUnitRulesParam = function(id, key)
        if key == "city_parade_retiring" then return f.retiring and 1 or 0 end
        assert(key == "city_parade_variant"); return f.variants[id]
    end
    S.GetUnitPieceMap = function(id) assert(f.defs[id] == 7); return f.pieceMap end
    if options.rootScale then
        S.GetUnitPieceMatrix = function()
            local s = options.rootScale
            return s, 0, 0, 0, 0, s, 0, 0, 0, 0, s, 0, 0, 3.2, -1.8, 1
        end
        gl.Scale = function(x, y, z)
            assert(f.activeShader == 1, "only the legacy placement frame receives scale compensation")
            f.spriteScale = {x, y, z}
        end
    end
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
    S.GetGroundHeight = function(x, z)
        f.groundReads[#f.groundReads + 1] = {x, z}
        return terrainHeight(x, z)
    end
    S.GetUnitDirection = function() return f.direction[1], f.direction[2], f.direction[3] end
    S.Echo = function(message) f.errors[#f.errors + 1] = message end
    gl.CreateShader = function(spec)
        f.shaderCount = f.shaderCount + 1
        if f.shaderCount == 1 then f.shaderSpec = spec end
        if options.shaderFailure or (options.sceneShaderFailure and f.shaderCount > 1) then return nil end
        return f.shaderCount
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
        f.color = {r, g, b, a}
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
        assert(f.activeShader ~= 2, "raw world scenery must not inherit unit transforms")
        f.unit = id; f.transforms[#f.transforms + 1] = {"unit", id}
    end
    gl.UnitPieceMultMatrix = function(id, piece)
        assert(f.activeShader ~= 2, "raw world scenery must not inherit FBX piece transforms")
        assert(id == f.unit and piece == 0, "center piece zero is valid")
        f.transforms[#f.transforms + 1] = {"piece", id, piece}
    end
    gl.Translate = function(x, y, z)
        f.anchor = {x, y, z}
        if f.activeShader == 2 and f.matrixDepth == 1 then f.rawAnchor = {x, y, z} end
    end
    gl.CallList = function(id)
        if f.throwDraw then error("injected draw failure") end
        local world = f.matrixDepth == 1
        assert(f.activeShader == 1 and (f.matrixDepth == 2 or (world and f.lists[id].glyph == "lantern")),
            "only world lanterns may bypass the float attachment transform")
        assert(f.depthMask == false and f.depthTest == env.GL.LEQUAL and f.culling == false)
        assert(f.blend == "770:1")
        f.draws[#f.draws + 1] = {unit = f.unit, glyph = f.lists[id].glyph,
            frame = f.lists[id].frame, opacity = f.uniforms.opacity,
            pixelSize = f.uniforms.pixelSize, anchor = f.anchor, world = world}
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
        f.saved = {f.blend, f.depthMask, f.depthTest, f.culling, f.texture, f.materialTexture}
    end
    gl.PopAttrib = function()
        assert(f.attribDepth == 1); f.attribDepth = 0
        f.blend, f.depthMask, f.depthTest, f.culling = f.saved[1], f.saved[2], f.saved[3], f.saved[4]
        f.texture = f.saved[5]
        f.materialTexture = f.saved[6]
    end
    gl.DepthTest = function(value) f.depthTest = value end
    gl.DepthMask = function(value) f.depthMask = value end
    gl.Culling = function(value) f.culling = value end
    gl.Blending = function(src, dst) f.blend = src .. ":" .. dst end
    if options.native then
        gl.Rotate = function(angle, x, y, z)
            if f.matrixDepth == 1 and x == 1 and y == 0 and z == 0 then f.rawTilt = angle end
            if f.matrixDepth == 2 and math.abs(x) > .999 and math.abs(y) < .001 and math.abs(z) < .001 then f.wingAngle = angle end
        end
        gl.Texture = function(unit, texture)
            assert(unit == 0 or unit == 1)
            if unit == 0 then f.texture = texture else f.materialTexture = texture end
        end
        gl.UnitPiece = function(id, pieceID)
            if f.throwMeshDraw then error("injected mesh draw failure") end
            assert(f.activeShader == 2 and f.matrixDepth >= 1)
            assert(f.depthMask == false and f.depthTest == env.GL.LEQUAL and f.culling == env.GL.BACK)
            assert(f.blend == "770:771", "standard alpha must preserve dark silhouettes and mask holes")
            assert(f.texture == "%7:0")
            assert(f.materialTexture == "%7:1", "opacity comes from packed material, not diffuse team-color alpha")
            f.meshDraws[#f.meshDraws + 1] = {id = id, piece = pieceID,
                anchor = f.rawAnchor, opacity = f.color[4], tilt = f.rawTilt, wingAngle = f.wingAngle}
        end
    end
    f.result = loadEnv("luarules/gadgets/gfx_parade_scenery.lua", env)
    f.env, f.gadget = env, env.gadget
    if not options.synced then f.gadget:Initialize() end
    return f
end

local function drawAt(f, seconds)
    f.seconds, f.draws, f.meshDraws, f.groundReads = seconds, {}, {}, {}
    f.gadget:DrawWorld()
    assert(not f.removed and #f.errors == 0)
end

local function advanceTo(f, seconds)
    -- Keep the fixture visible between samples; a long camera gap deliberately
    -- creates a new station and would not exercise an existing cohort's age.
    while f.seconds + 1 < seconds do drawAt(f, f.seconds + 1) end
    drawAt(f, seconds)
end

local function meshDraws(f, piece)
    local found = {}
    for _, draw in ipairs(f.meshDraws) do
        if draw.piece == f.pieceMap[piece] then found[#found + 1] = draw end
    end
    return found
end

local function pixelLanterns(f)
    local found = {}
    for _, draw in ipairs(f.draws) do
        if draw.glyph == "lantern" then
            assert(draw.world, "fallback lanterns must use the planted world frame")
            found[#found + 1] = draw
        end
    end
    return found
end

local function atAnchor(draws, x, z)
    for _, draw in ipairs(draws) do
        if close(draw.anchor[1], x) and close(draw.anchor[3], z) then return draw end
    end
    error("missing world anchor " .. x .. ", " .. z)
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
    for _, seconds in ipairs({10, 12}) do
        for index, variant in ipairs(catalog.variants) do
            f.variants[5] = index; drawAt(f, seconds)
            local expected, hasLantern = {}, false
            for _, item in ipairs(themeFor(variant.hologramTheme or variant.key)) do
                if item.glyph == "lantern" then hasLantern = true
                else expected[#expected + 1] = item end
            end
            local lanternCount = hasLantern and seconds == 12 and 6 or 0
            assert(#f.draws == #expected + lanternCount)
            for n, item in ipairs(expected) do assert(f.draws[n].glyph == item.glyph) end
            assert(#pixelLanterns(f) == lanternCount)
        end
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

check("complete near native scenery owns the scene without duplicate legacy candles or figures", function()
    local f = fixture({native = true})
    f.gadget:DrawWorld()
    assert(#f.draws == 0 and #f.meshDraws == 0, "new world stations fade in without legacy flashes")
    assert(f.shaderCount == 2, "confirm native renderer before suppressing the fallback")
    f.seconds = 12; f.gadget:DrawWorld()
    assert(#f.draws == 0, "native ground candles and spectators replace the old sprite placements")
    assert(#f.meshDraws == #sceneConfig.figures * 3 + #sceneConfig.props)
    assert(f.shaderCount == 2 and f.activeShader == 99 and f.matrixDepth == 0 and f.attribDepth == 0)
    assert(f.texture == "caller-texture" and f.materialTexture == "caller-material"
        and f.blend == "original" and f.depthMask == true)
    for _, draw in ipairs(f.meshDraws) do assert(draw.opacity > 0 and draw.opacity <= 1) end
    f.gadget:Shutdown(); assert(f.deletedShaders[1] and f.deletedShaders[2])
end)

check("legacy ornaments retain world-sized placement around a scaled FBX root", function()
    local f = fixture({rootScale = 0.0254})
    f.gadget:DrawWorld(); f.seconds = 12; f.gadget:DrawWorld()
    assert(math.abs(f.spriteScale[1] - 1/0.0254) < 0.000001)
    assert(f.spriteScale[1] == f.spriteScale[2] and f.spriteScale[1] == f.spriteScale[3])
    assert(#f.draws == 20 and #f.meshDraws == 0)
    local native = fixture({native = true, rootScale = 0.0254})
    native.gadget:DrawWorld(); native.seconds = 12; native.gadget:DrawWorld()
    assert(native.spriteScale == nil and #native.draws == 0,
        "native raw geometry never receives the legacy root scale compensation")
    assert(#native.meshDraws == #sceneConfig.figures * 3 + #sceneConfig.props)
end)

check("distance LOD crossfades the complete scenes and restores all legacy glyphs beyond native range", function()
    local f = fixture({native = true})
    f.gadget:DrawWorld(); f.seconds = 12; f.gadget:DrawWorld()
    assert(#f.draws == 0)
    local closeOpacity = {}
    for _, draw in ipairs(f.meshDraws) do closeOpacity[draw.piece] = draw.opacity end
    f.camera = {0, 0, 950}; f.draws = {}; f.meshDraws = {}; f.gadget:DrawWorld()
    local legacy = fixture(); legacy.camera = f.camera; legacy.seconds = f.seconds; legacy.gadget:DrawWorld()
    assert(#f.draws == 10 and #f.meshDraws == #sceneConfig.figures * 3 + #sceneConfig.props)
    for index, draw in ipairs(f.draws) do
        assert(math.abs(draw.opacity - legacy.draws[index].opacity * 0.5) < 0.000001)
    end
    -- Every figure piece has one placement, unlike the repeated lantern/star
    -- props, so compare exact per-piece opacity without order assumptions.
    for _, draw in ipairs(f.meshDraws) do
        if draw.piece < f.pieceMap.PARADECANDLE then
            assert(math.abs(draw.opacity - closeOpacity[draw.piece] * 0.5) < 0.000001)
        end
    end
    for _, distance in ipairs({sceneConfig.maxDistance, 1300}) do
        f.camera = {0, 0, distance}; f.draws = {}; f.meshDraws = {}; f.gadget:DrawWorld()
        legacy.camera = f.camera; legacy.draws = {}; legacy.gadget:DrawWorld()
        assert(#f.draws == 10 and #f.meshDraws == 0)
        for index, draw in ipairs(f.draws) do
            assert(math.abs(draw.opacity - legacy.draws[index].opacity) < 0.000001)
        end
    end
end)

check("native candles keep their terrain contact and do not follow a moving carrier", function()
    local f = fixture({native = true})
    f.gadget:DrawWorld(); f.seconds = 12; f.gadget:DrawWorld()
    local candleID = f.pieceMap.PARADECANDLE
    local before = {}
    for _, draw in ipairs(f.meshDraws) do
        if draw.piece == candleID then
            before[draw.anchor[1] .. ":" .. draw.anchor[3]] = draw.anchor[2]
            assert(math.abs(draw.anchor[2] - (4 + draw.anchor[1]*0.01 + draw.anchor[3]*0.02)) < 0.000001)
        end
    end
    f.meshDraws = {}; f.positions[20] = {50, 200, 20}; f.seconds = 12.5
    f.gadget:DrawWorld()
    local count = 0
    for _, draw in ipairs(f.meshDraws) do
        if draw.piece == candleID then
            count = count + 1
            assert(before[draw.anchor[1] .. ":" .. draw.anchor[3]] == draw.anchor[2])
        end
    end
    assert(count == 4, "all four candles remain at their original curb positions")
end)

check("native lanterns appear at daemon release and blink off together before recycling", function()
    local f, settings = fixture({native = true}), sceneConfig.lanterns
    drawAt(f, 0)
    for _, time in ipairs({0.4, settings.releaseSeconds - 0.01}) do
        drawAt(f, time)
        assert(#meshDraws(f, "PARADELANTERN") == 0 and #f.draws == 0)
        assert(#f.meshDraws > 0, "the audience must remain visible while lanterns wait")
    end
    drawAt(f, settings.releaseSeconds)
    assert(#meshDraws(f, "PARADELANTERN") == 6 and #f.draws == 0)
    for _, item in ipairs(sceneConfig.figures) do
        if item.lanternEmitter then
            local body = meshDraws(f, (item.model .. "body"):upper())
            assert(#body == 1 and math.abs(body[1].tilt) > 8,
                "the release must coincide with a rendered placement gesture")
        end
    end
    for generation = 0, 3 do
        local release = settings.releaseSeconds + generation * 4 * settings.switchSeconds
        drawAt(f, release + 0.0001)
        local lanterns = meshDraws(f, "PARADELANTERN")
        assert(#lanterns == 6 and #f.draws == 0)
        for _, draw in ipairs(lanterns) do assert(close(draw.opacity, lanterns[1].opacity)) end
        local blink = release + 4 * settings.switchSeconds - settings.blinkSeconds
        advanceTo(f, blink - 0.0001)
        lanterns = meshDraws(f, "PARADELANTERN")
        assert(#lanterns == 6 and #f.draws == 0)
        for _, draw in ipairs(lanterns) do
            assert(close(draw.opacity, 0.88), "visible lanterns must not dim before blinking out")
        end
        drawAt(f, blink + 0.0001)
        assert(#meshDraws(f, "PARADELANTERN") == 0 and #f.draws == 0)
        drawAt(f, release + 4 * settings.switchSeconds - 0.0001)
        assert(#meshDraws(f, "PARADELANTERN") == 0 and #f.draws == 0,
            "the hidden interval must last until the next daemon release")
    end
end)

check("daemon terrain samples follow the task pose while placed lanterns remain anchored", function()
    local f, settings = fixture({native = true}), sceneConfig.lanterns
    f.positions[20], f.direction, f.camera = {200, 0, 300}, {3, 0, 4}, {200, 0, 600}
    drawAt(f, 0)
    for _, time in ipairs({0.4, 0.9}) do
        drawAt(f, time)
        for _, item in ipairs(sceneConfig.figures) do
            if item.lanternEmitter then
                local body = meshDraws(f, (item.model .. "body"):upper())[1]
                assert(body)
                local sampled = false
                for _, point in ipairs(f.groundReads) do
                    if close(point[1], body.anchor[1]) and close(point[2], body.anchor[3]) then sampled = true end
                end
                assert(sampled, "moving helpers need terrain at their current position before cache expiry")
                local hop = time == 0.4 and 0.35 or 0
                assert(close(body.anchor[2], terrainHeight(body.anchor[1], body.anchor[3]) + hop))
            end
        end
    end
    drawAt(f, settings.releaseSeconds + 0.15)
    local lanterns, planted = meshDraws(f, "PARADELANTERN")
    assert(#lanterns == 6)
    for _, item in ipairs(sceneConfig.props) do
        if item.motion == "lantern" then
            local source = meshDraws(f, (item.emitter .. "body"):upper())[1]
            local inward, along = item.x < 0 and 1 or -1, item.lanternSlot <= 3 and -1 or 1
            local x = source.anchor[1] + 0.8 * inward * settings.reach + 0.6 * along * settings.pairSpacing
            local z = source.anchor[3] - 0.6 * inward * settings.reach + 0.8 * along * settings.pairSpacing
            local draw = atAnchor(lanterns, x, z)
            assert(draw.anchor[2] >= terrainHeight(x, z))
            if item.lanternSlot == 1 then
                assert(close(draw.anchor[2], terrainHeight(x, z)))
                planted = draw.anchor
            end
        end
    end
    f.positions[20], f.direction = {250, 200, 320}, {-1, 0, 0}
    drawAt(f, 3)
    local same = atAnchor(meshDraws(f, "PARADELANTERN"), planted[1], planted[3])
    assert(close(same.anchor[2], planted[2]), "a released ground lantern must not follow a returning helper or turning truck")
end)

check("moving native and fallback stations keep bounded cohorts and reset release after visibility changes", function()
    for _, native in ipairs({true, false}) do
        local f = fixture({native = native})
        f.variants[5] = 2 -- A lantern theme also exercises the fallback route.
        drawAt(f, 0)
        local function lanterns() return native and meshDraws(f, "PARADELANTERN") or pixelLanterns(f) end
        local overlapping = false
        for tick = 1, 120 do
            local seconds = tick / 10
            f.positions[20] = {seconds * 34.32, 0, 0}
            drawAt(f, seconds)
            local count = #lanterns()
            assert(count == 0 or count == 6 or count == 12, "retain at most two complete station cohorts")
            if count == 12 then overlapping = true end
        end
        assert(overlapping, "fast parade travel must still release both crossfading station cohorts")
        f.los = false; drawAt(f, 14)
        assert(#lanterns() == 0)
        f.los = true; drawAt(f, 17)
        assert(#lanterns() == 0, "returning after a visibility gap must wait for a new daemon release")
        advanceTo(f, 18.5); assert(#lanterns() == 6)
        drawAt(f, 16); assert(#lanterns() == 0, "rewinding must discard the previous cohort")
        advanceTo(f, 17.5); assert(#lanterns() == 6)
        f.retiring = true; drawAt(f, 17.6)
        assert(#lanterns() == 0, "a dismissed procession cannot create another ground cohort")
    end
end)

check("rendered banknotes descend then blink out while koi keep their floating height", function()
    local f, money, koi = fixture({native = true})
    for _, item in ipairs(sceneConfig.props) do
        if item.model == "money" then money = item elseif item.model == "koi" then koi = item end
    end
    drawAt(f, 0)
    local cycle = money.fallSeconds + money.blinkSeconds
    for generation = 0, 1 do
        local previous
        for step = 1, 31 do
            advanceTo(f, generation * cycle + step * money.fallSeconds / 32)
            local notes, fish = meshDraws(f, "PARADEMONEY"), meshDraws(f, "PARADEKOI")
            assert(#notes == 1 and #fish == 1)
            local note = notes[1].anchor
            assert(close(note[1], money.x) and close(note[3], money.z))
            assert(note[2] >= terrainHeight(note[1], note[3]))
            if previous then assert(note[2] < previous, "a visible banknote must never take an upward leg") end
            previous = note[2]
            local height = fish[1].anchor[2] - terrainHeight(koi.x, koi.z)
            assert(close(fish[1].anchor[1], koi.x) and close(fish[1].anchor[3], koi.z))
            assert(math.abs(height - koi.y) <= 0.180001, "koi hover without accumulating a fall")
        end
        local disappearance = generation * cycle + money.fallSeconds
        advanceTo(f, disappearance - 0.0001)
        local last = meshDraws(f, "PARADEMONEY")
        assert(#last == 1 and close(last[1].opacity, money.opacity),
            "money must remain at its material opacity until it blinks out")
        drawAt(f, disappearance + 0.0001)
        assert(#meshDraws(f, "PARADEMONEY") == 0 and #meshDraws(f, "PARADEKOI") == 1,
            "money blinks off without recycling the floating koi")
        drawAt(f, disappearance + money.blinkSeconds - 0.0001)
        assert(#meshDraws(f, "PARADEMONEY") == 0)
    end
end)

check("both lantern fallback themes keep exact motion thirds in the world frame", function()
    for _, variant in ipairs({2, 4}) do
        local f = fixture({rootScale = 0.0254})
        f.variants[5] = variant
        f.positions[20], f.direction, f.camera = {200, 0, 300}, {3, 0, 4}, {200, 0, 600}
        drawAt(f, 0)
        drawAt(f, sceneConfig.lanterns.releaseSeconds - 0.01)
        assert(#pixelLanterns(f) == 0, "fallback lanterns cannot appear before daemon release")
        local seen, planted = {}, nil
        for epoch = 0, 1 do
            local time = sceneConfig.lanterns.releaseSeconds + epoch * sceneConfig.lanterns.switchSeconds + 0.4
            drawAt(f, time)
            local before = pixelLanterns(f)
            assert(#before == 6)
            drawAt(f, time + 0.05)
            local after, counts = pixelLanterns(f), {stationary = 0, up = 0, down = 0}
            assert(#after == 6)
            for _, old in ipairs(before) do
                local current = atAnchor(after, old.anchor[1], old.anchor[3])
                local delta = current.anchor[2] - old.anchor[2]
                local mode = close(delta, 0) and "stationary" or delta > 0 and "up" or "down"
                counts[mode] = counts[mode] + 1
                local key = old.anchor[1] .. ":" .. old.anchor[3]
                seen[key] = seen[key] or {}; seen[key][mode] = true
                if mode == "stationary" and close(current.anchor[2], terrainHeight(current.anchor[1], current.anchor[3])) then
                    planted = current.anchor
                end
            end
            assert(counts.stationary == 2 and counts.up == 2 and counts.down == 2)
        end
        local fixed, switching = 0, 0
        for _, modes in pairs(seen) do
            local count = 0; for _ in pairs(modes) do count = count + 1 end
            if count == 1 then fixed = fixed + 1 elseif count == 2 then switching = switching + 1 end
        end
        assert(fixed == 3 and switching == 3 and planted)
        f.positions[20], f.direction = {220, 0, 330}, {-1, 0, 0}
        drawAt(f, 5)
        local same = atAnchor(pixelLanterns(f), planted[1], planted[3])
        assert(close(same.anchor[2], planted[2]) and close(f.spriteScale[1], 1 / 0.0254),
            "world lanterns remain planted while attached ornaments compensate the imported root scale")
    end
end)

check("lantern mesh and billboard LOD share release time and every world anchor", function()
    local f = fixture({native = true})
    f.variants[5] = 2
    drawAt(f, 0); drawAt(f, 2)
    local near = meshDraws(f, "PARADELANTERN")
    assert(#near == 6 and #pixelLanterns(f) == 0)
    f.camera = {0, 0, 950}; drawAt(f, 2)
    local native, fallback = meshDraws(f, "PARADELANTERN"), pixelLanterns(f)
    assert(#native == 6 and #fallback == 6, "the LOD overlap must not restart the cohort")
    for _, draw in ipairs(near) do
        local mesh = atAnchor(native, draw.anchor[1], draw.anchor[3])
        local pixel = atAnchor(fallback, draw.anchor[1], draw.anchor[3])
        assert(close(mesh.anchor[2], draw.anchor[2]) and close(pixel.anchor[2], draw.anchor[2]))
        assert(close(mesh.opacity, draw.opacity * 0.5))
    end
    f.camera = {0, 0, 1300}; drawAt(f, 2)
    assert(#meshDraws(f, "PARADELANTERN") == 0 and #pixelLanterns(f) == 6)
    f.camera = {0, 0, 300}; drawAt(f, 2)
    assert(#meshDraws(f, "PARADELANTERN") == 6 and #pixelLanterns(f) == 0)
    local settings = sceneConfig.lanterns
    local blink = settings.releaseSeconds + 4 * settings.switchSeconds - settings.blinkSeconds
    advanceTo(f, blink - 0.0001)
    f.camera = {0, 0, 950}; drawAt(f, blink - 0.0001)
    assert(#meshDraws(f, "PARADELANTERN") == 6 and #pixelLanterns(f) == 6)
    drawAt(f, blink + 0.0001)
    assert(#meshDraws(f, "PARADELANTERN") == 0 and #pixelLanterns(f) == 0,
        "neither LOD path may render the hidden cohort")
    drawAt(f, settings.releaseSeconds + 4 * settings.switchSeconds + 0.0001)
    assert(#meshDraws(f, "PARADELANTERN") == 6 and #pixelLanterns(f) == 6)
end)

check("native additions inherit the legacy visibility boundary and bounded nearest payload set", function()
    local f = fixture({native = true})
    for id = 30, 45 do
        local parent = 100 + id
        f.alive[id], f.alive[parent], f.defs[id], f.defs[parent] = true, true, 7, 1
        f.parents[id], f.variants[id], f.positions[parent] = parent, 1, {id, 0, 0}
        f.gadget:UnitCreated(id, 7)
    end
    f.gadget:DrawWorld(); f.draws = {}; f.seconds = 12; f.gadget:DrawWorld()
    assert(#f.meshDraws == sceneConfig.maxVisiblePayloads * (#sceneConfig.figures * 3 + #sceneConfig.props))
    assert(#f.draws == (12 - sceneConfig.maxVisiblePayloads) * 10,
        "every remaining legacy budget slot retains its complete fallback")
    local ids = {}; for _, draw in ipairs(f.meshDraws) do ids[draw.id] = true end
    local count = 0; for _ in pairs(ids) do count = count + 1 end
    assert(count == sceneConfig.maxVisiblePayloads and ids[5])
    for _, draw in ipairs(f.draws) do assert(not ids[draw.unit], "near native and legacy ownership is exclusive") end
    for _, key in ipairs({"noDraw", "cloaked"}) do
        f[key] = true; f.meshDraws = {}; f.gadget:DrawWorld(); assert(#f.meshDraws == 0)
        f[key] = false
    end
    f.los = false; f.meshDraws = {}; f.gadget:DrawWorld(); assert(#f.meshDraws == 0)
    f.fullView = true; f.gadget:DrawWorld(); assert(#f.meshDraws > 0)
    f.retiring = true; f.meshDraws = {}; f.gadget:DrawWorld(); assert(#f.meshDraws == 0)
    f.retiring = false
    f.camera = {0, 0, 2000}; f.meshDraws = {}; f.gadget:DrawWorld(); assert(#f.meshDraws == 0)
end)

check("missing meshes or native shader/draw failures retain the original billboard fallback", function()
    local missing = fixture({native = true})
    missing.pieceMap = {center = 0}
    missing.gadget:DrawWorld(); missing.seconds = 12; missing.gadget:DrawWorld()
    assert(#missing.draws == 20 and #missing.meshDraws == 0 and missing.shaderCount == 1)
    for _, absent in ipairs({"PARADECIVILIAN1MASK", "PARADECANDLE"}) do
        local partial = fixture({native = true})
        partial.pieceMap[absent] = nil
        partial.gadget:DrawWorld(); partial.seconds = 12; partial.gadget:DrawWorld()
        assert(#partial.draws == 20 and #partial.meshDraws == 0 and partial.shaderCount == 1,
            "a missing native figure part or ground prop must keep the whole fallback")
    end
    for _, mode in ipairs({"shader", "draw"}) do
        local f = fixture({native = true, sceneShaderFailure = mode == "shader"})
        f.gadget:DrawWorld()
        assert(#f.draws == (mode == "shader" and 10 or 0), "shader failure restores fallback in the first frame")
        f.draws = {}; f.seconds = 12; f.throwMeshDraw = mode == "draw"
        f.gadget:DrawWorld()
        assert(#f.draws == 10, "native draw failure restores fallback in the failing frame")
        f.draws = {}; f.seconds = 13; f.gadget:DrawWorld()
        assert(#f.draws == 10 and not f.removed and #f.errors == 1 and f.shaderCount == 2)
        assert(f.matrixDepth == 0 and f.attribDepth == 0 and f.activeShader == 99)
        assert(f.texture == "caller-texture" and f.materialTexture == "caller-material"
            and f.blend == "original" and f.depthMask == true)
        if mode == "draw" then assert(f.deletedShaders[2]) end
        f.gadget:Shutdown(); assert(f.deletedShaders[1])
    end
end)

print("PASS: parade pixel and native hologram regression suite")

check("artist bird variants draw exactly two hinged wings and missing wings restore fallback", function()
    local f = fixture({native=true, authored=true})
    drawAt(f,10); drawAt(f,12)
    assert(#f.errors == 0)
    local reverse = {}; for name,id in pairs(f.pieceMap) do reverse[id]=name end
    local angles, birds = {}, 0
    for _, draw in ipairs(f.meshDraws) do
        local name = reverse[draw.piece]
        if name:match("^PARADEMOTH%dSUB%d$") then angles[#angles+1] = draw.wingAngle end
        if name:match("^PARADEMOTH%d$") then birds=birds+1 end
    end
    assert(birds == 1 and #angles == 2)
    assert(close(angles[1],-angles[2]) and math.abs(angles[1]) >= 18 and math.abs(angles[1]) <= 78)
    assert(#f.meshDraws <= 71, "one station exceeds 48 figure + 21 prop + 2 wing draw budget")
    f = fixture({native=true, authored=true})
    for name in pairs(f.pieceMap) do if name:match("^PARADEMOTH%dSUB2$") then f.pieceMap[name]=nil end end
    drawAt(f,10); drawAt(f,12)
    assert(#f.meshDraws == 0 and #f.draws > 0)
end)

check('radiance receives the displayed world scene and clears hidden or failed scenes',function()
    local f=fixture({native=true,authored=true})
    drawAt(f,0);drawAt(f,3)
    assert(#f.radiance>0 and f.radianceDef==7)
    for _,object in ipairs(f.radiance) do
        assert(object.id==5 and object.parent==20 and object.opacity>0 and object.pose)
    end
    f.los=false;drawAt(f,3.1);assert(#f.radiance==0)
    f.los=true;drawAt(f,4);drawAt(f,7);assert(#f.radiance>0)
    f.throwMeshDraw=true;f.seconds=7.1;f.gadget:DrawWorld();assert(#f.radiance==0)
    f.gadget:Shutdown();assert(#f.radiance==0)
end)
