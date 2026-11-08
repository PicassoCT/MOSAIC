local function section(path, first, last)
    local f = assert(io.open(path))
    local s = f:read('*a')
    f:close()
    local a = assert(s:find(first, 1, true))
    return s:sub(a, last and assert(s:find(last, a + #first, true)) - 1 or #s)
end

local function execute(source, env)
    setmetatable(env, {__index = _G})
    local fn
    if setfenv then
        fn = assert(loadstring(source))
        setfenv(fn, env)
    else
        fn = assert(load(source, 'test', 't', env))
    end
    fn()
end

local names = {
    'Roof01Sub02',
    'Roof1Sub3',
    'ClassicWhiteOffice_Roof_Deco05Sub01',
    'ID_l100_Industrial_RoofBlock01Sub027',
    'StreetDeco06',
    'StreetDeco7',
}

local pieceMap = {}
for index, name in ipairs(names) do
    pieceMap[name] = 100 + index
end

local env = {
    unitID = 1,
    lib_boolDebug = false,
    Spring = {
        GetUnitPieceList = function() return names end,
        GetUnitPieceMap = function() return pieceMap end,
        Echo = function() end,
    },
}

execute(section(
    'scripts/lib_UnitScript.lua',
    'local function canonicalPieceGroupName',
    '-- >generates a Pieces List'
), env)

local groups = env.getPieceTableByNameGroups(false, true)

assert(groups.Roof1Sub[2] == pieceMap.Roof01Sub02)
assert(groups.Roof1Sub[3] == pieceMap.Roof1Sub3)
assert(groups.ClassicWhiteOffice_Roof_Deco5Sub[1] == pieceMap.ClassicWhiteOffice_Roof_Deco05Sub01)
assert(groups.ID_l100_Industrial_RoofBlock1Sub[27] == pieceMap.ID_l100_Industrial_RoofBlock01Sub027)
assert(groups.StreetDeco[6] == pieceMap.StreetDeco06)
assert(groups.StreetDeco[7] == pieceMap.StreetDeco7)
assert(groups.Roof01Sub == nil, 'padded group alias leaked into canonical table')
assert(groups.ClassicWhiteOffice_Roof_Deco05Sub == nil, 'embedded zero padding was retained')

print('PASS piece groups: numeric zero padding is ignored while exact source names remain resolvable')
