x_axis,y_axis,z_axis=1,2,3
local M=dofile('scripts/animations_civilian_conversation.lua')
local bank=dofile('scripts/animations_civilian_female.lua')
local originalNormal,originalAggro=bank.UPBODY_NORMAL_TALK,bank.UPBODY_AGGRO_TALK
M.register(bank)
assert(bank.UPBODY_NORMAL_TALK==originalNormal and bank.UPBODY_AGGRO_TALK==originalAggro,'authored clips must survive')
local allowed={Head1=true,UpBody=true,UpArm1=true,UpArm2=true,LowArm1=true,LowArm2=true}
local signatures,generated,totalCommands={},{},0
for name,clip in pairs(bank) do
 if name:match('^UPBODY_NORMAL_TALK_') or name:match('^UPBODY_AGGRO_TALK_') then
  generated[#generated+1]=name
  local lastTime=-1;local first,last,signature={},{},{}
  local count=0
  for index,frame in ipairs(clip) do
   assert(frame.time>lastTime,'non-monotonic keyframe time');lastTime=frame.time
   for _,cmd in ipairs(frame.commands) do
    assert(cmd.c=='turn' and allowed[cmd.p],'gesture acquired a leg/prop/cloth/physics piece')
    assert(cmd.t==cmd.t and math.abs(cmd.t)<math.pi,'invalid/overextended pose')
    assert(cmd.s==cmd.s and cmd.s>0 and cmd.s<=12,'unbounded angular speed')
    local key=cmd.p..cmd.a;last[key]=cmd.t
    if index==1 then first[key]=cmd.t end
    signature[#signature+1]=string.format('%s/%s/%.4f',key,frame.time,cmd.t)
    count=count+1
   end
  end
  for key,start in pairs(first) do assert(math.abs(last[key]-start)<1e-5,'gesture failed to recover neutral: '..key) end
  assert(count<500,'excessive precompiled command budget');totalCommands=totalCommands+count
  local sig=table.concat(signature,';');assert(not signatures[sig],'duplicate gesture');signatures[sig]=true
 end
end
assert(#generated==8,'expected eight new distinct gestures')
local seen={}
for _,base in ipairs({'UPBODY_NORMAL_TALK','UPBODY_AGGRO_TALK'}) do
 local previous
 math.randomseed(1337)
 for i=1,500 do
  local name=M.select(base,previous)
  assert(bank[name] and name~=previous,'missing clip or immediate repetition')
  seen[name]=true;previous=name
 end
end
for _,name in ipairs(generated) do assert(seen[name],'unreachable variation '..name) end
assert(seen.UPBODY_NORMAL_TALK and seen.UPBODY_AGGRO_TALK,'legacy clips became unreachable')
assert(M.select('WALKCYCLE_WALK','x')=='WALKCYCLE_WALK','unrelated animation remapped')
-- setupAnimation mutates commands: separate registrations must not share them.
local second={};M.register(second);local name=generated[1]
bank[name][1].commands[1].p=99
assert(type(second[name][1].commands[1].p)=='string','cross-unit template mutation')
print('PASS: eight distinct bounded conversation gestures, neutral recovery, all choices reachable, no immediate repeat, no physics/leg commands; '..totalCommands..' generated commands')
