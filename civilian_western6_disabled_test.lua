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

check('unavailable western civilian 6 is not registered', function()
    local class = {}
    function class:New() return self end
    local defs = run(read('units/neutral/civilian_western/Civilian_western6.lua'), {
        Civilian = class, lowerkeys = function(t) return t end,
    })
    assert(next(defs) == nil)
end)
