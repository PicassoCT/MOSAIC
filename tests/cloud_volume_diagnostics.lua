-- The diagnostic must survive GPU initialization failure and report real reasons.
local messages={}
gadget={};gadgetHandler={IsSyncedCode=function()return false end}
SYNCED={CloudVolumeRevision=1,CloudVolumeRecords={}}
Spring={Echo=function(s)messages[#messages+1]=s end,GetSelectedUnits=function()return {10}end,
    GetUnitPieceMap=function()return {GroundGases=1}end,
    GetUnitPieceInfo=function()return {isEmpty=true}end}
VFS={Include=function(path)
    if path:find('cloud_volume_renderer',1,true) then return function()return nil,'test compile failure'end end
    return dofile(path)
end}
dofile('luarules/gadgets/gfx_cloud_volumes.lua');gadget:Initialize()
assert(gadget:TextCommand('cloudvolumes'))
local report=table.concat(messages,'\n')
assert(report:find('FAILED: test compile failure',1,true))
assert(report:find('1 matching pieces, 0 registered now, 1 unusable bounds',1,true))
assert(report:find('GroundGases: engine reports empty geometry',1,true))
assert(not gadget:TextCommand('unrelated'))
gadget:DrawWorld();gadget:Shutdown()
print('PASS: cloud status survives shader failure and identifies bounds rejection')
