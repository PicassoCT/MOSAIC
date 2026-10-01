-- Lua 5.1: real definitions, registry, unit script, objective gadget and preview command.
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
local units,nextID={},1000
local rewards,queued={},{}
e.gadget={};e.gadgetHandler={IsSyncedCode=function()return true end}
e.echo=function()end;e.toString=tostring
e.getGameConfig=function()return {Objectives={RewardCyle=30,Reward=17}}end
e.getAllTeamsOfType=function(side)return {[side=='protagon' and 1 or 2]=true}end
e.getManualObjectiveSpawnMapNames=function()return false end
e.Spring.GetGaiaTeamID=function()return 0 end
e.Spring.GetUnitDefID=function(id)return units[id] and units[id].def end
e.Spring.GetUnitTeam=function(id)return units[id] and units[id].team end
e.Spring.GetUnitPosition=function(id)local u=units[id];return u.x,u.y,u.z end
e.Spring.GetUnitTooltip=function(id)return units[id].tooltip or '' end
e.Spring.SetUnitTooltip=function(id,t)units[id].tooltip=t end
e.Spring.GetGroundHeight=function()return 10 end
e.Spring.CreateUnit=function(name,x,y,z,facing,team)
    nextID=nextID+1
    units[nextID]={def=type(name)=='number' and name or def(name),team=team,x=x,y=y,z=z}
    local id=nextID;e.gadget:UnitCreated(id,units[id].def);return id
end
e.doesUnitExistAlive=function(id)return units[id]~=nil end
e.GG.Bank={TransferToTeam=function(_,amount,team,id)rewards[#rewards+1]={amount,team,id}end}
e.GG.UnitsToSpawn={PushCreateUnit=function(_,...)queued[#queued+1]={...}end}
loadIn('luarules/gadgets/game_objective.lua',e)
local ids={}
for _,s in ipairs(specs) do ids[#ids+1]=e.Spring.CreateUnit(s.name,200,10,200,0,0) end
assert(count(e.GG.Objectives)==8)
e.gadget:GameFrame(30);assert(#rewards==8)
for i,id in ipairs(ids) do
    assert(rewards[i][1]==17)
    local old=e.GG.Objectives[id]
    e.gadget:UnitDestroyed(id);units[id]=nil
    assert(e.GG.Objectives[id]==nil)
    local marker=nextID;local dead=assert(e.GG.DeadObjectives[marker])
    assert(dead.defID==def(specs[i].name) and dead.boolProProtagon~=old.boolProProtagon)
    rewards={};e.gadget:GameFrame(60)
    local found=false
    for _,r in ipairs(rewards) do if r[3]==marker then assert(r[2]==(dead.boolProProtagon and 1 or 2));found=true end end
    assert(found)
    e.gadget:UnitDestroyed(marker);units[marker]=nil
    assert(e.GG.DeadObjectives[marker]==nil)
    local q=queued[#queued];assert(q[1]==def(specs[i].name) and q[6]==0)
    local restored=e.Spring.CreateUnit(unpack(q));assert(e.GG.Objectives[restored])
end
local playerOwned=e.Spring.CreateUnit(specs[1].name,200,10,200,0,1)
assert(not e.GG.Objectives[playerOwned])

-- Preview command cannot mutate a non-cheat game and skips unsafe placement.
e.gadget={};local action,cheating,occupied,water,created
e.gadgetHandler.AddChatAction=function(_,name,fn)assert(name=='civicobjectives');action=fn end
e.gadgetHandler.RemoveChatAction=function(_,name)assert(name=='civicobjectives');action=nil end
e.Spring.Echo=function()end;e.Spring.IsCheatingEnabled=function()return cheating end
e.Spring.GetUnitsInCylinder=function()return occupied and {5} or {}end
e.Spring.GetGroundHeight=function()return water and -20 or 10 end
e.Spring.CreateUnit=function(name,_,_,_,_,team)assert(registry[def(name)]=='land' and team==0);created=created+1;return created end
loadIn('luarules/gadgets/dbg_civic_objectives.lua',e);e.gadget:Initialize()
created=0;action(nil,nil,{});assert(created==0)
cheating=true;action(nil,nil,{});assert(created==8)
occupied=true;action(nil,nil,{});assert(created==8)
occupied=false;water=true;action(nil,nil,{});assert(created==8)
water=false;action(nil,nil,{'-10000','-10000'});assert(created==8)
e.gadget:Shutdown();assert(not action)
print('Civic objectives: definitions, radiance, Gaia lifecycle, rewards, restoration and preview command PASS')
