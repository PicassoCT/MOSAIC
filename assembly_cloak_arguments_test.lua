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

check('assembly cloak pauses hide pieces and complete after uncloaking', function()
    local source = read('scripts/assemblyscript.lua')
    local hidden, sleeps = {}, 0
    local env = {
        partName = 10, objectToPick = 20, scaraNumber = 1, robotID = 1,
        currentTool = 5, DeskTable = {{[5] = 30}},
        getTrayObects = function() return {11, 12} end,
        getScaraTable = function() return {21, 22} end,
        getRobotTable = function() return {31, 32} end,
        Hide = function(id)
            assert(type(id) == 'number', 'Hide requires a numeric piece ID')
            hidden[id] = true
        end,
    }
    env.hideT = function(pieces) for _, id in ipairs(pieces) do env.Hide(id) end end
    env.Sleep = function(ms)
        assert(ms == 500); sleeps = sleeps + 1; env.boolLocalCloaked = false
    end
    run(definition(source, 'stopWaitLocalyCloaked'), env)
    local calls = 0
    for line in source:gmatch('[^\n]+') do
        if line:match('^%s+stopWaitLocalyCloaked%(') then
            env.boolLocalCloaked = true
            run(line, env)
            calls = calls + 1
        end
    end
    assert(calls == 3 and sleeps == 3)
    for _, id in ipairs({10, 11, 12, 20, 21, 22, 30, 31, 32}) do
        assert(hidden[id], 'piece was omitted: '..id)
    end
    hidden = {}
    env.stopWaitLocalyCloaked(10, {11, 12})
    assert(next(hidden) == nil, 'uncloaked assembly should keep animating')
end)
