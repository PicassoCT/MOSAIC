local function run(synced, hasAI)
    local e=setmetatable({}, {__index=_G});e._G=e
    local teamsCreated,created,finished=0,0,0
    local wp={UnitCreated=function() end,UnitDestroyed=function() end,GameStart=function() end,GameFrame=function() end}
    local nn={DeclareInput=function() end,DeclareOutput=function() end,SetConfigData=function() end,Procreate=function() end}
    e.gadget={};e.callInList={}
    e.UnitDefNames={house_arab0={id=1},house_western0={id=2},operativeinvestigator={id=3},operativepropagator={id=4}}
    e.CMD={}
    e.Spring={GetModOptions=function() return {craig_difficulty='2'} end,
        GetGameFrame=function() return 0 end,GetMyPlayerID=function() return 7 end,
        GetTeamList=function() return {0,1} end,
        GetTeamLuaAI=function(t) return t==1 and hasAI and 'Prometheus' or '' end,
        GetTeamInfo=function(t) return t,7,false,true,'antagon',t end,
        GetTeamResources=function() return 100,1000 end,
        GetSideData=function() return {} end,GetTeamUnits=function() return {10,11} end,
        GetUnitIsDead=function() return false end,GetUnitDefID=function() return 4 end,
        GetUnitHealth=function(id) return 100,100,0,0,id==10 and 1 or 0.5 end,
        Echo=function() end,Log=function() end}
    e.gadgetHandler={IsSyncedCode=function() return synced end,UpdateCallIn=function() end,
        AddChatAction=function() end,AddSyncAction=function() end,RemoveSyncAction=function() end}
    e.SendToUnsynced=function() end
    e.Script={LuaUI={}}
    e.CreateWaypointMgr=function() return wp end
    e.CreateGANN=function() return nn end
    e.CreateIntelligence=function() return {GameStart=function() end,GameFrame=function() end} end
    e.CreateTeam=function()
        assert(e.gadget.waypointMgr==wp and e.gadget.base_gann==nn)
        assert(e.gadget.intelligences[1])
        teamsCreated=teamsCreated+1
        return {GameStart=function() end,GameFrame=function() end,
            UnitCreated=function() created=created+1 end,
            UnitFinished=function() finished=finished+1 end}
    end
    local function include(p)
        p=p:gsub('LuaRules','luarules'):gsub('Configs','configs'):gsub('Gadgets','gadgets')
        if p=='luarules/configs/prometheus/config.lua' or p=='luarules/gadgets/prometheus/framework.lua' or
            p=='luarules/gadgets/prometheus/base/gann_inputs.lua' then
            return setfenv(assert(loadfile(p)),e)()
        end
    end
    e.include=include;e.VFS={Include=include,FileExists=function() return false end,ZIP=1}
    local result=setfenv(assert(loadfile('luarules/gadgets/prometheus/main.lua')),e)()
    if not hasAI then assert(result==false,'no-AI framework result must propagate');return end
    assert(e.gadget.difficulty=='medium')
    e.gadget:Initialize()
    e.gadget:GameFrame(128) -- also validates startup when the exact first frame was missed
    if not synced then
        assert(teamsCreated==1 and created==2 and finished==1)
        e.gadget:GameFrame(129);assert(teamsCreated==1)
    end
end
run(true,true);run(false,true);run(true,false);run(false,false)
print('PASS Prometheus startup: both Lua realms, shared managers, difficulty, late frames, partial builds, no-AI exit')
