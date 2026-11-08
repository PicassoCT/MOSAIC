-- Actual synced producer and existing script entry points, controlled engine API.
local function loadIn(path,env)
    local f=setfenv and setfenv(assert(loadfile(path)),env) or assert(loadfile(path,'t',env))
    return f()
end
local frame,events,damage,cegs,sounds=100,{},{},0,0
local env=setmetatable({GG={},gadget={},gadgetHandler={IsSyncedCode=function() return true end},
    Spring={GetGameFrame=function() return frame end,GetUnitPosition=function(id) return id,10,0 end},
    SendToUnsynced=function(name,x,y,z,id,owner) events[#events+1]={name,x,y,z,id,owner} end}, {__index=_G})
loadIn('luarules/gadgets/gfx_priority_sfx_events.lua',env);env.gadget:Initialize()
local api=env.GG.PrioritySFX
assert(api.Burst('sticky',1,2,3,4) and api.Unit('emp',10,20))
assert(events[1][1]=='explosion_light' and events[1][5]==-101)
assert(events[2][3]==30 and events[2][5]==-102,'EMP offset/visual ID wrong')
assert(not api.Burst('invalid',0,0,0) and not api.Burst('emp',0/0,0,0))
for i=1,1000 do api.Burst('emp',i,0,0,i) end
assert(#events==64,'unbounded synced notifications')
frame=101;assert(api.Burst('emp',0,0,0));assert(#events==65)
-- Notifications have no authority over damage, stun, orders or unit lifetime.
local engine={
    SpawnCEG=function() cegs=cegs+1 end,PlaySoundFile=function() sounds=sounds+1 end,
    ValidUnitID=function() return true end,GetUnitIsDead=function() return false end,
    AddUnitDamage=function(id,value,_,attacker) damage[#damage+1]={id,value,attacker} end,
    GetUnitsInCylinder=function() return {2,1,3} end,
    GetUnitPosition=function(id) return (id-1)*75,0,0 end,
}
local sticky=loadIn('luarules/configs/sticky_bombs.lua',setmetatable({Spring=engine,GG=env.GG},{__index=_G}))
sticky.explode(99,2,0,0,0,3)
assert(#damage==1 and damage[1][1]==2 and damage[1][2]==3450 and damage[1][3]==99)
assert(cegs==1 and sounds==1 and events[#events][5]==-101,'detonation lost CEG/sound/new event')
damage={};sticky.explode(99,nil,0,0,0,1)
assert(#damage==2 and damage[1][1]==1 and damage[1][2]==1150 and damage[2][2]==575)
-- Information payload: old cloud and gameplay calls remain, new pulses happen
-- only at actual electrical targets and the existing idempotency guard holds.
local clouds,pulses,stunned,killed,destroyed={},{},{},{},0
local noop=function() end
local function empty() return {} end
local e=setmetatable({script={},unitID=10,unitDefID=1,
    UnitDefs={[1]={name='informationpayload'}},UnitDefNames={launcher={id=9}},
    houseTypeTable={},include=noop,piece=function(x) return x end,
    getDefusalCapableTypeTable=empty,getCultureUnitModelTypes=empty,getLoadAbleTruckTypes=empty,
    getChemTrailInfluencedTypes=empty,getAutomationPayloadDisabledType=function() return {[11]=true} end,
    getAutomationPayloadDestroyedType=function() return {[12]=true} end,isTeamAITeam=function() return false end,
    getGameConfig=function() return {game={culture='arabic'},military={warheads={automationStunTimeSeconds=30}}} end,
    foreach=function(t,f) for _,id in ipairs(t) do f(id) end end,
    stunUnit=function(id) stunned[#stunned+1]=id end,
    Spring={GetUnitTeam=function() return 0 end,GetGaiaTeamID=function() return 9 end,
        GetGameFrame=function() return frame end,GetAllUnits=function() return {1,2,3} end,
        GetUnitPosition=function(id) return id,10,0 end,GetUnitDefID=function(id) return 10+id end,
        DestroyUnit=function() destroyed=destroyed+1 end},
    GG={CloudVolume={Burst=function(...) clouds[#clouds+1]={...} end},
        PrioritySFX={Burst=function(...) pulses[#pulses+1]={...} end},
        UnitsToKill={PushKillUnit=function(_,id) killed[#killed+1]=id end}},
}, {__index=_G})
loadIn('scripts/warheadpayloadscript.lua',e);e.mightyBadaBoom();e.mightyBadaBoom()
assert(#clouds==2 and #pulses==2 and #stunned==1 and #killed==1 and destroyed==1)
assert(pulses[1][1]=='emp' and pulses[1][3]==60 and pulses[2][3]==10)
assert(clouds[1][1]=='electric' and clouds[1][3]==60)
env.gadget:Shutdown();assert(not env.GG.PrioritySFX)
print('PASS: production event producer cap, IDs, finite input, sticky damage/CEG/sound preservation, information-payload target hooks/idempotency, API cleanup')
