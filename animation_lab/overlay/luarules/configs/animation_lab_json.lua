-- External animation-lab support. Copied only into a disposable run archive.
local json = {}
local arrayTag = {}
function json.array(value) return setmetatable(value or {}, arrayTag) end

local escapes = {['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b',
    ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'}
local function quote(value)
    return '"' .. value:gsub('[%z\1-\31\\"]', function(c)
        return escapes[c] or string.format('\\u%04x', c:byte())
    end) .. '"'
end

function json.encode(value)
    local kind = type(value)
    if kind == 'nil' then return 'null' end
    if kind == 'boolean' then return value and 'true' or 'false' end
    if kind == 'number' then
        assert(value == value and value ~= math.huge and value ~= -math.huge,
            'animation telemetry contains a non-finite number')
        return string.format('%.14g', value)
    end
    if kind == 'string' then return quote(value) end
    assert(kind == 'table', 'animation telemetry cannot encode ' .. kind)
    local parts = {}
    if getmetatable(value) == arrayTag or #value > 0 then
        for i = 1, #value do parts[i] = json.encode(value[i]) end
        return '[' .. table.concat(parts, ',') .. ']'
    end
    local keys = {}
    for key in pairs(value) do
        assert(type(key) == 'string', 'animation telemetry object key must be a string')
        keys[#keys + 1] = key
    end
    table.sort(keys)
    for i, key in ipairs(keys) do parts[i] = quote(key) .. ':' .. json.encode(value[key]) end
    return '{' .. table.concat(parts, ',') .. '}'
end
return json
