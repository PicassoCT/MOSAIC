-- Lua 5.1: real definitions, registry, unit script, objective gadget.
local function loadIn(path,env)
    local fn=assert(loadfile(path));setfenv(fn,env);return fn()
end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local specs=dofile('luarules/configs/civic_objectives.lua')
assert(#specs==8)
local e=setmetatable({GG={InstanceCulture='asian'},Spring={},Game={mapName='test',mapSizeX=4096,mapSizeZ=4096,gameSpeed=30},
    UnitDefs={},UnitDefNames={},count=count,unitCanBuild=function() return {} end}, {__index=_G})
local src=assert(io.open('scripts/lib_mosaic.lua')):read('*a')
local function def(name)
    if not e.UnitDefNames[name] then
        local d={id=#e.UnitDefs+1,name=name,buildOptions={}}
        e.UnitDefs[d.id]=d;e.UnitDefNames[name]=d
    end
    return e.UnitDefNames[name].id
end
for name in src:gmatch('UnitDefNames%["([^"]+)"%]') do def(name) end
for _,s in ipairs(specs) do def(s.name) end
loadIn('scripts/lib_mosaic.lua',e)
local registry=e.getObjectiveTypes(e.UnitDefs)
for _,s in ipairs(specs) do assert(registry[def(s.name)]=='land',s.name) end
assert(registry[def('objective_factoryship')]=='water')

e.VFS={Include=function(path)
    if path=='luarules/configs/civic_objectives.lua' then return specs end
    if path=='luarules/gadgets/include/objective_income.lua' then return loadIn(path,e) end
end}
e.Building={New=function(_,t) return t end};e.lowerkeys=function(t)return t end
local defs=loadIn('units/neutral/objective_civic.lua',e)
assert(count(defs)==8)
for _,s in ipairs(specs) do
    local d=assert(defs[s.name]);assert(d.maxDamage==15000 and not d.builder and not d.canAttack)
    assert(d.customparams.normaltex=='unittextures/house_asian_normal.dds')
    assert(#d.yardMap==d.footprintX*d.footprintZ)
    assert(d.collisionVolumeOffsets=='0 '..(s.height/2)..' 0')
    local metadata=loadIn('objects3d/'..d.objectName..'.lua',e)
    assert(metadata.height==s.height and metadata.tex2=='house_asian_selfilu_reflection.png')
    assert(io.open('unitpics/'..d.buildPic))
end

local light,visible
e.unitID=101;e.script={};e.piece=function(n)assert(n=='facades');return 3 end
e.include=function(n)return loadIn('scripts/'..n,e)end
e.Spring.SetUnitAlwaysVisible=function(_,v)visible=v end
e.GG.SetObjectiveRadiancePieceVisible=function(id,p,on,mode)
    assert(id==101 and p==3);light=on and mode or nil
end
loadIn('scripts/objective_civic_script.lua',e)
e.script.Create();assert(visible and light=='material')
assert(e.script.Killed()==0 and light==nil)

-- Exercise normal Gaia lifecycle and reward reversal using the actual gadget.
local units,nextID,frame={},1000,0
local rates={}
local rewards={}
e.gadget={};e.gadgetHandler={IsSyncedCode=function()return true end}
e.echo=function()end;e.toString=tostring
e.UnitDefs[def('propagandaserver')].metalMake=5
e.getAllTeamsOfType=function(side)return {[side=='protagon' and 1 or 2]=true}end
e.getManualObjectiveSpawnMapNames=function()return true end
e.detectMapControlledPlacementComplete=function()end
e.Spring.GetGaiaTeamID=function()return 0 end
e.Spring.GetGameFrame=function()return frame end
e.Spring.GetTeamInfo=function(id)return id,nil,false end
e.Spring.GetTeamStartPosition=function(id)return id==1 and 0 or 4096,10,2048 end
e.Spring.AreTeamsAllied=function(a,b)return a==b end
e.Spring.GetUnitHealth=function()return 15000,15000 end
e.Spring.GetUnitBuildFacing=function(id)return units[id].facing end
e.Spring.SetUnitRulesParam=function(id,key,rate)assert(key=='objective_income' and rate>0 and rate<=12);rates[id]=rate end
e.Spring.GetUnitDefID=function(id)return units[id] and units[id].def end
e.Spring.GetUnitTeam=function(id)return units[id] and units[id].team end
e.Spring.GetUnitPosition=function(id)local u=units[id];return u.x,u.y,u.z end
e.Spring.GetUnitTooltip=function(id)return units[id].tooltip or '' end
e.Spring.SetUnitTooltip=function(id,t)units[id].tooltip=t end
e.Spring.GetGroundHeight=function()return 10 end
local failNext=false
e.Spring.CreateUnit=function(name,x,y,z,facing,team)
    if failNext then failNext=false;return nil end
    nextID=nextID+1
    units[nextID]={def=type(name)=='number' and name or def(name),team=team,x=x,y=y,z=z,facing=facing}
    local id=nextID;e.gadget:UnitCreated(id,units[id].def);return id
end
e.doesUnitExistAlive=function(id)return units[id]~=nil end
e.GG.Bank={TransferToTeam=function(_,amount,team,id)rewards[#rewards+1]={amount,team,id}end}
loadIn('luarules/gadgets/game_objective.lua',e)
local function step(f)frame=f;e.gadget:GameFrame(f)end
e.gadget:Initialize();step(1)
e.GG.MapCompletedBuildingPlacement=true;step(2)
local ids={}
for _,s in ipairs(specs) do ids[#ids+1]=e.Spring.CreateUnit(s.name,200,10,200,2,0) end
assert(count(e.GG.Objectives)==8)
step(300);assert(#rewards==8)
local totalMoney=0
for _,r in ipairs(rewards) do assert(r[1]>0 and r[1]<=120);totalMoney=totalMoney+r[1]end
assert(math.abs(totalMoney-12*(300-2)/30)<1e-6)
for i,id in ipairs(ids) do
    local old=e.GG.Objectives[id]
    e.gadget:UnitDestroyed(id);units[id]=nil
    assert(e.GG.Objectives[id]==nil)
    local marker=nextID;local dead=assert(e.GG.DeadObjectives[marker])
    assert(dead.siteID==old.siteID)
    assert(dead.defID==def(specs[i].name) and dead.boolProProtagon~=old.boolProProtagon)
    rewards={}
    -- The actual bank swaps its queue. A cached reference would lose payment.
    e.GG.Bank={TransferToTeam=function(_,amount,team,uid)rewards[#rewards+1]={amount,team,uid}end}
    step(math.floor(frame/300+1)*300)
    local found=false
    for _,r in ipairs(rewards) do if r[3]==marker then assert(r[2]==(dead.boolProProtagon and 1 or 2));found=true end end
    assert(found)
    e.gadget:UnitDestroyed(marker);units[marker]=nil
    assert(e.GG.DeadObjectives[marker]==nil)
    assert(#e.GG.ObjectiveRestores==1 and e.GG.ObjectiveRestores[1].siteID==old.siteID)
    step(frame+30)
    local restored=nextID
    assert(e.GG.Objectives[restored].boolProProtagon==old.boolProProtagon)
    assert(units[restored].facing==2 and #e.GG.ObjectiveRestores==0)
    assert(e.GG.Objectives[restored].income.pressure==0)
    assert(e.GG.Objectives[restored].siteID==old.siteID)
end
local playerOwned=e.Spring.CreateUnit(specs[1].name,200,10,200,0,1)
assert(not e.GG.Objectives[playerOwned])

-- Failed marker creation and failed restoration both retry without income.
local id=next(e.GG.Objectives);local old=e.GG.Objectives[id]
failNext=true;e.gadget:UnitDestroyed(id);units[id]=nil
assert(#e.GG.ObjectiveRestores==1 and e.GG.ObjectiveRestores[1].marker)
step(frame+30);local marker=nextID
assert(e.GG.DeadObjectives[marker].boolProProtagon~=old.boolProProtagon)
e.gadget:UnitDestroyed(marker);units[marker]=nil
failNext=true;step(frame+30);assert(#e.GG.ObjectiveRestores==1)
step(frame+30);assert(#e.GG.ObjectiveRestores==0)
assert(e.GG.Objectives[nextID].boolProProtagon==old.boolProProtagon)
assert(e.GG.Objectives[nextID].siteID==old.siteID)

-- Distinct sites survive engine unit-ID reuse; queued and live versions of
-- one site never appear twice in the allocation.
local currentMaxID=nextID
nextID=ids[1]-1
local reused=e.Spring.CreateUnit(specs[1].name,200,10,200,0,0)
assert(reused==ids[1])
local seen={}
for _,r in pairs(e.GG.Objectives)do assert(not seen[r.siteID]);seen[r.siteID]=true end
nextID=currentMaxID
rates={};step(math.floor(frame/300+1)*300)
local totalRate=0;for _,rate in pairs(rates)do totalRate=totalRate+rate end
assert(math.abs(totalRate-12)<1e-6)

-- Reload preserves states and the pending income clock.
local oldTable=e.GG.Objectives;local total=count(oldTable)
e.gadget={};loadIn('luarules/gadgets/game_objective.lua',e);e.gadget:Initialize()
step(frame+30);assert(e.GG.Objectives==oldTable and count(oldTable)==total)

print('Civic objectives: definitions, radiance, Gaia lifecycle, rewards and restoration PASS')
