-- Exercise the real generated banks, role selection, cancellation and arena loop.
x_axis,y_axis,z_axis=1,2,3
local exchange=dofile('scripts/animations_melee_exchanges.lua')
local bank={FIGHTING={legacy=true}}
exchange.register(bank)
local count=0
local allowed={center=true,Torso=true,Head=true,UpArm1=true,UpArm2=true,LowArm1=true,LowArm2=true}
for name,clip in pairs(bank) do
 if name~='FIGHTING' and not name:find('MELEE_STEP',1,true) and name~='MELEE_BRACE' then
  count=count+1
  local previous=-1
  for _,frame in ipairs(clip) do
   assert(frame.time>previous,'non-monotonic clip: '..name);previous=frame.time
   for _,cmd in ipairs(frame.commands) do
    assert(allowed[cmd.p],'animation took ownership of accessory or lower-body piece')
    assert(cmd.t==cmd.t and math.abs(cmd.t)<math.pi)
    assert(cmd.s>0 and cmd.s<20,'unbounded speed')
   end
  end
  assert(previous<=33,'exchange must stay short')
 end
end
assert(count==14 and bank.FIGHTING.legacy)
local params={melee_style=1,melee_attacker=11,melee_exchange=1}
local alive=true
Spring={ValidUnitID=function(id)return id==90 end,GetUnitIsDead=function()return not alive end,
 GetUnitRulesParam=function(_,name)return params[name] end}
for style=1,7 do
 params.melee_style=style
 local attack,epoch=exchange.select('FIGHTING',90,11)
 local defend=exchange.select('FIGHTING',90,12)
 assert(bank[attack] and bank[defend] and attack~=defend)
 assert(attack:gsub('_ATTACK$','')==defend:gsub('_DEFEND$',''))
 assert(epoch==1 and not exchange.stale(90,epoch))
end
params.melee_style=8
assert(exchange.select('FIGHTING',90,11)=='FIGHTING','original fight must remain reachable')
assert(exchange.select('WALKCYCLE_RUNNING',90,11)=='WALKCYCLE_RUNNING')
local foot,footEpoch=exchange.select('MELEE_STEP_ADVANCE',90,11)
assert(foot=='MELEE_STEP_ADVANCE' and footEpoch==1,'paired feet ignored shared beat changes')
params.melee_exchange=2
assert(exchange.stale(90,1),'stale exchange did not cancel')
alive=false
assert(exchange.stale(90,2),'dead arena did not cancel')
alive=true
local waited,calls=0,0
Sleep=function(ms)waited=waited+ms;calls=calls+1;params.melee_exchange=3 end
assert(not exchange.wait(90,2,500) and waited==33 and calls==1,
 'paired beat stayed asleep through the next exchange')
waited,calls=0,0
assert(exchange.wait(nil,nil,500) and waited==500 and calls==1,
 'ordinary animation gained combat polling overhead')
Sleep=function(ms)waited=waited+ms;calls=calls+1 end
waited,calls=0,0
assert(exchange.wait(90,3,99) and waited==99 and calls==3)
assert(exchange.duration(8)>=50*1000/30,'legacy fight is cut off before its last keyframe')

local file=assert(io.open('scripts/closeCombatArenascript.lua'))
local source=file:read('*a');file:close()
local fn=assert(source:match('(function fightAnimation%(%).-\nend)'))
local headerFile=assert(io.open('gamedata/unit_script_header.lua'))
local header=headerFile:read('*a');headerFile:close()
-- Compile the actual header axis declarations and arena override together.
-- The game's header uses Y=3, Z=2; a standalone 1,2,3 mock missed a real roll.
local axes=assert(header:match('(local x_axis = 1.-local z_axis = 2)'))
local arenaAxes=source:match('(local x_axis, y_axis, z_axis = [^\n]+)') or ''
fn=axes..'\n'..arenaAxes..'\n'..fn
local styles,roles={},{}
local lastStyle,lastEpoch,beats
local milliseconds=0
beats=0
local function finite(n) return n==n and n>-math.huge and n<math.huge end
local function command(_,_,target,speed)
 assert(finite(target) and finite(speed) and speed>=0,'invalid arena motion')
