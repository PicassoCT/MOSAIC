-- Lua 5.1: real registration/config and the owner's ponytail/show-body functions.
local map={Head=1,hairemit01=2,hairemit02=3,hairemit03=4,TailRotator=5,Tail1=6,Tail2=7}
Spring={GetUnitPieceMap=function() return map end,ValidUnitID=function() return true end,
    GetUnitIsDead=function() return false end}
local config=dofile('luarules/gadgets/include/smoke_ribbon_config.lua')
local records={}
GG={SmokeRibbon={Set=function(id,slot,piece,options)
    records[slot]=config.Normalize(id,piece,options);return true
end}}
local register=dofile('scripts/lib_investigator_hair.lua')
local groups={hairemit={2,3,4},Tail={6,7}}
local count,driven=register(8,groups,true)
assert(count==3 and driven)
for i=1,3 do
    local r=records['hair'..i]
    assert(r.piece==i+1 and r.directionPiece==6 and r.windAffected,
        'ponytail driver disabled stationary wind on loose locks')
    assert(r.hang==0.85 and r.strands==4,'investigator locks must hang with fine strands')
    assert(r.colorStart[1]>0.8 and r.colorStart[2]>0.7 and r.colorEnd[3]>0.7,
        'investigator locks lost their light blonde colour')
    assert(r.rootOffset[1]==0 and r.rootOffset[2]==0 and r.rootOffset[3]==0)
end
records={};count,driven=register(8,{Tail={6,7}},true)
assert(count==3 and driven and records.hair3.piece==4,'named emitters not resolved')
local paddedMap=map
for _,names in ipairs({{'hairemit1','hairemit2','hairemit3'}, {'hairemit1','hairemit002','hairemit003'}}) do
    map={Head=1,TailRotator=5,Tail1=6,Tail2=7}
    for i,name in ipairs(names) do map[name]=i+1 end
    records={};count,driven=register(8,{Tail={6,7}},true)
    assert(count==3 and driven,'un/padded exported emitters not resolved')
    for i=1,3 do assert(records['hair'..i].piece==i+1,'exported emitter order changed') end
end
map=paddedMap
records={};count,driven=register(8,groups,false)
assert(count==3 and not driven and records.hair1.directionPiece==1 and records.hair1.windAffected,
    'ponytail budget fallback lacks head/wind response')
map.hairemit02=nil;records={};count=register(8,{Tail={6,7}},true)
assert(count==2 and records.hair3 and not records.hair2,'missing emitter truncated later roots')
map.hairemit01=nil;map.hairemit03=nil;records={};count=register(8,{Tail={6,7}},true)
assert(count==0 and next(records)==nil,'old model manufactured estimated roots')
GG.SmokeRibbon=nil;assert(register(8,groups,true)==0,'missing renderer failed')

local file=assert(io.open('scripts/operativeInvestigatorScript.lua'));local source=file:read('*a');file:close()
local function extract(first,last) return assert(source:match(first..'(.-)'..last)) end
local env=setmetatable({unitID=8,Head=1,backpack=9,x_axis=1,y_axis=2,z_axis=3,
    cigarette=11,cigaretteSmoke={Show=function()end},
    upperBodyPieces={},lowerBodyPieces={},shownPieces={},FoldtopFolded=10,
    TablesOfPiecesGroups={Tail={6,7}},boolHasPonyTail=false}, {__index=_G})
local threads,acquires,turns,windStrength=0,0,{},10
env.Spring={GetUnitPieceMap=function()return map end,
    GetWind=function()return windStrength,0,0,windStrength,1,0,0 end,
    GetUnitPosition=function()return 0,0,0 end,
    GetUnitPiecePosDir=function()return 0,0,-1 end,
    GetGameFrame=function()return 30 end,
    UnitScript={GetPieceRotation=function()return 0,0,0 end}}
env.showT=function()end;env.Show=function()end;env.resetT=function()end
env.getGlobalLimitedRessource=function()acquires=acquires+1;return true end
env.StartThread=function()threads=threads+1 end
env.Turn=function(piece,axis,angle,speed)
    assert(type(piece)=='number' and angle==angle and math.abs(angle)<math.huge)
    turns[#turns+1]={piece=piece,axis=axis,angle=angle}
end
env.Sleep=function()coroutine.yield()end
env.lerp=function(a,b,t)return a+(b-a)*t end
env.takeTableSubRange=function(t,a,b)local r={};for i=a,b do r[#r+1]=t[i] end;return r end
local code='local boolWalking=false; local tailWindStarted,ponyTailChosen=false,false;\n'..
    'function setWalking(v) boolWalking=v end\nfunction showBody()'..
    extract('function showBody%(%)','\nboolHasPonyTail = false')..
    '\nfunction localclamp'..extract('function localclamp','\nfunction PlayAnimation')
assert(loadstring(code,'investigator hair integration'));setfenv(assert(loadstring(code)),env)()
env.showBody();env.showBody();env.showBody()
assert(threads==1 and acquires==1,'show/reveal repeated the wind thread or exhausted ponytail slots')
local co=coroutine.create(function()env.tailWind({6,7})end)
assert(coroutine.resume(co));assert(#turns==3,'wind failed to animate yaw, lift and chain')
local standingYaw=turns[1].angle
turns={};env.setWalking(true)
co=coroutine.create(function()env.tailWind({6,7})end)
assert(coroutine.resume(co));assert(#turns==3 and turns[1].angle~=standingYaw,'movement state ignored')
windStrength=0;turns={};assert(coroutine.resume(co));local movingLift=turns[2].angle
turns={};env.setWalking(false);assert(coroutine.resume(co))
assert(turns[2].angle<movingLift,'stopping does not relax wind lift')
turns={};co=coroutine.create(function()env.tailWind({6})end)
assert(coroutine.resume(co));assert(#turns==2,'single-bone rig failed')
env.tailWind({}) -- incomplete rig is harmless
assert(env.windTarget==nil and env.targetRot==nil and env.times==nil,'wind leaked temporary globals')
print('PASS: investigator named/group/sparse emitters, missing model/API, shared tail driver, budget fallback, one wind loop, moving/stopped/single-bone rig')
