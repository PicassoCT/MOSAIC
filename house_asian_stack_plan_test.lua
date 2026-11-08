-- Run from the repository root with Lua 5.1 or later.
-- Exercise the production planner against controlled geometry, not RNG output
-- snapshots: a different valid layout should continue to pass these checks.
VFS = {Include = dofile}
local stacks = dofile('scripts/lib_house_asian_stacks.lua')

local function equal(a,b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function ring(radius)
    local result = {}
    for i=1,16 do result[i] = radius end
    return result
end

local function fixture(families)
    local f = {pieceMap={},catalog={styles={'pod','industrial','trad','office'},groups={}},
        profiles={version=1,unitScale=0.0254,floorHeight=595.4,tolerance=35,directions=16,pieces={}}}
    local serial = 0
    function f.add(name, bottom, top, groundOnly)
        serial = serial + 1
        f.pieceMap[name] = serial
        f.profiles.pieces[name] = {
            bottom=ring(bottom), top=ring(top), groundOnly=groundOnly or false, styles={4},
            fallbackEligible=true,
            min={-math.abs(bottom),0,-math.abs(bottom)},
            max={math.abs(top),595.4,math.abs(top)},
        }
    end
    for family=1,families do
        local prefix = 'ID_u'..(1000+family)..'_Office_Wall'
        local group = {id=prefix:lower(),styles={4},stage='wall',rows=4,columns=1,pieces={}}
        for level=1,4 do
            local name = prefix..level
            group.pieces[level] = name
            -- Distinct interfaces force a coherent choice of authored family.
            f.add(name, family*100, family*100)
        end
        f.catalog.groups[#f.catalog.groups+1] = group
    end
    -- Plenty of unused alternate bases ensures probability checks measure the
    -- user's exception rate rather than candidate exhaustion.
    for n=1,80 do f.add('Office_Floor'..n,100000+n*100,100000+n*100,true) end
    function f.inventory(reverse)
        local map = {}
        local names = {};for name in pairs(f.pieceMap) do names[#names+1] = name end
        table.sort(names,function(a,b) return reverse and a>b or not reverse and a<b end)
        for _,name in ipairs(names) do map[name] = f.pieceMap[name] end
        return stacks.inventory(map,f.catalog,f.profiles)
    end
    return f
end

local perimeter = {1,2,3,4,5,6,7,12,13,18,19,24,25,30,31,32,33,34,35,36}
local function options(f,seed,chance,slots)
    return {inventory=f.inventory(),seed=seed,height=3,groundStyle='office',wallStyle='office',
        slots=slots or perimeter,mismatchChance=chance}
end

local function compatible(f,lower,upper)
    local a,b = assert(f.profiles.pieces[lower]),assert(f.profiles.pieces[upper])
    for k=1,16 do
        if math.abs(a.top[k]-b.bottom[k]) > f.profiles.tolerance then return false end
    end
    return true
end

local function verify(f,result,slots,requireFullHeight)
    local used,indices,columns,mismatches = {},{},0,0
    for _,index in ipairs(slots) do indices[index] = true end
    for index,column in pairs(result.columns) do
        assert(indices[index],'column outside requested footprint')
        columns = columns+1
        assert(column.height == #column.pieces-1,'column height disagrees with pieces')
        assert(column.height >= 1,'unsupported foundation without a tower')
        if requireFullHeight then assert(column.height == 3,'available complete stack was shortened') end
        assert(column.roofHeight==(column.height+1)*f.profiles.floorHeight,
            'ordinary column roof height disagrees with its complete stack')
        assert(type(column.rotation)=='number' and column.rotation%90==0,'invalid structural facing')
        assert(type(column.mismatchedFoundation)=='boolean','missing explicit exception marker')
        assert(type(column.mismatchRequested)=='boolean','missing exception draw result')
        assert(f.pieceMap[column.originalFoundation],'unavailable normal foundation')
        for n,name in ipairs(column.pieces) do
            assert(f.pieceMap[name],'invented piece: '..tostring(name))
            assert(not used[name],'piece allocated to two structural slots: '..name)
            used[name] = true
            assert(result.reserved[name],'planned piece not reserved')
            local level = n-1
            local phase = n==1 and result.layout.floor or result.layout.wall
            assert(phase[level] and phase[level][index]==name,'layout/column disagreement')
            if n>1 then
                assert(not f.profiles.pieces[name].groundOnly,'ground-only piece used above ground')
                if n>2 or not column.mismatchedFoundation then
                    assert(compatible(f,column.pieces[n-1],name),'unmarked non-fitting interface')
                end
            end
        end
        assert(compatible(f,column.originalFoundation,column.pieces[2]),'original base did not fit')
        if column.mismatchedFoundation then
            mismatches = mismatches+1
            assert(column.mismatchRequested,'exception made without a successful draw')
            assert(column.pieces[1]~=column.originalFoundation,'exception kept original base')
            assert(not compatible(f,column.pieces[1],column.pieces[2]),'exception did not make a non-fitting base')
        else
            assert(column.pieces[1]==column.originalFoundation,'foundation changed without exception')
        end
    end
    assert(columns == #slots,'incomplete requested footprint')
    return mismatches,columns
end

local f = fixture(60)
local opts = options(f,24113,0)
local random,randomseed = math.random,math.randomseed
math.random = function() error('structural planner consumed shared RNG') end
math.randomseed = function() error('structural planner reseeded shared RNG') end
local normal = stacks.plan(opts)
assert(verify(f,normal,perimeter,true)==0)
local replay = stacks.plan(opts)
assert(equal(normal,replay),'same inputs changed the structural layout')
opts.inventory = f.inventory(true)
assert(equal(normal,stacks.plan(opts)),'dictionary insertion order changed the layout')

opts.mismatchChance = 1
local different = stacks.plan(opts)
assert(verify(f,different,perimeter,true)==#perimeter,'guaranteed exception was not applied')
for index,a in pairs(normal.columns) do
    local b = different.columns[index]
    assert(a.rotation==b.rotation and a.height==b.height,'foundation exception changed its tower pose')
    assert(a.family==b.family,'foundation exception selected another tower')
    for n=2,#a.pieces do assert(a.pieces[n]==b.pieces[n],'foundation exception changed an upper floor') end
end

-- The default must be a probability per foundation, not a building-wide roll
-- that makes whole neighbourhoods uniformly mismatched. Count a fixed sample;
-- these broad bounds catch 0%, 100%, a 1% typo, and rerolling once per floor.
local mismatches,total,mixedBuildings = 0,0,0
opts.inventory = f.inventory()
opts.mismatchChance = nil
for seed=1,300 do
    opts.seed = seed*104729+7919
    local result = stacks.plan(opts)
    local n,count = verify(f,result,perimeter,true)
    mismatches,total = mismatches+n,total+count
    if n>0 and n<count then mixedBuildings=mixedBuildings+1 end
end
local rate = mismatches/total
assert(rate>0.075 and rate<0.125,'default foundation mismatch rate is not 10%: '..rate)
assert(mixedBuildings>150,'foundation exception appears to be rolled per building')

-- A missing middle piece must never produce a partly matched column. The
-- available complete families are sufficient, so a whole alternative exists.
local missing = fixture(25)
local broken = missing.catalog.groups[1]
missing.pieceMap[broken.pieces[3]] = nil
local missingResult = stacks.plan(options(missing,713,0))
verify(missing,missingResult,perimeter,true)

-- Existing catalogues can predate case, numeric-padding, and suffix-separator
-- changes in an artist's re-export. Resolve to actual names without inventing
-- pieces or confusing a member numbered 1 with a distinct member numbered 101.
local renamed = fixture(2)
local renamedGroup = renamed.catalog.groups[1]
for row=1,4 do renamedGroup.pieces[row]='ID_u01001_office_wALL_'..string.format('%02d',row) end
renamed.add('ID_u1001_Office_Wall101',100,100)
local renamedOptions=options(renamed,739,0,{1})
renamedOptions.featured=renamedGroup
local renamedResult=stacks.plan(renamedOptions)
verify(renamed,renamedResult,{1},true)
for row,name in ipairs(renamedResult.columns[1].pieces) do
    assert(name=='ID_u1001_Office_Wall'..row,'catalog alias resolved to the wrong member')
end

-- A shared generic name prefix is not proof of compatibility. These four
-- unrelated pieces cannot form one coherent tower; a complete fitting path is
-- available under other names. Authored components remain separate contracts.
local wrongShape = fixture(0)
for n=1,4 do
    wrongShape.add('Office_Wall'..n,n*100,n*100)
    wrongShape.add('Office_Block'..n,77,77)
end
verify(wrongShape,stacks.plan(options(wrongShape,83,0,{2})),{2},true)

-- Conversely, compatible generic pieces may form a stack even when their names
-- have no shared family token. Ground-only pieces belong exclusively at base.
local generic = fixture(0)
generic.add('Office_Shop1',77,77,true)
generic.add('Office_Apartment1',77,77)
generic.add('Office_Workshop1',77,77)
generic.add('Office_Studio1',77,77)
local genericResult = stacks.plan(options(generic,592,0,{2}))
verify(generic,genericResult,{2},true)

-- A multi-column authored component must retain its ordering and one facade
-- orientation, including the corner at index 1. Test with exceptions disabled
-- because the user deliberately allows a replacement of its foundation.
local featured = fixture(25)
local group = {id='id_a9000_office_wall',styles={4},stage='wall',rows=4,columns=2,pieces={}}
for n=1,8 do
    local name = 'ID_a9000_Office_Wall'..n
    group.pieces[n]=name
    local radius = 200000+math.floor((n-1)/4)*100
    featured.add(name,radius,radius)
end
featured.catalog.groups[#featured.catalog.groups+1] = group
local featuredOptions = options(featured,2026,0)
featuredOptions.featured = group
local featuredResult = stacks.plan(featuredOptions)
verify(featured,featuredResult,perimeter,true)
for column=1,2 do
    for row=1,4 do
        assert(featuredResult.columns[column].pieces[row]==group.pieces[(column-1)*4+row],
            'featured component lost its authored ordering')
    end
end
assert(featuredResult.columns[1].rotation==featuredResult.columns[2].rotation,
    'featured component split across corner orientations')

-- A six-wide featured roof fixes both front corners to the front facade.
-- A two-wide wall must choose a compatible face before placement; changing
-- only the corner column afterwards tears that authored component apart.
local roof = {id='id_l9900_office_roof',styles={4},stage='roof',rows=1,columns=6,pieces={}}
for column=1,6 do
    local name='ID_l9900_Office_Roof'..column
    roof.pieces[column]=name
    featured.add(name,300000,300000)
end
featured.catalog.groups[#featured.catalog.groups+1]=roof
local roofOptions=options(featured,2,0)
roofOptions.featured=roof
for seed=1,24 do
    roofOptions.seed=seed
    local result=stacks.plan(roofOptions)
    verify(featured,result,perimeter,true)
    local wallFacing,wallColumns=nil,0
    for _,column in pairs(result.columns) do
        if column.family==group.id then
            wallColumns=wallColumns+1
            wallFacing=wallFacing or column.rotation
            assert(column.rotation==wallFacing,'featured roof split a multi-column wall orientation')
        end
    end
    assert(wallColumns==2,'compatible two-wide wall placement was lost')
    for index=1,6 do
        assert(result.columns[index].rotation==180,'featured roof support faces another facade')
        assert(result.layout.roof[4][index]==roof.pieces[index],'featured roof ordering changed')
    end
end

-- Some authored shopfront components occupy more than one nominal storey and
-- have no compatible upper socket. Keep them intact and clear their real top
-- with the roof, rather than placing a cap through the middle of the mesh.
local tall=fixture(0)
local tallName='ID_l9901_Office_Floor1'
tall.add(tallName,400000,400000,true)
tall.profiles.pieces[tallName].max[2]=1213.75
local tallGroup={id='id_l9901_office_floor',styles={4},stage='floor',rows=1,columns=1,pieces={tallName}}
tall.catalog.groups[#tall.catalog.groups+1]=tallGroup
local tallOptions=options(tall,619,0,{1})
tallOptions.featured=tallGroup
local tallColumn=stacks.plan(tallOptions).columns[1]
assert(tallColumn.height==0 and tallColumn.pieces[1]==tallName,'tall authored shopfront was altered')
assert(tallColumn.roofHeight==tall.profiles.pieces[tallName].max[2],
    'roof clips an authored shopfront taller than one nominal storey')

-- A deliberate footprint exception must still fit below the first upper
-- storey. If only an oversized alternate base exists, leave the fitting base.
local tallAlternate=fixture(1)
for n=1,80 do tallAlternate.pieceMap['Office_Floor'..n]=nil end
tallAlternate.add('Office_TallFloor1',800000,800000,true)
tallAlternate.profiles.pieces.Office_TallFloor1.max[2]=1213.75
local bounded=stacks.plan(options(tallAlternate,831,1,{1})).columns[1]
assert(bounded.mismatchRequested and not bounded.mismatchedFoundation,
    'oversized alternate shopfront was inserted into an intact tower')
assert(bounded.pieces[1]==bounded.originalFoundation,'unsafe exception changed the foundation')

math.random,math.randomseed = random,randomseed
print(string.format('PASS: complete structural paths, unique pieces, compatible interfaces, deterministic poses, %.2f%% foundation exceptions',rate*100))

-- Half of each office-style footprint regains the original shopfront pool.
-- Compatibility filtering must not silently turn it back into tower bottoms.
local shops=fixture(60)
local baseOptions=options(shops,831,0)
local intact=stacks.plan(baseOptions)
baseOptions.legacyGroundFraction=.5
baseOptions.legacyGroundNames={}
for n=1,80 do baseOptions.legacyGroundNames[n]='Office_Floor'..n end
local mixed=stacks.plan(baseOptions)
assert(mixed.legacyFoundationCount==10 and mixed.legacyFoundationTarget==10)
local restored,used=0,{}
for index,column in pairs(mixed.columns)do
    if column.legacyFoundation then
        restored=restored+1
        assert(column.pieces[1]:find('Office_Floor',1,true)==1)
        assert(not column.mismatchRequested)
    else assert(column.pieces[1]==intact.columns[index].pieces[1]) end
    for row=2,#column.pieces do assert(column.pieces[row]==intact.columns[index].pieces[row],'shopfront changed upper stack') end
    assert(column.rotation==intact.columns[index].rotation and column.roofHeight==intact.columns[index].roofHeight)
    for _,name in ipairs(column.pieces)do assert(not used[name]);used[name]=true end
end
assert(restored==10 and equal(mixed,stacks.plan(baseOptions)),'half-building restoration is not deterministic')
baseOptions.legacyGroundFraction=0
assert(equal(intact,stacks.plan(baseOptions)),'disabled restoration changed another building style')
print('PASS: exactly half the street slots restore shops; upper stacks, roof heights, unique pieces and deterministic planning remain intact')

-- Ground-culture presets have distinct quotas; industrial exceptions cannot
-- introduce shopfronts on a straight facade even with forced mismatch draws.
for _,style in ipairs({'trad','office','pod','industrial'})do
    local policy=stacks.shopfrontPolicies[style]
    baseOptions.legacyGroundFraction=policy.fraction
    baseOptions.legacyGroundCornersOnly=policy.cornersOnly
    baseOptions.mismatchChance=1
    local result=stacks.plan(baseOptions)
    local expected=style=='industrial' and 4 or math.floor(#perimeter*policy.fraction)
    assert(result.legacyFoundationCount==expected,style..' quota is wrong')
    for index,column in pairs(result.columns)do
        if style=='industrial' and index~=1 and index~=6 and index~=31 and index~=36 then
            assert(not column.legacyFoundation and not column.mismatchedFoundation,'industrial non-corner changed')
        end
    end
end
print('PASS: traditional/office/pod quotas and industrial corner-only restoration including mismatch gating')
