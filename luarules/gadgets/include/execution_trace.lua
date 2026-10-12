-- Temporary, bounded execution traces. Callers choose a cycle (for example a
-- shot frame) and use fixed stage/reason names; repeated draws print only once.
local M = {}
local function scalar(value)
    local kind = type(value)
    if kind ~= 'string' and kind ~= 'number' and kind ~= 'boolean' and kind ~= 'nil' then
        return '<'..kind..'>'
    end
    return tostring(value):gsub('[\r\n]', ' '):sub(1, 240)
end

function M.New(prefix, options)
    options = options or {}
    local maxUnits = math.max(1, math.floor(options.maxUnits or 256))
    local maxEvents = math.max(1, math.floor(options.maxEvents or 64))
    local maxCycles = math.max(1, math.floor(options.maxCycles or 16))
    local records, slots, cursor = {}, {}, 0
    local echo = Spring and Spring.Echo
    local getFrame = Spring and Spring.GetGameFrame
    local label = scalar(prefix)
    local trace = {}

    function trace.Forget(unitID)
        records[unitID or false] = nil
    end

    local function log(unitID, cycle, stage, fields)
        if not echo then return false end
        local key = unitID or false
        local record = records[key]
        if not record then
            cursor = cursor % maxUnits + 1
            local old = slots[cursor]
            if old and records[old.key] == old then records[old.key] = nil end
            record = {key = key, cycles = {}, count = 0, clock = 0}
            records[key], slots[cursor] = record, record
        end
        -- Several block fires can remain alive with different birth frames.
        -- Retain recently observed cycles so alternating slots do not reset
        -- each other's deduplication on every draw.
        record.clock = record.clock + 1
        local cycleKey = cycle or false
        local state = record.cycles[cycleKey]
        if not state then
            if record.count >= maxCycles then
                local oldestKey, oldest
                for key, value in pairs(record.cycles) do
                    if not oldest or value.used < oldest.used then oldestKey, oldest = key, value end
                end
                record.cycles[oldestKey] = nil
                record.count = record.count - 1
            end
            state = {events = {}, count = 0}
            record.cycles[cycleKey] = state
            record.count = record.count + 1
        end
        state.used = record.clock
        local reason = fields and fields.reason
        local event = scalar(stage)..'\0'..scalar(reason)..'\0'..
            scalar(fields and fields.piece)..'\0'..scalar(fields and fields.slot)
        if state.events[event] or state.count >= maxEvents then return false end
        state.events[event], state.count = true, state.count + 1
        local parts = {'['..label..']', 'frame='..scalar(getFrame and getFrame()),
            'unit='..scalar(unitID), 'cycle='..scalar(cycle), 'stage='..scalar(stage)}
        local keys = {}
        for name in pairs(fields or {}) do keys[#keys + 1] = name end
        table.sort(keys, function(a,b) return scalar(a) < scalar(b) end)
        for _, name in ipairs(keys) do
            parts[#parts + 1] = scalar(name)..'='..scalar(fields[name])
        end
        echo(table.concat(parts, ' '))
        return true
    end

    function trace.Log(unitID, cycle, stage, fields)
        -- Diagnostics must never interrupt a shot, a damage callback or a draw.
        local ok, emitted = pcall(log, unitID, cycle, stage, fields)
        return ok and emitted or false
    end
    return trace
end
return M
