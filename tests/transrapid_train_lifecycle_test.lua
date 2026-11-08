-- Run from the game root with lua. Exercise the real startup and train loops
-- with interleaved coroutines and movement waits, without an engine instance.
local unpack = table.unpack or unpack
local pieces, groups, shown = {}, {}, {}
local threads, starts, moving, positions, arrivals = {}, {}, {}, {}, {}
local now, routeDirection = 0, 1
unitID = 42; script = {}; x_axis = 1; y_axis = 2; z_axis = 3
Spring = {GetGaiaTeamID = function() return 0 end}
function piece(name)
    if not pieces[name] then pieces[name] = #pieces + 1; pieces[#pieces + 1] = name end
    return pieces[name]
end
for _, name in ipairs({'Train', 'Train1Sub', 'Train2Sub', 'Train3Sub', 'Train4Sub',
    'Rail1Sub', 'Rail2Sub', 'TunnelPlus', 'TunnelMinus', 'Add'}) do
    groups[name] = {}
    for i = 1, 4 do groups[name][i] = piece(name .. i) end
end
function include(name)
    if name == 'lib_Animation.lua' then dofile('scripts/' .. name) end
end
function getPieceTableByNameGroups() return groups end
function hideAll() shown = {} end
function Show(p) shown[p] = true end
function Hide(p)
    assert(not moving[p], 'train hidden before reaching its destination')
    shown[p] = nil
end
ShowRadiancePiece = Show
function showT(t) for _, p in pairs(t) do Show(p) end end
function hideT(t) for _, p in pairs(t) do Hide(p) end end
function foreach(t, fn) for _, p in pairs(t) do fn(p) end end
function maRa() return false end
function randSign() return routeDirection end
function moveCtrlHologramToUnitPiece() end
function getRandomElementFromTable(t) return t[1] end
function Turn() end
function StopSpin() end
function Sleep(ms) coroutine.yield(now + ms) end
function StartThread(fn, ...)
    starts[fn] = (starts[fn] or 0) + 1
    threads[#threads + 1] = {co = coroutine.create(fn), args = {...}, wake = now}
end
function Move(p, axis, target, speed)
    if axis ~= x_axis then return end
    assert(not moving[p], 'another command interrupted a train before arrival')
    if speed == 0 then
        positions[p] = target
    else
        assert(shown[p], 'movement command targeted a hidden train')
        local distance = math.abs(target - (positions[p] or 0))
        assert(distance == 120000, 'train did not start at the correct station')
        moving[p] = {target = target, finish = now + distance / speed * 1000}
    end
end
function WaitForMove(p)
    local move = moving[p]
    -- Yield even for instantaneous placement to expose shared coroutine state.
    coroutine.yield(move and move.finish or now + 1)
    if move then
        assert(now >= move.finish, 'train wait ended before arrival')
        positions[p] = move.target
        moving[p] = nil
        arrivals[p] = (arrivals[p] or 0) + 1
        local expected = 0
        if p == groups.Train[1] then expected = -120000 * routeDirection end
        if p == groups.Train[4] then expected = 120000 * routeDirection end
        assert(move.target == expected, 'train reached the wrong end station')
    end
end

dofile('scripts/objectivetransrapidscript.lua')
-- Track geometry is independent of command ownership; retain its startup barrier.
airPortConnection = function() end
deployTrack = function()
    Sleep(300)
    semaphore = semaphore + 1
end
local tunnels
deployTunnels = function()
    assert(semaphore == 2, 'trains started before both tracks were ready')
    tunnels = tunnels + 1
    Sleep(50)
end

local function simulate(direction, stopAt)
    routeDirection = direction
    threads, starts, moving, positions, arrivals = {}, {}, {}, {}, {}
    now, semaphore, tunnels = 0, 0, 0
    script.Create()
    while true do
        local nextThread
        for _, thread in ipairs(threads) do
            if coroutine.status(thread.co) ~= 'dead'
                and (not nextThread or thread.wake < nextThread.wake) then
                nextThread = thread
            end
        end
        assert(nextThread, 'train service stopped')
        if nextThread.wake > stopAt then break end
        now = nextThread.wake
        local ok, wake = coroutine.resume(nextThread.co, unpack(nextThread.args))
        nextThread.args = {}
        assert(ok, wake)
        if coroutine.status(nextThread.co) ~= 'dead' then nextThread.wake = wake end
    end
    assert(starts[trainLoop] == 1, 'station started duplicate train controllers')
    assert(starts[back] == 1 and starts[forth] == 1, 'direction has competing drivers')
    assert(tunnels == 2, 'tunnels were deployed more than once per side')
    for _, p in ipairs(groups.Train) do
        assert((arrivals[p] or 0) >= 3, 'train failed to complete repeated station trips')
    end
end

math.randomseed(42)
simulate(1, 120000)
simulate(-1, 120000)
print('PASS: one controller, track readiness, independent trains, full arrivals and repeated trips in both orientations')
