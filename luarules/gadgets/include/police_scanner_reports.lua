-- Public radio reports contain incident coordinates, never a suspect's live position.
-- Coalesce bursts of damage into one bounded update per police tick.
local M = {}
local fields = {'x','y','z','kind','frame'}
local public = {public=true}
function M.New()
    local pending
    local serial = Spring.GetGameRulesParam('police_scanner_serial') or 0
    local api = {}
    function api.Report(kind, location)
        pending = {kind=kind, x=location.x, y=location.y, z=location.z,
            frame=Spring.GetGameFrame()}
    end
    function api.Flush()
        if not pending then return end
        serial = serial + 1
        local prefix = 'police_scanner_'..((serial-1)%3+1)..'_'
        for _, key in ipairs(fields) do
            Spring.SetGameRulesParam(prefix..key, pending[key], public)
            -- Keep the latest-report fields for older UI instances.
            Spring.SetGameRulesParam('police_scanner_'..key, pending[key], public)
        end
        Spring.SetGameRulesParam(prefix..'serial', serial, public)
        Spring.SetGameRulesParam('police_scanner_serial', serial, public)
        pending = nil
    end
    return api
end
return M
