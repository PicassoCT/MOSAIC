-- Run from the game root with Lua 5.1 or newer (or texlua).
-- Drive the actual station-ad animation through its sleeps and visibility API.
local function fixture(initialFlag)
    local s = {visible={}, shows={}, hides={}, rule=initialFlag, threads={}}
    local pieceNames = {[0]='Frame'}
    local pieceMap = {Frame=0}
    local flicker = {}
    for i=1,8 do
        pieceNames[i] = 'Flicker'..i
        pieceMap[pieceNames[i]] = i
        flicker[i] = i
    end
    local env = setmetatable({unitID=42, script={}}, {__index=_G})
    s.env = env
    env.include = function(path) assert(path=='lib_UnitScript.lua') end
    env.piece = function(name) return assert(pieceMap[name]) end
    env.getPieceTableByNameGroups = function() return {Flicker=flicker} end
    env.Spring = {
        GetUnitPieceList=function(id) assert(id==42); return pieceNames end,
        GetUnitPieceMap=function(id) assert(id==42); return pieceMap end,
        GetUnitRulesParam=function(id, key)
            assert(id==42 and key=='city_parade_hide_commercial')
            return s.rule
        end,
        SetUnitAlwaysVisible=function() end,
        SetUnitNoSelect=function() end,
        SetUnitBlocking=function() end,
    }
    env.Show = function(id)
        assert(pieceNames[id], 'unknown shown piece')
        s.visible[id] = true
        s.shows[#s.shows+1] = id
    end
    env.Hide = function(id)
        assert(pieceNames[id], 'unknown hidden piece')
        s.visible[id] = nil
        s.hides[#s.hides+1] = id
    end
    env.Sleep = function(milliseconds) return coroutine.yield(milliseconds) end
    env.maRa = function() return false end
    function s:step()
        local ok, delay = coroutine.resume(self.threads[1])
        assert(ok, delay)
        assert(type(delay)=='number' and delay>0, 'animation stopped advancing')
        assert(coroutine.status(self.threads[1])=='suspended')
    end
    env.StartThread = function(fn)
        s.threads[#s.threads+1] = coroutine.create(fn)
        assert(#s.threads==1, 'unexpected animation worker')
        s:step()
    end
    function s:setHidden(hidden)
        self.rule = hidden and 1 or 0
        env.SetParadeCommercialHidden(hidden)
    end
    local chunk
    if setfenv then
        chunk = assert(loadfile('scripts/animated_hologramscript.lua'))
        setfenv(chunk, env)
    else
        chunk = assert(loadfile('scripts/animated_hologramscript.lua', 't', env))
    end
    chunk()
    env.script.Create()
    return s
end

local function assertFrame(s, frame)
    assert(s.visible[0] and s.visible[frame], 'frame border or current ad missing')
    local count = 0
    for id in pairs(s.visible) do
        assert(id==0 or id==frame, 'stale ad frame restored')
        count = count + 1
    end
    assert(count==2)
end

local s = fixture()
assertFrame(s, 1)
s:setHidden(true)
assert(not next(s.visible), 'border or active frame survived suppression')
local hides, shows = #s.hides, #s.shows
s:setHidden(true)
assert(#s.hides==hides and #s.shows==shows, 'repeated hide changed visibility')
s:step(); s:step()
assert(not next(s.visible) and #s.shows==shows, 'a later animation frame leaked')
s:setHidden(false)
assertFrame(s, 3)
hides, shows = #s.hides, #s.shows
s:setHidden(false)
assert(#s.hides==hides and #s.shows==shows, 'repeated restore redrew pieces')
s:step()
assertFrame(s, 4)
print('PASS: native ad masks border and flicker, keeps animating, restores latest frame, and toggles idempotently')

local hidden = fixture(1)
assert(not next(hidden.visible) and #hidden.shows==0, 'initially suppressed ad flashed during creation')
hidden:step(); hidden:step(); hidden:step()
assert(not next(hidden.visible) and #hidden.shows==0, 'initially suppressed flicker leaked')
hidden:setHidden(false)
assertFrame(hidden, 4)
hidden:step()
assertFrame(hidden, 5)
print('PASS: creation with a persisted parade flag stays hidden and resumes the current animation frame')
