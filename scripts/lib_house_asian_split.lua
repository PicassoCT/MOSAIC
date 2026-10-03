-- Pure, synced-safe pre-spawn planning. No unit IDs, RNG calls or table-order
-- dependence. A plan is only committed after CreateUnit succeeds.
local catalog = VFS.Include("scripts/house_asian_split_catalog.lua")
local M = {catalog = catalog}

local function hash(text)
    local value = 0
    for i = 1, #text do value = (value * 31 + string.byte(text, i)) % 2147483647 end
    return value
end

function M.seed(x, z, mapName)
    return hash((mapName or "") .. ":" .. math.floor(x * 16) .. ":" .. math.floor(z * 16))
end

function M.variantName(a, b)
    return "house_asian_split_" .. math.min(a, b) .. "_" .. math.max(a, b)
end

function M.newState()
    return {used = {}}
end

local function makePlan(primary, secondary, seed, group)
    return {
        unitName = M.variantName(primary, secondary),
        groundStyle = catalog.styles[primary],
        wallStyle = catalog.styles[group and primary or secondary],
        roofStyle = catalog.styles[secondary],
        height = group and group.rows == 4 and 3 or 2 + seed % 2,
        group = group,
        seed = seed,
    }
end

function M.choose(state, x, z, mapName)
    local seed = M.seed(x, z, mapName)
    local group
    -- Exhaust complete authored components before ordinary recombination.
    -- Read-only selection makes failed spawns retryable without consuming one.
    for offset = 0, #catalog.groups - 1 do
        local candidate = catalog.groups[(seed + offset) % #catalog.groups + 1]
        if not state.used[candidate.id] then group = candidate; break end
    end
    local primary = (math.ceil(x / 1000) + math.ceil(z / 1000)) % 4 + 1
    if group then primary = group.styles[seed % #group.styles + 1] end
    local secondary = primary
    if math.floor(seed / 7) % 2 == 1 then
        secondary = (primary - 1 + 1 + math.floor(seed / 17) % 3) % 4 + 1
    end
    -- A roof component must use a style in which that component exists.
    if group and group.stage == "roof" then primary, secondary = secondary, primary end
    return makePlan(primary, secondary, seed, group)
end

function M.commit(state, plan)
    if plan.group then state.used[plan.group.id] = true end
end

function M.forVariant(a, b, x, z, mapName)
    local seed = M.seed(x, z, mapName)
    if seed % 2 == 1 then a, b = b, a end
    return makePlan(a, b, seed)
end

-- Return reserved pieces by phase -> level -> perimeter index. All coherent
-- blocks occupy the first straight facade, so corners never split a component.
function M.layout(plan)
    local layout, reserved = {floor = {}, wall = {}, roof = {}}, {}
    local group = plan.group
    if not group then return layout, reserved end
    for n, name in ipairs(group.pieces) do
        local row = (n - 1) % group.rows
        local column = math.floor((n - 1) / group.rows) + 1
        local phase = group.stage
        local level = phase == "roof" and plan.height + 1 or row
        if phase == "wall" and row == 0 then phase = "floor" end
        layout[phase][level] = layout[phase][level] or {}
        layout[phase][level][column] = name
        reserved[name] = true
    end
    return layout, reserved
end

return M
