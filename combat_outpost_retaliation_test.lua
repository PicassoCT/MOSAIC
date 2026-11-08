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

check('combat outpost retaliates using its actual unit ID', function()
    local orders = 0
    local env = {
        unitID = 17, script = {}, CMD = {ATTACK = 20},
        UnitDefs = {[1] = {name = 'combatoutpost'}},
        Spring = {GetUnitDefID = function(id) assert(id == 17); return 1 end},
        doesUnitExistAlive = function(id) return id == 42 end,
    }
    env.Spring.GiveOrderToUnit = function(id, command, targets)
        assert(id == 17 and command == 20 and targets[1] == 42)
        orders = orders + 1
    end
    run(definition(read('scripts/lib_UnitScript.lua'), 'Command'), env)
    run(definition(read('scripts/objectivecombatoutpostscript.lua'), 'script.HitByWeapon'), env)
    env.script.HitByWeapon(0, 0, 1, 50, 42)
    assert(orders == 1)
    env.script.HitByWeapon(0, 0, 1, 50, nil)
    assert(orders == 1)
end)
