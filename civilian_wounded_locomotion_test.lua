for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'})do
 local f=assert(io.open(path));local source=f:read('*a');f:close()
 local states={walking='walking',wounded='wounded',coverwalk='coverwalk',standing='standing',aiming='aiming',transported='transported',slaved='slaved',trolley='trolley'}
 local selected,played
 local mask={body=true}
 local env=setmetatable({script={},bodyConfig={},eAnimState=states,SIG_STOP=1,
  Signal=function()end,Turn=function()end,center=1,y_axis=2,
  setOverrideAnimationState=function(u,l)selected={u,l}end,
  lowerBodyAnimations={walking={'walk'},wounded={'wound'}},
  conditionalFilterOutUpperBodyTable=function()return mask end,
  randT=function(t,...)assert(select('#',...)==0,'mask passed to random selector');return t[1]end,
  PlayAnimation=function(name,filter)played={name,filter}end,
  playAerosolAnimation=function()return false end,maRa=function()return false end,
 },{__index=_G})
 local function run(code)
  if setfenv then setfenv(assert(loadstring(code)),env)()
  else assert(load(code,path,'t',env))() end
 end
 run(assert(source:match('(function getWalkingState%(%).-\nend)')))
 run(assert(source:match('(function script.StartMoving%(%).-\nend)')))
 for _,case in ipairs({{false,false,'walking'},{true,false,'wounded'},{false,true,'coverwalk'},{true,true,'coverwalk'}})do
  env.bodyConfig.boolWounded,env.bodyConfig.boolCoverWalk=case[1],case[2]
  env.script.StartMoving();assert(selected[1]==case[3] and selected[2]==case[3],'movement discarded injury priority')
 end
 selected=nil;env.boolDying=true;env.script.StartMoving();assert(not selected,'death restarted locomotion');env.boolDying=false
 run(assert(source:match('(LowerAnimationStateFunctions = %b{})')))
 env.bodyConfig={boolWounded=true};env.LowerAnimationStateFunctions.walking()
 assert(played[1]=='wound' and played[2]==mask,'wounded playback lost upper-body ownership mask')
 env.bodyConfig={boolInfluenced=true};env.LowerAnimationStateFunctions.walking()
 assert(played[1]=='wound' and played[2]==mask,'influenced wounded playback lost mask')
end
print('PASS: civilian and agent injury priorities survive movement; wounded clips receive the body mask')
