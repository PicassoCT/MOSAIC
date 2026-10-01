-- Lua 5.1+: no engine required. Lock values, schema and per-instance evaluation.
local f=assert(io.open('scripts/lib_mosaic.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('function getGameConfig()',1,true))
local last=assert(source:find('   function getAllCultures',first,true))
local expected=dofile('tests/fixtures/game_config_expected.lua')
local code=source:sub(first,last-1)
local roots={game=true,city=true,civilians=true,police=true,economy=true,
    objectives=true,espionage=true,military=true,presentation=true,performance=true}
local function loadConfig(env)
    local fn
    if setfenv then fn=assert(loadstring(code));setfenv(fn,env)
    else fn=assert(load(code,'game config','t',env))end
    fn();return env.getGameConfig()
end
local count=0
for _,factor in ipairs({0,.35,.8,1,2})do
    for _,culture in ipairs({'arabic','asian','western','international'})do
        local env=setmetatable({GG={unitFactor=factor},GameVersion='test-version',
            getInstanceCultureOrDefaultToo=function()return culture end},{__index=_G})
        local config=loadConfig(env)
        local flat={}
        local function walk(t,path)
            assert(getmetatable(t)==nil,'configuration must be plain data, without compatibility proxies')
            for key,value in pairs(t)do
                assert(type(key)=='string' and key:match('^[a-z][a-zA-Z0-9]*$'),'nonstandard key: '..key)
                local name=path=='' and key or path..'.'..key
                if type(value)=='table' then walk(value,name)else flat[name]=value end
            end
        end
        for key in pairs(config)do assert(roots[key],'unexpected/legacy root '..key)end
        for key in pairs(roots)do assert(config[key],'missing section '..key)end
        walk(config,'')
        local values=expected(factor,culture,'test-version')
        for path,value in pairs(values)do assert(flat[path]==value,path..' changed');flat[path]=nil end
        assert(next(flat)==nil,'unaccounted config value')
        -- getGameConfig continues to create independent tables and evaluate
        -- the current unit factor and culture, as it did before migration.
        config.espionage.cybercrime.payoutMoney=-1
        local another=env.getGameConfig()
        assert(another.espionage.cybercrime.payoutMoney==25)
        count=count+1
    end
end
print('Game config: 209 settings, 20 factor/culture combinations, plain new schema and independent instances PASS')
