-- Startup lifecycle only. Real managers + engine bridge are exercised separately
-- by prometheus_orders_test.lua; a successful CreateTeam is not gameplay proof.
local function run(synced,hasAI,source)
    local e=setmetatable({}, {__index=_G});e._G=e
    local calls={created=0,finished=0,teams=0,ticks=0}
    local units={10,11};local side=source=='team' and 'Antagon' or ''
    local start=source=='startUnit' and 4 or nil
    local alive=true
    e.gadget={};e.CMD={}
    e.UnitDefNames={operativepropagator={id=4},operativeinvestigator={id=3}}
    e.Spring={GetModOptions=function() return {craig_difficulty='2'} end,
        GetMyPlayerID=function() return 7 end,GetTeamList=function() return {0,1} end,
        GetTeamLuaAI=function(t) return t==1 and hasAI and 'Prometheus' or '' end,
        GetTeamInfo=function(t) return t,7,not alive,true,side,t end,
        GetTeamRulesParam=function() return start end,GetTeamUnits=function() return units end,
        GetUnitIsDead=function() return false end,GetUnitDefID=function() return 4 end,
        GetUnitHealth=function(id) return 100,100,0,0,id==10 and 1 or 0.5 end,
        Echo=function() end,Log=function() end}
    e.gadgetHandler={IsSyncedCode=function() return synced end,UpdateCallIn=function() end,
        AddChatAction=function() end,AddSyncAction=function() end,RemoveSyncAction=function() end}
    e.SendToUnsynced=function() end
    e.CreateTeam=function(id,ally,faction)
        assert(id==1 and ally==1 and faction=='antagon')
        calls.teams=calls.teams+1
        return {GameStart=function() end,GameFrame=function() calls.ticks=calls.ticks+1 end,
            Shutdown=function() end,UnitCreated=function() calls.created=calls.created+1 end,
            UnitFinished=function() calls.finished=calls.finished+1 end}
    end
    local function include(p)
        p=p:gsub('LuaRules','luarules'):gsub('Gadgets','gadgets')
        if p:find('/main.lua') or p:find('/framework.lua') then return setfenv(assert(loadfile(p)),e)() end
    end
    e.include=include;e.VFS={Include=include,ZIP=1}
    local result=include('luarules/gadgets/prometheus/main.lua')
    if not hasAI then assert(result==false);return end
    assert(e.gadget.difficulty=='medium')
    e.gadget:Initialize()
    if source=='delayed' then units={} end
    e.gadget:GameFrame(128)
    if not synced then
        if source=='delayed' then
            assert(calls.teams==0);units={10,11};e.gadget:GameFrame(129)
        end
        assert(calls.teams==1 and calls.created==2 and calls.finished==1)
        e.gadget:GameFrame(130);assert(calls.teams==1)
        local ticks=calls.ticks;e.gadget:GameFrame(130);assert(calls.ticks==ticks)
        e.gadget:TeamDied(1);e.gadget:GameFrame(131);assert(calls.teams==1,'dead team must not restart')
    end
end
for _,source in ipairs({'team','startUnit','unit','delayed'}) do run(false,true,source) end
run(true,true,'team');run(true,false,'team');run(false,false,'team')
print('PASS Prometheus startup: side/startUnit/operative/delayed spawn, partial builds, late frames, realms, no-AI exit, death')
