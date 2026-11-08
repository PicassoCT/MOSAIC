-- Run from the repository root with Lua 5.1+.
-- Execute both real widget initializers and the real shared profile getters in
-- LuaUI's isolated environment. Renderer doubles keep this an import regression.
local function loadIn(path, environment)
    local chunk = setfenv and setfenv(assert(loadfile(path)), environment)
        or assert(loadfile(path, 't', environment))
    return chunk()
end
local function read(path)
    local file = assert(io.open(path))
    local source = file:read('*a'); file:close()
    return source
end
local function newWidget()
    local state = {logs = {}, globals = {}, live = {}, serial = 0, captures = 0}
    local function alloc(kind)
        state.serial = state.serial + 1
        state.live[state.serial] = kind
        return state.serial
    end
    local function free(id, kind)
        assert(state.live[id] == kind, 'invalid or duplicate GL resource deletion')
        state.live[id] = nil
    end
    local function node() return {Shutdown = function() end} end
    local function noop() end
    local systemEnvironment = setmetatable({}, {__index = _G})
    loadIn('luaui/system.lua', systemEnvironment)
    local environment = {}
    -- Match mosaicwidgets.NewWidget: copy the actual System exports rather
    -- than giving the widget a host-global fallback that hides missing _G.
    for key, value in pairs(assert(rawget(systemEnvironment, 'System'))) do
        environment[key] = value
    end
    environment.widget = environment
    assert(environment._G == nil and environment.pairs == pairs)
    assert(getmetatable(environment) == nil)
    environment.WG = {}
    environment.UnitDefs = {
        [1] = {name = 'policetruck', speed = 30, customParams = {baseclass = 'Truck'}},
        [2] = {name = 'civilian_arab0', speed = 20, customParams = {baseclass = 'Civilian'}},
        [3] = {name = 'ground_tank_day', speed = 25, customParams = {baseclass = 'Tank'}},
        [4] = {name = 'ground_tank_night', speed = 25, customParams = {baseclass = 'Tank'}},
        [5] = {name = 'house_arab0', speed = 0, isBuilding = true},
    }
    environment.WeaponDefs = {}
    environment.Game = {mapSizeX = 8192, mapSizeZ = 8192, gameSpeed = 30}
    environment.Spring = {
        GetAllUnits = function() return {} end,
        GetGameFrame = function() return 0 end,
        GetViewGeometry = function() return 1280, 720, 0, 0 end,
        Echo = function(message) state.logs[#state.logs + 1] = message end,
    }
    environment.GL = {}
    environment.gl = {
        GetViewSizes = function() return 1280, 720 end,
        CreateTexture = function() return alloc('texture') end,
        DeleteTexture = function(id) free(id, 'texture') end,
        CreateShader = function() return alloc('shader') end,
        DeleteShader = function(id) free(id, 'shader') end,
        GetUniformLocation = function(_, name) return name end,
        GetShaderLog = function() return '' end,
        RenderToTexture = noop, UnitPiece = noop, BeginEnd = noop, UnitMultMatrix = noop,
    }
    environment.widgetHandler = {
        RegisterGlobal = function(_, name, callback)
            assert(not state.globals[name], 'callback registered twice')
            state.globals[name] = callback
        end,
        DeregisterGlobal = function(_, name) state.globals[name] = nil end,
        RemoveWidget = function() error('lighting widget removed during initialization') end,
    }
    state.propagation = node()
    local scene = node(); scene.mobileSupported = true
    local modules = {
        ['luaui/widgets_mosaic/include/combat_light_sources.lua'] = {
            New = function(_, police, tanks)
                state.police, state.tanks = police, tanks
                return {Collect = function() return {} end, UnitCreated = noop}
            end,
        },
        ['luaui/widgets_mosaic/include/combat_light_renderer.lua'] = function()
            local renderer = node()
            renderer.Capture = function() state.captures = state.captures + 1 end
            return renderer
        end,
        ['luarules/gadgets/include/smoke_ribbon_renderer.lua'] = node,
        ['luaui/widgets_mosaic/include/combat_tracers.lua'] = node,
        ['luarules/gadgets/include/cloud_volume_config.lua'] = {},
        ['luaui/widgets_mosaic/include/radiance_objective_sources.lua'] = {},
        ['luaui/widgets_mosaic/include/radiance_propagation.lua'] = function() return state.propagation end,
        ['luaui/widgets_mosaic/include/radiance_local.lua'] = {New = node},
        ['luaui/widgets_mosaic/include/radiance_scene.lua'] = function() return scene end,
        ['luaui/widgets_mosaic/include/headlight_live_field.lua'] = node,
        ['luaui/widgets_mosaic/include/window_lighting.lua'] = node,
        ['luaui/widgets_mosaic/include/mobile_shadow_field.lua'] = {
            New = function(profiles)
                state.mobileProfiles = profiles
                local mobile = node()
                mobile.enabled, mobile.count, mobile.stats = true, 0, {}
                return mobile
            end,
        },
    }
    environment.VFS = {LoadFile = read}
    environment.VFS.Include = function(path, includeEnvironment)
        if path == 'scripts/lib_mosaic.lua' then
            assert(includeEnvironment and includeEnvironment.MOSAIC_CONFIG_ONLY)
            assert(includeEnvironment ~= environment, 'config helpers should have their own environment')
            state.configEnvironment = includeEnvironment
        end
        if modules[path] then return modules[path] end
        -- Explicit VFS environments are used directly, without adding standard
        -- functions. Unscoped includes inherit the caller's environment.
        return loadIn(path, includeEnvironment or (getfenv and getfenv(2) or environment))
    end
    return environment, state
end
local function assertIsolated(environment, state)
    assert(state.configEnvironment and environment.MOSAIC_CONFIG_ONLY == nil)
    assert(environment.GG == nil and state.configEnvironment.GG == nil,
        'graphics config import initialized synced state')
    for _, name in ipairs({'getPoliceLightTypeTable', 'getTankMuzzleTypeTable',
        'getMobileRadianceShadowTypeTable', 'getStructuralBuildingTypeTable'}) do
        assert(environment[name] == nil, 'config helper escaped into the widget: ' .. name)
    end
    assert(environment._G == nil, 'initialization introduced a host-global dependency')
end

do
    local environment, state = newWidget()
    loadIn('luaui/widgets_mosaic/gfx_light_effects.lua', environment)
    environment.widget:Initialize()
    assert(state.police[1] and state.police[1].pieceLift == 10,
        'the real police light profile did not reach combat sources')
    assert(not state.police[2] and state.tanks[3] and state.tanks[4])
    assert(state.tanks[3].piece == 'FireEmit' and state.tanks[3] == state.tanks[4],
        'the shared day/night muzzle profile did not reach combat sources')
    assert(environment.WG.CaptureCombatLightEmission and environment.WG.HasCombatLightEmission
        and environment.WG.lighteffects, 'combat light providers did not initialize')
    assert(state.globals.GadgetWeaponExplosion and state.globals.GadgetWeaponBarrelfire
        and state.globals.GadgetCombatFire and state.globals.GadgetPyroTorchOff)
    environment.WG.CaptureCombatLightEmission(0, 128, 1, 1)
    assert(state.captures == 1 and not environment.WG.HasCombatLightEmission(1))
    assertIsolated(environment, state)
    environment.widget:Shutdown()
    assert(not next(state.globals) and not next(environment.WG))
end

do
    local environment, state = newWidget()
    loadIn('luaui/widgets_mosaic/gfx_neonlights_radiancecascade.lua', environment)
    environment.widget:Initialize()
    assert(environment.WG.NeonRadiance == state.propagation)
    local profiles = assert(state.mobileProfiles,
        'mobile shadows did not initialize: ' .. table.concat(state.logs, '\n'))
    assert(profiles[1].shape == 1 and profiles[2].shape == 2
        and profiles[3].shape == 1 and profiles[4].shape == 1 and profiles[5] == nil,
        'the real mobile property set did not reach the shadow provider')
    environment.widget:TextCommand('radiancelight shadows stats')
    assert(state.logs[#state.logs]:find('height-aware', 1, true),
        'mobile shadow diagnostics did not recognize the initialized provider')
    assertIsolated(environment, state)
    environment.widget:Shutdown()
    assert(not next(state.globals) and not next(state.live) and not next(environment.WG),
        'isolated widget shutdown leaked lighting resources or providers')
end
print('PASS: isolated LuaUI environments without _G initialize real police/tank light profiles and mobile shadow profiles; providers, private config and cleanup preserved')
