-- Run with Lua 5.1+ (or texlua). Exercise real culture/type helpers, not copies.
local function loadEnv(path, env)
    local chunk
    if setfenv then chunk = setfenv(assert(loadfile(path)), env)
    else chunk = assert(loadfile(path, 't', env)) end
    return chunk()
end

local defs, byName, families = {}, {}, {}
local function add(name, params)
    local id = #defs + 1
    defs[id] = {id=id, name=name, customParams=params or {}, buildOptions={}}
    byName[name] = defs[id]
end
local function family(name, last)
    families[name] = {}
    for i=0,last do
        local unitName = name .. i
        add(unitName)
        families[name][unitName] = true
    end
end
family('house_arab', 0); family('house_western', 0); family('house_asian', 4)
family('truck_arab', 9); family('truck_western', 4)
family('civilian_arab', 5); family('civilian_western', 4)
add('civilian_worker_western'); add('civilian_courier_asian')
add('house_ruin')
for _, name in ipairs({'house_asian_split_1_1', 'house_asian_split_1_2'}) do
    add(name, {house_asian_base='house_asian0'})
    families.house_asian[name] = true
end
-- Unrelated/out-of-range units must never enter these pools either.
add('vehiclecorpse'); add('gcscrapheap'); add('truck_arab99'); add('civilian_western99')
for _, name in ipairs({'protagonsafehouse','antagonsafehouse','nimrod','propagandaserver',
    'protagonassembly','antagonassembly','launcher','hivemind','warheadfactory'}) do add(name) end

local env = {arg=false, GG={InstanceCulture='international', AllCultures={international='international'}},
    Game={mapName='test', mapSizeX=8192, mapSizeZ=8192},
    UnitDefs=defs, UnitDefNames=byName,
    Spring={GetModOptions=function() return {} end, Echo=function() end}, VFS={Include=function() end}}
setmetatable(env, {__index=_G}); env._G=env
loadEnv('scripts/lib_UnitScript.lua', env)
loadEnv((arg and arg[1]) or 'scripts/lib_mosaic.lua', env)
loadEnv('scripts/lib_staticstring.lua', env)

local culturalFamilies = {
    arabic={house={'house_arab'}, truck={'truck_arab'}, civilian={'civilian_arab'}},
    western={house={'house_western'}, truck={'truck_western'}, civilian={'civilian_western'}},
    asian={house={'house_asian'}, truck={'truck_western'}, civilian={'civilian_arab'}},
    international={house={'house_arab','house_western','house_asian'},
        truck={'truck_arab','truck_western'}, civilian={'civilian_arab','civilian_western'}},
}
local function expected(culture, kind)
    local result = {}
    for _, name in ipairs(culturalFamilies[culture][kind]) do
        for unitName in pairs(families[name]) do result[unitName] = true end
    end
    if kind == 'house' then result.house_ruin = true end
    if kind == 'civilian' then
        if culture == 'western' or culture == 'international' then
            result.civilian_worker_western = true
        end
        if culture == 'asian' or culture == 'international' then
            result.civilian_courier_asian = true
        end
    end
    return result
end
local function checkMap(label, actual, wanted)
    for id in pairs(actual) do
        local name = assert(defs[id], label .. ': invalid unit ID').name
        assert(wanted[name], label .. ': unexpected ' .. name)
    end
    for name in pairs(wanted) do
        assert(actual[byName[name].id], label .. ': missing ' .. name)
    end
end

for _, culture in ipairs({'arabic','western','asian','international'}) do
    env.GG.InstanceCulture = culture
    env.GG.GameConfig.game.culture = culture
    for _, kind in ipairs({'house','truck','civilian'}) do
        local label, wanted = culture .. '/' .. kind, expected(culture, kind)
        checkMap(label .. ' names', env.getCultureUnitModelNames_Dict_DefIDName(culture, kind, defs), wanted)
        checkMap(label .. ' spawn IDs', env.getCultureUnitModelTypes(culture, kind, defs), wanted)
        local names = {}
        for _, name in ipairs(env.getTypeUnitNameTable(culture, kind, defs)) do
            assert(byName[name] and not names[byName[name].id], label .. ': invalid/duplicate name')
            names[byName[name].id] = true
        end
        checkMap(label .. ' name list', names, wanted)
    end
    local plotHouses = expected(culture, 'house')
    plotHouses.house_ruin = nil
    plotHouses.house_asian_split_1_1 = nil
    plotHouses.house_asian_split_1_2 = nil
    checkMap(culture .. ' ordinary city plot lottery',
        env.getCityHouseSpawnTypeTable(culture, defs), plotHouses)
    local mobile = expected(culture, 'civilian')
    for name in pairs(expected(culture, 'truck')) do mobile[name] = true end
    checkMap(culture .. ' mobile civilians', env.getMobileCivilianDefIDTypeTable(defs), mobile)
    checkMap(culture .. ' pedestrians', env.getPanicableCiviliansTypeTable(defs), expected(culture, 'civilian'))
    local male = env.getCivlianDisguiseBySexTypeTable(defs, 'male')
    local female = env.getCivlianDisguiseBySexTypeTable(defs, 'female')
    local worker, courier = byName.civilian_worker_western.id, byName.civilian_courier_asian.id
    assert((male[worker] ~= nil) == (culture == 'western' or culture == 'international'),
        culture .. ': worker disguise does not match the ordinary population')
    assert((female[courier] ~= nil) == (culture == 'asian' or culture == 'international'),
        culture .. ': courier disguise does not match the ordinary population')
    assert(not female[worker] and not male[courier], culture .. ': wrong sex in occupational disguises')
    assert(env.getUnitType_BaseTypeMap(defs, culture).house_ruin == 'house',
        culture .. ': ruin incorrectly classified as traffic/pedestrian')
end
-- Naming must follow the model rather than the unrelated unit-ID parity fallback.
env.Spring.GetUnitDefID = function(id)
    return id <= 2 and byName.civilian_worker_western.id or byName.civilian_courier_asian.id
end
assert(env.getCivilianSex(1, defs) == 'male' and env.getCivilianSex(2, defs) == 'male')
assert(env.getCivilianSex(3, defs) == 'female' and env.getCivilianSex(4, defs) == 'female')
local ruinCandidates = expected('international', 'house')
ruinCandidates.house_ruin = nil
checkMap('intact and variant plots eligible for war damage',
    env.getCityRuinCandidateTypeTable(defs), ruinCandidates)
checkMap('war ruin choices', env.getCityRuinTypeTable(defs), {house_ruin=true})
assert(env.getBuildingScrapHeapTypeTable(defs)[byName.house_ruin.id], 'lost reconstruction rubble option')
assert(env.getBuildingRuinTypeTable(defs)[byName.house_ruin.id], 'lost ruin property membership')
print('PASS: culture pools preserve existing families and add matching occupational spawns, disguises and names')
