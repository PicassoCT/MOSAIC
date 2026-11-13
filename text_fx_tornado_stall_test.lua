-- Reuse the complete production-preview scheduler with the engine reporting
-- permanently busy glyph moves during tornado. The next case must still run.
local f=assert(io.open('tests/text_fx_test_unit_test.lua'))
local source=f:read('*a');f:close()
local marker='Spring.GetUnitPieceInfo=function()'
local injected=[[
local ordinaryBusy=Spring.UnitScript.IsInMove
local function inTornado()
    local currentCase=announcements[#announcements]
    return currentCase and currentCase.text:find('] letterTornado |',1,true)
end
Spring.UnitScript.IsInMove=function(...)
    if inTornado() then return true end
    return ordinaryBusy(...)
end
local ordinaryWait=WaitForMove
function WaitForMove(...)
    assert(not inTornado(),'tornado used an unbounded native movement wait')
    return ordinaryWait(...)
end
]]
local start=assert(source:find(marker,1,true))
source=source:sub(1,start-1)..injected..source:sub(start)
assert(loadstring(source))()
print('PASS: permanently stalled tornado formation/restoration recover and all 99 preview cases complete')
