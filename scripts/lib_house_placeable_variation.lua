-- Dedicated deterministic randomness. All integer intermediates remain below
-- 2^24, including on Recoil's float32 Lua builds. Never touch math.random.
local M = {}
function M.hash(seed, text)
    local value = seed % 524287
    for i=1,#text do value = (value*31 + text:byte(i)) % 524287 end
    return value
end

function M.typeKey(name, prop)
    -- Labels identify the same authored prop across the modular and standalone
    -- catalogs (whose numbering and zero padding differ). Explicit IDs can
    -- override labels if future catalogs use different names for the same type.
    return prop.typeKey or prop.label or name
end

function M.order(pool, catalogue, seed, getUses)
    table.sort(pool, function(a,b) return a.name < b.name end)
    local random = seed % 65536
    for i=#pool,2,-1 do
        random = (random*253 + 13849) % 65536
        local j = 1 + math.floor(random/65536*i)
        pool[i],pool[j] = pool[j],pool[i]
    end
    for rank,item in ipairs(pool) do
        item.typeKey = M.typeKey(item.name, catalogue.pieces[item.name])
        item.uses = getUses(item.typeKey)
        item.rank = rank
    end
    table.sort(pool, function(a,b)
        if a.uses ~= b.uses then return a.uses < b.uses end
        return a.rank < b.rank
    end)
end
return M
