-- Lua 5.1: polygon ponytail selection, reveal lifecycle and wind animation.
local map={Head=1,TailRotator=5,Tail1=6,Tail2=7}
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
print('PASS: investigator polygon ponytail, one wind loop, moving/stopped/single-bone rig')
