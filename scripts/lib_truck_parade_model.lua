-- Resolve both the original flattened export and the artist's grouped FBX
-- export. Piece IDs are engine values (including zero); names are not assumed
-- to be lowercase and an underscore in an authored motion name is harmless.
local model = {}

local function normalized(name)
    return type(name) == "string" and name:lower():gsub("[_%s]", "") or name
end
model.normalized = normalized

function model.inverseMatrixScale(matrix)
    if #matrix ~= 16 then return nil end
    local result = {}
    for axis = 1, 3 do
        local first = (axis - 1) * 4 + 1
        local scale = math.sqrt(matrix[first]^2 + matrix[first+1]^2 + matrix[first+2]^2)
        if scale <= 0 or scale ~= scale or scale == math.huge then return nil end
        result[axis] = 1 / scale
    end
    return result
end

function model.inspect(pieceMap, getInfo)
    local result = {map = pieceMap or {}, names = {}, children = {}, ids = {}}
    local entries = {}
    for name, id in pairs(result.map) do
        if type(id) == "number" then entries[#entries + 1] = {name = name, id = id} end
    end
    table.sort(entries, function(a, b)
        if a.id == b.id then return a.name < b.name end
        return a.id < b.id
    end)
    for _, entry in ipairs(entries) do
        local key = normalized(entry.name)
        if result.names[key] == nil then result.names[key] = entry.id end
        result.ids[entry.id] = true
    end
    function result.find(name)
        return result.map[name] or result.names[normalized(name)]
    end
    for _, entry in ipairs(entries) do
        local info = getInfo and getInfo(entry.id)
        if info then
            if info.parent == "[null]" or info.parent == -1 then result.root = entry.id end
            local children = {}
            for _, child in ipairs(info.children or {}) do
                local id = type(child) == "number" and child or result.find(child)
                if id ~= nil then children[#children + 1] = id end
            end
            result.children[entry.id] = children
        end
    end
    result.center = result.find("center") or result.root or (entries[1] and entries[1].id)
    return result
end

function model.selection(index, variant)
    local root = index.find(variant.pieceName)
    if root == nil then
        for _, alias in ipairs(variant.pieceAliases or {}) do
            root = index.find(alias)
            if root ~= nil then break end
        end
    end
    if root == nil then return nil end
    local pieces, seen = {}, {}
    local function add(id)
        if id == nil or seen[id] then return end
        seen[id] = true
        pieces[#pieces + 1] = id
        for _, child in ipairs(index.children[id] or {}) do add(child) end
    end
    add(root)
    -- The early exporter stored articulated meshes beside the main root.
    -- Later exports can bake them into a child mesh; keep the sculpture even
    -- when a formerly separate fin/wing no longer exists as an engine piece.
    for _, name in ipairs(variant.pieces or {}) do add(index.find(name)) end
    local motions = {}
    for _, motion in ipairs(variant.motion or {}) do
        local id = index.find(motion.pieceName)
        if id ~= nil then
            motions[#motions + 1] = {id = id, axis = motion.axis,
                spin = motion.spin, angle = motion.angle}
        end
    end
    return {pieces = pieces, motions = motions}
end

return model
