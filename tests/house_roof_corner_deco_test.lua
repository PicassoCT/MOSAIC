local function section(path, first, last)
    local f = assert(io.open(path))
    local s = f:read('*a')
    f:close()
    local a = assert(s:find(first, 1, true))
    local b = last and assert(s:find(last, a + #first, true)) or (#s + 1)
    return s:sub(a, b - 1), s
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

local function contains(t, value)
    for _, v in ipairs(t or {}) do if v == value then return true end end
    return false
end

local function checkAsian()
    local source, whole = section(
        'scripts/house_asian_script.lua',
        'local roofCornerPlanIndices',
        'materialChoiceTable ='
    )
    local names = {
        [1] = 'Office_Roof_Deco1',
        [11] = 'Office_Pod_Wall_Block11',
        [12] = 'Office_Pod_Wall_Block12',
        [13] = 'Office_Pod_Wall_Block13',
        [14] = 'Office_Pod_Wall_Block14',
        [15] = 'Office_Pod_Wall_Block15',
        [16] = 'Office_Pod_Wall_Block16',
    }
    local reverse = {}
    for id, name in pairs(names) do reverse[name] = id end
    local env = {
        pieceID_NameMap = names,
        pieceName_pieceNr = reverse,
        reservedSplitPieces = {},
        splitPhase = nil,
    }
    execute(source, env)

    for _, index in ipairs({1, 6, 31, 36}) do assert(env.isRoofPlanCorner(index)) end
    for _, index in ipairs({2, 5, 7, 30, 32, 35}) do assert(not env.isRoofPlanCorner(index)) end
    for id = 11, 16 do assert(env.isCornerRoofDecoPiece(id), names[id]) end
    assert(not env.isCornerRoofDecoPiece(1))

    local office = env.addAsianRoofCornerDecoPieces({1}, 'office')
    for id = 11, 16 do assert(contains(office, id), 'Asian corner piece not admitted: '..names[id]) end
    local pod = env.addAsianRoofCornerDecoPieces({1}, 'pod')
    for id = 11, 16 do assert(contains(pod, id), 'Asian pod corner piece not admitted: '..names[id]) end
    local industrial = env.addAsianRoofCornerDecoPieces({1}, 'industrial')
    assert(#industrial == 1 and industrial[1] == 1, 'Asian corner pieces leaked into unrelated style')

    local edge = env.getRoofDecoMaterialForPlanIndex(office, 2)
    for id = 11, 16 do assert(not contains(edge, id), 'Asian corner piece leaked onto edge') end
    local corner = env.getRoofDecoMaterialForPlanIndex(office, 1)
    for id = 11, 16 do assert(contains(corner, id), 'Asian corner rejected corner piece') end

    env.splitPhase = nil
    assert(not env.isCornerRoofDecoAllowed(11, 1), 'Asian corner piece allowed during wall construction')
    env.splitPhase = 'roof'
    assert(env.isCornerRoofDecoAllowed(11, 1), 'Asian corner piece rejected from roof corner')
    assert(not env.isCornerRoofDecoAllowed(11, 2), 'Asian corner piece allowed on roof edge')

    assert(whole:find('decoMaterial = addAsianRoofCornerDecoPieces(decoMaterial, materialColourName)', 1, true))
    assert(whole:find('getRoofDecoMaterialForPlanIndex(decoMaterial, index)', 1, true))
    assert(whole:find('isCornerRoofDecoAllowed(piecenum, index)', 1, true))
end

local function checkWestern()
    local source, whole = section(
        'scripts/house_western_script.lua',
        'local roofCornerPlanIndices',
        'function addRoofDeocrate'
    )
    local names = {[1] = 'Office_Roof_Deco1'}
    for id = 19, 27 do names[id] = 'WhiteOffice_Roof_Deco'..id end
    local env = {pieceNr_pieceName = names}
    execute(source, env)

    for id = 19, 27 do assert(env.isCornerRoofDecoPiece(id), names[id]) end
    assert(not env.isCornerRoofDecoPiece(1))

    local material = {1}
    for id = 19, 27 do material[#material + 1] = id end
    local edge = env.getRoofDecoMaterialForPlanIndex(material, 2)
    assert(#edge == 1 and edge[1] == 1, 'Western corner deco leaked onto roof edge')
    local corner = env.getRoofDecoMaterialForPlanIndex(material, 36)
    for id = 19, 27 do assert(contains(corner, id), 'Western corner rejected corner deco') end

    assert(whole:find('getRoofDecoMaterialForPlanIndex(decoMaterial, i)', 1, true))
end

checkAsian()
checkWestern()
print('PASS roof corner deco: exported Asian and Western corner pieces are corner-only')
