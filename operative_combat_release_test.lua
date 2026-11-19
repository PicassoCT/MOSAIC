for _,path in ipairs({'scripts/operativeassetscript.lua','scripts/operativePropagatorScript.lua','scripts/operativeInvestigatorScript.lua'})do
 local f=assert(io.open(path));local source=f:read('*a');f:close()
 local fn=assert(source:match('(function closeCombatOS%(%).-\nend)'))
 assert(source:find('local boolWalking = false',1,true)<source:find('function closeCombatOS()',1,true),'combat exit reads a shadowed walking flag')
 for _,moving in ipairs({false,true})do
  local commands={};local alive=true
  local env=setmetatable({unitID=1,boolInClosedCombat=true,closeCombat={arenaID=90},
   eAnimState={fighting='fight',walking='walk',standing='stand'},
   Hide=function()end,StartThread=function()end,setViewRadius=function()end,maRa=function()return false end,
   Sleep=function(ms)coroutine.yield(ms)end,
   doesUnitExistAlive=function()return alive end,
   setOverrideAnimationState=function(u,l)commands[#commands+1]={upper=u,lower=l}end,
  },{__index=_G})
  local code='local boolWalking = '..tostring(moving)..'\n'..fn
  if setfenv then setfenv(assert(loadstring(code)),env)()else assert(load(code,path,'t',env))()end
  local co=coroutine.create(env.closeCombatOS)
  for step=1,8 do
   local ok,ms=coroutine.resume(co);assert(ok,ms)
   if ms==500 then alive=false end
   if not env.boolInClosedCombat then break end
  end
  assert(not env.boolInClosedCombat,'arena destruction did not release combat state')
  local final=commands[#commands]
  assert(final.upper==nil and final.lower==(moving and 'walk' or 'stand'),path..': survivor kept combat footwork or lost live locomotion')
 end
end
print('PASS: all three combat owners restore stationary or moving survivor locomotion after arena destruction')
