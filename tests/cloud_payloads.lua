-- Execute the actual detonation entrypoints, with gameplay services stubbed.
include=function()end;piece=function()return 1 end;script={};unitID=10;unitDefID=1
UnitDefs={[1]={name='physicspayload'},[2]={name='gcscrapheap'}}
UnitDefNames=setmetatable({gcscrapheap={id=2}},{__index=function()return {id=1}end})
local bursts,killed,destroyed={},{},0
local config={instance={culture='international'},payloadDestructionRange=100,
    Warhead={DefusalPunishment=10,automationPayloadStunTimeSeconds=5}}
getGameConfig=function()return config end
for _,name in ipairs({'getDefusalCapableTypeTable','getCultureUnitModelTypes','getLoadAbleTruckTypes',
    'getChemTrailInfluencedTypes','getAutomationPayloadDisabledType','getAutomationPayloadDestroyedType'}) do
    _G[name]=function()return {[1]=true}end
end
isTeamAITeam=function()return false end
Spring={GetUnitTeam=function()return 0 end,GetGaiaTeamID=function()return 0 end,
    GetGameFrame=function()return 0 end,GetUnitPosition=function(id)return id,0,id end,
    GetUnitDefID=function(id)return id==30 and 2 or 1 end,DestroyUnit=function()destroyed=destroyed+1 end,
    SetUnitAlwaysVisible=function()end,GetAllUnits=function()return {20}end,
    GetUnitHealth=function()return 100,100 end,GetUnitLastAttacker=function()return nil end}
GG={CloudVolume={Burst=function(p,x,y,z)bursts[#bursts+1]=p end},
    Bank={TransferToTeam=function()end},UnitsToKill={PushKillUnit=function(_,id)killed[id]=true end},
    AerosolAffectedCivilians={}}
getAllTeamsOfType=function()return {}end
getAllNearUnit=function()return {20,30}end
foreach=function(t,filter,action)
    for _,id in pairs(t)do local result=filter(id);if result and action then action(result)end end
end
createUnitAtUnit=function(team,name,id)assert(name=='nukedecalfactory' and id==10);return 40 end
getChemTrailTypes=function()return {wanderlost=1}end
setAerosolCivilianBehaviour=function()return true end
stunUnit=function()end
houseTypeTable={}
for _,kind in ipairs({'physicspayload','biopayload','informationpayload'}) do
    UnitDefs[1].name=kind;bursts={};destroyed=0;killed={}
    dofile('scripts/warheadpayloadscript.lua')
    -- Avoid building a million-cell crater in this visual integration test.
    createCrater=function()end
    mightyBadaBoom();mightyBadaBoom()
    assert(destroyed==1,'detonation repeated')
    if kind=='physicspayload' then
        assert(bursts[1]=='nuclear' and #bursts==1)
        assert(killed[20] and not killed[30],'blast damage filter changed')
    elseif kind=='biopayload' then assert(bursts[1]=='bio' and GG.AerosolAffectedCivilians[20])
    else assert(bursts[1]=='electric' and killed[20]) end
end
bursts={};destroyed=0
Spring.PlaySoundFile=function()end;Spring.SetUnitNeutral=function()end
Spring.SetUnitNoSelect=function()end;Spring.SetUnitNoDraw=function()end
Sleep=function()end;StartThread=function(fn)fn()end
dofile('scripts/impactorscript.lua');script.Create()
assert(bursts[1]=='impact' and #bursts==1 and destroyed==1)
print('PASS: godrod helper, nuclear/bio/information payload routes, one-shot detonation, damage filters, independent visual before source removal')
