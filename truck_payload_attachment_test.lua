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

check('payload attachment tolerates delay and payload destruction', function()
    local env = {unitID = 7, Spring = {}}
    local alive, parent, queries = true, nil, 0
    env.doesUnitExistAlive = function(id) assert(id == 7); return alive end
    env.Spring.GetUnitTransporter = function(id)
        assert(id == 7); queries = queries + 1; return parent
    end
    env.Sleep = function(ms) assert(ms == 100); coroutine.yield() end
    run(definition(read('scripts/truckPayloadScript.lua'), 'delayedParentDetection'), env)
    local thread = coroutine.create(env.delayedParentDetection)
    for _ = 1, 5 do assert(coroutine.resume(thread)) end
    assert(env.transportingParent == nil and coroutine.status(thread) == 'suspended')
    parent = 42
    assert(coroutine.resume(thread))
    assert(env.transportingParent == 42 and coroutine.status(thread) == 'dead')
    parent, env.transportingParent = nil, nil
    thread = coroutine.create(env.delayedParentDetection)
    assert(coroutine.resume(thread))
    alive = false
    local lastQueries = queries
    assert(coroutine.resume(thread))
    assert(coroutine.status(thread) == 'dead' and queries == lastQueries)
end)

check('payload rewards retain parent credit and handle unattached payloads', function()
    local attackers, transfers = {}, {}
    local env = {
        unitID = 7, Spring = {}, GG = {Bank = {}},
        GameConfig = {economy = {rewards = {fortKnoxDestructionMoney = 100}}},
    }
    env.Spring.GetUnitTransporter = function() return nil end
    env.Spring.GetUnitLastAttacker = function(id)
        assert(type(id) == 'number'); return attackers[id]
    end
    env.Spring.GetUnitTeam = function(id) assert(id == 50); return 2 end
    env.GG.Bank.TransferToTeam = function(_, money, team, source)
        assert(money == 100 and team == 2 and source == 7)
        transfers[#transfers + 1] = true
    end
    run(definition(read('scripts/truckPayloadScript.lua'), 'rewardAudacity'), env)
    env.rewardAudacity()
    assert(#transfers == 0)
    env.transportingParent, attackers[42] = 42, 50
    env.rewardAudacity()
    assert(#transfers == 1)
    env.transportingParent, attackers[7] = nil, 50
    env.rewardAudacity()
    assert(#transfers == 2)
end)
