-- Lua 5.1+: diagnostic formatting, sampling and output cannot break callbacks.
local function fixture(sink)
    local frame, lines = 0, {}
    local env = setmetatable({GG={}, Spring={
        Echo=sink or function(line) lines[#lines+1]=line end,
        GetGameFrame=function() return frame end,
    }}, {__index=_G})
    local chunk
    if setfenv then
        chunk=assert(loadfile('scripts/lib_building_destruction_trace.lua'));setfenv(chunk,env)
    else
        chunk=assert(loadfile('scripts/lib_building_destruction_trace.lua','t',env))
    end
    local trace=chunk()
    return trace, lines, function(value) frame=value end, env
end

local trace, lines, tick, env=fixture()
assert(trace.Log(42,'damage_queued',{piece=2,damage=12.5,reason='test\nreason',value={}},30))
assert(lines[1]=='[BuildingDestruction] frame=0 unit=42 stage=damage_queued damage=12.5 piece=2 reason=test reason value=<table>')
assert(not trace.Log(42,'damage_queued',{piece=2,reason='test\nreason'},30))
tick(29)
assert(not trace.Log(42,'damage_queued',{piece=2,reason='test\nreason'},30))
assert(trace.Log(42,'damage_queued',{piece=3,reason='test\nreason'},30), 'distinct blocks were hidden')
assert(trace.Log(43,'damage_queued',{piece=2,reason='test\nreason'},30), 'distinct houses were hidden')
tick(30)
assert(trace.Log(42,'damage_queued',{piece=2,reason='test\nreason'},30))
assert(lines[#lines]:find('suppressed=2',1,true), 'sample omitted suppression count')
assert(trace.Log(42,'failure_scheduled',{piece=2}))
assert(trace.Log(42,'failure_scheduled',{piece=2}), 'real transitions must not be sampled')
assert(trace.Log(nil,'damage_gadget_ready'))
trace.Forget(42)
trace.Forget(nil)
assert(trace.Log(42,'damage_queued',{piece=2,reason='test\nreason'},30), 'old unit lifetime retained repeat state')
assert(env.GG.BuildingDestructionTrace==trace, 'logger was not shared across contexts')

local failed=fixture(function() error('simulated output failure') end)
assert(failed.Log(42,'damage_queued',{damage=100})==false, 'output failure escaped into gameplay')
print('PASS: safe scalar formatting, deterministic fields, bounded repeats, unit/piece isolation, cleanup and failing output sink')
