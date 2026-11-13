-- Compile the real header on separate includes, as the engine loader does.
local function read(path)
    local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local header=read('gamedata/unit_script_header.lua')
local lib=read('scripts/lib_textFx.lua')
local function environment(enabled)
    local calls={}
    local native={}
    for _,name in ipairs({'Move','Turn','Spin','StopSpin'}) do
        native[name]=function(...) calls[#calls+1]={name,...} end
    end
    native.Sleep=function(ms) return coroutine.yield(ms) end
    local env=setmetatable({unitID=1,unitDefID=1,textSpinner=99,textSpinnerAxis=3,
        UnitDefs={{customParams={text_fx_speed=enabled}}},
        Spring={UnitScript=native,GetUnitTeam=function() return 0 end}}, {__index=_G})
    env._G=env
    local function compile(source)
        setfenv(assert(loadstring(header..'\n'..source)),env)()
    end
    compile(lib)
    compile([[
        function sharedAnimation()
            Move(7,1,100,10);Turn(7,3,-1,2)
            Spin(7,2,-3,4);StopSpin(7,2,2)
            Move(7,1,0,0);Turn(7,3,0)
            Sleep(900)
        end
    ]])
    return env,calls
end
local function resume(co)
    local ok,value=coroutine.resume(co);assert(ok,value);return value
end
for _,case in ipairs({{1,1},{2,2},{3,3},{0,1},{9,3},{'invalid',1},{0/0,1}}) do
    local input,r=unpack(case)
    local env,calls=environment(true)
    local co=coroutine.create(function()
        assert(env.runHologramTextFx(env.sharedAnimation,{}, {spinnerSpeed=0.2},{},input)==r)
        assert(env.GetHologramTextFxSpeed()==1)
    end)
    assert(resume(co)==900/r,'effect sleep not accelerated')
    assert(calls[1][4]==100 and calls[1][5]==10*r,'movement target/speed')
    assert(calls[2][4]==-1 and calls[2][5]==2*r,'rotation target/speed')
    assert(calls[3][4]==-3*r and calls[3][5]==4*r*r,'spin ramp')
    assert(calls[4][4]==2*r*r,'braking ramp')
    assert(calls[5][5]==0 and calls[6][5]==nil,'snap/default speeds changed')
    assert(env.GetHologramTextFxSpeed()==1,'speed escaped coroutine')
    -- A simultaneous dancer/include must retain the normal speed and delay.
    local other=coroutine.create(env.sharedAnimation)
    assert(resume(other)==900 and calls[7][5]==10,'concurrent animation accelerated')
    resume(other);resume(co)
    assert(coroutine.status(co)=='dead')
    assert(calls[#calls][1]=='Spin' and calls[#calls][4]==0.2,'parent spin not restored')
end
local env,calls=environment(true)
env.math=setmetatable({random=function(lo,hi) assert(lo==100 and hi==300);return 175 end},{__index=math})
local co=coroutine.create(function()
    assert(env.runHologramTextFx(env.sharedAnimation,{}, {},{})==1.75)
    env.runHologramTextFx(function()
        assert(env.GetHologramTextFxSpeed()==2)
        env.runHologramTextFx(env.sharedAnimation,{}, {},{},3)
        assert(env.GetHologramTextFxSpeed()==2,'nested effect lost outer rate')
    end,{}, {},{},2)
    assert(env.GetHologramTextFxSpeed()==1)
end)
assert(resume(co)==900/1.75);assert(resume(co)==300);resume(co)
-- Errors terminate only their own coroutine, as in the engine scheduler.
co=coroutine.create(function() env.runHologramTextFx(function() error('injected') end,{}, {},{},3) end)
assert(not coroutine.resume(co));assert(env.GetHologramTextFxSpeed()==1)
local ordinary,ordinaryCalls=environment(false)
co=coroutine.create(function() ordinary.runHologramTextFx(ordinary.sharedAnimation,{}, {},{},3) end)
assert(resume(co)==900 and ordinaryCalls[1][5]==10,'opted-out unit changed')
resume(co)
print('PASS: 1x–3x FX speed, clamps, include dispatch, coroutine isolation, nested rates and parent spin restoration')

-- Run all actual preview cases through the header too. The existing scheduler
-- asserts that final-motion cleanup and five-second pauses remain unscaled.
local source=read('tests/text_fx_test_unit_test.lua')
local marker='function include(file)'
local setup=[[
unitDefID=1;UnitDefs[1]={customParams={text_fx_speed=1}}
Spring.GetUnitTeam=function() return 0 end
for _,name in ipairs({'Move','Turn','Spin','StopSpin','Sleep','Hide','Show',
    'WaitForMove','WaitForTurn','StartThread','Signal','SetSignalMask'}) do
    Spring.UnitScript[name]=_G[name]
end
local function loadWithHeader(path)
    local f=assert(io.open(path));local s=f:read('*a');f:close()
    return assert(loadstring(headerSource..'\n'..s))()
end
]]
local at=assert(source:find(marker,1,true))
source=source:sub(1,at-1)..setup..source:sub(at)
source=source:gsub("return dofile%('scripts/'%.%.file%)", "return loadWithHeader('scripts/'..file)")
source=source:gsub("dofile%('scripts/text_fx_test_script.lua'%)", "loadWithHeader('scripts/text_fx_test_script.lua')")
assert(loadstring(source))()
print('PASS: full 96-case preview at randomized speed with normal five-second pauses')
