-- lua tests/house_asian_split_test.lua (Lua 5.1 and newer)
VFS = {Include = dofile}
local planner = dofile('scripts/lib_house_asian_split.lua')
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

-- Independent states with different dictionary insertion order / RNG history
-- must make exactly the same selections for the same successful spawn stream.
local a, b = planner.newState(), planner.newState()
local seen, variants = {}, {}
local random, randomseed = math.random, math.randomseed
math.random = function() error('planner must not consume global RNG') end
math.randomseed = function() error('planner must not reseed global RNG') end
for i=1,#planner.catalog.groups + 1000 do
    local x,z = (i * 773) % 8192 + 0.5, (i * 431) % 8192 + 0.25
    local pa, pb = planner.choose(a,x,z,'LastDayOfDhubai'), planner.choose(b,x,z,'LastDayOfDhubai')
    assert(equal(pa,pb), 'non-deterministic plan')
    assert(equal(pa,planner.choose(a,x,z,'LastDayOfDhubai')), 'failed spawn consumed a group')
    variants[pa.unitName] = true
    if i <= #planner.catalog.groups then
        assert(pa.group and not seen[pa.group.id], 'group skipped or repeated before exhaustion')
        seen[pa.group.id] = true
        local layout, reserved = planner.layout(pa)
        local count = 0
        for phase, levels in pairs(layout) do
            for level, slots in pairs(levels) do
                for index,name in pairs(slots) do
                    assert(index >= 1 and index <= 6, 'component crosses facade corner')
                    assert(level <= pa.height + 1 and reserved[name])
                    if phase=='floor' then assert(level==0) end
                    if phase=='roof' then assert(level==pa.height+1) end
                    count = count + 1
                end
            end
        end
        assert(count == #pa.group.pieces, 'incomplete component')
    else
        assert(not pa.group, 'ordinary recombination did not begin after exhaustion')
    end
    planner.commit(a,pa)
    -- Rebuild the used dictionary backwards to catch iteration-order coupling.
    planner.commit(b,pb)
    local keys = {}; for key in pairs(b.used) do keys[#keys+1]=key end
    table.sort(keys, function(x,y) return x>y end)
    local used={};for _,key in ipairs(keys) do used[key]=true end;b.used=used
end
math.random, math.randomseed = random, randomseed
local count=0;for _ in pairs(variants) do count=count+1 end
assert(count==10, 'selection did not cover all four pure and six pair variants')
for x=1,4 do for y=x,4 do
    local p=planner.forVariant(x,y,123,456,'map')
    assert(p.unitName==planner.variantName(x,y) and not p.group)
    assert(equal(p,planner.forVariant(x,y,123,456,'map')))
end end
print('PASS: deterministic pre-spawn plans, failed-spawn retry, 95 coherent groups, 10 variants')
