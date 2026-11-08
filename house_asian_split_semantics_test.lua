-- Run with Lua 5.1+. Exercise the actual inheritance and gameplay registries.
local function loadEnv(path,env)
    local f
    if setfenv then f=assert(loadfile(path));setfenv(f,env)
    else f=assert(loadfile(path,'t',env)) end
    return f()
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function noop() end
-- gamedata/system.lua is supplied by the engine's basecontent archive.
local function lowerkeys(t)
    local moved={}
    for k,v in pairs(t) do
        if type(v)=='table' then lowerkeys(v) end
        if type(k)=='string' and k~=k:lower() then moved[k:lower()]=v;t[k]=nil end
    end
    for k,v in pairs(moved) do t[k]=v end
    return t
end
local env={Spring={GetModOptions=function() return {} end},RecursiveFileSearch=function() return {} end}
setmetatable(env,{__index=_G});env._G=env
env.VFS={Include=function(path)
    if path=='gamedata/system.lua' then return {lowerkeys=lowerkeys} end
    if path=='gamedata/sidedata.lua' then return {} end
end}
loadEnv('gamedata/unitdefs_pre.lua',env)
env.Building=loadEnv('baseclasses/units/Buildings.lua',env).Building
local definitions=loadEnv('units/neutral/house_asian.lua',env)
local base=definitions.house_asian0
local defs, byName, variants={}, {}, {}
for a=1,4 do for b=a,4 do
    local name='house_asian_split_'..a..'_'..b
    local def=assert(definitions[name])
    assert(def.objectname==name..'.dae')
    local model=assert(io.open('objects3d/'..def.objectname,'rb'));model:close()
    assert(def.customparams.house_asian_base=='house_asian0')
    assert(def.customparams.house_asian_style_a==a and def.customparams.house_asian_style_b==b)
    for k,v in pairs(base) do
        if k=='customparams' then
            for key,value in pairs(v) do assert(equal(def[k][key],value),'custom parameter changed') end
        elseif k~='objectname' then
            assert(equal(def[k],v), 'gameplay inheritance changed: '..k)
        end
    end
    local id=#defs+1
    defs[id]={id=id,name=name,customParams=def.customparams,buildOptions={}}
    byName[name]=defs[id];variants[id]=true
end end
for _,name in ipairs({'house_asian0','house_asian1','house_asian2','house_asian3','house_asian4',
    'house_arab0','house_western0','house_ruin','protagonsafehouse','antagonsafehouse',
    'nimrod','propagandaserver','protagonassembly','antagonassembly','launcher','hivemind','warheadfactory'}) do
    local id=#defs+1;defs[id]={id=id,name=name,buildOptions={}};byName[name]=defs[id]
end
-- lib_mosaic has a small amount of module initialization; supply actual runtime
-- shape and load its real helpers, rather than copying the registry logic.
local lib={GG={InstanceCulture='international',AllCultures={international='international'}},
    Game={mapName='test',mapSizeX=8192,mapSizeZ=8192},UnitDefs=defs,UnitDefNames=byName,
    Spring={GetModOptions=function() return {} end},VFS={Include=noop}}
setmetatable(lib,{__index=_G})
loadEnv('scripts/lib_UnitScript.lua',lib)
loadEnv('scripts/lib_mosaic.lua',lib)
local registries={lib.getHouseTypeTable(defs,'international'),
    lib.getCultureUnitModelTypes('international','house',defs),
    lib.getHouseTypeTable(defs,'asian'),lib.getClimbableHouseTypeTable(defs),
    lib.getWindowBuildingTypes(defs),lib.getRaidAbleTypeTable(defs)}
for _,registry in ipairs(registries) do
    for id in pairs(variants) do assert(registry[id], 'variant missing from a house gameplay registry') end
end
local arab=lib.getHouseTypeTable(defs,'arabic')
for id in pairs(variants) do assert(not arab[id], 'changed culture eligibility') end
print('PASS: UnitDef inheritance, model references, culture/house/raid/roof/window registries')
