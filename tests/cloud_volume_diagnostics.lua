-- Exercise the REAL actions.lua dispatcher in separate synced/unsynced envs.
local messages,queue={},{}
local function makeEnv(synced)
    local e={};setmetatable(e,{__index=_G});e._G=e
    e.gadget={ghInfo={layer=2}};e.GG={}
    e.Spring={Echo=function(s)messages[#messages+1]=s end,
        GetMyPlayerID=function()return 7 end,GetSelectedUnits=function()return {10}end,
        GetUnitPieceMap=function()return {GroundGases=1}end,
        GetUnitPieceInfo=function()return {isEmpty=true}end}
    local function run(path)local f=assert(loadfile(path));setfenv(f,e);return f()end
    if synced then e.SendToUnsynced=function(...)queue[#queue+1]={...}end end
    e.VFS={Include=function(path)
        if path:find('cloud_volume_renderer',1,true) then return function()return nil,'test compile failure'end end
        return run(path)
    end}
    local actions=run('luarules/actions.lua')
    e.gadgetHandler={IsSyncedCode=function()return synced end,
        AddChatAction=function(_,cmd,func,help)return actions.AddChatAction(e.gadget,cmd,func,help)end,
        RemoveChatAction=function(_,cmd)return actions.RemoveChatAction(e.gadget,cmd)end,
        AddSyncAction=function(_,cmd,func)return actions.AddSyncAction(e.gadget,cmd,func)end,
        RemoveSyncAction=function(_,cmd)return actions.RemoveSyncAction(e.gadget,cmd)end}
    run('luarules/gadgets/gfx_cloud_volumes.lua');e.gadget:Initialize()
    return e,actions
end
local sync,sa=makeEnv(true)
local unsync,ua=makeEnv(false);unsync.SYNCED=sync
assert(not sync.gadget.TextCommand and not unsync.gadget.TextCommand)
assert(sa.GotChatMsg('cloudvolumes',7),'command not dispatched')
assert(#queue==1 and queue[1][1]=='cloud_volume_report')
ua.RecvFromSynced(unpack(queue[1]))
local report=table.concat(messages,'\n')
assert(report:find('synced API ready',1,true))
assert(report:find('FAILED: test compile failure',1,true))
assert(report:find('1 matching pieces, 0 registered now, 1 unusable bounds',1,true))
assert(report:find('GroundGases: engine reports empty geometry',1,true))
local before=#messages
ua.RecvFromSynced('cloud_volume_report',8);assert(#messages==before,'reported on another player client')
assert(not sa.GotChatMsg('unrelated',7))
unsync.gadget:DrawWorld();unsync.gadget:Shutdown();sync.gadget:Shutdown()
assert(not sa.HaveChatAction() and not ua.HaveSyncAction(),'callbacks leaked on reload')
print('PASS: real chat/sync dispatcher, startup messages, GPU failure, bounds report, player filtering, cleanup')
