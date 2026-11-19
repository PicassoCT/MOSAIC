-- Real Killed call-ins: preserve resource cleanup and authored variation while
-- transferring body ownership to the shared procedural solver.
local scripts={
 {'scripts/operativeassetscript.lua',4096+16+32+8},
 {'scripts/operativePropagatorScript.lua',512+128+256+64},
 {'scripts/operativeInvestigatorScript.lua',512+128+256+64},
}
for _,spec in ipairs(scripts) do
 local file=assert(io.open(spec[1]));local source=file:read('*a');file:close()
 local killed=assert(source:match('(function script.Killed%([^\n]*\n.-\nend)'))
 local hit=assert(source:match('(function script.HitByWeapon%([^\n]*\n.-\nend)'))
 for _,choice in ipairs({1,8}) do
  local physical,authored,signal,mask,released,smoke=0,0,nil,nil,0,0
  local env=setmetatable({
   script={},boolInClosedCombat=true,unitID=77,civilianID=88,
   SIG_ANIM=spec[2]==4152 and 4096 or 512,
   SIG_UP=spec[2]==4152 and 16 or 128,
   SIG_LOW=spec[2]==4152 and 32 or 256,
   SIG_STOP=spec[2]==4152 and 8 or 64,
   boolHasPonyTail=true,
   math=setmetatable({random=function()return choice end},{__index=math}),
   doesUnitExistAlive=function()return true end,
   Spring={DestroyUnit=function(id,selfd,reclaim)assert(id==88 and selfd and reclaim)end},
   releaseHumanShield=function()released=released+1 end,
   setHumanShieldActive=function(active)assert(not active)end,
   cigaretteSmoke={Shutdown=function()smoke=smoke+1 end},
   StartThread=function()end,releaseGlobalLimitedRessource=function()end,
   SetSignalMask=function(value)mask=value end,
   Signal=function(value)signal=value end,
   PlayAnimation=function(name)assert(name=='DEATH');authored=authored+1 end,
   proceduralDeath=function(damage,maxHealth,dx,dz)
    assert(damage==300 and maxHealth==200 and dx==-.5 and dz==.8)
    physical=physical+1
   end,
  },{__index=_G})
  local code=hit..'\n'..killed
  local fn
  if setfenv then fn=assert(loadstring(code));setfenv(fn,env)
  else fn=assert(load(code,spec[1],'t',env)) end
  fn()
  assert(env.script.HitByWeapon(-.5,.8,1,300)==300)
  assert(env.script.Killed(300,200)==1)
  assert(mask==0 and signal==spec[2],'wrong body animation signal mask')
  assert(env.bodyDying and not env.boolInClosedCombat)
  assert(physical==(choice==8 and 1 or 0) and authored==(choice==1 and 1 or 0))
  if spec[1]:find('Investigator',1,true) then assert(smoke==1)
  else assert(released==1) end
 end
end
print('PASS: all three operative death call-ins, both death paths, impact direction, body ownership and existing cleanup')
