for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
 local f=assert(io.open(path));local source=f:read('*a');f:close()
 local setup=assert(source:match('(function setupAnimation%(%).-\nend)'))
 local commands={
  {c='turn',p='Handbag',a=1,t=1,s=1},
  {c='turn',p='Head1',a=2,t=.2,s=1},
  {c='turn',p='Handbag5',a=3,t=.3,s=1},
  {c='move',p='center',a=3,t=15,s=2},
  {c='turn',p=4,a=1,t=.4,s=1},
  {c='turn',p='OtherAbsentProp',a=1,t=.5,s=1},
 }
 local cache={}
 local env=setmetatable({animationCacheKey='model-a',
  GetSharedOneTimeResult=function(key)return cache[key]end,
  SetSharedOneTimeResult=function(key,value)cache[key]=value end,
  x_axis=1,y_axis=2,z_axis=3,unitID=1,
  map={center=0,Head1=2,UpLeg1=4},Animations={fixture={{time=0,commands=commands}}},
  constructSkeleton=function()return {[0]={0,0,12}}end,
 },{__index=_G})
 local loader
 if setfenv then loader=assert(loadstring(setup));setfenv(loader,env)
 else loader=assert(load(setup,path,'t',env))end
 loader();env.setupAnimation()
 local result=env.Animations.fixture[1].commands
 assert(#result==3,'missing props truncated valid body commands')
 assert(result[1].p==2 and result[1].a==3 and result[1].t==.2)
 assert(result[2].p==0 and result[2].a==2 and result[2].t==3,'move offset or zero-valued piece ID lost')
 assert(result[3].p==4 and result[3].a==1)
 local firstBank=env.Animations
 env.Animations={};env.setupAnimation()
 assert(env.Animations==firstBank,'same-definition unit did not reuse resolved bank')
 assert(result[2].a==2 and result[2].t==3,'cached bank was converted twice')
 env.animationCacheKey='model-b'
 env.map={center=0,Head1=9}
 env.Animations={fixture={{time=0,commands={{c='turn',p='Head1',a=2,t=.1,s=1}}}}}
 env.setupAnimation()
 assert(env.Animations~=firstBank and env.Animations.fixture[1].commands[1].p==9,
  'different skeletons shared resolved piece IDs')
 assert(firstBank.fixture[1].commands[1].p==2,'a different model mutated the cached bank')
end
print('PASS: both civilian loaders retain dense body commands with absent props and share resolved banks only within each model definition')
