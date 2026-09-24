local f=assert(io.open('scripts/lib_mosaic.lua'));local text=f:read('*a');f:close()
local a=assert(text:find('function buildRunWeaterForeCast()',1,true))
local b=assert(text:find('\nfunction buildRunDeterministicAdvertisement',a,true))
local played,waits={},{}
local choices={0,1,0,3};local index=0
local env={Spring={PlaySoundFile=function(path)played[#played+1]=path end},
 Sleep=function(ms)waits[#waits+1]=ms end,
 getDetermenisticHash=function()return 0 end,
 math={random=function()index=index+1;return choices[index]end}}
setmetatable(env,{__index=_G})
local run=assert(loadstring(text:sub(a,b-1)));setfenv(run,env);run()
env.buildRunWeaterForeCast()
assert(#played==5 and #waits==6,'forecast did not finish')
assert(played[2]:find('/PreLude/2.ogg',1,true))
assert(played[4]:find('/PostLude/4.ogg',1,true))
assert(math.abs(waits[3]-4560)<.01 and math.abs(waits[5]-11660)<.01,'wait used another clip duration')
assert(played[1]==played[5] and waits[1]==waits[6])
print('PASS: full forecast sequence, local duration table and matching postlude duration')