end
local env=setmetatable({unitID=90,unitDefID=1,MeleeExchanges=exchange,fighterOne=11,fighterTwo=12,
 move1=1,move2=2,turn1=3,turn2=4,center=5,arena=6,attach1=7,attach2=8,
 Turn=command,Move=command,WMove=command,
 Spin=function(piece,axis,speed,accel)assert(axis==2,'arena must circle about engine axis 2 despite the actor header');command(piece,axis,speed,accel)end,
 StopSpin=function()end,stopSpins=function()end,reset=function()end,
 StartThread=function()end,spawnCegAtPiece=function()end,spawnCegAtPieceGround=function()end,spawnCegAtUnit=function()end,
 randSign=function()return math.random(0,1)==0 and -1 or 1 end,
 Sleep=function(ms)assert(finite(ms) and ms>0);milliseconds=milliseconds+ms;coroutine.yield()end,
 Spring={GetGameFrame=function()return milliseconds*30/1000 end,GetUnitHeight=function()return 40 end,
 GetUnitPieceInfo=function(_,piece)return {offset={piece==1 and -2 or piece==2 and 2 or 0,1,0}} end,
 SetUnitRulesParam=function(_,key,value)
  assert(value~=nil,'arena published a missing participant')
  if key=='melee_style' then
   assert(value>=1 and value<=8 and value~=lastStyle,'repeated or invalid exchange')
   lastStyle=value;styles[value]=true
  elseif key=='melee_attacker' then
   assert(value==11 or value==12);roles[value]=true
  elseif key=='melee_exchange' then
   assert(value==(lastEpoch or 0)+1);lastEpoch=value;beats=beats+1
  end
 end}}, {__index=_G})
local compiled
if setfenv then compiled=assert(loadstring(fn));setfenv(compiled,env)
else compiled=assert(load(fn,'arena','t',env)) end
compiled()
math.randomseed(1337)
local thread=coroutine.create(env.fightAnimation)
for i=1,600 do local ok,err=coroutine.resume(thread);assert(ok,err) end
for style=1,8 do assert(styles[style],'unreachable arena style '..style) end
assert(roles[11] and roles[12] and beats>100)
-- All three lower-body controllers must leave the fight's upper body alone.
for _,path in ipairs({'scripts/operativeassetscript.lua','scripts/operativePropagatorScript.lua','scripts/operativeInvestigatorScript.lua'}) do
 local f=assert(io.open(path));local body=f:read('*a');f:close()
 local definition=assert(body:match('(LowerAnimationStateFunctions%s*=%s*{.-\n})'))
 local filter,receivedMask
 local state={walking='walking',standing='standing',riding='riding',aiming='aiming',idle='idle'}
 local upper={[42]=42}
 local scope=setmetatable({eAnimState=state,boolFlying=false,boolAiming=false,boolInClosedCombat=true,
  upperBodyPieces=upper,meleeFootworkClip='WALKCYCLE_WALK',closeCombat={arenaID=90},unitID=11,MeleeExchanges=exchange,
  lowerBodyAnimations={walking={'WALKCYCLE_RUNNING'}},randT=function(t)return t[1]end,
  playMaskedAnimation=function(mask,clip,pieces)filter=pieces;receivedMask=mask;assert(clip)end,
  reset=function()error('lower controller took center ownership during combat')end,
 },{__index=_G})
 local loader
 if setfenv then loader=assert(loadstring(definition));setfenv(loader,scope)
 else loader=assert(load(definition,path,'t',scope)) end
 loader()
 local mask={[99]=true}
 assert(scope.LowerAnimationStateFunctions.walking(mask)=='walking')
 assert(filter==upper and receivedMask==mask,path..': lower clip overwrites the fight')
end

assert(bank.MELEE_BRACE and bank.MELEE_STEP_ADVANCE and bank.MELEE_STEP_RETREAT)
params.melee_style=1;params.melee_attacker=11
assert(exchange.footwork(90,11,'legacy')=='MELEE_STEP_ADVANCE')
assert(exchange.footwork(90,12,'legacy')=='MELEE_STEP_RETREAT')
params.melee_style=8;assert(exchange.footwork(90,11,'legacy')=='legacy')
assert(exchange.footwork(90,11,nil,true)=='MELEE_BRACE')
print('PASS: 14 bounded clips, paired roles, legacy variation, cancellation and '..beats..' finite arena exchanges')
