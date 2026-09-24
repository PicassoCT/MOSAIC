local function eq(a,b,msg) assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
local function env(synced)
    local e=setmetatable({}, {__index=_G});e._G=e
    local w={sent={},orders={},rules={},teams={[258]=1},warnings=0,actions={}}
    e.CMD={MOVE=10,ATTACK=20,CLOAK=95,OPT_ALT=128,OPT_CTRL=64,OPT_SHIFT=32,OPT_RIGHT=16}
    e.gadget={GetInfo=function() return {name='Prometheus'} end, betrayalContacts={}}
    e.callInList={'UnitCreated'}
    e.gadget.UnitCreated=function(self,id) eq(self,e.gadget);w.created=id end
    e.gadgetHandler={IsSyncedCode=function() return synced end,UpdateCallIn=function() end,
        AddSyncAction=function(self,key,fn) w.actions[key]=fn end,
        RemoveSyncAction=function(self,key) w.actions[key]=nil end}
    e.SendToUnsynced=function(key,...) w.forwarded={key,...} end
    e.Spring={
        GetMyPlayerID=function() return 7 end,GetTeamList=function() return {0,1,2} end,
        GetTeamLuaAI=function(t) return t==1 and 'Prometheus' or '' end,
        GetTeamInfo=function(t) return t,t==1 and 7 or 9,false,true,'antagon',t end,
        ValidUnitID=function(id) return w.teams[id]~=nil end,
        GetUnitTeam=function(id) return w.teams[id] end,
        GetUnitRulesParam=function(id,k) return w.rules[id] and w.rules[id][k] end,
        GiveOrderToUnit=function(id,cmd,p,o) w.orders[#w.orders+1]={id,cmd,p,o} end,
        SendLuaRulesMsg=function(s) w.sent[#w.sent+1]=s end,
        Log=function() w.warnings=w.warnings+1 end,
    }
    return e,w
end
local function loadIn(p,e) return setfenv(assert(loadfile(p)),e)() end
local client,cw=env(false);loadIn('luarules/gadgets/prometheus/framework.lua',client)
client.gadget:Initialize()
assert(cw.actions.Prometheus_UnitCreated)
cw.actions.Prometheus_UnitCreated('Prometheus_UnitCreated',44);eq(cw.created,44)
client.GiveOrderToUnit(258,10,{1200.4,0,600.8},{'shift'})
client.gadget:GameFrame(1);eq(#cw.sent,1)
local packet=cw.sent[1]
local server,sw=env(true);loadIn('luarules/gadgets/prometheus/framework.lua',server)
server.gadget:Initialize();server.gadget:UnitCreated(99);eq(sw.forwarded[1],'Prometheus_UnitCreated')
server.gadget:RecvLuaMsg(packet,9);server.gadget:GameFrame(1);eq(#sw.orders,0,'unauthorized sender')
server.gadget:RecvLuaMsg(packet,7);server.gadget:GameFrame(2);eq(#sw.orders,1)
eq(sw.orders[1][1],258);eq(sw.orders[1][3][1],1200);eq(sw.orders[1][3][3],601);eq(sw.orders[1][4],32)
server.gadget:RecvLuaMsg(packet..string.char(1),7);server.gadget:GameFrame(3)
eq(#sw.orders,1,'malformed batch must execute nothing');eq(sw.warnings,1)
server.gadget:GameFrame(4);eq(sw.warnings,1,'bad packet must not retry forever')
server.gadget:RecvLuaMsg(packet,7);sw.teams[258]=2;server.gadget:GameFrame(5)
eq(#sw.orders,1,'ownership must be checked after queueing')
sw.teams[258]=1;sw.rules[258]={betrayal_runner=1}
server.gadget:RecvLuaMsg(packet,7);server.gadget:GameFrame(6);eq(#sw.orders,1,'AI must not commandeer runner')
cw.rules[258]={betrayal_runner=1};client.GiveOrderToUnit(258,10,{1,0,1},{})
client.gadget:GameFrame(2);eq(#cw.sent,1)
cw.rules[258]={};client.gadget.betrayalContacts[258]=true
client.GiveOrderToUnit(258,10,{1,0,1},{})
client.GiveOrderToUnit(258,10,{2,0,2},{},true);client.gadget:GameFrame(3);eq(#cw.sent,2)
client.gadget:Shutdown();eq(cw.actions.Prometheus_UnitCreated,nil)

-- Repeated LOS and damage events must not duplicate enemies or corrupt indices.
local e={};setmetatable(e,{__index=_G})
e.FLAG_RADIUS=230
e.gadget={difficulty='medium',flags={},waypointMgr={GetWaypoints=function() return {} end}}
e.Spring={GetTeamList=function() return {0,1,2,3} end,GetGaiaTeamID=function() return 0 end,
    GetTeamInfo=function(t) return t,0,false,false,'antagon',t end,
    AreTeamsAllied=function(a,b) return a==b end,GetAllUnits=function() return {} end}
loadIn('luarules/gadgets/prometheus/intelligence.lua',e)
local intel=e.CreateIntelligence(1,1)
intel.UnitEnteredLos(10,2,1,1);intel.UnitEnteredLos(10,2,1,1)
intel.UnitEnteredLos(11,2,1,1);intel.UnitEnteredLos(12,2,1,1)
eq(#intel.GetUnits(20),3)
intel.UnitDestroyed(10);intel.UnitDestroyed(12)
local remaining=intel.GetUnits(20);eq(#remaining,1);eq(remaining[1],11)
intel.UnitEnteredLos(99,2,3,1);eq(#intel.GetUnits(20),1,'another allyteam LOS is private')
intel.UnitLeftLos(11,2,3,1);eq(#intel.GetUnits(20),1)
intel.UnitDamaged(55,1,2,1,false,0,0,56,1,3);eq(#intel.GetUnits(20),1,'third-party combat is private')

-- A receiver is a mobile operative, never a forced safehouse rendezvous.
e.gadget={betrayalContacts={}}
e.UnitDefNames={operativepropagator={id=1},operativeinvestigator={id=2},operativeasset={id=3},civilianagent={id=4}}
local rules={[100]={betrayal_runner=1},[101]={},[102]={}}
local positions={[100]={100,0,100},[101]={500,0,100},[102]={3000,0,3000}}
local orders={}
e.CMD={MOVE=10}
e.Spring={GetTeamUnits=function() return {100,101,102} end,
    GetUnitRulesParam=function(id,k) return rules[id][k] end,
    GetUnitDefID=function(id) return id==102 and 5 or 1 end,
    GetUnitHealth=function() return 100,100,0,0,1 end,
    GetUnitPosition=function(id) return unpack(positions[id]) end}
e.GiveOrderToUnit=function(id,cmd,p,o,priority) orders[#orders+1]={id,cmd,p,priority} end
loadIn('luarules/gadgets/prometheus/betrayal.lua',e)
local rescue=e.CreateBetrayalMgr(1);rescue.GameFrame(128)
eq(orders[1][1],101);eq(orders[1][4],true);assert(e.gadget.betrayalContacts[101])
rules[100].betrayal_runner=0;rescue.GameFrame(256);eq(e.gadget.betrayalContacts[101],nil)

-- Regression: combat used unit IDs as team IDs and could execute its own operators.
e={};setmetatable(e,{__index=_G});e.SQUAD_SIZE=1
local target1={x=100,y=0,z=100};local target2={x=200,y=0,z=200}
local attacks={};local teams={[40]=1,[41]=1,[60]=1,[61]=0,[62]=2,[63]=3}
e.CMD={MOVE=10,ATTACK=20,FIGHT=16,FIRE_STATE=45}
e.UnitDefs={[1]={speed=60,mass=200,weapons={}}}
e.UnitDefNames={physicspayload={id=9},launcher={id=10},operativepropagator={id=2},operativeinvestigator={id=3},operativeasset={id=4}}
e.Spring={GetGaiaTeamID=function() return 0 end,GetUnitDefID=function() return 1 end,
    GetUnitPosition=function() return 0,0,0 end,GetUnitNoSelect=function() return false end,
    GetUnitsInCylinder=function() return {60,61,62,63} end,GetUnitTeam=function(id) return teams[id] end,
    GetUnitIsCloaked=function() return false end,GetTeamUnitsByDefs=function() return {} end,
    AreTeamsAllied=function(a,b) return a==b or a==3 or b==3 end,
    GetGroundHeight=function() return 0 end}
e.gadget={IsDebug=function() return false end,waypointMgr={GetWaypoints=function() return {} end,
    GetNearestWaypoint2D=function() return target1 end,GetNext=function() return target2 end},
    intelligences={[1]={GetTarget=function() return target1,{1,0},{} end}}}
e.GiveOrderToUnit=function(id,cmd,p) if cmd==20 then attacks[#attacks+1]=p[1] end end
loadIn('luarules/gadgets/prometheus/combat.lua',e)
local combat=e.CreateCombatMgr(1,1,{FirepowerGradient=function() return 0,0 end},{},function() end)
combat.UnitFinished(40,1,1);combat.UnitFinished(41,1,1);combat.GameFrame(128)
eq(#attacks,2);eq(attacks[1],62);eq(attacks[2],62)
print('PASS Prometheus: serialization, authorization, event forwarding, ownership, intel indices, rendezvous, friendly targeting')
