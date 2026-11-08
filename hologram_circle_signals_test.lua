-- Run from the game root with Lua 5.1 or newer.
-- Execute the production callbacks and call sites with strict engine fixtures.
local function read(path)
    local f = assert(io.open(path))
    local source = f:read('*a'); f:close()
    return source
end
local function run(source, env)
    setmetatable(env, {__index = _G})
    if setfenv then
        return setfenv(assert(loadstring(source)), env)()
    end
    return assert(load(source, 'regression', 't', env))()
end
local function definition(source, name)
    local escaped = name:gsub('%.', '%%.')
    return assert(source:match('(function '..escaped..'%([^\n]*\n.-\nend)'))
end
local function check(name, fn)
    fn(); print('PASS: '..name)
end

check('both circle dances use distinct valid signals in every hologram caller', function()
    local animation = read('scripts/tigLilAnimation.lua')
    for _, path in ipairs({
        'scripts/advertisingblimphologramscript.lua',
        'scripts/house_western_hologram_script.lua',
        'scripts/house_western_brothel_hologram_script.lua',
    }) do
        local env = {}
        for name, value in read(path):gmatch('(SIG_%u+)%s*=%s*(%d+)') do
            env[name] = tonumber(value)
        end
        local bits = {}
        for name, value in pairs(env) do
            assert(not bits[value], path..': overlapping signal '..name)
            bits[value] = true
        end
        env.animationLifetime = (env.SIG_CORE or 0) + env.SIG_TIGLIL
        local signal, mask
        env.Signal = function(value) assert(type(value) == 'number'); signal = value end
        env.SetSignalMask = function(value) assert(type(value) == 'number'); mask = value end
        env.Turn = function() coroutine.yield('animating') end
        for _, name in ipairs({'danceTurnLeft', 'danceTurnRight'}) do
            run(definition(animation, name), env)
            local thread = coroutine.create(env[name])
            local ok, state = coroutine.resume(thread)
            assert(ok, state)
            assert(state == 'animating')
            assert(signal == env.SIG_INCIRCLE)
            assert(mask == env.SIG_INCIRCLE + env.animationLifetime)
        end
    end
end)
