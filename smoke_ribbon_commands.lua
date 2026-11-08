-- Route the real /luarules action through both production action handlers.
-- Direct TextCommand calls miss the absent gadget TextCommand dispatcher.
local environments,handlers,renderers,messages={},{},{},{}
local function createSide(synced)
    local side=synced and 'server' or 'client'
    local env=setmetatable({gadget={ghInfo={layer=1}},GG={},Game={},actionHandler=false}, {__index=_G})
    env._G=env
    env.Spring={
        ValidUnitID=function(id)return id==7 end,GetUnitIsDead=function()return false end,
        GetUnitPieceMap=function()return {root=1}end,GetSelectedUnits=function()return {7}end,
        GetMyPlayerID=function()return 2 end,
        Echo=function(message)messages[#messages+1]=message end,
    }
    local function include(path)
        if path=='luarules/gadgets/include/smoke_ribbon_renderer.lua' then
            return function()
                local renderer={records={}}
                function renderer:Draw()end
                function renderer:Shutdown()end
                renderers[side]=renderer
                return renderer
            end
        end
        local f=assert(loadfile(path));setfenv(f,env);return f()
    end
    env.VFS={Include=include}
    if synced then
        env.SendToUnsynced=function(...)
            return handlers.client.RecvFromSynced(...)
        end
    end
    local actions=include('luarules/actions.lua')
    handlers[side]=actions
    env.gadgetHandler={
        IsSyncedCode=function()return synced end,
        AddChatAction=function(_,name,fn,help)return actions.AddChatAction(env.gadget,name,fn,help)end,
        RemoveChatAction=function(_,name)return actions.RemoveChatAction(env.gadget,name)end,
        AddSyncAction=function(_,name,fn,help)return actions.AddSyncAction(env.gadget,name,fn,help)end,
        RemoveSyncAction=function(_,name)return actions.RemoveSyncAction(env.gadget,name)end,
        RemoveGadget=function()error('renderer unexpectedly unavailable')end,
    }
    include('luarules/gadgets/gfx_smoke_ribbons.lua')
    environments[side]=env
    return env
end
local server=createSide(true)
local client=createSide(false)
client.SYNCED=server
server.gadget:Initialize();client.gadget:Initialize()
assert(handlers.server.GotChatMsg('smokeribbon root electric',2),'real LuaRules chat action was not handled')
client.gadget:DrawWorld()
local preview=assert(renderers.client.records.__preview,'chat action failed to reach the local renderer')
local live=client.VFS.Include('scripts/lib_graphene_arc.lua').Options(19)
assert(preview.mode==live.mode and preview.width==live.width and preview.length==live.length,
    'command did not use the production parachute electrical preset')
for _,field in ipairs({'colorStart','colorEnd','emission','sourceGlow'}) do
    for i,value in ipairs(live[field]) do
        assert(preview[field][i]==value,'preview changed live electrical '..field..' channel '..i)
    end
end
handlers.server.GotChatMsg('smokeribbon off',3)
client.gadget:DrawWorld()
assert(renderers.client.records.__preview==preview,'another player altered this client preview')
handlers.server.GotChatMsg('smokeribbon status',2)
assert(messages[#messages]:find('renderer ready; synced registry ready; selected unit slots 0',1,true),
    'status command failed or counted a local preview as a synced attachment')
handlers.server.GotChatMsg('smokeribbon off',2)
client.gadget:DrawWorld()
assert(not renderers.client.records.__preview,'off action left the local electric preview alive')
handlers.server.GotChatMsg('smokeribbon missing electric',2)
assert(messages[#messages]:find('unknown smoke emitter piece',1,true),'invalid emitter failure was swallowed')
client.gadget:Shutdown();server.gadget:Shutdown()
assert(not handlers.server.GotChatMsg('smokeribbon root electric',2),'shutdown retained its chat action')
assert(not handlers.client.RecvFromSynced('smoke_ribbon_command',2,'root electric'),'shutdown retained its sync action')
print('PASS: production LuaRules chat dispatch, synced-to-local routing, exact live electrical preset, other-player isolation, status, off, invalid-piece report and action cleanup')
