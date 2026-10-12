-- Temporary printf instrumentation. Revert the diagnostics commit to remove it.
-- All state in this module is diagnostic; it never controls the simulation.
if GG.BuildingDestructionTrace then return GG.BuildingDestructionTrace end

local spEcho, spGetGameFrame = Spring.Echo, Spring.GetGameFrame
local sort, concat = table.sort, table.concat
local tostring, type, pairs, pcall = tostring, type, pairs, pcall
local recent = {}
local M = {}

local function scalar(value)
    local kind = type(value)
    if kind ~= "number" and kind ~= "boolean" and kind ~= "string" and kind ~= "nil" then
        return "<" .. kind .. ">"
    end
    return (tostring(value):gsub("[\r\n]", " "))
end

-- Repeated observations are sampled per entity, stage, piece, plot and reason.
-- Actual state transitions omit repeatFrames and are always printed.
function M.Log(unitID, stage, fields, repeatFrames)
    if not spEcho then return false end
    fields = fields or {}
    local frame = spGetGameFrame and spGetGameFrame() or 0
    local suppressed = 0
    if repeatFrames and repeatFrames > 0 then
        local entity = unitID or "system"
        local byStage = recent[entity]
        if not byStage then byStage = {}; recent[entity] = byStage end
        local key = stage .. ":" .. scalar(fields.piece or fields.block)
            .. ":" .. scalar(fields.plot) .. ":" .. scalar(fields.reason)
        local previous = byStage[key]
        if previous and frame >= previous.frame and frame - previous.frame < repeatFrames then
            previous.suppressed = previous.suppressed + 1
            return false
        end
        suppressed = previous and previous.suppressed or 0
        byStage[key] = {frame = frame, suppressed = 0}
    end
    local parts = {"[BuildingDestruction]", "frame=" .. scalar(frame),
        "unit=" .. scalar(unitID), "stage=" .. scalar(stage)}
    local keys = {}
    for key in pairs(fields) do keys[#keys + 1] = key end
    sort(keys)
    for _, key in ipairs(keys) do
        parts[#parts + 1] = scalar(key) .. "=" .. scalar(fields[key])
    end
    if suppressed > 0 then parts[#parts + 1] = "suppressed=" .. suppressed end
    -- Logging must not interrupt a damage callback even if the output sink fails.
    local ok = pcall(spEcho, concat(parts, " "))
    return ok
end

function M.Forget(unitID)
    if unitID ~= nil then recent[unitID] = nil end
end

GG.BuildingDestructionTrace = M
return M
