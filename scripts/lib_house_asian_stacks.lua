-- Plan structural columns before any piece is moved. Names, never dictionary
-- ordinals, identify an authored component. Randomness is local to this plan.
local catalog = VFS.Include("scripts/house_asian_split_catalog.lua")
local profiles = VFS.Include("scripts/house_asian_stack_profiles.lua")
local M = {}
local styles = {"pod", "industrial", "trad", "office"}

local function key(name)
    local normalized = name:lower():gsub("_(%d+)", "%1")
    return (normalized:gsub("%d+", function(n) return tostring(tonumber(n)) end))
end

local function hash(seed, label)
    local value = seed % 2147483647
    for i = 1, #label do value = (value * 31 + label:byte(i)) % 2147483647 end
    -- Mix the final character too: adjacent perimeter indices must not share
    -- nearly identical probability draws. Products remain exact in Lua doubles.
    value = (value * 48271) % 2147483647
    return (value * 48271) % 2147483647
end

local function sortedKeys(t)
    local result = {}
    for name in pairs(t or {}) do result[#result + 1] = name end
    table.sort(result)
    return result
end

local function hasStyle(name, style)
    return not style or name:lower():find(style, 1, true) ~= nil
end

local function copy(t)
    local result = {}
    for i, value in ipairs(t or {}) do result[i] = value end
    return result
end

function M.compatible(lower, upper, tolerance)
    if not lower or not upper or not lower.top or not upper.bottom then return false end
    if #lower.top == 0 or #lower.top ~= #upper.bottom then return false end
    for i, value in ipairs(lower.top) do
        if math.abs(value - upper.bottom[i]) > tolerance then return false end
    end
    return true
end

function M.inventory(pieceMap, componentCatalog, socketProfiles)
    componentCatalog, socketProfiles = componentCatalog or catalog, socketProfiles or profiles
    local inv = {names = sortedKeys(pieceMap), resolve = {}, groups = {}, profiles = {},
        nextPieces = {}, authoredNext = {}, ground = {}, paths = {},
        tolerance = socketProfiles.tolerance or 35,
        floorHeight = socketProfiles.floorHeight or 595.4}
    local exact = {}
    for _, name in ipairs(inv.names) do
        exact[name] = true
        local canonical = key(name)
        -- An ambiguous alias must never silently bind to a different piece.
        if inv.resolve[canonical] then inv.resolve[canonical] = false
        elseif inv.resolve[canonical] == nil then inv.resolve[canonical] = name end
    end
    function inv.name(name) return exact[name] and name or inv.resolve[key(name)] end
    for name, profile in pairs(socketProfiles.pieces or {}) do
        local actual = inv.name(name)
        if actual then inv.profiles[actual] = profile end
    end
    for _, group in ipairs(componentCatalog.groups or {}) do
        local resolved, complete = {}, true
        for _, name in ipairs(group.pieces) do
            local actual = inv.name(name)
            if not actual then complete = false; break end
            resolved[#resolved + 1] = actual
        end
        if complete then
            local entry = {id = group.id, rows = group.rows, columns = group.columns,
                stage = group.stage, pieces = resolved}
            inv.groups[#inv.groups + 1] = entry
            if group.stage == "wall" and group.rows > 1 then
                for column = 0, group.columns - 1 do
                    for row = 1, group.rows - 1 do
                        inv.authoredNext[resolved[column * group.rows + row]] =
                            resolved[column * group.rows + row + 1]
                    end
                end
            end
        end
    end
    table.sort(inv.groups, function(a, b) return a.id < b.id end)
    local eligible = {}
    for _, name in ipairs(inv.names) do
        local profile = inv.profiles[name]
        if profile and (profile.fallbackEligible or profile.groundOnly) then
            inv.ground[#inv.ground + 1] = name
        end
        if profile and profile.fallbackEligible and not profile.groundOnly then
            eligible[#eligible + 1] = name
        end
    end
    for _, lower in ipairs(inv.names) do
        if inv.profiles[lower] then
            local nextPieces = {}
            for _, upper in ipairs(eligible) do
                if lower ~= upper and M.compatible(inv.profiles[lower], inv.profiles[upper], inv.tolerance) then
                    nextPieces[#nextPieces + 1] = upper
                end
            end
            inv.nextPieces[lower] = nextPieces
        end
    end
    for style, paths in pairs(socketProfiles.fallbackPaths or {}) do
        local styleName = styles[tonumber(style)] or style
        inv.paths[styleName] = {}
        for _, path in ipairs(paths) do
            local resolved, complete = {}, true
            for _, name in ipairs(path) do
                local actual = inv.name(name)
                if not actual then complete = false; break end
                resolved[#resolved + 1] = actual
            end
            if complete then inv.paths[styleName][#inv.paths[styleName] + 1] = resolved end
        end
    end
    return inv
end

local faces = {{1,2,3,4,5,6}, {6,12,18,24,30,36},
    {36,35,34,33,32,31}, {31,25,19,13,7,1}}
local facings = {180,90,0,270}

local function rotation(seed, index)
    if index <= 6 then
        if index == 1 then return 180 + 90 * (hash(seed, "corner:1") % 2) end
        if index == 6 then return 180 - 90 * (hash(seed, "corner:6") % 2) end
        return 180
    elseif index >= 31 then
        if index == 31 then return 360 - 90 * (hash(seed, "corner:31") % 2) end
        if index == 36 then return 360 + 90 * (hash(seed, "corner:36") % 2) end
        return 360
    end
    return index % 6 == 1 and 270 or 90
end

function M.plan(options)
    local inv = options.inventory or M.inventory(assert(options.pieceMap))
    local seed, wanted = options.seed or 0, options.height or 3
    local groundStyle, wallStyle = options.groundStyle, options.wallStyle or options.groundStyle
    local result = {columns = {}, reserved = {}, layout = {floor = {[0] = {}}, wall = {}, roof = {}}, height = 0}
    local used, active, fixedRotations, slots = {}, {}, {}, copy(options.slots)
    table.sort(slots)
    for _, index in ipairs(slots) do active[index] = true end

    local function reserve(names)
        for _, name in ipairs(names) do used[name] = true; result.reserved[name] = true end
    end
    local function available(names)
        for _, name in ipairs(names) do if used[name] then return false end end
        return true
    end
    local function ranked(names, label)
        local rankedNames = copy(names)
        local ranks = {}
        for _, name in ipairs(rankedNames) do ranks[name] = hash(seed, label .. name) end
        table.sort(rankedNames, function(a, b)
            local ah, bh = ranks[a], ranks[b]
            return ah == bh and a < b or ah < bh
        end)
        return rankedNames
    end

    -- Find an entire path before claiming any of its pieces. Backtracking is
    -- bounded; exhaustion produces a shorter complete column, never a bad join.
    local function findPath(prefix, rows, index)
        local path, inPath, visits = copy(prefix), {}, 0
        for _, name in ipairs(path) do inPath[name] = true end
        local rootChoices = ranked(inv.ground, "ground:" .. index .. ":")
        local choices = {}
        local function extend()
            if #path >= rows then return copy(path) end
            visits = visits + 1
            if visits > 4000 then return nil end
            local previous = path[#path]
            local candidates = rootChoices
            if previous then
                if not choices[previous] then
                    choices[previous] = ranked(inv.nextPieces[previous] or {}, "wall:" .. index .. ":")
                    local authored = inv.authoredNext[previous]
                    if authored then table.insert(choices[previous], 1, authored) end
                end
                candidates = choices[previous]
            end
            for _, name in ipairs(candidates) do
                local profile = inv.profiles[name]
                local style = previous and wallStyle or groundStyle
                if not used[name] and not inPath[name] and hasStyle(name, style)
                    and (not previous or not (profile and profile.groundOnly)) then
                    path[#path + 1], inPath[name] = name, true
                    local found = extend()
                    if found then return found end
                    inPath[name], path[#path] = nil, nil
                end
            end
        end
        return extend()
    end

    local function put(index, pieces, family, facing, authored)
        assert(active[index] and not result.columns[index], "Duplicate structural slot")
        assert(not facing or not fixedRotations[index] or facing == fixedRotations[index],
            "Structural component conflicts with its featured roof orientation")
        reserve(pieces)
        result.columns[index] = {pieces = copy(pieces), family = family,
            rotation = facing or fixedRotations[index] or rotation(seed, index), height = #pieces - 1,
            authored = authored or false, mismatchedFoundation = false}
    end

    local featured
    if options.featured then
        for _, group in ipairs(inv.groups) do
            if group.id == options.featured.id then featured = group; break end
        end
        assert(featured, "Featured Asian component is missing from the model: " .. options.featured.id)
        reserve(featured.pieces)
        if featured.stage == "roof" then
            result.layout.roof[wanted + 1] = {}
            for column, name in ipairs(featured.pieces) do
                result.layout.roof[wanted + 1][column] = name
                fixedRotations[column] = 180
            end
        else
            for column = 1, featured.columns do
                local prefix = {}
                for row = 1, featured.rows do prefix[row] = featured.pieces[(column - 1) * featured.rows + row] end
                local complete
                for rows = math.max(wanted + 1, #prefix), #prefix, -1 do
                    complete = findPath(prefix, rows, column)
                    if complete then break end
                end
                put(column, complete, featured.id, featured.columns > 1 and 180 or nil, true)
            end
        end
    end

    local components = {}
    for _, group in ipairs(inv.groups) do
        if group.stage == "wall" and group.rows >= wanted + 1
            and hasStyle(group.pieces[1], wallStyle) and available(group.pieces) then
            components[#components + 1] = group
        end
    end
    -- Generic pieces with certified matching sockets are also complete choices.
    for n, path in ipairs(inv.paths[wallStyle] or {}) do
        if #path >= wanted + 1 then
            components[#components + 1] = {id = "compatible:" .. wallStyle .. ":" .. n,
                rows = #path, columns = 1, pieces = path, compatible = true}
        end
    end
    local componentRanks = {}
    for _, group in ipairs(components) do componentRanks[group.id] = hash(seed, "component:" .. group.id) end
    table.sort(components, function(a, b)
        if a.columns ~= b.columns then return a.columns > b.columns end
        local ah, bh = componentRanks[a.id], componentRanks[b.id]
        return ah == bh and a.id < b.id or ah < bh
    end)
    for _, group in ipairs(components) do
        if available(group.pieces) then
            local placements = {}
            if group.columns == 1 then
                for _, index in ipairs(slots) do
                    if not result.columns[index] then placements[#placements + 1] = {indices = {index}, id = tostring(index)} end
                end
            else
                for face, row in ipairs(faces) do
                    for first = 1, #row - group.columns + 1 do
                        local indices, free = {}, true
                        for offset = 0, group.columns - 1 do
                            local index = row[first + offset]
                            if not active[index] or result.columns[index]
                                or (fixedRotations[index] and fixedRotations[index] ~= facings[face]) then
                                free = false; break
                            end
                            indices[#indices + 1] = index
                        end
                        if free then placements[#placements + 1] = {indices = indices, facing = facings[face], id = face .. ":" .. first} end
                    end
                end
            end
            for _, placement in ipairs(placements) do
                placement.rank = hash(seed, group.id .. ":slot:" .. placement.id)
            end
            table.sort(placements, function(a, b)
                local ah, bh = a.rank, b.rank
                return ah == bh and a.id < b.id or ah < bh
            end)
            local placement = placements[1]
            if placement then
                reserve(group.pieces)
                for column, index in ipairs(placement.indices) do
                    local pieces = {}
                    for row = 1, wanted + 1 do pieces[row] = group.pieces[(column - 1) * group.rows + row] end
                    put(index, pieces, group.id, placement.facing, not group.compatible)
                end
            end
        end
    end

    for _, index in ipairs(slots) do
        if not result.columns[index] then
            local complete
            for rows = wanted + 1, 1, -1 do
                complete = findPath({}, rows, index)
                if complete then break end
            end
            assert(complete, "No unused Asian foundation for perimeter slot " .. index)
            put(index, complete, "compatible", nil, false)
        end
    end

    -- A mixed-style shopfront may replace a tower's own first piece only when
    -- its top socket fits. These choices precede the independent mismatch pass.
    for _, index in ipairs(slots) do
        local column = result.columns[index]
        if column.height > 0 and not hasStyle(column.pieces[1], groundStyle) then
            for _, name in ipairs(ranked(inv.ground, "shopfront:" .. index .. ":")) do
                if not used[name] and hasStyle(name, groundStyle)
                    and M.compatible(inv.profiles[name], inv.profiles[column.pieces[2]], inv.tolerance) then
                    reserve({name}); column.pieces[1] = name; column.compatibleFoundation = true
                    break
                end
            end
        end
        column.originalFoundation = column.pieces[1]
    end

    local chance = options.mismatchChance
    if chance == nil then chance = 0.1 end
    assert(chance >= 0 and chance <= 1, "Invalid foundation mismatch probability")
    for _, index in ipairs(slots) do
        local column = result.columns[index]
        column.mismatchRequested = column.height > 0
            and hash(seed, "foundation-exception:" .. index) % 10000 < chance * 10000
        if column.mismatchRequested then
            local firstUpper = inv.profiles[column.pieces[2]]
            for _, name in ipairs(ranked(inv.ground, "mismatched-base:" .. index .. ":")) do
                if not used[name] and hasStyle(name, groundStyle)
                    and key(name):gsub("%d+$", "") ~= key(column.originalFoundation):gsub("%d+$", "")
                    and firstUpper and inv.profiles[name].top and firstUpper.bottom
                    and (not inv.profiles[name].max or inv.profiles[name].max[2] <= inv.floorHeight + inv.tolerance)
                    and not M.compatible(inv.profiles[name], firstUpper, inv.tolerance) then
                    reserve({name}); column.pieces[1] = name; column.mismatchedFoundation = true
                    break
                end
            end
        end
        column.roofHeight = (column.height + 1) * inv.floorHeight
        if column.height == 0 then
            -- Some authored horizontal ground components contain a whole tall
            -- facade in one piece. Their cap must clear the actual root mesh.
            local profile = inv.profiles[column.pieces[1]]
            if profile and profile.max then column.roofHeight = math.max(column.roofHeight, profile.max[2]) end
        end
        result.height = math.max(result.height, column.height)
        result.layout.floor[0][index] = column.pieces[1]
        for level = 1, column.height do
            result.layout.wall[level] = result.layout.wall[level] or {}
            result.layout.wall[level][index] = column.pieces[level + 1]
        end
        if featured and featured.stage == "roof" and index <= featured.columns then
            -- A horizontal roof component shares one orientation and elevation.
            assert(column.height == wanted, "Featured roof has no complete supporting column")
            assert(column.rotation == 180, "Featured roof orientation was changed during assembly")
        end
    end
    return result
end

return M
